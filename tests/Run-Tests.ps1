[CmdletBinding()]
param(
    [switch]$Unit,
    [switch]$Integration,
    [switch]$All
)

if (-not ($Unit -or $Integration -or $All)) {
    $All = $true
}

$testRoots = @()
if ($All -or $Unit) {
    $testRoots += Join-Path $PSScriptRoot 'unit'
}
if ($All -or $Integration) {
    $testRoots += Join-Path $PSScriptRoot 'integration'
}

$testFiles = @(
    foreach ($testRoot in $testRoots) {
        if (Test-Path -LiteralPath $testRoot -PathType Container) {
            Get-ChildItem -LiteralPath $testRoot -Filter '*.Tests.ps1' -File -Recurse
        }
    }
)

if ($testFiles.Count -eq 0) {
    [Console]::Error.WriteLine('No matching Pester tests were found.')
    exit 2
}

try {
    Import-Module Pester -MinimumVersion 3.4 -ErrorAction Stop
    $result = Invoke-Pester -Script $testFiles.FullName -PassThru
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 2
}

if ($null -eq $result -or $result.TotalCount -eq 0) {
    [Console]::Error.WriteLine('Pester did not execute any tests.')
    exit 2
}

if ($result.FailedCount -gt 0) {
    exit 1
}

exit 0
