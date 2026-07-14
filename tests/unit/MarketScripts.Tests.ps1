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
}
