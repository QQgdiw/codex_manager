$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tomlLibrary = Join-Path $projectRoot 'scripts\lib\Read-Toml.ps1'

function Get-ScenarioConfigErrors {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Config,

        [Parameter(Mandatory = $true)]
        [object]$Whitelist
    )

    $errors = New-Object System.Collections.Generic.List[string]

    foreach ($field in @('schema_version', 'profile_id', 'name',
            'description', 'approval_policy')) {
        $property = $Config.PSObject.Properties[$field]
        if ($null -eq $property -or $property.Value -isnot [string] -or
            [string]::IsNullOrWhiteSpace($property.Value)) {
            $errors.Add("Scenario config field '$field' must be a non-empty string.")
        }
    }

    if ($Config.PSObject.Properties['approval_policy'] -and
        $Config.approval_policy -cne 'approved_only') {
        $errors.Add("Scenario config approval_policy must be approved_only.")
    }

    foreach ($arrayField in @('required_capabilities', 'enabled_tools')) {
        $property = $Config.PSObject.Properties[$arrayField]
        if ($null -eq $property -or $property.Value -isnot [System.Array]) {
            $errors.Add("Scenario config field '$arrayField' must be an array.")
            continue
        }
        for ($index = 0; $index -lt $property.Value.Count; $index++) {
            $value = $property.Value[$index]
            if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) {
                $errors.Add("Scenario config field '$arrayField[$index]' must be a non-empty string.")
            }
        }
    }

    $capabilities = @($Config.required_capabilities)
    foreach ($required in @('browser_retrieval', 'resource_synthesis')) {
        if ($capabilities -notcontains $required) {
            $errors.Add("Scenario config must declare required capability '$required'.")
        }
    }

    $toolsById = @{}
    foreach ($tool in @($Whitelist.tools)) {
        $toolsById[$tool.id] = $tool
    }

    $enabledToolsProperty = $Config.PSObject.Properties['enabled_tools']
    $enabledTools = if ($null -ne $enabledToolsProperty -and
        $enabledToolsProperty.Value -is [System.Array]) {
        @($enabledToolsProperty.Value)
    }
    else {
        @()
    }

    $seenEnabled = @{}
    foreach ($id in $enabledTools) {
        if ($seenEnabled.ContainsKey($id)) {
            $errors.Add("Scenario config contains duplicate enabled tool '$id'.")
            continue
        }
        $seenEnabled[$id] = $true

        if (-not $toolsById.ContainsKey($id)) {
            $errors.Add("Scenario config enabled tool '$id' is not in whitelist.")
            continue
        }
        if ($toolsById[$id].approval -cne 'approved') {
            $errors.Add("Scenario config enabled tool '$id' is not approved.")
        }
    }

    foreach ($id in @($seenEnabled.Keys)) {
        if (-not $toolsById.ContainsKey($id)) {
            continue
        }
        foreach ($conflict in @($toolsById[$id].conflicts)) {
            if ($seenEnabled.ContainsKey($conflict)) {
                $errors.Add("Scenario config enabled tools '$id' and '$conflict' conflict.")
            }
        }
    }

    return ,($errors.ToArray())
}

Describe 'Scenario config profiles' {
    BeforeAll {
        . $tomlLibrary
        $script:whitelist = Read-ProjectToml -Path (
            Join-Path $projectRoot 'Resources\tool_whitelist.toml'
        )
        $script:scenarioFiles = @(
            'config_note.toml',
            'config_basic.toml',
            'config_mcu.toml',
            'config_zynq.toml',
            'config_hardware.toml',
            'config_file.toml'
        )
    }

    It 'rejects an empty scenario config' {
        $errors = Get-ScenarioConfigErrors -Config ([pscustomobject]@{}) `
            -Whitelist $script:whitelist

        $errors.Count | Should BeGreaterThan 0
        ($errors -join "`n") | Should Match 'schema_version'
        ($errors -join "`n") | Should Match 'required_capabilities'
        ($errors -join "`n") | Should Match 'enabled_tools'
    }

    It 'keeps every scenario config parseable and approved-only' {
        foreach ($file in $script:scenarioFiles) {
            $config = Read-ProjectToml -Path (Join-Path $projectRoot "Resources\$file")
            $errors = Get-ScenarioConfigErrors -Config $config `
                -Whitelist $script:whitelist

            ($errors -join "`n") | Should Be ''
        }
    }

    It 'keeps generated scenario profiles empty until explicit profile enablement' {
        $approvedCount = @(
            $script:whitelist.tools | Where-Object { $_.approval -eq 'approved' }
        ).Count
        $approvedCount | Should Be 4

        foreach ($file in $script:scenarioFiles) {
            $config = Read-ProjectToml -Path (Join-Path $projectRoot "Resources\$file")
            @($config.enabled_tools).Count | Should Be 0
        }
    }

    It 'rejects a scenario that enables a proposed tool' {
        $config = [pscustomobject]@{
            schema_version = '1.0'
            profile_id = 'invalid'
            name = 'Invalid'
            description = 'Invalid proposed tool enablement.'
            approval_policy = 'approved_only'
            required_capabilities = @('browser_retrieval', 'resource_synthesis')
            enabled_tools = @('mcp.modelcontextprotocol.memory')
        }

        $errors = Get-ScenarioConfigErrors -Config $config `
            -Whitelist $script:whitelist

        ($errors -join "`n") | Should Match 'not approved'
    }
}
