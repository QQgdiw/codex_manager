$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$entryPoint = Join-Path $projectRoot 'scripts\Invoke-CodexToolManager.ps1'
$journalLibrary = Join-Path $projectRoot 'scripts\lib\ChangeJournal.ps1'

function Write-EntryPointTextFile {
    param(
        [string]$Path,
        [string]$Text
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $encoding = New-Object Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $Text, $encoding)
}

function New-EntryPointFixture {
    param(
        [string]$Root,
        [string]$Approval = 'approved',
        [string]$ToolId = 'skill.entry',
        [string]$ToolType = 'skill',
        [string]$Target = $null
    )

    if ([string]::IsNullOrWhiteSpace($Target)) {
        $Target = Join-Path $Root 'managed\skill.entry'
    }
    $configPath = Join-Path $Root 'config.toml'
    $whitelistPath = Join-Path $Root 'whitelist.toml'
    $hash = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
    Write-EntryPointTextFile -Path $configPath -Text @"
schema_version = 1
name = "entrypoint"
enabled_tools = ["$ToolId"]
"@
    Write-EntryPointTextFile -Path $whitelistPath -Text @"
schema_version = "1.0"

[[tools]]
id = "$ToolId"
name = "Entry Point Skill"
type = "$ToolType"
source = "https://example.invalid/entrypoint"
version = "v1.0.0"
sha256 = "$hash"
license = "MIT"
approval = "$Approval"
risk = "low"
install_target = "$($Target.Replace('\', '\\'))"
credential_refs = []
conflicts = []
dependencies = []
permissions = []
external_changes = []
rollback_capability = "managed_files"
"@

    return [pscustomobject]@{
        Config = $configPath
        Whitelist = $whitelistPath
        Target = $Target
    }
}

function New-EntryPointPluginFixture {
    param(
        [string]$Root,
        [string]$ToolId = 'plugin.openai-bundled.browser',
        [string]$Selector = 'browser',
        [string]$Marketplace = 'openai-bundled'
    )

    $configPath = Join-Path $Root 'config.toml'
    $whitelistPath = Join-Path $Root 'whitelist.toml'
    $hash = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
    Write-EntryPointTextFile -Path $configPath -Text @"
schema_version = 1
name = "plugin-entrypoint"
enabled_tools = ["$ToolId"]
"@
    Write-EntryPointTextFile -Path $whitelistPath -Text @"
schema_version = "1.0"

[[tools]]
id = "$ToolId"
name = "Entry Point Plugin"
type = "plugin"
source = "https://github.com/example/plugin-market"
version = "v1.0.0"
sha256 = "$hash"
license = "MIT"
approval = "approved"
risk = "low"
install_target = "Plugins/$Marketplace/$Selector"
credential_refs = []
conflicts = []
dependencies = []
permissions = []
external_changes = []
rollback_capability = "managed_files"
marketplace_name = "$Marketplace"
plugin_selector = "$Selector"
"@

    return [pscustomobject]@{
        Config = $configPath
        Whitelist = $whitelistPath
        ToolId = $ToolId
        Selector = $Selector
        Marketplace = $Marketplace
    }
}

function New-EntryPointSkillSource {
    param(
        [string]$Root,
        [string]$SkillId = 'entry-skill'
    )

    $source = Join-Path $Root "source-$SkillId"
    New-Item -ItemType Directory -Path $source -Force | Out-Null
    Write-EntryPointTextFile -Path (Join-Path $source 'SKILL.md') -Text @"
---
name: Entry Skill
description: Entry point integration test skill.
---

# Entry Skill

This is an integration-test-only skill.
"@
    New-Item -ItemType Directory -Path (Join-Path $source 'docs') -Force | Out-Null
    Write-EntryPointTextFile -Path (Join-Path $source 'docs\usage.md') -Text 'Usage.'
    return $source
}

