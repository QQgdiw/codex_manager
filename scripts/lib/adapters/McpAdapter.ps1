$commonLibrary = Join-Path (Split-Path -Parent $PSScriptRoot) 'Common.ps1'
if (Test-Path -LiteralPath $commonLibrary -PathType Leaf) {
    . $commonLibrary
}

$verificationLibrary = Join-Path (Split-Path -Parent $PSScriptRoot) 'VerificationEngine.ps1'
if (Test-Path -LiteralPath $verificationLibrary -PathType Leaf) {
    . $verificationLibrary
}

function Get-McpAdapterMember {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($name in $Names) {
            if ($InputObject.Contains($name)) {
                return $InputObject[$name]
            }
        }
        foreach ($key in @($InputObject.Keys)) {
            foreach ($name in $Names) {
                if ([string]::Equals("$key", $name, [StringComparison]::OrdinalIgnoreCase)) {
                    return $InputObject[$key]
                }
            }
        }
        return $null
    }

    foreach ($name in $Names) {
        $property = $InputObject.PSObject.Properties[$name]
        if ($null -ne $property) {
            return $property.Value
        }
    }
    foreach ($property in @($InputObject.PSObject.Properties)) {
        foreach ($name in $Names) {
            if ([string]::Equals($property.Name, $name, [StringComparison]::OrdinalIgnoreCase)) {
                return $property.Value
            }
        }
    }

    return $null
}

function Get-McpAdapterString {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    $value = Get-McpAdapterMember -InputObject $InputObject -Names $Names
    if ($null -eq $value) {
        return $null
    }
    $text = "$value"
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }
    return $text
}

function Get-McpAdapterArray {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return @()
    }
    if ($Value -is [string]) {
        return @($Value)
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        return @($Value)
    }
    return @($Value)
}

function Test-McpAdapterSafeName {
    param([AllowNull()][string]$Value)

    return (
        -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value -match '^[A-Za-z0-9][A-Za-z0-9._-]*$'
    )
}

function Test-McpAdapterSafeEnvName {
    param([AllowNull()][string]$Value)

    return (
        -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value -match '^[A-Za-z_][A-Za-z0-9_]*$'
    )
}

function Test-McpAdapterSensitiveEnvName {
    param([AllowNull()][string]$Value)

    return ($Value -match '(?i)(token|secret|password|api[_-]?key|credential)')
}

