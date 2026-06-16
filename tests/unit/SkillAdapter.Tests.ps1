$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$skillLibrary = Join-Path $projectRoot 'scripts\lib\adapters\SkillAdapter.ps1'

function Get-TestSkillBasePath {
    if (-not [string]::IsNullOrWhiteSpace($TestDrive)) {
        return $TestDrive
    }

    $basePath = Join-Path ([IO.Path]::GetTempPath()) 'SkillAdapter.Tests'
    New-Item -ItemType Directory -Path $basePath -Force | Out-Null
    return $basePath
}

function New-TestSkillSource {
    param(
        [string]$SkillId = 'example-skill',
        [hashtable]$Files = @{}
    )

    $sourceRoot = Join-Path (Get-TestSkillBasePath) "src-$SkillId-$([Guid]::NewGuid().ToString('N'))"
    New-Item -ItemType Directory -Path $sourceRoot -Force | Out-Null
    $skillMarkdown = @"
---
name: Example Skill
description: Test skill description
---

# Example Skill

Read [usage](docs/usage.md).

Run scripts/setup.ps1 only after review.
"@
    Set-Content -LiteralPath (Join-Path $sourceRoot 'SKILL.md') `
        -Value $skillMarkdown `
        -Encoding ASCII
    New-Item -ItemType Directory -Path (Join-Path $sourceRoot 'docs') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $sourceRoot 'docs\usage.md') `
        -Value 'Usage documentation.' `
        -Encoding ASCII
    New-Item -ItemType Directory -Path (Join-Path $sourceRoot 'scripts') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $sourceRoot 'scripts\setup.ps1') `
        -Value 'Write-Output setup' `
        -Encoding ASCII

    foreach ($relativePath in $Files.Keys) {
        $fullPath = Join-Path $sourceRoot $relativePath
        $parent = Split-Path -Parent $fullPath
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        Set-Content -LiteralPath $fullPath -Value $Files[$relativePath] -Encoding ASCII
    }

    return $sourceRoot
}

