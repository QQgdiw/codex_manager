$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$journalLibrary = Join-Path $projectRoot 'scripts\lib\ChangeJournal.ps1'

function Get-JournalExceptionMessage {
    param([scriptblock]$Action)

    try {
        & $Action
        return $null
    }
    catch {
        return $_.Exception.Message
    }
}

function New-TestJournal {
    param(
        [string]$Root,
        [string]$OperationId = ([Guid]::NewGuid().ToString('N'))
    )

    $stateRoot = Join-Path $Root '.state'
    $codexRoot = Join-Path $Root '.codex-test'
    New-Item -ItemType Directory -Path $codexRoot -Force | Out-Null
    return New-ChangeJournal `
        -OperationId $OperationId `
        -AllowedRoots @($Root) `
        -CodexRoot $codexRoot `
        -StateRoot $stateRoot
}

function Read-TestJournal {
    param([object]$Journal)

    return Get-Content -LiteralPath $Journal.JournalPath -Raw |
        ConvertFrom-Json
}

function Write-TestJournal {
    param(
        [object]$Journal,
        [object]$Document
    )

    $encoding = New-Object Text.UTF8Encoding($false)
    [IO.File]::WriteAllText(
        $Journal.JournalPath,
        ($Document | ConvertTo-Json -Depth 20),
        $encoding
    )
}

function Invoke-TestRollback {
    param(
        [object]$Journal,
        [string]$Root
    )

    return Invoke-JournalRollback -Journal $Journal -AllowedRoots @($Root)
}

function New-OverlappingRootsJournal {
    param(
        [string]$Parent,
        [string]$Child,
        [string[]]$RootOrder
    )

    $codexRoot = Join-Path $Parent '.codex-test'
    New-Item -ItemType Directory -Path $codexRoot -Force | Out-Null
    $journal = New-ChangeJournal `
        -OperationId ([Guid]::NewGuid().ToString('N')) `
        -AllowedRoots $RootOrder `
        -WorkspaceRoot $Parent `
        -CodexRoot $codexRoot `
        -StateRoot (Join-Path $Parent '.state')
    $document = Read-TestJournal -Journal $journal
    $document.AllowedRoots = @($RootOrder)
    Write-TestJournal -Journal $journal -Document $document
    return $journal
}

Describe 'Change journal persistence' {
    BeforeAll {
        . $journalLibrary
    }

    It 'persists a strictly versioned journal in the managed state directory' {
        $root = Join-Path $TestDrive 'persisted'
        New-Item -ItemType Directory -Path $root | Out-Null

        $journal = New-TestJournal -Root $root -OperationId 'operation-001'
        $document = Read-TestJournal -Journal $journal

        (Test-Path -LiteralPath $journal.JournalPath -PathType Leaf) | Should Be $true
        $journal.JournalPath | Should Be (
            Join-Path $root '.state\journals\operation-001\journal.json'
        )
        $document.Schema | Should Be 'codex.change-journal'
        $document.Version | Should Be 1
        $document.OperationId | Should Be 'operation-001'
        @($document.AllowedRoots).Count | Should BeGreaterThan 0
        @($document.Changes).Count | Should Be 0
        @(Get-ChildItem -LiteralPath (Split-Path $journal.JournalPath) -Filter '*.tmp').Count |
            Should Be 0
    }

    It 'rejects operation identifiers that can escape the journal directory' {
        $root = Join-Path $TestDrive 'bad-operation'
        New-Item -ItemType Directory -Path $root | Out-Null

        $message = Get-JournalExceptionMessage {
            New-TestJournal -Root $root -OperationId '..\outside'
        }

        $message | Should Match 'OperationId'
    }

    It 'records external rollback text without executing it' {
        $root = Join-Path $TestDrive 'external'
        New-Item -ItemType Directory -Path $root | Out-Null
        $sentinel = Join-Path $root 'executed.txt'
        $journal = New-TestJournal -Root $root
        $command = "Set-Content -LiteralPath '$sentinel' -Value unsafe"

        Add-ExternalChange `
            -Journal $journal `
            -Description 'unmanaged installer change' `
            -RollbackCommand $command
        $result = Invoke-TestRollback -Journal $journal -Root $root

        (Test-Path -LiteralPath $sentinel) | Should Be $false
        @($result.Failed).Count | Should Be 0
        @($result.Residuals).Count | Should Be 1
        $result.Residuals[0].Description | Should Be 'unmanaged installer change'
    }
}

