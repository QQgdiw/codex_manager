$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pluginLibrary = Join-Path $projectRoot 'scripts\lib\adapters\PluginAdapter.ps1'

function New-TestPluginTool {
    param(
        [hashtable]$SnapshotOverrides = @{},
        [hashtable]$ToolOverrides = @{}
    )

    $snapshot = @{
        id = 'plugin.openai-browser'
        name = 'OpenAI Browser'
        type = 'plugin'
        source = 'https://github.com/openai/codex-plugins'
        version = 'v1.2.3'
        sha256 = ('a' * 64)
        install_target = 'codex-plugin'
        marketplace_name = 'openai-primary'
        plugin_id = 'openai-browser'
        sensitive_redactions = @('SECRET-TOKEN')
    }
    foreach ($key in $SnapshotOverrides.Keys) {
        if ($null -eq $SnapshotOverrides[$key]) {
            [void]$snapshot.Remove($key)
        }
        else {
            $snapshot[$key] = $SnapshotOverrides[$key]
        }
    }

    $tool = @{
        Id = 'plugin.openai-browser'
        Name = 'OpenAI Browser'
        Type = 'plugin'
        ApprovedSnapshot = [pscustomobject]$snapshot
    }
    foreach ($key in $ToolOverrides.Keys) {
        if ($null -eq $ToolOverrides[$key]) {
            [void]$tool.Remove($key)
        }
        else {
            $tool[$key] = $ToolOverrides[$key]
        }
    }

    return [pscustomobject]$tool
}

function New-SuccessProcessResult {
    param([string]$StdOut = '{}')

    return [pscustomobject]@{
        Succeeded = $true
        ExitCode = 0
        TimedOut = $false
        StdOut = $StdOut
        StdErr = ''
    }
}

function New-FailedProcessResult {
    param([string]$StdErr = 'failed')

    return [pscustomobject]@{
        Succeeded = $false
        ExitCode = 1
        TimedOut = $false
        StdOut = ''
        StdErr = $StdErr
    }
}

