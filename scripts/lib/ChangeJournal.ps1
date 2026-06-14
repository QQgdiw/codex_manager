$script:ChangeJournalSchema = 'codex.change-journal'
$script:ChangeJournalVersion = 1

if (-not ('ChangeJournalPathRuntime' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
using System.Text;

public static class ChangeJournalPathRuntime
{
    private const uint FileReadAttributes = 0x80;
    private const uint ShareRead = 0x1;
    private const uint ShareWrite = 0x2;
    private const uint ShareDelete = 0x4;
    private const uint OpenExisting = 3;
    private const uint BackupSemantics = 0x02000000;

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern SafeFileHandle CreateFile(
        string fileName,
        uint desiredAccess,
        uint shareMode,
        IntPtr securityAttributes,
        uint creationDisposition,
        uint flagsAndAttributes,
        IntPtr templateFile
    );

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern uint GetFinalPathNameByHandle(
        SafeFileHandle file,
        StringBuilder path,
        uint pathLength,
        uint flags
    );

    public static string GetFinalPath(string path)
    {
        using (SafeFileHandle handle = CreateFile(
            path,
            FileReadAttributes,
            ShareRead | ShareWrite | ShareDelete,
            IntPtr.Zero,
            OpenExisting,
            BackupSemantics,
            IntPtr.Zero
        ))
        {
            if (handle.IsInvalid)
            {
                throw new IOException(
                    "Unable to resolve path.",
                    Marshal.GetExceptionForHR(Marshal.GetHRForLastWin32Error())
                );
            }

            StringBuilder buffer = new StringBuilder(32768);
            uint length = GetFinalPathNameByHandle(
                handle,
                buffer,
                (uint)buffer.Capacity,
                0
            );
            if (length == 0 || length >= buffer.Capacity)
            {
                throw new IOException("Unable to resolve final path.");
            }

            string result = buffer.ToString();
            if (result.StartsWith(@"\\?\UNC\", StringComparison.OrdinalIgnoreCase))
            {
                return @"\\" + result.Substring(8);
            }
            if (result.StartsWith(@"\\?\", StringComparison.OrdinalIgnoreCase))
            {
                return result.Substring(4);
            }
            return result;
        }
    }
}
'@
}

function Get-ChangeJournalWorkspaceRoot {
    $root = & git -C ([Environment]::CurrentDirectory) rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($root)) {
        return [IO.Path]::GetFullPath("$root")
    }
    return [IO.Path]::GetFullPath([Environment]::CurrentDirectory)
}

function Assert-NoParentTraversal {
    param([Parameter(Mandatory = $true)][string]$Path)

    $segments = $Path -split '[\\/]'
    if ($segments -contains '..') {
        throw "Path contains a parent traversal segment: $Path"
    }
}

function Get-CanonicalJournalPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$RejectParentTraversal
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'Path must not be empty.'
    }
    if ($RejectParentTraversal) {
        Assert-NoParentTraversal -Path $Path
    }

    $fullPath = [IO.Path]::GetFullPath($Path)
    $pending = New-Object 'System.Collections.Generic.List[string]'
    $cursor = $fullPath
    while (-not (Test-Path -LiteralPath $cursor)) {
        $leaf = Split-Path -Leaf $cursor
        if ([string]::IsNullOrEmpty($leaf)) {
            throw "Unable to resolve path: $Path"
        }
        $pending.Insert(0, $leaf)
        $parent = Split-Path -Parent $cursor
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $cursor) {
            throw "Unable to resolve path: $Path"
        }
        $cursor = $parent
    }

    $resolved = [ChangeJournalPathRuntime]::GetFinalPath($cursor)
    foreach ($segment in $pending) {
        $resolved = Join-Path $resolved $segment
    }
    return [IO.Path]::GetFullPath($resolved).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
}

function Test-PathWithinRoot {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root
    )

    if ($Path.Equals($Root, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    $prefix = $Root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    return $Path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
}

function Assert-ManagedJournalPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][object[]]$AllowedRoots,
        [switch]$RejectRoot
    )

    $canonical = Get-CanonicalJournalPath -Path $Path -RejectParentTraversal
    $matchedRoot = $null
    foreach ($root in @($AllowedRoots)) {
        if (Test-PathWithinRoot -Path $canonical -Root "$root") {
            $matchedRoot = "$root"
            break
        }
    }
    if ($null -eq $matchedRoot) {
        throw "Path is outside every allowed root: $Path"
    }
    if ($RejectRoot -and $canonical.Equals(
        $matchedRoot,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Refusing to register an allowed root for recursive deletion: $Path"
    }
    return $canonical
}

