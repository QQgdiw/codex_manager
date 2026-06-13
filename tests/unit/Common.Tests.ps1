$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$commonLibrary = Join-Path $projectRoot 'scripts\lib\Common.ps1'

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

function ConvertTo-CodePointText {
    param([string]$Value)

    return (($Value.ToCharArray() | ForEach-Object { '{0:X4}' -f [int]$_ }) -join ' ')
}

Describe 'New-OperationResult' {
    BeforeAll {
        . $commonLibrary
    }

    It 'returns the stable operation result shape' {
        $before = [DateTime]::UtcNow
        $data = [pscustomobject]@{ Value = 42 }

        $result = New-OperationResult -Status 'Succeeded' -Message 'done' -Data $data

        @($result.PSObject.Properties.Name) | Should Be @('Status', 'Message', 'Data', 'Timestamp')
        $result.Status | Should Be 'Succeeded'
        $result.Message | Should Be 'done'
        $result.Data | Should Be $data
        $result.Timestamp.Kind | Should Be ([DateTimeKind]::Utc)
        ($result.Timestamp -ge $before) | Should Be $true
    }

    It 'rejects an empty status' {
        $message = Get-ThrownMessage {
            New-OperationResult -Status ' ' -Message 'invalid' -Data $null
        }

        $message | Should Match 'Status'
    }
}

Describe 'Protect-LogText' {
    BeforeAll {
        . $commonLibrary
    }

    It 'replaces literal sensitive values including regex characters' {
        $result = Protect-LogText -Text 'token=a.b*c? and a.b*c?' -SensitiveValues @('a.b*c?')

        $result | Should Be 'token=[REDACTED] and [REDACTED]'
    }

    It 'redacts longer overlapping values first' {
        $result = Protect-LogText -Text 'secret-token secret' -SensitiveValues @('secret', 'secret-token')

        $result | Should Be '[REDACTED] [REDACTED]'
    }

    It 'redacts distinct sensitive values with the same length' {
        $result = Protect-LogText -Text 'alpha bravo' -SensitiveValues @('alpha', 'bravo')

        $result | Should Be '[REDACTED] [REDACTED]'
    }

    It 'ignores null and empty sensitive values' {
        (Protect-LogText -Text 'unchanged' -SensitiveValues $null) | Should Be 'unchanged'
        (Protect-LogText -Text 'unchanged' -SensitiveValues @('', $null)) | Should Be 'unchanged'
    }
}

