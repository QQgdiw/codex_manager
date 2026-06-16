$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$mcpLibrary = Join-Path $projectRoot 'scripts\lib\adapters\McpAdapter.ps1'

function New-TestMcpTool {
    param(
        [hashtable]$SnapshotOverrides = @{},
        [hashtable]$ToolOverrides = @{}
    )

    # Task 9 MCP ApprovedSnapshot extension fields:
    # type='mcp'; mcp_transport='stdio'|'http'; mcp_name is the Codex MCP name.
    # stdio contains command, args[], working_directory, startup_file, and env key/value pairs.
    # http contains url and optional bearer_token_env_var. Token values are never accepted.
    $snapshot = @{
        id = 'mcp.local-docs'
        name = 'Local Docs MCP'
        type = 'mcp'
        source = 'local'
        version = '1.0.0'
        sha256 = ('b' * 64)
        mcp_transport = 'stdio'
        mcp_name = 'local-docs'
        stdio = @{
            command = 'node'
            args = @('dist/index.js')
            working_directory = $TestDrive
            startup_file = 'dist/index.js'
            env = @{
                LOG_LEVEL = 'info'
            }
        }
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
        Id = 'mcp.local-docs'
        Name = 'Local Docs MCP'
        Type = 'mcp'
        command = 'unsafe-top-level-command'
        url = 'https://unsafe.example.invalid'
        bearer_token = 'SECRET-TOKEN'
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
    param(
        [string]$StdErr = 'failed',
        [bool]$TimedOut = $false
    )

    return [pscustomobject]@{
        Succeeded = $false
        ExitCode = 1
        TimedOut = $TimedOut
        StdOut = ''
        StdErr = $StdErr
    }
}

function New-TestStartupFile {
    $dist = Join-Path $TestDrive 'dist'
    New-Item -ItemType Directory -Path $dist -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dist 'index.js') -Value 'process.exit(0)' -Encoding ASCII
}

Describe 'Get-McpInstallPlan' {
    BeforeAll {
        . $mcpLibrary
    }

    It 'builds a stdio add command from the approved snapshot only' {
        New-TestStartupFile

        $plan = Get-McpInstallPlan -Tool (
            New-TestMcpTool -ToolOverrides @{
                ApprovedSnapshot = [pscustomobject]@{
                    id = 'mcp.safe'
                    name = 'Safe MCP'
                    type = 'mcp'
                    source = 'local'
                    version = '1.0.0'
                    sha256 = ('c' * 64)
                    mcp_transport = 'stdio'
                    mcp_name = 'safe-docs'
                    stdio = @{
                        command = 'node'
                        args = @('dist/index.js')
                        working_directory = $TestDrive
                        startup_file = 'dist/index.js'
                    }
                }
                mcp_name = 'unsafe-top-level'
            }
        )

        $plan.Status | Should Be 'planned'
        $plan.McpName | Should Be 'safe-docs'
        $plan.AddCommand.FilePath | Should Be 'codex'
        ($plan.AddCommand.Arguments -join '|') |
            Should Be 'mcp|add|safe-docs|--|node|dist/index.js'
        ($plan.AddCommand.Arguments -contains 'unsafe-top-level-command') | Should Be $false
        $plan.StartupFileExists | Should Be $true
    }

    It 'builds an HTTP add command with bearer token env var name only' {
        $tool = New-TestMcpTool -SnapshotOverrides @{
            mcp_transport = 'http'
            mcp_name = 'remote-docs'
            stdio = $null
            http = @{
                url = 'https://mcp.example.test/sse'
                bearer_token_env_var = 'MCP_REMOTE_TOKEN'
            }
        }

        $plan = Get-McpInstallPlan -Tool $tool
        $json = $plan | ConvertTo-Json -Depth 8 -Compress

        $plan.Status | Should Be 'planned'
        ($plan.AddCommand.Arguments -join '|') |
            Should Be 'mcp|add|remote-docs|--url|https://mcp.example.test/sse|--bearer-token-env-var|MCP_REMOTE_TOKEN'
        $json | Should Match 'MCP_REMOTE_TOKEN'
        $json | Should Not Match 'SECRET-TOKEN'
        (@($plan.SensitiveRedactions) -join '|') | Should Not Match 'SECRET-TOKEN'
    }

    It 'rejects unsafe bearer token environment variable names' {
        $plan = Get-McpInstallPlan -Tool (
            New-TestMcpTool -SnapshotOverrides @{
                mcp_transport = 'http'
                stdio = $null
                http = @{
                    url = 'https://mcp.example.test/sse'
                    bearer_token_env_var = 'BAD-NAME'
                }
            }
        )

        $plan.Status | Should Be 'failed'
        $plan.Message | Should Match 'bearer token'
    }

    It 'rejects stdio env name references because codex requires key value pairs' {
        New-TestStartupFile

        $plan = Get-McpInstallPlan -Tool (
            New-TestMcpTool -SnapshotOverrides @{
                stdio = @{
                    command = 'node'
                    args = @('dist/index.js')
                    working_directory = $TestDrive
                    startup_file = 'dist/index.js'
                    env_names = @('SAFE_FLAG')
                }
            }
        )

        $plan.Status | Should Be 'failed'
        $plan.Message | Should Match 'stdio.env_names'
    }

    It 'fails precheck when the stdio startup file is missing' {
        $plan = Get-McpInstallPlan -Tool (
            New-TestMcpTool -SnapshotOverrides @{
                stdio = @{
                    command = 'node'
                    args = @('dist/index.js')
                    working_directory = (Join-Path $TestDrive 'missing-root')
                    startup_file = 'dist/index.js'
                }
            }
        )

        $plan.Status | Should Be 'failed'
        $plan.Message | Should Match 'startup file'
        $plan.AddCommand | Should Be $null
    }

    It 'does not use top-level fields when the approved snapshot omits MCP fields' {
        $plan = Get-McpInstallPlan -Tool (
            New-TestMcpTool -SnapshotOverrides @{
                mcp_name = $null
                stdio = $null
            }
        )

        $plan.Status | Should Be 'failed'
        $plan.Message | Should Match 'mcp_name'
    }
}