function Get-McpAdapterSnapshot {
    param([AllowNull()][object]$Tool)

    return Get-McpAdapterMember -InputObject $Tool `
        -Names @('ApprovedSnapshot', 'approved_snapshot')
}

function New-McpAdapterCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    return [pscustomobject][ordered]@{
        FilePath = $FilePath
        Arguments = [string[]]@($Arguments)
    }
}

function New-McpApprovedSnapshotSummary {
    param([AllowNull()][object]$Snapshot)

    if ($null -eq $Snapshot) {
        return $null
    }

    return [pscustomobject][ordered]@{
        id = Get-McpAdapterString -InputObject $Snapshot -Names @('id', 'Id')
        name = Get-McpAdapterString -InputObject $Snapshot -Names @('name', 'Name')
        type = Get-McpAdapterString -InputObject $Snapshot -Names @('type', 'Type')
        source = Get-McpAdapterString -InputObject $Snapshot -Names @('source', 'Source')
        version = Get-McpAdapterString -InputObject $Snapshot -Names @('version', 'Version')
        sha256 = Get-McpAdapterString -InputObject $Snapshot -Names @('sha256', 'Hash')
        smoke = Get-McpAdapterMember -InputObject $Snapshot -Names @('smoke', 'Smoke')
    }
}

function Protect-McpAdapterText {
    param(
        [AllowNull()]
        [object]$Text,

        [AllowNull()]
        [string[]]$SensitiveValues = @()
    )

    $value = if ($null -eq $Text) { '' } else { "$Text" }
    if (Get-Command Protect-LogText -ErrorAction SilentlyContinue) {
        $value = Protect-LogText -Text $value -SensitiveValues $SensitiveValues
    }

    $value = $value -replace '(?i)auth\.json', '[REDACTED]'
    $value = [regex]::Replace(
        $value,
        '(?i)((?:"?(?:token|access_token|refresh_token|auth_token|api_key|secret|password|credential)"?)\s*[:=]\s*)("[^"]*"|[^\s,;}\]]+)',
        '$1[REDACTED]'
    )
    $value = [regex]::Replace(
        $value,
        '(?i)(Bearer\s+)[A-Za-z0-9._~+/\-]+=*',
        '$1[REDACTED]'
    )
    $value = [regex]::Replace($value, '(?i)\bSECRET-[A-Za-z0-9._-]+\b', '[REDACTED]')
    return $value
}

function New-McpAdapterTextSummary {
    param(
        [AllowNull()]
        [object]$Text,

        [AllowNull()]
        [string[]]$SensitiveValues = @()
    )

    $raw = if ($null -eq $Text) { '' } else { "$Text" }
    $safe = Protect-McpAdapterText -Text $raw -SensitiveValues $SensitiveValues
    $maxLength = 240
    $preview = $safe
    $truncated = $false
    if ($preview.Length -gt $maxLength) {
        $preview = $preview.Substring(0, $maxLength)
        $truncated = $true
    }

    return [pscustomobject][ordered]@{
        Length = $raw.Length
        Preview = $preview
        Truncated = $truncated
    }
}

function New-McpProcessSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Step,

        [AllowNull()]
        [object]$Result,

        [AllowNull()]
        [string[]]$SensitiveValues = @()
    )

    $succeeded = Get-McpAdapterMember -InputObject $Result -Names @('Succeeded')
    $exitCode = Get-McpAdapterMember -InputObject $Result -Names @('ExitCode')
    $timedOut = Get-McpAdapterMember -InputObject $Result -Names @('TimedOut')
    $stderr = Get-McpAdapterMember -InputObject $Result -Names @('StdErr', 'stderr')
    $stdout = Get-McpAdapterMember -InputObject $Result -Names @('StdOut', 'stdout')
    $exceptionType = Get-McpAdapterMember -InputObject $Result -Names @('ExceptionType')

    return [pscustomobject][ordered]@{
        Step = $Step
        Succeeded = if ($null -eq $succeeded) { $false } else { [bool]$succeeded }
        ExitCode = $exitCode
        TimedOut = if ($null -eq $timedOut) { $false } else { [bool]$timedOut }
        StdOut = New-McpAdapterTextSummary -Text $stdout `
            -SensitiveValues $SensitiveValues
        StdErr = New-McpAdapterTextSummary -Text $stderr `
            -SensitiveValues $SensitiveValues
        ExceptionType = if ($null -eq $exceptionType) { $null } else { "$exceptionType" }
    }
}

function Test-McpProcessSucceeded {
    param([AllowNull()][object]$Result)

    if ($null -eq $Result) {
        return $false
    }
    $succeeded = Get-McpAdapterMember -InputObject $Result -Names @('Succeeded')
    if ($null -ne $succeeded) {
        return [bool]$succeeded
    }
    $exitCode = Get-McpAdapterMember -InputObject $Result -Names @('ExitCode')
    return ($null -ne $exitCode -and [int]$exitCode -eq 0)
}

function Get-McpProcessText {
    param(
        [AllowNull()]
        [object]$Result,

        [AllowNull()]
        [string[]]$SensitiveValues = @()
    )

    $stderr = Get-McpAdapterMember -InputObject $Result -Names @('StdErr', 'stderr')
    $stdout = Get-McpAdapterMember -InputObject $Result -Names @('StdOut', 'stdout')
    $timedOut = Get-McpAdapterMember -InputObject $Result -Names @('TimedOut')
    $text = if (-not [string]::IsNullOrWhiteSpace("$stderr")) {
        "$stderr"
    }
    else {
        "$stdout"
    }
    if ($timedOut) {
        $text = "startup timed out. $text"
    }
    return Protect-McpAdapterText -Text $text -SensitiveValues $SensitiveValues
}

function Invoke-McpAdapterExecutor {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Command,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Executor,

        [AllowNull()]
        [string[]]$SensitiveValues = @()
    )

    try {
        $result = @(& $Executor $Command)
    }
    catch {
        $message = Protect-McpAdapterText -Text $_.Exception.Message `
            -SensitiveValues $SensitiveValues
        return [pscustomobject][ordered]@{
            Succeeded = $false
            ExitCode = $null
            TimedOut = $false
            StdOut = ''
            StdErr = "MCP adapter executor failed: $message"
            ExceptionType = $_.Exception.GetType().FullName
        }
    }

    if ($result.Count -eq 0) {
        return $null
    }
    return $result[-1]
}

