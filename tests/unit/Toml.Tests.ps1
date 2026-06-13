$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tomlLibrary = Join-Path $projectRoot 'scripts\lib\Read-Toml.ps1'
$fixtures = Join-Path $projectRoot 'tests\fixtures'

function Get-ThrownMessage {
    param([scriptblock]$Action)

    try {
        & $Action
        return $null
    }
    catch {
        return $_.Exception.Message
    }
}

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

        $message = Get-ThrownMessage { Read-ProjectToml -Path $invalidPath }

        $message | Should Match 'converter failed'
        $message | Should Match 'exit code 2'
    }

    It 'rejects a missing file' {
        $message = Get-ThrownMessage {
            Read-ProjectToml -Path (Join-Path $TestDrive 'missing.toml')
        }

        $message | Should Match 'does not exist'
    }

    It 'rejects a non-object TOML root from the converter' {
        $fakePython = Join-Path $TestDrive 'fake-python-non-object.cmd'
        Set-Content -LiteralPath $fakePython -Value '@echo [1,2,3]' -Encoding ASCII

        $message = Get-ThrownMessage {
            Read-ProjectToml -Path (Join-Path $fixtures 'config.valid.toml') -PythonCommand $fakePython -SkipPythonVersionCheck
        }

        $message | Should Match 'not an object'
    }

    It 'rejects Python versions older than 3.11' {
        $fakePython = Join-Path $TestDrive 'fake-python-old.cmd'
        Set-Content -LiteralPath $fakePython -Value '@echo 3.10.9' -Encoding ASCII

        $message = Get-ThrownMessage {
            Read-ProjectToml -Path (Join-Path $fixtures 'config.valid.toml') -PythonCommand $fakePython
        }

        $message | Should Match '3.11'
    }

    It 'rejects an unavailable Python command' {
        $missingPython = Join-Path $TestDrive 'missing-python.exe'

        $message = Get-ThrownMessage {
            Read-ProjectToml -Path (Join-Path $fixtures 'config.valid.toml') -PythonCommand $missingPython
        }

        $message | Should Match 'unavailable'
    }

    It 'reports converter subprocess failures' {
        $fakePython = Join-Path $TestDrive 'fake-python-failure.cmd'
        Set-Content -LiteralPath $fakePython -Value '@exit /b 3' -Encoding ASCII

        $message = Get-ThrownMessage {
            Read-ProjectToml -Path (Join-Path $fixtures 'config.valid.toml') -PythonCommand $fakePython -SkipPythonVersionCheck
        }

        $message | Should Match 'exit code 3'
    }

    It 'preserves UTF-8 TOML text when the console uses CP437' {
        $unicodePath = Join-Path $TestDrive 'bridge-unicode.toml'
        $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
        $expected = ([char]0x4E2D).ToString() + [char]0x6587 + [char]0x5DE5 + [char]0x5177
        [System.IO.File]::WriteAllText(
            $unicodePath,
            ('name = "{0}"' -f $expected),
            $utf8WithoutBom
        )
        $originalEncoding = [Console]::OutputEncoding

        try {
            [Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(437)
            $document = Read-ProjectToml -Path $unicodePath
        }
        finally {
            [Console]::OutputEncoding = $originalEncoding
        }

        $document.name | Should Be $expected
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

    It 'forces UTF-8 output for non-ASCII TOML despite the inherited Python encoding' {
        $converter = Join-Path $projectRoot 'scripts\python\toml_to_json.py'
        $unicodePath = Join-Path $TestDrive 'unicode.toml'
        $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($unicodePath, 'name = "中文工具"', $utf8WithoutBom)

        $python = (Get-Command python -ErrorAction Stop).Source
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $python
        $startInfo.Arguments = ('"{0}" "{1}"' -f $converter, $unicodePath)
        $startInfo.UseShellExecute = $false
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.StandardOutputEncoding = $utf8WithoutBom
        $startInfo.StandardErrorEncoding = $utf8WithoutBom
        if ($null -ne $startInfo.Environment) {
            $startInfo.Environment['PYTHONIOENCODING'] = 'cp1252'
        }
        else {
            $startInfo.EnvironmentVariables['PYTHONIOENCODING'] = 'cp1252'
        }

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        $null = $process.Start()
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()

        $process.ExitCode | Should Be 0
        $stderr | Should Be ''
        ($stdout | ConvertFrom-Json).name | Should Be '中文工具'
    }

    It 'exits two for invalid TOML syntax' {
        $converter = Join-Path $projectRoot 'scripts\python\toml_to_json.py'
        $invalidPath = Join-Path $TestDrive 'invalid-cli.toml'
        Set-Content -LiteralPath $invalidPath -Value 'broken = [' -Encoding UTF8

        $null = @(& python $converter $invalidPath 2>&1)

        $LASTEXITCODE | Should Be 2
    }

    It 'exits two for invalid UTF-8 input' {
        $converter = Join-Path $projectRoot 'scripts\python\toml_to_json.py'
        $invalidPath = Join-Path $TestDrive 'invalid-utf8.toml'
        [System.IO.File]::WriteAllBytes($invalidPath, [byte[]](0xFF, 0xFE, 0xFD))

        $output = @(& python $converter $invalidPath 2>&1)

        $LASTEXITCODE | Should Be 2
        ($output -join "`n") | Should Match 'input error'
    }
}
