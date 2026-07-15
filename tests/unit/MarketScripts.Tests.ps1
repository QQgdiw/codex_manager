param(
    [switch]$ContractProbe
)

function ConvertFrom-ContractCodePoints {
    param(
        [int[]]$CodePoints
    )

    return [string]::Concat([char[]]$CodePoints)
}

function Get-PluginMarketContractDocuments {
    param(
        [string]$RepositoryRoot
    )

    return [pscustomobject]@{
        Prd = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'Resources\PRD.md') -Raw -Encoding UTF8
        Plan = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'Resources\PP.md') -Raw -Encoding UTF8
        Guide = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'Resources\GUIDE.md') -Raw -Encoding UTF8
        HistoricalDesign = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'docs\superpowers\specs\2026-06-25-market-approval-hardening-design.md') -Raw -Encoding UTF8
        HistoricalPlan = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'docs\superpowers\plans\2026-06-25-market-approval-hardening.md') -Raw -Encoding UTF8
    }
}

function Assert-PluginMarketSourceContract {
    param(
        [string]$Prd,
        [string]$Plan,
        [string]$Guide
    )

    $uniqueAuthority = ConvertFrom-ContractCodePoints @(0x552F, 0x4E00, 0x6536, 0x5F55, 0x6743, 0x5A01)
    $completeCatalog = ConvertFrom-ContractCodePoints @(0x5B8C, 0x6574, 0x6E05, 0x5355)
    $completeDirectory = ConvertFrom-ContractCodePoints @(0x5B8C, 0x6574, 0x76EE, 0x5F55)
    $all = ConvertFrom-ContractCodePoints @(0x6240, 0x6709)
    $returned = ConvertFrom-ContractCodePoints @(0x8FD4, 0x56DE)
    $record = ConvertFrom-ContractCodePoints @(0x8BB0, 0x5F55)
    $upstream = ConvertFrom-ContractCodePoints @(0x4E0A, 0x6E38)
    $rawDuplicates = ConvertFrom-ContractCodePoints @(0x539F, 0x59CB, 0x91CD, 0x590D)
    $relevance = ConvertFrom-ContractCodePoints @(0x76F8, 0x5173, 0x6027)
    $focusIndex = ConvertFrom-ContractCodePoints @(0x91CD, 0x70B9, 0x7D22, 0x5F15)
    $account = ConvertFrom-ContractCodePoints @(0x8D26, 0x6237)
    $workspace = ConvertFrom-ContractCodePoints @(0x5DE5, 0x4F5C, 0x533A)
    $visible = ConvertFrom-ContractCodePoints @(0x53EF, 0x89C1)
    $failure = ConvertFrom-ContractCodePoints @(0x5931, 0x8D25)
    $loadError = ConvertFrom-ContractCodePoints @(0x52A0, 0x8F7D, 0x9519, 0x8BEF)
    $previousVersion = ConvertFrom-ContractCodePoints @(0x4E0A, 0x4E00, 0x7248)
    $doNotOverwrite = ConvertFrom-ContractCodePoints @(0x4E0D, 0x5F97, 0x8986, 0x76D6)
    $localCache = ConvertFrom-ContractCodePoints @(0x672C, 0x5730, 0x7F13, 0x5B58)
    $cannot = ConvertFrom-ContractCodePoints @(0x4E0D, 0x80FD)
    $mustNot = ConvertFrom-ContractCodePoints @(0x4E0D, 0x5F97)
    $doNot = ConvertFrom-ContractCodePoints @(0x4E0D, 0x8981)
    $noLonger = ConvertFrom-ContractCodePoints @(0x4E0D, 0x518D)
    $cover = ConvertFrom-ContractCodePoints @(0x8986, 0x76D6)
    $violations = New-Object System.Collections.Generic.List[string]

    if ($Prd -notmatch ('plugin/list.*' + $uniqueAuthority)) {
        [void]$violations.Add('PRD must identify plugin/list as the unique complete-catalog authority.')
    }
    if ($Prd -notmatch ('plugin/list.*' + $returned + '.*' + $all + '.*' + $record)) {
        [void]$violations.Add('PRD must preserve every plugin/list record.')
    }
    if ($Prd -notmatch ($completeCatalog + '.*' + $upstream + '.*' + $rawDuplicates)) {
        [void]$violations.Add('PRD must preserve upstream raw duplicates in the complete catalog.')
    }
    if ($Prd -notmatch ($relevance + '.*' + $focusIndex + '.*' + $completeCatalog)) {
        [void]$violations.Add('PRD must limit relevance to the focus index, not the complete catalog.')
    }
    if ($Prd -notmatch ($account + '.*' + $workspace + '.*' + $visible)) {
        [void]$violations.Add('PRD must describe account and workspace visibility boundaries.')
    }
    if ($Prd -notmatch ('plugin/list.*' + $failure + '.*' + $previousVersion + '.*' + $mustNot + '.*' + $cover) -or
        $Prd -notmatch ($loadError + '.*' + $previousVersion + '.*' + $mustNot + '.*' + $cover)) {
        [void]$violations.Add('PRD must preserve the previous version after collection or load failure.')
    }
    if ($Plan -notmatch '--output\s+\.\\\.tmp\\plugins_market\.candidate\.md') {
        [void]$violations.Add('PP must include the candidate output command.')
    }
    if ($Plan -notmatch '--output\s+\.\\Resources\\plugins_market\.md') {
        [void]$violations.Add('PP must include the formal output command.')
    }
    if ($Plan -notmatch '--check\s+\.\\Resources\\plugins_market\.md') {
        [void]$violations.Add('PP must include the --check command.')
    }
    if ($Guide -notmatch '--output\s+\.\\Resources\\plugins_market\.md' -or
        $Guide -notmatch '--check\s+\.\\Resources\\plugins_market\.md' -or
        $Guide -notmatch ('GitHub.*CLI snapshot.*' + $localCache)) {
        [void]$violations.Add('GUIDE must provide executable commands and prohibit manual fallback sources.')
    }

    $sourcePatterns = [ordered]@{
        'openai/plugins.git' = 'openai/plugins\.git'
        'codex plugin list' = 'codex plugin list'
        'CLI marketplace snapshot' = 'CLI\s+(?:marketplace\s+)?snapshot'
        'local cache' = $localCache
    }
    $documents = @(
        [pscustomobject]@{ Name = 'PRD'; Text = $Prd }
        [pscustomobject]@{ Name = 'PP'; Text = $Plan }
        [pscustomobject]@{ Name = 'GUIDE'; Text = $Guide }
    )
    $prohibitionMarkers = @($doNotOverwrite, $mustNot, $cannot, $doNot, $noLonger)
    foreach ($document in $documents) {
        foreach ($sourceName in $sourcePatterns.Keys) {
            $sourcePattern = $sourcePatterns[$sourceName]
            $sourceLines = @($document.Text -split "`r?`n" | Where-Object { $_ -match $sourcePattern })
            foreach ($sourceLine in $sourceLines) {
                $assertsCompleteCatalog = $sourceLine -match ($completeCatalog + '|' + $completeDirectory + '|complete(?:-catalog| catalog| directory)')
                if (-not $assertsCompleteCatalog) {
                    continue
                }
                $hasProhibition = $false
                foreach ($prohibitionMarker in $prohibitionMarkers) {
                    if ($sourceLine.IndexOf($prohibitionMarker, [System.StringComparison]::Ordinal) -ge 0) {
                        $hasProhibition = $true
                        break
                    }
                }
                if (-not $hasProhibition) {
                    [void]$violations.Add("$($document.Name) describes $sourceName without prohibiting it as a complete-catalog replacement.")
                }
            }
        }
    }

    if ($violations.Count -gt 0) {
        throw ('Plugin market source contract violations: ' + ($violations -join ' '))
    }
}