Describe 'File change snapshots' {
    BeforeAll {
        . $journalLibrary
    }

    It 'captures the original binary bytes and metadata before modification' {
        $root = Join-Path $TestDrive 'binary'
        New-Item -ItemType Directory -Path $root | Out-Null
        $path = Join-Path $root 'firmware.bin'
        $original = [byte[]](0, 1, 2, 127, 128, 254, 255)
        [IO.File]::WriteAllBytes($path, $original)
        $timestamp = [DateTime]::UtcNow.AddDays(-3)
        [IO.File]::SetLastWriteTimeUtc($path, $timestamp)
        $journal = New-TestJournal -Root $root

        Add-FileChange -Journal $journal -Path $path -Kind modify
        [IO.File]::WriteAllBytes($path, [byte[]](9, 8, 7))
        [IO.File]::SetLastWriteTimeUtc($path, [DateTime]::UtcNow)
        $result = Invoke-TestRollback -Journal $journal -Root $root

        @($result.Failed).Count | Should Be 0
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($path)) |
            Should Be ([Convert]::ToBase64String($original))
        [Math]::Abs(([IO.File]::GetLastWriteTimeUtc($path) - $timestamp).TotalSeconds) |
            Should BeLessThan 2
    }

    It 'does not overwrite the first snapshot when a path is recorded twice' {
        $root = Join-Path $TestDrive 'duplicate'
        New-Item -ItemType Directory -Path $root | Out-Null
        $path = Join-Path $root 'config.toml'
        [IO.File]::WriteAllText($path, 'first')
        $journal = New-TestJournal -Root $root

        Add-FileChange -Journal $journal -Path $path -Kind modify
        [IO.File]::WriteAllText($path, 'second')
        Add-FileChange -Journal $journal -Path $path -Kind modify
        [IO.File]::WriteAllText($path, 'third')
        $document = Read-TestJournal -Journal $journal
        Invoke-TestRollback -Journal $journal -Root $root | Out-Null

        @($document.Changes).Count | Should Be 1
        [IO.File]::ReadAllText($path) | Should Be 'first'
    }

    It 'rejects unsupported change kinds' {
        $root = Join-Path $TestDrive 'kind'
        New-Item -ItemType Directory -Path $root | Out-Null
        $journal = New-TestJournal -Root $root

        $message = Get-JournalExceptionMessage {
            Add-FileChange -Journal $journal -Path (Join-Path $root 'x') -Kind move
        }

        $message | Should Match 'Kind'
    }
}

