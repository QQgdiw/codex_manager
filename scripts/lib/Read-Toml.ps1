function Test-ProjectObject {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Value
    )

    return ($Value -is [System.Collections.IDictionary] -or
        $Value -is [System.Management.Automation.PSCustomObject])
}

function Get-ProjectMember {
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

function ConvertTo-ProcessArgument {
    param([AllowEmptyString()][string]$Value)

    return '"' + ($Value -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

function Invoke-Utf8Process {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [string[]]$ArgumentList = @()
    )

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $extension = [System.IO.Path]::GetExtension($FilePath)
    $quotedArguments = @($ArgumentList | ForEach-Object { ConvertTo-ProcessArgument "$_" })

    if ($extension -ieq '.cmd' -or $extension -ieq '.bat') {
        $startInfo.FileName = $env:ComSpec
        $command = @((ConvertTo-ProcessArgument $FilePath)) + $quotedArguments
        $startInfo.Arguments = '/d /s /c "' + ($command -join ' ') + '"'
    }
    else {
        $startInfo.FileName = $FilePath
        $startInfo.Arguments = $quotedArguments -join ' '
    }

    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.StandardOutputEncoding = $utf8WithoutBom
    $startInfo.StandardErrorEncoding = $utf8WithoutBom

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo

    try {
        $null = $process.Start()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()

        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            StdOut = $stdoutTask.Result
            StdErr = $stderrTask.Result
        }
    }
    finally {
        $process.Dispose()
    }
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
        $versionResult = Invoke-Utf8Process -FilePath $python.Source -ArgumentList @(
            '-c',
            'import sys; print(sys.version_info.major,sys.version_info.minor,sys.version_info.micro,sep=chr(46))'
        )
        $versionText = $versionResult.StdOut.Trim()
        $parsedVersion = $null

        if ($versionResult.ExitCode -ne 0 -or
            -not [version]::TryParse($versionText, [ref]$parsedVersion)) {
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

    $converterResult = Invoke-Utf8Process -FilePath $python.Source -ArgumentList @(
        $converterPath,
        $Path
    )
    $jsonText = $converterResult.StdOut

    if ($converterResult.ExitCode -ne 0) {
        $detail = $converterResult.StdErr.Trim()
        if ([string]::IsNullOrWhiteSpace($detail)) {
            $detail = $jsonText.Trim()
        }
        throw "TOML converter failed with exit code $($converterResult.ExitCode): $detail"
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
    $schemaMember = Get-ProjectMember -InputObject $Document -Name 'schema_version'
    if (-not $schemaMember.Exists) {
        $errors.Add("Document is missing required field 'schema_version'.")
    }
    elseif ($schemaMember.Value -isnot [string] -or
        [string]::IsNullOrWhiteSpace($schemaMember.Value)) {
        $errors.Add("Document field 'schema_version' must be a non-empty string.")
    }
    elseif ($schemaMember.Value -cne '1.0') {
        $errors.Add("Document field 'schema_version' must be supported version '1.0'.")
    }

    $toolsMember = Get-ProjectMember -InputObject $Document -Name 'tools'

    if (-not $toolsMember.Exists -or $null -eq $toolsMember.Value) {
        $errors.Add("Document is missing required 'tools' collection.")
        $tools = @()
    }
    elseif ($toolsMember.Value -isnot [System.Array]) {
        $errors.Add("Document 'tools' value must be an array.")
        $tools = @()
    }
    else {
        $tools = @($toolsMember.Value)
    }

    $stringFields = @(
        'id', 'name', 'type', 'source', 'version', 'sha256',
        'license', 'approval', 'risk', 'install_target'
    )
    $arrayFields = @('credential_refs', 'conflicts')
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

        $members = @{}
        foreach ($field in $stringFields + $arrayFields) {
            $members[$field] = Get-ProjectMember -InputObject $tool -Name $field
            if (-not $members[$field].Exists) {
                $errors.Add("$label is missing required field '$field'.")
            }
        }

        foreach ($field in $stringFields) {
            $member = $members[$field]
            if ($member.Exists -and
                ($member.Value -isnot [string] -or
                    [string]::IsNullOrWhiteSpace($member.Value))) {
                $errors.Add("$label field '$field' must be a non-empty string.")
            }
        }

        foreach ($field in $arrayFields) {
            $member = $members[$field]
            if (-not $member.Exists) {
                continue
            }
            if ($member.Value -isnot [System.Array]) {
                $errors.Add("$label field '$field' must be an array.")
                continue
            }
            for ($itemIndex = 0; $itemIndex -lt $member.Value.Count; $itemIndex++) {
                $item = $member.Value[$itemIndex]
                if ($item -isnot [string] -or [string]::IsNullOrWhiteSpace($item)) {
                    $errors.Add(
                        "$label field '$field[$itemIndex]' must be a non-empty string."
                    )
                }
            }
        }

        $idMember = $members['id']
        if ($idMember.Exists -and $idMember.Value -is [string] -and
            -not [string]::IsNullOrWhiteSpace($idMember.Value)) {
            $id = $idMember.Value
            if ($seenIds.ContainsKey($id)) {
                $errors.Add("$label has duplicate id '$id'.")
            }
            else {
                $seenIds[$id] = $true
            }
        }

        $typeMember = $members['type']
        if ($typeMember.Exists -and $typeMember.Value -is [string] -and
            -not [string]::IsNullOrWhiteSpace($typeMember.Value) -and
            $allowedTypes -notcontains $typeMember.Value) {
            $errors.Add("$label field 'type' must be plugin, mcp, or skill.")
        }

        $approvalMember = $members['approval']
        if ($approvalMember.Exists -and $approvalMember.Value -is [string] -and
            -not [string]::IsNullOrWhiteSpace($approvalMember.Value) -and
            $allowedApprovals -notcontains $approvalMember.Value) {
            $errors.Add("$label field 'approval' has an invalid value.")
        }

        $hashMember = $members['sha256']
        if ($hashMember.Exists -and $hashMember.Value -is [string] -and
            -not [string]::IsNullOrWhiteSpace($hashMember.Value) -and
            $hashMember.Value -cnotmatch '^[0-9a-f]{64}$') {
            $errors.Add("$label field 'sha256' must be 64 lowercase hexadecimal characters.")
        }
    }

    return [pscustomobject]@{
        IsValid = ($errors.Count -eq 0)
        Errors = @($errors)
        Warnings = @($warnings)
    }
}
