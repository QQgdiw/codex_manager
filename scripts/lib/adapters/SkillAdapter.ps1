$commonLibrary = Join-Path (Split-Path -Parent $PSScriptRoot) 'Common.ps1'
if (Test-Path -LiteralPath $commonLibrary -PathType Leaf) {
    . $commonLibrary
}

$verificationLibrary = Join-Path (Split-Path -Parent $PSScriptRoot) 'VerificationEngine.ps1'
if (Test-Path -LiteralPath $verificationLibrary -PathType Leaf) {
    . $verificationLibrary
}

function Get-SkillAdapterMember {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($name in $Names) {
            if ($InputObject.Contains($name)) {
                return $InputObject[$name]
            }
        }
        foreach ($key in @($InputObject.Keys)) {
            foreach ($name in $Names) {
                if ([string]::Equals("$key", $name, [StringComparison]::OrdinalIgnoreCase)) {
                    return $InputObject[$key]
                }
            }
        }
        return $null
    }

    foreach ($name in $Names) {
        $property = $InputObject.PSObject.Properties[$name]
        if ($null -ne $property) {
            return $property.Value
        }
    }
    foreach ($property in @($InputObject.PSObject.Properties)) {
        foreach ($name in $Names) {
            if ([string]::Equals($property.Name, $name, [StringComparison]::OrdinalIgnoreCase)) {
                return $property.Value
            }
        }
    }

    return $null
}

function Get-SkillAdapterString {
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    $value = Get-SkillAdapterMember -InputObject $InputObject -Names $Names
    if ($null -eq $value) {
        return $null
    }
    $text = "$value"
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }
    return $text
}

function Get-SkillAdapterArray {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return @()
    }
    if ($Value -is [string]) {
        return @($Value)
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        return @($Value)
    }
    return @($Value)
}

function Test-SkillAdapterSafeName {
    param([AllowNull()][string]$Value)

    return (
        -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value -match '^[A-Za-z0-9][A-Za-z0-9._-]*$'
    )
}

function Get-SkillAdapterSnapshot {
    param([AllowNull()][object]$Tool)

    return Get-SkillAdapterMember -InputObject $Tool `
        -Names @('ApprovedSnapshot', 'approved_snapshot')
}

function Protect-SkillAdapterText {
    param(
        [AllowNull()]
        [object]$Text,

        [AllowNull()]
        [string[]]$SensitiveValues = @()
    )

    $value = if ($null -eq $Text) { '' } else { "$Text" }
    if (Get-Command Protect-LogText -ErrorAction SilentlyContinue) {
        $value = Protect-LogText -Text $value -SensitiveValues $SensitiveValues
    }

    $value = $value -replace '(?i)auth\.json', '[REDACTED]'
    $value = [regex]::Replace(
        $value,
        '(?i)((?:"?(?:token|access_token|refresh_token|auth_token|api_key|secret|password|credential)"?)\s*[:=]\s*)("[^"]*"|[^\s,;}\]]+)',
        '$1[REDACTED]'
    )
    $value = [regex]::Replace($value, '(?i)\bSECRET-[A-Za-z0-9._-]+\b', '[REDACTED]')
    return $value
}

function Test-SkillAdapterPathWithinRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $rootFullPath = [IO.Path]::GetFullPath($Root).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $pathFullPath = [IO.Path]::GetFullPath($Path)

    return (
        [string]::Equals($pathFullPath, $rootFullPath, [StringComparison]::OrdinalIgnoreCase) -or
        $pathFullPath.StartsWith(
            $rootFullPath + [IO.Path]::DirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase
        ) -or
        $pathFullPath.StartsWith(
            $rootFullPath + [IO.Path]::AltDirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase
        )
    )
}

function ConvertTo-SkillAdapterHex {
    param([byte[]]$Bytes)

    return ([BitConverter]::ToString($Bytes) -replace '-', '').ToLowerInvariant()
}

function Test-SkillAdapterReparsePoint {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Item
    )

    return (($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
}

function Assert-SkillAdapterPathIsNotReparsePoint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    if (Test-SkillAdapterReparsePoint -Item $item) {
        throw "$Label must not be a reparse point, symbolic link, or junction."
    }
}

function Assert-SkillAdapterTreeHasNoReparsePoint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    Assert-SkillAdapterPathIsNotReparsePoint -Path $Path -Label $Label
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return
    }

    $pending = New-Object System.Collections.Generic.Stack[string]
    $pending.Push([IO.Path]::GetFullPath($Path))
    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        foreach ($item in @(Get-ChildItem -LiteralPath $current -Force -ErrorAction Stop)) {
            if (Test-SkillAdapterReparsePoint -Item $item) {
                throw "$Label must not contain reparse points, symbolic links, or junctions."
            }
            if ($item.PSIsContainer) {
                $pending.Push($item.FullName)
            }
        }
    }
}

function Get-SkillSourceHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath
    )

    $sourceFullPath = [IO.Path]::GetFullPath($SourcePath)
    if (-not (Test-Path -LiteralPath $sourceFullPath -PathType Container)) {
        throw 'Skill source_path must be an existing directory.'
    }
    Assert-SkillAdapterTreeHasNoReparsePoint -Path $sourceFullPath -Label 'Skill source_path tree'

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $entries = New-Object System.Collections.Generic.List[string]
        $files = @(
            Get-ChildItem -LiteralPath $sourceFullPath -Recurse -Force |
                Where-Object { -not $_.PSIsContainer } |
                Sort-Object FullName
        )
        foreach ($file in $files) {
            $fileFullPath = [IO.Path]::GetFullPath($file.FullName)
            if (-not (Test-SkillAdapterPathWithinRoot -Path $fileFullPath -Root $sourceFullPath)) {
                throw 'Skill source contains a file outside the source root.'
            }
            $relative = $fileFullPath.Substring(
                $sourceFullPath.TrimEnd(
                    [IO.Path]::DirectorySeparatorChar,
                    [IO.Path]::AltDirectorySeparatorChar
                ).Length
            ).TrimStart(
                [IO.Path]::DirectorySeparatorChar,
                [IO.Path]::AltDirectorySeparatorChar
            ).Replace('\', '/')
            $fileBytes = [IO.File]::ReadAllBytes($fileFullPath)
            $fileHash = ConvertTo-SkillAdapterHex -Bytes ($sha.ComputeHash($fileBytes))
            [void]$entries.Add("$relative`n$fileHash")
        }

        $manifest = [string]::Join("`n", $entries.ToArray())
        $manifestBytes = [Text.Encoding]::UTF8.GetBytes($manifest)
        return ConvertTo-SkillAdapterHex -Bytes ($sha.ComputeHash($manifestBytes))
    }
    finally {
        $sha.Dispose()
    }
}

