$script:ChangeJournalSchema = 'codex.change-journal'
$script:ChangeJournalVersion = 2

Add-Type -AssemblyName System.Security

if (-not ('ChangeJournalRuntime' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

public static class ChangeJournalRuntime
{
    private const uint GenericRead = 0x80000000;
    private const uint FileReadAttributes = 0x80;
    private const uint ShareRead = 0x1;
    private const uint ShareWrite = 0x2;
    private const uint ShareDelete = 0x4;
    private const uint OpenExisting = 3;
    private const uint BackupSemantics = 0x02000000;

    [StructLayout(LayoutKind.Sequential)]
    private struct ByHandleFileInformation
    {
        public uint FileAttributes;
        public System.Runtime.InteropServices.ComTypes.FILETIME CreationTime;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastAccessTime;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWriteTime;
        public uint VolumeSerialNumber;
        public uint FileSizeHigh;
        public uint FileSizeLow;
        public uint NumberOfLinks;
        public uint FileIndexHigh;
        public uint FileIndexLow;
    }

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

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetFileInformationByHandle(
        SafeFileHandle file,
        out ByHandleFileInformation information
    );

    public static string[] GetIdentity(string path)
    {
        using (SafeFileHandle handle = CreateFile(
            path,
            FileReadAttributes,
            ShareRead | ShareWrite | ShareDelete,
            IntPtr.Zero,
            OpenExisting,
            BackupSemantics,
            IntPtr.Zero
        ))
        {
            if (handle.IsInvalid)
            {
                throw new IOException(
                    "Unable to open path for identity.",
                    Marshal.GetExceptionForHR(Marshal.GetHRForLastWin32Error())
                );
            }
            ByHandleFileInformation information;
            if (!GetFileInformationByHandle(handle, out information))
            {
                throw new IOException(
                    "Unable to read path identity.",
                    Marshal.GetExceptionForHR(Marshal.GetHRForLastWin32Error())
                );
            }
            return new string[] {
                information.VolumeSerialNumber.ToString("x8"),
                information.FileIndexHigh.ToString("x8") +
                    information.FileIndexLow.ToString("x8")
            };
        }
    }
}

public sealed class ChangeJournalJsonScanner
{
    private readonly string text;
    private int index;
    private bool duplicateFound;

    private ChangeJournalJsonScanner(string json)
    {
        if (json == null) throw new ArgumentNullException("json");
        text = json;
    }

    public static bool HasDuplicateProperties(string json)
    {
        ChangeJournalJsonScanner parser = new ChangeJournalJsonScanner(json);
        parser.ParseValue();
        parser.SkipWhitespace();
        if (parser.index != parser.text.Length) throw new FormatException();
        return parser.duplicateFound;
    }

    private void ParseValue()
    {
        SkipWhitespace();
        if (index >= text.Length) throw new FormatException();
        switch (text[index])
        {
            case '{': ParseObject(); return;
            case '[': ParseArray(); return;
            case '"': ParseString(); return;
            case 't': ParseLiteral("true"); return;
            case 'f': ParseLiteral("false"); return;
            case 'n': ParseLiteral("null"); return;
            default: ParseNumber(); return;
        }
    }

    private void ParseObject()
    {
        index++;
        SkipWhitespace();
        HashSet<string> names = new HashSet<string>(StringComparer.Ordinal);
        if (Consume('}')) return;
        while (true)
        {
            SkipWhitespace();
            string name = ParseString();
            if (!names.Add(name)) duplicateFound = true;
            SkipWhitespace();
            Require(':');
            ParseValue();
            SkipWhitespace();
            if (Consume('}')) return;
            Require(',');
        }
    }

    private void ParseArray()
    {
        index++;
        SkipWhitespace();
        if (Consume(']')) return;
        while (true)
        {
            ParseValue();
            SkipWhitespace();
            if (Consume(']')) return;
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
            if (character == '"') return value.ToString();
            if (character < 0x20) throw new FormatException();
            if (character != '\\')
            {
                value.Append(character);
                continue;
            }
            if (index >= text.Length) throw new FormatException();
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
                    if (index + 4 > text.Length) throw new FormatException();
                    int code;
                    if (!Int32.TryParse(
                        text.Substring(index, 4),
                        System.Globalization.NumberStyles.HexNumber,
                        System.Globalization.CultureInfo.InvariantCulture,
                        out code
                    )) throw new FormatException();
                    value.Append((char)code);
                    index += 4;
                    break;
                default: throw new FormatException();
            }
        }
        throw new FormatException();
    }

    private void ParseLiteral(string literal)
    {
        if (index + literal.Length > text.Length ||
            String.CompareOrdinal(text, index, literal, 0, literal.Length) != 0)
            throw new FormatException();
        index += literal.Length;
    }

    private void ParseNumber()
    {
        int start = index;
        Consume('-');
        if (Consume('0'))
        {
        }
        else
        {
            RequireDigit();
            while (index < text.Length && Char.IsDigit(text[index])) index++;
        }
        if (Consume('.'))
        {
            RequireDigit();
            while (index < text.Length && Char.IsDigit(text[index])) index++;
        }
        if (index < text.Length && (text[index] == 'e' || text[index] == 'E'))
        {
            index++;
            if (index < text.Length && (text[index] == '+' || text[index] == '-'))
                index++;
            RequireDigit();
            while (index < text.Length && Char.IsDigit(text[index])) index++;
        }
        if (index == start) throw new FormatException();
    }

    private void RequireDigit()
    {
        if (index >= text.Length || !Char.IsDigit(text[index]))
            throw new FormatException();
        index++;
    }

    private void SkipWhitespace()
    {
        while (index < text.Length)
        {
            char character = text[index];
            if (character != ' ' && character != '\t' &&
                character != '\r' && character != '\n') return;
            index++;
        }
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
        if (!Consume(expected)) throw new FormatException();
    }
}
'@
}

