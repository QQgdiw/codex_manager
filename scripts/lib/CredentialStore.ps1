$script:DefaultCredentialStorePath = Join-Path (
    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
) '.secrets\credentials.dpapi'
$script:CredentialStoreSchemaVersion = '1'

if (-not ('Security.Cryptography.ProtectedData' -as [type])) {
    Add-Type -AssemblyName System.Security
}

if (-not ('ManagedCredentialPathRuntime' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

public static class ManagedCredentialPathRuntime
{
    private const uint FileReadAttributes = 0x80;
    private const uint FileShareRead = 0x1;
    private const uint FileShareWrite = 0x2;
    private const uint FileShareDelete = 0x4;
    private const uint OpenExisting = 3;
    private const uint FileFlagBackupSemantics = 0x02000000;

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern SafeFileHandle CreateFile(
        string fileName,
        uint desiredAccess,
        uint shareMode,
        IntPtr securityAttributes,
        uint creationDisposition,
        uint flagsAndAttributes,
        IntPtr templateFile
    );

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern uint GetFinalPathNameByHandle(
        SafeFileHandle file,
        StringBuilder path,
        uint pathLength,
        uint flags
    );

    public static string GetFinalDirectoryPath(string path)
    {
        using (SafeFileHandle handle = CreateFile(
            path,
            FileReadAttributes,
            FileShareRead | FileShareWrite | FileShareDelete,
            IntPtr.Zero,
            OpenExisting,
            FileFlagBackupSemantics,
            IntPtr.Zero
        ))
        {
            if (handle.IsInvalid)
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }

            StringBuilder result = new StringBuilder(32768);
            uint length = GetFinalPathNameByHandle(
                handle,
                result,
                (uint)result.Capacity,
                0
            );
            if (length == 0 || length >= result.Capacity)
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }

            string finalPath = result.ToString();
            if (finalPath.StartsWith(@"\\?\UNC\", StringComparison.Ordinal))
            {
                return @"\\" + finalPath.Substring(8);
            }
            if (finalPath.StartsWith(@"\\?\", StringComparison.Ordinal))
            {
                return finalPath.Substring(4);
            }
            return finalPath;
        }
    }
}
'@
}

if (-not ('ManagedCredentialJsonRuntime' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

public sealed class ManagedCredentialJsonRuntime
{
    private readonly string text;
    private int index;
    private bool duplicateFound;

    private ManagedCredentialJsonRuntime(string json)
    {
        if (json == null)
        {
            throw new ArgumentNullException("json");
        }
        text = json;
    }

    public static bool HasDuplicateProperties(string json)
    {
        ManagedCredentialJsonRuntime parser =
            new ManagedCredentialJsonRuntime(json);
        parser.ParseValue();
        parser.SkipWhitespace();
        if (parser.index != parser.text.Length)
        {
            throw new FormatException();
        }
        return parser.duplicateFound;
    }

    private void ParseValue()
    {
        SkipWhitespace();
        if (index >= text.Length)
        {
            throw new FormatException();
        }

        switch (text[index])
        {
            case '{':
                ParseObject();
                return;
            case '[':
                ParseArray();
                return;
            case '"':
                ParseString();
                return;
            case 't':
                ParseLiteral("true");
                return;
            case 'f':
                ParseLiteral("false");
                return;
            case 'n':
                ParseLiteral("null");
                return;
            default:
                ParseNumber();
                return;
        }
    }

    private void ParseObject()
    {
        index++;
        SkipWhitespace();
        HashSet<string> names = new HashSet<string>(StringComparer.Ordinal);
        if (Consume('}'))
        {
            return;
        }

        while (true)
        {
            SkipWhitespace();
            string name = ParseString();
            if (!names.Add(name))
            {
                duplicateFound = true;
            }
            SkipWhitespace();
            Require(':');
            ParseValue();
            SkipWhitespace();
            if (Consume('}'))
            {
                return;
            }
            Require(',');
        }
    }

    private void ParseArray()
    {
        index++;
        SkipWhitespace();
        if (Consume(']'))
        {
            return;
        }

        while (true)
        {
            ParseValue();
            SkipWhitespace();
            if (Consume(']'))
            {
                return;
            }
            Require(',');
        }
    }

    private string ParseString()
    {
        Require('"');
        StringBuilder value = new StringBuilder();
        while (index < text.Length)
        {
            char character = text[index++];
            if (character == '"')
            {
                return value.ToString();
            }
            if (character < 0x20)
            {
                throw new FormatException();
            }
            if (character != '\\')
            {
                value.Append(character);
                continue;
            }
            if (index >= text.Length)
            {
                throw new FormatException();
            }

            char escape = text[index++];
            switch (escape)
            {
                case '"': value.Append('"'); break;
                case '\\': value.Append('\\'); break;
                case '/': value.Append('/'); break;
                case 'b': value.Append('\b'); break;
                case 'f': value.Append('\f'); break;
                case 'n': value.Append('\n'); break;
                case 'r': value.Append('\r'); break;
                case 't': value.Append('\t'); break;
                case 'u':
                    if (index + 4 > text.Length)
                    {
                        throw new FormatException();
                    }
                    int codePoint;
                    if (!Int32.TryParse(
                        text.Substring(index, 4),
                        NumberStyles.AllowHexSpecifier,
                        CultureInfo.InvariantCulture,
                        out codePoint
                    ))
                    {
                        throw new FormatException();
                    }
                    value.Append((char)codePoint);
                    index += 4;
                    break;
                default:
                    throw new FormatException();
            }
        }
        throw new FormatException();
    }

    private void ParseNumber()
    {
        int start = index;
        if (Consume('-'))
        {
            if (index >= text.Length)
            {
                throw new FormatException();
            }
        }

        if (Consume('0'))
        {
        }
        else
        {
            RequireDigits();
        }

        if (Consume('.'))
        {
            RequireDigits();
        }
        if (index < text.Length && (text[index] == 'e' || text[index] == 'E'))
        {
            index++;
            if (index < text.Length && (text[index] == '+' || text[index] == '-'))
            {
                index++;
            }
            RequireDigits();
        }
        if (index == start)
        {
            throw new FormatException();
        }
    }

    private void RequireDigits()
    {
        int start = index;
        while (index < text.Length && Char.IsDigit(text[index]))
        {
            index++;
        }
        if (index == start)
        {
            throw new FormatException();
        }
    }

    private void ParseLiteral(string literal)
    {
        if (
            index + literal.Length > text.Length ||
            !String.Equals(
                text.Substring(index, literal.Length),
                literal,
                StringComparison.Ordinal
            )
        )
        {
            throw new FormatException();
        }
        index += literal.Length;
    }

    private bool Consume(char expected)
    {
        if (index < text.Length && text[index] == expected)
        {
            index++;
            return true;
        }
        return false;
    }

    private void Require(char expected)
    {
        if (!Consume(expected))
        {
            throw new FormatException();
        }
    }

    private void SkipWhitespace()
    {
        while (
            index < text.Length &&
            (text[index] == ' ' || text[index] == '\t' ||
             text[index] == '\r' || text[index] == '\n')
        )
        {
            index++;
        }
    }
}
'@
}

function Assert-ManagedCredentialName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($Name -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
        throw 'Credential name is invalid.'
    }
}

function Test-ManagedCredentialNameEqual {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Left,

        [Parameter(Mandatory = $true)]
        [string]$Right
    )

    return [string]::Equals(
        $Left,
        $Right,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function Resolve-CredentialStorePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StorePath
    )

    if ([string]::IsNullOrWhiteSpace($StorePath)) {
        throw 'Credential store path is invalid.'
    }

    return [IO.Path]::GetFullPath($StorePath)
}

function Protect-CredentialStoreDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StorePath
    )

    try {
        $directory = [ManagedCredentialPathRuntime]::GetFinalDirectoryPath(
            (Split-Path -Parent $StorePath)
        )
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            New-Item -ItemType Directory -Path $directory -Force `
                -ErrorAction Stop | Out-Null
        }

        $currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User
        $systemSid = New-Object Security.Principal.SecurityIdentifier('S-1-5-18')
        $inheritance = (
            [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
            [Security.AccessControl.InheritanceFlags]::ObjectInherit
        )
        $security = [IO.Directory]::GetAccessControl(
            $directory,
            [Security.AccessControl.AccessControlSections]::Access
        )
        $security.SetAccessRuleProtection($true, $false)
        $existingRules = @($security.GetAccessRules(
            $true,
            $false,
            [Security.Principal.SecurityIdentifier]
        ))
        foreach ($existingSid in @(
            $existingRules |
                ForEach-Object { $_.IdentityReference.Value } |
                Select-Object -Unique
        )) {
            $security.PurgeAccessRules(
                (New-Object Security.Principal.SecurityIdentifier($existingSid))
            )
        }
        foreach ($sid in @($currentSid, $systemSid)) {
            $rule = New-Object Security.AccessControl.FileSystemAccessRule(
                $sid,
                [Security.AccessControl.FileSystemRights]::FullControl,
                $inheritance,
                [Security.AccessControl.PropagationFlags]::None,
                [Security.AccessControl.AccessControlType]::Allow
            )
            $security.AddAccessRule($rule)
        }
        [IO.Directory]::SetAccessControl($directory, $security)

        $verified = [IO.Directory]::GetAccessControl(
            $directory,
            [Security.AccessControl.AccessControlSections]::Access
        )
        if (-not $verified.AreAccessRulesProtected) {
            throw 'invalid'
        }
        $rules = @($verified.GetAccessRules(
            $true,
            $true,
            [Security.Principal.SecurityIdentifier]
        ))
        if ($rules.Count -ne 2) {
            throw 'invalid'
        }
        foreach ($sid in @($currentSid, $systemSid)) {
            $matchingRules = @($rules | Where-Object {
                $_.IdentityReference -eq $sid -and
                $_.AccessControlType -eq (
                    [Security.AccessControl.AccessControlType]::Allow
                ) -and
                $_.FileSystemRights -eq (
                    [Security.AccessControl.FileSystemRights]::FullControl
                ) -and
                $_.InheritanceFlags -eq $inheritance -and
                $_.PropagationFlags -eq (
                    [Security.AccessControl.PropagationFlags]::None
                ) -and
                -not $_.IsInherited
            })
            if ($matchingRules.Count -ne 1) {
                throw 'invalid'
            }
        }
    }
    catch {
        throw 'Credential store directory permissions could not be secured.'
    }
}

function Assert-CredentialStoreDirectorySecure {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StorePath
    )

    try {
        $directory = [ManagedCredentialPathRuntime]::GetFinalDirectoryPath(
            (Split-Path -Parent $StorePath)
        )
        $currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User
        $systemSid = New-Object Security.Principal.SecurityIdentifier('S-1-5-18')
        $security = [IO.Directory]::GetAccessControl(
            $directory,
            [Security.AccessControl.AccessControlSections]::Access
        )
        if (-not $security.AreAccessRulesProtected) {
            throw 'invalid'
        }

        $rules = @($security.GetAccessRules(
            $true,
            $true,
            [Security.Principal.SecurityIdentifier]
        ))
        if (@($rules | Where-Object { $_.IsInherited }).Count -ne 0) {
            throw 'invalid'
        }
        if (@($rules | Where-Object {
            $_.AccessControlType -eq (
                [Security.AccessControl.AccessControlType]::Allow
            ) -and
            $_.IdentityReference -ne $currentSid -and
            $_.IdentityReference -ne $systemSid
        }).Count -ne 0) {
            throw 'invalid'
        }
        if (@($rules | Where-Object {
            $_.AccessControlType -eq (
                [Security.AccessControl.AccessControlType]::Deny
            ) -and (
                $_.IdentityReference -eq $currentSid -or
                $_.IdentityReference -eq $systemSid
            )
        }).Count -ne 0) {
            throw 'invalid'
        }
        foreach ($sid in @($currentSid, $systemSid)) {
            $fullControlRules = @($rules | Where-Object {
                $_.AccessControlType -eq (
                    [Security.AccessControl.AccessControlType]::Allow
                ) -and
                $_.IdentityReference -eq $sid -and
                ($_.FileSystemRights -band (
                    [Security.AccessControl.FileSystemRights]::FullControl
                )) -eq (
                    [Security.AccessControl.FileSystemRights]::FullControl
                )
            })
            if ($fullControlRules.Count -eq 0) {
                throw 'invalid'
            }
        }
    }
    catch {
        throw 'Credential store directory permissions could not be secured.'
    }
}

function Protect-CredentialStoreFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User
        $systemSid = New-Object Security.Principal.SecurityIdentifier('S-1-5-18')
        $security = New-Object Security.AccessControl.FileSecurity
        $security.SetAccessRuleProtection($true, $false)
        foreach ($sid in @($currentSid, $systemSid)) {
            $rule = New-Object Security.AccessControl.FileSystemAccessRule(
                $sid,
                [Security.AccessControl.FileSystemRights]::FullControl,
                [Security.AccessControl.AccessControlType]::Allow
            )
            $security.AddAccessRule($rule)
        }
        [IO.File]::SetAccessControl($Path, $security)

        $verified = [IO.File]::GetAccessControl(
            $Path,
            [Security.AccessControl.AccessControlSections]::Access
        )
        $rules = @($verified.GetAccessRules(
            $true,
            $true,
            [Security.Principal.SecurityIdentifier]
        ))
        if (-not $verified.AreAccessRulesProtected -or $rules.Count -ne 2) {
            throw 'invalid'
        }
        foreach ($sid in @($currentSid, $systemSid)) {
            if (@($rules | Where-Object {
                $_.IdentityReference -eq $sid -and
                $_.AccessControlType -eq (
                    [Security.AccessControl.AccessControlType]::Allow
                ) -and
                $_.FileSystemRights -eq (
                    [Security.AccessControl.FileSystemRights]::FullControl
                ) -and
                -not $_.IsInherited
            }).Count -ne 1) {
                throw 'invalid'
            }
        }
    }
    catch {
        throw 'Credential store file permissions could not be secured.'
    }
}

function Initialize-CredentialStoreDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StorePath
    )

    try {
        $directory = Split-Path -Parent $StorePath
        $created = $false
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            if (Test-Path -LiteralPath $directory) {
                throw 'invalid'
            }
            New-Item -ItemType Directory -Path $directory -Force `
                -ErrorAction Stop | Out-Null
            $created = $true
        }
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            throw 'invalid'
        }
        return $created
    }
    catch {
        throw 'Credential store directory permissions could not be secured.'
    }
}