function Get-SkillFrontMatter {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    $content = [IO.File]::ReadAllText($ManifestPath)
    $lines = $content -split "`r?`n"
    if ($lines.Count -lt 3 -or $lines[0].Trim() -ne '---') {
        return [pscustomobject][ordered]@{
            Metadata = @{}
            Error = 'SKILL.md must start with YAML front matter.'
        }
    }

    $metadata = @{}
    $closed = $false
    for ($i = 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line.Trim() -eq '---') {
            $closed = $true
            break
        }
        if ($line -match '^\s*([A-Za-z0-9_-]+)\s*:\s*(.*?)\s*$') {
            $value = $Matches[2].Trim()
            $value = $value.Trim('"').Trim("'")
            $metadata[$Matches[1].ToLowerInvariant()] = $value
        }
    }

    if (-not $closed) {
        return [pscustomobject][ordered]@{
            Metadata = $metadata
            Error = 'SKILL.md YAML front matter must be closed.'
        }
    }
    foreach ($required in @('name', 'description')) {
        if (-not $metadata.ContainsKey($required) -or [string]::IsNullOrWhiteSpace($metadata[$required])) {
            return [pscustomobject][ordered]@{
                Metadata = $metadata
                Error = "SKILL.md YAML front matter must include '$required'."
            }
        }
    }

    return [pscustomobject][ordered]@{
        Metadata = [pscustomobject][ordered]@{
            name = $metadata['name']
            description = $metadata['description']
        }
        Error = $null
    }
}

