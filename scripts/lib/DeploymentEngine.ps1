$deploymentLibraryRoot = $PSScriptRoot

if (-not (Get-Command -Name New-OperationResult -ErrorAction SilentlyContinue)) {
    . (Join-Path $deploymentLibraryRoot 'Common.ps1')
}
if (-not (Get-Command -Name Test-WhitelistDocument -ErrorAction SilentlyContinue)) {
    . (Join-Path $deploymentLibraryRoot 'Read-Toml.ps1')
}

function Test-DeploymentObject {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Value
    )

    return ($Value -is [System.Collections.IDictionary] -or
        $Value -is [System.Management.Automation.PSCustomObject])
}

function Get-DeploymentMember {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($key in $InputObject.Keys) {
            if ("$key" -ieq $Name) {
                return [pscustomobject]@{
                    Exists = $true
                    Value = $InputObject[$key]
                }
            }
        }
    }
    else {
        $property = $InputObject.PSObject.Properties[$Name]
        if ($null -ne $property) {
            return [pscustomobject]@{
                Exists = $true
                Value = $property.Value
            }
        }
    }

    return [pscustomobject]@{
        Exists = $false
        Value = $null
    }
}

function Copy-DeploymentValue {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value -or
        $Value -is [string] -or
        $Value.GetType().IsValueType) {
        return $Value
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $copy = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $copy["$key"] = Copy-DeploymentValue -Value $Value[$key]
        }
        return [pscustomobject]$copy
    }

    if ($Value -is [System.Array] -or
        $Value -is [System.Collections.IList]) {
        $copy = @($Value | ForEach-Object {
            Copy-DeploymentValue -Value $_
        })
        return ,$copy
    }

    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        $copy = [ordered]@{}
        foreach ($property in $Value.PSObject.Properties) {
            $copy[$property.Name] = Copy-DeploymentValue -Value $property.Value
        }
        return [pscustomobject]$copy
    }

    return $Value
}

function Add-DeploymentValidationError {
    param(
        [System.Collections.Generic.List[string]]$Errors,
        [string]$Message
    )

    if (-not $Errors.Contains($Message)) {
        $Errors.Add($Message)
    }
}

function Get-DeploymentStringArray {
    param(
        [object]$InputObject,
        [string]$Name,
        [string]$Label,
        [System.Collections.Generic.List[string]]$Errors,
        [switch]$Optional
    )

    $member = Get-DeploymentMember -InputObject $InputObject -Name $Name
    if (-not $member.Exists) {
        if (-not $Optional) {
            Add-DeploymentValidationError -Errors $Errors `
                -Message "$Label is missing required field '$Name'."
        }
        return @()
    }

    if ($member.Value -isnot [System.Array]) {
        Add-DeploymentValidationError -Errors $Errors `
            -Message "$Label field '$Name' must be an array."
        return @()
    }

    $values = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt $member.Value.Count; $index++) {
        $value = $member.Value[$index]
        if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) {
            Add-DeploymentValidationError -Errors $Errors `
                -Message "$Label field '$Name[$index]' must be a non-empty string."
            continue
        }
        $values.Add($value)
    }
    return $values.ToArray()
}

function Get-DeploymentOptionalString {
    param(
        [object]$InputObject,
        [string]$Name,
        [string]$Label,
        [System.Collections.Generic.List[string]]$Errors
    )

    $member = Get-DeploymentMember -InputObject $InputObject -Name $Name
    if (-not $member.Exists) {
        return $null
    }
    if ($member.Value -isnot [string] -or
        [string]::IsNullOrWhiteSpace($member.Value)) {
        Add-DeploymentValidationError -Errors $Errors `
            -Message "$Label field '$Name' must be a non-empty string."
        return $null
    }
    return $member.Value
}

