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
        $script:childScript = Join-Path $TestDrive 'managed-child.ps1'
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
        [Console]::Error.WriteLine("错误:$Value")
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
    }

    It 'captures successful UTF-8 stdout and stderr' {
        $result = Invoke-ManagedProcess -FilePath $powerShellPath -Arguments @(
            '-NoProfile', '-File', $childScript, 'echo', '中文 参数'
        ) -TimeoutSeconds 10

        $result.ExitCode | Should Be 0
        $result.TimedOut | Should Be $false
        $result.Succeeded | Should Be $true
        $result.StdOut.Trim() | Should Be '中文 参数'
        $result.StdErr.Trim() | Should Be '错误:中文 参数'
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

    It 'throws when the executable cannot be started' {
        $message = Get-ThrownMessage {
            Invoke-ManagedProcess -FilePath (Join-Path $TestDrive 'missing.exe') -Arguments @() -TimeoutSeconds 1
        }

        $message | Should Match 'start'
    }
}