function Get-SkillManifestRelativeReferences {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    $content = [IO.File]::ReadAllText($ManifestPath)
    $items = New-Object System.Collections.Generic.List[string]

    foreach ($match in [regex]::Matches($content, '\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Trim()
        if ($target -match '^[A-Za-z][A-Za-z0-9+.-]*:' -or $target.StartsWith('#')) {
            continue
        }
        $target = ($target -split '#')[0].Trim()
        if (-not [string]::IsNullOrWhiteSpace($target)) {
            [void]$items.Add($target)
        }
    }

    foreach ($match in [regex]::Matches(
            $content,
            '(?<![A-Za-z0-9._/\\-])scripts[\\/][A-Za-z0-9._/\\-]+\.(ps1|js|mjs|cjs|py|sh|cmd|bat)'
        )) {
        [void]$items.Add($match.Value)
    }

    return @($items.ToArray() | Select-Object -Unique)
}

function Resolve-SkillRelativeFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,

        [Parameter(Mandatory = $true)]
        [string]$Kind
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return [pscustomobject][ordered]@{
            Path = $null
            Error = "$Kind path must not be empty."
        }
    }
    if ([IO.Path]::IsPathRooted($RelativePath)) {
        return [pscustomobject][ordered]@{
            Path = $null
            Error = "$Kind path must be relative to source_path."
        }
    }

    $sourceFullPath = [IO.Path]::GetFullPath($SourceRoot)
    $fullPath = [IO.Path]::GetFullPath((Join-Path $sourceFullPath $RelativePath))
    if (-not (Test-SkillAdapterPathWithinRoot -Path $fullPath -Root $sourceFullPath)) {
        return [pscustomobject][ordered]@{
            Path = $null
            Error = "$Kind path must stay within source_path."
        }
    }
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        return [pscustomobject][ordered]@{
            Path = $null
            Error = "$Kind path does not exist."
        }
    }

    return [pscustomobject][ordered]@{
        Path = $fullPath
        Error = $null
    }
}

function New-SkillApprovedSnapshotSummary {
    param([AllowNull()][object]$Snapshot)

    if ($null -eq $Snapshot) {
        return $null
    }

    return [pscustomobject][ordered]@{
        id = Get-SkillAdapterString -InputObject $Snapshot -Names @('id', 'Id')
        name = Get-SkillAdapterString -InputObject $Snapshot -Names @('name', 'Name')
        type = Get-SkillAdapterString -InputObject $Snapshot -Names @('type', 'Type')
        source = Get-SkillAdapterString -InputObject $Snapshot -Names @('source', 'Source')
        version = Get-SkillAdapterString -InputObject $Snapshot -Names @('version', 'Version')
        sha256 = Get-SkillAdapterString -InputObject $Snapshot -Names @('sha256', 'Hash')
        skill_id = Get-SkillAdapterString -InputObject $Snapshot -Names @('skill_id', 'SkillId')
    }
}

function New-SkillAdapterFailedPlan {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Errors,

        [AllowNull()]
        [object]$Snapshot
    )

    $summary = New-SkillApprovedSnapshotSummary -Snapshot $Snapshot
    return [pscustomobject][ordered]@{
        Status = 'failed'
        Message = "Skill adapter validation failed: $($Errors -join '; ')"
        Errors = @($Errors)
        ApprovedSnapshot = $summary
        Id = if ($null -eq $summary) { $null } else { $summary.id }
        Name = if ($null -eq $summary) { $null } else { $summary.name }
        Type = if ($null -eq $summary) { $null } else { $summary.type }
        Source = if ($null -eq $summary) { $null } else { $summary.source }
        Version = if ($null -eq $summary) { $null } else { $summary.version }
        SkillId = if ($null -eq $summary) { $null } else { $summary.skill_id }
        Sha256 = if ($null -eq $summary) { $null } else { $summary.sha256 }
        SourcePath = $null
        TargetRoot = $null
        TargetPath = $null
        ManifestPath = $null
        ManifestMetadata = $null
        SourceHash = $null
        SensitiveRedactions = @()
    }
}