function Write-ChangeJournalDocument {
    param(
        [Parameter(Mandatory = $true)][object]$Document,
        [Parameter(Mandatory = $true)][string]$JournalPath
    )

    $Document.UpdatedAtUtc = [DateTime]::UtcNow.ToString('o')
    $directory = Split-Path -Parent $JournalPath
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $temporaryPath = Join-Path $directory (
        '.journal.{0}.tmp' -f [Guid]::NewGuid().ToString('N')
    )
    $replacedPath = Join-Path $directory (
        '.journal.{0}.previous.tmp' -f [Guid]::NewGuid().ToString('N')
    )
    $encoding = New-Object Text.UTF8Encoding($false)
    try {
        $json = $Document | ConvertTo-Json -Depth 20
        [IO.File]::WriteAllText($temporaryPath, $json, $encoding)
        if (Test-Path -LiteralPath $JournalPath -PathType Leaf) {
            [IO.File]::Replace($temporaryPath, $JournalPath, $replacedPath)
        }
        else {
            [IO.File]::Move($temporaryPath, $JournalPath)
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
        if (Test-Path -LiteralPath $replacedPath) {
            Remove-Item -LiteralPath $replacedPath -Force
        }
    }
}

function Read-ChangeJournalDocument {
    param([Parameter(Mandatory = $true)][object]$Journal)

    if ($null -eq $Journal -or [string]::IsNullOrWhiteSpace("$($Journal.JournalPath)")) {
        throw 'Journal must contain JournalPath.'
    }
    $journalPath = [IO.Path]::GetFullPath("$($Journal.JournalPath)")
    if (-not (Test-Path -LiteralPath $journalPath -PathType Leaf)) {
        throw "Change journal does not exist: $journalPath"
    }
    try {
        $document = [IO.File]::ReadAllText($journalPath) | ConvertFrom-Json
    }
    catch {
        throw "Change journal is corrupted or invalid: $journalPath"
    }
    if (
        $null -eq $document -or
        $document.Schema -ne $script:ChangeJournalSchema -or
        [int]$document.Version -ne $script:ChangeJournalVersion -or
        [string]::IsNullOrWhiteSpace("$($document.OperationId)") -or
        $null -eq $document.AllowedRoots -or
        $null -eq $document.Changes
    ) {
        throw "Change journal schema or version is invalid: $journalPath"
    }

    $journalDirectory = Get-CanonicalJournalPath -Path (Split-Path -Parent $journalPath)
    if (-not $journalDirectory.Equals(
        "$($document.JournalDirectory)",
        [StringComparison]::OrdinalIgnoreCase
    )) {
        throw 'Change journal directory metadata does not match its location.'
    }

    return [pscustomobject]@{
        Path = $journalPath
        Directory = $journalDirectory
        Document = $document
    }
}

function New-ChangeJournal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationId,

        [string[]]$AllowedRoots = @(),

        [string]$WorkspaceRoot = (Get-ChangeJournalWorkspaceRoot),

        [string]$CodexRoot = (Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex'),

        [string]$StateRoot
    )

    if ($OperationId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') {
        throw 'OperationId contains unsupported characters or length.'
    }

    $workspaceCanonical = Get-CanonicalJournalPath -Path $WorkspaceRoot
    if ([string]::IsNullOrWhiteSpace($StateRoot)) {
        $StateRoot = Join-Path $workspaceCanonical '.state'
    }
    $allRoots = @($workspaceCanonical, $CodexRoot) + @($AllowedRoots)
    $canonicalRoots = @(
        $allRoots |
            Where-Object { -not [string]::IsNullOrWhiteSpace("$_") } |
            ForEach-Object { Get-CanonicalJournalPath -Path "$_" } |
            Sort-Object -Unique
    )

    $stateCanonical = Get-CanonicalJournalPath -Path $StateRoot
    if (-not (Test-PathWithinRoot -Path $stateCanonical -Root $workspaceCanonical)) {
        $stateAllowed = $false
        foreach ($root in $canonicalRoots) {
            if (Test-PathWithinRoot -Path $stateCanonical -Root $root) {
                $stateAllowed = $true
                break
            }
        }
        if (-not $stateAllowed) {
            throw 'StateRoot must be inside a managed allowed root.'
        }
    }

    $journalDirectory = Join-Path $stateCanonical (
        'journals\{0}' -f $OperationId
    )
    New-Item -ItemType Directory -Path $journalDirectory -Force | Out-Null
    $journalDirectory = Get-CanonicalJournalPath -Path $journalDirectory
    $journalPath = Join-Path $journalDirectory 'journal.json'
    if (Test-Path -LiteralPath $journalPath) {
        throw "A journal already exists for operation: $OperationId"
    }

    $now = [DateTime]::UtcNow.ToString('o')
    $document = [pscustomobject]@{
        Schema = $script:ChangeJournalSchema
        Version = $script:ChangeJournalVersion
        OperationId = $OperationId
        WorkspaceRoot = $workspaceCanonical
        JournalDirectory = $journalDirectory
        AllowedRoots = @($canonicalRoots)
        CreatedAtUtc = $now
        UpdatedAtUtc = $now
        Changes = @()
    }
    Write-ChangeJournalDocument -Document $document -JournalPath $journalPath
    return [pscustomobject]@{
        OperationId = $OperationId
        JournalPath = $journalPath
    }
}

