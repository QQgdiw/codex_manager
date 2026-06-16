$commonLibrary = Join-Path $PSScriptRoot 'Common.ps1'
if (Test-Path -LiteralPath $commonLibrary -PathType Leaf) {
    . $commonLibrary
}

$script:VerificationAllowedStatuses = @(
    'not_verified',
    'static_verified',
    'load_verified',
    'smoke_verified',
    'partial',
    'failed',
    'blocked'
)

function Assert-VerificationStatus {
    param([string]$Status)

    if ($script:VerificationAllowedStatuses -notcontains $Status) {
        throw "Verification status '$Status' is not allowed."
    }
}

function Get-VerificationMemberValue {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Object,

        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    foreach ($name in $Names) {
        $property = $Object.PSObject.Properties[$name]
        if ($null -ne $property) {
            return $property.Value
        }
    }

    return $null
}

function Get-VerificationString {
    param(
        [object]$Object,
        [string[]]$Names
    )

    $value = Get-VerificationMemberValue -Object $Object -Names $Names
    if ($null -eq $value) {
        return ''
    }

    return [string]$value
}

function Get-VerificationArray {
    param([object]$Value)

    if ($null -eq $Value) {
        return @()
    }

    if ($Value -is [string]) {
        if ([string]::IsNullOrEmpty($Value)) {
            return @()
        }
        return @($Value)
    }

    return @($Value)
}

function Get-VerificationSensitiveRedactions {
    param([object]$Tool)

    $redactions = Get-VerificationArray -Value (
        Get-VerificationMemberValue -Object $Tool -Names @('SensitiveRedactions', 'sensitive_redactions')
    )
    return @($redactions | Where-Object { -not [string]::IsNullOrEmpty([string]$_) })
}

function New-VerificationResult {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Tool,

        [Parameter(Mandatory = $true)]
        [string]$Level,

        [Parameter(Mandatory = $true)]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [DateTime]$StartedAt,

        [AllowNull()]
        [object[]]$Checks = @(),

        [AllowNull()]
        [object[]]$Residuals = @(),

        [AllowNull()]
        [string[]]$SensitiveRedactions = @(),

        [AllowNull()]
        [object]$ErrorCode = $null
    )

    Assert-VerificationStatus -Status $Status

    $finishedAt = [DateTime]::UtcNow
    if ($finishedAt -lt $StartedAt) {
        $finishedAt = $StartedAt
    }

    $redactions = @(Get-VerificationArray -Value $SensitiveRedactions)
    $safeChecks = @()
    foreach ($check in @(Get-VerificationArray -Value $Checks)) {
        $safeChecks += Protect-VerificationText -Text ([string]$check) -SensitiveValues $redactions
    }
    $safeResiduals = @()
    foreach ($residual in @(Get-VerificationArray -Value $Residuals)) {
        $safeResiduals += Protect-VerificationText -Text ([string]$residual) -SensitiveValues $redactions
    }
    $safeErrorCode = $ErrorCode
    if ($null -ne $safeErrorCode) {
        $safeErrorCode = Protect-VerificationText -Text ([string]$safeErrorCode) -SensitiveValues $redactions
    }

    return [pscustomobject][ordered]@{
        ToolId = Get-VerificationString -Object $Tool -Names @('id', 'ToolId')
        Name = Get-VerificationString -Object $Tool -Names @('name', 'Name')
        Type = Get-VerificationString -Object $Tool -Names @('type', 'Type')
        Version = Get-VerificationString -Object $Tool -Names @('version', 'Version')
        Source = Get-VerificationString -Object $Tool -Names @('source', 'Source')
        Level = $Level
        Status = $Status
        Message = Protect-VerificationText -Text $Message -SensitiveValues $redactions
        StartedAt = $StartedAt.ToUniversalTime()
        FinishedAt = $finishedAt.ToUniversalTime()
        Checks = @($safeChecks)
        Residuals = @($safeResiduals)
        SensitiveRedactions = @($redactions)
        ErrorCode = $safeErrorCode
    }
}