function Get-ChangeJournalWorkspaceRoot {
    $root = & git -C ([Environment]::CurrentDirectory) rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace("$root")) {
        return [IO.Path]::GetFullPath("$root").TrimEnd('\', '/')
    }
    return [IO.Path]::GetFullPath([Environment]::CurrentDirectory).TrimEnd('\', '/')
}

function Get-ChangeJournalDefaultRoots {
    $codexRoot = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex'
    return @(
        [IO.Path]::GetFullPath((Get-ChangeJournalWorkspaceRoot)).TrimEnd('\', '/'),
        [IO.Path]::GetFullPath($codexRoot).TrimEnd('\', '/')
    )
}

function Assert-NoParentTraversal {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (($Path -split '[\\/]') -contains '..') {
        throw "Path contains a parent traversal segment: $Path"
    }
}

function Get-LexicalJournalPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$RejectParentTraversal
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'Path must not be empty.'
    }
    if ($RejectParentTraversal) {
        Assert-NoParentTraversal -Path $Path
    }
    return [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Test-PathWithinRoot {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root
    )

    if ($Path.Equals($Root, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    return $Path.StartsWith(
        $Root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function ConvertTo-LexicalRootList {
    param([AllowNull()][object[]]$Roots = @())

    return @(
        $Roots |
            Where-Object { -not [string]::IsNullOrWhiteSpace("$_") } |
            ForEach-Object { Get-LexicalJournalPath -Path "$_" } |
            Sort-Object -Unique |
            Sort-Object -Property @{ Expression = { $_.Length }; Descending = $true }
    )
}

function Get-TrustedJournalRoots {
    param([AllowNull()][string[]]$AllowedRoots = @())

    return ConvertTo-LexicalRootList -Roots (
        @(Get-ChangeJournalDefaultRoots) + @($AllowedRoots)
    )
}

function Get-MatchingJournalRoot {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Roots
    )

    foreach ($root in $Roots) {
        if (Test-PathWithinRoot -Path $Path -Root $root) {
            return $root
        }
    }
    return $null
}

function Assert-NoReparsePath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root
    )

    $relative = $Path.Substring($Root.Length).TrimStart('\', '/')
    $cursor = $Root
    $paths = @($cursor)
    if (-not [string]::IsNullOrEmpty($relative)) {
        foreach ($segment in ($relative -split '[\\/]')) {
            $cursor = Join-Path $cursor $segment
            $paths += $cursor
        }
    }
    foreach ($candidate in $paths) {
        if (Test-Path -LiteralPath $candidate) {
            $attributes = [IO.File]::GetAttributes($candidate)
            if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Path contains a reparse point: $candidate"
            }
        }
    }
}

function Assert-ManagedJournalPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$AllowedRoots,
        [switch]$RejectRoot
    )

    $lexical = Get-LexicalJournalPath -Path $Path -RejectParentTraversal
    $roots = ConvertTo-LexicalRootList -Roots $AllowedRoots
    $root = Get-MatchingJournalRoot -Path $lexical -Roots $roots
    if ($null -eq $root) {
        throw "Path is outside every allowed root: $Path"
    }
    if ($RejectRoot) {
        foreach ($candidate in $roots) {
            if ($lexical.Equals($candidate, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Refusing to register an allowed root for recursive deletion: $Path"
            }
        }
    }
    Assert-NoReparsePath -Path $lexical -Root $root
    return $lexical
}

function Test-ExactPropertySet {
    param(
        [Parameter(Mandatory = $true)][object]$Object,
        [Parameter(Mandatory = $true)][string[]]$Expected
    )

    if ($Object -isnot [pscustomobject]) {
        return $false
    }
    $actual = @($Object.PSObject.Properties.Name)
    if ($actual.Count -ne $Expected.Count) {
        return $false
    }
    foreach ($name in $Expected) {
        if ($actual -cnotcontains $name) {
            return $false
        }
    }
    return $true
}

function Assert-JournalTimestamp {
    param(
        [AllowNull()][object]$Value,
        [Parameter(Mandatory = $true)][string]$Name,
        [switch]$AllowNull
    )

    if ($AllowNull -and $null -eq $Value) {
        return
    }
    if ($Value -isnot [string]) {
        throw "Change journal $Name type is invalid."
    }
    $parsed = [DateTime]::MinValue
    if (-not [DateTime]::TryParseExact(
        $Value,
        'yyyy-MM-ddTHH:mm:ss.fffffffZ',
        [Globalization.CultureInfo]::InvariantCulture,
        (
            [Globalization.DateTimeStyles]::AssumeUniversal -bor
            [Globalization.DateTimeStyles]::AdjustToUniversal
        ),
        [ref]$parsed
    )) {
        throw "Change journal $Name is invalid."
    }
}

function Assert-JournalIdentity {
    param(
        [AllowNull()][object]$Identity,
        [switch]$AllowNull
    )

    if ($AllowNull -and $null -eq $Identity) {
        return
    }
    if (-not (Test-ExactPropertySet -Object $Identity -Expected @(
        'VolumeSerial', 'FileId'
    ))) {
        throw 'Change journal identity schema is invalid.'
    }
    if (
        $Identity.VolumeSerial -isnot [string] -or
        $Identity.VolumeSerial -cnotmatch '^[0-9a-f]{8}$' -or
        $Identity.FileId -isnot [string] -or
        $Identity.FileId -cnotmatch '^[0-9a-f]{16}$'
    ) {
        throw 'Change journal identity type is invalid.'
    }
}

function Assert-ChangeJournalEntry {
    param([Parameter(Mandatory = $true)][object]$Entry)

    if ($Entry -isnot [pscustomobject] -or $Entry.Type -isnot [string]) {
        throw 'Change journal entry type is invalid.'
    }
    if ($Entry.Type -ceq 'external') {
        if (-not (Test-ExactPropertySet -Object $Entry -Expected @(
            'Id', 'Type', 'Description', 'RollbackCommand', 'RecordedAtUtc',
            'RolledBack', 'RolledBackAtUtc'
        ))) {
            throw 'Change journal external entry has unknown or missing properties.'
        }
        if (
            $Entry.Id -isnot [string] -or
            $Entry.Id -cnotmatch '^[0-9a-f]{32}$' -or
            $Entry.Description -isnot [string] -or
            [string]::IsNullOrWhiteSpace($Entry.Description) -or
            $Entry.RollbackCommand -isnot [string] -or
            $Entry.RolledBack -isnot [bool]
        ) {
            throw 'Change journal external entry type is invalid.'
        }
    }
    elseif ($Entry.Type -ceq 'file') {
        if (-not (Test-ExactPropertySet -Object $Entry -Expected @(
            'Id', 'Type', 'Kind', 'Path', 'BackupPath', 'BackupSha256',
            'Metadata', 'OriginalIdentity', 'Confirmed', 'ConfirmedIdentity',
            'RecordedAtUtc', 'RolledBack', 'RolledBackAtUtc'
        ))) {
            throw 'Change journal file entry has unknown or missing properties.'
        }
        if (
            $Entry.Id -isnot [string] -or
            $Entry.Id -cnotmatch '^[0-9a-f]{32}$' -or
            $Entry.Kind -isnot [string] -or
            $Entry.Kind -cnotin @('create', 'modify', 'delete', 'directory_create') -or
            $Entry.Path -isnot [string] -or
            -not [IO.Path]::IsPathRooted($Entry.Path) -or
            $Entry.Confirmed -isnot [bool] -or
            $Entry.RolledBack -isnot [bool]
        ) {
            throw 'Change journal file entry type is invalid.'
        }
        if ($Entry.Kind -cin @('modify', 'delete')) {
            if (
                $Entry.BackupPath -isnot [string] -or
                $Entry.BackupSha256 -isnot [string] -or
                $Entry.BackupSha256 -cnotmatch '^[0-9a-f]{64}$' -or
                -not (Test-ExactPropertySet -Object $Entry.Metadata -Expected @(
                    'Attributes', 'CreationTimeUtc', 'LastWriteTimeUtc',
                    'LastAccessTimeUtc'
                ))
            ) {
                throw 'Change journal file entry backup schema is invalid.'
            }
            if ($Entry.Metadata.Attributes -isnot [int]) {
                throw 'Change journal file entry metadata type is invalid.'
            }
            Assert-JournalIdentity -Identity $Entry.OriginalIdentity
        }
        else {
            if (
                $null -ne $Entry.BackupPath -or
                $null -ne $Entry.BackupSha256 -or
                $null -ne $Entry.Metadata -or
                $null -ne $Entry.OriginalIdentity
            ) {
                throw 'Change journal create entry backup fields must be null.'
            }
        }
        Assert-JournalIdentity -Identity $Entry.ConfirmedIdentity -AllowNull
        if ($Entry.Confirmed -and $null -eq $Entry.ConfirmedIdentity) {
            throw 'Change journal confirmed entry identity is missing.'
        }
        if (-not $Entry.Confirmed -and $null -ne $Entry.ConfirmedIdentity) {
            throw 'Change journal unconfirmed entry identity must be null.'
        }
        if ($null -ne $Entry.Metadata) {
            foreach ($name in @(
                'CreationTimeUtc', 'LastWriteTimeUtc', 'LastAccessTimeUtc'
            )) {
                Assert-JournalTimestamp -Value $Entry.Metadata.$name -Name $name
            }
        }
    }
    else {
        throw 'Change journal entry Type is invalid.'
    }
    Assert-JournalTimestamp -Value $Entry.RecordedAtUtc -Name 'RecordedAtUtc'
    Assert-JournalTimestamp `
        -Value $Entry.RolledBackAtUtc `
        -Name 'RolledBackAtUtc' `
        -AllowNull
}

function Assert-ChangeJournalDocument {
    param([Parameter(Mandatory = $true)][object]$Document)

    if (-not (Test-ExactPropertySet -Object $Document -Expected @(
        'Schema', 'Version', 'OperationId', 'WorkspaceRoot',
        'JournalDirectory', 'AllowedRoots', 'CreatedAtUtc', 'UpdatedAtUtc',
        'Changes', 'Integrity'
    ))) {
        throw 'Change journal has unknown or missing properties.'
    }
    if (
        $Document.Schema -isnot [string] -or
        $Document.Schema -cne $script:ChangeJournalSchema -or
        $Document.Version -isnot [int] -or
        $Document.Version -ne $script:ChangeJournalVersion -or
        $Document.OperationId -isnot [string] -or
        $Document.OperationId -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$' -or
        $Document.WorkspaceRoot -isnot [string] -or
        $Document.JournalDirectory -isnot [string] -or
        $Document.AllowedRoots -isnot [array] -or
        $Document.Changes -isnot [array] -or
        $Document.Integrity -isnot [string]
    ) {
        throw 'Change journal schema, version, or property type is invalid.'
    }
    foreach ($root in $Document.AllowedRoots) {
        if ($root -isnot [string] -or -not [IO.Path]::IsPathRooted($root)) {
            throw 'Change journal AllowedRoots type is invalid.'
        }
    }
    Assert-JournalTimestamp -Value $Document.CreatedAtUtc -Name 'CreatedAtUtc'
    Assert-JournalTimestamp -Value $Document.UpdatedAtUtc -Name 'UpdatedAtUtc'
    foreach ($entry in $Document.Changes) {
        Assert-ChangeJournalEntry -Entry $entry
    }
}

function ConvertTo-ChangeJournalPayload {
    param([Parameter(Mandatory = $true)][object]$Document)

    return [pscustomobject][ordered]@{
        Schema = $Document.Schema
        Version = $Document.Version
        OperationId = $Document.OperationId
        WorkspaceRoot = $Document.WorkspaceRoot
        JournalDirectory = $Document.JournalDirectory
        AllowedRoots = @($Document.AllowedRoots)
        CreatedAtUtc = $Document.CreatedAtUtc
        UpdatedAtUtc = $Document.UpdatedAtUtc
        Changes = @($Document.Changes)
    }
}

function Get-ChangeJournalPayloadHash {
    param([Parameter(Mandatory = $true)][object]$Document)

    $json = ConvertTo-ChangeJournalPayload -Document $Document |
        ConvertTo-Json -Depth 20 -Compress
    $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes($json)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
        [Array]::Clear($bytes, 0, $bytes.Length)
    }
}

function Protect-ChangeJournalIntegrity {
    param([Parameter(Mandatory = $true)][byte[]]$Hash)

    $protected = $null
    try {
        $protected = [Security.Cryptography.ProtectedData]::Protect(
            $Hash,
            $null,
            [Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        return [Convert]::ToBase64String($protected)
    }
    finally {
        if ($null -ne $protected) {
            [Array]::Clear($protected, 0, $protected.Length)
        }
    }
}

function Assert-ChangeJournalIntegrity {
    param([Parameter(Mandatory = $true)][object]$Document)

    $protected = $null
    $actual = $null
    $expected = $null
    try {
        $protected = [Convert]::FromBase64String($Document.Integrity)
        $actual = [Security.Cryptography.ProtectedData]::Unprotect(
            $protected,
            $null,
            [Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        $expected = Get-ChangeJournalPayloadHash -Document $Document
        if ($actual.Length -ne $expected.Length) {
            throw 'Change journal integrity verification failed.'
        }
        $different = 0
        for ($index = 0; $index -lt $actual.Length; $index++) {
            $different = $different -bor ($actual[$index] -bxor $expected[$index])
        }
        if ($different -ne 0) {
            throw 'Change journal integrity verification failed.'
        }
    }
    catch {
        throw 'Change journal integrity verification failed.'
    }
    finally {
        foreach ($bytes in @($protected, $actual, $expected)) {
            if ($null -ne $bytes) {
                [Array]::Clear($bytes, 0, $bytes.Length)
            }
        }
    }
}

function Get-ChangeJournalLockPath {
    param([Parameter(Mandatory = $true)][string]$JournalPath)

    $operationDirectory = Split-Path -Parent $JournalPath
    $journalsDirectory = Split-Path -Parent $operationDirectory
    return Join-Path $journalsDirectory (
        (Split-Path -Leaf $operationDirectory) + '.lock'
    )
}

function Get-ChangeJournalStorageLayout {
    param([Parameter(Mandatory = $true)][string]$JournalPath)

    $journalPathValue = Get-LexicalJournalPath -Path $JournalPath -RejectParentTraversal
    if ((Split-Path -Leaf $journalPathValue) -cne 'journal.json') {
        throw 'Change journal path must end in journal.json.'
    }
    $operationDirectory = Get-LexicalJournalPath -Path (
        Split-Path -Parent $journalPathValue
    )
    $journalsDirectory = Get-LexicalJournalPath -Path (
        Split-Path -Parent $operationDirectory
    )
    if ((Split-Path -Leaf $journalsDirectory) -cne 'journals') {
        throw 'Change journal path must be inside a journals directory.'
    }
    $stateRoot = Get-LexicalJournalPath -Path (
        Split-Path -Parent $journalsDirectory
    )
    $operationId = Split-Path -Leaf $operationDirectory
    if ($operationId -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
        throw 'Change journal operation directory is invalid.'
    }
    return [pscustomobject]@{
        JournalPath = $journalPathValue
        OperationId = $operationId
        OperationDirectory = $operationDirectory
        JournalsDirectory = $journalsDirectory
        StateRoot = $stateRoot
        BackupDirectory = Join-Path $operationDirectory 'backups'
        LockPath = Join-Path $journalsDirectory "$operationId.lock"
    }
}

function Assert-StorageComponentSafe {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }
    $attributes = [IO.File]::GetAttributes($Path)
    if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Change journal storage contains a reparse point: $Path"
    }
}

function Ensure-JournalStorageDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$StateRoot,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$TrustedRoot
    )

    $stateRootValue = Get-LexicalJournalPath -Path $StateRoot
    $pathValue = Get-LexicalJournalPath -Path $Path
    if (-not (Test-PathWithinRoot -Path $pathValue -Root $stateRootValue)) {
        throw 'Journal storage directory is outside StateRoot.'
    }
    $trustedRootValue = Get-LexicalJournalPath -Path $TrustedRoot
    if (-not (Test-Path -LiteralPath $trustedRootValue -PathType Container)) {
        throw 'Trusted root must exist before creating journal storage.'
    }
    Assert-StorageComponentSafe -Path $trustedRootValue

    $relative = $pathValue.Substring($trustedRootValue.Length).TrimStart('\', '/')
    $components = @()
    $cursor = $trustedRootValue
    if (-not [string]::IsNullOrEmpty($relative)) {
        foreach ($segment in ($relative -split '[\\/]')) {
            $cursor = Join-Path $cursor $segment
            $components += $cursor
        }
    }
    foreach ($component in $components) {
        if (-not (Test-PathWithinRoot -Path $component -Root $trustedRootValue)) {
            throw 'Journal storage directory escaped its trusted root.'
        }
        $parent = Split-Path -Parent $component
        if (-not [string]::IsNullOrEmpty($parent)) {
            Assert-NoReparsePath -Path $parent -Root $TrustedRoot
        }
        Assert-StorageComponentSafe -Path $component
        if (-not (Test-Path -LiteralPath $component)) {
            [void][IO.Directory]::CreateDirectory($component)
        }
        Assert-StorageComponentSafe -Path $component
        Assert-NoReparsePath -Path $component -Root $TrustedRoot
        if (-not (Test-Path -LiteralPath $component -PathType Container)) {
            throw "Journal storage component is not a directory: $component"
        }
    }
}

function Validate-JournalStoragePath {
    param(
        [Parameter(Mandatory = $true)][string]$JournalPath,
        [Parameter(Mandatory = $true)][string[]]$TrustedRoots,
        [switch]$CreateDirectories,
        [switch]$IncludeBackupDirectory
    )

    $layout = Get-ChangeJournalStorageLayout -JournalPath $JournalPath
    $roots = ConvertTo-LexicalRootList -Roots $TrustedRoots
    $trustedRoot = Get-MatchingJournalRoot -Path $layout.StateRoot -Roots $roots
    if ($null -eq $trustedRoot) {
        throw 'Change journal StateRoot is outside every trusted allowed root.'
    }
    Assert-NoReparsePath -Path $layout.StateRoot -Root $trustedRoot

    $directories = @(
        $layout.StateRoot,
        $layout.JournalsDirectory,
        $layout.OperationDirectory
    )
    if ($IncludeBackupDirectory) {
        $directories += $layout.BackupDirectory
    }
    foreach ($directory in $directories) {
        if (-not (Test-PathWithinRoot -Path $directory -Root $layout.StateRoot)) {
            throw 'Journal internal path is outside StateRoot.'
        }
        if ($CreateDirectories) {
            Ensure-JournalStorageDirectory `
                -StateRoot $layout.StateRoot `
                -Path $directory `
                -TrustedRoot $trustedRoot
        }
        else {
            Assert-NoReparsePath -Path $directory -Root $trustedRoot
            if (
                $directory -ne $layout.BackupDirectory -and
                -not (Test-Path -LiteralPath $directory -PathType Container)
            ) {
                throw "Journal storage directory does not exist: $directory"
            }
        }
    }
    foreach ($filePath in @(
        $layout.JournalPath,
        $layout.LockPath
    )) {
        if (-not (Test-PathWithinRoot -Path $filePath -Root $layout.StateRoot)) {
            throw 'Journal internal file path is outside StateRoot.'
        }
        Assert-NoReparsePath -Path $filePath -Root $trustedRoot
        Assert-StorageComponentSafe -Path $filePath
    }
    return $layout
}