function Add-FileChange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$Journal,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]
        [ValidateSet('create', 'modify', 'delete', 'directory_create')]
        [string]$Kind
    )

    $loaded = Read-ChangeJournalDocument -Journal $Journal
    $rejectRoot = $Kind -eq 'directory_create'
    $canonical = Assert-ManagedJournalPath `
        -Path $Path `
        -AllowedRoots @($loaded.Document.AllowedRoots) `
        -RejectRoot:$rejectRoot
    foreach ($existing in @($loaded.Document.Changes)) {
        if (
            $existing.Type -eq 'file' -and
            "$($existing.Path)".Equals(
                $canonical,
                [StringComparison]::OrdinalIgnoreCase
            )
        ) {
            return $existing
        }
    }

    $existsAsFile = Test-Path -LiteralPath $canonical -PathType Leaf
    $existsAsDirectory = Test-Path -LiteralPath $canonical -PathType Container
    if ($Kind -in @('modify', 'delete') -and -not $existsAsFile) {
        throw "Kind '$Kind' requires an existing file: $canonical"
    }
    if ($Kind -eq 'create' -and ($existsAsFile -or $existsAsDirectory)) {
        throw "Kind 'create' requires an absent path: $canonical"
    }
    if ($Kind -eq 'directory_create' -and ($existsAsFile -or $existsAsDirectory)) {
        throw "Kind 'directory_create' requires an absent path: $canonical"
    }

    $backupPath = $null
    $backupSha256 = $null
    $metadata = $null
    if ($Kind -in @('modify', 'delete')) {
        $backupDirectory = Join-Path $loaded.Directory 'backups'
        New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
        $backupPath = Join-Path $backupDirectory (
            '{0}.bin' -f [Guid]::NewGuid().ToString('N')
        )
        [IO.File]::Copy($canonical, $backupPath, $false)
        $backupSha256 = (Get-FileHash -LiteralPath $backupPath -Algorithm SHA256).Hash.ToLowerInvariant()
        $item = Get-Item -LiteralPath $canonical -Force
        $metadata = [pscustomobject]@{
            Attributes = [int]$item.Attributes
            CreationTimeUtc = $item.CreationTimeUtc.ToString('o')
            LastWriteTimeUtc = $item.LastWriteTimeUtc.ToString('o')
            LastAccessTimeUtc = $item.LastAccessTimeUtc.ToString('o')
        }
    }

    $entry = [pscustomobject]@{
        Id = [Guid]::NewGuid().ToString('N')
        Type = 'file'
        Kind = $Kind
        Path = $canonical
        BackupPath = $backupPath
        BackupSha256 = $backupSha256
        Metadata = $metadata
        RecordedAtUtc = [DateTime]::UtcNow.ToString('o')
        RolledBack = $false
        RolledBackAtUtc = $null
    }
    $loaded.Document.Changes = @($loaded.Document.Changes) + @($entry)
    Write-ChangeJournalDocument `
        -Document $loaded.Document `
        -JournalPath $loaded.Path
    return $entry
}

function Add-ExternalChange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$Journal,
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$RollbackCommand
    )

    $loaded = Read-ChangeJournalDocument -Journal $Journal
    $entry = [pscustomobject]@{
        Id = [Guid]::NewGuid().ToString('N')
        Type = 'external'
        Description = $Description
        RollbackCommand = $RollbackCommand
        RecordedAtUtc = [DateTime]::UtcNow.ToString('o')
        RolledBack = $false
        RolledBackAtUtc = $null
    }
    $loaded.Document.Changes = @($loaded.Document.Changes) + @($entry)
    Write-ChangeJournalDocument `
        -Document $loaded.Document `
        -JournalPath $loaded.Path
    return $entry
}

function Assert-ValidJournalBackup {
    param(
        [Parameter(Mandatory = $true)][object]$Entry,
        [Parameter(Mandatory = $true)][object]$Loaded
    )

    if ([string]::IsNullOrWhiteSpace("$($Entry.BackupPath)")) {
        throw 'Journal backup path is missing.'
    }
    $backup = Get-CanonicalJournalPath -Path "$($Entry.BackupPath)"
    $backupRoot = Join-Path $Loaded.Directory 'backups'
    $backupRoot = Get-CanonicalJournalPath -Path $backupRoot
    if (-not (Test-PathWithinRoot -Path $backup -Root $backupRoot)) {
        throw 'Journal backup path is outside the journal backup directory.'
    }
    if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
        throw 'Journal backup file is missing.'
    }
    $actualHash = (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne "$($Entry.BackupSha256)".ToLowerInvariant()) {
        throw 'Journal backup SHA256 hash does not match.'
    }
    return $backup
}

function Restore-JournalFile {
    param(
        [Parameter(Mandatory = $true)][object]$Entry,
        [Parameter(Mandatory = $true)][object]$Loaded
    )

    $target = Assert-ManagedJournalPath `
        -Path "$($Entry.Path)" `
        -AllowedRoots @($Loaded.Document.AllowedRoots)
    switch ("$($Entry.Kind)") {
        'create' {
            if (Test-Path -LiteralPath $target -PathType Container) {
                throw 'Created file path is now a directory.'
            }
            if (Test-Path -LiteralPath $target -PathType Leaf) {
                [IO.File]::SetAttributes($target, [IO.FileAttributes]::Normal)
                Remove-Item -LiteralPath $target -Force
            }
        }
        'directory_create' {
            $target = Assert-ManagedJournalPath `
                -Path "$($Entry.Path)" `
                -AllowedRoots @($Loaded.Document.AllowedRoots) `
                -RejectRoot
            if (Test-Path -LiteralPath $target -PathType Leaf) {
                throw 'Created directory path is now a file.'
            }
            if (Test-Path -LiteralPath $target -PathType Container) {
                Remove-Item -LiteralPath $target -Recurse -Force
            }
        }
        { $_ -in @('modify', 'delete') } {
            $backup = Assert-ValidJournalBackup -Entry $Entry -Loaded $Loaded
            $parent = Split-Path -Parent $target
            if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }
            if (Test-Path -LiteralPath $target -PathType Container) {
                throw 'Restored file path is now a directory.'
            }
            if (Test-Path -LiteralPath $target -PathType Leaf) {
                [IO.File]::SetAttributes($target, [IO.FileAttributes]::Normal)
            }
            [IO.File]::Copy($backup, $target, $true)
            $metadata = $Entry.Metadata
            [IO.File]::SetCreationTimeUtc(
                $target,
                [DateTime]::Parse(
                    "$($metadata.CreationTimeUtc)",
                    [Globalization.CultureInfo]::InvariantCulture,
                    [Globalization.DateTimeStyles]::RoundtripKind
                )
            )
            [IO.File]::SetLastWriteTimeUtc(
                $target,
                [DateTime]::Parse(
                    "$($metadata.LastWriteTimeUtc)",
                    [Globalization.CultureInfo]::InvariantCulture,
                    [Globalization.DateTimeStyles]::RoundtripKind
                )
            )
            [IO.File]::SetLastAccessTimeUtc(
                $target,
                [DateTime]::Parse(
                    "$($metadata.LastAccessTimeUtc)",
                    [Globalization.CultureInfo]::InvariantCulture,
                    [Globalization.DateTimeStyles]::RoundtripKind
                )
            )
            [IO.File]::SetAttributes(
                $target,
                [IO.FileAttributes][int]$metadata.Attributes
            )
        }
        default {
            throw "Unsupported journal file change kind: $($Entry.Kind)"
        }
    }
    return $target
}

