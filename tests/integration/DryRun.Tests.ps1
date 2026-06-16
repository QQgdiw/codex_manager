$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$deploymentLibrary = Join-Path $projectRoot 'scripts\lib\DeploymentEngine.ps1'

function Get-DryRunTreeSnapshot {
    param([string]$Root)

    return @(
        Get-ChildItem -LiteralPath $Root -Recurse -Force |
            Sort-Object FullName |
            ForEach-Object {
                [pscustomobject]@{
                    RelativePath = $_.FullName.Substring($Root.Length)
                    Kind = if ($_.PSIsContainer) { 'directory' } else { 'file' }
                    Hash = if ($_.PSIsContainer) {
                        $null
                    }
                    else {
                        (Get-FileHash -LiteralPath $_.FullName `
                            -Algorithm SHA256).Hash
                    }
                }
            }
    )
}

Describe 'Deployment dry run integration' {
    BeforeAll {
        . $deploymentLibrary
    }

    It 'leaves workspace, simulated Codex config, credential store, and journal unchanged' {
        $root = Join-Path $TestDrive 'dry-run-root'
        $workspace = Join-Path $root 'workspace'
        $codexRoot = Join-Path $root 'codex-user'
        $credentialRoot = Join-Path $root 'credentials'
        $journalRoot = Join-Path $root 'journal'
        New-Item -ItemType Directory -Path $workspace, $codexRoot, `
            $credentialRoot, $journalRoot | Out-Null
        [IO.File]::WriteAllText((Join-Path $workspace 'tracked.txt'), 'original')
        [IO.File]::WriteAllText((Join-Path $codexRoot 'config.toml'), 'model="test"')
        [IO.File]::WriteAllText(
            (Join-Path $credentialRoot 'credentials.dpapi'),
            '{"schema_version":"test","credentials":[]}'
        )
        [IO.File]::WriteAllText((Join-Path $journalRoot 'existing.json'), '{}')
        $before = @(Get-DryRunTreeSnapshot -Root $root)
        $tool = [pscustomobject]@{
            id = 'skill.dry'
            name = 'Dry Run Skill'
            type = 'skill'
            source = 'https://example.invalid/skill.dry'
            version = 'v1.0.0'
            sha256 = ('b' * 64)
            license = 'MIT'
            approval = 'approved'
            risk = 'low'
            install_target = (Join-Path $workspace 'Skills\skill.dry')
            credential_refs = @('metadata-only')
            conflicts = @()
            dependencies = @()
            permissions = @('network')
            external_changes = @(
                (Join-Path $codexRoot 'config.toml'),
                (Join-Path $journalRoot 'new.json')
            )
            rollback_capability = 'managed_files'
        }
        $plan = New-DeploymentPlan `
            -Config ([pscustomobject]@{ enabled_tools = @('skill.dry') }) `
            -Whitelist ([pscustomobject]@{
                schema_version = '1.0'
                tools = @($tool)
            }) `
            -CredentialMetadata @([pscustomobject]@{ Name = 'metadata-only' })

        $results = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$true -Executor {
            param($Item)
            [IO.File]::WriteAllText($Item.Target, 'side effect')
            throw 'executor must not run in dry run'
        })
        $after = @(Get-DryRunTreeSnapshot -Root $root)

        $results.Count | Should Be 1
        $results[0].Status | Should Be 'dry_run'
        ($after | ConvertTo-Json -Depth 5) | Should Be (
            $before | ConvertTo-Json -Depth 5
        )
        (Test-Path -LiteralPath $tool.install_target) | Should Be $false
    }
}