Describe 'Install-ManagedMcp' {
    BeforeAll {
        . $mcpLibrary
    }

    It 'returns blocked plan_only when no executor is provided' {
        New-TestStartupFile
        $plan = Get-McpInstallPlan -Tool (New-TestMcpTool)

        $result = Install-ManagedMcp -Plan $plan

        $result.Status | Should Be 'blocked'
        $result.Data.PlanOnly | Should Be $true
        $result.Message | Should Match 'Executor'
    }

    It 'runs the MCP add command and records journal intent without rollback shell' {
        New-TestStartupFile
        $script:calls = @()
        $script:journalEntries = @()
        $journal = [pscustomobject]@{
            AddExternalChange = {
                param($Entry)
                $script:journalEntries += ,$Entry
            }
        }
        $plan = Get-McpInstallPlan -Tool (New-TestMcpTool)

        $result = Install-ManagedMcp -Plan $plan -Journal $journal -Executor {
            param($Command)
            $script:calls += ,$Command
            New-SuccessProcessResult -StdOut 'registered SECRET-TOKEN auth.json'
        }

        $result.Status | Should Be 'succeeded'
        $script:calls.Count | Should Be 1
        ($script:calls[0].Arguments -join '|') |
            Should Be 'mcp|add|local-docs|--env|LOG_LEVEL=info|--|node|dist/index.js'
        $script:journalEntries.Count | Should Be 1
        $script:journalEntries[0].Type | Should Be 'ExternalChange'
        $script:journalEntries[0].RollbackCommand | Should Be ''
        ($result.Data | ConvertTo-Json -Depth 8 -Compress) | Should Not Match 'SECRET-TOKEN|auth\.json'
    }

    It 'does not call executor when startup precheck failed' {
        $script:calls = 0
        $plan = Get-McpInstallPlan -Tool (
            New-TestMcpTool -SnapshotOverrides @{
                stdio = @{
                    command = 'node'
                    args = @('dist/index.js')
                    working_directory = (Join-Path $TestDrive 'missing-install-root')
                    startup_file = 'dist/index.js'
                }
            }
        )

        $result = Install-ManagedMcp -Plan $plan -Executor {
            param($Command)
            $script:calls++
            New-SuccessProcessResult
        }

        $result.Status | Should Be 'failed'
        $script:calls | Should Be 0
    }

    It 'reports startup timeout as a failed summarized result' {
        New-TestStartupFile
        $plan = Get-McpInstallPlan -Tool (New-TestMcpTool)

        $result = Install-ManagedMcp -Plan $plan -Executor {
            param($Command)
            New-FailedProcessResult -StdErr 'startup timed out SECRET-TOKEN' -TimedOut $true
        }

        $result.Status | Should Be 'failed'
        $result.Message | Should Match 'timed out|timeout'
        $result.Message | Should Not Match 'SECRET-TOKEN'
        $result.Data.ResultSummary.TimedOut | Should Be $true
    }

    It 'catches executor exceptions and stores only redacted summaries' {
        New-TestStartupFile
        $plan = Get-McpInstallPlan -Tool (New-TestMcpTool)

        $result = Install-ManagedMcp -Plan $plan -Executor {
            param($Command)
            throw 'executor failed SECRET-TOKEN bearer token=RAW-AUTH-TOKEN'
        }
        $json = $result.Data | ConvertTo-Json -Depth 8 -Compress

        $result.Status | Should Be 'failed'
        $result.Message | Should Not Match 'SECRET-TOKEN|RAW-AUTH-TOKEN'
        $json | Should Not Match 'SECRET-TOKEN|RAW-AUTH-TOKEN'
        ($result.Data.PSObject.Properties.Name -join '|') | Should Not Match '(^|\|)Result($|\|)'
    }
}