function Invoke-WithChangeJournalLock {
    param(
        [Parameter(Mandatory = $true)][string]$JournalPath,
        [Parameter(Mandatory = $true)][string[]]$TrustedRoots,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    $layout = Validate-JournalStoragePath `
        -JournalPath $JournalPath `
        -TrustedRoots $TrustedRoots
    $lockPath = $layout.LockPath
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    $stream = $null
    try {
        while ($null -eq $stream) {
            try {
                [void](Validate-JournalStoragePath `
                    -JournalPath $JournalPath `
                    -TrustedRoots $TrustedRoots)
                $stream = [IO.File]::Open(
                    $lockPath,
                    [IO.FileMode]::OpenOrCreate,
                    [IO.FileAccess]::ReadWrite,
                    [IO.FileShare]::None
                )
            }
            catch [IO.IOException] {
                if ([DateTime]::UtcNow -ge $deadline) {
                    throw 'Change journal is busy.'
                }
                Start-Sleep -Milliseconds 25
            }
        }
        [void](Validate-JournalStoragePath `
            -JournalPath $JournalPath `
            -TrustedRoots $TrustedRoots)
        return & $Action
    }
    finally {
        if ($null -ne $stream) {
            $stream.Dispose()
        }
    }
}

function Write-DurableFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][byte[]]$Bytes
    )

    $stream = New-Object IO.FileStream -ArgumentList @(
        $Path,
        [IO.FileMode]::CreateNew,
        [IO.FileAccess]::Write,
        [IO.FileShare]::None,
        4096,
        [IO.FileOptions]::WriteThrough
    )
    try {
        $stream.Write($Bytes, 0, $Bytes.Length)
        $stream.Flush($true)
    }
    finally {
        $stream.Dispose()
    }
}