function Get-SkillInstallPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Tool
    )

    $snapshot = Get-SkillAdapterSnapshot -Tool $Tool
    $errors = New-Object System.Collections.Generic.List[string]
    if ($null -eq $snapshot) {
        [void]$errors.Add('ApprovedSnapshot is required for Skill planning.')
        return New-SkillAdapterFailedPlan -Errors $errors.ToArray() -Snapshot $snapshot
    }

    $id = Get-SkillAdapterString -InputObject $snapshot -Names @('id', 'Id')
    $type = Get-SkillAdapterString -InputObject $snapshot -Names @('type', 'Type')
    $name = Get-SkillAdapterString -InputObject $snapshot -Names @('name', 'Name')
    $source = Get-SkillAdapterString -InputObject $snapshot -Names @('source', 'Source')
    $version = Get-SkillAdapterString -InputObject $snapshot -Names @('version', 'Version')
    $sha256 = Get-SkillAdapterString -InputObject $snapshot -Names @('sha256', 'Hash')
    $expectedHash = Get-SkillAdapterString -InputObject $snapshot `
        -Names @('expected_source_hash', 'ExpectedSourceHash')
    if ($null -eq $expectedHash) {
        $expectedHash = $sha256
    }
    $approval = Get-SkillAdapterString -InputObject $snapshot -Names @('approval', 'Approval')
    $skillId = Get-SkillAdapterString -InputObject $snapshot -Names @('skill_id', 'SkillId')
    $sourcePath = Get-SkillAdapterString -InputObject $snapshot -Names @('source_path', 'SourcePath')
    $workspaceRoot = Get-SkillAdapterString -InputObject $snapshot `
        -Names @('managed_workspace_root', 'ManagedWorkspaceRoot')
    $skillManifest = Get-SkillAdapterString -InputObject $snapshot `
        -Names @('skill_manifest', 'SkillManifest')
    $targetRootInput = Get-SkillAdapterString -InputObject $snapshot `
        -Names @('target_root', 'TargetRoot')
    $targetSubdir = Get-SkillAdapterString -InputObject $snapshot `
        -Names @('target_subdir', 'TargetSubdir')

    foreach ($required in @(
            @{ Name = 'id'; Value = $id },
            @{ Name = 'type'; Value = $type },
            @{ Name = 'name'; Value = $name },
            @{ Name = 'source'; Value = $source },
            @{ Name = 'version'; Value = $version },
            @{ Name = 'sha256'; Value = $sha256 },
            @{ Name = 'approval'; Value = $approval },
            @{ Name = 'skill_id'; Value = $skillId },
            @{ Name = 'source_path'; Value = $sourcePath },
            @{ Name = 'managed_workspace_root'; Value = $workspaceRoot },
            @{ Name = 'skill_manifest'; Value = $skillManifest }
        )) {
        if ([string]::IsNullOrWhiteSpace($required.Value)) {
            [void]$errors.Add("Missing required whitelist field '$($required.Name)'.")
        }
    }

    if ($null -ne $type -and $type -ne 'skill') {
        [void]$errors.Add("ApprovedSnapshot type must be 'skill'.")
    }
    if ($null -ne $skillId -and -not (Test-SkillAdapterSafeName -Value $skillId)) {
        [void]$errors.Add('skill_id must contain only safe characters.')
    }
    if ($null -ne $skillManifest) {
        if ([IO.Path]::IsPathRooted($skillManifest) -or $skillManifest -ne 'SKILL.md') {
            [void]$errors.Add("skill_manifest must be the relative path 'SKILL.md'.")
        }
    }
    if ($null -ne $targetRootInput) {
        [void]$errors.Add('target_root is not supported; Skills install target is fixed under managed_workspace_root.')
    }

    $sourceFullPath = $null
    $manifestPath = $null
    $manifestMetadata = $null
    $sourceHash = $null
    if ($errors.Count -eq 0) {
        $sourceFullPath = [IO.Path]::GetFullPath($sourcePath)
        if (-not (Test-Path -LiteralPath $sourceFullPath -PathType Container)) {
            [void]$errors.Add('source_path must be an existing directory.')
        }
        else {
            try {
                Assert-SkillAdapterTreeHasNoReparsePoint `
                    -Path $sourceFullPath `
                    -Label 'Skill source_path tree'
            }
            catch {
                [void]$errors.Add($_.Exception.Message)
            }
        }
        if ($errors.Count -eq 0) {
            $manifestPath = [IO.Path]::GetFullPath((Join-Path $sourceFullPath $skillManifest))
            if (-not (Test-SkillAdapterPathWithinRoot -Path $manifestPath -Root $sourceFullPath)) {
                [void]$errors.Add('skill_manifest must stay within source_path.')
            }
            elseif (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
                [void]$errors.Add('SKILL.md manifest does not exist.')
            }
            else {
                $frontMatter = Get-SkillFrontMatter -ManifestPath $manifestPath
                if ($null -ne $frontMatter.Error) {
                    [void]$errors.Add($frontMatter.Error)
                }
                else {
                    $manifestMetadata = $frontMatter.Metadata
                }
            }
        }
    }

    if ($errors.Count -eq 0) {
        $declaredReferences = @(
            Get-SkillAdapterArray -Value (
                Get-SkillAdapterMember -InputObject $snapshot `
                    -Names @('references', 'References', 'relative_references', 'RelativeReferences')
            ) |
                ForEach-Object { [string]$_ }
        )
        $declaredScripts = @(
            Get-SkillAdapterArray -Value (
                Get-SkillAdapterMember -InputObject $snapshot `
                    -Names @('scripts', 'Scripts', 'script_paths', 'ScriptPaths')
            ) |
                ForEach-Object { [string]$_ }
        )
        $manifestReferences = @(Get-SkillManifestRelativeReferences -ManifestPath $manifestPath)

        foreach ($reference in @($declaredReferences + $manifestReferences)) {
            $resolved = Resolve-SkillRelativeFile -RelativePath $reference `
                -SourceRoot $sourceFullPath `
                -Kind 'reference'
            if ($null -ne $resolved.Error) {
                [void]$errors.Add($resolved.Error)
            }
        }
        foreach ($script in $declaredScripts) {
            $resolved = Resolve-SkillRelativeFile -RelativePath $script `
                -SourceRoot $sourceFullPath `
                -Kind 'script'
            if ($null -ne $resolved.Error) {
                [void]$errors.Add($resolved.Error)
            }
        }
    }

    $workspaceFullPath = $null
    $targetRoot = $null
    $targetPath = $null
    if ($errors.Count -eq 0) {
        $workspaceFullPath = [IO.Path]::GetFullPath($workspaceRoot)
        if ($null -ne $targetSubdir -and [IO.Path]::IsPathRooted($targetSubdir)) {
            [void]$errors.Add('target_subdir must be relative.')
        }
        else {
            $allowedSkillsRoot = [IO.Path]::GetFullPath((Join-Path $workspaceFullPath 'Skills'))
            if ($null -ne $targetSubdir) {
                $targetSubdirPath = [IO.Path]::GetFullPath((Join-Path $workspaceFullPath $targetSubdir))
                if (-not (Test-SkillAdapterPathWithinRoot -Path $targetSubdirPath -Root $allowedSkillsRoot)) {
                    [void]$errors.Add('target_subdir must stay within the managed workspace Skills directory.')
                }
            }
            $targetRoot = $allowedSkillsRoot
            $targetPath = [IO.Path]::GetFullPath((Join-Path $targetRoot $skillId))
            if (-not (Test-SkillAdapterPathWithinRoot -Path $targetPath -Root $allowedSkillsRoot)) {
                [void]$errors.Add('target must stay within the managed workspace Skills directory.')
                $targetPath = $null
            }
        }
    }

    if ($errors.Count -eq 0) {
        try {
            $sourceHash = Get-SkillSourceHash -SourcePath $sourceFullPath
        }
        catch {
            [void]$errors.Add('Skill source hash could not be computed.')
        }
        if ($null -ne $sourceHash -and
            -not [string]::Equals($sourceHash, $expectedHash, [StringComparison]::OrdinalIgnoreCase)) {
            [void]$errors.Add('Skill source sha256 hash does not match the approved snapshot.')
        }
    }

    if ($errors.Count -gt 0) {
        return New-SkillAdapterFailedPlan -Errors $errors.ToArray() -Snapshot $snapshot
    }

    $redactions = @(
        Get-SkillAdapterArray -Value (
            Get-SkillAdapterMember -InputObject $snapshot `
                -Names @('sensitive_redactions', 'SensitiveRedactions')
        ) |
            Where-Object { -not [string]::IsNullOrEmpty([string]$_) } |
            ForEach-Object { [string]$_ }
    )

    return [pscustomobject][ordered]@{
        Status = 'planned'
        Message = "Managed Skill '$skillId' install is planned."
        Errors = @()
        ApprovedSnapshot = New-SkillApprovedSnapshotSummary -Snapshot $snapshot
        Id = $id
        Name = $name
        Type = $type
        Source = $source
        Version = $version
        Sha256 = $sha256
        Approval = $approval
        SkillId = $skillId
        SourcePath = $sourceFullPath
        ManagedWorkspaceRoot = $workspaceFullPath
        TargetRoot = $targetRoot
        TargetPath = $targetPath
        ManifestPath = $manifestPath
        ManifestMetadata = $manifestMetadata
        SourceHash = $sourceHash
        ActivationAsserted = $false
        SensitiveRedactions = @($redactions)
    }
}

