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

    It 'keeps the Plugins market source contract current' {
        $repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $prd = Get-Content -LiteralPath (Join-Path $repositoryRoot 'Resources\PRD.md') -Raw -Encoding UTF8
        $plan = Get-Content -LiteralPath (Join-Path $repositoryRoot 'Resources\PP.md') -Raw -Encoding UTF8
        $historicalDesign = Get-Content -LiteralPath (Join-Path $repositoryRoot 'docs\superpowers\specs\2026-06-25-market-approval-hardening-design.md') -Raw -Encoding UTF8
        $historicalPlan = Get-Content -LiteralPath (Join-Path $repositoryRoot 'docs\superpowers\plans\2026-06-25-market-approval-hardening.md') -Raw -Encoding UTF8

        $uniqueAuthority = [string]::Concat([char[]](0x552F, 0x4E00, 0x6536, 0x5F55, 0x6743, 0x5A01))
        $completeCatalog = [string]::Concat([char[]](0x5B8C, 0x6574, 0x6E05, 0x5355))
        $focusIndex = [string]::Concat([char[]](0x91CD, 0x70B9, 0x7D22, 0x5F15))
        $supersededPrefix = [string]::Concat([char[]](0x5DF2, 0x88AB))
        $supersededSuffix = [string]::Concat([char[]](0x8BBE, 0x8BA1, 0x53D6, 0x4EE3))
        $historicalDesignHeader = (($historicalDesign -split "`r?`n") | Select-Object -First 6) -join "`n"
        $historicalPlanHeader = (($historicalPlan -split "`r?`n") | Select-Object -First 6) -join "`n"

        ($prd -match ('plugin/list.*' + $uniqueAuthority)) | Should Be $true
        ($prd -match $completeCatalog) | Should Be $true
        ($prd -match $focusIndex) | Should Be $true
        ($plan -match 'git clone.*openai/plugins\.git') | Should Be $false
        ($plan -match 'export-plugins-market\.mjs') | Should Be $true
        ($historicalDesignHeader -match ($supersededPrefix + ' 2026-07-13 ' + $supersededSuffix)) | Should Be $true
        ($historicalPlanHeader -match ($supersededPrefix + ' 2026-07-13 ' + $supersededSuffix)) | Should Be $true
    }
}