Describe 'Get-PluginInstallPlan' {
    BeforeAll {
        . $pluginLibrary
    }

    It 'builds marketplace and plugin commands with fixed ref and exact selector' {
        $plan = Get-PluginInstallPlan -Tool (New-TestPluginTool)

        $plan.Status | Should Be 'planned'
        $plan.PluginSelector | Should Be 'openai-browser'
        $plan.MarketplaceName | Should Be 'openai-primary'
        $plan.MarketplaceCommand.FilePath | Should Be 'codex'
        ($plan.MarketplaceCommand.Arguments -join '|') |
            Should Be 'plugin|marketplace|add|https://github.com/openai/codex-plugins|--ref|v1.2.3|--json'
        ($plan.PluginCommand.Arguments -join '|') |
            Should Be 'plugin|add|openai-browser@openai-primary|--json'
        $plan.MarketplaceCommand.Arguments.GetType().IsArray | Should Be $true
        $plan.PluginCommand.Arguments.GetType().IsArray | Should Be $true
    }

    It 'derives a safe selector from id when selector fields are absent' {
        $plan = Get-PluginInstallPlan -Tool (
            New-TestPluginTool -SnapshotOverrides @{
                plugin_id = $null
                plugin_selector = $null
            }
        )

        $plan.Status | Should Be 'planned'
        $plan.PluginSelector | Should Be 'openai-browser'
        ($plan.PluginCommand.Arguments -join '|') |
            Should Be 'plugin|add|openai-browser@openai-primary|--json'
    }

    It 'rejects unsafe selector characters instead of quoting them into commands' {
        $plan = Get-PluginInstallPlan -Tool (
            New-TestPluginTool -SnapshotOverrides @{
                plugin_selector = 'openai-browser;Remove-Item'
                plugin_id = $null
            }
        )

        $plan.Status | Should Be 'failed'
        $plan.Message | Should Match 'validation|selector|safe'
        $plan.PluginCommand | Should Be $null
    }

    It 'fails validation when whitelist snapshot fields are incomplete' {
        $plan = Get-PluginInstallPlan -Tool (
            New-TestPluginTool -SnapshotOverrides @{ sha256 = $null }
        )

        $plan.Status | Should Be 'failed'
        $plan.Message | Should Match 'validation'
        ($plan.Errors -join '|') | Should Match 'sha256'
    }

    It 'does not use top-level marketplace_name when the approved snapshot omits it' {
        $plan = Get-PluginInstallPlan -Tool (
            New-TestPluginTool `
                -SnapshotOverrides @{ marketplace_name = $null } `
                -ToolOverrides @{ marketplace_name = 'openai-primary' }
        )

        $plan.Status | Should Be 'failed'
        ($plan.Errors -join '|') | Should Match 'marketplace_name'
        $plan.MarketplaceCommand | Should Be $null
        $plan.PluginCommand | Should Be $null
    }

    It 'does not use top-level name when the approved snapshot omits it' {
        $plan = Get-PluginInstallPlan -Tool (
            New-TestPluginTool `
                -SnapshotOverrides @{ name = $null } `
                -ToolOverrides @{ Name = 'Top Level Name' }
        )

        $plan.Status | Should Be 'failed'
        ($plan.Errors -join '|') | Should Match 'name'
        $plan.MarketplaceCommand | Should Be $null
        $plan.PluginCommand | Should Be $null
    }

    It 'derives missing selector only from approved snapshot id despite a top-level selector' {
        $plan = Get-PluginInstallPlan -Tool (
            New-TestPluginTool `
                -SnapshotOverrides @{
                    id = 'plugin.snapshot-selector'
                    plugin_id = $null
                    plugin_selector = $null
                } `
                -ToolOverrides @{ plugin_selector = 'top-level-selector' }
        )

        $plan.Status | Should Be 'planned'
        $plan.PluginSelector | Should Be 'snapshot-selector'
        ($plan.PluginCommand.Arguments -join '|') |
            Should Be 'plugin|add|snapshot-selector@openai-primary|--json'
    }

    It 'fails validation when the approved snapshot is missing even if top-level fields are complete' {
        $plan = Get-PluginInstallPlan -Tool (
            New-TestPluginTool -ToolOverrides @{
                ApprovedSnapshot = $null
                id = 'plugin.top-level'
                name = 'Top Level Plugin'
                source = 'https://github.com/openai/codex-plugins'
                version = 'v1.2.3'
                sha256 = ('b' * 64)
                install_target = 'codex-plugin'
                marketplace_name = 'openai-primary'
                plugin_selector = 'top-level'
            }
        )

        $plan.Status | Should Be 'failed'
        $plan.Message | Should Match 'ApprovedSnapshot|approved snapshot'
        $plan.MarketplaceCommand | Should Be $null
        $plan.PluginCommand | Should Be $null
    }
}

