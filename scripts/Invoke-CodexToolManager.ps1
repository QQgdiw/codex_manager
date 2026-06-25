param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$script:ProjectRoot = Split-Path -Parent $PSScriptRoot
$script:LibraryRoot = Join-Path $PSScriptRoot 'lib'

. (Join-Path $script:LibraryRoot 'Common.ps1')
. (Join-Path $script:LibraryRoot 'Read-Toml.ps1')
. (Join-Path $script:LibraryRoot 'DeploymentEngine.ps1')
. (Join-Path $script:LibraryRoot 'ChangeJournal.ps1')
. (Join-Path $script:LibraryRoot 'CredentialStore.ps1')
. (Join-Path $script:LibraryRoot 'VerificationEngine.ps1')
. (Join-Path $script:LibraryRoot 'adapters\PluginAdapter.ps1')
. (Join-Path $script:LibraryRoot 'adapters\McpAdapter.ps1')
. (Join-Path $script:LibraryRoot 'adapters\SkillAdapter.ps1')

$script:SuccessExitCode = 0
$script:BusinessFailureExitCode = 1
$script:FatalExitCode = 2

function ConvertTo-ManagerArgumentMap {
    param([AllowNull()][string[]]$Values = @())

    $map = @{}
    $positionals = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt @($Values).Count; $index++) {
        $token = $Values[$index]
        if ($token -match '^-([A-Za-z][A-Za-z0-9_]*)$') {
            $name = $matches[1]
            if (($index + 1) -lt @($Values).Count -and
                $Values[$index + 1] -notmatch '^-([A-Za-z][A-Za-z0-9_]*)$') {
                $value = $Values[$index + 1]
                $index++
            }
            else {
                $value = $true
            }

            if ($map.ContainsKey($name)) {
                $map[$name] = @($map[$name]) + @($value)
            }
            else {
                $map[$name] = $value
            }
            continue
        }

        $positionals.Add($token)
    }

    $map['__positionals'] = $positionals.ToArray()
    return $map
}

function Get-ManagerArgument {
    param(
        [System.Collections.IDictionary]$Map,
        [string]$Name,
        [switch]$Mandatory
    )

    if ($Map.ContainsKey($Name) -and $Map[$Name] -eq $true) {
        throw "Parameter -$Name requires a value."
    }
    if ($Map.ContainsKey($Name)) {
        return [string]$Map[$Name]
    }
    if ($Mandatory) {
        throw "Missing required parameter -$Name."
    }
    return $null
}

function Test-ManagerSwitch {
    param(
        [System.Collections.IDictionary]$Map,
        [string[]]$Names
    )

    foreach ($name in $Names) {
        if ($Map.ContainsKey($name)) {
            $value = $Map[$name]
            if ($value -is [bool]) {
                return $value
            }
            return ($value -notin @('false', 'False', '0'))
        }
    }
    return $false
}

function Assert-ManagerAllowedArguments {
    param(
        [System.Collections.IDictionary]$Map,
        [string[]]$AllowedNames = @(),
        [int]$RequiredPositionals = 0,
        [int]$MaximumPositionals = 0
    )

    $allowed = @{}
    foreach ($name in @($AllowedNames)) {
        $allowed[$name] = $true
    }

    foreach ($key in @($Map.Keys)) {
        if ($key -eq '__positionals') {
            continue
        }
        if (-not $allowed.ContainsKey($key)) {
            throw "Unsupported parameter -$key."
        }
    }

    $positionals = @($Map['__positionals'])
    if ($positionals.Count -lt $RequiredPositionals) {
        throw "Expected at least $RequiredPositionals positional argument(s)."
    }
    if ($positionals.Count -gt $MaximumPositionals) {
        throw 'Unexpected extra positional argument.'
    }
}

function Write-ManagerJson {
    param([object]$Value)

    $Value | ConvertTo-Json -Depth 30
}