function Invoke-JournalRollback {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][object]$Journal)

    $loaded = Read-ChangeJournalDocument -Journal $Journal
    $succeeded = New-Object 'System.Collections.Generic.List[object]'
    $failed = New-Object 'System.Collections.Generic.List[object]'
    $residuals = New-Object 'System.Collections.Generic.List[object]'
    $changes = @($loaded.Document.Changes)

    for ($index = $changes.Count - 1; $index -ge 0; $index--) {
        $entry = $changes[$index]
        if ($entry.Type -eq 'external') {
            $residuals.Add([pscustomobject]@{
                Id = $entry.Id
                Type = 'external'
                Description = $entry.Description
                RollbackCommand = $entry.RollbackCommand
                Reason = 'String rollback commands are recorded but never executed.'
            })
            continue
        }
        if ($entry.Type -ne 'file') {
            $failed.Add([pscustomobject]@{
                Id = $entry.Id
                Path = $entry.Path
                Error = "Unsupported journal change type: $($entry.Type)"
            })
            continue
        }
        if ([bool]$entry.RolledBack) {
            $succeeded.Add([pscustomobject]@{
                Id = $entry.Id
                Path = $entry.Path
                Kind = $entry.Kind
                AlreadyRolledBack = $true
            })
            continue
        }

        try {
            $target = Restore-JournalFile -Entry $entry -Loaded $loaded
            $entry.RolledBack = $true
            $entry.RolledBackAtUtc = [DateTime]::UtcNow.ToString('o')
            Write-ChangeJournalDocument `
                -Document $loaded.Document `
                -JournalPath $loaded.Path
            $succeeded.Add([pscustomobject]@{
                Id = $entry.Id
                Path = $target
                Kind = $entry.Kind
                AlreadyRolledBack = $false
            })
        }
        catch {
            $failed.Add([pscustomobject]@{
                Id = $entry.Id
                Path = $entry.Path
                Kind = $entry.Kind
                Error = $_.Exception.Message
            })
        }
    }

    $status = if ($failed.Count -gt 0) {
        'Failed'
    }
    elseif ($residuals.Count -gt 0) {
        'Partial'
    }
    else {
        'Succeeded'
    }
    return [pscustomobject]@{
        Status = $status
        Succeeded = $succeeded.ToArray()
        Failed = $failed.ToArray()
        Residuals = $residuals.ToArray()
    }
}