function Get-McpAdapterSafeRedactions {
    param([AllowNull()][object]$Snapshot)

    return @(
        Get-McpAdapterArray -Value (
            Get-McpAdapterMember -InputObject $Snapshot `
                -Names @('sensitive_redactions', 'SensitiveRedactions')
        ) |
            Where-Object {
                $text = [string]$_
                -not [string]::IsNullOrEmpty($text) -and
                $text -notmatch '(?i)(token|secret|password|api[_-]?key|credential)'
            } |
            ForEach-Object { [string]$_ }
    )
}

function Test-McpAdapterLocalPathCandidate {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }
    if ($Value.StartsWith('-')) {
        return $false
    }
    return (
        $Value -match '[\\/]' -or
        [IO.Path]::GetExtension($Value) -match '^\.(js|mjs|cjs|ps1|py|cmd|bat|exe)$'
    )
}

function Test-McpAdapterPathWithinRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $rootFullPath = [IO.Path]::GetFullPath($Root).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $pathFullPath = [IO.Path]::GetFullPath($Path)

    return (
        [string]::Equals($pathFullPath, $rootFullPath, [StringComparison]::OrdinalIgnoreCase) -or
        $pathFullPath.StartsWith(
            $rootFullPath + [IO.Path]::DirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        $pathFullPath.StartsWith(
            $rootFullPath + [IO.Path]::AltDirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase
        )
    )
}

function Get-McpAdapterLocalCandidateFullPath {
    param(
        [AllowNull()][string]$Value,
        [AllowNull()][string]$WorkingDirectory
    )

    if (-not (Test-McpAdapterLocalPathCandidate -Value $Value) -or
        [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
        return $null
    }

    try {
        if ([IO.Path]::IsPathRooted($Value)) {
            return [IO.Path]::GetFullPath($Value)
        }
        return [IO.Path]::GetFullPath((Join-Path $WorkingDirectory $Value))
    }
    catch {
        return $null
    }
}

function Resolve-McpStartupFilePath {
    param(
        [AllowNull()][object]$Stdio,
        [AllowNull()][string]$WorkingDirectory,
        [AllowNull()][string]$Command,
        [AllowNull()][string[]]$Arguments
    )

    $startup = Get-McpAdapterString -InputObject $Stdio `
        -Names @('startup_file', 'StartupFile', 'startup_path', 'StartupPath', 'path', 'Path')
    if ($null -eq $startup) {
        if (Test-McpAdapterLocalPathCandidate -Value $Command) {
            $startup = $Command
        }
        else {
            foreach ($arg in @($Arguments)) {
                if (Test-McpAdapterLocalPathCandidate -Value $arg) {
                    $startup = $arg
                    break
                }
            }
        }
    }
    if ($null -eq $startup) {
        return [pscustomobject][ordered]@{
            Path = $null
            Error = $null
        }
    }
    if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) {
        return [pscustomobject][ordered]@{
            Path = $null
            Error = 'stdio.working_directory is required for startup file validation.'
        }
    }
    if ([IO.Path]::IsPathRooted($startup)) {
        return [pscustomobject][ordered]@{
            Path = $null
            Error = 'stdio.startup_file must be relative to stdio.working_directory.'
        }
    }
    $workingDirectoryPath = [IO.Path]::GetFullPath($WorkingDirectory)
    $startupPath = [IO.Path]::GetFullPath((Join-Path $workingDirectoryPath $startup))
    if (-not (Test-McpAdapterPathWithinRoot -Path $startupPath -Root $workingDirectoryPath)) {
        return [pscustomobject][ordered]@{
            Path = $null
            Error = 'stdio.startup_file must stay within stdio.working_directory.'
        }
    }

    return [pscustomobject][ordered]@{
        Path = $startupPath
        Error = $null
    }
}

function New-McpAdapterFailedPlan {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Errors,

        [AllowNull()]
        [object]$Snapshot
    )

    $summary = New-McpApprovedSnapshotSummary -Snapshot $Snapshot
    return [pscustomobject][ordered]@{
        Status = 'failed'
        Message = "MCP adapter validation failed: $($Errors -join '; ')"
        Errors = @($Errors)
        ApprovedSnapshot = $summary
        Id = if ($null -eq $summary) { $null } else { $summary.id }
        Name = if ($null -eq $summary) { $null } else { $summary.name }
        Type = if ($null -eq $summary) { $null } else { $summary.type }
        Source = if ($null -eq $summary) { $null } else { $summary.source }
        Version = if ($null -eq $summary) { $null } else { $summary.version }
        McpName = $null
        Transport = $null
        AddCommand = $null
        RemoveCommand = $null
        GetCommand = $null
        StartupFilePath = $null
        StartupFileExists = $false
        SensitiveRedactions = @()
    }
}