function Test-VerificationToolObject {
    param([object]$Tool)

    if ($null -eq $Tool) {
        throw 'Tool must not be null.'
    }
}

function Test-VerificationCredentialMetadata {
    param([object]$Tool)

    $credentialRefs = Get-VerificationArray -Value (
        Get-VerificationMemberValue -Object $Tool -Names @('credential_refs', 'CredentialRefs')
    )
    if ($credentialRefs.Count -eq 0) {
        return $true
    }

    $metadataProperty = $Tool.PSObject.Properties['CredentialMetadata']
    if ($null -eq $metadataProperty -or $null -eq $metadataProperty.Value) {
        return $false
    }

    $metadata = $metadataProperty.Value
    foreach ($credentialRef in $credentialRefs) {
        $name = [string]$credentialRef
        if ($metadata -is [Collections.IDictionary]) {
            if (-not $metadata.Contains($name)) {
                return $false
            }
        }
        elseif ($null -eq $metadata.PSObject.Properties[$name]) {
            return $false
        }
    }

    return $true
}

function Test-VerificationCredentialRefsDeclared {
    param([object]$Tool)

    foreach ($name in @('credential_refs', 'CredentialRefs')) {
        if ($null -ne $Tool.PSObject.Properties[$name]) {
            return $true
        }
    }

    return $false
}

function Get-VerificationAdapterResultValue {
    param(
        [object]$AdapterResult,
        [string]$Name,
        [object]$DefaultValue
    )

    if ($null -eq $AdapterResult) {
        return $DefaultValue
    }

    if ($AdapterResult -is [Collections.IDictionary] -and $AdapterResult.Contains($Name)) {
        return $AdapterResult[$Name]
    }

    $property = $AdapterResult.PSObject.Properties[$Name]
    if ($null -ne $property) {
        return $property.Value
    }

    return $DefaultValue
}

