$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$mcpLibrary = Join-Path $projectRoot 'scripts\lib\adapters\McpAdapter.ps1'

function New-TestMcpTool {
    param(
        [hashtable]$SnapshotOverrides = @{},
        [hashtable]$ToolOverrides = @{}
    )

    # Task 9 MCP ApprovedSnapshot extension fields:
    # type='mcp'; mcp_transport='stdio'|'http'; mcp_name is the Codex MCP name.
    # stdio contains command, args[], working_directory, and startup_file.
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
        }
        smoke = [pscustomobject]@{
            tool_name = 'local-docs'
            timeout_seconds = 10
            expected_content_types = @('text')
            script_path = 'scripts/smoke/mcp/local-docs.mjs'
            script_sha256 = ('0' * 64)
            arguments = [pscustomobject]@{}
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

function New-TestSmokeRuntime {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Project,

        [string]$WorkingDirectory = $TestDrive,

        [string]$ScriptRelativePath = 'scripts/smoke/mcp/test.mjs'
    )

    $scriptPath = Join-Path $Project $ScriptRelativePath
    New-Item -ItemType Directory -Path (Split-Path $scriptPath) -Force | Out-Null
    Set-Content -LiteralPath $scriptPath -Encoding UTF8 -Value 'process.exit(0);'
    $runnerPath = Join-Path $Project 'scripts\node\mcp-smoke-runner.mjs'
    New-Item -ItemType Directory -Path (Split-Path $runnerPath) -Force | Out-Null
    Set-Content -LiteralPath $runnerPath -Encoding UTF8 -Value 'process.exit(0);'
    $sdk = Join-Path $WorkingDirectory 'node_modules\@modelcontextprotocol\sdk\dist\esm\client'
    New-Item -ItemType Directory -Path $sdk -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $sdk 'index.js') -Encoding UTF8 -Value 'export {};'
    Set-Content -LiteralPath (Join-Path $sdk 'stdio.js') -Encoding UTF8 -Value 'export {};'

    return [pscustomobject]@{
        ScriptPath = [IO.Path]::GetFullPath($scriptPath)
        ScriptSha256 = (Get-FileHash $scriptPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
}

function Assert-McpPlanDoesNotLeak {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Plan,

        [Parameter(Mandatory = $true)]
        [string[]]$Secrets
    )

    $json = $Plan | ConvertTo-Json -Depth 8 -Compress
    foreach ($secret in $Secrets) {
        $Plan.Message | Should Not Match ([regex]::Escape($secret))
        (@($Plan.Errors) -join '|') | Should Not Match ([regex]::Escape($secret))
        $json | Should Not Match ([regex]::Escape($secret))
    }
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
        @($plan.AddCommand.Arguments)[-1] |
            Should Be ([IO.Path]::GetFullPath((Join-Path $TestDrive 'dist\index.js')))
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

    It 'rejects HTTP URLs with query, fragment, or userinfo without leaking secret text' {
        $unsafeUrls = @(
            'https://mcp.example.test/sse?token=RAW-QUERY-TOKEN',
            'https://mcp.example.test/sse#RAW-FRAGMENT-TOKEN',
            'https://user:RAW-USERINFO-TOKEN@mcp.example.test/sse'
        )
        foreach ($unsafeUrl in $unsafeUrls) {
            $plan = Get-McpInstallPlan -Tool (
                New-TestMcpTool -SnapshotOverrides @{
                    mcp_transport = 'http'
                    mcp_name = 'remote-docs'
                    stdio = $null
                    http = @{
                        url = $unsafeUrl
                    }
                }
            )

            $plan.Status | Should Be 'failed'
            $plan.AddCommand | Should Be $null
            $plan.Message | Should Match 'http.url'
            Assert-McpPlanDoesNotLeak -Plan $plan -Secrets @(
                'RAW-QUERY-TOKEN',
                'RAW-FRAGMENT-TOKEN',
                'RAW-USERINFO-TOKEN',
                $unsafeUrl
            )
        }
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

    It 'rejects stdio env values without leaking the value' {
        New-TestStartupFile
        $envValue = 'RAW-STDIO-ENV-SECRET'

        $plan = Get-McpInstallPlan -Tool (
            New-TestMcpTool -SnapshotOverrides @{
                stdio = @{
                    command = 'node'
                    args = @('dist/index.js')
                    working_directory = $TestDrive
                    startup_file = 'dist/index.js'
                    env = @{
                        PUBLIC_CONFIG = $envValue
                    }
                }
            }
        )

        $plan.Status | Should Be 'failed'
        $plan.AddCommand | Should Be $null
        $plan.Message | Should Match 'stdio.env'
        Assert-McpPlanDoesNotLeak -Plan $plan -Secrets @($envValue)
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

    It 'does not leak sensitive missing startup file paths in failed plans' {
        $rawStartupPath = 'auth.json\token-secret-server.js'
        $plan = Get-McpInstallPlan -Tool (
            New-TestMcpTool -SnapshotOverrides @{
                stdio = @{
                    command = 'node'
                    args = @('dist/index.js')
                    working_directory = $TestDrive
                    startup_file = $rawStartupPath
                }
            }
        )

        $plan.Status | Should Be 'failed'
        $plan.Message | Should Match 'startup file'
        $plan.AddCommand | Should Be $null
        Assert-McpPlanDoesNotLeak -Plan $plan -Secrets @(
            $rawStartupPath,
            'auth.json',
            'token-secret-server.js'
        )
    }

    It 'rejects absolute stdio startup files even when they exist' {
        $workRoot = Join-Path $TestDrive 'work'
        $outsideRoot = Join-Path $TestDrive 'outside'
        New-Item -ItemType Directory -Path $workRoot, $outsideRoot -Force | Out-Null
        $absoluteStartupFile = Join-Path $outsideRoot 'server.js'
        Set-Content -LiteralPath $absoluteStartupFile -Value 'process.exit(0)' -Encoding ASCII

        $plan = Get-McpInstallPlan -Tool (
            New-TestMcpTool -SnapshotOverrides @{
                stdio = @{
                    command = 'node'
                    args = @('dist/index.js')
                    working_directory = $workRoot
                    startup_file = $absoluteStartupFile
                }
            }
        )

        $plan.Status | Should Be 'failed'
        $plan.AddCommand | Should Be $null
        $plan.Message | Should Match 'startup_file'
    }

    It 'rejects stdio startup files that escape the working directory' {
        $workRoot = Join-Path $TestDrive 'work'
        $outsideRoot = Join-Path $TestDrive 'secrets'
        New-Item -ItemType Directory -Path $workRoot, $outsideRoot -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $outsideRoot 'server.js') `
            -Value 'process.exit(0)' `
            -Encoding ASCII

        $plan = Get-McpInstallPlan -Tool (
            New-TestMcpTool -SnapshotOverrides @{
                stdio = @{
                    command = 'node'
                    args = @('dist/index.js')
                    working_directory = $workRoot
                    startup_file = '..\secrets\server.js'
                }
            }
        )

        $plan.Status | Should Be 'failed'
        $plan.AddCommand | Should Be $null
        $plan.Message | Should Match 'working_directory'
    }

    It 'rejects stdio startup files whose path contains a reparse point' {
        $workRoot = Join-Path $TestDrive 'work-with-junction'
        $outsideRoot = Join-Path $TestDrive 'outside-startup'
        New-Item -ItemType Directory -Path $workRoot, $outsideRoot -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $outsideRoot 'index.js') -Value 'process.exit(0)' -Encoding ASCII
        New-Item -ItemType Junction -Path (Join-Path $workRoot 'dist') -Target $outsideRoot | Out-Null

        $plan = Get-McpInstallPlan -Tool (
            New-TestMcpTool -SnapshotOverrides @{
                stdio = @{
                    command = 'node'
                    args = @('dist/index.js')
                    working_directory = $workRoot
                    startup_file = 'dist/index.js'
                }
            }
        )

        $plan.Status | Should Be 'failed'
        $plan.StartupFileExists | Should Be $false
        $plan.AddCommand | Should Be $null
        $plan.Message | Should Match 'reparse|startup_file|working_directory'
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
        @($script:calls[0].Arguments)[-1] |
            Should Be ([IO.Path]::GetFullPath((Join-Path $TestDrive 'dist\index.js')))
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

Describe 'Get-McpSmokePlan' {
    BeforeAll {
        . $mcpLibrary
    }

    It 'resolves an approved lifecycle script below scripts smoke mcp' {
        $project = Join-Path $TestDrive 'project'
        $scriptDir = Join-Path $project 'scripts\smoke\mcp'
        New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
        $scriptPath = Join-Path $scriptDir 'test.mjs'
        Set-Content -LiteralPath $scriptPath -Encoding UTF8 -Value 'process.exit(0);'
        $runnerPath = Join-Path $project 'scripts\node\mcp-smoke-runner.mjs'
        New-Item -ItemType Directory -Path (Split-Path $runnerPath) -Force | Out-Null
        Set-Content -LiteralPath $runnerPath -Encoding UTF8 -Value 'process.exit(0);'
        $sdk = Join-Path $TestDrive 'node_modules\@modelcontextprotocol\sdk\dist\esm\client'
        New-Item -ItemType Directory -Path $sdk -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $sdk 'index.js') -Encoding UTF8 -Value 'export {};'
        Set-Content -LiteralPath (Join-Path $sdk 'stdio.js') -Encoding UTF8 -Value 'export {};'
        $hash = (Get-FileHash $scriptPath -Algorithm SHA256).Hash.ToLowerInvariant()
        New-TestStartupFile
        $install = Get-McpInstallPlan -Tool (New-TestMcpTool -SnapshotOverrides @{
            smoke = [pscustomobject]@{
                tool_name = 'local_tool'; timeout_seconds = 10
                expected_content_types = @('text')
                script_path = 'scripts/smoke/mcp/test.mjs'
                script_sha256 = $hash
                arguments = [pscustomobject]@{ value = 1 }
            }
        })

        $plan = Get-McpSmokePlan -InstallPlan $install -ProjectRoot $project

        $plan.Status | Should Be 'planned'
        $plan.ScriptPath | Should Be ([IO.Path]::GetFullPath($scriptPath))
        $plan.ToolName | Should Be 'local_tool'
    }

    It 'rejects a lifecycle script path that escapes the approved directory' {
        $project = Join-Path $TestDrive 'escape-project'
        $outside = Join-Path $project 'scripts\smoke\outside.mjs'
        New-Item -ItemType Directory -Path (Split-Path $outside) -Force | Out-Null
        Set-Content -LiteralPath $outside -Encoding UTF8 -Value 'process.exit(0);'
        New-TestStartupFile
        $install = Get-McpInstallPlan -Tool (New-TestMcpTool -SnapshotOverrides @{
            smoke = [pscustomobject]@{
                tool_name = 'local_tool'; timeout_seconds = 10
                expected_content_types = @('text')
                script_path = 'scripts/smoke/mcp/../outside.mjs'
                script_sha256 = (Get-FileHash $outside).Hash.ToLowerInvariant()
                arguments = [pscustomobject]@{}
            }
        })

        $plan = Get-McpSmokePlan -InstallPlan $install -ProjectRoot $project

        $plan.Status | Should Be 'failed'
        $plan.ErrorCode | Should Be 'mcp_smoke_script_path_rejected'
    }

    It 'rejects a lifecycle path containing a reparse point' {
        $project = Join-Path $TestDrive 'reparse-project'
        $approvedParent = Join-Path $project 'scripts\smoke'
        $outside = Join-Path $TestDrive 'outside-lifecycle'
        New-Item -ItemType Directory -Path $approvedParent -Force | Out-Null
        New-Item -ItemType Directory -Path $outside -Force | Out-Null
        $outsideScript = Join-Path $outside 'test.mjs'
        Set-Content -LiteralPath $outsideScript -Encoding UTF8 -Value 'process.exit(0);'
        New-Item -ItemType Junction -Path (Join-Path $approvedParent 'mcp') `
            -Target $outside | Out-Null
        New-TestStartupFile
        $install = Get-McpInstallPlan -Tool (New-TestMcpTool -SnapshotOverrides @{
            smoke = [pscustomobject]@{
                tool_name = 'local_tool'; timeout_seconds = 10
                expected_content_types = @('text')
                script_path = 'scripts/smoke/mcp/test.mjs'
                script_sha256 = (Get-FileHash $outsideScript).Hash.ToLowerInvariant()
                arguments = [pscustomobject]@{}
            }
        })

        $plan = Get-McpSmokePlan -InstallPlan $install -ProjectRoot $project

        $plan.Status | Should Be 'failed'
        $plan.ErrorCode | Should Be 'mcp_smoke_script_path_rejected'
    }

    It 'rejects a lifecycle path containing a nested reparse point' {
        $project = Join-Path $TestDrive 'nested-reparse-project'
        $approvedRoot = Join-Path $project 'scripts\smoke\mcp'
        $outside = Join-Path $TestDrive 'outside-nested-lifecycle'
        New-Item -ItemType Directory -Path $approvedRoot, $outside -Force | Out-Null
        $outsideScript = Join-Path $outside 'test.mjs'
        Set-Content -LiteralPath $outsideScript -Encoding UTF8 -Value 'process.exit(0);'
        New-Item -ItemType Junction -Path (Join-Path $approvedRoot 'nested') -Target $outside | Out-Null
        New-TestSmokeRuntime -Project $project | Out-Null
        New-TestStartupFile
        $install = Get-McpInstallPlan -Tool (New-TestMcpTool -SnapshotOverrides @{
            smoke = [pscustomobject]@{
                tool_name = 'local_tool'; timeout_seconds = 10
                expected_content_types = @('text')
                script_path = 'scripts/smoke/mcp/nested/test.mjs'
                script_sha256 = (Get-FileHash $outsideScript -Algorithm SHA256).Hash.ToLowerInvariant()
                arguments = [pscustomobject]@{}
            }
        })

        $plan = Get-McpSmokePlan -InstallPlan $install -ProjectRoot $project

        $plan.Status | Should Be 'failed'
        $plan.ErrorCode | Should Be 'mcp_smoke_script_path_rejected'
    }

    It 'rejects a lifecycle script hash mismatch' {
        $project = Join-Path $TestDrive 'hash-project'
        $scriptDir = Join-Path $project 'scripts\smoke\mcp'
        New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $scriptDir 'test.mjs') `
            -Encoding UTF8 -Value 'process.exit(0);'
        New-TestStartupFile
        $install = Get-McpInstallPlan -Tool (New-TestMcpTool -SnapshotOverrides @{
            smoke = [pscustomobject]@{
                tool_name = 'local_tool'; timeout_seconds = 10
                expected_content_types = @('text')
                script_path = 'scripts/smoke/mcp/test.mjs'
                script_sha256 = ('0' * 64)
                arguments = [pscustomobject]@{}
            }
        })

        $plan = Get-McpSmokePlan -InstallPlan $install -ProjectRoot $project

        $plan.Status | Should Be 'failed'
        $plan.ErrorCode | Should Be 'mcp_smoke_script_hash_mismatch'
    }

    It 'rejects invalid smoke profile schema values' {
        $cases = @(
            @{ Name = 'absolute script path'; ScriptRelativePath = 'scripts/smoke/mcp/absolute.mjs'; ScriptPathMode = 'absolute'; HashMode = 'valid'; Timeout = 10; ContentTypes = @('text'); Arguments = [pscustomobject]@{} },
            @{ Name = 'non mjs script'; ScriptRelativePath = 'scripts/smoke/mcp/not-mjs.js'; ScriptPathMode = 'relative'; HashMode = 'valid'; Timeout = 10; ContentTypes = @('text'); Arguments = [pscustomobject]@{} },
            @{ Name = 'uppercase hash'; ScriptRelativePath = 'scripts/smoke/mcp/uppercase.mjs'; ScriptPathMode = 'relative'; HashMode = 'uppercase'; Timeout = 10; ContentTypes = @('text'); Arguments = [pscustomobject]@{} },
            @{ Name = 'timeout too high'; ScriptRelativePath = 'scripts/smoke/mcp/timeout.mjs'; ScriptPathMode = 'relative'; HashMode = 'valid'; Timeout = 999; ContentTypes = @('text'); Arguments = [pscustomobject]@{} },
            @{ Name = 'empty content types'; ScriptRelativePath = 'scripts/smoke/mcp/content.mjs'; ScriptPathMode = 'relative'; HashMode = 'valid'; Timeout = 10; ContentTypes = @(); Arguments = [pscustomobject]@{} },
            @{ Name = 'non object arguments'; ScriptRelativePath = 'scripts/smoke/mcp/arguments.mjs'; ScriptPathMode = 'relative'; HashMode = 'valid'; Timeout = 10; ContentTypes = @('text'); Arguments = @('not-object') }
        )

        foreach ($case in $cases) {
            $project = Join-Path $TestDrive ("schema-" + ($case.Name -replace '[^a-zA-Z0-9]', '-'))
            $runtime = New-TestSmokeRuntime -Project $project -ScriptRelativePath $case.ScriptRelativePath
            New-TestStartupFile
            $scriptPath = if ($case.ScriptPathMode -eq 'absolute') {
                $runtime.ScriptPath
            }
            else {
                $case.ScriptRelativePath
            }
            $hash = if ($case.HashMode -eq 'uppercase') {
                $runtime.ScriptSha256.ToUpperInvariant()
            }
            else {
                $runtime.ScriptSha256
            }
            $install = Get-McpInstallPlan -Tool (New-TestMcpTool -SnapshotOverrides @{
                smoke = [pscustomobject]@{
                    tool_name = 'local_tool'
                    timeout_seconds = $case.Timeout
                    expected_content_types = $case.ContentTypes
                    script_path = $scriptPath
                    script_sha256 = $hash
                    arguments = $case.Arguments
                }
            })

            $plan = Get-McpSmokePlan -InstallPlan $install -ProjectRoot $project

            $plan.Status | Should Not Be 'planned'
            $plan.ErrorCode | Should Be 'mcp_smoke_profile_invalid'
        }
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