function Get-McpInstallPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Tool
    )

    $snapshot = Get-McpAdapterSnapshot -Tool $Tool
    $errors = New-Object System.Collections.Generic.List[string]
    if ($null -eq $snapshot) {
        [void]$errors.Add('ApprovedSnapshot is required for MCP command planning.')
        return New-McpAdapterFailedPlan -Errors $errors.ToArray() -Snapshot $snapshot
    }

    $id = Get-McpAdapterString -InputObject $snapshot -Names @('id', 'Id')
    $type = Get-McpAdapterString -InputObject $snapshot -Names @('type', 'Type')
    $name = Get-McpAdapterString -InputObject $snapshot -Names @('name', 'Name')
    $source = Get-McpAdapterString -InputObject $snapshot -Names @('source', 'Source')
    $version = Get-McpAdapterString -InputObject $snapshot -Names @('version', 'Version')
    $sha256 = Get-McpAdapterString -InputObject $snapshot -Names @('sha256', 'Hash')
    $transport = Get-McpAdapterString -InputObject $snapshot `
        -Names @('mcp_transport', 'McpTransport', 'transport')
    $mcpName = Get-McpAdapterString -InputObject $snapshot `
        -Names @('mcp_name', 'McpName')
    $stdio = Get-McpAdapterMember -InputObject $snapshot -Names @('stdio', 'Stdio')
    $http = Get-McpAdapterMember -InputObject $snapshot -Names @('http', 'Http')

    foreach ($required in @(
            @{ Name = 'id'; Value = $id },
            @{ Name = 'type'; Value = $type },
            @{ Name = 'name'; Value = $name },
            @{ Name = 'source'; Value = $source },
            @{ Name = 'version'; Value = $version },
            @{ Name = 'sha256'; Value = $sha256 },
            @{ Name = 'mcp_transport'; Value = $transport },
            @{ Name = 'mcp_name'; Value = $mcpName }
        )) {
        if ([string]::IsNullOrWhiteSpace($required.Value)) {
            [void]$errors.Add("Missing required whitelist field '$($required.Name)'.")
        }
    }

    if ($null -ne $type -and $type -ne 'mcp') {
        [void]$errors.Add("ApprovedSnapshot type must be 'mcp'.")
    }
    if ($null -ne $transport -and @('stdio', 'http') -notcontains $transport) {
        [void]$errors.Add("mcp_transport must be 'stdio' or 'http'.")
    }
    if ($null -ne $mcpName -and -not (Test-McpAdapterSafeName -Value $mcpName)) {
        [void]$errors.Add('mcp_name must contain only safe characters.')
    }

    $addArguments = @()
    $startupPath = $null
    $startupExists = $false
    if ($transport -eq 'stdio') {
        if ($null -eq $stdio) {
            [void]$errors.Add("Missing required whitelist field 'stdio'.")
        }
        $command = Get-McpAdapterString -InputObject $stdio -Names @('command', 'Command')
        $args = @(
            Get-McpAdapterArray -Value (
                Get-McpAdapterMember -InputObject $stdio -Names @('args', 'Arguments')
            ) |
                ForEach-Object { [string]$_ }
        )
        $workingDirectory = Get-McpAdapterString -InputObject $stdio `
            -Names @('working_directory', 'WorkingDirectory')
        if ([string]::IsNullOrWhiteSpace($command)) {
            [void]$errors.Add("Missing required whitelist field 'stdio.command'.")
        }

        $envArgs = @()
        $env = Get-McpAdapterMember -InputObject $stdio -Names @('env', 'Env')
        if ($null -ne $env) {
            [void]$errors.Add(
                'stdio.env is not supported because environment values may expose secrets.'
            )
        }
        $envNames = @(
            Get-McpAdapterArray -Value (
                Get-McpAdapterMember -InputObject $stdio `
                    -Names @('env_names', 'EnvNames', 'env_name', 'EnvName')
            ) |
                ForEach-Object { [string]$_ }
        )
        if ($envNames.Count -gt 0) {
            [void]$errors.Add(
                'stdio.env_names is not supported because codex mcp add --env requires KEY=VALUE.'
            )
        }

        $startupCheck = Resolve-McpStartupFilePath -Stdio $stdio `
            -WorkingDirectory $workingDirectory `
            -Command $command `
            -Arguments $args
        if ($null -ne $startupCheck.Error) {
            [void]$errors.Add($startupCheck.Error)
        }
        $startupPath = $startupCheck.Path
        if ($null -ne $startupPath) {
            $startupExists = Test-Path -LiteralPath $startupPath -PathType Leaf
            if (-not $startupExists) {
                [void]$errors.Add('MCP stdio startup file does not exist.')
            }
        }

        $resolvedCommand = $command
        $resolvedArgs = @($args)
        if ($null -ne $startupPath -and $startupExists) {
            $startupMapped = $false
            $commandPath = Get-McpAdapterLocalCandidateFullPath `
                -Value $command `
                -WorkingDirectory $workingDirectory
            if ($null -ne $commandPath -and
                [string]::Equals(
                    $commandPath,
                    $startupPath,
                    [StringComparison]::OrdinalIgnoreCase
                )) {
                $resolvedCommand = $startupPath
                $startupMapped = $true
            }

            for ($index = 0; $index -lt $resolvedArgs.Count; $index++) {
                $argumentPath = Get-McpAdapterLocalCandidateFullPath `
                    -Value $resolvedArgs[$index] `
                    -WorkingDirectory $workingDirectory
                if ($null -ne $argumentPath -and
                    [string]::Equals(
                        $argumentPath,
                        $startupPath,
                        [StringComparison]::OrdinalIgnoreCase
                    )) {
                    $resolvedArgs[$index] = $startupPath
                    $startupMapped = $true
                }
            }

            if (-not $startupMapped) {
                [void]$errors.Add(
                    'stdio.startup_file must identify the command or one of its arguments.'
                )
            }
        }

        if ($errors.Count -eq 0) {
            $addArguments = @('mcp', 'add', $mcpName) +
                $envArgs +
                @('--', $resolvedCommand) +
                $resolvedArgs
        }
    }
    elseif ($transport -eq 'http') {
        if ($null -eq $http) {
            [void]$errors.Add("Missing required whitelist field 'http'.")
        }
        $url = Get-McpAdapterString -InputObject $http -Names @('url', 'Url')
        $bearerTokenEnvVar = Get-McpAdapterString -InputObject $http `
            -Names @('bearer_token_env_var', 'BearerTokenEnvVar')
        if ([string]::IsNullOrWhiteSpace($url)) {
            [void]$errors.Add("Missing required whitelist field 'http.url'.")
        }
        else {
            $uri = $null
            if (-not [Uri]::TryCreate($url, [UriKind]::Absolute, [ref]$uri) -or
                @('http', 'https') -notcontains $uri.Scheme) {
                [void]$errors.Add('http.url must be an absolute http or https URL.')
            }
            elseif (-not [string]::IsNullOrEmpty($uri.UserInfo) -or
                -not [string]::IsNullOrEmpty($uri.Query) -or
                -not [string]::IsNullOrEmpty($uri.Fragment)) {
                [void]$errors.Add('http.url must not include userinfo, query, or fragment.')
            }
        }
        if ($null -ne $bearerTokenEnvVar -and
            -not (Test-McpAdapterSafeEnvName -Value $bearerTokenEnvVar)) {
            [void]$errors.Add('HTTP bearer token environment variable name is not safe.')
        }
        if ($errors.Count -eq 0) {
            $addArguments = @('mcp', 'add', $mcpName, '--url', $url)
            if ($null -ne $bearerTokenEnvVar) {
                $addArguments += @('--bearer-token-env-var', $bearerTokenEnvVar)
            }
        }
    }

    if ($errors.Count -gt 0) {
        return New-McpAdapterFailedPlan -Errors $errors.ToArray() -Snapshot $snapshot
    }

    $summary = New-McpApprovedSnapshotSummary -Snapshot $snapshot
    $redactions = Get-McpAdapterSafeRedactions -Snapshot $snapshot
    return [pscustomobject][ordered]@{
        Status = 'planned'
        Message = "Codex MCP '$mcpName' install is planned."
        Errors = @()
        ApprovedSnapshot = $summary
        Id = $id
        Name = $name
        Type = $type
        Source = $source
        Version = $version
        Sha256 = $sha256
        McpName = $mcpName
        Transport = $transport
        AddCommand = New-McpAdapterCommand -FilePath 'codex' -Arguments $addArguments
        RemoveCommand = New-McpAdapterCommand -FilePath 'codex' `
            -Arguments @('mcp', 'remove', $mcpName)
        GetCommand = New-McpAdapterCommand -FilePath 'codex' `
            -Arguments @('mcp', 'get', $mcpName, '--json')
        StartupFilePath = $startupPath
        StartupFileExists = $startupExists
        WorkingDirectory = $workingDirectory
        ResolvedCommand = $resolvedCommand
        ResolvedArguments = @($resolvedArgs)
        SensitiveRedactions = @($redactions)
    }
}