function Invoke-WithCredentialStoreLock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StorePath,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    $directoryCreated = Initialize-CredentialStoreDirectory -StorePath $StorePath
    if ($directoryCreated) {
        Protect-CredentialStoreDirectory -StorePath $StorePath
    }
    else {
        Assert-CredentialStoreDirectorySecure -StorePath $StorePath
    }

    $lockPath = $StorePath + '.lock'
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    $lockStream = $null
    try {
        while ($null -eq $lockStream) {
            try {
                $lockStream = [IO.File]::Open(
                    $lockPath,
                    [IO.FileMode]::OpenOrCreate,
                    [IO.FileAccess]::ReadWrite,
                    [IO.FileShare]::None
                )
            }
            catch [IO.IOException] {
                if ([DateTime]::UtcNow -ge $deadline) {
                    throw 'Credential store is busy.'
                }
                Start-Sleep -Milliseconds 50
            }
            catch [UnauthorizedAccessException] {
                throw 'Credential store directory permissions could not be secured.'
            }
        }

        Assert-CredentialStoreDirectorySecure -StorePath $StorePath
        Protect-CredentialStoreFile -Path $lockPath
        if (Test-Path -LiteralPath $StorePath -PathType Leaf) {
            Protect-CredentialStoreFile -Path $StorePath
        }
        return & $Action
    }
    finally {
        if ($null -ne $lockStream) {
            $lockStream.Dispose()
        }
    }
}

