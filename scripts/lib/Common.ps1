$script:ManagedProcessOutputLineLimit = 50
$script:ManagedProcessOutputEdgeLineCount = 25
$script:ManagedProcessOutputLineCharacterLimit = 4096

if (-not ('ManagedProcessRuntime' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

public sealed class ManagedProcessOutputCollector
{
    private const int EdgeLineCount = 25;
    private const int LineCharacterLimit = 4096;
    private const int EdgeCharacterCount = LineCharacterLimit / 2;
    private readonly List<string> firstLines = new List<string>(EdgeLineCount);
    private readonly Queue<string> lastLines = new Queue<string>(EdgeLineCount);
    private readonly StringBuilder firstCharacters = new StringBuilder(EdgeCharacterCount);
    private readonly char[] lastCharacters = new char[EdgeCharacterCount];
    private int lastCharacterCount;
    private int lastCharacterIndex;
    private long currentLineCharacterCount;
    private long totalLineCount;
    private bool pendingCarriageReturn;

    public void AddCharacters(char[] characters, int count)
    {
        for (int index = 0; index < count; index++)
        {
            char value = characters[index];
            if (pendingCarriageReturn)
            {
                AddLine();
                pendingCarriageReturn = false;
                if (value == '\n')
                {
                    continue;
                }
            }

            if (value == '\r')
            {
                pendingCarriageReturn = true;
            }
            else if (value == '\n')
            {
                AddLine();
            }
            else
            {
                AddLineCharacter(value);
            }
        }
    }

    public void Complete()
    {
        if (pendingCarriageReturn)
        {
            AddLine();
            pendingCarriageReturn = false;
        }
        else if (currentLineCharacterCount > 0)
        {
            AddLine();
        }
    }

    public string GetText()
    {
        if (totalLineCount == 0)
        {
            return String.Empty;
        }

        List<string> lines = new List<string>(51);
        lines.AddRange(firstLines);
        if (totalLineCount > 50)
        {
            lines.Add(String.Format(
                "[TRUNCATED: {0} lines omitted]",
                totalLineCount - 50
            ));
        }
        lines.AddRange(lastLines);
        return String.Join(Environment.NewLine, lines.ToArray());
    }

    private void AddLineCharacter(char value)
    {
        currentLineCharacterCount++;
        if (firstCharacters.Length < EdgeCharacterCount)
        {
            firstCharacters.Append(value);
            return;
        }

        lastCharacters[lastCharacterIndex] = value;
        lastCharacterIndex = (lastCharacterIndex + 1) % EdgeCharacterCount;
        if (lastCharacterCount < EdgeCharacterCount)
        {
            lastCharacterCount++;
        }
    }

    private void AddLine()
    {
        string line = GetCurrentLine();
        totalLineCount++;
        if (firstLines.Count < EdgeLineCount)
        {
            firstLines.Add(line);
        }
        else
        {
            if (lastLines.Count == EdgeLineCount)
            {
                lastLines.Dequeue();
            }
            lastLines.Enqueue(line);
        }

        firstCharacters.Length = 0;
        lastCharacterCount = 0;
        lastCharacterIndex = 0;
        currentLineCharacterCount = 0;
    }

    private string GetCurrentLine()
    {
        StringBuilder line = new StringBuilder(LineCharacterLimit + 64);
        line.Append(firstCharacters);
        if (currentLineCharacterCount > LineCharacterLimit)
        {
            line.AppendFormat(
                "[TRUNCATED: {0} chars omitted]",
                currentLineCharacterCount - LineCharacterLimit
            );
        }

        int start = lastCharacterCount == EdgeCharacterCount ? lastCharacterIndex : 0;
        for (int offset = 0; offset < lastCharacterCount; offset++)
        {
            line.Append(lastCharacters[(start + offset) % EdgeCharacterCount]);
        }
        return line.ToString();
    }
}

public static class ManagedProcessRuntime
{
    private const uint SnapshotProcesses = 0x00000002;
    private static readonly UTF8Encoding Utf8WithReplacement =
        new UTF8Encoding(false, false);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct ProcessEntry
    {
        public uint Size;
        public uint Usage;
        public uint ProcessId;
        public IntPtr DefaultHeapId;
        public uint ModuleId;
        public uint ThreadCount;
        public uint ParentProcessId;
        public int BasePriority;
        public uint Flags;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
        public string ExecutableFile;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr CreateToolhelp32Snapshot(
        uint flags,
        uint processId
    );

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    private static extern bool Process32First(
        IntPtr snapshot,
        ref ProcessEntry entry
    );

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    private static extern bool Process32Next(
        IntPtr snapshot,
        ref ProcessEntry entry
    );

    [DllImport("kernel32.dll")]
    private static extern bool CloseHandle(IntPtr handle);

    public static Task ConsumeAsync(
        Stream stream,
        ManagedProcessOutputCollector collector
    )
    {
        return Task.Factory.StartNew(
            delegate { Consume(stream, collector); },
            CancellationToken.None,
            TaskCreationOptions.LongRunning,
            TaskScheduler.Default
        );
    }

    public static void TerminateProcessTree(int rootProcessId)
    {
        for (int attempt = 0; attempt < 5; attempt++)
        {
            List<int> processIds = GetProcessTree(rootProcessId);
            for (int index = processIds.Count - 1; index >= 0; index--)
            {
                TerminateProcess(processIds[index]);
            }

            if (processIds.Count == 0)
            {
                return;
            }
            Thread.Sleep(20);
        }
    }

    private static void Consume(
        Stream stream,
        ManagedProcessOutputCollector collector
    )
    {
        Decoder decoder = Utf8WithReplacement.GetDecoder();
        byte[] bytes = new byte[4096];
        char[] characters = new char[4096];
        int byteCount;
        while ((byteCount = stream.Read(bytes, 0, bytes.Length)) > 0)
        {
            int byteIndex = 0;
            while (byteIndex < byteCount)
            {
                int bytesUsed;
                int charactersUsed;
                bool completed;
                decoder.Convert(
                    bytes,
                    byteIndex,
                    byteCount - byteIndex,
                    characters,
                    0,
                    characters.Length,
                    false,
                    out bytesUsed,
                    out charactersUsed,
                    out completed
                );
                byteIndex += bytesUsed;
                collector.AddCharacters(characters, charactersUsed);
            }
        }

        int finalBytesUsed;
        int finalCharactersUsed;
        bool finalCompleted;
        decoder.Convert(
            new byte[0],
            0,
            0,
            characters,
            0,
            characters.Length,
            true,
            out finalBytesUsed,
            out finalCharactersUsed,
            out finalCompleted
        );
        collector.AddCharacters(characters, finalCharactersUsed);
        collector.Complete();
    }

    private static List<int> GetProcessTree(int rootProcessId)
    {
        Dictionary<int, List<int>> children =
            new Dictionary<int, List<int>>();
        IntPtr snapshot = CreateToolhelp32Snapshot(SnapshotProcesses, 0);
        if (snapshot == new IntPtr(-1))
        {
            return new List<int>();
        }

        try
        {
            ProcessEntry entry = new ProcessEntry();
            entry.Size = (uint)Marshal.SizeOf(typeof(ProcessEntry));
            if (Process32First(snapshot, ref entry))
            {
                do
                {
                    int parentId = unchecked((int)entry.ParentProcessId);
                    List<int> childIds;
                    if (!children.TryGetValue(parentId, out childIds))
                    {
                        childIds = new List<int>();
                        children[parentId] = childIds;
                    }
                    childIds.Add(unchecked((int)entry.ProcessId));
                }
                while (Process32Next(snapshot, ref entry));
            }
        }
        finally
        {
            CloseHandle(snapshot);
        }

        List<int> result = new List<int>();
        AddDescendants(rootProcessId, children, result);
        if (IsRunning(rootProcessId))
        {
            result.Insert(0, rootProcessId);
        }
        return result;
    }

    private static void AddDescendants(
        int parentId,
        Dictionary<int, List<int>> children,
        List<int> result
    )
    {
        List<int> childIds;
        if (!children.TryGetValue(parentId, out childIds))
        {
            return;
        }

        foreach (int childId in childIds)
        {
            result.Add(childId);
            AddDescendants(childId, children, result);
        }
    }

    private static bool IsRunning(int processId)
    {
        try
        {
            using (Process process = Process.GetProcessById(processId))
            {
                return !process.HasExited;
            }
        }
        catch
        {
            return false;
        }
    }

    private static void TerminateProcess(int processId)
    {
        try
        {
            using (Process process = Process.GetProcessById(processId))
            {
                if (!process.HasExited)
                {
                    process.Kill();
                    process.WaitForExit(2000);
                }
            }
        }
        catch
        {
        }
    }
}
'@
}

function New-OperationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Data
    )

    if ([string]::IsNullOrWhiteSpace($Status)) {
        throw 'Status must not be empty.'
    }

    return [pscustomobject]@{
        Status = $Status
        Message = $Message
        Data = $Data
        Timestamp = [DateTime]::UtcNow
    }
}

