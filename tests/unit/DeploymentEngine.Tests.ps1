$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$deploymentLibrary = Join-Path $projectRoot 'scripts\lib\DeploymentEngine.ps1'

function New-TestTool {
    param(
        [string]$Id,
        [string]$Approval = 'approved',
        [string]$Hash = ('a' * 64),
        [string[]]$Dependencies = @(),
        [string[]]$Conflicts = @(),
        [string[]]$CredentialRefs = @(),
        [string[]]$Permissions = @()
    )

    return [pscustomobject][ordered]@{
        id = $Id
        name = "Tool $Id"
        type = 'skill'
        source = "https://example.invalid/$Id"
        version = 'v1.0.0'
        sha256 = $Hash
        license = 'MIT'
        approval = $Approval
        risk = 'low'
        install_target = "Skills/$Id"
        credential_refs = @($CredentialRefs)
        conflicts = @($Conflicts)
        dependencies = @($Dependencies)
        permissions = @($Permissions)
        external_changes = @("external:$Id")
        rollback_capability = 'managed_files'
    }
}

function New-TestWhitelist {
    param([object[]]$Tools)

    return [pscustomobject]@{
        schema_version = '1.0'
        tools = @($Tools)
    }
}

function New-TestConfig {
    param([string[]]$EnabledTools)

    return [pscustomobject]@{
        schema_version = 1
        name = 'test'
        enabled_tools = @($EnabledTools)
    }
}

function Get-TestErrorText {
    param([object]$Validation)

    return (@($Validation.Errors) -join [Environment]::NewLine)
}

