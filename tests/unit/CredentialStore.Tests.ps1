$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$credentialLibrary = Join-Path $projectRoot 'scripts\lib\CredentialStore.ps1'

function ConvertFrom-TestSecureString {
    param([Security.SecureString]$SecureString)

    $bstr = [IntPtr]::Zero
    try {
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

function New-TestSecretText {
    return -join @(
        [char]0x0054, [char]0x0065, [char]0x0073, [char]0x0074,
        [char]0x002D, [char]0x0053, [char]0x0065, [char]0x0063,
        [char]0x0072, [char]0x0065, [char]0x0074, [char]0x002D,
        [char]0x0039, [char]0x0037, [char]0x0033, [char]0x0031
    )
}

function Get-TestExceptionMessage {
    param([scriptblock]$Action)

    try {
        & $Action
        return $null
    }
    catch {
        return $_.Exception.Message
    }
}

function Test-JunctionAvailable {
    $probeRoot = Join-Path ([IO.Path]::GetTempPath()) (
        'credential-junction-probe-' + [Guid]::NewGuid().ToString('N')
    )
    $target = $probeRoot + '-target'
    try {
        New-Item -ItemType Directory -Path $target -Force | Out-Null
        New-Item -ItemType Junction -Path $probeRoot -Target $target `
            -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
    finally {
        if (Test-Path -LiteralPath $probeRoot) {
            [IO.Directory]::Delete($probeRoot)
        }
        if (Test-Path -LiteralPath $target) {
            Remove-Item -LiteralPath $target -Recurse -Force
        }
    }
}

function Invoke-TestConcurrentWriters {
    param(
        [string[]]$StorePaths,
        [int]$WriterCount,
        [string]$WorkingRoot,
        [string]$SecretPrefix
    )

    $barrierRoot = Join-Path $WorkingRoot ('barrier-' + [Guid]::NewGuid().ToString('N'))
    $goPath = Join-Path $barrierRoot 'go'
    $processes = @()
    $expectedSecrets = @{}
    New-Item -ItemType Directory -Path $barrierRoot -Force | Out-Null
    try {
        foreach ($index in 0..($WriterCount - 1)) {
            $name = 'concurrent-' + $index
            $secretText = $SecretPrefix + '-' + $index
            $expectedSecrets[$name] = $secretText
            $storePath = $StorePaths[$index % $StorePaths.Count]
            $readyPath = Join-Path $barrierRoot ('ready-' + $index)
            $command = @"
. '$($credentialLibrary.Replace("'", "''"))'
[IO.File]::WriteAllText('$($readyPath.Replace("'", "''"))', '')
`$deadline = [DateTime]::UtcNow.AddSeconds(30)
while (-not (Test-Path -LiteralPath '$($goPath.Replace("'", "''"))')) {
    if ([DateTime]::UtcNow -ge `$deadline) { exit 91 }
    Start-Sleep -Milliseconds 10
}
`$secret = ConvertTo-SecureString '$($secretText.Replace("'", "''"))' -AsPlainText -Force
Set-ManagedCredential -Name '$name' -Secret `$secret -StorePath '$($storePath.Replace("'", "''"))'
"@
            $encodedCommand = [Convert]::ToBase64String(
                [Text.Encoding]::Unicode.GetBytes($command)
            )
            $processes += Start-Process powershell -ArgumentList @(
                '-NoProfile',
                '-EncodedCommand',
                $encodedCommand
            ) -PassThru -WindowStyle Hidden
        }

        $readyDeadline = [DateTime]::UtcNow.AddSeconds(30)
        while (@(Get-ChildItem -LiteralPath $barrierRoot -Filter 'ready-*').Count -lt $WriterCount) {
            if ([DateTime]::UtcNow -ge $readyDeadline) {
                throw 'Concurrent writer startup barrier timed out.'
            }
            Start-Sleep -Milliseconds 20
        }
        [IO.File]::WriteAllText($goPath, '')

        $exitCodes = @()
        foreach ($process in $processes) {
            if (-not $process.WaitForExit(30000)) {
                throw 'Concurrent credential writer timed out.'
            }
            $exitCodes += $process.ExitCode
        }

        return [pscustomobject]@{
            ExitCodes = $exitCodes
            ExpectedSecrets = $expectedSecrets
        }
    }
    finally {
        foreach ($process in $processes) {
            if (-not $process.HasExited) {
                $process.Kill()
            }
            $process.Dispose()
        }
        if (Test-Path -LiteralPath $barrierRoot) {
            Remove-Item -LiteralPath $barrierRoot -Recurse -Force
        }
    }
}

$script:junctionAvailable = Test-JunctionAvailable

Describe 'CredentialStore' {
    BeforeAll {
        . $credentialLibrary
        $script:testRoot = Join-Path ([IO.Path]::GetTempPath()) (
            'credential-store-tests-' + [Guid]::NewGuid().ToString('N')
        )
        New-Item -ItemType Directory -Path $script:testRoot -Force | Out-Null
    }

    AfterAll {
        if (Test-Path -LiteralPath $script:testRoot) {
            Remove-Item -LiteralPath $script:testRoot -Recurse -Force
        }
    }

    BeforeEach {
        $script:caseRoot = Join-Path $script:testRoot ([Guid]::NewGuid().ToString('N'))
        $script:storePath = Join-Path $script:caseRoot 'credentials.dpapi'
        $script:secretText = New-TestSecretText
        $script:secret = ConvertTo-SecureString $script:secretText -AsPlainText -Force
    }

    It 'encrypts and decrypts a credential for the current user' {
        Set-ManagedCredential -Name 'service-token' -Secret $script:secret -StorePath $script:storePath

        $actual = Get-ManagedCredential -Name 'service-token' -StorePath $script:storePath

        $actual | Should BeOfType ([Security.SecureString])
        (ConvertFrom-TestSecureString $actual) | Should Be $script:secretText
    }

    It 'creates a missing storage directory and leaves no plaintext on disk' {
        $output = @(
            Set-ManagedCredential -Name 'service-token' -Secret $script:secret `
                -StorePath $script:storePath
        )

        (Test-Path -LiteralPath $script:storePath -PathType Leaf) | Should Be $true
        $content = [IO.File]::ReadAllText($script:storePath)
        $content.Contains($script:secretText) | Should Be $false
        (($output | Out-String).Contains($script:secretText)) | Should Be $false
    }

    It 'resolves the production default path from the library location' {
        $expectedPath = Join-Path $projectRoot '.secrets\credentials.dpapi'
        $originalLocation = Get-Location
        try {
            Set-Location ([IO.Path]::GetTempPath())
            $script:DefaultCredentialStorePath | Should Be $expectedPath
        }
        finally {
            Set-Location $originalLocation
        }
    }

    It 'writes only the approved schema and credential fields' {
        Set-ManagedCredential -Name 'service-token' -Secret $script:secret -StorePath $script:storePath

        $document = [IO.File]::ReadAllText($script:storePath) | ConvertFrom-Json
        @($document.PSObject.Properties.Name) | Should Be @('schema_version', 'credentials')
        $document.schema_version.GetType().FullName | Should Be 'System.String'
        $document.schema_version | Should Be '1'
        @($document.credentials[0].PSObject.Properties.Name) |
            Should Be @('name', 'ciphertext', 'created_at', 'updated_at')
    }

    It 'updates ciphertext and updated time while preserving created time' {
        Set-ManagedCredential -Name 'service-token' -Secret $script:secret -StorePath $script:storePath
        $before = [IO.File]::ReadAllText($script:storePath) | ConvertFrom-Json
        Start-Sleep -Milliseconds 20
        $replacementText = $script:secretText + '-updated'
        $replacement = ConvertTo-SecureString $replacementText -AsPlainText -Force

        Set-ManagedCredential -Name 'service-token' -Secret $replacement -StorePath $script:storePath

        $after = [IO.File]::ReadAllText($script:storePath) | ConvertFrom-Json
        $after.credentials.Count | Should Be 1
        $after.credentials[0].created_at | Should Be $before.credentials[0].created_at
        $after.credentials[0].updated_at | Should Not Be $before.credentials[0].updated_at
        $after.credentials[0].ciphertext | Should Not Be $before.credentials[0].ciphertext
        (ConvertFrom-TestSecureString (
            Get-ManagedCredential -Name 'service-token' -StorePath $script:storePath
        )) | Should Be $replacementText
    }

    It 'matches credential names using OrdinalIgnoreCase and preserves the first name casing' {
        Set-ManagedCredential -Name 'CaseName' -Secret $script:secret -StorePath $script:storePath
        $replacementText = $script:secretText + '-case-update'
        $replacement = ConvertTo-SecureString $replacementText -AsPlainText -Force

        Set-ManagedCredential -Name 'casename' -Secret $replacement -StorePath $script:storePath

        $storedDocument = [IO.File]::ReadAllText($script:storePath) | ConvertFrom-Json
        @($storedDocument.credentials).Count | Should Be 1
        $storedDocument.credentials[0].name | Should Be 'CaseName'
        (ConvertFrom-TestSecureString (
            Get-ManagedCredential -Name 'CASENAME' -StorePath $script:storePath
        )) | Should Be $replacementText
        $metadata = @(Get-ManagedCredentialMetadata -StorePath $script:storePath)
        $metadata.Count | Should Be 1
        $metadata[0].Name | Should Be 'CaseName'
        (Remove-ManagedCredential -Name 'caseNAME' -StorePath $script:storePath) |
            Should Be $true
        (Get-ManagedCredentialMetadata -StorePath $script:storePath).Count | Should Be 0
    }

    It 'removes an existing credential and returns true' {
        Set-ManagedCredential -Name 'service-token' -Secret $script:secret -StorePath $script:storePath

        $removed = Remove-ManagedCredential -Name 'service-token' -StorePath $script:storePath

        $removed | Should Be $true
        (Get-ManagedCredentialMetadata -StorePath $script:storePath).Count | Should Be 0
    }

    It 'returns false when removing a credential that does not exist' {
        (Remove-ManagedCredential -Name 'missing' -StorePath $script:storePath) |
            Should Be $false
    }

    It 'throws a stable non-sensitive error when a credential does not exist' {
        $message = Get-TestExceptionMessage {
            Get-ManagedCredential -Name $script:secretText -StorePath $script:storePath
        }

        $message | Should Be 'Managed credential was not found.'
        $message.Contains($script:secretText) | Should Be $false
    }

    It 'returns metadata without ciphertext' {
        Set-ManagedCredential -Name 'service-token' -Secret $script:secret -StorePath $script:storePath

        $metadata = @(Get-ManagedCredentialMetadata -StorePath $script:storePath)

        $metadata.Count | Should Be 1
        @($metadata[0].PSObject.Properties.Name) |
            Should Be @('Name', 'CreatedAt', 'UpdatedAt')
        ($metadata[0].PSObject.Properties.Name -contains 'ciphertext') | Should Be $false
    }

    It 'enforces the designed ASCII safe-character rule for credential names' {
        $message = Get-TestExceptionMessage {
            Set-ManagedCredential -Name '../unsafe' -Secret $script:secret -StorePath $script:storePath
        }

        $message | Should Be 'Credential name is invalid.'
        (Test-Path -LiteralPath $script:storePath) | Should Be $false
    }

    It 'treats malformed storage as a fatal non-sensitive error' {
        New-Item -ItemType Directory -Path $script:caseRoot -Force | Out-Null
        [IO.File]::WriteAllText($script:storePath, '{not-json')

        $message = Get-TestExceptionMessage {
            Get-ManagedCredentialMetadata -StorePath $script:storePath
        }

        $message | Should Be 'Credential store is invalid.'
        $message.Contains($script:secretText) | Should Be $false
    }

    It 'rejects a numeric schema version instead of coercing it' {
        New-Item -ItemType Directory -Path $script:caseRoot -Force | Out-Null
        [IO.File]::WriteAllText(
            $script:storePath,
            '{"schema_version":1,"credentials":[]}'
        )

        (Get-TestExceptionMessage {
            Get-ManagedCredentialMetadata -StorePath $script:storePath
        }) | Should Be 'Credential store is invalid.'
    }

    It 'rejects an unsupported string schema version' {
        New-Item -ItemType Directory -Path $script:caseRoot -Force | Out-Null
        [IO.File]::WriteAllText(
            $script:storePath,
            '{"schema_version":"2","credentials":[]}'
        )

        (Get-TestExceptionMessage {
            Get-ManagedCredentialMetadata -StorePath $script:storePath
        }) | Should Be 'Credential store is invalid.'
    }

    It 'rejects credentials that are an object instead of an array' {
        New-Item -ItemType Directory -Path $script:caseRoot -Force | Out-Null
        [IO.File]::WriteAllText(
            $script:storePath,
            '{"schema_version":"1","credentials":{}}'
        )

        (Get-TestExceptionMessage {
            Get-ManagedCredentialMetadata -StorePath $script:storePath
        }) | Should Be 'Credential store is invalid.'
    }

    It 'rejects case-variant credential field names' {
        New-Item -ItemType Directory -Path $script:caseRoot -Force | Out-Null
        $json = @'
{"schema_version":"1","credentials":[{"Name":"x","ciphertext":"AA==","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}]}
'@
        [IO.File]::WriteAllText($script:storePath, $json)

        (Get-TestExceptionMessage {
            Get-ManagedCredentialMetadata -StorePath $script:storePath
        }) | Should Be 'Credential store is invalid.'
    }

    It 'rejects unknown credential fields' {
        New-Item -ItemType Directory -Path $script:caseRoot -Force | Out-Null
        $json = @'
{"schema_version":"1","credentials":[{"name":"x","ciphertext":"AA==","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z","extra":"x"}]}
'@
        [IO.File]::WriteAllText($script:storePath, $json)

        (Get-TestExceptionMessage {
            Get-ManagedCredentialMetadata -StorePath $script:storePath
        }) | Should Be 'Credential store is invalid.'
    }

    It 'rejects empty or non-string credential fields' {
        New-Item -ItemType Directory -Path $script:caseRoot -Force | Out-Null
        $json = @'
{"schema_version":"1","credentials":[{"name":123,"ciphertext":"","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}]}
'@
        [IO.File]::WriteAllText($script:storePath, $json)

        (Get-TestExceptionMessage {
            Get-ManagedCredentialMetadata -StorePath $script:storePath
        }) | Should Be 'Credential store is invalid.'
    }

    It 'rejects stored duplicate names that differ only by casing' {
        Set-ManagedCredential -Name 'CaseName' -Secret $script:secret -StorePath $script:storePath
        $document = [IO.File]::ReadAllText($script:storePath) | ConvertFrom-Json
        $duplicate = [pscustomobject][ordered]@{
            name = 'casename'
            ciphertext = $document.credentials[0].ciphertext
            created_at = $document.credentials[0].created_at
            updated_at = $document.credentials[0].updated_at
        }
        $document.credentials = @($document.credentials[0], $duplicate)
        [IO.File]::WriteAllText(
            $script:storePath,
            ($document | ConvertTo-Json -Depth 4)
        )

        $message = Get-TestExceptionMessage {
            Get-ManagedCredentialMetadata -StorePath $script:storePath
        }

        $message | Should Be 'Credential store is invalid.'
    }

    It 'treats tampered ciphertext as a fatal non-sensitive error' {
        Set-ManagedCredential -Name 'service-token' -Secret $script:secret -StorePath $script:storePath
        $document = [IO.File]::ReadAllText($script:storePath) | ConvertFrom-Json
        $document.credentials[0].ciphertext = [Convert]::ToBase64String(
            [Guid]::NewGuid().ToByteArray()
        )
        [IO.File]::WriteAllText(
            $script:storePath,
            ($document | ConvertTo-Json -Depth 4)
        )

        $message = Get-TestExceptionMessage {
            Get-ManagedCredential -Name 'service-token' -StorePath $script:storePath
        }

        $message | Should Be 'Managed credential could not be decrypted.'
        $message.Contains($script:secretText) | Should Be $false
        $message.Contains($document.credentials[0].ciphertext) | Should Be $false
    }

    It 'supports a store path containing spaces and codepoint-built Unicode' {
        $unicodeDirectory = -join @(
            [char]0x51ED, [char]0x636E, [char]0x5B58, [char]0x50A8
        )
        $path = Join-Path $script:caseRoot (
            Join-Path ('path with spaces ' + $unicodeDirectory) 'credentials.dpapi'
        )

        Set-ManagedCredential -Name 'service-token' -Secret $script:secret -StorePath $path

        (ConvertFrom-TestSecureString (
            Get-ManagedCredential -Name 'service-token' -StorePath $path
        )) | Should Be $script:secretText
    }

    It 'does not leave atomic write temporary files' {
        Set-ManagedCredential -Name 'service-token' -Secret $script:secret -StorePath $script:storePath
        Set-ManagedCredential -Name 'service-token' -Secret $script:secret -StorePath $script:storePath

        $residue = @(Get-ChildItem -LiteralPath $script:caseRoot -File | Where-Object {
            $_.Name -like '*.tmp-*' -or $_.Name -like '*.bak-*'
        })
        $residue.Count | Should Be 0
        $lockPath = $script:storePath + '.lock'
        (Test-Path -LiteralPath $lockPath -PathType Leaf) | Should Be $true
        (Get-Item -LiteralPath $lockPath).Length | Should Be 0
        ([IO.File]::ReadAllText($lockPath).Contains($script:secretText)) |
            Should Be $false
    }

    It 'serializes same-path writers released by a startup barrier' {
        $result = Invoke-TestConcurrentWriters -StorePaths @($script:storePath) `
            -WriterCount 8 -WorkingRoot $script:caseRoot `
            -SecretPrefix $script:secretText

        @($result.ExitCodes | Where-Object { $_ -ne 0 }).Count | Should Be 0
        @(Get-ManagedCredentialMetadata -StorePath $script:storePath).Count |
            Should Be 8
    }

    It 'serializes junction-alias writers against the same lock file' `
        -Skip:(-not $script:junctionAvailable) {
        New-Item -ItemType Directory -Path $script:caseRoot -Force | Out-Null
        $aliasRoot = $script:caseRoot + '-junction'
        New-Item -ItemType Junction -Path $aliasRoot -Target $script:caseRoot |
            Out-Null
        try {
            $aliasStorePath = Join-Path $aliasRoot 'credentials.dpapi'
            $result = Invoke-TestConcurrentWriters `
                -StorePaths @($script:storePath, $aliasStorePath) `
                -WriterCount 20 -WorkingRoot $script:caseRoot `
                -SecretPrefix $script:secretText

            @($result.ExitCodes | Where-Object { $_ -ne 0 }).Count | Should Be 0
            @(Get-ManagedCredentialMetadata -StorePath $script:storePath).Count |
                Should Be 20
        }
        finally {
            if (Test-Path -LiteralPath $aliasRoot) {
                [IO.Directory]::Delete($aliasRoot)
            }
        }
    }

    It 'protects the storage directory for only the current user and SYSTEM' {
        Set-ManagedCredential -Name 'service-token' -Secret $script:secret `
            -StorePath $script:storePath

        $acl = Get-Acl -LiteralPath $script:caseRoot
        $currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User
        $systemSid = New-Object Security.Principal.SecurityIdentifier('S-1-5-18')
        $rules = @($acl.GetAccessRules(
            $true,
            $false,
            [Security.Principal.SecurityIdentifier]
        ))

        $acl.AreAccessRulesProtected | Should Be $true
        @($rules | Where-Object {
            $_.AccessControlType -eq 'Allow' -and
            $_.IdentityReference -ne $currentSid -and
            $_.IdentityReference -ne $systemSid
        }).Count | Should Be 0
        @($rules | Where-Object {
            $_.IdentityReference -eq $currentSid -and
            ($_.FileSystemRights -band [Security.AccessControl.FileSystemRights]::FullControl)
        }).Count | Should BeGreaterThan 0
        @($rules | Where-Object {
            $_.IdentityReference -eq $systemSid -and
            ($_.FileSystemRights -band [Security.AccessControl.FileSystemRights]::FullControl)
        }).Count | Should BeGreaterThan 0
        [IO.File]::WriteAllText((Join-Path $script:caseRoot 'write-check'), '')
    }

    It 'fails Set with a stable secret-free error when directory security cannot be established' {
        New-Item -ItemType Directory -Path $script:caseRoot -Force | Out-Null
        $blockedParent = Join-Path $script:caseRoot $script:secretText
        [IO.File]::WriteAllText($blockedParent, '')
        $blockedStore = Join-Path $blockedParent 'credentials.dpapi'

        $message = Get-TestExceptionMessage {
            Set-ManagedCredential -Name 'service-token' -Secret $script:secret `
                -StorePath $blockedStore
        }

        $message | Should Be 'Credential store directory permissions could not be secured.'
        $message.Contains($script:secretText) | Should Be $false
    }
}