function Get-DeploymentCredentialMetadata {
    $credentialLibrary = Join-Path $deploymentLibraryRoot 'CredentialStore.ps1'
    if (-not (Get-Command -Name Get-ManagedCredentialMetadata `
            -ErrorAction SilentlyContinue)) {
        . $credentialLibrary
    }
    return @(Get-ManagedCredentialMetadata)
}

function Protect-DeploymentExceptionText {
    param(
        [AllowEmptyString()]
        [string]$Text
    )

    $protected = $Text
    $protected = [regex]::Replace(
        $protected,
        '(?i)\b(token|password|secret|api[_-]?key|authorization)' +
            '\s*[:=]\s*(?:"[^"]*"|''[^'']*''|[^\s,;]+)',
        '$1=[REDACTED]'
    )
    $protected = [regex]::Replace(
        $protected,
        '(?i)\bbearer\s+[^\s,;]+',
        'Bearer [REDACTED]'
    )
    $protected = [regex]::Replace(
        $protected,
        '\bgh[a-z]_[A-Za-z0-9]{10,}\b',
        '[REDACTED]'
    )
    $protected = [regex]::Replace(
        $protected,
        '\b[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{12,}\b',
        '[REDACTED]'
    )
    return $protected
}

function New-DeploymentPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Config,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Whitelist,

        [AllowNull()]
        [object[]]$CredentialMetadata
    )

    if (-not (Test-DeploymentObject -Value $Config)) {
        throw 'Deployment config must be a readable object.'
    }

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]
    $whitelistValidation = Test-WhitelistDocument -Document $Whitelist
    foreach ($errorText in @($whitelistValidation.Errors)) {
        Add-DeploymentValidationError -Errors $errors `
            -Message "Whitelist: $errorText"
    }
    foreach ($warningText in @($whitelistValidation.Warnings)) {
        $warnings.Add("Whitelist: $warningText")
    }

    $enabledMember = Get-DeploymentMember -InputObject $Config `
        -Name 'enabled_tools'
    if (-not $enabledMember.Exists) {
        throw "Deployment config is missing required 'enabled_tools' array."
    }
    if ($enabledMember.Value -isnot [System.Array]) {
        throw "Deployment config field 'enabled_tools' must be an array."
    }

    $enabledIds = New-Object System.Collections.Generic.List[string]
    $enabledSet = @{}
    for ($index = 0; $index -lt $enabledMember.Value.Count; $index++) {
        $id = $enabledMember.Value[$index]
        if ($id -isnot [string] -or [string]::IsNullOrWhiteSpace($id)) {
            Add-DeploymentValidationError -Errors $errors `
                -Message "Config enabled_tools[$index] must be a non-empty string."
            continue
        }
        if ($enabledSet.ContainsKey($id)) {
            $warnings.Add(
                "Config contains duplicate enabled tool '$id'; first occurrence is used."
            )
            continue
        }
        $enabledSet[$id] = $true
        $enabledIds.Add($id)
    }

    $toolsMember = Get-DeploymentMember -InputObject $Whitelist -Name 'tools'
    $whitelistTools = if ($toolsMember.Exists -and
        $toolsMember.Value -is [System.Array]) {
        @($toolsMember.Value)
    }
    else {
        @()
    }
    $toolsById = @{}
    foreach ($tool in $whitelistTools) {
        if (-not (Test-DeploymentObject -Value $tool)) {
            continue
        }
        $idMember = Get-DeploymentMember -InputObject $tool -Name 'id'
        if ($idMember.Exists -and $idMember.Value -is [string] -and
            -not $toolsById.ContainsKey($idMember.Value)) {
            $toolsById[$idMember.Value] = $tool
        }
    }

    if (-not $PSBoundParameters.ContainsKey('CredentialMetadata')) {
        $CredentialMetadata = @(Get-DeploymentCredentialMetadata)
    }
    $credentialNames = @{}
    foreach ($metadata in @($CredentialMetadata)) {
        if (-not (Test-DeploymentObject -Value $metadata)) {
            continue
        }
        $nameMember = Get-DeploymentMember -InputObject $metadata -Name 'Name'
        if ($nameMember.Exists -and $nameMember.Value -is [string] -and
            -not [string]::IsNullOrWhiteSpace($nameMember.Value)) {
            $credentialNames[$nameMember.Value] = $true
        }
    }

    $itemsById = @{}
    $configuredItems = New-Object System.Collections.Generic.List[object]
    foreach ($id in $enabledIds) {
        if (-not $toolsById.ContainsKey($id)) {
            Add-DeploymentValidationError -Errors $errors `
                -Message "Enabled tool '$id' is missing from the whitelist."
            continue
        }

        $tool = $toolsById[$id]
        $label = "Whitelist tool '$id'"
        $approval = Get-DeploymentMember -InputObject $tool -Name 'approval'
        if (-not $approval.Exists -or $approval.Value -cne 'approved') {
            $approvalText = if ($approval.Exists) { "$($approval.Value)" } else {
                '<missing>'
            }
            Add-DeploymentValidationError -Errors $errors `
                -Message "$label approval '$approvalText' is not approved."
        }

        $hash = Get-DeploymentMember -InputObject $tool -Name 'sha256'
        if (-not $hash.Exists -or $hash.Value -isnot [string] -or
            $hash.Value -cnotmatch '^[0-9a-f]{64}$') {
            Add-DeploymentValidationError -Errors $errors `
                -Message "$label sha256 hash must be 64 lowercase hexadecimal characters."
        }

        $dependencies = @(Get-DeploymentStringArray -InputObject $tool `
            -Name 'dependencies' -Label $label -Errors $errors -Optional)
        $permissionsMember = Get-DeploymentMember -InputObject $tool `
            -Name 'permissions'
        $permissions = if ($permissionsMember.Exists) {
            @(Get-DeploymentStringArray -InputObject $tool -Name 'permissions' `
                -Label $label -Errors $errors -Optional)
        }
        else {
            $null
        }
        $credentialRefs = @(Get-DeploymentStringArray -InputObject $tool `
            -Name 'credential_refs' -Label $label -Errors $errors)
        $conflicts = @(Get-DeploymentStringArray -InputObject $tool `
            -Name 'conflicts' -Label $label -Errors $errors)
        $externalChanges = @(Get-DeploymentStringArray -InputObject $tool `
            -Name 'external_changes' -Label $label -Errors $errors -Optional)
        $rollbackCapability = Get-DeploymentOptionalString -InputObject $tool `
            -Name 'rollback_capability' -Label $label -Errors $errors

        foreach ($credentialRef in $credentialRefs) {
            if (-not $credentialNames.ContainsKey($credentialRef)) {
                Add-DeploymentValidationError -Errors $errors `
                    -Message "$label requires missing credential '$credentialRef'."
            }
        }

        $source = Get-DeploymentMember -InputObject $tool -Name 'source'
        $version = Get-DeploymentMember -InputObject $tool -Name 'version'
        $target = Get-DeploymentMember -InputObject $tool -Name 'install_target'
        $type = Get-DeploymentMember -InputObject $tool -Name 'type'
        $name = Get-DeploymentMember -InputObject $tool -Name 'name'
        $item = [pscustomobject][ordered]@{
            Id = $id
            Name = Copy-DeploymentValue -Value $name.Value
            Type = Copy-DeploymentValue -Value $type.Value
            Source = Copy-DeploymentValue -Value $source.Value
            Version = Copy-DeploymentValue -Value $version.Value
            Hash = Copy-DeploymentValue -Value $hash.Value
            Target = Copy-DeploymentValue -Value $target.Value
            Permissions = Copy-DeploymentValue -Value $permissions
            CredentialRefs = Copy-DeploymentValue -Value $credentialRefs
            Conflicts = Copy-DeploymentValue -Value $conflicts
            Dependencies = Copy-DeploymentValue -Value $dependencies
            ExternalChanges = Copy-DeploymentValue -Value $externalChanges
            RollbackCapability = Copy-DeploymentValue `
                -Value $rollbackCapability
            Approval = Copy-DeploymentValue -Value $approval.Value
            Status = 'planned'
        }
        $itemsById[$id] = $item
        $configuredItems.Add($item)
    }

    foreach ($item in $configuredItems) {
        foreach ($dependency in @($item.Dependencies)) {
            if (-not $toolsById.ContainsKey($dependency)) {
                Add-DeploymentValidationError -Errors $errors `
                    -Message "Tool '$($item.Id)' has missing dependency '$dependency'."
            }
            elseif (-not $enabledSet.ContainsKey($dependency)) {
                Add-DeploymentValidationError -Errors $errors `
                    -Message (
                        "Tool '$($item.Id)' dependency '$dependency' is not enabled."
                    )
            }
        }
    }

    for ($leftIndex = 0; $leftIndex -lt $configuredItems.Count; $leftIndex++) {
        $left = $configuredItems[$leftIndex]
        for ($rightIndex = $leftIndex + 1;
            $rightIndex -lt $configuredItems.Count;
            $rightIndex++) {
            $right = $configuredItems[$rightIndex]
            if (@($left.Conflicts) -contains $right.Id -or
                @($right.Conflicts) -contains $left.Id) {
                Add-DeploymentValidationError -Errors $errors `
                    -Message "Enabled tools '$($left.Id)' and '$($right.Id)' conflict."
            }
        }
    }

    $orderedItems = New-Object System.Collections.Generic.List[object]
    $orderedIds = @{}
    while ($orderedItems.Count -lt $configuredItems.Count) {
        $madeProgress = $false
        foreach ($item in $configuredItems) {
            if ($orderedIds.ContainsKey($item.Id)) {
                continue
            }
            $unresolved = @(
                @($item.Dependencies) |
                    Where-Object {
                        $enabledSet.ContainsKey($_) -and
                        $itemsById.ContainsKey($_) -and
                        -not $orderedIds.ContainsKey($_)
                    }
            )
            if ($unresolved.Count -eq 0) {
                $orderedItems.Add($item)
                $orderedIds[$item.Id] = $true
                $madeProgress = $true
            }
        }
        if (-not $madeProgress) {
            $cycleIds = @(
                $configuredItems |
                    Where-Object { -not $orderedIds.ContainsKey($_.Id) } |
                    ForEach-Object { $_.Id }
            )
            Add-DeploymentValidationError -Errors $errors `
                -Message "Dependency cycle detected among: $($cycleIds -join ', ')."
            foreach ($item in $configuredItems) {
                if (-not $orderedIds.ContainsKey($item.Id)) {
                    $orderedItems.Add($item)
                    $orderedIds[$item.Id] = $true
                }
            }
        }
    }

    return [pscustomobject][ordered]@{
        SchemaVersion = '1.0'
        Status = 'planned'
        Items = $orderedItems.ToArray()
        Errors = $errors.ToArray()
        Warnings = $warnings.ToArray()
    }
}

function Test-DeploymentPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Plan
    )

    if (-not (Test-DeploymentObject -Value $Plan)) {
        throw 'Deployment plan must be a readable object.'
    }

    foreach ($required in @('SchemaVersion', 'Status', 'Items', 'Errors', 'Warnings')) {
        $member = Get-DeploymentMember -InputObject $Plan -Name $required
        if (-not $member.Exists) {
            throw "Deployment plan is missing required field '$required'."
        }
    }

    $items = (Get-DeploymentMember -InputObject $Plan -Name 'Items').Value
    $storedErrors = (Get-DeploymentMember -InputObject $Plan -Name 'Errors').Value
    $warnings = (Get-DeploymentMember -InputObject $Plan -Name 'Warnings').Value
    if ($items -isnot [System.Array] -or
        $storedErrors -isnot [System.Array] -or
        $warnings -isnot [System.Array]) {
        throw 'Deployment plan Items, Errors, and Warnings must be arrays.'
    }

    $errors = New-Object System.Collections.Generic.List[string]
    foreach ($errorText in $storedErrors) {
        Add-DeploymentValidationError -Errors $errors -Message "$errorText"
    }

    foreach ($item in $items) {
        if (-not (Test-DeploymentObject -Value $item)) {
            throw 'Deployment plan contains a damaged item.'
        }
        foreach ($required in @(
                'Id', 'Type', 'Source', 'Version', 'Hash', 'Target',
                'Permissions', 'CredentialRefs', 'Conflicts', 'Dependencies',
                'ExternalChanges', 'RollbackCapability', 'Approval', 'Status'
            )) {
            if (-not (Get-DeploymentMember -InputObject $item `
                    -Name $required).Exists) {
                throw "Deployment plan item is missing required field '$required'."
            }
        }

        $approval = (Get-DeploymentMember -InputObject $item `
                -Name 'Approval').Value
        if ($approval -cne 'approved') {
            Add-DeploymentValidationError -Errors $errors `
                -Message "Deployment plan item '$($item.Id)' is not approved."
        }
    }

    return [pscustomobject][ordered]@{
        IsValid = ($errors.Count -eq 0)
        Errors = $errors.ToArray()
        Warnings = @($warnings | ForEach-Object { "$_" })
    }
}

function Get-DeploymentAdapter {
    param(
        [AllowNull()]
        [System.Collections.IDictionary]$AdapterMap,
        [object]$Item
    )

    if ($null -eq $AdapterMap) {
        return $null
    }
    foreach ($key in @($Item.Id, $Item.Type)) {
        if ($AdapterMap.Contains($key) -and
            $AdapterMap[$key] -is [scriptblock]) {
            return $AdapterMap[$key]
        }
    }
    return $null
}

function Invoke-DeploymentPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Plan,

        [Parameter(Mandatory = $true)]
        [bool]$WhatIf,

        [AllowNull()]
        [System.Collections.IDictionary]$AdapterMap,

        [AllowNull()]
        [scriptblock]$Executor
    )

    $validation = Test-DeploymentPlan -Plan $Plan
    $results = New-Object System.Collections.Generic.List[object]
    $statusById = @{}

    if (-not $validation.IsValid) {
        $message = "Deployment plan is invalid: $($validation.Errors -join '; ')"
        foreach ($item in @($Plan.Items)) {
            $result = New-OperationResult -Status 'blocked' -Message $message `
                -Data ([pscustomobject][ordered]@{
                    ItemId = $item.Id
                    RollbackRequired = $false
                    RollbackCapability = $item.RollbackCapability
                })
            $results.Add($result)
        }
        return $results.ToArray()
    }

    foreach ($item in @($Plan.Items)) {
        if ($WhatIf) {
            $result = New-OperationResult -Status 'dry_run' `
                -Message "Deployment of '$($item.Id)' is planned; no changes were made." `
                -Data ([pscustomobject][ordered]@{
                    ItemId = $item.Id
                    PlannedStatus = 'planned'
                    RollbackRequired = $false
                    RollbackCapability = $item.RollbackCapability
                })
            $results.Add($result)
            $statusById[$item.Id] = $result.Status
            continue
        }

        $blockedDependencies = @(
            @($item.Dependencies) |
                Where-Object {
                    $null -ne $_ -and
                    $statusById.ContainsKey($_) -and
                    $statusById[$_] -ne 'succeeded'
                }
        )
        if ($blockedDependencies.Count -gt 0) {
            $result = New-OperationResult -Status 'blocked' `
                -Message (
                    "Deployment of '$($item.Id)' is blocked by dependency: " +
                    ($blockedDependencies -join ', ')
                ) `
                -Data ([pscustomobject][ordered]@{
                    ItemId = $item.Id
                    RollbackRequired = $false
                    RollbackCapability = $item.RollbackCapability
                })
            $results.Add($result)
            $statusById[$item.Id] = $result.Status
            continue
        }

        $itemExecutor = if ($null -ne $Executor) {
            $Executor
        }
        else {
            Get-DeploymentAdapter -AdapterMap $AdapterMap -Item $item
        }
        if ($null -eq $itemExecutor) {
            $result = New-OperationResult -Status 'blocked' `
                -Message "No deployment adapter is available for '$($item.Id)'." `
                -Data ([pscustomobject][ordered]@{
                    ItemId = $item.Id
                    RollbackRequired = $false
                    RollbackCapability = $item.RollbackCapability
                })
            $results.Add($result)
            $statusById[$item.Id] = $result.Status
            continue
        }

        try {
            $result = & $itemExecutor $item
            if (-not (Test-DeploymentObject -Value $result)) {
                throw 'Deployment executor returned an invalid OperationResult.'
            }
            foreach ($required in @('Status', 'Message', 'Data', 'Timestamp')) {
                if (-not (Get-DeploymentMember -InputObject $result `
                        -Name $required).Exists) {
                    throw (
                        "Deployment executor result is missing field '$required'."
                    )
                }
            }
            $result = [pscustomobject][ordered]@{
                Status = (Get-DeploymentMember -InputObject $result `
                        -Name 'Status').Value
                Message = Protect-DeploymentExceptionText -Text "$(
                    (Get-DeploymentMember -InputObject $result -Name 'Message').Value
                )"
                Data = (Get-DeploymentMember -InputObject $result `
                        -Name 'Data').Value
                Timestamp = (Get-DeploymentMember -InputObject $result `
                        -Name 'Timestamp').Value
            }
        }
        catch {
            $safeMessage = Protect-DeploymentExceptionText `
                -Text $_.Exception.Message
            $result = New-OperationResult -Status 'failed' `
                -Message $safeMessage `
                -Data ([pscustomobject][ordered]@{
                    ItemId = $item.Id
                    RollbackRequired = $true
                    RollbackCapability = $item.RollbackCapability
                })
        }

        $results.Add($result)
        $statusById[$item.Id] = "$($result.Status)".ToLowerInvariant()
    }

    return $results.ToArray()
}