function Test-CredentialStorePropertySet {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string[]]$Expected
    )

    $actual = @($InputObject.PSObject.Properties.Name)
    if ($actual.Count -ne $Expected.Count) {
        return $false
    }

    foreach ($propertyName in $Expected) {
        $matches = @($actual | Where-Object {
            [string]::Equals(
                $_,
                $propertyName,
                [StringComparison]::Ordinal
            )
        })
        if ($matches.Count -ne 1) {
            return $false
        }
    }

    return $true
}

function New-EmptyCredentialStore {
    return [pscustomobject][ordered]@{
        schema_version = $script:CredentialStoreSchemaVersion
        credentials = @()
    }
}

function ConvertFrom-CredentialStoreTimestamp {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $parsed = [DateTime]::MinValue
    $styles = (
        [Globalization.DateTimeStyles]::AssumeUniversal -bor
        [Globalization.DateTimeStyles]::AdjustToUniversal
    )
    if (-not [DateTime]::TryParseExact(
        $Value,
        'yyyy-MM-ddTHH:mm:ss.fffffffZ',
        [Globalization.CultureInfo]::InvariantCulture,
        $styles,
        [ref]$parsed
    )) {
        throw 'invalid'
    }
    return $parsed
}

function Read-CredentialStore {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StorePath
    )

    if (-not (Test-Path -LiteralPath $StorePath -PathType Leaf)) {
        return New-EmptyCredentialStore
    }

    try {
        $json = [IO.File]::ReadAllText($StorePath)
        if ([ManagedCredentialJsonRuntime]::HasDuplicateProperties($json)) {
            throw 'invalid'
        }
        $document = $json | ConvertFrom-Json
        if ($null -eq $document -or $document -isnot [pscustomobject]) {
            throw 'invalid'
        }
        if (-not (Test-CredentialStorePropertySet -InputObject $document -Expected @(
            'schema_version', 'credentials'
        ))) {
            throw 'invalid'
        }
        if (
            $document.schema_version -isnot [string] -or
            -not [string]::Equals(
                $document.schema_version,
                $script:CredentialStoreSchemaVersion,
                [StringComparison]::Ordinal
            )
        ) {
            throw 'invalid'
        }
        if ($document.credentials -isnot [array]) {
            throw 'invalid'
        }

        $seenNames = New-Object 'Collections.Generic.HashSet[string]' (
            [StringComparer]::OrdinalIgnoreCase
        )
        foreach ($credential in @($document.credentials)) {
            if (
                $null -eq $credential -or
                $credential -isnot [pscustomobject] -or
                -not (
                Test-CredentialStorePropertySet -InputObject $credential -Expected @(
                    'name', 'ciphertext', 'created_at', 'updated_at'
                )
            )) {
                throw 'invalid'
            }
            foreach ($propertyName in @(
                'name', 'ciphertext', 'created_at', 'updated_at'
            )) {
                $value = $credential.PSObject.Properties[$propertyName].Value
                if (
                    $value -isnot [string] -or
                    [string]::IsNullOrWhiteSpace($value)
                ) {
                    throw 'invalid'
                }
            }
            Assert-ManagedCredentialName -Name $credential.name
            if (-not $seenNames.Add($credential.name)) {
                throw 'invalid'
            }
            [void][Convert]::FromBase64String($credential.ciphertext)
            $createdAt = ConvertFrom-CredentialStoreTimestamp `
                -Value $credential.created_at
            $updatedAt = ConvertFrom-CredentialStoreTimestamp `
                -Value $credential.updated_at
            if ($createdAt -gt $updatedAt) {
                throw 'invalid'
            }
        }

        $document.credentials = @($document.credentials)
        return $document
    }
    catch {
        throw 'Credential store is invalid.'
    }
}

