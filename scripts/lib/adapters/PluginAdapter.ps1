$commonLibrary = Join-Path (Split-Path -Parent $PSScriptRoot) 'Common.ps1'
if (Test-Path -LiteralPath $commonLibrary -PathType Leaf) {
    . $commonLibrary
}

$verificationLibrary = Join-Path (Split-Path -Parent $PSScriptRoot) 'VerificationEngine.ps1'
if (Test-Path -LiteralPath $verificationLibrary -PathType Leaf) {
    . $verificationLibrary
}

function Get-PluginAdapterMember {
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

function Get-PluginAdapterString {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    $value = Get-PluginAdapterMember -InputObject $InputObject -Names $Names
    if ($null -eq $value) {
        return $null
    }
    $text = "$value"
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }
    return $text
}

function Get-PluginAdapterArray {
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

function Test-PluginAdapterSafeName {
    param([AllowNull()][string]$Value)

    return (
        -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value -match '^[A-Za-z0-9][A-Za-z0-9._-]*$'
    )
}

function Get-PluginAdapterSnapshot {
    param([AllowNull()][object]$Tool)

    $snapshot = Get-PluginAdapterMember -InputObject $Tool `
        -Names @('ApprovedSnapshot', 'approved_snapshot')
    return $snapshot
}

function Get-PluginAdapterSelectorFromId {
    param([AllowNull()][string]$Id)

    if ([string]::IsNullOrWhiteSpace($Id)) {
        return $null
    }
    if ($Id -match '^plugin\.([A-Za-z0-9][A-Za-z0-9._-]*)$') {
        return $Matches[1]
    }
    if (Test-PluginAdapterSafeName -Value $Id) {
        return $Id
    }
    return $null
}

function New-PluginAdapterCommand {
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

function New-PluginAdapterFailedPlan {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Errors,

        [AllowNull()]
        [object]$Tool
    )

    return [pscustomobject][ordered]@{
        Status = 'failed'
        Message = "Plugin adapter validation failed: $($Errors -join '; ')"
        Errors = @($Errors)
        Tool = $Tool
        ApprovedSnapshot = Get-PluginAdapterSnapshot -Tool $Tool
        PluginSelector = $null
        MarketplaceName = $null
        MarketplaceCommand = $null
        PluginCommand = $null
        RemoveCommand = $null
        SensitiveRedactions = @()
    }
}

function Get-PluginInstallPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Tool
    )

    $snapshot = Get-PluginAdapterSnapshot -Tool $Tool
    $errors = New-Object System.Collections.Generic.List[string]
    if ($null -eq $snapshot) {
        [void]$errors.Add('ApprovedSnapshot is required for plugin command planning.')
        return New-PluginAdapterFailedPlan -Errors $errors.ToArray() -Tool $Tool
    }

    $id = Get-PluginAdapterString -InputObject $snapshot -Names @('id', 'Id')
    $type = Get-PluginAdapterString -InputObject $snapshot -Names @('type', 'Type')
    $name = Get-PluginAdapterString -InputObject $snapshot -Names @('name', 'Name')
    if ($null -eq $name) {
        $name = Get-PluginAdapterString -InputObject $Tool -Names @('name', 'Name')
    }
    $source = Get-PluginAdapterString -InputObject $snapshot -Names @('source', 'Source')
    $version = Get-PluginAdapterString -InputObject $snapshot -Names @('version', 'Version')
    $sha256 = Get-PluginAdapterString -InputObject $snapshot -Names @('sha256', 'Hash')
    $target = Get-PluginAdapterString -InputObject $snapshot `
        -Names @('install_target', 'InstallTarget', 'Target')
    $marketplace = Get-PluginAdapterString -InputObject $snapshot `
        -Names @('marketplace_name', 'MarketplaceName', 'marketplace')
    $selector = Get-PluginAdapterString -InputObject $snapshot `
        -Names @('plugin_id', 'PluginId', 'plugin_selector', 'PluginSelector')
    if ($null -eq $selector) {
        $selector = Get-PluginAdapterSelectorFromId -Id $id
    }

    foreach ($required in @(
            @{ Name = 'id'; Value = $id },
            @{ Name = 'type'; Value = $type },
            @{ Name = 'name'; Value = $name },
            @{ Name = 'source'; Value = $source },
            @{ Name = 'version'; Value = $version },
            @{ Name = 'sha256'; Value = $sha256 },
            @{ Name = 'install_target'; Value = $target },
            @{ Name = 'marketplace_name'; Value = $marketplace },
            @{ Name = 'plugin selector'; Value = $selector }
        )) {
        if ([string]::IsNullOrWhiteSpace($required.Value)) {
            [void]$errors.Add("Missing required whitelist field '$($required.Name)'.")
        }
    }

    if ($null -ne $selector -and -not (Test-PluginAdapterSafeName -Value $selector)) {
        [void]$errors.Add("Plugin selector must contain only safe characters.")
    }
    if ($null -ne $marketplace -and -not (Test-PluginAdapterSafeName -Value $marketplace)) {
        [void]$errors.Add("Marketplace name must contain only safe characters.")
    }
    if ($null -ne $type -and $type -ne 'plugin') {
        [void]$errors.Add("ApprovedSnapshot type must be 'plugin'.")
    }

    if ($errors.Count -gt 0) {
        return New-PluginAdapterFailedPlan -Errors $errors.ToArray() -Tool $Tool
    }

    $qualifiedSelector = "$selector@$marketplace"
    $marketplaceCommand = New-PluginAdapterCommand -FilePath 'codex' -Arguments @(
        'plugin',
        'marketplace',
        'add',
        $source,
        '--ref',
        $version,
        '--json'
    )
    $pluginCommand = New-PluginAdapterCommand -FilePath 'codex' -Arguments @(
        'plugin',
        'add',
        $qualifiedSelector,
        '--json'
    )
    $removeCommand = New-PluginAdapterCommand -FilePath 'codex' -Arguments @(
        'plugin',
        'remove',
        $qualifiedSelector
    )
    $redactions = @(
        (Get-PluginAdapterArray -Value (
            Get-PluginAdapterMember -InputObject $snapshot `
                -Names @('sensitive_redactions', 'SensitiveRedactions')
        )) +
        (Get-PluginAdapterArray -Value (
            Get-PluginAdapterMember -InputObject $Tool `
                -Names @('sensitive_redactions', 'SensitiveRedactions')
        )) |
            Where-Object { -not [string]::IsNullOrEmpty([string]$_) } |
            ForEach-Object { [string]$_ }
    )

    return [pscustomobject][ordered]@{
        Status = 'planned'
        Message = "Codex plugin '$qualifiedSelector' install is planned."
        Errors = @()
        Tool = $Tool
        ApprovedSnapshot = $snapshot
        Id = $id
        Name = $name
        Type = $type
        Source = $source
        Version = $version
        Sha256 = $sha256
        InstallTarget = $target
        PluginSelector = $selector
        MarketplaceName = $marketplace
        QualifiedSelector = $qualifiedSelector
        MarketplaceCommand = $marketplaceCommand
        PluginCommand = $pluginCommand
        RemoveCommand = $removeCommand
        SensitiveRedactions = @($redactions)
    }
}

function Protect-PluginAdapterText {
    param(
        [AllowNull()]
        [object]$Text,

        [AllowNull()]
        [string[]]$SensitiveValues = @()
    )

    $value = if ($null -eq $Text) { '' } else { "$Text" }
    if (Get-Command Protect-LogText -ErrorAction SilentlyContinue) {
        return Protect-LogText -Text $value -SensitiveValues $SensitiveValues
    }
    return $value
}

function Test-PluginProcessSucceeded {
    param([AllowNull()][object]$Result)

    if ($null -eq $Result) {
        return $false
    }
    $succeeded = Get-PluginAdapterMember -InputObject $Result -Names @('Succeeded')
    if ($null -ne $succeeded) {
        return [bool]$succeeded
    }
    $exitCode = Get-PluginAdapterMember -InputObject $Result -Names @('ExitCode')
    return ($null -ne $exitCode -and [int]$exitCode -eq 0)
}

function Get-PluginProcessText {
    param(
        [AllowNull()]
        [object]$Result,

        [AllowNull()]
        [string[]]$SensitiveValues = @()
    )

    $stderr = Get-PluginAdapterMember -InputObject $Result -Names @('StdErr', 'stderr')
    $stdout = Get-PluginAdapterMember -InputObject $Result -Names @('StdOut', 'stdout')
    $text = if (-not [string]::IsNullOrWhiteSpace("$stderr")) {
        "$stderr"
    }
    else {
        "$stdout"
    }
    return Protect-PluginAdapterText -Text $text -SensitiveValues $SensitiveValues
}

function Invoke-PluginAdapterExecutor {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Command,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Executor
    )

    $result = @(& $Executor $Command)
    if ($result.Count -eq 0) {
        return $null
    }
    return $result[-1]
}

