$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$verificationLibrary = Join-Path $projectRoot 'scripts\lib\VerificationEngine.ps1'

function New-TestVerificationTool {
    param(
        [string]$Id = 'tool.alpha',
        [string]$Name = 'Tool Alpha',
        [string]$Type = 'skill',
        [string]$Source = 'https://example.invalid/tool.alpha',
        [string]$Version = 'v1.0.0',
        [string[]]$CredentialRefs = @(),
        [object]$CredentialMetadata = $null,
        [string[]]$Paths = @(),
        [string[]]$Commands = @(),
        [scriptblock]$LoadVerifier = $null,
        [scriptblock]$SmokeVerifier = $null,
        [switch]$OmitCredentialRefs
    )

    $tool = [ordered]@{
        id = $Id
        name = $Name
        type = $Type
        source = $Source
        version = $Version
    }
    if (-not $OmitCredentialRefs) {
        $tool.credential_refs = @($CredentialRefs)
    }
    if ($PSBoundParameters.ContainsKey('CredentialMetadata')) {
        $tool.CredentialMetadata = $CredentialMetadata
    }
    if ($Paths.Count -gt 0) {
        $tool.Paths = @($Paths)
    }
    if ($Commands.Count -gt 0) {
        $tool.Commands = @($Commands)
    }
    if ($null -ne $LoadVerifier) {
        $tool.LoadVerifier = $LoadVerifier
    }
    if ($null -ne $SmokeVerifier) {
        $tool.SmokeVerifier = $SmokeVerifier
    }

    return [pscustomobject]$tool
}

function New-TestSensitiveValue {
    return -join @(
        [char]0x0053, [char]0x0065, [char]0x006E, [char]0x0073,
        [char]0x0069, [char]0x0074, [char]0x0069, [char]0x0076,
        [char]0x0065, [char]0x002D, [char]0x0056, [char]0x0061,
        [char]0x006C, [char]0x0075, [char]0x0065, [char]0x002D,
        [char]0x0037, [char]0x0031, [char]0x0039
    )
}