function Get-SkillResultRedactions {
    param([AllowNull()][object]$Plan)

    return @(
        Get-SkillAdapterArray -Value $Plan.SensitiveRedactions
        $Plan.SourcePath
        $Plan.TargetRoot
        $Plan.TargetPath
        $Plan.ManagedWorkspaceRoot
        'auth.json'
        'raw exception'
    ) | Where-Object { -not [string]::IsNullOrEmpty([string]$_) } | ForEach-Object { [string]$_ }
}

function Get-SkillVerifierResultValue {
    param(
        [AllowNull()]
        [object]$Result,

        [Parameter(Mandatory = $true)]
        [string[]]$Names,

        [AllowNull()]
        [object]$DefaultValue = $null
    )

    if ($null -eq $Result) {
        return $DefaultValue
    }

    foreach ($name in $Names) {
        $property = $Result.PSObject.Properties[$name]
        if ($null -ne $property) {
            return $property.Value
        }
    }

    return $DefaultValue
}

function ConvertTo-SkillVerificationResult {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Plan,

        [AllowNull()]
        [object]$VerifierResult
    )

    $status = [string](Get-SkillVerifierResultValue `
            -Result $VerifierResult `
            -Names @('Status', 'status') `
            -DefaultValue 'failed')
    $message = [string](Get-SkillVerifierResultValue `
            -Result $VerifierResult `
            -Names @('Message', 'message') `
            -DefaultValue 'Verifier did not return a message.')
    $checks = @(Get-SkillAdapterArray -Value (
            Get-SkillVerifierResultValue `
                -Result $VerifierResult `
                -Names @('Checks', 'checks') `
                -DefaultValue @()
        ))
    $errorCode = Get-SkillVerifierResultValue `
        -Result $VerifierResult `
        -Names @('ErrorCode', 'error_code', 'errorCode') `
        -DefaultValue $null

    return New-SkillVerificationResult -Plan $Plan `
        -Status $status `
        -Message $message `
        -Checks $checks `
        -ErrorCode $errorCode
}

function Add-SkillJournalIntent {
    param(
        [AllowNull()]
        [object]$Plan,

        [AllowNull()]
        [object]$Journal
    )

    if ($null -eq $Journal) {
        return
    }

    $entry = [pscustomobject][ordered]@{
        Type = 'ExternalChange'
        Description = "Managed Skill install will replace workspace skill '$($Plan.SkillId)'."
        RollbackCommand = ''
        Plan = [pscustomobject][ordered]@{
            SkillId = $Plan.SkillId
            SourceHash = $Plan.SourceHash
            ActivationAsserted = $false
        }
    }

    $callback = Get-SkillAdapterMember -InputObject $Journal -Names @('AddExternalChange')
    if ($callback -is [scriptblock]) {
        & $callback $entry
        return
    }

    $journalPath = Get-SkillAdapterMember -InputObject $Journal -Names @('JournalPath')
    if ($null -ne $journalPath -and
        (Get-Command Add-ExternalChange -ErrorAction SilentlyContinue)) {
        [void](Add-ExternalChange -Journal $Journal `
                -Description $entry.Description `
                -RollbackCommand '')
    }
}

function Install-ManagedSkill {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Plan,

        [AllowNull()]
        [object]$Journal
    )

    if ($Plan.Status -ne 'planned') {
        return New-OperationResult -Status 'failed' `
            -Message (Protect-SkillAdapterText -Text $Plan.Message `
                -SensitiveValues $Plan.SensitiveRedactions) `
            -Data ([pscustomobject][ordered]@{
                PlanOnly = $true
                Errors = @($Plan.Errors)
            })
    }

    $redactions = @(Get-SkillResultRedactions -Plan $Plan)
    try {
        if (-not (Test-SkillAdapterPathWithinRoot -Path $Plan.TargetPath -Root $Plan.TargetRoot)) {
            throw 'Planned target path is outside the approved target root.'
        }
        Assert-SkillAdapterPathIsNotReparsePoint `
            -Path $Plan.TargetRoot `
            -Label 'Managed workspace Skills directory'
        Assert-SkillAdapterTreeHasNoReparsePoint `
            -Path $Plan.TargetPath `
            -Label 'Managed Skill target directory'

        Add-SkillJournalIntent -Plan $Plan -Journal $Journal
        $parent = Split-Path -Parent $Plan.TargetPath
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            New-Item -ItemType Directory -Path $parent -Force -ErrorAction Stop | Out-Null
        }
        if (Test-Path -LiteralPath $Plan.TargetPath) {
            Remove-Item -LiteralPath $Plan.TargetPath -Recurse -Force -ErrorAction Stop
        }
        New-Item -ItemType Directory -Path $Plan.TargetPath -Force -ErrorAction Stop | Out-Null
        foreach ($item in @(Get-ChildItem -LiteralPath $Plan.SourcePath -Force)) {
            Copy-Item -LiteralPath $item.FullName `
                -Destination $Plan.TargetPath `
                -Recurse `
                -Force `
                -ErrorAction Stop
        }

        return New-OperationResult -Status 'succeeded' `
            -Message "Managed Skill '$($Plan.SkillId)' was installed to the managed workspace directory; activation was not asserted." `
            -Data ([pscustomobject][ordered]@{
                SkillId = $Plan.SkillId
                Installed = $true
                ActivationAsserted = $false
                SourceHash = $Plan.SourceHash
            })
    }
    catch {
        $failureMessage = 'Managed Skill install failed.'
        if ($_.Exception.Message -match 'reparse point|symbolic link|junction') {
            $reason = Protect-SkillAdapterText -Text $_.Exception.Message `
                -SensitiveValues $redactions
            $failureMessage = "Managed Skill install failed: $reason"
        }
        return New-OperationResult -Status 'failed' `
            -Message $failureMessage `
            -Data ([pscustomobject][ordered]@{
                SkillId = $Plan.SkillId
                Installed = $false
                ActivationAsserted = $false
                ErrorType = $_.Exception.GetType().FullName
            })
    }
}