if ($ContractProbe) {
    $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $documents = Get-PluginMarketContractDocuments -RepositoryRoot $repositoryRoot
    Assert-PluginMarketSourceContract `
        -Prd ($documents.Prd + "`n" + 'codex plugin list can be used as a complete catalog replacement.') `
        -Plan $documents.Plan `
        -Guide $documents.Guide
    exit 0
}

Describe 'Market scripts' {
    It 'runs the plugin catalog Node tests' {
        $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $testPath = Join-Path $repositoryRoot 'tests\node\plugin-catalog.test.mjs'
        $output = & node --test $testPath 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            $tail = @($output | Select-Object -Last 20) -join [Environment]::NewLine
            throw "plugin catalog Node tests failed with exit code $exitCode`n$tail"
        }

        $exitCode | Should Be 0
    }

    It 'runs the GitHub market Node tests' {
        $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $testPath = Join-Path $repositoryRoot 'tests\node\github-market.test.mjs'
        $output = & node --test $testPath 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            $tail = @($output | Select-Object -Last 20) -join [Environment]::NewLine
            throw "GitHub market Node tests failed with exit code $exitCode`n$tail"
        }

        $exitCode | Should Be 0
    }

    It 'keeps the complete Plugins market source contract current' {
        $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $documents = Get-PluginMarketContractDocuments -RepositoryRoot $repositoryRoot
        $supersededPrefix = [string]::Concat([char[]](0x5DF2, 0x88AB))
        $supersededSuffix = [string]::Concat([char[]](0x8BBE, 0x8BA1, 0x53D6, 0x4EE3))
        $historicalDesignHeader = (($documents.HistoricalDesign -split "`r?`n") | Select-Object -First 6) -join "`n"
        $historicalPlanHeader = (($documents.HistoricalPlan -split "`r?`n") | Select-Object -First 6) -join "`n"

        { Assert-PluginMarketSourceContract -Prd $documents.Prd -Plan $documents.Plan -Guide $documents.Guide } | Should Not Throw
        ($historicalDesignHeader -match ($supersededPrefix + ' 2026-07-13 ' + $supersededSuffix)) | Should Be $true
        ($historicalPlanHeader -match ($supersededPrefix + ' 2026-07-13 ' + $supersededSuffix)) | Should Be $true
    }

    It 'rejects a complete-catalog replacement source in memory' {
        $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $documents = Get-PluginMarketContractDocuments -RepositoryRoot $repositoryRoot
        $errorText = $null

        try {
            Assert-PluginMarketSourceContract `
                -Prd ($documents.Prd + "`n" + 'codex plugin list can be used as a complete catalog replacement.') `
                -Plan $documents.Plan `
                -Guide $documents.Guide
        }
        catch {
            $errorText = $_.Exception.Message
        }

        ($null -ne $errorText) | Should Be $true
        $errorText | Should Match 'codex plugin list'
    }
}