function Add-PluginJournalIntent {
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
        Description = (
            "Codex plugin install may update managed Codex plugin " +
            "configuration or cache for '$($Plan.QualifiedSelector)'."
        )
        RollbackCommand = ''
        Plan = [pscustomobject][ordered]@{
            MarketplaceCommand = $Plan.MarketplaceCommand
            PluginCommand = $Plan.PluginCommand
        }
    }

    $callback = Get-PluginAdapterMember -InputObject $Journal `
        -Names @('AddExternalChange')
    if ($callback -is [scriptblock]) {
        & $callback $entry
        return
    }

    $journalPath = Get-PluginAdapterMember -InputObject $Journal -Names @('JournalPath')
    if ($null -ne $journalPath -and
        (Get-Command Add-ExternalChange -ErrorAction SilentlyContinue)) {
        [void](Add-ExternalChange -Journal $Journal `
                -Description $entry.Description `
                -RollbackCommand '')
    }
}

function New-PluginBlockedResult {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Plan,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    return New-OperationResult -Status 'blocked' -Message $Message `
        -Data ([pscustomobject][ordered]@{
            PlanOnly = $true
            QualifiedSelector = $Plan.QualifiedSelector
            MarketplaceCommand = $Plan.MarketplaceCommand
            PluginCommand = $Plan.PluginCommand
            RemoveCommand = $Plan.RemoveCommand
        })
}