function New-McpSmokePlanIssue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [string]$ErrorCode,

        [AllowNull()]
        [object]$InstallPlan
    )

    return [pscustomobject][ordered]@{
        Status = $Status
        Message = $Message
        ErrorCode = $ErrorCode
        InstallPlan = $InstallPlan
    }
}

function Test-McpAdapterReparsePoint {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }
        $item = Get-Item -LiteralPath $path -Force
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            return $true
        }
    }
    return $false
}

function Get-McpSmokePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$InstallPlan,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    if ($InstallPlan.Status -ne 'planned') {
        return New-McpSmokePlanIssue -Status 'failed' `
            -Message $InstallPlan.Message `
            -ErrorCode 'mcp_install_plan_invalid' `
            -InstallPlan $InstallPlan
    }

    $profile = Get-McpAdapterMember -InputObject $InstallPlan.ApprovedSnapshot `
        -Names @('smoke', 'Smoke')
    if ($null -eq $profile) {
        return New-McpSmokePlanIssue -Status 'blocked' `
            -Message 'MCP smoke verifier profile is missing.' `
            -ErrorCode 'smoke_verifier_missing' `
            -InstallPlan $InstallPlan
    }

    if ($InstallPlan.Transport -ne 'stdio') {
        return New-McpSmokePlanIssue -Status 'failed' `
            -Message 'MCP smoke verification requires stdio transport.' `
            -ErrorCode 'mcp_smoke_profile_invalid' `
            -InstallPlan $InstallPlan
    }

    $toolName = Get-McpAdapterString -InputObject $profile -Names @('tool_name', 'ToolName')
    $scriptPathValue = Get-McpAdapterString -InputObject $profile `
        -Names @('script_path', 'ScriptPath')
    $expectedSha256 = Get-McpAdapterString -InputObject $profile `
        -Names @('script_sha256', 'ScriptSha256')
    $timeoutValue = Get-McpAdapterString -InputObject $profile `
        -Names @('timeout_seconds', 'TimeoutSeconds')
    if ([string]::IsNullOrWhiteSpace($toolName) -or
        [string]::IsNullOrWhiteSpace($scriptPathValue) -or
        [string]::IsNullOrWhiteSpace($expectedSha256) -or
        [string]::IsNullOrWhiteSpace($timeoutValue)) {
        return New-McpSmokePlanIssue -Status 'failed' `
            -Message 'MCP smoke verifier profile is incomplete.' `
            -ErrorCode 'mcp_smoke_profile_invalid' `
            -InstallPlan $InstallPlan
    }

    $timeoutSeconds = 0
    if (-not [int]::TryParse($timeoutValue, [ref]$timeoutSeconds) -or $timeoutSeconds -le 0) {
        return New-McpSmokePlanIssue -Status 'failed' `
            -Message 'MCP smoke verifier timeout_seconds must be a positive integer.' `
            -ErrorCode 'mcp_smoke_profile_invalid' `
            -InstallPlan $InstallPlan
    }

    $projectRootPath = [IO.Path]::GetFullPath($ProjectRoot)
    $scriptsPath = [IO.Path]::GetFullPath((Join-Path $projectRootPath 'scripts'))
    $smokePath = [IO.Path]::GetFullPath((Join-Path $scriptsPath 'smoke'))
    $mcpPath = [IO.Path]::GetFullPath((Join-Path $smokePath 'mcp'))
    $scriptCandidate = if ([IO.Path]::IsPathRooted($scriptPathValue)) {
        $scriptPathValue
    }
    else {
        Join-Path $projectRootPath $scriptPathValue
    }
    $resolvedScriptPath = [IO.Path]::GetFullPath($scriptCandidate)

    if (-not (Test-McpAdapterPathWithinRoot -Path $resolvedScriptPath -Root $mcpPath)) {
        return New-McpSmokePlanIssue -Status 'failed' `
            -Message 'MCP smoke script path must stay below scripts/smoke/mcp.' `
            -ErrorCode 'mcp_smoke_script_path_rejected' `
            -InstallPlan $InstallPlan
    }

    if (Test-McpAdapterReparsePoint -Paths @(
            $scriptsPath,
            $smokePath,
            $mcpPath,
            $resolvedScriptPath
        )) {
        return New-McpSmokePlanIssue -Status 'failed' `
            -Message 'MCP smoke script path must not contain reparse points.' `
            -ErrorCode 'mcp_smoke_script_path_rejected' `
            -InstallPlan $InstallPlan
    }

    if (-not (Test-Path -LiteralPath $resolvedScriptPath -PathType Leaf)) {
        return New-McpSmokePlanIssue -Status 'failed' `
            -Message 'MCP smoke script file does not exist.' `
            -ErrorCode 'mcp_smoke_script_missing' `
            -InstallPlan $InstallPlan
    }

    $actualSha256 = (Get-FileHash -LiteralPath $resolvedScriptPath -Algorithm SHA256).
        Hash.ToLowerInvariant()
    if ($actualSha256 -ne $expectedSha256.ToLowerInvariant()) {
        return New-McpSmokePlanIssue -Status 'failed' `
            -Message 'MCP smoke script SHA256 does not match the approved profile.' `
            -ErrorCode 'mcp_smoke_script_hash_mismatch' `
            -InstallPlan $InstallPlan
    }

    $runnerPath = Join-Path $projectRootPath 'scripts\node\mcp-smoke-runner.mjs'
    if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
        return New-McpSmokePlanIssue -Status 'failed' `
            -Message 'MCP smoke runner script does not exist.' `
            -ErrorCode 'mcp_smoke_runner_missing' `
            -InstallPlan $InstallPlan
    }

    $workingDirectory = Get-McpAdapterString -InputObject $InstallPlan `
        -Names @('WorkingDirectory', 'working_directory')
    if ([string]::IsNullOrWhiteSpace($workingDirectory)) {
        return New-McpSmokePlanIssue -Status 'failed' `
            -Message 'MCP smoke profile requires a stdio working directory.' `
            -ErrorCode 'mcp_smoke_profile_invalid' `
            -InstallPlan $InstallPlan
    }
    $workingDirectoryPath = [IO.Path]::GetFullPath($workingDirectory)
    $sdkClientPath = Join-Path $workingDirectoryPath `
        'node_modules\@modelcontextprotocol\sdk\dist\esm\client\index.js'
    $sdkStdioPath = Join-Path $workingDirectoryPath `
        'node_modules\@modelcontextprotocol\sdk\dist\esm\client\stdio.js'
    foreach ($sdkPath in @($sdkClientPath, $sdkStdioPath)) {
        if (-not (Test-Path -LiteralPath $sdkPath -PathType Leaf)) {
            return New-McpSmokePlanIssue -Status 'failed' `
                -Message 'MCP SDK client files required by the smoke runner are missing.' `
                -ErrorCode 'mcp_smoke_sdk_missing' `
                -InstallPlan $InstallPlan
        }
    }

    try {
        $serverFilePath = [string]@(
            Get-Command -Name $InstallPlan.ResolvedCommand -CommandType Application `
                -ErrorAction Stop
        )[0].Source
    }
    catch {
        return New-McpSmokePlanIssue -Status 'failed' `
            -Message 'MCP stdio server command could not be resolved.' `
            -ErrorCode 'mcp_smoke_server_command_not_found' `
            -InstallPlan $InstallPlan
    }

    return [pscustomobject][ordered]@{
        Status = 'planned'
        Message = 'MCP smoke verification is planned.'
        ErrorCode = $null
        InstallPlan = $InstallPlan
        ToolName = [string]$toolName
        Arguments = Get-McpAdapterMember -InputObject $profile -Names @('arguments', 'Arguments')
        TimeoutSeconds = [int]$timeoutSeconds
        ExpectedContentTypes = @(
            Get-McpAdapterArray -Value (
                Get-McpAdapterMember -InputObject $profile `
                    -Names @('expected_content_types', 'ExpectedContentTypes')
            )
        )
        ScriptPath = $resolvedScriptPath
        ScriptSha256 = [string]$expectedSha256
        RunnerPath = $runnerPath
        TempRootParent = (Join-Path $projectRootPath '.tmp\mcp-smoke')
        SdkClientPath = $sdkClientPath
        SdkStdioPath = $sdkStdioPath
        ServerFilePath = $serverFilePath
    }
}