function Uninstall-ManagedSkill {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Plan
    )

    if ($Plan.Status -ne 'planned') {
        return New-OperationResult -Status 'failed' `
            -Message (Protect-SkillAdapterText -Text $Plan.Message `
                -SensitiveValues $Plan.SensitiveRedactions) `
            -Data ([pscustomobject][ordered]@{ Errors = @($Plan.Errors) })
    }

    $redactions = @(Get-SkillResultRedactions -Plan $Plan)
    try {
        if (-not (Test-SkillAdapterPathWithinRoot -Path $Plan.TargetPath -Root $Plan.TargetRoot)) {
            throw 'Planned target path is outside the approved target root.'
        }
        Assert-SkillAdapterPathIsNotReparsePoint `
            -Path $Plan.TargetRoot `
            -Label 'Managed workspace Skills directory'
        Assert-SkillAdapterTreeHasNoReparsePoint `
            -Path $Plan.TargetPath `
            -Label 'Managed Skill target directory'
        if (Test-Path -LiteralPath $Plan.TargetPath) {
            Remove-Item -LiteralPath $Plan.TargetPath -Recurse -Force -ErrorAction Stop
        }

        return New-OperationResult -Status 'succeeded' `
            -Message "Managed Skill '$($Plan.SkillId)' was removed from the managed workspace directory." `
            -Data ([pscustomobject][ordered]@{
                SkillId = $Plan.SkillId
                Removed = $true
                ActivationAsserted = $false
            })
    }
    catch {
        $message = Protect-SkillAdapterText -Text $_.Exception.Message `
            -SensitiveValues $redactions
        return New-OperationResult -Status 'failed' `
            -Message "Managed Skill uninstall failed: $message" `
            -Data ([pscustomobject][ordered]@{
                SkillId = $Plan.SkillId
                Removed = $false
                ErrorType = $_.Exception.GetType().FullName
            })
    }
}

