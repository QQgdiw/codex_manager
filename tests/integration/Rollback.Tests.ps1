$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$journalLibrary = Join-Path $projectRoot 'scripts\lib\ChangeJournal.ps1'

Describe 'Persistent rollback integration' {
    BeforeAll {
        . $journalLibrary
    }

    It 'rolls back from a newly loaded journal object' {
        $root = Join-Path $TestDrive 'reload'
        $stateRoot = Join-Path $root '.state'
        $codexRoot = Join-Path $root '.codex-test'
        New-Item -ItemType Directory -Path $root, $codexRoot | Out-Null
        $path = Join-Path $root 'config.toml'
        [IO.File]::WriteAllText($path, 'original')
        $journal = New-ChangeJournal `
            -OperationId 'reload-operation' `
            -AllowedRoots @($root) `
            -CodexRoot $codexRoot `
            -StateRoot $stateRoot
        Add-FileChange -Journal $journal -Path $path -Kind modify -AllowedRoots @($root)
        [IO.File]::WriteAllText($path, 'changed')

        $reloaded = [pscustomobject]@{ JournalPath = $journal.JournalPath }
        $result = Invoke-JournalRollback -Journal $reloaded -AllowedRoots @($root)

        @($result.Failed).Count | Should Be 0
        [IO.File]::ReadAllText($path) | Should Be 'original'
    }

    It 'rolls back in a separate PowerShell process after persistence' {
        $root = Join-Path $TestDrive 'new-process'
        $stateRoot = Join-Path $root '.state'
        $codexRoot = Join-Path $root '.codex-test'
        New-Item -ItemType Directory -Path $root, $codexRoot | Out-Null
        $path = Join-Path $root 'created.txt'
        $journal = New-ChangeJournal `
            -OperationId 'process-operation' `
            -AllowedRoots @($root) `
            -CodexRoot $codexRoot `
            -StateRoot $stateRoot
        Add-FileChange -Journal $journal -Path $path -Kind create -AllowedRoots @($root)
        [IO.File]::WriteAllText($path, 'created')
        Confirm-FileChange -Journal $journal -Path $path -AllowedRoots @($root)
        $runner = Join-Path $root 'rollback-runner.ps1'
        $resultPath = Join-Path $root 'rollback-result.json'
        $runnerText = @'
param(
    [string]$Library,
    [string]$JournalPath,
    [string]$ResultPath,
    [string]$AllowedRoot
)
. $Library
$journal = [pscustomobject]@{ JournalPath = $JournalPath }
$result = Invoke-JournalRollback -Journal $journal -AllowedRoots @($AllowedRoot)
$result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ResultPath -Encoding UTF8
if (@($result.Failed).Count -gt 0) { exit 1 }
'@
        Set-Content -LiteralPath $runner -Value $runnerText -Encoding UTF8

        & powershell -NoProfile -ExecutionPolicy Bypass -File $runner `
            -Library $journalLibrary `
            -JournalPath $journal.JournalPath `
            -ResultPath $resultPath `
            -AllowedRoot $root
        $exitCode = $LASTEXITCODE

        $exitCode | Should Be 0
        (Test-Path -LiteralPath $path) | Should Be $false
        (Test-Path -LiteralPath $resultPath -PathType Leaf) | Should Be $true
    }

    It 'does not lose entries from thirty-two concurrent writers' {
        $root = Join-Path $TestDrive 'concurrent'
        $stateRoot = Join-Path $root '.state'
        $codexRoot = Join-Path $root '.codex-test'
        New-Item -ItemType Directory -Path $root, $codexRoot | Out-Null
        $journal = New-ChangeJournal `
            -OperationId 'concurrent-operation' `
            -AllowedRoots @($root) `
            -CodexRoot $codexRoot `
            -StateRoot $stateRoot
        $runner = Join-Path $root 'add-runner.ps1'
        $runnerText = @'
param([string]$Library, [string]$JournalPath, [string]$Description, [string]$AllowedRoot)
. $Library
$journal = [pscustomobject]@{ JournalPath = $JournalPath }
Add-ExternalChange -Journal $journal -Description $Description -RollbackCommand '' -AllowedRoots @($AllowedRoot) | Out-Null
'@
        Set-Content -LiteralPath $runner -Value $runnerText -Encoding UTF8
        $processes = @(
            1..32 | ForEach-Object {
                Start-Process powershell -PassThru -WindowStyle Hidden -ArgumentList @(
                    '-NoProfile',
                    '-ExecutionPolicy', 'Bypass',
                    '-File', "`"$runner`"",
                    '-Library', "`"$journalLibrary`"",
                    '-JournalPath', "`"$($journal.JournalPath)`"",
                    '-Description', "writer-$_",
                    '-AllowedRoot', "`"$root`""
                )
            }
        )
        $processes | ForEach-Object { $_.WaitForExit() }

        @($processes | Where-Object { $_.ExitCode -ne 0 }).Count | Should Be 0
        $document = Get-Content -LiteralPath $journal.JournalPath -Raw | ConvertFrom-Json
        @($document.Changes).Count | Should Be 32
    }
}