function Add-McpJournalIntent {
    param(
        [AllowNull()]
        [object]$Plan,

        [AllowNull()]
        [object]$Journal
    )

    if ($null -eq $Journal) {
        return
    }

    $entry = [pscustomobject][ordered]@{
        Type = 'ExternalChange'
        Description = "Codex MCP install may update managed Codex MCP configuration for '$($Plan.McpName)'."
        RollbackCommand = ''
        Plan = [pscustomobject][ordered]@{
            AddCommand = $Plan.AddCommand
            RemoveCommand = $Plan.RemoveCommand
        }
    }

    $callback = Get-McpAdapterMember -InputObject $Journal -Names @('AddExternalChange')
    if ($callback -is [scriptblock]) {
        & $callback $entry
        return
    }

    $journalPath = Get-McpAdapterMember -InputObject $Journal -Names @('JournalPath')
    if ($null -ne $journalPath -and
        (Get-Command Add-ExternalChange -ErrorAction SilentlyContinue)) {
        [void](Add-ExternalChange -Journal $Journal `
                -Description $entry.Description `
                -RollbackCommand '')
    }
}

function Install-ManagedMcp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Plan,

        [AllowNull()]
        [object]$Journal,

        [AllowNull()]
        [scriptblock]$Executor
    )

    if ($Plan.Status -ne 'planned') {
        return New-OperationResult -Status 'failed' `
            -Message (Protect-McpAdapterText -Text $Plan.Message `
                -SensitiveValues $Plan.SensitiveRedactions) `
            -Data ([pscustomobject][ordered]@{
                PlanOnly = $true
                Errors = @($Plan.Errors)
            })
    }
    Add-McpJournalIntent -Plan $Plan -Journal $Journal
    if ($null -eq $Executor) {
        return New-OperationResult -Status 'blocked' `
            -Message 'Executor is required; MCP install is plan_only and no codex command was run.' `
            -Data ([pscustomobject][ordered]@{
                PlanOnly = $true
                McpName = $Plan.McpName
                AddCommand = $Plan.AddCommand
                RemoveCommand = $Plan.RemoveCommand
            })
    }

    $addResult = Invoke-McpAdapterExecutor -Command $Plan.AddCommand `
        -Executor $Executor `
        -SensitiveValues $Plan.SensitiveRedactions
    if (-not (Test-McpProcessSucceeded -Result $addResult)) {
        return New-OperationResult -Status 'failed' `
            -Message (
                'Codex MCP add failed: ' +
                (Get-McpProcessText -Result $addResult `
                    -SensitiveValues $Plan.SensitiveRedactions)
            ) `
            -Data ([pscustomobject][ordered]@{
                McpName = $Plan.McpName
                FailedStep = 'mcp_add'
                Command = $Plan.AddCommand
                ResultSummary = New-McpProcessSummary -Step 'mcp_add' `
                    -Result $addResult `
                    -SensitiveValues $Plan.SensitiveRedactions
            })
    }

    return New-OperationResult -Status 'succeeded' `
        -Message "Codex MCP '$($Plan.McpName)' add command completed." `
        -Data ([pscustomobject][ordered]@{
            McpName = $Plan.McpName
            Steps = @(
                New-McpProcessSummary -Step 'mcp_add' `
                    -Result $addResult `
                    -SensitiveValues $Plan.SensitiveRedactions
            )
        })
}