function New-SkillVerificationResult {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Plan,

        [Parameter(Mandatory = $true)]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [AllowNull()]
        [object[]]$Checks = @(),

        [AllowNull()]
        [object]$ErrorCode = $null
    )

    $redactions = @(Get-SkillResultRedactions -Plan $Plan)
    $safeMessage = Protect-SkillAdapterText -Text $Message -SensitiveValues $redactions
    $safeChecks = @()
    foreach ($check in @(Get-SkillAdapterArray -Value $Checks)) {
        $safeChecks += Protect-SkillAdapterText -Text ([string]$check) `
            -SensitiveValues $redactions
    }
    $safeErrorCode = $ErrorCode
    if ($null -ne $safeErrorCode) {
        $safeErrorCode = Protect-SkillAdapterText -Text ([string]$safeErrorCode) `
            -SensitiveValues $redactions
    }

    if (Get-Command New-VerificationResult -ErrorAction SilentlyContinue) {
        return New-VerificationResult -Tool $Plan.ApprovedSnapshot `
            -Level 'load' `
            -Status $Status `
            -Message $safeMessage `
            -StartedAt ([DateTime]::UtcNow) `
            -Checks $safeChecks `
            -SensitiveRedactions @() `
            -ErrorCode $safeErrorCode
    }

    return [pscustomobject][ordered]@{
        ToolId = $Plan.Id
        Name = $Plan.Name
        Type = 'skill'
        Version = $Plan.Version
        Source = $Plan.Source
        Level = 'load'
        Status = $Status
        Message = $safeMessage
        Checks = @($safeChecks)
        ErrorCode = $safeErrorCode
    }
}

function Test-ManagedSkill {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Plan,

        [AllowNull()]
        [scriptblock]$Verifier
    )

    if ($Plan.Status -ne 'planned') {
        return New-SkillVerificationResult -Plan $Plan `
            -Status 'failed' `
            -Message $Plan.Message `
            -ErrorCode 'validation_failed'
    }

    $managedSkillsRoot = [IO.Path]::GetFullPath((Join-Path $Plan.ManagedWorkspaceRoot 'Skills'))
    $managedSkillRoot = [IO.Path]::GetFullPath((Join-Path $managedSkillsRoot $Plan.SkillId))
    $plannedTargetPath = [IO.Path]::GetFullPath($Plan.TargetPath)
    $plannedManifestPath = [IO.Path]::GetFullPath((Join-Path $plannedTargetPath 'SKILL.md'))
    $isManagedTarget = (
        [string]::Equals($plannedTargetPath, $managedSkillRoot, [StringComparison]::OrdinalIgnoreCase) -and
        (Test-SkillAdapterPathWithinRoot -Path $plannedManifestPath -Root $managedSkillRoot)
    )

    try {
        Assert-SkillAdapterPathIsNotReparsePoint `
            -Path $managedSkillsRoot `
            -Label 'Managed workspace Skills directory'
        Assert-SkillAdapterTreeHasNoReparsePoint `
            -Path $plannedTargetPath `
            -Label 'Managed Skill target directory'
    }
    catch {
        return New-SkillVerificationResult -Plan $Plan `
            -Status 'failed' `
            -Message $_.Exception.Message `
            -Checks @('managed workspace Skills and target directories are not reparse points') `
            -ErrorCode 'reparse_point_rejected'
    }

    if (-not $isManagedTarget -or
        -not (Test-Path -LiteralPath $plannedTargetPath -PathType Container) -or
        -not (Test-Path -LiteralPath $plannedManifestPath -PathType Leaf)) {
        return New-SkillVerificationResult -Plan $Plan `
            -Status 'failed' `
            -Message "Managed Skill '$($Plan.SkillId)' is not installed in the managed workspace Skills directory." `
            -Checks @('managed skill target directory and SKILL.md exist') `
            -ErrorCode 'skill_not_installed'
    }

    try {
        $installedHash = Get-SkillSourceHash -SourcePath $plannedTargetPath
    }
    catch {
        return New-SkillVerificationResult -Plan $Plan `
            -Status 'failed' `
            -Message 'Managed Skill installed content hash could not be computed.' `
            -Checks @('installed managed skill source hash matches approved snapshot') `
            -ErrorCode 'skill_hash_unavailable'
    }

    if (-not [string]::Equals(
            [string]$installedHash,
            [string]$Plan.SourceHash,
            [StringComparison]::OrdinalIgnoreCase)) {
        return New-SkillVerificationResult -Plan $Plan `
            -Status 'failed' `
            -Message 'Managed Skill installed content hash does not match the approved snapshot.' `
            -Checks @('installed managed skill source hash matches approved snapshot') `
            -ErrorCode 'skill_hash_mismatch'
    }

    if ($null -ne $Verifier) {
        try {
            $verifierResult = & $Verifier $Plan
            return ConvertTo-SkillVerificationResult -Plan $Plan `
                -VerifierResult $verifierResult
        }
        catch {
            return New-SkillVerificationResult -Plan $Plan `
                -Status 'failed' `
                -Message 'Managed Skill verifier failed.' `
                -Checks @('official verifier completed without throwing') `
                -ErrorCode 'verifier_failed'
        }
    }

    return New-SkillVerificationResult -Plan $Plan `
        -Status 'blocked' `
        -Message (
            "Managed Skill '$($Plan.SkillId)' directory installed but activation not asserted; " +
            'an official Codex configuration or plugin manifest verifier is required.'
        ) `
        -Checks @('directory installed but activation not asserted') `
        -ErrorCode 'activation_not_asserted'
}