function New-EntryPointSkillFixture {
    param(
        [string]$Root,
        [string]$ToolId = 'skill.entry-skill',
        [string]$SkillId = 'entry-skill'
    )

    $source = New-EntryPointSkillSource -Root $Root -SkillId $SkillId
    $workspace = Join-Path $Root 'workspace'
    New-Item -ItemType Directory -Path $workspace -Force | Out-Null
    $hashRun = & powershell -NoProfile -ExecutionPolicy Bypass -Command (
        ". '$projectRoot\scripts\lib\adapters\SkillAdapter.ps1'; " +
        "Get-SkillSourceHash -SourcePath '$($source.Replace("'", "''"))'"
    )
    $hash = [string]($hashRun | Select-Object -Last 1)
    $configPath = Join-Path $Root 'config.toml'
    $whitelistPath = Join-Path $Root 'whitelist.toml'
    Write-EntryPointTextFile -Path $configPath -Text @"
schema_version = 1
name = "skill-entrypoint"
enabled_tools = ["$ToolId"]
"@
    Write-EntryPointTextFile -Path $whitelistPath -Text @"
schema_version = "1.0"

[[tools]]
id = "$ToolId"
name = "Entry Skill"
type = "skill"
source = "local"
version = "1.0.0"
sha256 = "$hash"
license = "MIT"
approval = "approved"
risk = "low"
install_target = "Skills/$SkillId"
credential_refs = []
conflicts = []
dependencies = []
permissions = []
external_changes = []
rollback_capability = "managed_files"
skill_id = "$SkillId"
source_path = "$($source.Replace('\', '\\'))"
managed_workspace_root = "$($workspace.Replace('\', '\\'))"
skill_manifest = "SKILL.md"
"@

    return [pscustomobject]@{
        Config = $configPath
        Whitelist = $whitelistPath
        Source = $source
        Workspace = $workspace
        Target = (Join-Path $workspace "Skills\$SkillId")
        SkillId = $SkillId
    }
}

