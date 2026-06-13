function Test-ProjectObject {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Value
    )

    return ($Value -is [System.Collections.IDictionary] -or
        $Value -is [System.Management.Automation.PSCustomObject])
}

function Read-ProjectToml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [string]$PythonCommand = 'python',

        [switch]$SkipPythonVersionCheck
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "TOML input file does not exist: $Path"
    }

    try {
        $python = Get-Command -Name $PythonCommand -ErrorAction Stop
    }
    catch {
        throw "Python command is unavailable: $PythonCommand"
    }

    if (-not $SkipPythonVersionCheck) {
        $versionOutput = @(
            & $python.Source -c 'import sys; print(sys.version_info.major,sys.version_info.minor,sys.version_info.micro,sep=chr(46))' 2>&1
        )
        $versionExitCode = $LASTEXITCODE
        $versionText = ($versionOutput | ForEach-Object { "$_" }) -join "`n"
        $parsedVersion = $null

        if ($versionExitCode -ne 0 -or
            -not [version]::TryParse($versionText.Trim(), [ref]$parsedVersion)) {
            throw "Unable to determine Python version using '$PythonCommand'."
        }
        if ($parsedVersion -lt [version]'3.11') {
            throw "Python 3.11 or later is required; found $parsedVersion."
        }
    }

    $converterPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'python\toml_to_json.py'
    if (-not (Test-Path -LiteralPath $converterPath -PathType Leaf)) {
        throw "TOML converter is missing: $converterPath"
    }

    $converterOutput = @(& $python.Source $converterPath $Path 2>&1)
    $converterExitCode = $LASTEXITCODE
    $jsonText = ($converterOutput | ForEach-Object { "$_" }) -join "`n"

    if ($converterExitCode -ne 0) {
        throw "TOML converter failed with exit code ${converterExitCode}: $jsonText"
    }

    try {
        $document = $jsonText | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "TOML converter returned invalid JSON: $($_.Exception.Message)"
    }

    if (-not (Test-ProjectObject -Value $document)) {
        throw 'TOML converter returned a JSON root that is not an object.'
    }

    return $document
}

function Test-WhitelistDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Document
    )

    if (-not (Test-ProjectObject -Value $Document)) {
        throw 'Whitelist document must be a readable object.'
    }

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]
    $toolsProperty = $Document.PSObject.Properties['tools']

    if ($null -eq $toolsProperty -or $null -eq $toolsProperty.Value) {
        $errors.Add("Document is missing required 'tools' collection.")
        $tools = @()
    }
    elseif ($toolsProperty.Value -is [string] -or
        -not ($toolsProperty.Value -is [System.Collections.IEnumerable])) {
        $errors.Add("Document 'tools' value must be a collection.")
        $tools = @()
    }
    else {
        $tools = @($toolsProperty.Value)
    }

    $requiredFields = @(
        'id', 'name', 'type', 'source', 'version', 'sha256', 'license',
        'approval', 'risk', 'install_target', 'credential_refs', 'conflicts'
    )
    $allowedTypes = @('plugin', 'mcp', 'skill')
    $allowedApprovals = @('proposed', 'approved', 'rejected', 'suspended')
    $seenIds = @{}

    for ($index = 0; $index -lt $tools.Count; $index++) {
        $tool = $tools[$index]
        $label = "tools[$index]"

        if (-not (Test-ProjectObject -Value $tool)) {
            $errors.Add("$label must be an object.")
            continue
        }

        foreach ($field in $requiredFields) {
            if ($null -eq $tool.PSObject.Properties[$field]) {
                $errors.Add("$label is missing required field '$field'.")
            }
        }

        $idProperty = $tool.PSObject.Properties['id']
        if ($null -ne $idProperty) {
            $id = "$($idProperty.Value)"
            if ([string]::IsNullOrWhiteSpace($id)) {
                $errors.Add("$label field 'id' must be non-empty.")
            }
            elseif ($seenIds.ContainsKey($id)) {
                $errors.Add("$label has duplicate id '$id'.")
            }
            else {
                $seenIds[$id] = $true
            }
        }

        $typeProperty = $tool.PSObject.Properties['type']
        if ($null -ne $typeProperty -and $allowedTypes -notcontains "$($typeProperty.Value)") {
            $errors.Add("$label field 'type' must be plugin, mcp, or skill.")
        }

        $approvalProperty = $tool.PSObject.Properties['approval']
        if ($null -ne $approvalProperty -and
            $allowedApprovals -notcontains "$($approvalProperty.Value)") {
            $errors.Add("$label field 'approval' has an invalid value.")
        }

        $hashProperty = $tool.PSObject.Properties['sha256']
        if ($null -ne $hashProperty -and "$($hashProperty.Value)" -cnotmatch '^[0-9a-f]{64}$') {
            $errors.Add("$label field 'sha256' must be 64 lowercase hexadecimal characters.")
        }
    }

    return [pscustomobject]@{
        IsValid = ($errors.Count -eq 0)
        Errors = @($errors)
        Warnings = @($warnings)
    }
}