Describe 'Managed file rollback' {
    BeforeAll {
        . $journalLibrary
    }

    It 'removes a file created by the operation' {
        $root = Join-Path $TestDrive 'create-file'
        New-Item -ItemType Directory -Path $root | Out-Null
        $path = Join-Path $root 'created.txt'
        $journal = New-TestJournal -Root $root

        Add-FileChange -Journal $journal -Path $path -Kind create
        [IO.File]::WriteAllText($path, 'created')
        $result = Invoke-TestRollback -Journal $journal -Root $root

        @($result.Failed).Count | Should Be 0
        (Test-Path -LiteralPath $path) | Should Be $false
    }

    It 'restores a file deleted by the operation' {
        $root = Join-Path $TestDrive 'delete-file'
        New-Item -ItemType Directory -Path $root | Out-Null
        $path = Join-Path $root 'deleted.txt'
        [IO.File]::WriteAllText($path, 'restore me')
        $journal = New-TestJournal -Root $root

        Add-FileChange -Journal $journal -Path $path -Kind delete
        Remove-Item -LiteralPath $path -Force
        $result = Invoke-TestRollback -Journal $journal -Root $root

        @($result.Failed).Count | Should Be 0
        [IO.File]::ReadAllText($path) | Should Be 'restore me'
    }

    It 'removes a directory created by the operation' {
        $root = Join-Path $TestDrive 'create-directory'
        New-Item -ItemType Directory -Path $root | Out-Null
        $path = Join-Path $root 'installed-tool'
        $journal = New-TestJournal -Root $root

        Add-FileChange -Journal $journal -Path $path -Kind directory_create
        New-Item -ItemType Directory -Path $path | Out-Null
        [IO.File]::WriteAllText((Join-Path $path 'payload.txt'), 'payload')
        $result = Invoke-TestRollback -Journal $journal -Root $root

        @($result.Failed).Count | Should Be 0
        (Test-Path -LiteralPath $path) | Should Be $false
    }

    It 'rolls changes back in reverse recording order' {
        $root = Join-Path $TestDrive 'reverse'
        New-Item -ItemType Directory -Path $root | Out-Null
        $first = Join-Path $root 'first.txt'
        $second = Join-Path $root 'second.txt'
        $journal = New-TestJournal -Root $root

        Add-FileChange -Journal $journal -Path $first -Kind create
        Add-FileChange -Journal $journal -Path $second -Kind create
        [IO.File]::WriteAllText($first, 'one')
        [IO.File]::WriteAllText($second, 'two')
        $result = Invoke-TestRollback -Journal $journal -Root $root

        @($result.Succeeded).Count | Should Be 2
        $result.Succeeded[0].Path | Should Be $second
        $result.Succeeded[1].Path | Should Be $first
    }

    It 'continues after one rollback item fails' {
        $root = Join-Path $TestDrive 'continue'
        New-Item -ItemType Directory -Path $root | Out-Null
        $modified = Join-Path $root 'modified.txt'
        $created = Join-Path $root 'created.txt'
        [IO.File]::WriteAllText($modified, 'original')
        $journal = New-TestJournal -Root $root

        Add-FileChange -Journal $journal -Path $created -Kind create
        Add-FileChange -Journal $journal -Path $modified -Kind modify
        [IO.File]::WriteAllText($created, 'new')
        [IO.File]::WriteAllText($modified, 'changed')
        $document = Read-TestJournal -Journal $journal
        [IO.File]::WriteAllText($document.Changes[1].BackupPath, 'tampered')
        $result = Invoke-TestRollback -Journal $journal -Root $root

        @($result.Failed).Count | Should Be 1
        @($result.Succeeded).Count | Should Be 1
        (Test-Path -LiteralPath $created) | Should Be $false
        [IO.File]::ReadAllText($modified) | Should Be 'changed'
    }

    It 'can be called repeatedly after a completed rollback' {
        $root = Join-Path $TestDrive 'repeat'
        New-Item -ItemType Directory -Path $root | Out-Null
        $path = Join-Path $root 'created.txt'
        $journal = New-TestJournal -Root $root
        Add-FileChange -Journal $journal -Path $path -Kind create
        [IO.File]::WriteAllText($path, 'new')

        Invoke-TestRollback -Journal $journal -Root $root | Out-Null
        $second = Invoke-TestRollback -Journal $journal -Root $root

        @($second.Failed).Count | Should Be 0
        (Test-Path -LiteralPath $path) | Should Be $false
    }
}