function Write-ChangeJournalDocument {
    param(
        [Parameter(Mandatory = $true)][object]$Document,
        [Parameter(Mandatory = $true)][string]$JournalPath,
        [Parameter(Mandatory = $true)][string[]]$TrustedRoots
    )

    $Document.UpdatedAtUtc = [DateTime]::UtcNow.ToString('o')
    $hash = Get-ChangeJournalPayloadHash -Document $Document
    try {
        $Document.Integrity = Protect-ChangeJournalIntegrity -Hash $hash
    }
    finally {
        [Array]::Clear($hash, 0, $hash.Length)
    }
    $directory = Split-Path -Parent $JournalPath
    [void](Validate-JournalStoragePath `
        -JournalPath $JournalPath `
        -TrustedRoots $TrustedRoots)
    $temporaryPath = Join-Path $directory (
        'journal.json.tmp-' + [Guid]::NewGuid().ToString('N')
    )
    $backupPath = Join-Path $directory (
        'journal.json.bak-' + [Guid]::NewGuid().ToString('N')
    )
    $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes(
        ($Document | ConvertTo-Json -Depth 20)
    )
    try {
        [void](Validate-JournalStoragePath `
            -JournalPath $JournalPath `
            -TrustedRoots $TrustedRoots)
        Write-DurableFile -Path $temporaryPath -Bytes $bytes
        [void](Validate-JournalStoragePath `
            -JournalPath $JournalPath `
            -TrustedRoots $TrustedRoots)
        if (Test-Path -LiteralPath $JournalPath -PathType Leaf) {
            [IO.File]::Replace($temporaryPath, $JournalPath, $backupPath, $true)
        }
        else {
            [IO.File]::Move($temporaryPath, $JournalPath)
        }
    }
    finally {
        [Array]::Clear($bytes, 0, $bytes.Length)
        foreach ($artifact in @($temporaryPath, $backupPath)) {
            if (Test-Path -LiteralPath $artifact -PathType Leaf) {
                Remove-Item -LiteralPath $artifact -Force
            }
        }
    }
}