function Save-ManagerJson {
    param(
        [Parameter(Mandatory = $true)][object]$Value,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parent) -and
        -not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $Value | ConvertTo-Json -Depth 30 |
        Set-Content -LiteralPath $Path -Encoding UTF8
}

function Read-ManagerPlan {
    param(
        [System.Collections.IDictionary]$Map,
        [switch]$RequireValidForDeployment
    )

    $planPath = Get-ManagerArgument -Map $Map -Name 'PlanPath'
    if (-not [string]::IsNullOrWhiteSpace($planPath)) {
        if (-not (Test-Path -LiteralPath $planPath -PathType Leaf)) {
            throw "Plan file does not exist: $planPath"
        }
        return (Get-Content -LiteralPath $planPath -Raw | ConvertFrom-Json)
    }

    $configPath = Get-ManagerArgument -Map $Map -Name 'Config' -Mandatory
    $whitelistPath = Get-ManagerArgument -Map $Map -Name 'Whitelist' -Mandatory
    $config = Read-ProjectToml -Path $configPath
    $whitelist = Read-ProjectToml -Path $whitelistPath
    $credentialStorePath = Get-ManagerArgument -Map $Map -Name 'CredentialStorePath'
    if ([string]::IsNullOrWhiteSpace($credentialStorePath)) {
        $credentialStorePath = Get-ManagerArgument -Map $Map -Name 'StorePath'
    }
    $metadata = if ([string]::IsNullOrWhiteSpace($credentialStorePath)) {
        @()
    }
    else {
        @(Get-ManagedCredentialMetadata -StorePath $credentialStorePath)
    }
    $plan = New-DeploymentPlan `
        -Config $config `
        -Whitelist $whitelist `
        -CredentialMetadata $metadata
    if ($RequireValidForDeployment -and @($plan.Errors).Count -gt 0) {
        return $plan
    }
    return $plan
}

function ConvertTo-ManagerVerificationTool {
    param(
        [object]$Item,
        [AllowNull()][scriptblock]$Executor
    )

    if ($Item.Type -eq 'plugin') {
        Add-ManagerPluginSnapshotDefaults -Item $Item
    }

    $tool = [pscustomobject][ordered]@{
        id = "$($Item.Id)"
        name = "$($Item.Name)"
        type = "$($Item.Type)"
        source = "$($Item.Source)"
        version = "$($Item.Version)"
        credential_refs = @($Item.CredentialRefs)
        sensitive_redactions = @()
        ApprovedSnapshot = $Item.ApprovedSnapshot
    }

    if ($Item.Type -eq 'plugin') {
        $tool | Add-Member -NotePropertyName LoadVerifier `
            -NotePropertyValue (New-ManagerPluginLoadVerifier -Executor $Executor)
    }

    return $tool
}

function New-ManagerCodexExecutor {
    param([int]$TimeoutSeconds = 120)

    return {
        param([object]$Command)

        $filePath = Get-ProjectMember -InputObject $Command -Name 'FilePath'
        $arguments = Get-ProjectMember -InputObject $Command -Name 'Arguments'
        if (-not $filePath.Exists -or
            [string]::IsNullOrWhiteSpace([string]$filePath.Value)) {
            throw 'Managed command is missing FilePath.'
        }

        $argumentValues = if ($arguments.Exists) {
            @($arguments.Value | ForEach-Object { [string]$_ })
        }
        else {
            @()
        }

        $resolvedFilePath = [string]$filePath.Value
        $resolvedCommand = Get-Command -Name $resolvedFilePath `
            -CommandType Application `
            -ErrorAction SilentlyContinue
        if ($null -ne $resolvedCommand) {
            $resolvedFilePath = [string]@($resolvedCommand)[0].Source
        }

        Invoke-ManagedProcess `
            -FilePath $resolvedFilePath `
            -Arguments $argumentValues `
            -TimeoutSeconds $TimeoutSeconds
    }.GetNewClosure()
}

function New-ManagerBlockedAdapter {
    param([string]$Type)

    return {
        param([object]$Item)

        New-OperationResult `
            -Status 'blocked' `
            -Message (
                "Deployment adapter '$Type' is available for planning only; " +
                "real installation is not enabled by this entry point."
            ) `
            -Data ([pscustomobject][ordered]@{
                ItemId = $Item.Id
                AdapterType = $Type
                RollbackRequired = $false
                RollbackCapability = $Item.RollbackCapability
            })
    }.GetNewClosure()
}

