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

function Write-TestAuthenticatedJournal {
    param(
        [object]$Journal,
        [object]$Document,
        [string]$Root
    )

    Write-ChangeJournalDocument `
        -Document $Document `
        -JournalPath $Journal.JournalPath `
        -TrustedRoots (Get-TrustedJournalRoots -AllowedRoots @($Root))
}

function Invoke-TestRollback {
    param(
        [object]$Journal,
        [string]$Root
    )

    return Invoke-JournalRollback -Journal $Journal -AllowedRoots @($Root)
}

function Add-TestFileChange {
    param(
        [object]$Journal,
        [string]$Root,
        [string]$Path,
        [string]$Kind
    )

    return Add-FileChange `
        -Journal $Journal `
        -Path $Path `
        -Kind $Kind `
        -AllowedRoots @($Root)
}

function Confirm-TestFileChange {
    param(
        [object]$Journal,
        [string]$Root,
        [string]$Path
    )

    return Confirm-FileChange `
        -Journal $Journal `
        -Path $Path `
        -AllowedRoots @($Root)
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
        $document.Version | Should Be 2
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
            -RollbackCommand $command `
            -AllowedRoots @($root)
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

        Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind modify
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

        Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind modify
        [IO.File]::WriteAllText($path, 'second')
        Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind modify
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
            Add-FileChange -Journal $journal -Path (Join-Path $root 'x') -Kind move -AllowedRoots @($root)
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

        Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind create
        [IO.File]::WriteAllText($path, 'created')
        Confirm-TestFileChange -Journal $journal -Root $root -Path $path
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

        Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind delete
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

        Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind directory_create
        New-Item -ItemType Directory -Path $path | Out-Null
        [IO.File]::WriteAllText((Join-Path $path 'payload.txt'), 'payload')
        Confirm-TestFileChange -Journal $journal -Root $root -Path $path
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

        Add-TestFileChange -Journal $journal -Root $root -Path $first -Kind create
        Add-TestFileChange -Journal $journal -Root $root -Path $second -Kind create
        [IO.File]::WriteAllText($first, 'one')
        [IO.File]::WriteAllText($second, 'two')
        Confirm-TestFileChange -Journal $journal -Root $root -Path $first
        Confirm-TestFileChange -Journal $journal -Root $root -Path $second
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

        Add-TestFileChange -Journal $journal -Root $root -Path $created -Kind create
        Add-TestFileChange -Journal $journal -Root $root -Path $modified -Kind modify
        [IO.File]::WriteAllText($created, 'new')
        [IO.File]::WriteAllText($modified, 'changed')
        Confirm-TestFileChange -Journal $journal -Root $root -Path $created
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
        Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind create
        [IO.File]::WriteAllText($path, 'new')
        Confirm-TestFileChange -Journal $journal -Root $root -Path $path

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
            Add-FileChange -Journal $journal -Path (Join-Path $outside 'x.txt') -Kind create -AllowedRoots @($root)
        }

        $message | Should Match 'allowed root|reparse'
    }

    It 'does not confuse a path prefix with a child path' {
        $root = Join-Path $TestDrive 'prefix'
        $collision = Join-Path $TestDrive 'prefix-collision'
        New-Item -ItemType Directory -Path $root, $collision | Out-Null
        $journal = New-TestJournal -Root $root

        $message = Get-JournalExceptionMessage {
            Add-FileChange -Journal $journal -Path (Join-Path $collision 'x.txt') -Kind create -AllowedRoots @($root)
        }

        $message | Should Match 'allowed root|reparse'
    }

    It 'rejects caller paths containing parent traversal segments' {
        $root = Join-Path $TestDrive 'dotdot'
        New-Item -ItemType Directory -Path $root | Out-Null
        $journal = New-TestJournal -Root $root
        $path = Join-Path $root 'child\..\escaped.txt'

        $message = Get-JournalExceptionMessage {
            Add-FileChange -Journal $journal -Path $path -Kind create -AllowedRoots @($root)
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
            Add-FileChange -Journal $journal -Path (Join-Path $junction 'x.txt') -Kind create -AllowedRoots @($root)
        }

        $message | Should Match 'allowed root|reparse'
    }

    It 'refuses to register an allowed root for recursive deletion' {
        $root = Join-Path $TestDrive 'root-delete'
        New-Item -ItemType Directory -Path $root | Out-Null
        $journal = New-TestJournal -Root $root

        $message = Get-JournalExceptionMessage {
            Add-FileChange -Journal $journal -Path $root -Kind directory_create -AllowedRoots @($root)
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
                    -Kind directory_create `
                    -AllowedRoots $roots
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
            -Kind directory_create `
            -AllowedRoots @($parent, $child) | Out-Null

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
                -Kind directory_create `
                -AllowedRoots $roots | Out-Null
            $document = Read-TestJournal -Journal $journal
            $document.Changes[0].Path = $child
            Write-TestAuthenticatedJournal `
                -Journal $journal `
                -Document $document `
                -Root $parent
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
            -Kind directory_create `
            -AllowedRoots $roots | Out-Null
        $document = Read-TestJournal -Journal $journal
        $document.Changes[0].Path = $alias
        Write-TestAuthenticatedJournal `
            -Journal $journal `
            -Document $document `
            -Root $parent
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
            Invoke-JournalRollback -Journal $journal -AllowedRoots @($root)
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
        Add-TestFileChange -Journal $journal -Root $root -Path $insidePath -Kind create
        $document = Read-TestJournal -Journal $journal
        $document.AllowedRoots = @($outside)
        $document.Changes[0].Path = $outsidePath
        Write-TestJournal -Journal $journal -Document $document

        $message = Get-JournalExceptionMessage {
            Invoke-JournalRollback -Journal $journal -AllowedRoots @($root)
        }

        (Test-Path -LiteralPath $outsidePath -PathType Leaf) | Should Be $true
        $message | Should Match 'integrity'
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
        Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind create
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

Describe 'Authenticated journal attack regressions' {
    BeforeAll {
        . $journalLibrary
    }

    It 'does not follow a junction and recursively delete its target' {
        $root = Join-Path $TestDrive 'junction-delete-attack'
        $target = Join-Path $root 'target'
        $alias = Join-Path $root 'alias'
        New-Item -ItemType Directory -Path $target -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $target 'keep.txt'), 'keep')
        $journal = New-TestJournal -Root $root
        Add-TestFileChange -Journal $journal -Root $root -Path $alias -Kind directory_create
        New-Item -ItemType Directory -Path $alias | Out-Null
        Confirm-TestFileChange -Journal $journal -Root $root -Path $alias
        Remove-Item -LiteralPath $alias -Force
        New-Item -ItemType Junction -Path $alias -Target $target | Out-Null

        $result = Invoke-JournalRollback -Journal $journal -AllowedRoots @($root)

        @($result.Failed).Count | Should Be 1
        (Test-Path -LiteralPath $target -PathType Container) | Should Be $true
        [IO.File]::ReadAllText((Join-Path $target 'keep.txt')) | Should Be 'keep'
        (Test-Path -LiteralPath $alias) | Should Be $true
    }

    It 'does not authorize Add-FileChange from tampered audit roots' {
        $root = Join-Path $TestDrive 'add-root'
        $outside = Join-Path $TestDrive 'add-outside'
        New-Item -ItemType Directory -Path $root, $outside | Out-Null
        $journal = New-TestJournal -Root $root
        $document = Read-TestJournal -Journal $journal
        $document.AllowedRoots = @($outside)
        Write-TestJournal -Journal $journal -Document $document

        $message = Get-JournalExceptionMessage {
            Add-FileChange `
                -Journal $journal `
                -Path (Join-Path $outside 'created.txt') `
                -Kind create `
                -AllowedRoots @($root)
        }

        $message | Should Match 'allowed root|integrity'
    }

    It 'rejects a backup path rebound to another journal backup' {
        $root = Join-Path $TestDrive 'backup-rebind'
        New-Item -ItemType Directory -Path $root | Out-Null
        $first = Join-Path $root 'first.txt'
        $second = Join-Path $root 'second.txt'
        [IO.File]::WriteAllText($first, 'first')
        [IO.File]::WriteAllText($second, 'second')
        $journal = New-TestJournal -Root $root
        Add-TestFileChange -Journal $journal -Root $root -Path $first -Kind modify
        Add-TestFileChange -Journal $journal -Root $root -Path $second -Kind modify
        $document = Read-TestJournal -Journal $journal
        $document.Changes[0].BackupPath = $document.Changes[1].BackupPath
        $document.Changes[0].BackupSha256 = $document.Changes[1].BackupSha256
        Write-TestAuthenticatedJournal `
            -Journal $journal `
            -Document $document `
            -Root $root

        $result = Invoke-JournalRollback -Journal $journal -AllowedRoots @($root)

        @($result.Failed).Count | Should Be 1
        $result.Failed[0].Error | Should Match 'backup'
    }

    It 'rejects duplicate JSON property names' {
        $root = Join-Path $TestDrive 'duplicate-json'
        New-Item -ItemType Directory -Path $root | Out-Null
        $journal = New-TestJournal -Root $root
        $json = [IO.File]::ReadAllText($journal.JournalPath)
        $json = $json -replace '"Version"\s*:\s*2', '"Version":2,"Version":2'
        [IO.File]::WriteAllText($journal.JournalPath, $json)

        $message = Get-JournalExceptionMessage {
            Invoke-JournalRollback -Journal $journal -AllowedRoots @($root)
        }

        $message | Should Match 'duplicate|journal'
    }

    It 'rejects unknown and incorrectly cased JSON properties' {
        $root = Join-Path $TestDrive 'unknown-json'
        New-Item -ItemType Directory -Path $root | Out-Null
        $journal = New-TestJournal -Root $root
        $json = [IO.File]::ReadAllText($journal.JournalPath)
        $json = $json -replace '"Schema"', '"schema"'
        [IO.File]::WriteAllText($journal.JournalPath, $json)

        $message = Get-JournalExceptionMessage {
            Invoke-TestRollback -Journal $journal -Root $root
        }

        $message | Should Match 'unknown|schema|property'
    }

    It 'rejects JSON properties with the wrong type' {
        $root = Join-Path $TestDrive 'wrong-type-json'
        New-Item -ItemType Directory -Path $root | Out-Null
        $journal = New-TestJournal -Root $root
        $json = [IO.File]::ReadAllText($journal.JournalPath)
        $json = $json -replace '"Version"\s*:\s*2', '"Version":"2"'
        [IO.File]::WriteAllText($journal.JournalPath, $json)

        $message = Get-JournalExceptionMessage {
            Invoke-TestRollback -Journal $journal -Root $root
        }

        $message | Should Match 'type|version|schema'
    }

    It 'rejects a schema-valid payload whose integrity is tampered' {
        $root = Join-Path $TestDrive 'integrity-json'
        New-Item -ItemType Directory -Path $root | Out-Null
        $journal = New-TestJournal -Root $root
        $json = [IO.File]::ReadAllText($journal.JournalPath)
        $json = $json -replace '"UpdatedAtUtc"\s*:\s*"[^"]+"', '"UpdatedAtUtc":"2001-01-01T00:00:00.0000000Z"'
        [IO.File]::WriteAllText($journal.JournalPath, $json)

        $message = Get-JournalExceptionMessage {
            Invoke-TestRollback -Journal $journal -Root $root
        }

        $message | Should Match 'integrity'
    }

    It 'leaves an unconfirmed create as a residual' {
        $root = Join-Path $TestDrive 'unconfirmed-create'
        New-Item -ItemType Directory -Path $root | Out-Null
        $path = Join-Path $root 'created.txt'
        $journal = New-TestJournal -Root $root
        Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind create
        [IO.File]::WriteAllText($path, 'created')

        $result = Invoke-TestRollback -Journal $journal -Root $root

        @($result.Residuals).Count | Should Be 1
        (Test-Path -LiteralPath $path -PathType Leaf) | Should Be $true
    }

    It 'refuses to delete a confirmed create replaced with another file' {
        $root = Join-Path $TestDrive 'create-identity'
        New-Item -ItemType Directory -Path $root | Out-Null
        $path = Join-Path $root 'created.txt'
        $journal = New-TestJournal -Root $root
        Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind create
        [IO.File]::WriteAllText($path, 'original create')
        Confirm-TestFileChange -Journal $journal -Root $root -Path $path
        Remove-Item -LiteralPath $path -Force
        [IO.File]::WriteAllText($path, 'replacement')

        $result = Invoke-TestRollback -Journal $journal -Root $root

        @($result.Failed).Count | Should Be 1
        [IO.File]::ReadAllText($path) | Should Be 'replacement'
    }

    It 'refuses to overwrite a modified file whose identity changed' {
        $root = Join-Path $TestDrive 'modify-identity'
        New-Item -ItemType Directory -Path $root | Out-Null
        $path = Join-Path $root 'modified.txt'
        [IO.File]::WriteAllText($path, 'original')
        $journal = New-TestJournal -Root $root
        Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind modify
        Remove-Item -LiteralPath $path -Force
        [IO.File]::WriteAllText($path, 'replacement')

        $result = Invoke-TestRollback -Journal $journal -Root $root

        @($result.Failed).Count | Should Be 1
        [IO.File]::ReadAllText($path) | Should Be 'replacement'
    }

    It 'requires a delete target to remain absent before restore' {
        $root = Join-Path $TestDrive 'delete-present'
        New-Item -ItemType Directory -Path $root | Out-Null
        $path = Join-Path $root 'deleted.txt'
        [IO.File]::WriteAllText($path, 'original')
        $journal = New-TestJournal -Root $root
        Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind delete

        $result = Invoke-TestRollback -Journal $journal -Root $root

        @($result.Failed).Count | Should Be 1
        [IO.File]::ReadAllText($path) | Should Be 'original'
    }

    It 'binds backups to the entry id and leaves no temporary artifacts' {
        $root = Join-Path $TestDrive 'durable-backup'
        New-Item -ItemType Directory -Path $root | Out-Null
        $path = Join-Path $root 'modified.txt'
        [IO.File]::WriteAllText($path, 'original')
        $journal = New-TestJournal -Root $root
        $entry = Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind modify
        $document = Read-TestJournal -Journal $journal
        $journalDirectory = Split-Path -Parent $journal.JournalPath

        (Split-Path -Leaf $document.Changes[0].BackupPath) | Should Be "$($entry.Id).bin"
        @(Get-ChildItem -LiteralPath $journalDirectory -Recurse -Force |
            Where-Object { $_.Name -match '\.tmp-' }).Count | Should Be 0
        (Get-Content -LiteralPath $journalLibrary -Raw) |
            Should Match '\.Flush\(\$true\)'
    }
}