function New-TestSkillTool {
    param(
        [hashtable]$SnapshotOverrides = @{},
        [hashtable]$ToolOverrides = @{},
        [string]$SourcePath = $null,
        [string]$WorkspaceRoot = $null,
        [string]$Hash = $null
    )

    if ([string]::IsNullOrWhiteSpace($SourcePath)) {
        $SourcePath = New-TestSkillSource
    }
    if ([string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
        $WorkspaceRoot = Join-Path (Get-TestSkillBasePath) "workspace-$([Guid]::NewGuid().ToString('N'))"
    }
    New-Item -ItemType Directory -Path $WorkspaceRoot -Force | Out-Null

    $snapshot = @{
        id = 'skill.example-skill'
        name = 'Example Skill'
        type = 'skill'
        source = 'local'
        version = '1.0.0'
        sha256 = $Hash
        approval = 'approved'
        skill_id = 'example-skill'
        source_path = $SourcePath
        managed_workspace_root = $WorkspaceRoot
        skill_manifest = 'SKILL.md'
        references = @('docs/usage.md')
        scripts = @('scripts/setup.ps1')
        sensitive_redactions = @('SECRET-SKILL-TOKEN')
    }
    if ([string]::IsNullOrWhiteSpace($snapshot.sha256)) {
        $snapshot.sha256 = Get-SkillSourceHash -SourcePath $SourcePath
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
        Id = 'skill.top-level'
        Name = 'Unsafe Top Level Skill'
        Type = 'skill'
        source_path = (Join-Path (Get-TestSkillBasePath) 'unsafe-source')
        target_subdir = '..\unsafe'
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

function Assert-SkillPlanDoesNotLeak {
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

Describe 'Get-SkillInstallPlan' {
    BeforeAll {
        . $skillLibrary
    }

    It 'builds a managed workspace Skills target from the approved snapshot only' {
        $source = New-TestSkillSource
        $hash = Get-SkillSourceHash -SourcePath $source
        $tool = New-TestSkillTool `
            -SourcePath $source `
            -Hash $hash `
            -ToolOverrides @{ skill_id = 'unsafe-top-level' }

        $plan = Get-SkillInstallPlan -Tool $tool

        $plan.Status | Should Be 'planned'
        $plan.SkillId | Should Be 'example-skill'
        $plan.TargetPath | Should Be (Join-Path $plan.ManagedWorkspaceRoot 'Skills\example-skill')
        $plan.ManifestPath | Should Be (Join-Path $source 'SKILL.md')
        $plan.ManifestMetadata.name | Should Be 'Example Skill'
        $plan.ManifestMetadata.description | Should Be 'Test skill description'
        $plan.SourceHash | Should Be $hash
        $plan.TargetPath | Should Not Match 'unsafe-top-level'
    }

    It 'rejects missing SKILL.md' {
        $source = New-TestSkillSource
        Remove-Item -LiteralPath (Join-Path $source 'SKILL.md') -Force

        $plan = Get-SkillInstallPlan -Tool (
            New-TestSkillTool -SourcePath $source -Hash ('a' * 64)
        )

        $plan.Status | Should Be 'failed'
        $plan.Message | Should Match 'SKILL.md|manifest'
    }

    It 'rejects front matter without required name and description' {
        $source = New-TestSkillSource
        Set-Content -LiteralPath (Join-Path $source 'SKILL.md') `
            -Value "---`nname: Only Name`n---`n# Body" `
            -Encoding ASCII

        $plan = Get-SkillInstallPlan -Tool (
            New-TestSkillTool -SourcePath $source -Hash (Get-SkillSourceHash -SourcePath $source)
        )

        $plan.Status | Should Be 'failed'
        $plan.Message | Should Match 'description'
    }

    It 'rejects declared references and scripts that escape the source path' {
        $source = New-TestSkillSource
        $plan = Get-SkillInstallPlan -Tool (
            New-TestSkillTool `
                -SourcePath $source `
                -Hash (Get-SkillSourceHash -SourcePath $source) `
                -SnapshotOverrides @{
                    references = @('..\outside.md')
                    scripts = @('scripts/setup.ps1')
                }
        )

        $plan.Status | Should Be 'failed'
        $plan.Message | Should Match 'reference|relative|source'
    }

    It 'rejects absolute script paths even when they exist' {
        $source = New-TestSkillSource
        $scriptPath = Join-Path $source 'scripts\setup.ps1'
        $plan = Get-SkillInstallPlan -Tool (
            New-TestSkillTool `
                -SourcePath $source `
                -Hash (Get-SkillSourceHash -SourcePath $source) `
                -SnapshotOverrides @{ scripts = @($scriptPath) }
        )

        $plan.Status | Should Be 'failed'
        $plan.Message | Should Match 'script|relative'
    }

    It 'rejects missing declared files' {
        $source = New-TestSkillSource
        $plan = Get-SkillInstallPlan -Tool (
            New-TestSkillTool `
                -SourcePath $source `
                -Hash (Get-SkillSourceHash -SourcePath $source) `
                -SnapshotOverrides @{ references = @('docs/missing.md') }
        )

        $plan.Status | Should Be 'failed'
        $plan.Message | Should Match 'does not exist'
    }

    It 'rejects target_subdir path traversal and absolute target paths' {
        $source = New-TestSkillSource
        foreach ($targetSubdir in @('..\outside', (Join-Path (Get-TestSkillBasePath) 'absolute-target'))) {
            $plan = Get-SkillInstallPlan -Tool (
                New-TestSkillTool `
                    -SourcePath $source `
                    -Hash (Get-SkillSourceHash -SourcePath $source) `
                    -SnapshotOverrides @{ target_subdir = $targetSubdir }
            )

            $plan.Status | Should Be 'failed'
            $plan.Message | Should Match 'target_subdir|target'
            $plan.TargetPath | Should Be $null
        }
    }

    It 'allows explicit target_root while keeping target under that root' {
        $source = New-TestSkillSource
        $targetRoot = Join-Path (Get-TestSkillBasePath) 'approved-targets'
        New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null

        $plan = Get-SkillInstallPlan -Tool (
            New-TestSkillTool `
                -SourcePath $source `
                -Hash (Get-SkillSourceHash -SourcePath $source) `
                -SnapshotOverrides @{ target_root = $targetRoot }
        )

        $plan.Status | Should Be 'planned'
        $plan.TargetRoot | Should Be ([IO.Path]::GetFullPath($targetRoot))
        $plan.TargetPath | Should Be (Join-Path $plan.TargetRoot 'example-skill')
    }

    It 'rejects mismatched source hashes deterministically' {
        $source = New-TestSkillSource
        $plan = Get-SkillInstallPlan -Tool (
            New-TestSkillTool -SourcePath $source -Hash ('0' * 64)
        )

        $plan.Status | Should Be 'failed'
        $plan.Message | Should Match 'sha256|hash'
    }

    It 'does not use top-level fields when approved snapshot omits required fields' {
        $source = New-TestSkillSource
        $plan = Get-SkillInstallPlan -Tool (
            New-TestSkillTool `
                -SourcePath $source `
                -Hash (Get-SkillSourceHash -SourcePath $source) `
                -SnapshotOverrides @{ skill_id = $null } `
                -ToolOverrides @{ skill_id = 'top-level-skill' }
        )

        $plan.Status | Should Be 'failed'
        (@($plan.Errors) -join '|') | Should Match 'skill_id'
    }
}

Describe 'Install-ManagedSkill' {
    BeforeAll {
        . $skillLibrary
    }

    It 'copies only the approved source into the managed target and records journal intent' {
        $source = New-TestSkillSource
        $plan = Get-SkillInstallPlan -Tool (
            New-TestSkillTool -SourcePath $source -Hash (Get-SkillSourceHash -SourcePath $source)
        )
        $script:journalEntries = @()
        $journal = [pscustomobject]@{
            AddExternalChange = {
                param($Entry)
                $script:journalEntries += ,$Entry
            }
        }

        $result = Install-ManagedSkill -Plan $plan -Journal $journal

        $result.Status | Should Be 'succeeded'
        (Test-Path -LiteralPath (Join-Path $plan.TargetPath 'SKILL.md') -PathType Leaf) |
            Should Be $true
        (Test-Path -LiteralPath (Join-Path $plan.TargetPath 'scripts\setup.ps1') -PathType Leaf) |
            Should Be $true
        $result.Data.ActivationAsserted | Should Be $false
        $result.Data.SourcePath | Should Be $null
        $script:journalEntries.Count | Should Be 1
        $script:journalEntries[0].RollbackCommand | Should Be ''
        $script:journalEntries[0].Description | Should Match 'example-skill'
    }

    It 'returns a redacted failed result without raw exception details' {
        $source = New-TestSkillSource
        $blockedTargetRoot = Join-Path (Get-TestSkillBasePath) 'SECRET-SKILL-TOKEN'
        Set-Content -LiteralPath $blockedTargetRoot -Value 'file blocks directory' -Encoding ASCII
        $plan = Get-SkillInstallPlan -Tool (
            New-TestSkillTool `
                -SourcePath $source `
                -Hash (Get-SkillSourceHash -SourcePath $source) `
                -SnapshotOverrides @{ target_root = $blockedTargetRoot }
        )

        $result = Install-ManagedSkill -Plan $plan
        $json = $result.Data | ConvertTo-Json -Depth 8 -Compress

        $result.Status | Should Be 'failed'
        $result.Message | Should Not Match 'SECRET-SKILL-TOKEN'
        $json | Should Not Match 'SECRET-SKILL-TOKEN'
        ($result.Data.PSObject.Properties.Name -join '|') | Should Not Match '(^|\|)Exception($|\|)'
    }
}

Describe 'Uninstall-ManagedSkill' {
    BeforeAll {
        . $skillLibrary
    }

    It 'removes only the planned managed target' {
        $source = New-TestSkillSource
        $plan = Get-SkillInstallPlan -Tool (
            New-TestSkillTool -SourcePath $source -Hash (Get-SkillSourceHash -SourcePath $source)
        )
        [void](Install-ManagedSkill -Plan $plan)

        $result = Uninstall-ManagedSkill -Plan $plan

        $result.Status | Should Be 'succeeded'
        (Test-Path -LiteralPath $plan.TargetPath) | Should Be $false
    }
}

Describe 'Test-ManagedSkill' {
    BeforeAll {
        . $skillLibrary
    }

    It 'returns blocked after directory install when no official verifier is provided' {
        $source = New-TestSkillSource
        $plan = Get-SkillInstallPlan -Tool (
            New-TestSkillTool -SourcePath $source -Hash (Get-SkillSourceHash -SourcePath $source)
        )
        [void](Install-ManagedSkill -Plan $plan)

        $result = Test-ManagedSkill -Plan $plan

        $result.Status | Should Be 'blocked'
        $result.Message | Should Match 'directory installed but activation not asserted'
        $result.ErrorCode | Should Be 'activation_not_asserted'
    }

    It 'delegates to a verifier when official activation evidence is available' {
        $source = New-TestSkillSource
        $plan = Get-SkillInstallPlan -Tool (
            New-TestSkillTool -SourcePath $source -Hash (Get-SkillSourceHash -SourcePath $source)
        )

        $result = Test-ManagedSkill -Plan $plan -Verifier {
            param($VerifierPlan)
            [pscustomobject]@{
                Status = 'load_verified'
                Message = "verified $($VerifierPlan.SkillId)"
                Checks = @('official plugin manifest contains skill')
            }
        }

        $result.Status | Should Be 'load_verified'
        $result.Checks[0] | Should Match 'official plugin manifest'
    }
}
