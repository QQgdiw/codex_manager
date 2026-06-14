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
        Add-FileChange -Journal $journal -Path $path -Kind modify
        [IO.File]::WriteAllText($path, 'changed')

        $reloaded = [pscustomobject]@{ JournalPath = $journal.JournalPath }
        $result = Invoke-JournalRollback -Journal $reloaded

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
        Add-FileChange -Journal $journal -Path $path -Kind create
        [IO.File]::WriteAllText($path, 'created')
        $runner = Join-Path $root 'rollback-runner.ps1'
        $resultPath = Join-Path $root 'rollback-result.json'
        $runnerText = @'
param([string]$Library, [string]$JournalPath, [string]$ResultPath)
. $Library
$journal = [pscustomobject]@{ JournalPath = $JournalPath }
$result = Invoke-JournalRollback -Journal $journal
$result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ResultPath -Encoding UTF8
if (@($result.Failed).Count -gt 0) { exit 1 }
'@
        Set-Content -LiteralPath $runner -Value $runnerText -Encoding UTF8

        & powershell -NoProfile -ExecutionPolicy Bypass -File $runner `
            -Library $journalLibrary `
            -JournalPath $journal.JournalPath `
            -ResultPath $resultPath
        $exitCode = $LASTEXITCODE

        $exitCode | Should Be 0
        (Test-Path -LiteralPath $path) | Should Be $false
        (Test-Path -LiteralPath $resultPath -PathType Leaf) | Should Be $true
    }
}