function Add-ManagerPluginSnapshotDefaults {
    param([object]$Item)

    $snapshotMember = Get-ProjectMember -InputObject $Item -Name 'ApprovedSnapshot'
    if (-not $snapshotMember.Exists -or $null -eq $snapshotMember.Value) {
        return
    }

    $snapshot = $snapshotMember.Value
    $marketplaceMember = Get-ProjectMember -InputObject $snapshot -Name 'marketplace_name'
    $selectorMember = Get-ProjectMember -InputObject $snapshot -Name 'plugin_selector'
    $marketplace = if ($marketplaceMember.Exists) {
        [string]$marketplaceMember.Value
    }
    else {
        $null
    }
    $selector = if ($selectorMember.Exists) {
        [string]$selectorMember.Value
    }
    else {
        $null
    }

    $idMember = Get-ProjectMember -InputObject $snapshot -Name 'id'
    if (-not $idMember.Exists) {
        $idMember = Get-ProjectMember -InputObject $Item -Name 'Id'
    }
    if ($idMember.Exists -and [string]$idMember.Value -match '^plugin\.(.+)\.([^.]+)$') {
        if ([string]::IsNullOrWhiteSpace($marketplace)) {
            $marketplace = $matches[1]
        }
        if ([string]::IsNullOrWhiteSpace($selector)) {
            $selector = $matches[2]
        }
    }

    $targetMember = Get-ProjectMember -InputObject $snapshot -Name 'install_target'
    if (-not $targetMember.Exists) {
        $targetMember = Get-ProjectMember -InputObject $Item -Name 'Target'
    }
    if ($targetMember.Exists -and
        [string]$targetMember.Value -match '(?i)(?:^|[\\/])Plugins[\\/]([^\\/]+)[\\/]([^\\/]+)(?:[\\/]|$)') {
        if ([string]::IsNullOrWhiteSpace($marketplace)) {
            $marketplace = $matches[1]
        }
        if ([string]::IsNullOrWhiteSpace($selector)) {
            $selector = $matches[2]
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($marketplace)) {
        $snapshot | Add-Member -NotePropertyName 'marketplace_name' `
            -NotePropertyValue $marketplace -Force
    }
    if (-not [string]::IsNullOrWhiteSpace($selector)) {
        $snapshot | Add-Member -NotePropertyName 'plugin_selector' `
            -NotePropertyValue $selector -Force
    }
}

function New-ManagerPluginAdapter {
    param([scriptblock]$Executor)

    return {
        param([object]$Item)

        Add-ManagerPluginSnapshotDefaults -Item $Item
        $plan = Get-PluginInstallPlan -Tool $Item
        Install-ManagedPlugin -Plan $plan -Executor $Executor
    }.GetNewClosure()
}

function New-ManagerPluginLoadVerifier {
    param([scriptblock]$Executor)

    return {
        param([object]$Tool)

        $plan = Get-PluginInstallPlan -Tool $Tool
        Test-ManagedPlugin -Plan $plan -Executor $Executor
    }.GetNewClosure()
}

function New-ManagerAdapterMap {
    param([AllowNull()][scriptblock]$Executor)

    if ($null -eq $Executor) {
        $Executor = New-ManagerCodexExecutor
    }

    $map = @{}
    $map['plugin'] = New-ManagerPluginAdapter -Executor $Executor
    $map['mcp'] = New-ManagerBlockedAdapter -Type 'mcp'
    $map['skill'] = New-ManagerBlockedAdapter -Type 'skill'
    return $map
}

function Invoke-ManagerPlan {
    param([System.Collections.IDictionary]$Map)

    Assert-ManagerAllowedArguments -Map $Map `
        -AllowedNames @('Config', 'Whitelist', 'OutputPath', 'CredentialStorePath', 'StorePath')
    $plan = Read-ManagerPlan -Map $Map
    $status = if (@($plan.Errors).Count -gt 0) { 'blocked' } else { 'succeeded' }
    $exitCode = if ($status -eq 'succeeded') {
        $script:SuccessExitCode
    }
    else {
        $script:BusinessFailureExitCode
    }

    $outputPath = Get-ManagerArgument -Map $Map -Name 'OutputPath'
    if (-not [string]::IsNullOrWhiteSpace($outputPath)) {
        Save-ManagerJson -Value $plan -Path $outputPath
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Body = [pscustomobject][ordered]@{
            Command = 'plan'
            Status = $status
            ExitCode = $exitCode
            Plan = $plan
        }
    }
}

function Invoke-ManagerDeploy {
    param([System.Collections.IDictionary]$Map)

    Assert-ManagerAllowedArguments -Map $Map `
        -AllowedNames @(
            'Config', 'Whitelist', 'PlanPath', 'CredentialStorePath',
            'StorePath', 'DryRun', 'WhatIf'
        )
    $plan = Read-ManagerPlan -Map $Map -RequireValidForDeployment
    if (@($plan.Errors).Count -gt 0) {
        return [pscustomobject]@{
            ExitCode = $script:BusinessFailureExitCode
            Body = [pscustomobject][ordered]@{
                Command = 'deploy'
                Status = 'blocked'
                ExitCode = $script:BusinessFailureExitCode
                Plan = $plan
                Results = @()
            }
        }
    }

    $dryRun = Test-ManagerSwitch -Map $Map -Names @('DryRun', 'WhatIf')
    $results = @(Invoke-DeploymentPlan `
        -Plan $plan `
        -WhatIf:([bool]$dryRun) `
        -AdapterMap (New-ManagerAdapterMap))
    $blockedOrFailed = @(
        $results | Where-Object { $_.Status -in @('blocked', 'failed') }
    )
    $status = if ($blockedOrFailed.Count -gt 0) { 'blocked' } else { 'succeeded' }
    $exitCode = if ($status -eq 'succeeded') {
        $script:SuccessExitCode
    }
    else {
        $script:BusinessFailureExitCode
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Body = [pscustomobject][ordered]@{
            Command = 'deploy'
            Status = $status
            ExitCode = $exitCode
            DryRun = [bool]$dryRun
            Plan = $plan
            Results = $results
        }
    }
}

function Invoke-ManagerVerify {
    param([System.Collections.IDictionary]$Map)

    Assert-ManagerAllowedArguments -Map $Map `
        -AllowedNames @('Config', 'Whitelist', 'PlanPath', 'CredentialStorePath', 'StorePath')
    $plan = Read-ManagerPlan -Map $Map
    if (@($plan.Errors).Count -gt 0) {
        return [pscustomobject]@{
            ExitCode = $script:BusinessFailureExitCode
            Body = [pscustomobject][ordered]@{
                Command = 'verify'
                Status = 'blocked'
                ExitCode = $script:BusinessFailureExitCode
                Plan = $plan
                Results = @()
            }
        }
    }

    $results = New-Object System.Collections.Generic.List[object]
    $executor = New-ManagerCodexExecutor
    foreach ($item in @($plan.Items)) {
        $tool = ConvertTo-ManagerVerificationTool -Item $item -Executor $executor
        $results.Add((Invoke-StaticVerification -Tool $tool))
        $results.Add((Invoke-LoadVerification -Tool $tool))
        $results.Add((Invoke-SmokeVerification -Tool $tool))
    }

    $problem = @(
        $results | Where-Object {
            $_.Status -in @('failed', 'blocked')
        }
    )
    $status = if ($problem.Count -gt 0) { 'blocked' } else { 'succeeded' }
    $exitCode = if ($status -eq 'succeeded') {
        $script:SuccessExitCode
    }
    else {
        $script:BusinessFailureExitCode
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Body = [pscustomobject][ordered]@{
            Command = 'verify'
            Status = $status
            ExitCode = $exitCode
            Plan = $plan
            Results = $results.ToArray()
        }
    }
}

function Invoke-ManagerRollback {
    param([System.Collections.IDictionary]$Map)

    Assert-ManagerAllowedArguments -Map $Map `
        -AllowedNames @('JournalPath', 'AllowedRoot', 'AllowedRoots')
    $journalPath = Get-ManagerArgument -Map $Map -Name 'JournalPath' -Mandatory
    $allowedRoots = @()
    if ($Map.ContainsKey('AllowedRoot')) {
        $allowedRoots = @($Map['AllowedRoot'])
    }
    elseif ($Map.ContainsKey('AllowedRoots')) {
        $allowedRoots = @($Map['AllowedRoots'])
    }
    $journal = [pscustomobject]@{ JournalPath = $journalPath }
    $rollback = Invoke-JournalRollback `
        -Journal $journal `
        -AllowedRoots $allowedRoots
    $status = if ($rollback.Status -ceq 'Succeeded') { 'succeeded' } else { 'blocked' }
    $exitCode = if ($status -eq 'succeeded') {
        $script:SuccessExitCode
    }
    else {
        $script:BusinessFailureExitCode
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Body = [pscustomobject][ordered]@{
            Command = 'rollback'
            Status = $status
            ExitCode = $exitCode
            Rollback = $rollback
        }
    }
}

function Invoke-ManagerCredential {
    param([System.Collections.IDictionary]$Map)

    Assert-ManagerAllowedArguments -Map $Map `
        -AllowedNames @('Name', 'Value', 'StorePath') `
        -RequiredPositionals 1 `
        -MaximumPositionals 1
    $positionals = @($Map['__positionals'])
    if ($positionals.Count -lt 1) {
        throw 'credential requires an action: set, get, remove, or list.'
    }
    $action = "$($positionals[0])".ToLowerInvariant()
    $storePath = Get-ManagerArgument -Map $Map -Name 'StorePath'
    $credentialParameters = @{}
    if (-not [string]::IsNullOrWhiteSpace($storePath)) {
        $credentialParameters['StorePath'] = $storePath
    }

    switch ($action) {
        'set' {
            $name = Get-ManagerArgument -Map $Map -Name 'Name' -Mandatory
            $value = Get-ManagerArgument -Map $Map -Name 'Value' -Mandatory
            $secret = ConvertTo-SecureString $value -AsPlainText -Force
            Set-ManagedCredential @credentialParameters -Name $name -Secret $secret
            $metadata = @(
                Get-ManagedCredentialMetadata @credentialParameters |
                    Where-Object { $_.Name -ieq $name }
            ) | Select-Object -First 1
            return [pscustomobject]@{
                ExitCode = $script:SuccessExitCode
                Body = [pscustomobject][ordered]@{
                    Command = 'credential'
                    Action = 'set'
                    Status = 'succeeded'
                    ExitCode = $script:SuccessExitCode
                    Credential = $metadata
                    Redacted = $true
                }
            }
        }
        'get' {
            $name = Get-ManagerArgument -Map $Map -Name 'Name' -Mandatory
            $metadata = @(
                Get-ManagedCredentialMetadata @credentialParameters |
                    Where-Object { $_.Name -ieq $name }
            ) | Select-Object -First 1
            if ($null -eq $metadata) {
                return [pscustomobject]@{
                    ExitCode = $script:BusinessFailureExitCode
                    Body = [pscustomobject][ordered]@{
                        Command = 'credential'
                        Action = 'get'
                        Status = 'not_found'
                        ExitCode = $script:BusinessFailureExitCode
                        Redacted = $true
                    }
                }
            }
            return [pscustomobject]@{
                ExitCode = $script:SuccessExitCode
                Body = [pscustomobject][ordered]@{
                    Command = 'credential'
                    Action = 'get'
                    Status = 'succeeded'
                    ExitCode = $script:SuccessExitCode
                    Credential = $metadata
                    Redacted = $true
                }
            }
        }
        'remove' {
            $name = Get-ManagerArgument -Map $Map -Name 'Name' -Mandatory
            $removed = Remove-ManagedCredential @credentialParameters -Name $name
            return [pscustomobject]@{
                ExitCode = $script:SuccessExitCode
                Body = [pscustomobject][ordered]@{
                    Command = 'credential'
                    Action = 'remove'
                    Status = 'succeeded'
                    ExitCode = $script:SuccessExitCode
                    Removed = [bool]$removed
                    Redacted = $true
                }
            }
        }
        'list' {
            $metadata = @(Get-ManagedCredentialMetadata @credentialParameters)
            return [pscustomobject]@{
                ExitCode = $script:SuccessExitCode
                Body = [pscustomobject][ordered]@{
                    Command = 'credential'
                    Action = 'list'
                    Status = 'succeeded'
                    ExitCode = $script:SuccessExitCode
                    Credentials = $metadata
                    Redacted = $true
                }
            }
        }
        default {
            throw "Unsupported credential action: $action"
        }
    }
}

function Invoke-ManagerStatus {
    param([System.Collections.IDictionary]$Map)

    Assert-ManagerAllowedArguments -Map $Map `
        -AllowedNames @('Config', 'Whitelist')
    $configPath = Get-ManagerArgument -Map $Map -Name 'Config'
    $whitelistPath = Get-ManagerArgument -Map $Map -Name 'Whitelist'
    return [pscustomobject]@{
        ExitCode = $script:SuccessExitCode
        Body = [pscustomobject][ordered]@{
            Command = 'status'
            Status = 'succeeded'
            ExitCode = $script:SuccessExitCode
            ProjectRoot = $script:ProjectRoot
            ConfigPath = $configPath
            ConfigExists = (
                -not [string]::IsNullOrWhiteSpace($configPath) -and
                (Test-Path -LiteralPath $configPath -PathType Leaf)
            )
            WhitelistPath = $whitelistPath
            WhitelistExists = (
                -not [string]::IsNullOrWhiteSpace($whitelistPath) -and
                (Test-Path -LiteralPath $whitelistPath -PathType Leaf)
            )
            AdapterTypes = @('plugin', 'mcp', 'skill')
            LastOperation = $null
        }
    }
}

try {
    if ([string]::IsNullOrWhiteSpace($Command)) {
        $Command = 'plan'
    }

    $normalizedCommand = $Command.ToLowerInvariant()
    $map = ConvertTo-ManagerArgumentMap -Values $Arguments
    $result = switch ($normalizedCommand) {
        'plan' { Invoke-ManagerPlan -Map $map; break }
        'deploy' { Invoke-ManagerDeploy -Map $map; break }
        'verify' { Invoke-ManagerVerify -Map $map; break }
        'rollback' { Invoke-ManagerRollback -Map $map; break }
        'credential' { Invoke-ManagerCredential -Map $map; break }
        'status' { Invoke-ManagerStatus -Map $map; break }
        default { throw "Unsupported command: $Command" }
    }

    Write-ManagerJson -Value $result.Body
    exit $result.ExitCode
}
catch {
    $body = [pscustomobject][ordered]@{
        Command = $Command
        Status = 'fatal'
        ExitCode = $script:FatalExitCode
        Message = $_.Exception.Message
    }
    Write-ManagerJson -Value $body
    exit $script:FatalExitCode
}
