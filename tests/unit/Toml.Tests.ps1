$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tomlLibrary = Join-Path $projectRoot 'scripts\lib\Read-Toml.ps1'
$fixtures = Join-Path $projectRoot 'tests\fixtures'

Describe 'Read-ProjectToml' {
    BeforeAll {
        . $tomlLibrary
    }

    It 'reads valid TOML as an object' {
        $document = Read-ProjectToml -Path (Join-Path $fixtures 'config.valid.toml')

        $document.name | Should Be 'basic'
        $document.tool_ids[0] | Should Be 'skill.example'
    }

    It 'rejects invalid TOML syntax' {
        $invalidPath = Join-Path $TestDrive 'invalid.toml'
        Set-Content -LiteralPath $invalidPath -Value 'broken = [' -Encoding UTF8

        { Read-ProjectToml -Path $invalidPath } | Should Throw
    }

    It 'rejects a missing file' {
        { Read-ProjectToml -Path (Join-Path $TestDrive 'missing.toml') } | Should Throw
    }

    It 'rejects a non-object TOML root from the converter' {
        $fakePython = Join-Path $TestDrive 'fake-python-non-object.cmd'
        Set-Content -LiteralPath $fakePython -Value '@echo [1,2,3]' -Encoding ASCII

        { Read-ProjectToml -Path (Join-Path $fixtures 'config.valid.toml') -PythonCommand $fakePython -SkipPythonVersionCheck } | Should Throw
    }

    It 'rejects Python versions older than 3.11' {
        $fakePython = Join-Path $TestDrive 'fake-python-old.cmd'
        Set-Content -LiteralPath $fakePython -Value '@echo 3.10.9' -Encoding ASCII

        { Read-ProjectToml -Path (Join-Path $fixtures 'config.valid.toml') -PythonCommand $fakePython } | Should Throw
    }

    It 'rejects an unavailable Python command' {
        $missingPython = Join-Path $TestDrive 'missing-python.exe'

        { Read-ProjectToml -Path (Join-Path $fixtures 'config.valid.toml') -PythonCommand $missingPython } | Should Throw
    }

    It 'reports converter subprocess failures' {
        $fakePython = Join-Path $TestDrive 'fake-python-failure.cmd'
        Set-Content -LiteralPath $fakePython -Value '@exit /b 3' -Encoding ASCII

        { Read-ProjectToml -Path (Join-Path $fixtures 'config.valid.toml') -PythonCommand $fakePython -SkipPythonVersionCheck } | Should Throw
    }
}

Describe 'toml_to_json.py' {
    It 'writes JSON and exits zero for valid TOML' {
        $converter = Join-Path $projectRoot 'scripts\python\toml_to_json.py'
        $output = @(& python $converter (Join-Path $fixtures 'config.valid.toml') 2>&1)
        $exitCode = $LASTEXITCODE

        $exitCode | Should Be 0
        (($output -join "`n") | ConvertFrom-Json).name | Should Be 'basic'
    }

    It 'exits two for invalid TOML syntax' {
        $converter = Join-Path $projectRoot 'scripts\python\toml_to_json.py'
        $invalidPath = Join-Path $TestDrive 'invalid-cli.toml'
        Set-Content -LiteralPath $invalidPath -Value 'broken = [' -Encoding UTF8

        $null = @(& python $converter $invalidPath 2>&1)

        $LASTEXITCODE | Should Be 2
    }
}