Describe 'Layered tool verification' {
    BeforeAll {
        . $verificationLibrary
    }

    It 'returns a stable static verification result for a valid tool' {
        $existingPath = Join-Path $projectRoot 'README.md'
        $tool = New-TestVerificationTool -Paths @($existingPath) -Commands @('powershell')

        $result = Invoke-StaticVerification -Tool $tool

        $result.ToolId | Should Be 'tool.alpha'
        $result.Name | Should Be 'Tool Alpha'
        $result.Type | Should Be 'skill'
        $result.Version | Should Be 'v1.0.0'
        $result.Source | Should Be 'https://example.invalid/tool.alpha'
        $result.Level | Should Be 'static'
        $result.Status | Should Be 'static_verified'
        $result.ErrorCode | Should Be $null
        @($result.Checks).Count | Should BeGreaterThan 0
        $result.StartedAt.Kind | Should Be ([DateTimeKind]::Utc)
        $result.FinishedAt.Kind | Should Be ([DateTimeKind]::Utc)
        ($result.FinishedAt -ge $result.StartedAt) | Should Be $true
    }

    It 'returns failed instead of throwing for missing required fields' {
        $tool = New-TestVerificationTool
        $tool.PSObject.Properties.Remove('version')

        $result = Invoke-StaticVerification -Tool $tool

        $result.Status | Should Be 'failed'
        $result.ErrorCode | Should Be 'static_required_field_missing'
        ($result.Message -match 'version') | Should Be $true
    }

    It 'throws for a damaged tool structure' {
        { Invoke-StaticVerification -Tool $null } | Should Throw
    }

    It 'records missing credential metadata during static verification without failing static checks' {
        $tool = New-TestVerificationTool -CredentialRefs @('service-token')

        $result = Invoke-StaticVerification -Tool $tool

        $result.Status | Should Be 'static_verified'
        (@($result.Checks) -join "`n") | Should Match 'credential_missing'
    }

    It 'records missing credential_refs during static verification' {
        $tool = New-TestVerificationTool -OmitCredentialRefs

        $result = Invoke-StaticVerification -Tool $tool

        $result.Status | Should Be 'failed'
        $result.ErrorCode | Should Be 'credential_refs_missing'
        (@($result.Checks) -join "`n") | Should Match 'credential_refs_missing'
    }

    It 'returns blocked for load verification when required credential metadata is absent' {
        $tool = New-TestVerificationTool `
            -CredentialRefs @('service-token') `
            -LoadVerifier { param($Tool) @{ Status = 'load_verified'; Message = 'loaded' } }

        $result = Invoke-LoadVerification -Tool $tool

        $result.Status | Should Be 'blocked'
        $result.ErrorCode | Should Be 'credential_missing'
        $result.Level | Should Be 'load'
    }

    It 'blocks load and smoke verification without calling verifiers when credential_refs field is absent' {
        $script:loadVerifierCalled = $false
        $script:smokeVerifierCalled = $false
        $tool = New-TestVerificationTool `
            -OmitCredentialRefs `
            -LoadVerifier {
                $script:loadVerifierCalled = $true
                @{ Status = 'load_verified'; Message = 'loaded' }
            } `
            -SmokeVerifier {
                $script:smokeVerifierCalled = $true
                @{ Status = 'smoke_verified'; Message = 'smoked' }
            }

        $loadResult = Invoke-LoadVerification -Tool $tool
        $smokeResult = Invoke-SmokeVerification -Tool $tool

        $loadResult.Status | Should Be 'blocked'
        $loadResult.ErrorCode | Should Be 'credential_refs_missing'
        (@($loadResult.Checks) -join "`n") | Should Match 'credential_refs_missing'
        $smokeResult.Status | Should Be 'blocked'
        $smokeResult.ErrorCode | Should Be 'credential_refs_missing'
        (@($smokeResult.Checks) -join "`n") | Should Match 'credential_refs_missing'
        $script:loadVerifierCalled | Should Be $false
        $script:smokeVerifierCalled | Should Be $false
    }

    It 'continues load and smoke verification when credential_refs is explicitly empty' {
        $script:loadVerifierCallCount = 0
        $script:smokeVerifierCalled = $false
        $tool = New-TestVerificationTool `
            -CredentialRefs @() `
            -LoadVerifier {
                $script:loadVerifierCallCount += 1
                @{ Status = 'load_verified'; Message = 'loaded without credentials' }
            } `
            -SmokeVerifier {
                $script:smokeVerifierCalled = $true
                @{ Status = 'smoke_verified'; Message = 'smoked without credentials' }
            }

        $loadResult = Invoke-LoadVerification -Tool $tool
        $smokeResult = Invoke-SmokeVerification -Tool $tool

        $loadResult.Status | Should Be 'load_verified'
        $loadResult.Message | Should Be 'loaded without credentials'
        $smokeResult.Status | Should Be 'smoke_verified'
        $smokeResult.Message | Should Be 'smoked without credentials'
        $script:loadVerifierCallCount | Should Be 2
        $script:smokeVerifierCalled | Should Be $true
    }

    It 'blocks load and smoke verification without calling verifiers when credential metadata is absent' {
        $script:loadVerifierCalled = $false
        $script:smokeVerifierCalled = $false
        $tool = New-TestVerificationTool `
            -CredentialRefs @('api-token') `
            -LoadVerifier {
                $script:loadVerifierCalled = $true
                @{ Status = 'load_verified'; Message = 'loaded' }
            } `
            -SmokeVerifier {
                $script:smokeVerifierCalled = $true
                @{ Status = 'smoke_verified'; Message = 'smoked' }
            }

        $loadResult = Invoke-LoadVerification -Tool $tool
        $smokeResult = Invoke-SmokeVerification -Tool $tool

        $loadResult.Status | Should Be 'blocked'
        $loadResult.ErrorCode | Should Be 'credential_missing'
        $smokeResult.Status | Should Be 'blocked'
        $smokeResult.ErrorCode | Should Be 'credential_missing'
        $script:loadVerifierCalled | Should Be $false
        $script:smokeVerifierCalled | Should Be $false
    }

    It 'returns blocked for load verification when static verification has not passed' {
        $tool = New-TestVerificationTool -Version ''

        $result = Invoke-LoadVerification -Tool $tool

        $result.Status | Should Be 'blocked'
        $result.ErrorCode | Should Be 'static_not_verified'
    }

    It 'returns blocked for load verification when no load verifier exists' {
        $tool = New-TestVerificationTool

        $result = Invoke-LoadVerification -Tool $tool

        $result.Status | Should Be 'blocked'
        $result.ErrorCode | Should Be 'load_verifier_missing'
    }

    It 'uses an injected load verifier to return load success' {
        $tool = New-TestVerificationTool `
            -LoadVerifier { param($Tool) @{ Status = 'load_verified'; Message = "loaded $($Tool.id)"; Checks = @('adapter_load_ok') } }

        $result = Invoke-LoadVerification -Tool $tool

        $result.Status | Should Be 'load_verified'
        $result.Message | Should Be 'loaded tool.alpha'
        (@($result.Checks) -join "`n") | Should Match 'adapter_load_ok'
    }

    It 'uses an injected load verifier to return load failure' {
        $tool = New-TestVerificationTool `
            -LoadVerifier { @{ Status = 'failed'; Message = 'load failed'; ErrorCode = 'load_failed' } }

        $result = Invoke-LoadVerification -Tool $tool

        $result.Status | Should Be 'failed'
        $result.ErrorCode | Should Be 'load_failed'
    }

    It 'returns blocked for smoke verification when load verification has not passed' {
        $tool = New-TestVerificationTool `
            -LoadVerifier { @{ Status = 'failed'; Message = 'load failed'; ErrorCode = 'load_failed' } } `
            -SmokeVerifier { @{ Status = 'smoke_verified'; Message = 'smoke ok' } }

        $result = Invoke-SmokeVerification -Tool $tool

        $result.Status | Should Be 'blocked'
        $result.ErrorCode | Should Be 'load_not_verified'
    }

    It 'returns blocked for smoke verification when no smoke verifier exists' {
        $tool = New-TestVerificationTool `
            -LoadVerifier { @{ Status = 'load_verified'; Message = 'loaded' } }

        $result = Invoke-SmokeVerification -Tool $tool

        $result.Status | Should Be 'blocked'
        $result.ErrorCode | Should Be 'smoke_verifier_missing'
    }

    It 'uses an injected smoke verifier to return smoke success' {
        $tool = New-TestVerificationTool `
            -LoadVerifier { @{ Status = 'load_verified'; Message = 'loaded' } } `
            -SmokeVerifier { @{ Status = 'smoke_verified'; Message = 'minimal call ok'; Checks = @('smoke_call_ok') } }

        $result = Invoke-SmokeVerification -Tool $tool

        $result.Status | Should Be 'smoke_verified'
        $result.Message | Should Be 'minimal call ok'
    }

    It 'uses an injected smoke verifier to return smoke failure' {
        $tool = New-TestVerificationTool `
            -LoadVerifier { @{ Status = 'load_verified'; Message = 'loaded' } } `
            -SmokeVerifier { @{ Status = 'failed'; Message = 'minimal call failed'; ErrorCode = 'smoke_failed' } }

        $result = Invoke-SmokeVerification -Tool $tool

        $result.Status | Should Be 'failed'
        $result.ErrorCode | Should Be 'smoke_failed'
    }

    It 'rejects statuses outside the verification enum' {
        $recordPath = Join-Path $TestDrive 'records\verify_record.md'
        $result = Invoke-StaticVerification -Tool (New-TestVerificationTool)
        $result.Status = 'available'

        { Write-VerificationRecord -Result $result -Path $recordPath } | Should Throw
    }

    It 'appends markdown records with required sections and status distinctions' {
        $recordPath = Join-Path $TestDrive 'records\verify_record.md'
        $staticResult = Invoke-StaticVerification -Tool (New-TestVerificationTool)
        $blockedResult = Invoke-LoadVerification -Tool (New-TestVerificationTool)

        Write-VerificationRecord -Result $staticResult -Path $recordPath
        Write-VerificationRecord -Result $blockedResult -Path $recordPath
        $content = Get-Content -LiteralPath $recordPath -Raw

        ($content -match '## Verification Record') | Should Be $true
        ($content -match 'Tool: Tool Alpha') | Should Be $true
        ($content -match 'Version: v1.0.0') | Should Be $true
        ($content -match 'Source: https://example.invalid/tool.alpha') | Should Be $true
        ($content -match 'Level: static') | Should Be $true
        ($content -match 'Status: static_verified') | Should Be $true
        ($content -match 'Status: blocked') | Should Be $true
        ($content -match 'Verification summary:') | Should Be $true
        ($content -match '仅完成静态验证，不代表工具已完全可用') | Should Be $true
        ($content -match 'Residuals') | Should Be $true
        ($content -match 'Rollback') | Should Be $true
        ($content -match 'fully available') | Should Be $false
    }

    It 'redacts sensitive values when writing verification records' {
        $recordPath = Join-Path $TestDrive 'records\verify_record.md'
        $sensitive = New-TestSensitiveValue
        $result = Invoke-StaticVerification -Tool (New-TestVerificationTool)
        $result.Message = "static check mentioned $sensitive"
        $result.Checks = @("check included $sensitive")
        $result.SensitiveRedactions = @($sensitive)

        Write-VerificationRecord -Result $result -Path $recordPath -SensitiveValues @($sensitive)
        $content = Get-Content -LiteralPath $recordPath -Raw

        ($content.Contains($sensitive)) | Should Be $false
        ($content -match '\[REDACTED\]') | Should Be $true
    }
}
