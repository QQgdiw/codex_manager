Describe 'Repository baseline' {
    It 'runs under Windows PowerShell 5.1 or later' {
        $PSVersionTable.PSVersion.Major | Should BeGreaterThan 4
    }

    It 'executes a stable offline assertion' {
        (2 + 2) | Should Be 4
    }

    It 'provides the repository test entry point' {
        $runnerPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'Run-Tests.ps1'

        Test-Path -LiteralPath $runnerPath -PathType Leaf | Should Be $true
    }

    It 'supports Unit, Integration, and All selectors' {
        $runnerPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'Run-Tests.ps1'
        $command = Get-Command -Name $runnerPath -ErrorAction Stop

        ($command.Parameters.Keys -contains 'Unit') | Should Be $true
        ($command.Parameters.Keys -contains 'Integration') | Should Be $true
        ($command.Parameters.Keys -contains 'All') | Should Be $true
    }
}