function Read-ChangeJournalDocument {
    param(
        [Parameter(Mandatory = $true)][object]$Journal,
        [Parameter(Mandatory = $true)][string[]]$TrustedRoots
    )

    if ($null -eq $Journal -or [string]::IsNullOrWhiteSpace("$($Journal.JournalPath)")) {
        throw 'Journal must contain JournalPath.'
    }
    $journalPath = Get-LexicalJournalPath -Path "$($Journal.JournalPath)"
    [void](Validate-JournalStoragePath `
        -JournalPath $journalPath `
        -TrustedRoots $TrustedRoots)
    if (-not (Test-Path -LiteralPath $journalPath -PathType Leaf)) {
        throw "Change journal does not exist: $journalPath"
    }
    $json = [IO.File]::ReadAllText($journalPath)
    try {
        $hasDuplicates = [ChangeJournalJsonScanner]::HasDuplicateProperties($json)
    }
    catch {
        throw "Change journal is corrupted or invalid: $journalPath"
    }
    if ($hasDuplicates) {
        throw 'Change journal contains duplicate JSON properties.'
    }
    try {
        $document = $json | ConvertFrom-Json
    }
    catch {
        throw "Change journal is corrupted or invalid: $journalPath"
    }
    Assert-ChangeJournalDocument -Document $document

    if ((Split-Path -Leaf $journalPath) -cne 'journal.json') {
        throw 'Change journal path must end in journal.json.'
    }
    $directory = Get-LexicalJournalPath -Path (Split-Path -Parent $journalPath)
    if (-not $directory.Equals(
        $document.JournalDirectory,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw 'Change journal directory metadata does not match its location.'
    }
    if (-not (Split-Path -Leaf $directory).Equals(
        $document.OperationId,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw 'Change journal OperationId does not match its journal directory.'
    }
    Assert-ChangeJournalIntegrity -Document $document
    return [pscustomobject]@{
        Path = $journalPath
        Directory = $directory
        Document = $document
    }
}

function Get-JournalPathIdentity {
    param([Parameter(Mandatory = $true)][string]$Path)

    $identity = [ChangeJournalRuntime]::GetIdentity($Path)
    return [pscustomobject][ordered]@{
        VolumeSerial = $identity[0]
        FileId = $identity[1]
    }
}

function Test-JournalIdentityEqual {
    param(
        [Parameter(Mandatory = $true)][object]$First,
        [Parameter(Mandatory = $true)][object]$Second
    )

    return (
        $First.VolumeSerial -ceq $Second.VolumeSerial -and
        $First.FileId -ceq $Second.FileId
    )
}

function New-ChangeJournal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$OperationId,
        [string[]]$AllowedRoots = @(),
        [string]$WorkspaceRoot = (Get-ChangeJournalWorkspaceRoot),
        [string]$CodexRoot = (Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex'),
        [string]$StateRoot
    )

    if ($OperationId -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
        throw 'OperationId contains unsupported characters or length.'
    }
    $workspace = Get-LexicalJournalPath -Path $WorkspaceRoot
    if ([string]::IsNullOrWhiteSpace($StateRoot)) {
        $StateRoot = Join-Path $workspace '.state'
    }
    $auditRoots = ConvertTo-LexicalRootList -Roots (
        @($workspace, $CodexRoot) + @($AllowedRoots)
    )
    $state = Assert-ManagedJournalPath `
        -Path $StateRoot `
        -AllowedRoots (Get-TrustedJournalRoots -AllowedRoots $AllowedRoots)
    $journalDirectory = Join-Path $state "journals\$OperationId"
    $journalPath = Join-Path $journalDirectory 'journal.json'
    $trustedRoots = Get-TrustedJournalRoots -AllowedRoots $AllowedRoots
    [void](Validate-JournalStoragePath `
        -JournalPath $journalPath `
        -TrustedRoots $trustedRoots `
        -CreateDirectories)

    return Invoke-WithChangeJournalLock `
        -JournalPath $journalPath `
        -TrustedRoots $trustedRoots `
        -Action {
        if (Test-Path -LiteralPath $journalPath) {
            throw "A journal already exists for operation: $OperationId"
        }
        $journalDirectory = Get-LexicalJournalPath -Path $journalDirectory
        $now = [DateTime]::UtcNow.ToString('o')
        $document = [pscustomobject][ordered]@{
            Schema = $script:ChangeJournalSchema
            Version = $script:ChangeJournalVersion
            OperationId = $OperationId
            WorkspaceRoot = $workspace
            JournalDirectory = $journalDirectory
            AllowedRoots = @($auditRoots)
            CreatedAtUtc = $now
            UpdatedAtUtc = $now
            Changes = @()
            Integrity = ''
        }
        Write-ChangeJournalDocument `
            -Document $document `
            -JournalPath $journalPath `
            -TrustedRoots $trustedRoots
        return [pscustomobject]@{
            OperationId = $OperationId
            JournalPath = $journalPath
        }
    }
}

function Add-FileChange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$Journal,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]
        [ValidateSet('create', 'modify', 'delete', 'directory_create')]
        [string]$Kind,
        [AllowNull()][string[]]$AllowedRoots = @()
    )

    $journalPath = Get-LexicalJournalPath -Path "$($Journal.JournalPath)"
    $trustedRoots = Get-TrustedJournalRoots -AllowedRoots $AllowedRoots
    [void](Validate-JournalStoragePath `
        -JournalPath $journalPath `
        -TrustedRoots $trustedRoots)
    return Invoke-WithChangeJournalLock `
        -JournalPath $journalPath `
        -TrustedRoots $trustedRoots `
        -Action {
        $loaded = Read-ChangeJournalDocument `
            -Journal $Journal `
            -TrustedRoots $trustedRoots
        $pathValue = Assert-ManagedJournalPath `
            -Path $Path `
            -AllowedRoots $trustedRoots `
            -RejectRoot:($Kind -eq 'directory_create')
        $storageLayout = Get-ChangeJournalStorageLayout -JournalPath $loaded.Path
        if (
            $Kind -ceq 'directory_create' -and
            $pathValue.Equals(
                $storageLayout.StateRoot,
                [StringComparison]::OrdinalIgnoreCase
            )
        ) {
            throw 'Refusing to register journal StateRoot for recursive deletion.'
        }
        foreach ($existing in $loaded.Document.Changes) {
            if (
                $existing.Type -ceq 'file' -and
                $existing.Path.Equals($pathValue, [StringComparison]::OrdinalIgnoreCase)
            ) {
                return $existing
            }
        }

        $isFile = Test-Path -LiteralPath $pathValue -PathType Leaf
        $isDirectory = Test-Path -LiteralPath $pathValue -PathType Container
        if ($Kind -cin @('modify', 'delete') -and -not $isFile) {
            throw "Kind '$Kind' requires an existing file: $pathValue"
        }
        if ($Kind -cin @('create', 'directory_create') -and ($isFile -or $isDirectory)) {
            throw "Kind '$Kind' requires an absent path: $pathValue"
        }

        $entryId = [Guid]::NewGuid().ToString('N')
        $backupPath = $null
        $backupSha256 = $null
        $metadata = $null
        $originalIdentity = $null
        $committedBackup = $null
        try {
            if ($Kind -cin @('modify', 'delete')) {
                Assert-ManagedJournalPath -Path $pathValue -AllowedRoots $trustedRoots |
                    Out-Null
                $originalIdentity = Get-JournalPathIdentity -Path $pathValue
                $item = Get-Item -LiteralPath $pathValue -Force
                $metadata = [pscustomobject][ordered]@{
                    Attributes = [int]$item.Attributes
                    CreationTimeUtc = $item.CreationTimeUtc.ToString('o')
                    LastWriteTimeUtc = $item.LastWriteTimeUtc.ToString('o')
                    LastAccessTimeUtc = $item.LastAccessTimeUtc.ToString('o')
                }
                $backupDirectory = Join-Path $loaded.Directory 'backups'
                [void](Validate-JournalStoragePath `
                    -JournalPath $loaded.Path `
                    -TrustedRoots $trustedRoots `
                    -CreateDirectories `
                    -IncludeBackupDirectory)
                $backupPath = Join-Path $backupDirectory "$entryId.bin"
                $temporaryBackup = Join-Path $backupDirectory (
                    "$entryId.bin.tmp-" + [Guid]::NewGuid().ToString('N')
                )
                $bytes = [IO.File]::ReadAllBytes($pathValue)
                try {
                    [void](Validate-JournalStoragePath `
                        -JournalPath $loaded.Path `
                        -TrustedRoots $trustedRoots `
                        -IncludeBackupDirectory)
                    Write-DurableFile -Path $temporaryBackup -Bytes $bytes
                    Assert-ManagedJournalPath -Path $pathValue -AllowedRoots $trustedRoots |
                        Out-Null
                    $currentIdentity = Get-JournalPathIdentity -Path $pathValue
                    if (-not (Test-JournalIdentityEqual `
                        -First $originalIdentity `
                        -Second $currentIdentity
                    )) {
                        throw 'File identity changed while creating the backup.'
                    }
                    [void](Validate-JournalStoragePath `
                        -JournalPath $loaded.Path `
                        -TrustedRoots $trustedRoots `
                        -IncludeBackupDirectory)
                    Assert-StorageComponentSafe -Path $backupPath
                    [IO.File]::Move($temporaryBackup, $backupPath)
                    $committedBackup = $backupPath
                }
                finally {
                    [Array]::Clear($bytes, 0, $bytes.Length)
                    if (Test-Path -LiteralPath $temporaryBackup -PathType Leaf) {
                        Remove-Item -LiteralPath $temporaryBackup -Force
                    }
                }
                $backupSha256 = (
                    Get-FileHash -LiteralPath $backupPath -Algorithm SHA256
                ).Hash.ToLowerInvariant()
            }

            $entry = [pscustomobject][ordered]@{
                Id = $entryId
                Type = 'file'
                Kind = $Kind
                Path = $pathValue
                BackupPath = $backupPath
                BackupSha256 = $backupSha256
                Metadata = $metadata
                OriginalIdentity = $originalIdentity
                Confirmed = $false
                ConfirmedIdentity = $null
                RecordedAtUtc = [DateTime]::UtcNow.ToString('o')
                RolledBack = $false
                RolledBackAtUtc = $null
            }
            $loaded.Document.Changes = @($loaded.Document.Changes) + @($entry)
            Write-ChangeJournalDocument `
                -Document $loaded.Document `
                -JournalPath $loaded.Path `
                -TrustedRoots $trustedRoots
            return $entry
        }
        catch {
            if (
                $null -ne $committedBackup -and
                (Test-Path -LiteralPath $committedBackup -PathType Leaf)
            ) {
                Remove-Item -LiteralPath $committedBackup -Force
            }
            throw
        }
    }
}

function Confirm-FileChange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$Journal,
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowNull()][string[]]$AllowedRoots = @()
    )

    $journalPath = Get-LexicalJournalPath -Path "$($Journal.JournalPath)"
    $trustedRoots = Get-TrustedJournalRoots -AllowedRoots $AllowedRoots
    [void](Validate-JournalStoragePath `
        -JournalPath $journalPath `
        -TrustedRoots $trustedRoots)
    return Invoke-WithChangeJournalLock `
        -JournalPath $journalPath `
        -TrustedRoots $trustedRoots `
        -Action {
        $loaded = Read-ChangeJournalDocument `
            -Journal $Journal `
            -TrustedRoots $trustedRoots
        $pathValue = Assert-ManagedJournalPath -Path $Path -AllowedRoots $trustedRoots
        $entry = @(
            $loaded.Document.Changes |
                Where-Object {
                    $_.Type -ceq 'file' -and
                    $_.Path.Equals($pathValue, [StringComparison]::OrdinalIgnoreCase)
                }
        ) | Select-Object -First 1
        if ($null -eq $entry) {
            throw 'No file change exists for confirmation.'
        }
        if ($entry.Kind -cnotin @('create', 'directory_create')) {
            throw 'Only create changes require confirmation.'
        }
        if ($entry.Confirmed) {
            return $entry
        }
        if (
            $entry.Kind -ceq 'create' -and
            -not (Test-Path -LiteralPath $pathValue -PathType Leaf)
        ) {
            throw 'Created file does not exist for confirmation.'
        }
        if (
            $entry.Kind -ceq 'directory_create' -and
            -not (Test-Path -LiteralPath $pathValue -PathType Container)
        ) {
            throw 'Created directory does not exist for confirmation.'
        }
        Assert-ManagedJournalPath -Path $pathValue -AllowedRoots $trustedRoots |
            Out-Null
        $entry.ConfirmedIdentity = Get-JournalPathIdentity -Path $pathValue
        $entry.Confirmed = $true
        Write-ChangeJournalDocument `
            -Document $loaded.Document `
            -JournalPath $loaded.Path `
            -TrustedRoots $trustedRoots
        return $entry
    }
}