Describe 'Change journal safety boundaries' {
    BeforeAll {
        . $journalLibrary
    }

    It 'rejects paths outside all allowed roots' {
        $root = Join-Path $TestDrive 'inside'
        $outside = Join-Path $TestDrive 'outside'
        New-Item -ItemType Directory -Path $root, $outside | Out-Null
        $journal = New-TestJournal -Root $root

        $message = Get-JournalExceptionMessage {
            Add-FileChange -Journal $journal -Path (Join-Path $outside 'x.txt') -Kind create
        }

        $message | Should Match 'allowed root'
    }

    It 'does not confuse a path prefix with a child path' {
        $root = Join-Path $TestDrive 'prefix'
        $collision = Join-Path $TestDrive 'prefix-collision'
        New-Item -ItemType Directory -Path $root, $collision | Out-Null
        $journal = New-TestJournal -Root $root

        $message = Get-JournalExceptionMessage {
            Add-FileChange -Journal $journal -Path (Join-Path $collision 'x.txt') -Kind create
        }

        $message | Should Match 'allowed root'
    }

    It 'rejects caller paths containing parent traversal segments' {
        $root = Join-Path $TestDrive 'dotdot'
        New-Item -ItemType Directory -Path $root | Out-Null
        $journal = New-TestJournal -Root $root
        $path = Join-Path $root 'child\..\escaped.txt'

        $message = Get-JournalExceptionMessage {
            Add-FileChange -Journal $journal -Path $path -Kind create
        }

        $message | Should Match 'parent traversal'
    }

    It 'rejects a junction that resolves outside an allowed root' {
        $root = Join-Path $TestDrive 'junction-root'
        $outside = Join-Path $TestDrive 'junction-outside'
        New-Item -ItemType Directory -Path $root, $outside | Out-Null
        $junction = Join-Path $root 'linked'
        New-Item -ItemType Junction -Path $junction -Target $outside | Out-Null
        $journal = New-TestJournal -Root $root

        $message = Get-JournalExceptionMessage {
            Add-FileChange -Journal $journal -Path (Join-Path $junction 'x.txt') -Kind create
        }

        $message | Should Match 'allowed root'
    }

    It 'refuses to register an allowed root for recursive deletion' {
        $root = Join-Path $TestDrive 'root-delete'
        New-Item -ItemType Directory -Path $root | Out-Null
        $journal = New-TestJournal -Root $root

        $message = Get-JournalExceptionMessage {
            Add-FileChange -Journal $journal -Path $root -Kind directory_create
        }

        $message | Should Match 'root'
    }

    It 'rejects an overlapping child root regardless of root order' {
        foreach ($reverse in @($false, $true)) {
            $parent = Join-Path $TestDrive "overlap-register-$reverse"
            $child = Join-Path $parent 'child'
            New-Item -ItemType Directory -Path $parent | Out-Null
            $roots = if ($reverse) {
                @($child, $parent)
            }
            else {
                @($parent, $child)
            }
            $journal = New-OverlappingRootsJournal `
                -Parent $parent `
                -Child $child `
                -RootOrder $roots

            $message = Get-JournalExceptionMessage {
                Add-FileChange `
                    -Journal $journal `
                    -Path $child `
                    -Kind directory_create
            }

            $message | Should Match 'root'
            @((Read-TestJournal -Journal $journal).Changes).Count | Should Be 0
        }
    }

    It 'allows a subdirectory beneath an overlapping child root' {
        $parent = Join-Path $TestDrive 'overlap-subdirectory'
        $child = Join-Path $parent 'child'
        $subdirectory = Join-Path $child 'subdirectory'
        New-Item -ItemType Directory -Path $child -Force | Out-Null
        $journal = New-OverlappingRootsJournal `
            -Parent $parent `
            -Child $child `
            -RootOrder @($parent, $child)

        Add-FileChange `
            -Journal $journal `
            -Path $subdirectory `
            -Kind directory_create | Out-Null

        @((Read-TestJournal -Journal $journal).Changes).Count | Should Be 1
    }

    It 'does not roll back-delete an overlapping child root in either order' {
        foreach ($reverse in @($false, $true)) {
            $parent = Join-Path $TestDrive "overlap-rollback-$reverse"
            $child = Join-Path $parent 'child'
            $recorded = Join-Path $child 'recorded'
            New-Item -ItemType Directory -Path $parent | Out-Null
            $roots = if ($reverse) {
                @($child, $parent)
            }
            else {
                @($parent, $child)
            }
            $journal = New-OverlappingRootsJournal `
                -Parent $parent `
                -Child $child `
                -RootOrder $roots
            Add-FileChange `
                -Journal $journal `
                -Path $recorded `
                -Kind directory_create | Out-Null
            $document = Read-TestJournal -Journal $journal
            $document.Changes[0].Path = $child
            Write-TestJournal -Journal $journal -Document $document
            New-Item -ItemType Directory -Path $child -Force | Out-Null
            [IO.File]::WriteAllText((Join-Path $child 'keep.txt'), 'keep')

            $result = Invoke-JournalRollback `
                -Journal $journal `
                -AllowedRoots $roots

            @($result.Failed).Count | Should Be 1
            (Test-Path -LiteralPath $child -PathType Container) | Should Be $true
            [IO.File]::ReadAllText((Join-Path $child 'keep.txt')) | Should Be 'keep'
        }
    }

    It 'protects a child root reached through a junction' {
        $parent = Join-Path $TestDrive 'overlap-junction'
        $child = Join-Path $parent 'child'
        $alias = Join-Path $parent 'alias'
        $recorded = Join-Path $child 'recorded'
        New-Item -ItemType Directory -Path $child -Force | Out-Null
        New-Item -ItemType Junction -Path $alias -Target $child | Out-Null
        $roots = @($parent, $child)
        $journal = New-OverlappingRootsJournal `
            -Parent $parent `
            -Child $child `
            -RootOrder $roots
        Add-FileChange `
            -Journal $journal `
            -Path $recorded `
            -Kind directory_create | Out-Null
        $document = Read-TestJournal -Journal $journal
        $document.Changes[0].Path = $alias
        Write-TestJournal -Journal $journal -Document $document
        [IO.File]::WriteAllText((Join-Path $child 'keep.txt'), 'keep')

        $result = Invoke-JournalRollback `
            -Journal $journal `
            -AllowedRoots $roots

        @($result.Failed).Count | Should Be 1
        (Test-Path -LiteralPath $child -PathType Container) | Should Be $true
        [IO.File]::ReadAllText((Join-Path $child 'keep.txt')) | Should Be 'keep'
    }

    It 'rejects a corrupted journal before rollback' {
        $root = Join-Path $TestDrive 'corrupt'
        New-Item -ItemType Directory -Path $root | Out-Null
        $journal = New-TestJournal -Root $root
        [IO.File]::WriteAllText($journal.JournalPath, '{broken json')

        $message = Get-JournalExceptionMessage {
            Invoke-JournalRollback -Journal $journal
        }

        $message | Should Match 'journal'
    }

    It 'does not trust tampered journal roots to delete an external file' {
        $root = Join-Path $TestDrive 'tampered-root'
        $outside = Join-Path $TestDrive 'tampered-outside'
        New-Item -ItemType Directory -Path $root, $outside | Out-Null
        $insidePath = Join-Path $root 'created.txt'
        $outsidePath = Join-Path $outside 'keep.txt'
        [IO.File]::WriteAllText($outsidePath, 'keep')
        $journal = New-TestJournal -Root $root
        Add-FileChange -Journal $journal -Path $insidePath -Kind create
        $document = Read-TestJournal -Journal $journal
        $document.AllowedRoots = @($outside)
        $document.Changes[0].Path = $outsidePath
        Write-TestJournal -Journal $journal -Document $document

        $result = Invoke-JournalRollback -Journal $journal

        (Test-Path -LiteralPath $outsidePath -PathType Leaf) | Should Be $true
        @($result.Failed).Count | Should Be 1
        @($result.Succeeded).Count | Should Be 0
    }

    It 'rejects an operation identifier that does not match its journal directory' {
        $root = Join-Path $TestDrive 'tampered-operation'
        New-Item -ItemType Directory -Path $root | Out-Null
        $journal = New-TestJournal -Root $root -OperationId 'original-operation'
        $document = Read-TestJournal -Journal $journal
        $document.OperationId = 'different-operation'
        Write-TestJournal -Journal $journal -Document $document

        $message = Get-JournalExceptionMessage {
            Invoke-TestRollback -Journal $journal -Root $root
        }

        $message | Should Match 'OperationId'
    }

    It 'rejects malformed file entries before rollback' {
        $root = Join-Path $TestDrive 'tampered-entry'
        New-Item -ItemType Directory -Path $root | Out-Null
        $path = Join-Path $root 'created.txt'
        $journal = New-TestJournal -Root $root
        Add-FileChange -Journal $journal -Path $path -Kind create
        $document = Read-TestJournal -Journal $journal
        $document.Changes[0].Kind = 'arbitrary'
        Write-TestJournal -Journal $journal -Document $document

        $message = Get-JournalExceptionMessage {
            Invoke-TestRollback -Journal $journal -Root $root
        }

        $message | Should Match 'entry'
    }

    It 'ignores persisted journal state in Git' {
        $probe = '.state/journals/probe.json'

        $ignored = & git -C $projectRoot check-ignore $probe

        $LASTEXITCODE | Should Be 0
        "$ignored" | Should Be $probe
    }
}