function ConvertTo-VerificationResultFromAdapter {
    param(
        [object]$Tool,
        [string]$Level,
        [DateTime]$StartedAt,
        [object]$AdapterResult,
        [string]$DefaultSuccessStatus
    )

    $status = [string](Get-VerificationAdapterResultValue `
        -AdapterResult $AdapterResult `
        -Name 'Status' `
        -DefaultValue $DefaultSuccessStatus)
    $message = [string](Get-VerificationAdapterResultValue `
        -AdapterResult $AdapterResult `
        -Name 'Message' `
        -DefaultValue '')
    $checks = Get-VerificationAdapterResultValue `
        -AdapterResult $AdapterResult `
        -Name 'Checks' `
        -DefaultValue @()
    $residuals = Get-VerificationAdapterResultValue `
        -AdapterResult $AdapterResult `
        -Name 'Residuals' `
        -DefaultValue @()
    $sensitiveRedactions = @(Get-VerificationSensitiveRedactions -Tool $Tool) + @(
        Get-VerificationAdapterResultValue `
        -AdapterResult $AdapterResult `
        -Name 'SensitiveRedactions' `
        -DefaultValue @()
    )
    $errorCode = Get-VerificationAdapterResultValue `
        -AdapterResult $AdapterResult `
        -Name 'ErrorCode' `
        -DefaultValue $null

    if ($script:VerificationAllowedStatuses -notcontains $status) {
        $status = 'failed'
        $message = 'Verifier returned an unsupported status.'
        $errorCode = 'verifier_invalid_status'
    }

    return New-VerificationResult `
        -Tool $Tool `
        -Level $Level `
        -Status $status `
        -Message $message `
        -StartedAt $StartedAt `
        -Checks $checks `
        -Residuals $residuals `
        -SensitiveRedactions $sensitiveRedactions `
        -ErrorCode $errorCode
}

function Invoke-StaticVerification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Tool
    )

    Test-VerificationToolObject -Tool $Tool
    $startedAt = [DateTime]::UtcNow
    $checks = @()
    $errors = @()

    foreach ($field in @('id', 'name', 'type', 'source', 'version')) {
        $value = Get-VerificationMemberValue -Object $Tool -Names @($field)
        if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value)) {
            $errors += "Missing required field: $field"
        }
        else {
            $checks += "required_field_ok:$field"
        }
    }

    $paths = Get-VerificationArray -Value (
        Get-VerificationMemberValue -Object $Tool -Names @('Paths', 'paths')
    )
    foreach ($path in $paths) {
        if (Test-Path -LiteralPath ([string]$path)) {
            $checks += "path_exists:$path"
        }
        else {
            $errors += "Missing path: $path"
        }
    }

    $commands = Get-VerificationArray -Value (
        Get-VerificationMemberValue -Object $Tool -Names @('Commands', 'commands')
    )
    foreach ($command in $commands) {
        if ($null -ne (Get-Command -Name ([string]$command) -ErrorAction SilentlyContinue)) {
            $checks += "command_exists:$command"
        }
        else {
            $errors += "Missing command: $command"
        }
    }

    $credentialRefsDeclared = Test-VerificationCredentialRefsDeclared -Tool $Tool
    if (-not $credentialRefsDeclared) {
        $checks += 'credential_refs_missing'
        $errors += 'Missing required field: credential_refs'
    }
    elseif (-not (Test-VerificationCredentialMetadata -Tool $Tool)) {
        $checks += 'credential_missing'
    }

    if ($errors.Count -gt 0) {
        $errorCode = 'static_required_field_missing'
        if (-not $credentialRefsDeclared) {
            $errorCode = 'credential_refs_missing'
        }

        return New-VerificationResult `
            -Tool $Tool `
            -Level 'static' `
            -Status 'failed' `
            -Message ($errors -join '; ') `
            -StartedAt $startedAt `
            -Checks $checks `
            -ErrorCode $errorCode
    }

    return New-VerificationResult `
        -Tool $Tool `
        -Level 'static' `
        -Status 'static_verified' `
        -Message 'Static verification completed.' `
        -StartedAt $startedAt `
        -Checks $checks
}

