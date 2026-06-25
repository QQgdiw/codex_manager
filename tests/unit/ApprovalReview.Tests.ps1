$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tomlLibrary = Join-Path $projectRoot 'scripts\lib\Read-Toml.ps1'
$reviewPath = Join-Path $projectRoot 'Resources\approval_review.toml'
$whitelistPath = Join-Path $projectRoot 'Resources\tool_whitelist.toml'

function New-ValidApprovalReview {
    return @{
        id = 'plugin.openai-bundled.browser'
        name = 'Browser'
        type = 'plugin'
        source = 'https://github.com/openai/openai/tree/master/lib/browser_use/plugin'
        version = '26.609.41114'
        license = 'Proprietary'
        whitelist_status = 'approved'
        implementation_method = 'managed plugin install'
        primary_use = 'Browser automation and local web verification'
        risk_level = 'medium'
        risk_reason = 'Can operate an interactive browser session against user-selected targets.'
        verification_status = 'manifest hash captured in whitelist'
        recommended_action = 'approve_now'
        recommendation_reason = 'Already approved for the phase 1 closed loop.'
        approval_command_hint = 'Use the deployment workflow that reads Resources/tool_whitelist.toml.'
        dependencies = @()
        permissions = @('browser automation')
        scenario_fit = @('local web app verification')
    }
}

function Test-ApprovalReviewDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Document,

        [Parameter(Mandatory = $true)]
        [object]$WhitelistDocument
    )

    $errors = New-Object System.Collections.Generic.List[string]
    if (-not (Test-ProjectObject -Value $Document)) {
        $errors.Add('Approval review document must be a readable object.')
        return [pscustomobject]@{ IsValid = $false; Errors = @($errors) }
    }

    $reviewsMember = Get-ProjectMember -InputObject $Document -Name 'reviews'
    if (-not $reviewsMember.Exists -or $null -eq $reviewsMember.Value) {
        $errors.Add("Document is missing required 'reviews' collection.")
        $reviews = @()
    }
    elseif ($reviewsMember.Value -isnot [System.Array]) {
        $errors.Add("Document 'reviews' value must be an array.")
        $reviews = @()
    }
    else {
        $reviews = @($reviewsMember.Value)
    }

    $whitelistIds = @{}
    foreach ($tool in @($WhitelistDocument.tools)) {
        $idMember = Get-ProjectMember -InputObject $tool -Name 'id'
        if ($idMember.Exists -and $idMember.Value -is [string]) {
            $whitelistIds[$idMember.Value] = $true
        }
    }

    $stringFields = @(
        'id', 'name', 'type', 'source', 'version', 'license',
        'whitelist_status', 'implementation_method', 'primary_use',
        'risk_level', 'risk_reason', 'verification_status',
        'recommended_action', 'recommendation_reason', 'approval_command_hint'
    )
    $arrayFields = @('dependencies', 'permissions', 'scenario_fit')
    $allowedActions = @('approve_now', 'approve_later', 'reject', 'needs_review')
    $allowedRiskLevels = @('low', 'medium', 'high')
    $seenIds = @{}

    for ($index = 0; $index -lt $reviews.Count; $index++) {
        $review = $reviews[$index]
        $label = "reviews[$index]"

        if (-not (Test-ProjectObject -Value $review)) {
            $errors.Add("$label must be an object.")
            continue
        }

        $members = @{}
        foreach ($field in $stringFields + $arrayFields) {
            $members[$field] = Get-ProjectMember -InputObject $review -Name $field
            if (-not $members[$field].Exists) {
                $errors.Add("$label is missing required field '$field'.")
            }
        }

        foreach ($field in $stringFields) {
            $member = $members[$field]
            if ($member.Exists -and
                ($member.Value -isnot [string] -or
                    [string]::IsNullOrWhiteSpace($member.Value))) {
                $errors.Add("$label field '$field' must be a non-empty string.")
            }
        }

        foreach ($field in $arrayFields) {
            $member = $members[$field]
            if (-not $member.Exists) {
                continue
            }
            if ($member.Value -isnot [System.Array]) {
                $errors.Add("$label field '$field' must be an array.")
                continue
            }
            for ($itemIndex = 0; $itemIndex -lt $member.Value.Count; $itemIndex++) {
                $item = $member.Value[$itemIndex]
                if ($item -isnot [string] -or [string]::IsNullOrWhiteSpace($item)) {
                    $errors.Add(
                        "$label field '$field[$itemIndex]' must be a non-empty string."
                    )
                }
            }
        }

        $idMember = $members['id']
        if ($idMember.Exists -and $idMember.Value -is [string] -and
            -not [string]::IsNullOrWhiteSpace($idMember.Value)) {
            $id = $idMember.Value
            if (-not $whitelistIds.ContainsKey($id)) {
                $errors.Add("$label id '$id' does not exist in Resources/tool_whitelist.toml.")
            }
            if ($seenIds.ContainsKey($id)) {
                $errors.Add("$label has duplicate id '$id'.")
            }
            else {
                $seenIds[$id] = $true
            }
        }

        $actionMember = $members['recommended_action']
        if ($actionMember.Exists -and $actionMember.Value -is [string] -and
            -not [string]::IsNullOrWhiteSpace($actionMember.Value) -and
            $allowedActions -notcontains $actionMember.Value) {
            $errors.Add("$label field 'recommended_action' has an invalid value.")
        }

        $riskMember = $members['risk_level']
        if ($riskMember.Exists -and $riskMember.Value -is [string] -and
            -not [string]::IsNullOrWhiteSpace($riskMember.Value) -and
            $allowedRiskLevels -notcontains $riskMember.Value) {
            $errors.Add("$label field 'risk_level' has an invalid value.")
        }
    }

    return [pscustomobject]@{
        IsValid = ($errors.Count -eq 0)
        Errors = @($errors)
    }
}

Describe 'Test-ApprovalReviewDocument' {
    BeforeAll {
        . $tomlLibrary
    }

    It 'accepts the project approval review document' {
        $document = Read-ProjectToml -Path $reviewPath
        $whitelist = Read-ProjectToml -Path $whitelistPath

        $result = Test-ApprovalReviewDocument -Document $document -WhitelistDocument $whitelist

        $result.IsValid | Should Be $true
        $result.Errors.Count | Should Be 0
    }

    It 'has one review for every current whitelist tool' {
        $document = Read-ProjectToml -Path $reviewPath
        $whitelist = Read-ProjectToml -Path $whitelistPath

        $reviewIds = @($document.reviews | ForEach-Object { $_.id } | Sort-Object)
        $whitelistIds = @($whitelist.tools | ForEach-Object { $_.id } | Sort-Object)

        $reviewIds.Count | Should Be $whitelistIds.Count
        ($reviewIds -join "`n") | Should Be ($whitelistIds -join "`n")
    }

    It 'rejects invalid id, action, and risk values' {
        $whitelist = Read-ProjectToml -Path $whitelistPath
        $invalid = New-ValidApprovalReview
        $invalid.id = 'tool.not-in-whitelist'
        $invalid.recommended_action = 'approve_eventually'
        $invalid.risk_level = 'critical'
        $duplicate = New-ValidApprovalReview
        $document = @{ reviews = @($invalid, $duplicate, $duplicate) }

        $result = Test-ApprovalReviewDocument -Document $document -WhitelistDocument $whitelist
        $messages = $result.Errors -join "`n"

        $result.IsValid | Should Be $false
        $messages | Should Match 'does not exist'
        $messages | Should Match 'recommended_action'
        $messages | Should Match 'risk_level'
        $messages | Should Match 'duplicate id'
    }
}