Describe 'Install-ManagedPlugin' {
    BeforeAll {
        . $pluginLibrary
    }

    It 'returns blocked plan_only when no executor is provided' {
        $result = Install-ManagedPlugin -Plan (
            Get-PluginInstallPlan -Tool (New-TestPluginTool)
        )

        $result.Status | Should Be 'blocked'
        $result.Data.PlanOnly | Should Be $true
        $result.Message | Should Match 'Executor'
    }

    It 'runs marketplace add before plugin add' {
        $script:calls = @()
        $plan = Get-PluginInstallPlan -Tool (New-TestPluginTool)

        $result = Install-ManagedPlugin -Plan $plan -Executor {
            param($Command)
            $script:calls += ,$Command
            New-SuccessProcessResult
        }

        $result.Status | Should Be 'succeeded'
        $script:calls.Count | Should Be 2
        ($script:calls[0].Arguments -join '|') |
            Should Be 'plugin|marketplace|add|https://github.com/openai/codex-plugins|--ref|v1.2.3|--json'
        ($script:calls[1].Arguments -join '|') |
            Should Be 'plugin|add|openai-browser@openai-primary|--json'
    }

    It 'short-circuits plugin add when marketplace add fails' {
        $script:calls = @()
        $plan = Get-PluginInstallPlan -Tool (New-TestPluginTool)

        $result = Install-ManagedPlugin -Plan $plan -Executor {
            param($Command)
            $script:calls += ,$Command
            New-FailedProcessResult -StdErr 'marketplace failed'
        }

        $result.Status | Should Be 'failed'
        $script:calls.Count | Should Be 1
        $result.Message | Should Match 'marketplace failed'
    }

    It 'records journal external change intent without executable rollback shell' {
        $script:journalEntries = @()
        $journal = [pscustomobject]@{
            AddExternalChange = {
                param($Entry)
                $script:journalEntries += ,$Entry
            }
        }
        $plan = Get-PluginInstallPlan -Tool (New-TestPluginTool)

        $result = Install-ManagedPlugin -Plan $plan -Journal $journal -Executor {
            param($Command)
            New-SuccessProcessResult
        }

        $result.Status | Should Be 'succeeded'
        $script:journalEntries.Count | Should Be 1
        $script:journalEntries[0].Type | Should Be 'ExternalChange'
        $script:journalEntries[0].RollbackCommand | Should Be ''
        $script:journalEntries[0].Description | Should Match 'openai-browser@openai-primary'
    }

    It 'redacts sensitive stderr values in failed results' {
        $plan = Get-PluginInstallPlan -Tool (New-TestPluginTool)

        $result = Install-ManagedPlugin -Plan $plan -Executor {
            param($Command)
            New-FailedProcessResult -StdErr 'bad SECRET-TOKEN'
        }

        $result.Status | Should Be 'failed'
        $result.Message | Should Match '\[REDACTED\]'
        $result.Message | Should Not Match 'SECRET-TOKEN'
        $json = $result.Data | ConvertTo-Json -Depth 8 -Compress
        $result.Data.PSObject.Properties.Name | Should Not Contain 'Result'
        $json | Should Not Match 'SECRET-TOKEN'
    }

    It 'stores only redacted executor summaries in result data' {
        $plan = Get-PluginInstallPlan -Tool (New-TestPluginTool)

        $result = Install-ManagedPlugin -Plan $plan -Executor {
            param($Command)
            New-SuccessProcessResult `
                -StdOut 'installed SECRET-TOKEN auth.json {"token":"RAW-AUTH-TOKEN"}'
        }

        $json = $result.Data | ConvertTo-Json -Depth 8 -Compress
        $result.Status | Should Be 'succeeded'
        $result.Data.PSObject.Properties.Name | Should Not Contain 'MarketplaceResult'
        $result.Data.PSObject.Properties.Name | Should Not Contain 'PluginResult'
        $json | Should Match 'Steps'
        $json | Should Not Match 'SECRET-TOKEN'
        $json | Should Not Match 'RAW-AUTH-TOKEN'
        $json | Should Not Match 'auth\.json'
    }

    It 'returns a redacted failed result when the executor throws' {
        $plan = Get-PluginInstallPlan -Tool (New-TestPluginTool)

        $result = Install-ManagedPlugin -Plan $plan -Executor {
            param($Command)
            throw 'executor failed SECRET-TOKEN auth.json token=RAW-AUTH-TOKEN'
        }

        $json = $result.Data | ConvertTo-Json -Depth 8 -Compress
        $result.Status | Should Be 'failed'
        $result.Message | Should Match 'executor'
        $result.Message | Should Match '\[REDACTED\]'
        $result.Message | Should Not Match 'SECRET-TOKEN'
        $result.Message | Should Not Match 'RAW-AUTH-TOKEN'
        $json | Should Not Match 'SECRET-TOKEN'
        $json | Should Not Match 'RAW-AUTH-TOKEN'
        $json | Should Not Match 'auth\.json'
        $result.Data.FailedStep | Should Be 'marketplace_add'
    }
}

Describe 'Uninstall-ManagedPlugin' {
    BeforeAll {
        . $pluginLibrary
    }

    It 'generates and executes plugin remove command' {
        $script:calls = @()
        $plan = Get-PluginInstallPlan -Tool (New-TestPluginTool)

        $result = Uninstall-ManagedPlugin -Plan $plan -Executor {
            param($Command)
            $script:calls += ,$Command
            New-SuccessProcessResult
        }

        $result.Status | Should Be 'succeeded'
        $script:calls.Count | Should Be 1
        $script:calls[0].FilePath | Should Be 'codex'
        ($script:calls[0].Arguments -join '|') |
            Should Be 'plugin|remove|openai-browser@openai-primary'
    }
}

Describe 'Test-ManagedPlugin' {
    BeforeAll {
        . $pluginLibrary
    }

    It 'returns blocked when no executor or verifier is provided' {
        $result = Test-ManagedPlugin -Plan (
            Get-PluginInstallPlan -Tool (New-TestPluginTool)
        )

        $result.Status | Should Be 'blocked'
        $result.Message | Should Match 'Executor|Verifier'
    }

    It 'finds selector in JSON plugin list output' {
        $plan = Get-PluginInstallPlan -Tool (New-TestPluginTool)
        $json = @(
            [pscustomobject]@{
                plugin = 'openai-browser'
                marketplace = 'openai-primary'
            }
        ) | ConvertTo-Json -Compress

        $result = Test-ManagedPlugin -Plan $plan -Executor {
            param($Command)
            ($Command.Arguments -join '|') |
                Should Be 'plugin|list|--json'
            New-SuccessProcessResult -StdOut $json
        }

        $result.Status | Should Be 'load_verified'
        $result.Checks[0] | Should Match 'openai-browser@openai-primary'
    }

    It 'fails when plugin list output does not contain selector' {
        $plan = Get-PluginInstallPlan -Tool (New-TestPluginTool)

        $result = Test-ManagedPlugin -Plan $plan -Executor {
            param($Command)
            New-SuccessProcessResult -StdOut 'other-plugin@openai-primary'
        }

        $result.Status | Should Be 'failed'
        $result.Message | Should Match 'not found'
    }

    It 'reports malformed JSON separately from a missing selector' {
        $plan = Get-PluginInstallPlan -Tool (New-TestPluginTool)

        $result = Test-ManagedPlugin -Plan $plan -Executor {
            param($Command)
            New-SuccessProcessResult -StdOut '{ "plugin": "openai-browser", '
        }

        $result.Status | Should Be 'failed'
        $result.ErrorCode | Should Be 'plugin_list_parse_failed'
        $result.Message | Should Match 'parse|JSON'
        $result.Message | Should Not Match 'not found'
    }

    It 'finds selector in plain text only on exact token boundaries' {
        $plan = Get-PluginInstallPlan -Tool (New-TestPluginTool)

        $result = Test-ManagedPlugin -Plan $plan -Executor {
            param($Command)
            New-SuccessProcessResult -StdOut "installed plugins:`nopenai-browser@openai-primary`n"
        }

        $result.Status | Should Be 'load_verified'
    }

    It 'does not match selector as a substring of another plain text token' {
        $plan = Get-PluginInstallPlan -Tool (New-TestPluginTool)

        $result = Test-ManagedPlugin -Plan $plan -Executor {
            param($Command)
            New-SuccessProcessResult -StdOut 'selector-old=openai-browser@openai-primary-old'
        }

        $result.Status | Should Be 'failed'
        $result.ErrorCode | Should Be 'plugin_not_found'
    }
}