function Install-ManagedPlugin {
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
            -Message (Protect-PluginAdapterText -Text $Plan.Message `
                -SensitiveValues $Plan.SensitiveRedactions) `
            -Data ([pscustomobject][ordered]@{
                PlanOnly = $true
                Errors = @($Plan.Errors)
            })
    }
    Add-PluginJournalIntent -Plan $Plan -Journal $Journal
    if ($null -eq $Executor) {
        return New-PluginBlockedResult -Plan $Plan `
            -Message 'Executor is required; plugin install is plan_only and no codex command was run.'
    }

    $marketplaceResult = Invoke-PluginAdapterExecutor `
        -Command $Plan.MarketplaceCommand `
        -Executor $Executor
    if (-not (Test-PluginProcessSucceeded -Result $marketplaceResult)) {
        return New-OperationResult -Status 'failed' `
            -Message (
                'Codex plugin marketplace add failed: ' +
                (Get-PluginProcessText -Result $marketplaceResult `
                    -SensitiveValues $Plan.SensitiveRedactions)
            ) `
            -Data ([pscustomobject][ordered]@{
                QualifiedSelector = $Plan.QualifiedSelector
                FailedStep = 'marketplace_add'
                Command = $Plan.MarketplaceCommand
                Result = $marketplaceResult
            })
    }

    $pluginResult = Invoke-PluginAdapterExecutor `
        -Command $Plan.PluginCommand `
        -Executor $Executor
    if (-not (Test-PluginProcessSucceeded -Result $pluginResult)) {
        return New-OperationResult -Status 'failed' `
            -Message (
                'Codex plugin add failed: ' +
                (Get-PluginProcessText -Result $pluginResult `
                    -SensitiveValues $Plan.SensitiveRedactions)
            ) `
            -Data ([pscustomobject][ordered]@{
                QualifiedSelector = $Plan.QualifiedSelector
                FailedStep = 'plugin_add'
                Command = $Plan.PluginCommand
                Result = $pluginResult
            })
    }

    return New-OperationResult -Status 'succeeded' `
        -Message "Codex plugin '$($Plan.QualifiedSelector)' install commands completed." `
        -Data ([pscustomobject][ordered]@{
            QualifiedSelector = $Plan.QualifiedSelector
            MarketplaceResult = $marketplaceResult
            PluginResult = $pluginResult
        })
}

function Uninstall-ManagedPlugin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Plan,

        [AllowNull()]
        [scriptblock]$Executor
    )

    if ($Plan.Status -ne 'planned') {
        return New-OperationResult -Status 'failed' `
            -Message (Protect-PluginAdapterText -Text $Plan.Message `
                -SensitiveValues $Plan.SensitiveRedactions) `
            -Data ([pscustomobject][ordered]@{ Errors = @($Plan.Errors) })
    }
    if ($null -eq $Executor) {
        return New-OperationResult -Status 'blocked' `
            -Message 'Executor is required; plugin uninstall is plan_only and no codex command was run.' `
            -Data ([pscustomobject][ordered]@{
                PlanOnly = $true
                QualifiedSelector = $Plan.QualifiedSelector
                RemoveCommand = $Plan.RemoveCommand
            })
    }

    $removeResult = Invoke-PluginAdapterExecutor `
        -Command $Plan.RemoveCommand `
        -Executor $Executor
    if (-not (Test-PluginProcessSucceeded -Result $removeResult)) {
        return New-OperationResult -Status 'failed' `
            -Message (
                'Codex plugin remove failed: ' +
                (Get-PluginProcessText -Result $removeResult `
                    -SensitiveValues $Plan.SensitiveRedactions)
            ) `
            -Data ([pscustomobject][ordered]@{
                QualifiedSelector = $Plan.QualifiedSelector
                Command = $Plan.RemoveCommand
                Result = $removeResult
            })
    }

    return New-OperationResult -Status 'succeeded' `
        -Message "Codex plugin '$($Plan.QualifiedSelector)' remove command completed." `
        -Data ([pscustomobject][ordered]@{
            QualifiedSelector = $Plan.QualifiedSelector
            Result = $removeResult
        })
}

function Test-PluginListContainsSelector {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Output,

        [Parameter(Mandatory = $true)]
        [string]$PluginSelector,

        [Parameter(Mandatory = $true)]
        [string]$MarketplaceName
    )

    $qualified = "$PluginSelector@$MarketplaceName"
    if ($Output -match [regex]::Escape($qualified)) {
        return $true
    }

    try {
        $items = @($Output | ConvertFrom-Json -ErrorAction Stop)
        foreach ($item in $items) {
            $selector = Get-PluginAdapterString -InputObject $item `
                -Names @('plugin', 'plugin_id', 'plugin_selector', 'name', 'id')
            $marketplace = Get-PluginAdapterString -InputObject $item `
                -Names @('marketplace', 'marketplace_name')
            if ($selector -eq $PluginSelector -and $marketplace -eq $MarketplaceName) {
                return $true
            }
            if ("$selector" -eq $qualified) {
                return $true
            }
        }
    }
    catch {
    }

    return $false
}

function New-PluginVerificationResult {
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
        Type = 'plugin'
        Version = $Plan.Version
        Source = $Plan.Source
        Level = 'load'
        Status = $Status
        Message = Protect-PluginAdapterText -Text $Message `
            -SensitiveValues $Plan.SensitiveRedactions
        Checks = @($Checks)
        ErrorCode = $ErrorCode
    }
}