function Invoke-EntryPointProcess {
    param([string[]]$Arguments)

    $caseRoot = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $caseRoot | Out-Null
    $stdout = Join-Path $caseRoot 'stdout.json'
    $stderr = Join-Path $caseRoot 'stderr.txt'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $entryPoint @Arguments `
        > $stdout 2> $stderr
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        StdOutPath = $stdout
        StdErrPath = $stderr
        StdOut = if (Test-Path -LiteralPath $stdout) {
            [IO.File]::ReadAllText($stdout)
        }
        else {
            ''
        }
        StdErr = if (Test-Path -LiteralPath $stderr) {
            [IO.File]::ReadAllText($stderr)
        }
        else {
            ''
        }
    }
}

function ConvertFrom-EntryPointJson {
    param([object]$Run)

    $Run.StdOut.Trim() | Should Not Be ''
    return ($Run.StdOut | ConvertFrom-Json)
}

function New-FakeCodexCli {
    param([string]$Root)

    $bin = Join-Path $Root 'fake-bin'
    New-Item -ItemType Directory -Path $bin -Force | Out-Null
    $log = Join-Path $Root 'fake-codex.log'
    $script = Join-Path $bin 'codex.cmd'
    Set-Content -LiteralPath $script -Encoding ASCII -Value @"
@echo off
echo %~1 %~2 %~3 %~4 %~5 %~6 %~7>>"%CODEX_TOOL_MANAGER_FAKE_LOG%"
if "%~1"=="plugin" if "%~2"=="marketplace" if "%~3"=="add" (
  echo {"ok":true}
  exit /b 0
)
if "%~1"=="plugin" if "%~2"=="add" (
  echo {"ok":true}
  exit /b 0
)
if "%~1"=="plugin" if "%~2"=="list" (
  echo {"plugin":"browser","marketplace":"openai-bundled"}
  exit /b 0
)
echo unsupported fake codex command: %* 1>&2
exit /b 3
"@

    return [pscustomobject]@{
        Bin = $bin
        Log = $log
    }
}

Describe 'Codex tool manager entry point' {
    It 'plans by default, writes the requested JSON plan, and makes no changes' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'plan')
        $planPath = Join-Path $TestDrive 'plan-output.json'

        $run = Invoke-EntryPointProcess -Arguments @(
            'plan', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist,
            '-OutputPath', $planPath
        )

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'plan'
        $body.Status | Should Be 'succeeded'
        $body.Plan.Status | Should Be 'planned'
        @($body.Plan.Items).Count | Should Be 1
        (Test-Path -LiteralPath $planPath -PathType Leaf) | Should Be $true
        (Test-Path -LiteralPath $fixture.Target) | Should Be $false
    }

    It 'defaults to plan when no command is supplied' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'default-plan')

        $run = Invoke-EntryPointProcess -Arguments @(
            '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
        )

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'plan'
        $body.Status | Should Be 'succeeded'
        (Test-Path -LiteralPath $fixture.Target) | Should Be $false
    }

    It 'returns business failure for an unapproved tool without treating it as fatal' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'unapproved') `
            -Approval 'proposed'

        $run = Invoke-EntryPointProcess -Arguments @(
            'plan', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
        )

        $run.ExitCode | Should Be 1
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Status | Should Be 'blocked'
        (@($body.Plan.Errors) -join "`n") | Should Match 'not approved'
        $run.StdErr.Trim() | Should Be ''
    }

    It 'returns fatal exit code two for invalid configuration input' {
        $root = Join-Path $TestDrive 'fatal'
        New-Item -ItemType Directory -Path $root | Out-Null
        $configPath = Join-Path $root 'bad-config.toml'
        $whitelistPath = Join-Path $root 'whitelist.toml'
        Write-EntryPointTextFile -Path $configPath -Text 'enabled_tools = ['
        $fixture = New-EntryPointFixture -Root $root
        Move-Item -LiteralPath $fixture.Whitelist -Destination $whitelistPath -Force

        $run = Invoke-EntryPointProcess -Arguments @(
            'plan', '-Config', $configPath, '-Whitelist', $whitelistPath
        )

        $run.ExitCode | Should Be 2
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Status | Should Be 'fatal'
        $body.Message | Should Match 'TOML|converter|config'
    }

    It 'returns fatal exit code two for missing configuration path' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'missing-config')
        $missingConfig = Join-Path $TestDrive 'does-not-exist.toml'

        $run = Invoke-EntryPointProcess -Arguments @(
            'plan', '-Config', $missingConfig, '-Whitelist', $fixture.Whitelist
        )

        $run.ExitCode | Should Be 2
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Status | Should Be 'fatal'
        $body.Message | Should Match 'not found|exist|path|Config'
    }

    It 'returns fatal exit code two for unknown parameters' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'unknown-parameter')

        $run = Invoke-EntryPointProcess -Arguments @(
            'plan', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist,
            '-DryRnu'
        )

        $run.ExitCode | Should Be 2
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Status | Should Be 'fatal'
        $body.Message | Should Match 'Unsupported parameter|DryRnu'
    }

    It 'deploy dry-run reports planned work and leaves the target absent' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'dryrun')

        $run = Invoke-EntryPointProcess -Arguments @(
            'deploy', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist,
            '-DryRun'
        )

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'deploy'
        $body.Status | Should Be 'succeeded'
        @($body.Results)[0].Status | Should Be 'dry_run'
        (Test-Path -LiteralPath $fixture.Target) | Should Be $false
    }

    It 'deploy WhatIf reports planned work and leaves the target absent' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'whatif')

        $run = Invoke-EntryPointProcess -Arguments @(
            'deploy', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist,
            '-WhatIf'
        )

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'deploy'
        $body.Status | Should Be 'succeeded'
        @($body.Results)[0].Status | Should Be 'dry_run'
        (Test-Path -LiteralPath $fixture.Target) | Should Be $false
    }

    It 'keeps approved plugin deploy dry-run from calling Codex CLI' {
        $root = Join-Path $TestDrive 'plugin-dryrun'
        $fixture = New-EntryPointPluginFixture -Root $root
        $fake = New-FakeCodexCli -Root $root
        $oldPath = $env:PATH
        $oldLog = $env:CODEX_TOOL_MANAGER_FAKE_LOG
        try {
            $env:PATH = "$($fake.Bin);$oldPath"
            $env:CODEX_TOOL_MANAGER_FAKE_LOG = $fake.Log

            $run = Invoke-EntryPointProcess -Arguments @(
                'deploy', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist,
                '-DryRun'
            )
        }
        finally {
            $env:PATH = $oldPath
            if ($null -eq $oldLog) {
                Remove-Item Env:\CODEX_TOOL_MANAGER_FAKE_LOG -ErrorAction SilentlyContinue
            }
            else {
                $env:CODEX_TOOL_MANAGER_FAKE_LOG = $oldLog
            }
        }

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'deploy'
        $body.Status | Should Be 'succeeded'
        @($body.Results)[0].Status | Should Be 'dry_run'
        (Test-Path -LiteralPath $fake.Log -PathType Leaf) | Should Be $false
    }

    It 'keeps approved skill deploy dry-run from copying files' {
        $fixture = New-EntryPointSkillFixture -Root (Join-Path $TestDrive 'skill-dryrun')

        $run = Invoke-EntryPointProcess -Arguments @(
            'deploy', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist,
            '-DryRun'
        )

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'deploy'
        $body.Status | Should Be 'succeeded'
        @($body.Results)[0].Status | Should Be 'dry_run'
        (Test-Path -LiteralPath $fixture.Target) | Should Be $false
    }

    It 'deploys an approved skill through the managed Skill adapter' {
        $fixture = New-EntryPointSkillFixture -Root (Join-Path $TestDrive 'skill-deploy')

        $run = Invoke-EntryPointProcess -Arguments @(
            'deploy', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
        )

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'deploy'
        $body.Status | Should Be 'succeeded'
        @($body.Results)[0].Status | Should Be 'succeeded'
        (Test-Path -LiteralPath (Join-Path $fixture.Target 'SKILL.md') -PathType Leaf) |
            Should Be $true
        (Test-Path -LiteralPath (Join-Path $fixture.Target 'docs\usage.md') -PathType Leaf) |
            Should Be $true
    }

    It 'deploy without an adapter reports blocked business failure' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'deploy-blocked') `
            -ToolId 'mcp.entry' `
            -ToolType 'mcp'

        $run = Invoke-EntryPointProcess -Arguments @(
            'deploy', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
        )

        $run.ExitCode | Should Be 1
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Status | Should Be 'blocked'
        @($body.Results)[0].Status | Should Be 'blocked'
        @($body.Results)[0].Message | Should Match 'adapter'
    }

    It 'deploys an approved plugin through the Codex plugin adapter' {
        $root = Join-Path $TestDrive 'plugin-deploy'
        $fixture = New-EntryPointPluginFixture -Root $root
        $fake = New-FakeCodexCli -Root $root
        $oldPath = $env:PATH
        $oldLog = $env:CODEX_TOOL_MANAGER_FAKE_LOG
        try {
            $env:PATH = "$($fake.Bin);$oldPath"
            $env:CODEX_TOOL_MANAGER_FAKE_LOG = $fake.Log

            $run = Invoke-EntryPointProcess -Arguments @(
                'deploy', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
            )
        }
        finally {
            $env:PATH = $oldPath
            if ($null -eq $oldLog) {
                Remove-Item Env:\CODEX_TOOL_MANAGER_FAKE_LOG -ErrorAction SilentlyContinue
            }
            else {
                $env:CODEX_TOOL_MANAGER_FAKE_LOG = $oldLog
            }
        }

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'deploy'
        $body.Status | Should Be 'succeeded'
        @($body.Results)[0].Status | Should Be 'succeeded'
        $log = Get-Content -LiteralPath $fake.Log -Raw
        $log | Should Match 'plugin marketplace add'
        $log | Should Match 'plugin add browser@openai-bundled'
    }

    It 'verify is conservative when no load or smoke verifier is present' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'verify')

        $run = Invoke-EntryPointProcess -Arguments @(
            'verify', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
        )

        $run.ExitCode | Should Be 1
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'verify'
        $body.Status | Should Be 'blocked'
        @($body.Results | Where-Object { $_.Level -eq 'static' })[0].Status |
            Should Be 'static_verified'
        @($body.Results | Where-Object { $_.Level -eq 'load' })[0].Status |
            Should Be 'blocked'
        @($body.Results | Where-Object { $_.Level -eq 'smoke' })[0].Status |
            Should Be 'blocked'
    }

    It 'verifies an approved plugin through the Codex plugin list output' {
        $root = Join-Path $TestDrive 'plugin-verify'
        $fixture = New-EntryPointPluginFixture -Root $root
        $fake = New-FakeCodexCli -Root $root
        $oldPath = $env:PATH
        $oldLog = $env:CODEX_TOOL_MANAGER_FAKE_LOG
        try {
            $env:PATH = "$($fake.Bin);$oldPath"
            $env:CODEX_TOOL_MANAGER_FAKE_LOG = $fake.Log

            $run = Invoke-EntryPointProcess -Arguments @(
                'verify', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
            )
        }
        finally {
            $env:PATH = $oldPath
            if ($null -eq $oldLog) {
                Remove-Item Env:\CODEX_TOOL_MANAGER_FAKE_LOG -ErrorAction SilentlyContinue
            }
            else {
                $env:CODEX_TOOL_MANAGER_FAKE_LOG = $oldLog
            }
        }

        $run.ExitCode | Should Be 1
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'verify'
        $body.Status | Should Be 'blocked'
        @($body.Results | Where-Object { $_.Level -eq 'static' })[0].Status |
            Should Be 'static_verified'
        @($body.Results | Where-Object { $_.Level -eq 'load' })[0].Status |
            Should Be 'load_verified'
        @($body.Results | Where-Object { $_.Level -eq 'smoke' })[0].Status |
            Should Be 'blocked'
        $log = Get-Content -LiteralPath $fake.Log -Raw
        $log | Should Match 'plugin list --json'
    }

    It 'credential commands do not print plaintext secrets' {
        $storePath = Join-Path $TestDrive 'credentials\store.dpapi'
        $secret = 'super-secret-entrypoint-value'

        $setRun = Invoke-EntryPointProcess -Arguments @(
            'credential', 'set', '-Name', 'api-token', '-Value', $secret,
            '-StorePath', $storePath
        )
        $getRun = Invoke-EntryPointProcess -Arguments @(
            'credential', 'get', '-Name', 'api-token', '-StorePath', $storePath
        )
        $listRun = Invoke-EntryPointProcess -Arguments @(
            'credential', 'list', '-StorePath', $storePath
        )
        $removeRun = Invoke-EntryPointProcess -Arguments @(
            'credential', 'remove', '-Name', 'api-token', '-StorePath', $storePath
        )

        $setRun.ExitCode | Should Be 0
        $getRun.ExitCode | Should Be 0
        $listRun.ExitCode | Should Be 0
        $removeRun.ExitCode | Should Be 0
        $combined = @(
            $setRun.StdOut, $getRun.StdOut, $listRun.StdOut, $removeRun.StdOut,
            $setRun.StdErr, $getRun.StdErr, $listRun.StdErr, $removeRun.StdErr
        ) -join "`n"
        $combined | Should Not Match ([regex]::Escape($secret))
        (ConvertFrom-EntryPointJson -Run $getRun).Redacted | Should Be $true
        @((ConvertFrom-EntryPointJson -Run $listRun).Credentials).Count |
            Should Be 1
    }

    It 'rejects credential value parameters without values' {
        $storePath = Join-Path $TestDrive 'credentials-missing-value\store.dpapi'

        $run = Invoke-EntryPointProcess -Arguments @(
            'credential', 'set', '-Name', 'api-token', '-Value', 'secret-value',
            '-StorePath'
        )

        $run.ExitCode | Should Be 2
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Status | Should Be 'fatal'
        $body.Message | Should Match 'StorePath|value'
        (Test-Path -LiteralPath $storePath) | Should Be $false
    }

    It 'rejects extra credential positional arguments' {
        $storePath = Join-Path $TestDrive 'credentials-extra\store.dpapi'

        $run = Invoke-EntryPointProcess -Arguments @(
            'credential', 'set', 'extra', '-Name', 'api-token',
            '-Value', 'secret-value', '-StorePath', $storePath
        )

        $run.ExitCode | Should Be 2
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Status | Should Be 'fatal'
        $body.Message | Should Match 'credential|positional|extra'
        (Test-Path -LiteralPath $storePath) | Should Be $false
    }

    It 'rollback invokes the change journal rollback path' {
        . $journalLibrary
        $root = Join-Path $TestDrive 'rollback'
        $stateRoot = Join-Path $root '.state'
        $codexRoot = Join-Path $root '.codex-test'
        New-Item -ItemType Directory -Path $root, $codexRoot | Out-Null
        $path = Join-Path $root 'created.txt'
        $journal = New-ChangeJournal `
            -OperationId 'entrypoint-rollback' `
            -AllowedRoots @($root) `
            -CodexRoot $codexRoot `
            -StateRoot $stateRoot
        Add-FileChange -Journal $journal -Path $path -Kind create `
            -AllowedRoots @($root) | Out-Null
        [IO.File]::WriteAllText($path, 'created')
        Confirm-FileChange -Journal $journal -Path $path -AllowedRoots @($root) |
            Out-Null

        $run = Invoke-EntryPointProcess -Arguments @(
            'rollback', '-JournalPath', $journal.JournalPath, '-AllowedRoot', $root
        )

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Status | Should Be 'succeeded'
        $body.Rollback.Status | Should Be 'Succeeded'
        (Test-Path -LiteralPath $path) | Should Be $false
    }

    It 'reports rollback partial results as business failure' {
        . $journalLibrary
        $root = Join-Path $TestDrive 'rollback-partial'
        $stateRoot = Join-Path $root '.state'
        $codexRoot = Join-Path $root '.codex-test'
        New-Item -ItemType Directory -Path $root, $codexRoot | Out-Null
        $journal = New-ChangeJournal `
            -OperationId 'entrypoint-rollback-partial' `
            -AllowedRoots @($root) `
            -CodexRoot $codexRoot `
            -StateRoot $stateRoot
        Add-ExternalChange -Journal $journal `
            -Description 'external tool change remains manual' `
            -RollbackCommand '' `
            -AllowedRoots @($root) | Out-Null

        $run = Invoke-EntryPointProcess -Arguments @(
            'rollback', '-JournalPath', $journal.JournalPath, '-AllowedRoot', $root
        )

        $run.ExitCode | Should Be 1
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Status | Should Be 'blocked'
        $body.Rollback.Status | Should Be 'Partial'
        @($body.Rollback.Residuals).Count | Should Be 1
    }

    It 'status reports local inputs without network access' {
        $fixture = New-EntryPointFixture -Root (Join-Path $TestDrive 'status')

        $run = Invoke-EntryPointProcess -Arguments @(
            'status', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
        )

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'status'
        $body.Status | Should Be 'succeeded'
        $body.ConfigExists | Should Be $true
        $body.WhitelistExists | Should Be $true
        (@($body.AdapterTypes) -join '|') | Should Be 'plugin|mcp|skill'
    }
}