function Uninstall-ManagedMcp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Plan,

        [AllowNull()]
        [scriptblock]$Executor
    )

    if ($Plan.Status -ne 'planned') {
        return New-OperationResult -Status 'failed' `
            -Message (Protect-McpAdapterText -Text $Plan.Message `
                -SensitiveValues $Plan.SensitiveRedactions) `
            -Data ([pscustomobject][ordered]@{ Errors = @($Plan.Errors) })
    }
    if ($null -eq $Executor) {
        return New-OperationResult -Status 'blocked' `
            -Message 'Executor is required; MCP uninstall is plan_only and no codex command was run.' `
            -Data ([pscustomobject][ordered]@{
                PlanOnly = $true
                McpName = $Plan.McpName
                RemoveCommand = $Plan.RemoveCommand
            })
    }

    $removeResult = Invoke-McpAdapterExecutor -Command $Plan.RemoveCommand `
        -Executor $Executor `
        -SensitiveValues $Plan.SensitiveRedactions
    if (-not (Test-McpProcessSucceeded -Result $removeResult)) {
        return New-OperationResult -Status 'failed' `
            -Message (
                'Codex MCP remove failed: ' +
                (Get-McpProcessText -Result $removeResult `
                    -SensitiveValues $Plan.SensitiveRedactions)
            ) `
            -Data ([pscustomobject][ordered]@{
                McpName = $Plan.McpName
                Command = $Plan.RemoveCommand
                ResultSummary = New-McpProcessSummary -Step 'mcp_remove' `
                    -Result $removeResult `
                    -SensitiveValues $Plan.SensitiveRedactions
            })
    }

    return New-OperationResult -Status 'succeeded' `
        -Message "Codex MCP '$($Plan.McpName)' remove command completed." `
        -Data ([pscustomobject][ordered]@{
            McpName = $Plan.McpName
            Steps = @(
                New-McpProcessSummary -Step 'mcp_remove' `
                    -Result $removeResult `
                    -SensitiveValues $Plan.SensitiveRedactions
            )
        })
}