function Write-CredentialStore {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StorePath,

        [Parameter(Mandatory = $true)]
        [object]$Document
    )

    $directory = Split-Path -Parent $StorePath
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -ItemType Directory -Path $directory -Force -ErrorAction Stop |
            Out-Null
    }

    $temporaryPath = Join-Path $directory (
        ([IO.Path]::GetFileName($StorePath)) + '.tmp-' +
        [Guid]::NewGuid().ToString('N')
    )
    $backupPath = Join-Path $directory (
        ([IO.Path]::GetFileName($StorePath)) + '.bak-' +
        [Guid]::NewGuid().ToString('N')
    )
    $utf8WithoutBom = New-Object Text.UTF8Encoding($false)
    try {
        $json = $Document | ConvertTo-Json -Depth 4
        [IO.File]::WriteAllText($temporaryPath, $json, $utf8WithoutBom)
        if (Test-Path -LiteralPath $StorePath -PathType Leaf) {
            [IO.File]::Replace($temporaryPath, $StorePath, $backupPath, $true)
        }
        else {
            [IO.File]::Move($temporaryPath, $StorePath)
        }
        Protect-CredentialStoreFile -Path $StorePath
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
        if (Test-Path -LiteralPath $backupPath -PathType Leaf) {
            Remove-Item -LiteralPath $backupPath -Force
        }
    }
}

