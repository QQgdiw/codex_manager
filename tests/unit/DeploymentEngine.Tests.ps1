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
        (Test-DeploymentPlan -Plan $plan).IsValid | Should Be $true
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