function New-McpVerificationResult {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Plan,

        [Parameter(Mandatory = $true)]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [AllowNull()]
        [object[]]$Checks = @(),

        [AllowNull()]
        [object]$ErrorCode = $null
    )

    if (Get-Command New-VerificationResult -ErrorAction SilentlyContinue) {
        return New-VerificationResult -Tool $Plan.ApprovedSnapshot `
            -Level 'load' `
            -Status $Status `
            -Message $Message `
            -StartedAt ([DateTime]::UtcNow) `
            -Checks $Checks `
            -SensitiveRedactions $Plan.SensitiveRedactions `
            -ErrorCode $ErrorCode
    }

    return [pscustomobject][ordered]@{
        ToolId = $Plan.Id
        Name = $Plan.Name
        Type = 'mcp'
        Version = $Plan.Version
        Source = $Plan.Source
        Level = 'load'
        Status = $Status
        Message = Protect-McpAdapterText -Text $Message `
            -SensitiveValues $Plan.SensitiveRedactions
        Checks = @($Checks)
        ErrorCode = $ErrorCode
    }
}

function Test-McpGetOutputContainsName {
    param(
        [AllowNull()]
        [object]$JsonObject,

        [Parameter(Mandatory = $true)]
        [string]$McpName
    )

    foreach ($item in @(Get-McpAdapterArray -Value $JsonObject)) {
        $name = Get-McpAdapterString -InputObject $item `
            -Names @('name', 'Name', 'mcp_name', 'McpName', 'id', 'Id')
        if ($name -eq $McpName) {
            return $true
        }
    }
    return $false
}

function Test-ManagedMcpSmokeProfile {
    param([object]$Plan)

    if ($Plan.Status -eq 'blocked') {
        return @{
            Status = 'blocked'
            Message = $Plan.Message
            ErrorCode = $Plan.ErrorCode
        }
    }
    if ($Plan.Status -ne 'planned') {
        return @{
            Status = 'failed'
            Message = $Plan.Message
            ErrorCode = $Plan.ErrorCode
        }
    }
    return @{
        Status = 'static_verified'
        Message = 'MCP smoke profile paths and hashes were verified.'
        Checks = @('mcp_smoke_profile_valid', 'mcp_smoke_script_hash_verified')
    }
}

function Test-ManagedMcp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Plan,

        [AllowNull()]
        [scriptblock]$Executor,

        [AllowNull()]
        [scriptblock]$Verifier
    )

    if ($Plan.Status -ne 'planned') {
        return New-McpVerificationResult -Plan $Plan `
            -Status 'failed' `
            -Message $Plan.Message `
            -ErrorCode 'validation_failed'
    }
    if ($null -ne $Verifier) {
        return & $Verifier $Plan
    }
    if ($null -eq $Executor) {
        return New-McpVerificationResult -Plan $Plan `
            -Status 'blocked' `
            -Message 'Executor or Verifier is required; MCP availability was not tested.' `
            -ErrorCode 'missing_executor'
    }

    $getResult = Invoke-McpAdapterExecutor -Command $Plan.GetCommand `
        -Executor $Executor `
        -SensitiveValues $Plan.SensitiveRedactions
    if (-not (Test-McpProcessSucceeded -Result $getResult)) {
        return New-McpVerificationResult -Plan $Plan `
            -Status 'failed' `
            -Message (
                'Codex MCP get failed: ' +
                (Get-McpProcessText -Result $getResult `
                    -SensitiveValues $Plan.SensitiveRedactions)
            ) `
            -Checks @('codex mcp get <name> --json') `
            -ErrorCode 'mcp_get_failed'
    }

    $stdout = Get-McpAdapterMember -InputObject $getResult -Names @('StdOut', 'stdout')
    try {
        $json = "$stdout" | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return New-McpVerificationResult -Plan $Plan `
            -Status 'failed' `
            -Message 'Codex MCP get JSON output could not be parsed.' `
            -Checks @('codex mcp get <name> --json') `
            -ErrorCode 'mcp_get_parse_failed'
    }

    if (-not (Test-McpGetOutputContainsName -JsonObject $json -McpName $Plan.McpName)) {
        return New-McpVerificationResult -Plan $Plan `
            -Status 'failed' `
            -Message "Codex MCP '$($Plan.McpName)' was not found in MCP get output." `
            -Checks @('codex mcp get <name> --json') `
            -ErrorCode 'mcp_not_found'
    }

    return New-McpVerificationResult -Plan $Plan `
        -Status 'load_verified' `
        -Message "Codex MCP '$($Plan.McpName)' was found by codex mcp get." `
        -Checks @("Found $($Plan.McpName) with codex mcp get --json.")
}