function Protect-ManagedSecureString {
    param(
        [Parameter(Mandatory = $true)]
        [Security.SecureString]$Secret
    )

    $bstr = [IntPtr]::Zero
    $plainBytes = $null
    $protectedBytes = $null
    try {
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret)
        $byteCount = [Runtime.InteropServices.Marshal]::ReadInt32(
            [IntPtr]::Subtract($bstr, 4)
        )
        $plainBytes = New-Object byte[] $byteCount
        [Runtime.InteropServices.Marshal]::Copy(
            $bstr,
            $plainBytes,
            0,
            $byteCount
        )
        $protectedBytes = [Security.Cryptography.ProtectedData]::Protect(
            $plainBytes,
            $null,
            [Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        return [Convert]::ToBase64String($protectedBytes)
    }
    finally {
        if ($null -ne $plainBytes) {
            [Array]::Clear($plainBytes, 0, $plainBytes.Length)
        }
        if ($null -ne $protectedBytes) {
            [Array]::Clear($protectedBytes, 0, $protectedBytes.Length)
        }
        if ($bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

function Unprotect-ManagedSecureString {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Ciphertext
    )

    $protectedBytes = $null
    $plainBytes = $null
    try {
        $protectedBytes = [Convert]::FromBase64String($Ciphertext)
        $plainBytes = [Security.Cryptography.ProtectedData]::Unprotect(
            $protectedBytes,
            $null,
            [Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        if (($plainBytes.Length % 2) -ne 0) {
            throw 'invalid'
        }

        $secret = New-Object Security.SecureString
        for ($index = 0; $index -lt $plainBytes.Length; $index += 2) {
            $character = [char](
                $plainBytes[$index] -bor ($plainBytes[$index + 1] -shl 8)
            )
            $secret.AppendChar($character)
        }
        $secret.MakeReadOnly()
        return $secret
    }
    catch {
        throw 'Managed credential could not be decrypted.'
    }
    finally {
        if ($null -ne $protectedBytes) {
            [Array]::Clear($protectedBytes, 0, $protectedBytes.Length)
        }
        if ($null -ne $plainBytes) {
            [Array]::Clear($plainBytes, 0, $plainBytes.Length)
        }
    }
}

function Set-ManagedCredential {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [Security.SecureString]$Secret,

        [string]$StorePath = $script:DefaultCredentialStorePath
    )

    Assert-ManagedCredentialName -Name $Name
    $resolvedPath = Resolve-CredentialStorePath -StorePath $StorePath
    $ciphertext = Protect-ManagedSecureString -Secret $Secret

    Invoke-WithCredentialStoreLock -StorePath $resolvedPath -Action {
        $document = Read-CredentialStore -StorePath $resolvedPath
        $now = [DateTime]::UtcNow.ToString(
            'o',
            [Globalization.CultureInfo]::InvariantCulture
        )
        $existing = @($document.credentials | Where-Object {
            Test-ManagedCredentialNameEqual -Left $_.name -Right $Name
        })
        if ($existing.Count -eq 1) {
            $existing[0].ciphertext = $ciphertext
            $existing[0].updated_at = $now
        }
        else {
            $document.credentials += [pscustomobject][ordered]@{
                name = $Name
                ciphertext = $ciphertext
                created_at = $now
                updated_at = $now
            }
        }
        Write-CredentialStore -StorePath $resolvedPath -Document $document
    }
}

function Get-ManagedCredential {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$StorePath = $script:DefaultCredentialStorePath
    )

    Assert-ManagedCredentialName -Name $Name
    $resolvedPath = Resolve-CredentialStorePath -StorePath $StorePath
    return Invoke-WithCredentialStoreLock -StorePath $resolvedPath -Action {
        $document = Read-CredentialStore -StorePath $resolvedPath
        $matches = @($document.credentials | Where-Object {
            Test-ManagedCredentialNameEqual -Left $_.name -Right $Name
        })
        if ($matches.Count -eq 0) {
            throw 'Managed credential was not found.'
        }

        return Unprotect-ManagedSecureString -Ciphertext $matches[0].ciphertext
    }
}

function Remove-ManagedCredential {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$StorePath = $script:DefaultCredentialStorePath
    )

    Assert-ManagedCredentialName -Name $Name
    $resolvedPath = Resolve-CredentialStorePath -StorePath $StorePath
    return Invoke-WithCredentialStoreLock -StorePath $resolvedPath -Action {
        $document = Read-CredentialStore -StorePath $resolvedPath
        $remaining = @($document.credentials | Where-Object {
            -not (Test-ManagedCredentialNameEqual -Left $_.name -Right $Name)
        })
        if ($remaining.Count -eq @($document.credentials).Count) {
            return $false
        }

        $document.credentials = $remaining
        Write-CredentialStore -StorePath $resolvedPath -Document $document
        return $true
    }
}

function Get-ManagedCredentialMetadata {
    [CmdletBinding()]
    param(
        [string]$StorePath = $script:DefaultCredentialStorePath
    )

    $resolvedPath = Resolve-CredentialStorePath -StorePath $StorePath
    return Invoke-WithCredentialStoreLock -StorePath $resolvedPath -Action {
        $document = Read-CredentialStore -StorePath $resolvedPath
        return @($document.credentials | ForEach-Object {
            [pscustomobject][ordered]@{
                Name = $_.name
                CreatedAt = ConvertFrom-CredentialStoreTimestamp `
                    -Value $_.created_at
                UpdatedAt = ConvertFrom-CredentialStoreTimestamp `
                    -Value $_.updated_at
            }
        })
    }
}