function Sync-TestPlainPlanIntegrity {
    param([object]$Plan)

    $integrityMember = $Plan.PSObject.Properties['PlanIntegrity']
    if ($null -ne $integrityMember -and
        $null -ne (Get-Command -Name Get-DeploymentPlanIntegrity `
            -ErrorAction SilentlyContinue)) {
        $Plan.PlanIntegrity = Get-DeploymentPlanIntegrity -Plan $Plan
    }
}

function Sync-TestProtectedPlanIntegrityIfExposed {
    param([object]$Plan)

    $protectCommand = Get-Command -Name Protect-DeploymentPlanIntegrity `
        -ErrorAction SilentlyContinue
    if ($null -ne $protectCommand -and
        $null -ne (Get-Command -Name Get-DeploymentPlanIntegrity `
            -ErrorAction SilentlyContinue)) {
        $digest = Get-DeploymentPlanIntegrity -Plan $Plan
        $Plan.PlanIntegrity = $digest
        $Plan.ProtectedPlanIntegrity = Protect-DeploymentPlanIntegrity `
            -Digest $digest
    }
}

Describe 'Deployment plan construction and validation' {
    BeforeAll {
        . $deploymentLibrary
    }

    It 'creates an explicit planned snapshot for an approved tool' {
        $tool = New-TestTool -Id 'skill.a' -Permissions @('network') `
            -CredentialRefs @('api-token')
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @($tool)) `
            -CredentialMetadata @([pscustomobject]@{ Name = 'api-token' })

        $plan.Status | Should Be 'planned'
        $plan.Items.Count | Should Be 1
        $plan.Items[0].Id | Should Be 'skill.a'
        $plan.Items[0].Target | Should Be 'Skills/skill.a'
        $plan.Items[0].Permissions | Should Be @('network')
        $plan.Items[0].CredentialRefs | Should Be @('api-token')
        @($plan.Items[0].Conflicts).Count | Should Be 0
        @($plan.Items[0].Dependencies).Count | Should Be 0
        $plan.Items[0].ExternalChanges | Should Be @('external:skill.a')
        $plan.Items[0].RollbackCapability | Should Be 'managed_files'
        $plan.Items[0].Source | Should Be 'https://example.invalid/skill.a'
        $plan.Items[0].Version | Should Be 'v1.0.0'
        $plan.Items[0].Hash | Should Be ('a' * 64)
        $plan.Items[0].ApprovedSnapshot.id | Should Be 'skill.a'
        $plan.Items[0].ApprovedSnapshot.source |
            Should Be 'https://example.invalid/skill.a'
        $plan.Items[0].ApprovedSnapshot.sha256 | Should Be ('a' * 64)
        $plan.Items[0].ApprovedSnapshot.credential_refs |
            Should Be @('api-token')
        (Test-DeploymentPlan -Plan $plan).IsValid | Should Be $true
    }

    It 'preserves only plugin-specific approved fields for plugin snapshots' {
        $tool = New-TestTool -Id 'skill.a'
        $tool.type = 'plugin'
        $tool | Add-Member -NotePropertyName 'marketplace_name' `
            -NotePropertyValue 'openai-curated'
        $tool | Add-Member -NotePropertyName 'plugin_selector' `
            -NotePropertyValue 'superpowers'
        $tool | Add-Member -NotePropertyName 'skill_id' `
            -NotePropertyValue 'context-fundamentals'
        $tool | Add-Member -NotePropertyName 'source_path' `
            -NotePropertyValue 'E:\codex\Skills\context-fundamentals'
        $tool | Add-Member -NotePropertyName 'managed_workspace_root' `
            -NotePropertyValue 'E:\codex'
        $tool | Add-Member -NotePropertyName 'skill_manifest' `
            -NotePropertyValue 'SKILL.md'

        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @($tool)) `
            -CredentialMetadata @()

        $snapshot = $plan.Items[0].ApprovedSnapshot
        $snapshot.marketplace_name | Should Be 'openai-curated'
        $snapshot.plugin_selector | Should Be 'superpowers'
        $snapshot.PSObject.Properties['skill_id'] | Should Be $null
        $snapshot.PSObject.Properties['source_path'] | Should Be $null
        $snapshot.PSObject.Properties['managed_workspace_root'] | Should Be $null
        $snapshot.PSObject.Properties['skill_manifest'] | Should Be $null
        (Test-DeploymentPlan -Plan $plan).IsValid | Should Be $true
    }

    It 'preserves only skill-specific approved fields for skill snapshots' {
        $tool = New-TestTool -Id 'skill.a'
        $tool | Add-Member -NotePropertyName 'marketplace_name' `
            -NotePropertyValue 'openai-curated'
        $tool | Add-Member -NotePropertyName 'plugin_selector' `
            -NotePropertyValue 'superpowers'
        $tool | Add-Member -NotePropertyName 'skill_id' `
            -NotePropertyValue 'skill.a'
        $tool | Add-Member -NotePropertyName 'source_path' `
            -NotePropertyValue 'E:\codex\Skills\skill.a'
        $tool | Add-Member -NotePropertyName 'managed_workspace_root' `
            -NotePropertyValue 'E:\codex'
        $tool | Add-Member -NotePropertyName 'skill_manifest' `
            -NotePropertyValue 'SKILL.md'

        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @($tool)) `
            -CredentialMetadata @()

        $snapshot = $plan.Items[0].ApprovedSnapshot
        $snapshot.PSObject.Properties['marketplace_name'] | Should Be $null
        $snapshot.PSObject.Properties['plugin_selector'] | Should Be $null
        $snapshot.skill_id | Should Be 'skill.a'
        $snapshot.source_path | Should Be 'E:\codex\Skills\skill.a'
        $snapshot.managed_workspace_root | Should Be 'E:\codex'
        $snapshot.skill_manifest | Should Be 'SKILL.md'
        (Test-DeploymentPlan -Plan $plan).IsValid | Should Be $true
    }

    It 'rejects skill snapshots whose install target does not match skill_id' {
        $tool = New-TestTool -Id 'skill.a'
        $tool.install_target = 'Skills/other-skill'
        $tool | Add-Member -NotePropertyName 'skill_id' -NotePropertyValue 'skill.a'
        $tool | Add-Member -NotePropertyName 'source_path' `
            -NotePropertyValue 'E:\codex\Skills\skill.a'
        $tool | Add-Member -NotePropertyName 'managed_workspace_root' `
            -NotePropertyValue 'E:\codex'
        $tool | Add-Member -NotePropertyName 'skill_manifest' `
            -NotePropertyValue 'SKILL.md'

        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @($tool)) `
            -CredentialMetadata @()
        $validation = Test-DeploymentPlan -Plan $plan

        $validation.IsValid | Should Be $false
        Get-TestErrorText $validation | Should Match 'install_target'
        Get-TestErrorText $validation | Should Match 'skill_id'
    }

    It 'rejects every approval state other than approved' {
        foreach ($approval in @('proposed', 'rejected', 'suspended')) {
            $plan = New-DeploymentPlan `
                -Config (New-TestConfig @('skill.a')) `
                -Whitelist (New-TestWhitelist @(
                    (New-TestTool -Id 'skill.a' -Approval $approval)
                )) `
                -CredentialMetadata @()

            $validation = Test-DeploymentPlan -Plan $plan
            $validation.IsValid | Should Be $false
            (Get-TestErrorText $validation) | Should Match $approval
        }
    }

    It 'checks hash format again while building the plan' {
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @(
                (New-TestTool -Id 'skill.a' -Hash 'ABC123')
            )) `
            -CredentialMetadata @()

        $validation = Test-DeploymentPlan -Plan $plan

        $validation.IsValid | Should Be $false
        (Get-TestErrorText $validation) | Should Match 'sha256|hash'
    }

    It 'deduplicates configured ids while preserving first occurrence' {
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.b', 'skill.a', 'skill.b')) `
            -Whitelist (New-TestWhitelist @(
                (New-TestTool -Id 'skill.a'),
                (New-TestTool -Id 'skill.b')
            )) `
            -CredentialMetadata @()

        @($plan.Items.Id) | Should Be @('skill.b', 'skill.a')
        @($plan.Warnings).Count | Should Be 1
        $plan.Warnings[0] | Should Match 'duplicate|skill.b'
    }

    It 'detects conflicts declared by either enabled item' {
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a', 'skill.b')) `
            -Whitelist (New-TestWhitelist @(
                (New-TestTool -Id 'skill.a' -Conflicts @('skill.b')),
                (New-TestTool -Id 'skill.b')
            )) `
            -CredentialMetadata @()

        $validation = Test-DeploymentPlan -Plan $plan

        $validation.IsValid | Should Be $false
        (Get-TestErrorText $validation) | Should Match 'conflict'
    }

    It 'reports missing credential metadata without reading a secret' {
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @(
                (New-TestTool -Id 'skill.a' -CredentialRefs @('missing-token'))
            )) `
            -CredentialMetadata @()

        $validation = Test-DeploymentPlan -Plan $plan

        $validation.IsValid | Should Be $false
        (Get-TestErrorText $validation) | Should Match 'missing-token'
    }

    It 'uses stable dependency order' {
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.c', 'skill.b', 'skill.a')) `
            -Whitelist (New-TestWhitelist @(
                (New-TestTool -Id 'skill.a'),
                (New-TestTool -Id 'skill.b' -Dependencies @('skill.a')),
                (New-TestTool -Id 'skill.c' -Dependencies @('skill.a'))
            )) `
            -CredentialMetadata @()

        @($plan.Items.Id) | Should Be @('skill.a', 'skill.c', 'skill.b')
        (Test-DeploymentPlan -Plan $plan).IsValid | Should Be $true
    }

    It 'distinguishes missing dependencies from disabled dependencies' {
        $missingPlan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @(
                (New-TestTool -Id 'skill.a' -Dependencies @('skill.missing'))
            )) `
            -CredentialMetadata @()
        $disabledPlan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @(
                (New-TestTool -Id 'skill.a' -Dependencies @('skill.b')),
                (New-TestTool -Id 'skill.b')
            )) `
            -CredentialMetadata @()

        (Get-TestErrorText (Test-DeploymentPlan $missingPlan)) |
            Should Match 'missing'
        (Get-TestErrorText (Test-DeploymentPlan $disabledPlan)) |
            Should Match 'not enabled|disabled'
    }

    It 'reports dependency cycles as validation errors' {
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a', 'skill.b')) `
            -Whitelist (New-TestWhitelist @(
                (New-TestTool -Id 'skill.a' -Dependencies @('skill.b')),
                (New-TestTool -Id 'skill.b' -Dependencies @('skill.a'))
            )) `
            -CredentialMetadata @()

        $validation = Test-DeploymentPlan -Plan $plan

        $validation.IsValid | Should Be $false
        (Get-TestErrorText $validation) | Should Match 'cycle'
    }

    It 'strictly validates optional permissions and dependencies types' {
        $tool = New-TestTool -Id 'skill.a'
        $tool.permissions = 'network'
        $tool.dependencies = 'skill.b'

        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @($tool)) `
            -CredentialMetadata @()
        $errors = Get-TestErrorText (Test-DeploymentPlan -Plan $plan)

        $errors | Should Match 'permissions'
        $errors | Should Match 'dependencies'
    }

    It 'does not change when config and whitelist inputs are mutated later' {
        $config = New-TestConfig @('skill.a')
        $tool = New-TestTool -Id 'skill.a' -Permissions @('network')
        $whitelist = New-TestWhitelist @($tool)
        $plan = New-DeploymentPlan -Config $config -Whitelist $whitelist `
            -CredentialMetadata @()

        $config.enabled_tools[0] = 'skill.changed'
        $tool.source = 'https://changed.invalid'
        $tool.permissions[0] = 'admin'
        $tool.dependencies += 'skill.changed'

        $plan.Items[0].Id | Should Be 'skill.a'
        $plan.Items[0].Source | Should Be 'https://example.invalid/skill.a'
        $plan.Items[0].Permissions | Should Be @('network')
        @($plan.Items[0].Dependencies).Count | Should Be 0
    }

    It 'rejects approved plans whose executable or safety fields are tampered' {
        $tamperCases = @(
            @{ Name = 'Hash'; Mutate = { param($Plan) $Plan.Items[0].Hash = 'bad' } },
            @{ Name = 'Source'; Mutate = { param($Plan) $Plan.Items[0].Source = '' } },
            @{ Name = 'Version'; Mutate = { param($Plan) $Plan.Items[0].Version = '' } },
            @{ Name = 'Type'; Mutate = { param($Plan) $Plan.Items[0].Type = 'script' } },
            @{ Name = 'Target'; Mutate = { param($Plan) $Plan.Items[0].Target = '' } },
            @{ Name = 'Dependencies'; Mutate = {
                    param($Plan)
                    $Plan.Items[0].Dependencies = @([pscustomobject]@{ Id = 'skill.b' })
                } },
            @{ Name = 'CredentialRefs'; Mutate = {
                    param($Plan)
                    $Plan.Items[0].CredentialRefs = @('missing-token')
                } },
            @{ Name = 'Conflicts'; Mutate = {
                    param($Plan)
                    $Plan.Items[0].Conflicts = @([pscustomobject]@{ Id = 'skill.b' })
                } },
            @{ Name = 'RollbackCapability'; Mutate = {
                    param($Plan)
                    $Plan.Items[0].RollbackCapability = ''
                } },
            @{ Name = 'ExternalChanges'; Mutate = {
                    param($Plan)
                    $Plan.Items[0].ExternalChanges = @([pscustomobject]@{
                            Path = 'config.toml'
                        })
                } }
        )

        foreach ($case in $tamperCases) {
            $plan = New-DeploymentPlan `
                -Config (New-TestConfig @('skill.a')) `
                -Whitelist (New-TestWhitelist @(
                    (New-TestTool -Id 'skill.a' -CredentialRefs @('api-token'))
                )) `
                -CredentialMetadata @([pscustomobject]@{ Name = 'api-token' })
            & $case.Mutate $plan

            $validation = Test-DeploymentPlan -Plan $plan

            $validation.IsValid | Should Be $false
            Get-TestErrorText $validation | Should Match $case.Name
        }
    }

    It 'throws for a damaged plan structure' {
        { Test-DeploymentPlan -Plan ([pscustomobject]@{ Status = 'planned' }) } |
            Should Throw
    }

    It 'does not expose a public plan integrity protection function' {
        Get-Command -Name Protect-DeploymentPlanIntegrity `
            -ErrorAction SilentlyContinue | Should Be $null
    }
}

Describe 'Deployment plan invocation' {
    BeforeAll {
        . $deploymentLibrary
    }

    It 'does not invoke an executor during WhatIf' {
        $script:executorCalls = 0
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @((New-TestTool -Id 'skill.a'))) `
            -CredentialMetadata @()

        $results = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$true -Executor {
            param($Item)
            $script:executorCalls++
            throw 'executor must not run'
        })

        $script:executorCalls | Should Be 0
        $results.Count | Should Be 1
        $results[0].Status | Should Be 'dry_run'
        $results[0].Data.ItemId | Should Be 'skill.a'
    }

    It 'returns blocked when no adapter or executor is available' {
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @((New-TestTool -Id 'skill.a'))) `
            -CredentialMetadata @()

        $result = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$false)

        $result.Count | Should Be 1
        $result[0].Status | Should Be 'blocked'
    }

    It 'does not invoke an executor for an unapproved plan' {
        $script:unapprovedCalls = 0
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @(
                (New-TestTool -Id 'skill.a' -Approval 'proposed')
            )) `
            -CredentialMetadata @()

        $result = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$false -Executor {
            param($Item)
            $script:unapprovedCalls++
            New-OperationResult -Status 'succeeded' -Message 'unexpected' `
                -Data ([pscustomobject]@{ ItemId = $Item.Id })
        })

        $script:unapprovedCalls | Should Be 0
        $result[0].Status | Should Be 'blocked'
    }

    It 'does not invoke an executor after plan approval is tampered' {
        $script:tamperedApprovalCalls = 0
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @(
                (New-TestTool -Id 'skill.a')
            )) `
            -CredentialMetadata @()
        $plan.Items[0].Approval = 'proposed'

        $result = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$false -Executor {
            param($Item)
            $script:tamperedApprovalCalls++
            New-OperationResult -Status 'succeeded' -Message 'unexpected' `
                -Data ([pscustomobject]@{ ItemId = $Item.Id })
        })

        $script:tamperedApprovalCalls | Should Be 0
        $result[0].Status | Should Be 'blocked'
    }

    It 'does not invoke an executor or adapter after executable fields are tampered' {
        $script:tamperedCalls = 0
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @((New-TestTool -Id 'skill.a'))) `
            -CredentialMetadata @()
        $plan.Items[0].Source = ''
        $adapters = @{
            skill = {
                param($Item)
                $script:tamperedCalls++
                New-OperationResult -Status 'succeeded' -Message 'adapter' `
                    -Data ([pscustomobject]@{ ItemId = $Item.Id })
            }
        }

        $result = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$false `
            -AdapterMap $adapters -Executor {
                param($Item)
                $script:tamperedCalls++
                New-OperationResult -Status 'succeeded' -Message 'executor' `
                    -Data ([pscustomobject]@{ ItemId = $Item.Id })
            })

        $script:tamperedCalls | Should Be 0
        $result[0].Status | Should Be 'blocked'
        $result[0].Message | Should Match 'Deployment plan is invalid'
        $result[0].Message | Should Match 'Source'
    }

    It 'validates tampered plans before WhatIf dry-run results' {
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @((New-TestTool -Id 'skill.a'))) `
            -CredentialMetadata @()
        $plan.Items[0].Source = ''

        $result = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$true -Executor {
            param($Item)
            throw 'executor must not run'
        })

        $result[0].Status | Should Be 'blocked'
        $result[0].Message | Should Match 'Deployment plan is invalid'
        $result[0].Message | Should Match 'Source'
    }

    It 'blocks execution when tampered executable fields recompute plain integrity' {
        $script:plainIntegrityBypassCalls = 0
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @((New-TestTool -Id 'skill.a'))) `
            -CredentialMetadata @()
        $plan.Items[0].Source = 'https://example.invalid/tampered'
        $plan.Items[0].Hash = ('b' * 64)
        Sync-TestPlainPlanIntegrity -Plan $plan

        $result = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$false -Executor {
            param($Item)
            $script:plainIntegrityBypassCalls++
            New-OperationResult -Status 'succeeded' -Message 'unexpected' `
                -Data ([pscustomobject]@{ ItemId = $Item.Id })
        })

        $script:plainIntegrityBypassCalls | Should Be 0
        $result[0].Status | Should Be 'blocked'
        $result[0].Message | Should Match 'Deployment plan is invalid'
    }

    It 'blocks execution when credential refs are changed after planning' {
        $script:missingCredentialCalls = 0
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @(
                (New-TestTool -Id 'skill.a' -CredentialRefs @('api-token'))
            )) `
            -CredentialMetadata @([pscustomobject]@{ Name = 'api-token' })
        $plan.Items[0].CredentialRefs = @('missing-token')
        Sync-TestPlainPlanIntegrity -Plan $plan

        $result = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$false -Executor {
            param($Item)
            $script:missingCredentialCalls++
            New-OperationResult -Status 'succeeded' -Message 'unexpected' `
                -Data ([pscustomobject]@{ ItemId = $Item.Id })
        })

        $script:missingCredentialCalls | Should Be 0
        $result[0].Status | Should Be 'blocked'
        $result[0].Message | Should Match 'CredentialRefs|credential'
    }

    It 'blocks execution when plan item order is changed after planning' {
        $script:orderTamperCalls = New-Object System.Collections.Generic.List[string]
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.base', 'skill.child')) `
            -Whitelist (New-TestWhitelist @(
                (New-TestTool -Id 'skill.base'),
                (New-TestTool -Id 'skill.child' -Dependencies @('skill.base'))
            )) `
            -CredentialMetadata @()
        $plan.Items = @($plan.Items[1], $plan.Items[0])
        Sync-TestPlainPlanIntegrity -Plan $plan

        $result = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$false -Executor {
            param($Item)
            $script:orderTamperCalls.Add($Item.Id)
            New-OperationResult -Status 'succeeded' -Message 'unexpected' `
                -Data ([pscustomobject]@{ ItemId = $Item.Id })
        })

        @($script:orderTamperCalls).Count | Should Be 0
        $result[0].Status | Should Be 'blocked'
        $result[0].Message | Should Match 'order|topolog|dependency'
    }

    It 'blocks execution when executable fields are changed and protected integrity is recomputed' {
        $script:protectedIntegrityBypassCalls = 0
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @((New-TestTool -Id 'skill.a'))) `
            -CredentialMetadata @()
        $plan.Items[0].Source = 'https://example.invalid/tampered'
        $plan.Items[0].Hash = ('b' * 64)
        Sync-TestProtectedPlanIntegrityIfExposed -Plan $plan

        $result = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$false -Executor {
            param($Item)
            $script:protectedIntegrityBypassCalls++
            New-OperationResult -Status 'succeeded' -Message 'unexpected' `
                -Data ([pscustomobject]@{ ItemId = $Item.Id })
        })

        $script:protectedIntegrityBypassCalls | Should Be 0
        $result[0].Status | Should Be 'blocked'
        $result[0].Message | Should Match 'ApprovedSnapshot|snapshot|approved'
    }

    It 'blocks execution when safety fields differ from the approved snapshot' {
        $tamperCases = @(
            @{ Name = 'CredentialRefs'; Mutate = {
                    param($Plan) $Plan.Items[0].CredentialRefs = @('other-token')
                } },
            @{ Name = 'Conflicts'; Mutate = {
                    param($Plan) $Plan.Items[0].Conflicts = @('skill.other')
                } },
            @{ Name = 'Dependencies'; Mutate = {
                    param($Plan) $Plan.Items[0].Dependencies = @('skill.other')
                } },
            @{ Name = 'Target'; Mutate = {
                    param($Plan) $Plan.Items[0].Target = 'Skills/tampered'
                } }
        )

        foreach ($case in $tamperCases) {
            $script:snapshotMismatchCalls = 0
            $tool = New-TestTool -Id 'skill.a' -CredentialRefs @('api-token')
            $plan = New-DeploymentPlan `
                -Config (New-TestConfig @('skill.a')) `
                -Whitelist (New-TestWhitelist @($tool)) `
                -CredentialMetadata @(
                    [pscustomobject]@{ Name = 'api-token' },
                    [pscustomobject]@{ Name = 'other-token' }
                )
            & $case.Mutate $plan
            Sync-TestProtectedPlanIntegrityIfExposed -Plan $plan

            $result = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$false `
                -Executor {
                    param($Item)
                    $script:snapshotMismatchCalls++
                    New-OperationResult -Status 'succeeded' `
                        -Message 'unexpected' `
                        -Data ([pscustomobject]@{ ItemId = $Item.Id })
                })

            $script:snapshotMismatchCalls | Should Be 0
            $result[0].Status | Should Be 'blocked'
            $result[0].Message | Should Match $case.Name
        }
    }

    It 'blocks execution when the approved snapshot is tampered without recomputing integrity' {
        $script:snapshotTamperCalls = 0
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @((New-TestTool -Id 'skill.a'))) `
            -CredentialMetadata @()
        $plan.Items[0].ApprovedSnapshot.source =
            'https://example.invalid/tampered'

        $result = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$false -Executor {
            param($Item)
            $script:snapshotTamperCalls++
            New-OperationResult -Status 'succeeded' -Message 'unexpected' `
                -Data ([pscustomobject]@{ ItemId = $Item.Id })
        })

        $script:snapshotTamperCalls | Should Be 0
        $result[0].Status | Should Be 'blocked'
        $result[0].Message | Should Match 'ProtectedPlanIntegrity|integrity'
    }

    It 'blocks dependents after failure and continues independent items' {
        $script:executedIds = New-Object System.Collections.Generic.List[string]
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.fail', 'skill.child', 'skill.free')) `
            -Whitelist (New-TestWhitelist @(
                (New-TestTool -Id 'skill.fail'),
                (New-TestTool -Id 'skill.child' -Dependencies @('skill.fail')),
                (New-TestTool -Id 'skill.free')
            )) `
            -CredentialMetadata @()

        $results = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$false -Executor {
            param($Item)
            $script:executedIds.Add($Item.Id)
            if ($Item.Id -eq 'skill.fail') {
                return New-OperationResult -Status 'failed' -Message 'failed' `
                    -Data ([pscustomobject]@{ ItemId = $Item.Id })
            }
            return New-OperationResult -Status 'succeeded' -Message 'done' `
                -Data ([pscustomobject]@{ ItemId = $Item.Id })
        })

        @($script:executedIds) | Should Be @('skill.fail', 'skill.free')
        ($results | Where-Object { $_.Data.ItemId -eq 'skill.child' }).Status |
            Should Be 'blocked'
        ($results | Where-Object { $_.Data.ItemId -eq 'skill.free' }).Status |
            Should Be 'succeeded'
    }

    It 'converts executor exceptions to failed results and redacts secrets' {
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @((New-TestTool -Id 'skill.a'))) `
            -CredentialMetadata @()

        $result = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$false -Executor {
            param($Item)
            throw 'request failed token=super-secret-value password=hunter2'
        })

        $result[0].Status | Should Be 'failed'
        $result[0].Message | Should Not Match 'super-secret-value|hunter2'
        $result[0].Message | Should Match 'REDACTED'
        $result[0].Data.RollbackRequired | Should Be $true
        $result[0].Data.RollbackCapability | Should Be 'managed_files'
    }

    It 'redacts secrets from executor result messages' {
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @((New-TestTool -Id 'skill.a'))) `
            -CredentialMetadata @()

        $result = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$false -Executor {
            param($Item)
            New-OperationResult -Status 'failed' `
                -Message 'request failed api_key=super-secret-value' `
                -Data ([pscustomobject]@{ ItemId = $Item.Id })
        })

        $result[0].Message | Should Not Match 'super-secret-value'
        $result[0].Message | Should Match 'REDACTED'
    }

    It 'uses an adapter map when an executor is not supplied' {
        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('skill.a')) `
            -Whitelist (New-TestWhitelist @((New-TestTool -Id 'skill.a'))) `
            -CredentialMetadata @()
        $adapters = @{
            skill = {
                param($Item)
                New-OperationResult -Status 'succeeded' -Message 'adapter' `
                    -Data ([pscustomobject]@{ ItemId = $Item.Id })
            }
        }

        $result = @(Invoke-DeploymentPlan -Plan $plan -WhatIf:$false `
            -AdapterMap $adapters)

        $result[0].Status | Should Be 'succeeded'
        $result[0].Data.ItemId | Should Be 'skill.a'
    }
}
