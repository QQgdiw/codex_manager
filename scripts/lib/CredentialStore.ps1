$script:DefaultCredentialStorePath = Join-Path (
    Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
) '.secrets\credentials.dpapi'
$script:CredentialStoreSchemaVersion = 1

if (-not ('Security.Cryptography.ProtectedData' -as [type])) {
    Add-Type -AssemblyName System.Security
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

function Get-CredentialStoreMutexName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StorePath
    )

    $bytes = [Text.Encoding]::UTF8.GetBytes($StorePath.ToUpperInvariant())
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha256.ComputeHash($bytes)
        return 'Local\CodexCredentialStore-' + (
            ($hash | ForEach-Object { $_.ToString('x2') }) -join ''
        )
    }
    finally {
        [Array]::Clear($bytes, 0, $bytes.Length)
        $sha256.Dispose()
    }
}

function Invoke-WithCredentialStoreLock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StorePath,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Action
    )

    $mutex = New-Object Threading.Mutex(
        $false,
        (Get-CredentialStoreMutexName -StorePath $StorePath)
    )
    $acquired = $false
    try {
        try {
            $acquired = $mutex.WaitOne([TimeSpan]::FromSeconds(30))
        }
        catch [Threading.AbandonedMutexException] {
            $acquired = $true
        }

        if (-not $acquired) {
            throw 'Credential store is busy.'
        }

        return & $Action
    }
    finally {
        if ($acquired) {
            $mutex.ReleaseMutex()
        }
        $mutex.Dispose()
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
        if ($actual -notcontains $propertyName) {
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

function Read-CredentialStore {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StorePath
    )

    if (-not (Test-Path -LiteralPath $StorePath -PathType Leaf)) {
        return New-EmptyCredentialStore
    }

    try {
        $document = [IO.File]::ReadAllText($StorePath) | ConvertFrom-Json
        if ($null -eq $document) {
            throw 'invalid'
        }
        if (-not (Test-CredentialStorePropertySet -InputObject $document -Expected @(
            'schema_version', 'credentials'
        ))) {
            throw 'invalid'
        }
        if ($document.schema_version -ne $script:CredentialStoreSchemaVersion) {
            throw 'invalid'
        }
        if ($null -eq $document.credentials) {
            throw 'invalid'
        }

        $seenNames = New-Object 'Collections.Generic.HashSet[string]' (
            [StringComparer]::OrdinalIgnoreCase
        )
        foreach ($credential in @($document.credentials)) {
            if ($null -eq $credential -or -not (
                Test-CredentialStorePropertySet -InputObject $credential -Expected @(
                    'name', 'ciphertext', 'created_at', 'updated_at'
                )
            )) {
                throw 'invalid'
            }
            Assert-ManagedCredentialName -Name $credential.name
            if (-not $seenNames.Add($credential.name)) {
                throw 'invalid'
            }
            [void][Convert]::FromBase64String($credential.ciphertext)
            [void][DateTimeOffset]::Parse(
                $credential.created_at,
                [Globalization.CultureInfo]::InvariantCulture
            )
            [void][DateTimeOffset]::Parse(
                $credential.updated_at,
                [Globalization.CultureInfo]::InvariantCulture
            )
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
    $document = Read-CredentialStore -StorePath $resolvedPath
    $matches = @($document.credentials | Where-Object {
        Test-ManagedCredentialNameEqual -Left $_.name -Right $Name
    })
    if ($matches.Count -eq 0) {
        throw 'Managed credential was not found.'
    }

    return Unprotect-ManagedSecureString -Ciphertext $matches[0].ciphertext
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
    $document = Read-CredentialStore -StorePath $resolvedPath
    return @($document.credentials | ForEach-Object {
        [pscustomobject][ordered]@{
            Name = $_.name
            CreatedAt = [DateTimeOffset]::Parse(
                $_.created_at,
                [Globalization.CultureInfo]::InvariantCulture
            ).UtcDateTime
            UpdatedAt = [DateTimeOffset]::Parse(
                $_.updated_at,
                [Globalization.CultureInfo]::InvariantCulture
            ).UtcDateTime
        }
    })
}