function Test-ManagedPlugin {
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
        return New-PluginVerificationResult -Plan $Plan `
            -Status 'failed' `
            -Message $Plan.Message `
            -ErrorCode 'validation_failed'
    }
    if ($null -ne $Verifier) {
        return & $Verifier $Plan
    }
    if ($null -eq $Executor) {
        return New-PluginVerificationResult -Plan $Plan `
            -Status 'blocked' `
            -Message 'Executor or Verifier is required; plugin availability was not tested.' `
            -ErrorCode 'missing_executor'
    }

    $listCommand = New-PluginAdapterCommand -FilePath 'codex' `
        -Arguments @('plugin', 'list', '--json')
    $listResult = Invoke-PluginAdapterExecutor -Command $listCommand -Executor $Executor
    if (-not (Test-PluginProcessSucceeded -Result $listResult)) {
        return New-PluginVerificationResult -Plan $Plan `
            -Status 'failed' `
            -Message (
                'Codex plugin list failed: ' +
                (Get-PluginProcessText -Result $listResult `
                    -SensitiveValues $Plan.SensitiveRedactions)
            ) `
            -Checks @('codex plugin list --json') `
            -ErrorCode 'plugin_list_failed'
    }

    $stdout = Get-PluginAdapterMember -InputObject $listResult -Names @('StdOut', 'stdout')
    $found = Test-PluginListContainsSelector -Output "$stdout" `
        -PluginSelector $Plan.PluginSelector `
        -MarketplaceName $Plan.MarketplaceName
    if (-not $found) {
        return New-PluginVerificationResult -Plan $Plan `
            -Status 'failed' `
            -Message "Codex plugin '$($Plan.QualifiedSelector)' was not found in plugin list output." `
            -Checks @('codex plugin list --json') `
            -ErrorCode 'plugin_not_found'
    }

    return New-PluginVerificationResult -Plan $Plan `
        -Status 'load_verified' `
        -Message (
            "Codex plugin '$($Plan.QualifiedSelector)' was found in plugin list output; " +
            'no functional smoke capability was asserted.'
        ) `
        -Checks @("Found $($Plan.QualifiedSelector) in codex plugin list output.")
}