function Protect-LogText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [AllowNull()]
        [string[]]$SensitiveValues = @()
    )

    $protectedText = $Text
    $values = @(
        $SensitiveValues |
            Where-Object { -not [string]::IsNullOrEmpty($_) } |
            Sort-Object -Property Length -Descending
    )

    foreach ($value in $values) {
        $protectedText = $protectedText.Replace($value, '[REDACTED]')
    }

    return $protectedText
}

function ConvertTo-ManagedProcessArgument {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    return '"' + ($Value -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

function Invoke-ManagedProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [AllowNull()]
        [string[]]$Arguments = @(),

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 2147483)]
        [int]$TimeoutSeconds,

        [AllowNull()][string]$WorkingDirectory,
        [AllowNull()][System.Collections.IDictionary]$Environment,
        [switch]$ClearEnvironment
    )

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $FilePath
    $startInfo.Arguments = (@($Arguments) | ForEach-Object {
        ConvertTo-ManagedProcessArgument -Value "$_"
    }) -join ' '
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
        $startInfo.WorkingDirectory = [IO.Path]::GetFullPath($WorkingDirectory)
    }
    if ($ClearEnvironment) {
        $startInfo.EnvironmentVariables.Clear()
    }
    if ($null -ne $Environment) {
        foreach ($key in $Environment.Keys) {
            $name = [string]$key
            if ($name -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
                throw "Managed process environment name is invalid: $name"
            }
            $startInfo.EnvironmentVariables[$name] = [string]$Environment[$key]
        }
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $started = $false

    try {
        try {
            $started = $process.Start()
        }
        catch {
            throw 'Managed process failed to start.'
        }

        if (-not $started) {
            throw 'Managed process failed to start.'
        }

        $stdoutCollector = New-Object ManagedProcessOutputCollector
        $stderrCollector = New-Object ManagedProcessOutputCollector
        $stdoutTask = [ManagedProcessRuntime]::ConsumeAsync(
            $process.StandardOutput.BaseStream,
            $stdoutCollector
        )
        $stderrTask = [ManagedProcessRuntime]::ConsumeAsync(
            $process.StandardError.BaseStream,
            $stderrCollector
        )
        $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)

        if ($timedOut) {
            [ManagedProcessRuntime]::TerminateProcessTree($process.Id)
        }

        $process.WaitForExit()
        [System.Threading.Tasks.Task]::WaitAll(@($stdoutTask, $stderrTask))
        $stdout = $stdoutCollector.GetText()
        $stderr = $stderrCollector.GetText()
        $exitCode = if ($timedOut) { $null } else { $process.ExitCode }

        return [pscustomobject]@{
            ExitCode = $exitCode
            TimedOut = $timedOut
            StdOut = $stdout
            StdErr = $stderr
            DurationMs = [long]$stopwatch.Elapsed.TotalMilliseconds
            Succeeded = (-not $timedOut -and $exitCode -eq 0)
        }
    }
    finally {
        $stopwatch.Stop()
        $process.Dispose()
    }
}
