$deploymentLibraryRoot = $PSScriptRoot

if (-not ('Security.Cryptography.ProtectedData' -as [type])) {
    Add-Type -AssemblyName System.Security
}

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
        return $copy
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

function Copy-DeploymentArraySnapshot {
    param(
        [AllowNull()]
        [object]$Value
    )

    $items = New-Object System.Collections.Generic.List[object]
    if ($null -ne $Value) {
        $sourceItems = if ($Value -is [System.Array] -or
            ($Value -is [System.Collections.IList] -and $Value -isnot [string])) {
            @($Value)
        }
        else {
            @($Value)
        }
        foreach ($item in $sourceItems) {
            $items.Add((Copy-DeploymentValue -Value $item))
        }
    }
    return ,($items.ToArray())
}

function New-DeploymentApprovedSnapshot {
    param(
        [string]$Id,
        [object]$Tool,
        [object[]]$CredentialRefs,
        [object[]]$Conflicts,
        [object[]]$Dependencies,
        [object[]]$Permissions,
        [object[]]$ExternalChanges,
        [AllowNull()]
        [object]$RollbackCapability
    )

    return [pscustomobject][ordered]@{
        id = $Id
        name = Copy-DeploymentValue -Value (
            Get-DeploymentMember -InputObject $Tool -Name 'name'
        ).Value
        type = Copy-DeploymentValue -Value (
            Get-DeploymentMember -InputObject $Tool -Name 'type'
        ).Value
        source = Copy-DeploymentValue -Value (
            Get-DeploymentMember -InputObject $Tool -Name 'source'
        ).Value
        version = Copy-DeploymentValue -Value (
            Get-DeploymentMember -InputObject $Tool -Name 'version'
        ).Value
        sha256 = Copy-DeploymentValue -Value (
            Get-DeploymentMember -InputObject $Tool -Name 'sha256'
        ).Value
        license = Copy-DeploymentValue -Value (
            Get-DeploymentMember -InputObject $Tool -Name 'license'
        ).Value
        approval = Copy-DeploymentValue -Value (
            Get-DeploymentMember -InputObject $Tool -Name 'approval'
        ).Value
        risk = Copy-DeploymentValue -Value (
            Get-DeploymentMember -InputObject $Tool -Name 'risk'
        ).Value
        install_target = Copy-DeploymentValue -Value (
            Get-DeploymentMember -InputObject $Tool -Name 'install_target'
        ).Value
        credential_refs = Copy-DeploymentArraySnapshot -Value $CredentialRefs
        conflicts = Copy-DeploymentArraySnapshot -Value $Conflicts
        dependencies = Copy-DeploymentArraySnapshot -Value $Dependencies
        permissions = Copy-DeploymentArraySnapshot -Value $Permissions
        external_changes = Copy-DeploymentArraySnapshot -Value $ExternalChanges
        rollback_capability = Copy-DeploymentValue -Value $RollbackCapability
    }
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

function ConvertTo-DeploymentPlanIntegrityPayload {
    param(
        [object]$Plan
    )

    $items = @((Get-DeploymentMember -InputObject $Plan -Name 'Items').Value |
        ForEach-Object {
            [pscustomobject][ordered]@{
                Id = (Get-DeploymentMember -InputObject $_ -Name 'Id').Value
                Name = (Get-DeploymentMember -InputObject $_ -Name 'Name').Value
                Type = (Get-DeploymentMember -InputObject $_ -Name 'Type').Value
                Source = (Get-DeploymentMember -InputObject $_ -Name 'Source').Value
                Version = (Get-DeploymentMember -InputObject $_ -Name 'Version').Value
                Hash = (Get-DeploymentMember -InputObject $_ -Name 'Hash').Value
                License = (Get-DeploymentMember -InputObject $_ -Name 'License').Value
                Risk = (Get-DeploymentMember -InputObject $_ -Name 'Risk').Value
                Target = (Get-DeploymentMember -InputObject $_ -Name 'Target').Value
                Permissions = @((Get-DeploymentMember -InputObject $_ `
                        -Name 'Permissions').Value)
                CredentialRefs = @((Get-DeploymentMember -InputObject $_ `
                        -Name 'CredentialRefs').Value)
                Conflicts = @((Get-DeploymentMember -InputObject $_ `
                        -Name 'Conflicts').Value)
                Dependencies = @((Get-DeploymentMember -InputObject $_ `
                        -Name 'Dependencies').Value)
                ExternalChanges = @((Get-DeploymentMember -InputObject $_ `
                        -Name 'ExternalChanges').Value)
                RollbackCapability = (Get-DeploymentMember -InputObject $_ `
                    -Name 'RollbackCapability').Value
                Approval = (Get-DeploymentMember -InputObject $_ `
                    -Name 'Approval').Value
                Status = (Get-DeploymentMember -InputObject $_ -Name 'Status').Value
                ApprovedSnapshot = Copy-DeploymentValue -Value (
                    Get-DeploymentMember -InputObject $_ -Name 'ApprovedSnapshot'
                ).Value
            }
        })

    return [pscustomobject][ordered]@{
        SchemaVersion = (Get-DeploymentMember -InputObject $Plan `
            -Name 'SchemaVersion').Value
        Status = (Get-DeploymentMember -InputObject $Plan -Name 'Status').Value
        CredentialMetadataNames = @((Get-DeploymentMember -InputObject $Plan `
                -Name 'CredentialMetadataNames').Value)
        Items = $items
        Errors = @((Get-DeploymentMember -InputObject $Plan -Name 'Errors').Value)
        Warnings = @((Get-DeploymentMember -InputObject $Plan -Name 'Warnings').Value)
    }
}

function Get-DeploymentPlanIntegrity {
    param(
        [object]$Plan
    )

    $payload = ConvertTo-DeploymentPlanIntegrityPayload -Plan $Plan
    $json = $payload | ConvertTo-Json -Depth 20 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha256.ComputeHash($bytes)
    }
    finally {
        $sha256.Dispose()
    }
    return (($hash | ForEach-Object { $_.ToString('x2') }) -join '')
}

function Get-DeploymentPlanIntegrityEntropy {
    return [Text.Encoding]::UTF8.GetBytes(
        'codex.deployment.plan.integrity.v1'
    )
}

$script:ProtectDeploymentPlanIntegrity = {
    param([string]$Digest)

    $plainBytes = [Text.Encoding]::UTF8.GetBytes($Digest)
    $protectedBytes = [Security.Cryptography.ProtectedData]::Protect(
        $plainBytes,
        (Get-DeploymentPlanIntegrityEntropy),
        [Security.Cryptography.DataProtectionScope]::CurrentUser
    )
    return [Convert]::ToBase64String($protectedBytes)
}

$script:UnprotectDeploymentPlanIntegrity = {
    param([AllowNull()][object]$ProtectedDigest)

    if ($ProtectedDigest -isnot [string] -or
        [string]::IsNullOrWhiteSpace($ProtectedDigest)) {
        return $null
    }

    try {
        $protectedBytes = [Convert]::FromBase64String($ProtectedDigest)
        $plainBytes = [Security.Cryptography.ProtectedData]::Unprotect(
            $protectedBytes,
            (Get-DeploymentPlanIntegrityEntropy),
            [Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        return [Text.Encoding]::UTF8.GetString($plainBytes)
    }
    catch {
        return $null
    }
}

function Add-DeploymentPlanStringError {
    param(
        [System.Collections.Generic.List[string]]$Errors,
        [string]$ItemId,
        [string]$Field,
        [AllowNull()]
        [object]$Value
    )

    if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace($Value)) {
        Add-DeploymentValidationError -Errors $Errors `
            -Message "Deployment plan item '$ItemId' field '$Field' must be a non-empty string."
    }
}

function Get-DeploymentPlanStringArray {
    param(
        [System.Collections.Generic.List[string]]$Errors,
        [object]$Item,
        [string]$ItemId,
        [string]$Field
    )

    $member = Get-DeploymentMember -InputObject $Item -Name $Field
    if ($member.Value -isnot [System.Array]) {
        Add-DeploymentValidationError -Errors $Errors `
            -Message "Deployment plan item '$ItemId' field '$Field' must be an array."
        return @()
    }

    $values = @()
    for ($index = 0; $index -lt $member.Value.Count; $index++) {
        $value = $member.Value[$index]
        if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) {
            Add-DeploymentValidationError -Errors $Errors `
                -Message (
                    "Deployment plan item '$ItemId' field '$Field[$index]' " +
                    'must be a non-empty string.'
                )
            continue
        }
        $values += $value
    }
    return $values
}

function Test-DeploymentStringArrayEqual {
    param(
        [AllowNull()]
        [object]$Left,
        [AllowNull()]
        [object]$Right
    )

    if ($Left -isnot [System.Array] -or $Right -isnot [System.Array]) {
        return $false
    }
    if ($Left.Count -ne $Right.Count) {
        return $false
    }
    for ($index = 0; $index -lt $Left.Count; $index++) {
        if ($Left[$index] -cne $Right[$index]) {
            return $false
        }
    }
    return $true
}

function Add-DeploymentSnapshotMismatch {
    param(
        [System.Collections.Generic.List[string]]$Errors,
        [string]$ItemId,
        [string]$Field
    )

    Add-DeploymentValidationError -Errors $Errors -Message (
        "Deployment plan item '$ItemId' field '$Field' does not match " +
        'the ApprovedSnapshot.'
    )
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
    $credentialNameList = New-Object System.Collections.Generic.List[string]
    foreach ($metadata in @($CredentialMetadata)) {
        if (-not (Test-DeploymentObject -Value $metadata)) {
            continue
        }
        $nameMember = Get-DeploymentMember -InputObject $metadata -Name 'Name'
        if ($nameMember.Exists -and $nameMember.Value -is [string] -and
            -not [string]::IsNullOrWhiteSpace($nameMember.Value)) {
            if (-not $credentialNames.ContainsKey($nameMember.Value)) {
                $credentialNames[$nameMember.Value] = $true
                $credentialNameList.Add($nameMember.Value)
            }
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
        $license = Get-DeploymentMember -InputObject $tool -Name 'license'
        $risk = Get-DeploymentMember -InputObject $tool -Name 'risk'
        $permissionsCopy = Copy-DeploymentArraySnapshot -Value $permissions
        $credentialRefsCopy = Copy-DeploymentArraySnapshot -Value $credentialRefs
        $conflictsCopy = Copy-DeploymentArraySnapshot -Value $conflicts
        $dependenciesCopy = Copy-DeploymentArraySnapshot -Value $dependencies
        $externalChangesCopy = Copy-DeploymentArraySnapshot -Value $externalChanges
        $approvedSnapshot = New-DeploymentApprovedSnapshot -Id $id `
            -Tool $tool `
            -CredentialRefs $credentialRefs `
            -Conflicts $conflicts `
            -Dependencies $dependencies `
            -Permissions $permissions `
            -ExternalChanges $externalChanges `
            -RollbackCapability $rollbackCapability
        $item = [pscustomobject][ordered]@{
            Id = $id
            Name = Copy-DeploymentValue -Value $name.Value
            Type = Copy-DeploymentValue -Value $type.Value
            Source = Copy-DeploymentValue -Value $source.Value
            Version = Copy-DeploymentValue -Value $version.Value
            Hash = Copy-DeploymentValue -Value $hash.Value
            License = Copy-DeploymentValue -Value $license.Value
            Risk = Copy-DeploymentValue -Value $risk.Value
            Target = Copy-DeploymentValue -Value $target.Value
            Permissions = $permissionsCopy
            CredentialRefs = $credentialRefsCopy
            Conflicts = $conflictsCopy
            Dependencies = $dependenciesCopy
            ExternalChanges = $externalChangesCopy
            RollbackCapability = Copy-DeploymentValue `
                -Value $rollbackCapability
            Approval = Copy-DeploymentValue -Value $approval.Value
            Status = 'planned'
            ApprovedSnapshot = $approvedSnapshot
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

    $plan = [pscustomobject][ordered]@{
        SchemaVersion = '1.0'
        Status = 'planned'
        CredentialMetadataNames = $credentialNameList.ToArray()
        Items = $orderedItems.ToArray()
        Errors = $errors.ToArray()
        Warnings = $warnings.ToArray()
        PlanIntegrity = $null
        ProtectedPlanIntegrity = $null
    }
    $plan.PlanIntegrity = Get-DeploymentPlanIntegrity -Plan $plan
    $plan.ProtectedPlanIntegrity = & $script:ProtectDeploymentPlanIntegrity `
        -Digest $plan.PlanIntegrity
    return $plan
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

    foreach ($required in @(
            'SchemaVersion', 'Status', 'Items', 'Errors', 'Warnings',
            'CredentialMetadataNames', 'ProtectedPlanIntegrity'
        )) {
        $member = Get-DeploymentMember -InputObject $Plan -Name $required
        if (-not $member.Exists) {
            throw "Deployment plan is missing required field '$required'."
        }
    }

    $items = (Get-DeploymentMember -InputObject $Plan -Name 'Items').Value
    $storedErrors = (Get-DeploymentMember -InputObject $Plan -Name 'Errors').Value
    $warnings = (Get-DeploymentMember -InputObject $Plan -Name 'Warnings').Value
    $credentialMetadataNames = (Get-DeploymentMember -InputObject $Plan `
            -Name 'CredentialMetadataNames').Value
    if ($items -isnot [System.Array] -or
        $storedErrors -isnot [System.Array] -or
        $warnings -isnot [System.Array] -or
        $credentialMetadataNames -isnot [System.Array]) {
        throw (
            'Deployment plan Items, Errors, Warnings, and ' +
            'CredentialMetadataNames must be arrays.'
        )
    }

    $errors = New-Object System.Collections.Generic.List[string]
    foreach ($errorText in $storedErrors) {
        Add-DeploymentValidationError -Errors $errors -Message "$errorText"
    }

    $credentialNameSet = @{}
    for ($index = 0; $index -lt $credentialMetadataNames.Count; $index++) {
        $name = $credentialMetadataNames[$index]
        if ($name -isnot [string] -or [string]::IsNullOrWhiteSpace($name)) {
            Add-DeploymentValidationError -Errors $errors `
                -Message (
                    "Deployment plan CredentialMetadataNames[$index] " +
                    'must be a non-empty string.'
                )
            continue
        }
        $credentialNameSet[$name] = $true
    }

    $schemaVersion = (Get-DeploymentMember -InputObject $Plan `
            -Name 'SchemaVersion').Value
    if ($schemaVersion -cne '1.0') {
        Add-DeploymentValidationError -Errors $errors `
            -Message 'Deployment plan SchemaVersion is invalid.'
    }
    $status = (Get-DeploymentMember -InputObject $Plan -Name 'Status').Value
    if ($status -cne 'planned') {
        Add-DeploymentValidationError -Errors $errors `
            -Message 'Deployment plan Status must be planned.'
    }

    $itemIds = @{}
    $dependencyMap = @{}
    $conflictMap = @{}
    $currentOrder = New-Object System.Collections.Generic.List[string]
    foreach ($item in $items) {
        if (-not (Test-DeploymentObject -Value $item)) {
            throw 'Deployment plan contains a damaged item.'
        }
        foreach ($required in @(
                'Id', 'Type', 'Source', 'Version', 'Hash', 'Target',
                'Permissions', 'CredentialRefs', 'Conflicts', 'Dependencies',
                'ExternalChanges', 'RollbackCapability', 'Approval', 'Status',
                'License', 'Risk', 'ApprovedSnapshot'
            )) {
            if (-not (Get-DeploymentMember -InputObject $item `
                    -Name $required).Exists) {
                throw "Deployment plan item is missing required field '$required'."
            }
        }

        $id = (Get-DeploymentMember -InputObject $item -Name 'Id').Value
        $labelId = if ($id -is [string] -and
            -not [string]::IsNullOrWhiteSpace($id)) {
            $id
        }
        else {
            '<invalid>'
        }
        Add-DeploymentPlanStringError -Errors $errors -ItemId $labelId `
            -Field 'Id' -Value $id
        if ($id -is [string] -and -not [string]::IsNullOrWhiteSpace($id)) {
            if ($itemIds.ContainsKey($id)) {
                Add-DeploymentValidationError -Errors $errors `
                    -Message "Deployment plan item '$id' is duplicated."
            }
            else {
                $itemIds[$id] = $item
                $currentOrder.Add($id)
            }
        }

        foreach ($field in @(
                'Source', 'Version', 'Target', 'RollbackCapability',
                'License', 'Risk'
            )) {
            Add-DeploymentPlanStringError -Errors $errors -ItemId $labelId `
                -Field $field `
                -Value (Get-DeploymentMember -InputObject $item -Name $field).Value
        }

        $hash = (Get-DeploymentMember -InputObject $item -Name 'Hash').Value
        if ($hash -isnot [string] -or $hash -cnotmatch '^[0-9a-f]{64}$') {
            Add-DeploymentValidationError -Errors $errors `
                -Message (
                    "Deployment plan item '$labelId' field 'Hash' must be " +
                    '64 lowercase hexadecimal characters.'
                )
        }

        $type = (Get-DeploymentMember -InputObject $item -Name 'Type').Value
        if ($type -isnot [string] -or [string]::IsNullOrWhiteSpace($type) -or
            @('plugin', 'mcp', 'skill') -notcontains $type) {
            Add-DeploymentValidationError -Errors $errors `
                -Message (
                    "Deployment plan item '$labelId' field 'Type' must be " +
                    'plugin, mcp, or skill.'
                )
        }

        $approval = (Get-DeploymentMember -InputObject $item `
                -Name 'Approval').Value
        if ($approval -cne 'approved') {
            Add-DeploymentValidationError -Errors $errors `
                -Message "Deployment plan item '$($item.Id)' is not approved."
        }

        $itemStatus = (Get-DeploymentMember -InputObject $item `
                -Name 'Status').Value
        if ($itemStatus -cne 'planned') {
            Add-DeploymentValidationError -Errors $errors `
                -Message "Deployment plan item '$labelId' Status must be planned."
        }

        $itemArrayValues = @{}
        foreach ($arrayField in @(
                'Permissions', 'CredentialRefs', 'Conflicts', 'Dependencies',
                'ExternalChanges'
            )) {
            $values = @(Get-DeploymentPlanStringArray -Errors $errors `
                    -Item $item -ItemId $labelId -Field $arrayField)
            $itemArrayValues[$arrayField] = $values
            if ($arrayField -eq 'Dependencies') {
                $dependencyMap[$labelId] = $values
            }
            elseif ($arrayField -eq 'Conflicts') {
                $conflictMap[$labelId] = $values
            }
            elseif ($arrayField -eq 'CredentialRefs') {
                foreach ($credentialRef in $values) {
                    if (-not $credentialNameSet.ContainsKey($credentialRef)) {
                        Add-DeploymentValidationError -Errors $errors `
                            -Message (
                                "Deployment plan item '$labelId' CredentialRefs " +
                                "requires missing credential '$credentialRef'."
                            )
                    }
                }
            }
        }

        $approvedSnapshot = (Get-DeploymentMember -InputObject $item `
                -Name 'ApprovedSnapshot').Value
        if (-not (Test-DeploymentObject -Value $approvedSnapshot)) {
            Add-DeploymentValidationError -Errors $errors `
                -Message "Deployment plan item '$labelId' ApprovedSnapshot must be an object."
        }
        else {
            foreach ($requiredSnapshot in @(
                    'id', 'name', 'type', 'source', 'version', 'sha256',
                    'license', 'approval', 'risk', 'install_target',
                    'credential_refs', 'conflicts', 'dependencies',
                    'permissions', 'external_changes', 'rollback_capability'
                )) {
                if (-not (Get-DeploymentMember -InputObject $approvedSnapshot `
                        -Name $requiredSnapshot).Exists) {
                    Add-DeploymentValidationError -Errors $errors -Message (
                        "Deployment plan item '$labelId' ApprovedSnapshot " +
                        "is missing field '$requiredSnapshot'."
                    )
                }
            }

            $snapshotStringMap = [ordered]@{
                Id = 'id'
                Name = 'name'
                Type = 'type'
                Source = 'source'
                Version = 'version'
                Hash = 'sha256'
                License = 'license'
                Approval = 'approval'
                Risk = 'risk'
                Target = 'install_target'
                RollbackCapability = 'rollback_capability'
            }
            foreach ($itemField in $snapshotStringMap.Keys) {
                $snapshotField = $snapshotStringMap[$itemField]
                $itemValue = (Get-DeploymentMember -InputObject $item `
                        -Name $itemField).Value
                $snapshotValue = (Get-DeploymentMember `
                        -InputObject $approvedSnapshot `
                        -Name $snapshotField).Value
                if ($itemValue -cne $snapshotValue) {
                    Add-DeploymentSnapshotMismatch -Errors $errors `
                        -ItemId $labelId -Field $itemField
                }
            }

            $snapshotArrayMap = @{
                Permissions = 'permissions'
                CredentialRefs = 'credential_refs'
                Conflicts = 'conflicts'
                Dependencies = 'dependencies'
                ExternalChanges = 'external_changes'
            }
            foreach ($itemField in $snapshotArrayMap.Keys) {
                $snapshotField = $snapshotArrayMap[$itemField]
                $snapshotValue = (Get-DeploymentMember `
                        -InputObject $approvedSnapshot `
                        -Name $snapshotField).Value
                if (-not (Test-DeploymentStringArrayEqual `
                        -Left $itemArrayValues[$itemField] `
                        -Right $snapshotValue)) {
                    Add-DeploymentSnapshotMismatch -Errors $errors `
                        -ItemId $labelId -Field $itemField
                }
            }
        }
    }

    foreach ($itemId in $dependencyMap.Keys) {
        foreach ($dependency in @($dependencyMap[$itemId])) {
            if (-not $itemIds.ContainsKey($dependency)) {
                Add-DeploymentValidationError -Errors $errors `
                    -Message "Deployment plan item '$itemId' has missing dependency '$dependency'."
            }
        }
    }

    foreach ($leftId in $conflictMap.Keys) {
        foreach ($rightId in @($conflictMap[$leftId])) {
            if ($itemIds.ContainsKey($rightId)) {
                Add-DeploymentValidationError -Errors $errors `
                    -Message "Deployment plan items '$leftId' and '$rightId' conflict."
            }
        }
    }

    $orderedIds = @{}
    $stableOrder = New-Object System.Collections.Generic.List[string]
    while ($orderedIds.Count -lt $currentOrder.Count) {
        $madeProgress = $false
        foreach ($itemId in $currentOrder) {
            if ($orderedIds.ContainsKey($itemId)) {
                continue
            }
            $unresolved = @(
                @($dependencyMap[$itemId]) |
                    Where-Object {
                        $itemIds.ContainsKey($_) -and
                        -not $orderedIds.ContainsKey($_)
                    }
            )
            if ($unresolved.Count -eq 0) {
                $orderedIds[$itemId] = $true
                $stableOrder.Add($itemId)
                $madeProgress = $true
            }
        }
        if (-not $madeProgress) {
            $cycleIds = @(
                $itemIds.Keys |
                    Where-Object { -not $orderedIds.ContainsKey($_) }
            )
            Add-DeploymentValidationError -Errors $errors `
                -Message "Deployment plan dependency cycle detected among: $($cycleIds -join ', ')."
            break
        }
    }

    if ($stableOrder.Count -eq $currentOrder.Count) {
        for ($index = 0; $index -lt $currentOrder.Count; $index++) {
            if ($stableOrder[$index] -cne $currentOrder[$index]) {
                Add-DeploymentValidationError -Errors $errors -Message (
                    'Deployment plan item order is not the stable ' +
                    'topological dependency order.'
                )
                break
            }
        }
    }

    $protectedIntegrity = (Get-DeploymentMember -InputObject $Plan `
            -Name 'ProtectedPlanIntegrity').Value
    $unprotectedIntegrity = & $script:UnprotectDeploymentPlanIntegrity `
        -ProtectedDigest $protectedIntegrity
    if ($unprotectedIntegrity -isnot [string] -or
        $unprotectedIntegrity -cnotmatch '^[0-9a-f]{64}$') {
        Add-DeploymentValidationError -Errors $errors `
            -Message 'Deployment plan ProtectedPlanIntegrity is invalid.'
    }
    elseif ((Get-DeploymentPlanIntegrity -Plan $Plan) -cne
        $unprotectedIntegrity) {
        Add-DeploymentValidationError -Errors $errors -Message (
            'Deployment plan ProtectedPlanIntegrity does not match the ' +
            'current execution fields, credential metadata names, or item order.'
        )
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