function Add-ExternalChange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$Journal,
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$RollbackCommand,
        [AllowNull()][string[]]$AllowedRoots = @()
    )

    if ([string]::IsNullOrWhiteSpace($Description)) {
        throw 'Description must not be empty.'
    }
    $journalPath = Get-LexicalJournalPath -Path "$($Journal.JournalPath)"
    $trustedRoots = Get-TrustedJournalRoots -AllowedRoots $AllowedRoots
    [void](Validate-JournalStoragePath `
        -JournalPath $journalPath `
        -TrustedRoots $trustedRoots)
    return Invoke-WithChangeJournalLock `
        -JournalPath $journalPath `
        -TrustedRoots $trustedRoots `
        -Action {
        $loaded = Read-ChangeJournalDocument `
            -Journal $Journal `
            -TrustedRoots $trustedRoots
        $entry = [pscustomobject][ordered]@{
            Id = [Guid]::NewGuid().ToString('N')
            Type = 'external'
            Description = $Description
            RollbackCommand = $RollbackCommand
            RecordedAtUtc = [DateTime]::UtcNow.ToString('o')
            RolledBack = $false
            RolledBackAtUtc = $null
        }
        $loaded.Document.Changes = @($loaded.Document.Changes) + @($entry)
        Write-ChangeJournalDocument `
            -Document $loaded.Document `
            -JournalPath $loaded.Path `
            -TrustedRoots $trustedRoots
        return $entry
    }
}

