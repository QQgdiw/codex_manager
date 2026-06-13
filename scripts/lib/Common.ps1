$script:ManagedProcessOutputLineLimit = 50
$script:ManagedProcessOutputEdgeLineCount = 25

function New-OperationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Data
    )

    if ([string]::IsNullOrWhiteSpace($Status)) {
        throw 'Status must not be empty.'
    }

    return [pscustomobject]@{
        Status = $Status
        Message = $Message
        Data = $Data
        Timestamp = [DateTime]::UtcNow
    }
}

function Protect-LogText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [AllowNull()]
        [string[]]$SensitiveValues = @()
    )

    $protectedText = $Text
    $values = @(
        $SensitiveValues |
            Where-Object { -not [string]::IsNullOrEmpty($_) } |
            Sort-Object -Property Length -Descending
    )

    foreach ($value in $values) {
        $protectedText = $protectedText.Replace($value, '[REDACTED]')
    }

    return $protectedText
}

function ConvertTo-ManagedProcessArgument {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    return '"' + ($Value -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

function Limit-ManagedProcessOutput {
    param(
        [AllowEmptyString()]
        [string]$Text
    )

    if ([string]::IsNullOrEmpty($Text)) {
        return ''
    }

    $lines = @([regex]::Split($Text, "\r\n|\n|\r"))
    if ($lines.Count -gt 0 -and $lines[-1] -eq '') {
        $lines = @($lines[0..($lines.Count - 2)])
    }

    if ($lines.Count -le $script:ManagedProcessOutputLineLimit) {
        return ($lines -join [Environment]::NewLine)
    }

    $omittedCount = $lines.Count - $script:ManagedProcessOutputLineLimit
    $lastStart = $lines.Count - $script:ManagedProcessOutputEdgeLineCount
    $limitedLines = @(
        $lines[0..($script:ManagedProcessOutputEdgeLineCount - 1)]
        "[TRUNCATED: $omittedCount lines omitted]"
        $lines[$lastStart..($lines.Count - 1)]
    )

    return ($limitedLines -join [Environment]::NewLine)
}

function Invoke-ManagedProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [AllowNull()]
        [string[]]$Arguments = @(),

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 2147483)]
        [int]$TimeoutSeconds
    )

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $FilePath
    $startInfo.Arguments = (@($Arguments) | ForEach-Object {
        ConvertTo-ManagedProcessArgument -Value "$_"
    }) -join ' '
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
    $startInfo.StandardOutputEncoding = $strictUtf8
    $startInfo.StandardErrorEncoding = $strictUtf8

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $started = $false

    try {
        try {
            $started = $process.Start()
        }
        catch {
            throw 'Managed process failed to start.'
        }

        if (-not $started) {
            throw 'Managed process failed to start.'
        }

        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)

        if ($timedOut) {
            try {
                $process.Kill()
            }
            catch {
                throw 'Timed out process could not be terminated.'
            }
        }

        $process.WaitForExit()
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        $exitCode = if ($timedOut) { $null } else { $process.ExitCode }

        return [pscustomobject]@{
            ExitCode = $exitCode
            TimedOut = $timedOut
            StdOut = Limit-ManagedProcessOutput -Text $stdout
            StdErr = Limit-ManagedProcessOutput -Text $stderr
            DurationMs = [long]$stopwatch.Elapsed.TotalMilliseconds
            Succeeded = (-not $timedOut -and $exitCode -eq 0)
        }
    }
    finally {
        $stopwatch.Stop()
        $process.Dispose()
    }
}
