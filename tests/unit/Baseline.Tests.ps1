function New-RunnerFixture {
    param(
        [string]$UnitTest,
        [string]$IntegrationTest
    )

    $fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString('N'))
    $unitRoot = Join-Path $fixtureRoot 'unit'
    $integrationRoot = Join-Path $fixtureRoot 'integration'
    New-Item -ItemType Directory -Path $unitRoot, $integrationRoot -Force | Out-Null

    $sourceRunner = Join-Path (Split-Path $PSScriptRoot -Parent) 'Run-Tests.ps1'
    Copy-Item -LiteralPath $sourceRunner -Destination (Join-Path $fixtureRoot 'Run-Tests.ps1')

    if ($UnitTest) {
        Set-Content -LiteralPath (Join-Path $unitRoot 'Fixture.Tests.ps1') -Value $UnitTest -Encoding UTF8
    }
    if ($IntegrationTest) {
        Set-Content -LiteralPath (Join-Path $integrationRoot 'Fixture.Tests.ps1') -Value $IntegrationTest -Encoding UTF8
    }

    return $fixtureRoot
}

function Invoke-RunnerFixture {
    param(
        [string]$FixtureRoot,
        [string[]]$Arguments = @()
    )

    $runnerPath = Join-Path $FixtureRoot 'Run-Tests.ps1'
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $runnerPath @Arguments 2>&1

    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = @($output)
    }
}

$passingUnitTest = @'
Describe 'Unit fixture' {
    It 'runs' {
        Add-Content -LiteralPath $env:RUNNER_MARKER -Value 'unit'
        $true | Should Be $true
    }
}
'@

$passingIntegrationTest = @'
Describe 'Integration fixture' {
    It 'runs' {
        Add-Content -LiteralPath $env:RUNNER_MARKER -Value 'integration'
        $true | Should Be $true
    }
}
'@

$failingUnitTest = @'
Describe 'Failing unit fixture' {
    It 'fails' {
        $true | Should Be $false
    }
}
'@

Describe 'Repository baseline' {
    It 'runs under Windows PowerShell 5.1 or later' {
        $PSVersionTable.PSVersion.Major | Should BeGreaterThan 4
    }

    It 'runs unit and integration tests by default' {
        $fixtureRoot = New-RunnerFixture -UnitTest $passingUnitTest -IntegrationTest $passingIntegrationTest
        $markerPath = Join-Path $fixtureRoot 'marker.txt'
        $previousMarker = $env:RUNNER_MARKER
        try {
            $env:RUNNER_MARKER = $markerPath
            $result = Invoke-RunnerFixture -FixtureRoot $fixtureRoot
            $markers = @(Get-Content -LiteralPath $markerPath)

            $result.ExitCode | Should Be 0
            ($markers -contains 'unit') | Should Be $true
            ($markers -contains 'integration') | Should Be $true
        }
        finally {
            $env:RUNNER_MARKER = $previousMarker
            Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
        }
    }

    It 'runs only unit tests with Unit' {
        $fixtureRoot = New-RunnerFixture -UnitTest $passingUnitTest -IntegrationTest $passingIntegrationTest
        $markerPath = Join-Path $fixtureRoot 'marker.txt'
        $previousMarker = $env:RUNNER_MARKER
        try {
            $env:RUNNER_MARKER = $markerPath
            $result = Invoke-RunnerFixture -FixtureRoot $fixtureRoot -Arguments '-Unit'
            $markers = @(Get-Content -LiteralPath $markerPath)

            $result.ExitCode | Should Be 0
            ($markers -contains 'unit') | Should Be $true
            ($markers -contains 'integration') | Should Be $false
        }
        finally {
            $env:RUNNER_MARKER = $previousMarker
            Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
        }
    }

    It 'runs only integration tests with Integration' {
        $fixtureRoot = New-RunnerFixture -UnitTest $passingUnitTest -IntegrationTest $passingIntegrationTest
        $markerPath = Join-Path $fixtureRoot 'marker.txt'
        $previousMarker = $env:RUNNER_MARKER
        try {
            $env:RUNNER_MARKER = $markerPath
            $result = Invoke-RunnerFixture -FixtureRoot $fixtureRoot -Arguments '-Integration'
            $markers = @(Get-Content -LiteralPath $markerPath)

            $result.ExitCode | Should Be 0
            ($markers -contains 'unit') | Should Be $false
            ($markers -contains 'integration') | Should Be $true
        }
        finally {
            $env:RUNNER_MARKER = $previousMarker
            Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
        }
    }

    It 'returns 2 when the selected scope has no tests' {
        $fixtureRoot = New-RunnerFixture
        try {
            $result = Invoke-RunnerFixture -FixtureRoot $fixtureRoot -Arguments '-Integration'

            $result.ExitCode | Should Be 2
        }
        finally {
            Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
        }
    }

    It 'returns 1 when a selected test fails' {
        $fixtureRoot = New-RunnerFixture -UnitTest $failingUnitTest
        try {
            $result = Invoke-RunnerFixture -FixtureRoot $fixtureRoot -Arguments '-Unit'

            $result.ExitCode | Should Be 1
        }
        finally {
            Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
        }
    }
}