Describe 'Uninstall-ManagedMcp' {
    BeforeAll {
        . $mcpLibrary
    }

    It 'runs codex mcp remove for the approved MCP name' {
        New-TestStartupFile
        $script:calls = @()
        $plan = Get-McpInstallPlan -Tool (New-TestMcpTool)

        $result = Uninstall-ManagedMcp -Plan $plan -Executor {
            param($Command)
            $script:calls += ,$Command
            New-SuccessProcessResult
        }

        $result.Status | Should Be 'succeeded'
        $script:calls.Count | Should Be 1
        ($script:calls[0].Arguments -join '|') | Should Be 'mcp|remove|local-docs'
    }
}

Describe 'Test-ManagedMcp' {
    BeforeAll {
        . $mcpLibrary
    }

    It 'uses codex mcp get name --json to verify the MCP exists' {
        New-TestStartupFile
        $plan = Get-McpInstallPlan -Tool (New-TestMcpTool)

        $result = Test-ManagedMcp -Plan $plan -Executor {
            param($Command)
            ($Command.Arguments -join '|') | Should Be 'mcp|get|local-docs|--json'
            New-SuccessProcessResult -StdOut '{"name":"local-docs","transport":"stdio"}'
        }

        $result.Status | Should Be 'load_verified'
        $result.Checks[0] | Should Match 'local-docs'
    }

    It 'reports malformed JSON separately from missing configuration' {
        New-TestStartupFile
        $plan = Get-McpInstallPlan -Tool (New-TestMcpTool)

        $result = Test-ManagedMcp -Plan $plan -Executor {
            param($Command)
            New-SuccessProcessResult -StdOut '{"name":"local-docs",'
        }

        $result.Status | Should Be 'failed'
        $result.ErrorCode | Should Be 'mcp_get_parse_failed'
        $result.Message | Should Match 'JSON|parse'
    }

    It 'reports command failure as MCP get failed' {
        New-TestStartupFile
        $plan = Get-McpInstallPlan -Tool (New-TestMcpTool)

        $result = Test-ManagedMcp -Plan $plan -Executor {
            param($Command)
            New-FailedProcessResult -StdErr 'not found'
        }

        $result.Status | Should Be 'failed'
        $result.ErrorCode | Should Be 'mcp_get_failed'
    }

    It 'reports JSON for a different MCP as not found' {
        New-TestStartupFile
        $plan = Get-McpInstallPlan -Tool (New-TestMcpTool)

        $result = Test-ManagedMcp -Plan $plan -Executor {
            param($Command)
            New-SuccessProcessResult -StdOut '{"name":"other-docs"}'
        }

        $result.Status | Should Be 'failed'
        $result.ErrorCode | Should Be 'mcp_not_found'
        $result.Message | Should Match 'not found'
    }
}