Describe 'Journal storage path attacks' {
    BeforeAll {
        . $journalLibrary
    }

    It 'rejects a state root junction before creating journal files' {
        $root = Join-Path $TestDrive 'state-junction-root'
        $outside = Join-Path $TestDrive 'state-junction-outside'
        New-Item -ItemType Directory -Path $root, $outside | Out-Null
        New-Item -ItemType Junction -Path (Join-Path $root '.state') -Target $outside |
            Out-Null

        $message = Get-JournalExceptionMessage {
            New-TestJournal -Root $root -OperationId 'state-junction'
        }

        $message | Should Match 'reparse|junction'
        @(Get-ChildItem -LiteralPath $outside -Force).Count | Should Be 0
    }

    It 'rejects a journals directory junction before creating operation files' {
        $root = Join-Path $TestDrive 'journals-junction-root'
        $outside = Join-Path $TestDrive 'journals-junction-outside'
        $state = Join-Path $root '.state'
        New-Item -ItemType Directory -Path $state, $outside -Force | Out-Null
        New-Item -ItemType Junction -Path (Join-Path $state 'journals') -Target $outside |
            Out-Null

        $message = Get-JournalExceptionMessage {
            New-TestJournal -Root $root -OperationId 'journals-junction'
        }

        $message | Should Match 'reparse|junction'
        @(Get-ChildItem -LiteralPath $outside -Force).Count | Should Be 0
    }

    It 'rejects a backups directory junction before creating backup files' {
        $root = Join-Path $TestDrive 'backups-junction-root'
        $outside = Join-Path $TestDrive 'backups-junction-outside'
        New-Item -ItemType Directory -Path $root, $outside | Out-Null
        $path = Join-Path $root 'modified.txt'
        [IO.File]::WriteAllText($path, 'original')
        $journal = New-TestJournal -Root $root -OperationId 'backups-junction'
        $operationDirectory = Split-Path -Parent $journal.JournalPath
        New-Item -ItemType Junction `
            -Path (Join-Path $operationDirectory 'backups') `
            -Target $outside | Out-Null

        $message = Get-JournalExceptionMessage {
            Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind modify
        }

        $message | Should Match 'reparse|junction'
        @(Get-ChildItem -LiteralPath $outside -Force).Count | Should Be 0
    }

    It 'rejects a reparse lock path before opening it for every journal entry point' {
        foreach ($entryPoint in @('Add', 'Confirm', 'External', 'Rollback')) {
            $root = Join-Path $TestDrive "lock-junction-$entryPoint"
            $outside = Join-Path $TestDrive "lock-junction-outside-$entryPoint"
            New-Item -ItemType Directory -Path $root, $outside | Out-Null
            $path = Join-Path $root 'created.txt'
            $operationId = "lock-junction-$($entryPoint.ToLowerInvariant())"
            $journal = New-TestJournal -Root $root -OperationId $operationId
            if ($entryPoint -eq 'Confirm') {
                Add-TestFileChange -Journal $journal -Root $root -Path $path -Kind create |
                    Out-Null
                [IO.File]::WriteAllText($path, 'created')
            }
            $lockPath = Join-Path (
                Split-Path -Parent (Split-Path -Parent $journal.JournalPath)
            ) "$operationId.lock"
            Remove-Item -LiteralPath $lockPath -Force
            New-Item -ItemType Junction -Path $lockPath -Target $outside | Out-Null

            $message = Get-JournalExceptionMessage {
                switch ($entryPoint) {
                    'Add' {
                        Add-TestFileChange `
                            -Journal $journal `
                            -Root $root `
                            -Path $path `
                            -Kind create | Out-Null
                    }
                    'Confirm' {
                        Confirm-TestFileChange `
                            -Journal $journal `
                            -Root $root `
                            -Path $path | Out-Null
                    }
                    'External' {
                        Add-ExternalChange `
                            -Journal $journal `
                            -Description 'external' `
                            -RollbackCommand '' `
                            -AllowedRoots @($root) | Out-Null
                    }
                    'Rollback' {
                        Invoke-TestRollback -Journal $journal -Root $root | Out-Null
                    }
                }
            }

            $message | Should Match 'reparse|junction'
            @(Get-ChildItem -LiteralPath $outside -Force).Count | Should Be 0
        }
    }

    It 'rejects replacement of the lock parent before creating an external lock file' {
        $root = Join-Path $TestDrive 'lock-parent-root'
        $outside = Join-Path $TestDrive 'lock-parent-outside'
        New-Item -ItemType Directory -Path $root, $outside | Out-Null
        $journal = New-TestJournal -Root $root -OperationId 'lock-parent'
        $journalsDirectory = Split-Path -Parent (
            Split-Path -Parent $journal.JournalPath
        )
        Remove-Item -LiteralPath $journalsDirectory -Recurse -Force
        New-Item -ItemType Junction -Path $journalsDirectory -Target $outside | Out-Null

        $message = Get-JournalExceptionMessage {
            Add-ExternalChange `
                -Journal $journal `
                -Description 'external' `
                -RollbackCommand '' `
                -AllowedRoots @($root) | Out-Null
        }

        $message | Should Match 'reparse|junction'
        @(Get-ChildItem -LiteralPath $outside -Force).Count | Should Be 0
    }

    It 'rejects an operation directory junction before journal or temp access' {
        $root = Join-Path $TestDrive 'operation-parent-root'
        $outside = Join-Path $TestDrive 'operation-parent-outside'
        New-Item -ItemType Directory -Path $root, $outside | Out-Null
        $journal = New-TestJournal -Root $root -OperationId 'operation-parent'
        $operationDirectory = Split-Path -Parent $journal.JournalPath
        Remove-Item -LiteralPath $operationDirectory -Recurse -Force
        New-Item -ItemType Junction -Path $operationDirectory -Target $outside |
            Out-Null

        $message = Get-JournalExceptionMessage {
            Add-ExternalChange `
                -Journal $journal `
                -Description 'external' `
                -RollbackCommand '' `
                -AllowedRoots @($root) | Out-Null
        }

        $message | Should Match 'reparse|junction'
        @(Get-ChildItem -LiteralPath $outside -Force).Count | Should Be 0
    }

    It 'does not register the state root as a recursive deletion target' {
        $root = Join-Path $TestDrive 'state-delete-target'
        New-Item -ItemType Directory -Path $root | Out-Null
        $journal = New-TestJournal -Root $root -OperationId 'state-delete-target'
        $stateRoot = Join-Path $root '.state'

        $message = Get-JournalExceptionMessage {
            Add-TestFileChange `
                -Journal $journal `
                -Root $root `
                -Path $stateRoot `
                -Kind directory_create | Out-Null
        }

        $message | Should Match 'state|journal|storage|root'
    }

    It 'creates missing journal storage directories one level at a time' {
        $root = Join-Path $TestDrive 'missing-storage'
        $codexRoot = Join-Path $root '.codex-test'
        $stateRoot = Join-Path $root 'level-one\level-two\.state'
        New-Item -ItemType Directory -Path $root, $codexRoot | Out-Null

        $journal = New-ChangeJournal `
            -OperationId 'missing-storage' `
            -AllowedRoots @($root) `
            -WorkspaceRoot $root `
            -CodexRoot $codexRoot `
            -StateRoot $stateRoot

        foreach ($path in @(
            (Join-Path $root 'level-one'),
            (Join-Path $root 'level-one\level-two'),
            $stateRoot,
            (Join-Path $stateRoot 'journals'),
            (Join-Path $stateRoot 'journals\missing-storage')
        )) {
            (Test-Path -LiteralPath $path -PathType Container) | Should Be $true
            (
                [IO.File]::GetAttributes($path) -band
                [IO.FileAttributes]::ReparsePoint
            ) | Should Be 0
        }
        (Test-Path -LiteralPath $journal.JournalPath -PathType Leaf) |
            Should Be $true
    }
}