function Invoke-LoadVerification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Tool
    )

    Test-VerificationToolObject -Tool $Tool
    $startedAt = [DateTime]::UtcNow
    $staticResult = Invoke-StaticVerification -Tool $Tool
    if (@($staticResult.Checks) -contains 'credential_refs_missing') {
        return New-VerificationResult `
            -Tool $Tool `
            -Level 'load' `
            -Status 'blocked' `
            -Message 'Credential requirement declaration is missing.' `
            -StartedAt $startedAt `
            -Checks @($staticResult.Checks) `
            -ErrorCode 'credential_refs_missing'
    }

    if ($staticResult.Status -ne 'static_verified') {
        return New-VerificationResult `
            -Tool $Tool `
            -Level 'load' `
            -Status 'blocked' `
            -Message 'Load verification requires successful static verification.' `
            -StartedAt $startedAt `
            -Checks @($staticResult.Checks) `
            -ErrorCode 'static_not_verified'
    }

    if (-not (Test-VerificationCredentialMetadata -Tool $Tool)) {
        return New-VerificationResult `
            -Tool $Tool `
            -Level 'load' `
            -Status 'blocked' `
            -Message 'Required credential metadata is missing.' `
            -StartedAt $startedAt `
            -Checks @($staticResult.Checks) `
            -ErrorCode 'credential_missing'
    }

    $verifier = Get-VerificationMemberValue -Object $Tool -Names @('LoadVerifier', 'load_verifier')
    if ($null -eq $verifier -or -not ($verifier -is [scriptblock])) {
        return New-VerificationResult `
            -Tool $Tool `
            -Level 'load' `
            -Status 'blocked' `
            -Message 'No load verifier was provided.' `
            -StartedAt $startedAt `
            -Checks @($staticResult.Checks) `
            -ErrorCode 'load_verifier_missing'
    }

    try {
        $adapterResult = & $verifier $Tool
    }
    catch {
        return New-VerificationResult `
            -Tool $Tool `
            -Level 'load' `
            -Status 'failed' `
            -Message $_.Exception.Message `
            -StartedAt $startedAt `
            -Checks @($staticResult.Checks) `
            -SensitiveRedactions (Get-VerificationSensitiveRedactions -Tool $Tool) `
            -ErrorCode 'load_verifier_exception'
    }

    $result = ConvertTo-VerificationResultFromAdapter `
        -Tool $Tool `
        -Level 'load' `
        -StartedAt $startedAt `
        -AdapterResult $adapterResult `
        -DefaultSuccessStatus 'load_verified'
    $result.Checks = @($staticResult.Checks) + @($result.Checks)
    return $result
}

function Invoke-SmokeVerification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Tool
    )

    Test-VerificationToolObject -Tool $Tool
    $startedAt = [DateTime]::UtcNow
    $loadResult = Invoke-LoadVerification -Tool $Tool
    if ($loadResult.Status -ne 'load_verified') {
        $errorCode = 'load_not_verified'
        $message = 'Smoke verification requires successful load verification.'
        if (@('credential_missing', 'credential_refs_missing') -contains $loadResult.ErrorCode) {
            $errorCode = $loadResult.ErrorCode
            if ($loadResult.ErrorCode -eq 'credential_missing') {
                $message = 'Required credential metadata is missing.'
            }
            else {
                $message = 'Credential requirement declaration is missing.'
            }
        }

        return New-VerificationResult `
            -Tool $Tool `
            -Level 'smoke' `
            -Status 'blocked' `
            -Message $message `
            -StartedAt $startedAt `
            -Checks @($loadResult.Checks) `
            -Residuals @($loadResult.Residuals) `
            -SensitiveRedactions @($loadResult.SensitiveRedactions) `
            -ErrorCode $errorCode
    }

    $verifier = Get-VerificationMemberValue -Object $Tool -Names @('SmokeVerifier', 'smoke_verifier')
    if ($null -eq $verifier -or -not ($verifier -is [scriptblock])) {
        return New-VerificationResult `
            -Tool $Tool `
            -Level 'smoke' `
            -Status 'blocked' `
            -Message 'No smoke verifier was provided.' `
            -StartedAt $startedAt `
            -Checks @($loadResult.Checks) `
            -Residuals @($loadResult.Residuals) `
            -SensitiveRedactions @($loadResult.SensitiveRedactions) `
            -ErrorCode 'smoke_verifier_missing'
    }

    try {
        $adapterResult = & $verifier $Tool
    }
    catch {
        return New-VerificationResult `
            -Tool $Tool `
            -Level 'smoke' `
            -Status 'failed' `
            -Message $_.Exception.Message `
            -StartedAt $startedAt `
            -Checks @($loadResult.Checks) `
            -Residuals @($loadResult.Residuals) `
            -SensitiveRedactions @($loadResult.SensitiveRedactions) `
            -ErrorCode 'smoke_verifier_exception'
    }

    $result = ConvertTo-VerificationResultFromAdapter `
        -Tool $Tool `
        -Level 'smoke' `
        -StartedAt $startedAt `
        -AdapterResult $adapterResult `
        -DefaultSuccessStatus 'smoke_verified'
    $result.Checks = @($loadResult.Checks) + @($result.Checks)
    $result.Residuals = @($loadResult.Residuals) + @($result.Residuals)
    $result.SensitiveRedactions = @($loadResult.SensitiveRedactions) + @($result.SensitiveRedactions)
    return $result
}

function Protect-VerificationText {
    param(
        [AllowEmptyString()]
        [string]$Text,

        [AllowNull()]
        [string[]]$SensitiveValues = @()
    )

    $protected = $Text
    if (Get-Command -Name Protect-LogText -ErrorAction SilentlyContinue) {
        $protected = Protect-LogText -Text $protected -SensitiveValues $SensitiveValues
    }
    else {
        foreach ($value in @($SensitiveValues | Where-Object { -not [string]::IsNullOrEmpty($_) })) {
            $protected = $protected.Replace($value, '[REDACTED]')
        }
    }

    $protected = $protected -replace '(?i)(secret|token|cookie|password|api[_-]?key)\s*[:=]\s*[^,\s;]+', '$1=[REDACTED]'
    return $protected
}

function ConvertTo-VerificationMarkdownLine {
    param(
        [string]$Label,
        [object]$Value,
        [string[]]$SensitiveValues
    )

    $text = ''
    if ($null -ne $Value) {
        if ($Value -is [array]) {
            $text = (@($Value) -join '; ')
        }
        else {
            $text = [string]$Value
        }
    }
    if ([string]::IsNullOrEmpty($text)) {
        $text = 'none'
    }

    return "- ${Label}: $(Protect-VerificationText -Text $text -SensitiveValues $SensitiveValues)"
}

function Assert-VerificationRecordPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'Record path must not be empty.'
    }

    $fullPath = [IO.Path]::GetFullPath($Path)
    $parent = [IO.Path]::GetDirectoryName($fullPath)
    $userProfile = [Environment]::GetFolderPath('UserProfile')
    if ($parent -eq $userProfile) {
        throw 'Verification records must not be written directly to the user profile.'
    }

    return $fullPath
}

function Write-VerificationRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Result,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [AllowNull()]
        [string[]]$SensitiveValues = @()
    )

    if ($null -eq $Result) {
        throw 'Result must not be null.'
    }

    Assert-VerificationStatus -Status ([string]$Result.Status)
    $fullPath = Assert-VerificationRecordPath -Path $Path
    $parent = [IO.Path]::GetDirectoryName($fullPath)
    if (-not [string]::IsNullOrEmpty($parent) -and
        -not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $redactions = @($SensitiveValues) + @($Result.SensitiveRedactions)
    $startedAt = ([DateTime]$Result.StartedAt).ToUniversalTime().ToString('o')
    $finishedAt = ([DateTime]$Result.FinishedAt).ToUniversalTime().ToString('o')
    $verificationSummary = "level=$($Result.Level); status=$($Result.Status); checks=$(@($Result.Checks).Count); residuals=$(@($Result.Residuals).Count)"
    $caveat = 'none'
    if ($Result.Status -eq 'static_verified' -or $Result.Level -eq 'static') {
        $caveat = '仅完成静态验证，不代表工具已完全可用'
    }
    $lines = @(
        '## Verification Record',
        '',
        (ConvertTo-VerificationMarkdownLine -Label 'Tool' -Value $Result.Name -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'ToolId' -Value $Result.ToolId -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'Type' -Value $Result.Type -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'Version' -Value $Result.Version -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'Source' -Value $Result.Source -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'Level' -Value $Result.Level -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'Status' -Value $Result.Status -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'Message' -Value $Result.Message -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'StartedAt' -Value $startedAt -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'FinishedAt' -Value $finishedAt -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'Checks' -Value $Result.Checks -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'Verification summary' -Value $verificationSummary -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'Caveat' -Value $caveat -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'Rollback' -Value 'not_performed_by_verification_engine' -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'Residuals' -Value $Result.Residuals -SensitiveValues $redactions),
        (ConvertTo-VerificationMarkdownLine -Label 'BlockingReason' -Value $Result.ErrorCode -SensitiveValues $redactions),
        ''
    )

    Add-Content -LiteralPath $fullPath -Value $lines -Encoding UTF8
}