function Assert-ValidJournalBackup {
    param(
        [Parameter(Mandatory = $true)][object]$Entry,
        [Parameter(Mandatory = $true)][object]$Loaded,
        [Parameter(Mandatory = $true)][string[]]$TrustedRoots
    )

    [void](Validate-JournalStoragePath `
        -JournalPath $Loaded.Path `
        -TrustedRoots $TrustedRoots `
        -IncludeBackupDirectory)
    $expected = Join-Path (Join-Path $Loaded.Directory 'backups') "$($Entry.Id).bin"
    $expected = Get-LexicalJournalPath -Path $expected
    $actual = Get-LexicalJournalPath -Path $Entry.BackupPath
    if (-not $actual.Equals($expected, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Journal backup path is not bound to its entry id.'
    }
    Assert-NoReparsePath `
        -Path $actual `
        -Root (Get-LexicalJournalPath -Path $Loaded.Directory)
    if (-not (Test-Path -LiteralPath $actual -PathType Leaf)) {
        throw 'Journal backup file is missing.'
    }
    $hash = (Get-FileHash -LiteralPath $actual -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -cne $Entry.BackupSha256) {
        throw 'Journal backup SHA256 hash does not match.'
    }
    return $actual
}

function Assert-NoReparseDescendants {
    param([Parameter(Mandatory = $true)][string]$Path)

    foreach ($item in Get-ChildItem -LiteralPath $Path -Force -Recurse) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Created directory contains a reparse point: $($item.FullName)"
        }
    }
}

function Set-RestoredFileMetadata {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][object]$Metadata
    )

    [IO.File]::SetCreationTimeUtc($Path, [DateTime]::Parse($Metadata.CreationTimeUtc))
    [IO.File]::SetLastWriteTimeUtc($Path, [DateTime]::Parse($Metadata.LastWriteTimeUtc))
    [IO.File]::SetLastAccessTimeUtc($Path, [DateTime]::Parse($Metadata.LastAccessTimeUtc))
    [IO.File]::SetAttributes($Path, [IO.FileAttributes][int]$Metadata.Attributes)
}

function Restore-JournalFile {
    param(
        [Parameter(Mandatory = $true)][object]$Entry,
        [Parameter(Mandatory = $true)][object]$Loaded,
        [Parameter(Mandatory = $true)][string[]]$TrustedRoots
    )

    $target = Assert-ManagedJournalPath `
        -Path $Entry.Path `
        -AllowedRoots $TrustedRoots `
        -RejectRoot:($Entry.Kind -eq 'directory_create')
    if ($Entry.Kind -cin @('create', 'directory_create')) {
        if (-not $Entry.Confirmed) {
            return [pscustomobject]@{
                Residual = $true
                Path = $target
                Reason = 'Create change was not confirmed after creation.'
            }
        }
        $expectedType = if ($Entry.Kind -ceq 'create') { 'Leaf' } else { 'Container' }
        if (-not (Test-Path -LiteralPath $target -PathType $expectedType)) {
            return [pscustomobject]@{
                AlreadyRemoved = $true
                Path = $target
            }
        }
        $identity = Get-JournalPathIdentity -Path $target
        if (-not (Test-JournalIdentityEqual `
            -First $Entry.ConfirmedIdentity `
            -Second $identity
        )) {
            throw 'Created path identity no longer matches the confirmed identity.'
        }
        if ($Entry.Kind -ceq 'directory_create') {
            Assert-NoReparseDescendants -Path $target
        }
        Assert-ManagedJournalPath `
            -Path $target `
            -AllowedRoots $TrustedRoots `
            -RejectRoot:($Entry.Kind -eq 'directory_create') | Out-Null
        $identity = Get-JournalPathIdentity -Path $target
        if (-not (Test-JournalIdentityEqual `
            -First $Entry.ConfirmedIdentity `
            -Second $identity
        )) {
            throw 'Created path identity changed before deletion.'
        }
        if ($Entry.Kind -ceq 'create') {
            [IO.File]::SetAttributes($target, [IO.FileAttributes]::Normal)
            Remove-Item -LiteralPath $target -Force
        }
        else {
            Remove-Item -LiteralPath $target -Recurse -Force
        }
        return [pscustomobject]@{ Path = $target }
    }

    $backup = Assert-ValidJournalBackup `
        -Entry $Entry `
        -Loaded $Loaded `
        -TrustedRoots $TrustedRoots
    $parent = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Assert-ManagedJournalPath -Path $target -AllowedRoots $TrustedRoots | Out-Null

    if ($Entry.Kind -ceq 'delete') {
        if (Test-Path -LiteralPath $target) {
            throw 'Deleted file target is no longer absent.'
        }
    }
    else {
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
            throw 'Modified file target is missing or is not a file.'
        }
        $identity = Get-JournalPathIdentity -Path $target
        if (-not (Test-JournalIdentityEqual `
            -First $Entry.OriginalIdentity `
            -Second $identity
        )) {
            throw 'Modified file identity no longer matches the original identity.'
        }
    }

    $temporary = Join-Path $parent (
        '.' + [IO.Path]::GetFileName($target) + '.rollback.tmp-' +
        [Guid]::NewGuid().ToString('N')
    )
    $replaced = Join-Path $parent (
        '.' + [IO.Path]::GetFileName($target) + '.rollback.bak-' +
        [Guid]::NewGuid().ToString('N')
    )
    $bytes = [IO.File]::ReadAllBytes($backup)
    try {
        Write-DurableFile -Path $temporary -Bytes $bytes
        Assert-ManagedJournalPath -Path $target -AllowedRoots $TrustedRoots |
            Out-Null
        if ($Entry.Kind -ceq 'delete') {
            if (Test-Path -LiteralPath $target) {
                throw 'Deleted file target appeared before restore.'
            }
            [IO.File]::Move($temporary, $target)
        }
        else {
            $identity = Get-JournalPathIdentity -Path $target
            if (-not (Test-JournalIdentityEqual `
                -First $Entry.OriginalIdentity `
                -Second $identity
            )) {
                throw 'Modified file identity changed before restore.'
            }
            [IO.File]::Replace($temporary, $target, $replaced, $true)
        }
        Set-RestoredFileMetadata -Path $target -Metadata $Entry.Metadata
    }
    finally {
        [Array]::Clear($bytes, 0, $bytes.Length)
        foreach ($artifact in @($temporary, $replaced)) {
            if (Test-Path -LiteralPath $artifact -PathType Leaf) {
                Remove-Item -LiteralPath $artifact -Force
            }
        }
    }
    return [pscustomobject]@{ Path = $target }
}

function Invoke-JournalRollback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$Journal,
        [AllowNull()][string[]]$AllowedRoots = @()
    )

    $journalPath = Get-LexicalJournalPath -Path "$($Journal.JournalPath)"
    $trustedRoots = Get-TrustedJournalRoots -AllowedRoots $AllowedRoots
    [void](Validate-JournalStoragePath `
        -JournalPath $journalPath `
        -TrustedRoots $trustedRoots)
    return Invoke-WithChangeJournalLock `
        -JournalPath $journalPath `
        -TrustedRoots $trustedRoots `
        -Action {
        $loaded = Read-ChangeJournalDocument `
            -Journal $Journal `
            -TrustedRoots $trustedRoots
        $succeeded = New-Object 'Collections.Generic.List[object]'
        $failed = New-Object 'Collections.Generic.List[object]'
        $residuals = New-Object 'Collections.Generic.List[object]'
        $changes = @($loaded.Document.Changes)

        for ($index = $changes.Count - 1; $index -ge 0; $index--) {
            $entry = $changes[$index]
            if ($entry.Type -ceq 'external') {
                $residuals.Add([pscustomobject]@{
                    Id = $entry.Id
                    Type = 'external'
                    Description = $entry.Description
                    RollbackCommand = $entry.RollbackCommand
                    Reason = 'String rollback commands are recorded but never executed.'
                })
                continue
            }
            if ($entry.RolledBack) {
                $succeeded.Add([pscustomobject]@{
                    Id = $entry.Id
                    Path = $entry.Path
                    Kind = $entry.Kind
                    AlreadyRolledBack = $true
                })
                continue
            }
            try {
                $restored = Restore-JournalFile `
                    -Entry $entry `
                    -Loaded $loaded `
                    -TrustedRoots $trustedRoots
                if ($restored.Residual) {
                    $residuals.Add([pscustomobject]@{
                        Id = $entry.Id
                        Type = 'file'
                        Path = $entry.Path
                        Kind = $entry.Kind
                        Reason = $restored.Reason
                    })
                    continue
                }
                $entry.RolledBack = $true
                $entry.RolledBackAtUtc = [DateTime]::UtcNow.ToString('o')
                Write-ChangeJournalDocument `
                    -Document $loaded.Document `
                    -JournalPath $loaded.Path `
                    -TrustedRoots $trustedRoots
                $succeeded.Add([pscustomobject]@{
                    Id = $entry.Id
                    Path = $restored.Path
                    Kind = $entry.Kind
                    AlreadyRolledBack = [bool]$restored.AlreadyRemoved
                })
            }
            catch {
                $failed.Add([pscustomobject]@{
                    Id = $entry.Id
                    Path = $entry.Path
                    Kind = $entry.Kind
                    Error = $_.Exception.Message
                })
            }
        }
        $status = if ($failed.Count -gt 0) {
            'Failed'
        }
        elseif ($residuals.Count -gt 0) {
            'Partial'
        }
        else {
            'Succeeded'
        }
        return [pscustomobject]@{
            Status = $status
            Succeeded = $succeeded.ToArray()
            Failed = $failed.ToArray()
            Residuals = $residuals.ToArray()
        }
    }
}