Describe 'Invoke-ManagedProcess' {
    BeforeAll {
        . $commonLibrary

        $script:powerShellPath = Join-Path $PSHOME 'powershell.exe'
        $script:pythonPath = (Get-Command python -ErrorAction Stop).Source
        $script:childScript = Join-Path $TestDrive 'managed-child.ps1'
        $script:pythonChildScript = Join-Path $TestDrive 'managed-child.py'
        @'
param(
    [string]$Mode,
    [string]$Value,
    [string]$PidPath
)

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
[Console]::InputEncoding = New-Object System.Text.UTF8Encoding($false)

switch ($Mode) {
    'echo' {
        [Console]::Out.WriteLine($Value)
        $errorPrefix = ([char]0x9519) + ([char]0x8BEF) + ':'
        [Console]::Error.WriteLine($errorPrefix + $Value)
    }
    'exit' {
        [Console]::Error.WriteLine('expected failure')
        exit 7
    }
    'timeout' {
        [System.IO.File]::WriteAllText($PidPath, "$PID")
        Start-Sleep -Seconds 30
    }
    'lines' {
        1..60 | ForEach-Object { [Console]::Out.WriteLine("out-$_") }
        1..55 | ForEach-Object { [Console]::Error.WriteLine("err-$_") }
    }
}
'@ | Set-Content -LiteralPath $script:childScript -Encoding UTF8
        @'
import os
import subprocess
import sys
import time

mode = sys.argv[1]

if mode == "tree-parent":
    pid_path = sys.argv[2]
    inherit_streams = sys.argv[3] == "inherit"
    kwargs = {}
    if not inherit_streams:
        kwargs["stdout"] = subprocess.DEVNULL
        kwargs["stderr"] = subprocess.DEVNULL
    child = subprocess.Popen(
        [sys.executable, __file__, "tree-grandchild"],
        **kwargs
    )
    with open(pid_path, "w") as handle:
        handle.write(str(child.pid))
    sys.stdout.write("parent-ready\n")
    sys.stdout.flush()
    time.sleep(30)
elif mode == "tree-grandchild":
    time.sleep(6)
elif mode == "many-lines":
    for number in range(1, 20001):
        sys.stdout.write("out-%d\n" % number)
        sys.stderr.write("err-%d\n" % number)
elif mode == "long-line":
    sys.stdout.write(("a" * 50000) + ("z" * 50000))
elif mode == "invalid-utf8":
    sys.stdout.buffer.write(b"valid-\xff-end\n")
    sys.stderr.buffer.write(b"error-\xfe-end\n")
    sys.stdout.buffer.flush()
    sys.stderr.buffer.flush()
    sys.exit(7)
'@ | Set-Content -LiteralPath $script:pythonChildScript -Encoding ASCII
    }

    It 'captures successful UTF-8 stdout and stderr' {
        $value = ([char]0x4E2D) + ([char]0x6587) + ' ' + ([char]0x53C2) + ([char]0x6570)
        $errorPrefix = ([char]0x9519) + ([char]0x8BEF) + ':'
        $result = Invoke-ManagedProcess -FilePath $powerShellPath -Arguments @(
            '-NoProfile', '-File', $childScript, 'echo', $value
        ) -TimeoutSeconds 10

        $result.ExitCode | Should Be 0
        $result.TimedOut | Should Be $false
        $result.Succeeded | Should Be $true
        (ConvertTo-CodePointText $result.StdOut.Trim()) | Should Be (ConvertTo-CodePointText $value)
        (ConvertTo-CodePointText $result.StdErr.Trim()) | Should Be (ConvertTo-CodePointText ($errorPrefix + $value))
        ($result.DurationMs -ge 0) | Should Be $true
    }

    It 'preserves arguments containing spaces quotes and special characters' {
        $value = 'space "quoted" & symbols ^ %PATH%'

        $result = Invoke-ManagedProcess -FilePath $powerShellPath -Arguments @(
            '-NoProfile', '-File', $childScript, 'echo', $value
        ) -TimeoutSeconds 10

        $result.ExitCode | Should Be 0
        $result.StdOut.Trim() | Should Be $value
    }

    It 'returns a structured result for a non-zero exit' {
        $result = Invoke-ManagedProcess -FilePath $powerShellPath -Arguments @(
            '-NoProfile', '-File', $childScript, 'exit'
        ) -TimeoutSeconds 10

        $result.ExitCode | Should Be 7
        $result.TimedOut | Should Be $false
        $result.Succeeded | Should Be $false
        $result.StdErr.Trim() | Should Be 'expected failure'
    }

    It 'terminates and waits for a timed out process' {
        $pidPath = Join-Path $TestDrive 'timed-out.pid'

        $result = Invoke-ManagedProcess -FilePath $powerShellPath -Arguments @(
            '-NoProfile', '-File', $childScript, 'timeout', '', $pidPath
        ) -TimeoutSeconds 1

        $childPid = [int](Get-Content -LiteralPath $pidPath -Raw)
        $result.TimedOut | Should Be $true
        $result.Succeeded | Should Be $false
        $result.ExitCode | Should Be $null
        (Get-Process -Id $childPid -ErrorAction SilentlyContinue) | Should Be $null
    }

    It 'terminates a timed out process tree whose grandchild inherits output pipes' {
        $pidPath = Join-Path $TestDrive 'inherited-grandchild.pid'
        $grandchildPid = $null

        try {
            $result = Invoke-ManagedProcess -FilePath $pythonPath -Arguments @(
                $pythonChildScript, 'tree-parent', $pidPath, 'inherit'
            ) -TimeoutSeconds 1
            $grandchildPid = [int](Get-Content -LiteralPath $pidPath -Raw)

            $result.TimedOut | Should Be $true
            ($result.DurationMs -lt 4000) | Should Be $true
            (Get-Process -Id $grandchildPid -ErrorAction SilentlyContinue) | Should Be $null
        }
        finally {
            if ($null -ne $grandchildPid) {
                Stop-Process -Id $grandchildPid -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'terminates a timed out process tree whose grandchild does not inherit output pipes' {
        $pidPath = Join-Path $TestDrive 'detached-grandchild.pid'
        $grandchildPid = $null

        try {
            $result = Invoke-ManagedProcess -FilePath $pythonPath -Arguments @(
                $pythonChildScript, 'tree-parent', $pidPath, 'detached'
            ) -TimeoutSeconds 1
            $grandchildPid = [int](Get-Content -LiteralPath $pidPath -Raw)

            $result.TimedOut | Should Be $true
            ($result.DurationMs -lt 4000) | Should Be $true
            (Get-Process -Id $grandchildPid -ErrorAction SilentlyContinue) | Should Be $null
        }
        finally {
            if ($null -ne $grandchildPid) {
                Stop-Process -Id $grandchildPid -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'keeps the first and last 25 stdout lines with an omission count' {
        $result = Invoke-ManagedProcess -FilePath $powerShellPath -Arguments @(
            '-NoProfile', '-File', $childScript, 'lines'
        ) -TimeoutSeconds 10

        $lines = @($result.StdOut -split '\r?\n')
        $lines.Count | Should Be 51
        $lines[0] | Should Be 'out-1'
        $lines[24] | Should Be 'out-25'
        $lines[25] | Should Be '[TRUNCATED: 10 lines omitted]'
        $lines[26] | Should Be 'out-36'
        $lines[50] | Should Be 'out-60'
    }

    It 'truncates stderr independently using the same fixed policy' {
        $result = Invoke-ManagedProcess -FilePath $powerShellPath -Arguments @(
            '-NoProfile', '-File', $childScript, 'lines'
        ) -TimeoutSeconds 10

        $lines = @($result.StdErr -split '\r?\n')
        $lines.Count | Should Be 51
        $lines[25] | Should Be '[TRUNCATED: 5 lines omitted]'
        $lines[26] | Should Be 'err-31'
        $lines[50] | Should Be 'err-55'
    }

    It 'bounds very large stdout and stderr while preserving both edges' {
        $result = Invoke-ManagedProcess -FilePath $pythonPath -Arguments @(
            $pythonChildScript, 'many-lines'
        ) -TimeoutSeconds 20

        $stdoutLines = @($result.StdOut -split '\r?\n')
        $stderrLines = @($result.StdErr -split '\r?\n')
        $stdoutLines.Count | Should Be 51
        $stderrLines.Count | Should Be 51
        $stdoutLines[25] | Should Be '[TRUNCATED: 19950 lines omitted]'
        $stderrLines[25] | Should Be '[TRUNCATED: 19950 lines omitted]'
        $stdoutLines[0] | Should Be 'out-1'
        $stdoutLines[50] | Should Be 'out-20000'
        $result.StdOut | Should Not Match 'out-10000'
        $result.StdErr | Should Not Match 'err-10000'
    }

    It 'does not buffer complete process streams before truncating them' {
        $source = Get-Content -LiteralPath $commonLibrary -Raw

        $source | Should Not Match 'ReadToEnd'
    }

    It 'bounds a single oversized output line' {
        $result = Invoke-ManagedProcess -FilePath $pythonPath -Arguments @(
            $pythonChildScript, 'long-line'
        ) -TimeoutSeconds 10

        ($result.StdOut.Length -lt 5000) | Should Be $true
        $result.StdOut.StartsWith('a' * 2048) | Should Be $true
        $result.StdOut | Should Match '\[TRUNCATED: 95904 chars omitted\]'
        $result.StdOut.EndsWith('z' * 2048) | Should Be $true
    }

    It 'returns invalid UTF-8 as replacement text for a non-zero exit' {
        $result = Invoke-ManagedProcess -FilePath $pythonPath -Arguments @(
            $pythonChildScript, 'invalid-utf8'
        ) -TimeoutSeconds 10

        $replacement = [char]0xFFFD
        $result.ExitCode | Should Be 7
        $result.Succeeded | Should Be $false
        $result.StdOut | Should Match ([regex]::Escape($replacement))
        $result.StdErr | Should Match ([regex]::Escape($replacement))
    }

    It 'throws when the executable cannot be started' {
        $message = Get-ThrownMessage {
            Invoke-ManagedProcess -FilePath (Join-Path $TestDrive 'missing.exe') -Arguments @() -TimeoutSeconds 1
        }

        $message | Should Match 'start'
    }
}
