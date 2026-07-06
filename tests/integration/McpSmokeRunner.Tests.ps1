$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$runnerPath = Join-Path $projectRoot 'scripts\node\mcp-smoke-runner.mjs'
$utf8NoBom = New-Object Text.UTF8Encoding($false)

function Resolve-GitCommonRepositoryRoot {
    param([Parameter(Mandatory = $true)][string]$WorkTreeRoot)

    $commonOutput = & git -C $WorkTreeRoot rev-parse --git-common-dir 2>$null
    if ($LASTEXITCODE -ne 0 -or $null -eq $commonOutput) {
        throw "Unable to resolve git common directory for MCP SDK tests: $WorkTreeRoot"
    }
    $commonDir = ($commonOutput -join [Environment]::NewLine).Trim()
    if ([string]::IsNullOrWhiteSpace($commonDir)) {
        throw "Unable to resolve git common directory for MCP SDK tests: $WorkTreeRoot"
    }
    if (-not [IO.Path]::IsPathRooted($commonDir)) {
        $commonDir = Join-Path $WorkTreeRoot $commonDir
    }
    return Split-Path -Parent ([IO.Path]::GetFullPath($commonDir))
}

function Resolve-McpSdkRoot {
    param([Parameter(Mandatory = $true)][string]$RepositoryRoot)

    $candidate = Join-Path $RepositoryRoot 'MCP\servers\src\sequentialthinking\node_modules\@modelcontextprotocol\sdk\dist\esm\client'
    foreach ($entryPoint in @('index.js', 'stdio.js')) {
        $expectedPath = Join-Path $candidate $entryPoint
        if (-not (Test-Path -LiteralPath $expectedPath -PathType Leaf)) {
            throw "MCP SDK test dependency missing at: $expectedPath"
        }
    }
    return $candidate
}

$repositoryRoot = Resolve-GitCommonRepositoryRoot -WorkTreeRoot $projectRoot
$sdkRoot = Resolve-McpSdkRoot -RepositoryRoot $repositoryRoot
$nodePath = (Get-Command node).Source

function Invoke-TestSmokeRunner {
    param(
        [ValidateSet('success', 'missing', 'timeout', 'initialize-timeout', 'descendant', 'late-detached-exit', 'stderr-flood', 'sensitive-error', 'stubborn')]
        [string]$Mode,
        [int]$TimeoutSeconds = 5,
        [hashtable]$RequestOverrides = @{},
        [switch]$HideNativeCommands
    )
    $root = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $root | Out-Null
    $serverPath = Join-Path $root 'fake-server.mjs'
    $requestPath = Join-Path $root 'request.json'
    $resultPath = Join-Path $root 'result.json'
    $childPidPath = Join-Path $root 'child.pid'
    $stderrPath = Join-Path $root 'stderr.log'
    [IO.File]::WriteAllText($serverPath, @'
import readline from "node:readline";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { writeFileSync } from "node:fs";
const mode = process.argv[2];
const childPidPath = process.argv[3];
if (mode === "descendant") {
  const child = spawn(process.execPath, ["-e", "setInterval(() => {}, 1000)"], {
    detached: true,
    stdio: "ignore"
  });
  writeFileSync(childPidPath, String(child.pid));
  child.unref();
}
if (mode === "stderr-flood") {
  process.stderr.write("SENSITIVE_STDERR_MARKER");
  const chunk = "x".repeat(65536);
  for (let index = 0; index < 256; index += 1) {
    if (!process.stderr.write(chunk)) await once(process.stderr, "drain");
  }
}
if (mode === "stubborn") setInterval(() => {}, 1000);
const input = readline.createInterface({ input: process.stdin });
function send(value) { process.stdout.write(`${JSON.stringify(value)}\n`); }
for await (const line of input) {
  const message = JSON.parse(line);
  if (message.method === "initialize" && mode !== "initialize-timeout") {
    if (mode === "sensitive-error") {
      send({ jsonrpc: "2.0", id: message.id, error: {
        code: -32000, message: "SENSITIVE_SERVER_MARKER"
      }});
    } else {
      send({ jsonrpc: "2.0", id: message.id, result: {
        protocolVersion: "2025-03-26", capabilities: { tools: {} },
        serverInfo: { name: "fixture", version: "1.0.0" }
      }});
    }
  } else if (message.method === "tools/list") {
    const name = mode === "missing" ? "other_tool" : "fixture_tool";
    send({ jsonrpc: "2.0", id: message.id, result: { tools: [{
      name, description: "fixture", inputSchema: { type: "object" }
    }] }});
  } else if (message.method === "tools/call" && mode !== "timeout") {
    if (mode === "late-detached-exit") {
      const child = spawn(process.execPath, ["-e", "setInterval(() => {}, 1000)"], {
        detached: true,
        stdio: "ignore"
      });
      writeFileSync(childPidPath, String(child.pid));
      child.unref();
      process.stdout.write(`${JSON.stringify({
        jsonrpc: "2.0", id: message.id, result: {
          content: [{ type: "text", text: "ok" }], isError: false
        }
      })}\n`, () => setTimeout(() => process.exit(0), 25));
      continue;
    }
    send({ jsonrpc: "2.0", id: message.id, result: {
      content: [{ type: "text", text: "ok" }], isError: false
    }});
  }
}
'@, $utf8NoBom)
    $request = [ordered]@{
        sdkClientPath = Join-Path $sdkRoot 'index.js'
        sdkStdioPath = Join-Path $sdkRoot 'stdio.js'
        command = $nodePath
        args = @($serverPath, $Mode, $childPidPath)
        cwd = $root
        toolName = 'fixture_tool'
        arguments = [ordered]@{ value = 1 }
        timeoutSeconds = $TimeoutSeconds
    }
    foreach ($key in $RequestOverrides.Keys) {
        $request[$key] = $RequestOverrides[$key]
    }
    [IO.File]::WriteAllText(
        $requestPath,
        ($request | ConvertTo-Json -Depth 12 -Compress),
        $utf8NoBom
    )
    if ($HideNativeCommands) {
        $originalPath = $env:PATH
        try {
            $env:PATH = ''
            & $nodePath $runnerPath $requestPath $resultPath 2> $stderrPath
        } finally {
            $env:PATH = $originalPath
        }
    } else {
        & $nodePath $runnerPath $requestPath $resultPath 2> $stderrPath
    }
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        ResultPath = $resultPath
        ChildPidPath = $childPidPath
        StderrPath = $stderrPath
        Root = $root
    }
}

Describe 'MCP smoke runner' {
    BeforeAll {
        (Test-Path -LiteralPath (Join-Path $sdkRoot 'index.js') -PathType Leaf) |
            Should Be $true
        (Test-Path -LiteralPath (Join-Path $sdkRoot 'stdio.js') -PathType Leaf) |
            Should Be $true
    }

    It 'resolves the SDK without a fixed drive path' {
        $assignment = Select-String -LiteralPath $PSCommandPath -Pattern '^\$sdkRoot\s*='
        $assignment.Line | Should Match 'Resolve-McpSdkRoot'
    }

    It 'reports a clear error when the SDK test dependency is missing' {
        $missingRoot = Join-Path $TestDrive 'missing-repository'
        New-Item -ItemType Directory -Path $missingRoot | Out-Null
        try {
            Resolve-McpSdkRoot -RepositoryRoot $missingRoot | Out-Null
            throw 'Expected SDK resolution to fail.'
        } catch {
            $_.Exception.Message | Should Match '^MCP SDK test dependency missing at: '
        }
    }

    It 'reports a clear error when the git common directory cannot be resolved' {
        $notARepository = Join-Path $TestDrive 'not-a-repository'
        New-Item -ItemType Directory -Path $notARepository | Out-Null
        try {
            Resolve-GitCommonRepositoryRoot -WorkTreeRoot $notARepository | Out-Null
            throw 'Expected git common directory resolution to fail.'
        } catch {
            $_.Exception.Message | Should Match '^Unable to resolve git common directory for MCP SDK tests: '
        }
    }

    It 'initializes lists and calls the expected tool' {
        $run = Invoke-TestSmokeRunner -Mode 'success'
        $run.ExitCode | Should Be 0
        $result = Get-Content $run.ResultPath -Raw | ConvertFrom-Json
        $result.status | Should Be 'smoke_verified'
        (@($result.advertisedTools) -contains 'fixture_tool') | Should Be $true
        (@($result.contentTypes) -contains 'text') | Should Be $true
        $result.residualProcess | Should Be $false
    }

    It 'fails when the expected tool is missing' {
        $run = Invoke-TestSmokeRunner -Mode 'missing'
        $run.ExitCode | Should Be 1
        (Get-Content $run.ResultPath -Raw | ConvertFrom-Json).errorCode |
            Should Be 'mcp_smoke_tool_missing'
    }

    It 'times out and closes the server process' {
        $run = Invoke-TestSmokeRunner -Mode 'timeout' -TimeoutSeconds 1
        $run.ExitCode | Should Be 1
        $result = Get-Content $run.ResultPath -Raw | ConvertFrom-Json
        $result.errorCode | Should Be 'mcp_smoke_timeout'
        $result.residualProcess | Should Be $false
    }

    It 'captures and closes the server process when initialization times out' {
        $run = Invoke-TestSmokeRunner -Mode 'initialize-timeout' -TimeoutSeconds 1
        $run.ExitCode | Should Be 1
        $result = Get-Content $run.ResultPath -Raw | ConvertFrom-Json
        $result.errorCode | Should Be 'mcp_smoke_timeout'
        $result.serverPid | Should Not BeNullOrEmpty
        (Get-Process -Id $result.serverPid -ErrorAction SilentlyContinue) | Should BeNullOrEmpty
        $result.residualProcess | Should Be $false
    }

    It 'closes descendant processes before reporting success' {
        $run = Invoke-TestSmokeRunner -Mode 'descendant'
        $childPid = [int](Get-Content $run.ChildPidPath -Raw)
        try {
            $run.ExitCode | Should Be 0
            $result = Get-Content $run.ResultPath -Raw | ConvertFrom-Json
            $result.status | Should Be 'smoke_verified'
            (Get-Process -Id $childPid -ErrorAction SilentlyContinue) | Should BeNullOrEmpty
            $result.residualProcess | Should Be $false
        } finally {
            Stop-Process -Id $childPid -Force -ErrorAction SilentlyContinue
        }
    }

    It 'does not verify smoke when a late detached child outlives an exited server root' {
        $run = Invoke-TestSmokeRunner -Mode 'late-detached-exit'
        $childPid = [int](Get-Content $run.ChildPidPath -Raw)
        try {
            $run.ExitCode | Should Be 1
            $result = Get-Content $run.ResultPath -Raw | ConvertFrom-Json
            $result.status | Should Not Be 'smoke_verified'
            $result.errorCode | Should Match 'mcp_smoke_(cleanup_failed|residual_process)'
            $result.residualProcess | Should Be $true
        } finally {
            Stop-Process -Id $childPid -Force -ErrorAction SilentlyContinue
        }
    }

    It 'waits for a delayed process exit using bounded polling' {
        $probePath = Join-Path $TestDrive 'poll-probe.mjs'
        $probeResultPath = Join-Path $TestDrive 'poll-result.json'
        [IO.File]::WriteAllText($probePath, @'
import { spawn } from "node:child_process";
import { writeFile } from "node:fs/promises";
import { pathToFileURL } from "node:url";
const runner = await import(pathToFileURL(process.argv[2]).href);
const child = spawn(process.execPath, ["-e", "setTimeout(() => {}, 250)"], {
  stdio: "ignore"
});
const started = Date.now();
const residual = await runner.waitForProcessesToExit([child.pid], 1000);
await writeFile(process.argv[3], JSON.stringify({ residual, elapsed: Date.now() - started }));
'@, $utf8NoBom)
        & node $probePath $runnerPath $probeResultPath 2> (Join-Path $TestDrive 'poll-stderr.log')
        $LASTEXITCODE | Should Be 0
        $probe = Get-Content $probeResultPath -Raw | ConvertFrom-Json
        @($probe.residual).Count | Should Be 0
        ($probe.elapsed -ge 150) | Should Be $true
        ($probe.elapsed -lt 1000) | Should Be $true
    }

    It 'defines argument-array native process commands for both platforms' {
        $probePath = Join-Path $TestDrive 'platform-probe.mjs'
        $probeResultPath = Join-Path $TestDrive 'platform-result.json'
        [IO.File]::WriteAllText($probePath, @'
import { writeFile } from "node:fs/promises";
import { pathToFileURL } from "node:url";
const runner = await import(pathToFileURL(process.argv[2]).href);
const result = {
  win32: runner.nativeProcessCommands("win32", 123),
  posix: runner.nativeProcessCommands("linux", 123)
};
await writeFile(process.argv[3], JSON.stringify(result));
'@, $utf8NoBom)
        & node $probePath $runnerPath $probeResultPath 2> (Join-Path $TestDrive 'platform-stderr.log')
        $LASTEXITCODE | Should Be 0
        $commands = Get-Content $probeResultPath -Raw | ConvertFrom-Json
        $commands.win32.terminate.command | Should Be 'taskkill.exe'
        ($commands.win32.terminate.args -join ' ') | Should Be '/PID 123 /F'
        ($commands.win32.snapshot.args -join ' ') | Should Match 'CreationDate'
        $commands.posix.snapshot.command | Should Be 'ps'
        ($commands.posix.snapshot.args -join ' ') | Should Be '-eo pid=,ppid='
    }

    It 'does not terminate stale or reused process identities' {
        $probePath = Join-Path $TestDrive 'stale-cleanup-probe.mjs'
        $probeResultPath = Join-Path $TestDrive 'stale-cleanup-result.json'
        [IO.File]::WriteAllText($probePath, @'
import { writeFile } from "node:fs/promises";
import { pathToFileURL } from "node:url";
const runner = await import(pathToFileURL(process.argv[2]).href);
const terminated = [];
const residual = await runner.cleanupProcessTree(
  [{ pid: 321, parentPid: 1, startTick: "100" }],
  "linux",
  {
    snapshotProcessRows: async () => [
      { pid: 321, parentPid: 1, startTick: "200" }
    ],
    processExists: () => true,
    terminatePid: async (pid) => terminated.push(pid),
    forceTerminatePid: async (pid) => terminated.push(pid)
  }
);
await writeFile(process.argv[3], JSON.stringify({ terminated, residual }));
'@, $utf8NoBom)
        & node $probePath $runnerPath $probeResultPath 2> (Join-Path $TestDrive 'stale-cleanup-stderr.log')
        $LASTEXITCODE | Should Be 0
        $probe = Get-Content $probeResultPath -Raw | ConvertFrom-Json
        @($probe.terminated).Count | Should Be 0
        @($probe.residual).Count | Should Be 0
    }

    It 'does not match POSIX identities that share lstart but have different start ticks' {
        $probePath = Join-Path $TestDrive 'same-second-cleanup-probe.mjs'
        $probeResultPath = Join-Path $TestDrive 'same-second-cleanup-result.json'
        [IO.File]::WriteAllText($probePath, @'
import { writeFile } from "node:fs/promises";
import { pathToFileURL } from "node:url";
const runner = await import(pathToFileURL(process.argv[2]).href);
const terminated = [];
const residual = await runner.cleanupProcessTree(
  [{ pid: 654, parentPid: 1, startedAt: "Mon Jul  6 12:00:00 2026", startTick: "111111" }],
  "linux",
  {
    snapshotProcessRows: async () => [
      { pid: 654, parentPid: 1, startedAt: "Mon Jul  6 12:00:00 2026", startTick: "222222" }
    ],
    processExists: () => true,
    terminatePid: async (pid) => terminated.push(pid),
    forceTerminatePid: async (pid) => terminated.push(pid)
  }
);
await writeFile(process.argv[3], JSON.stringify({ terminated, residual }));
'@, $utf8NoBom)
        & node $probePath $runnerPath $probeResultPath 2> (Join-Path $TestDrive 'same-second-cleanup-stderr.log')
        $LASTEXITCODE | Should Be 0
        $probe = Get-Content $probeResultPath -Raw | ConvertFrom-Json
        @($probe.terminated).Count | Should Be 0
        @($probe.residual).Count | Should Be 0
    }

    It 'fails POSIX cleanup verification instead of terminating when high precision identity is missing' {
        $probePath = Join-Path $TestDrive 'missing-tick-cleanup-probe.mjs'
        $probeResultPath = Join-Path $TestDrive 'missing-tick-cleanup-result.json'
        [IO.File]::WriteAllText($probePath, @'
import { writeFile } from "node:fs/promises";
import { pathToFileURL } from "node:url";
const runner = await import(pathToFileURL(process.argv[2]).href);
const terminated = [];
let errorCode = null;
try {
  await runner.cleanupProcessTree(
    [{ pid: 777, parentPid: 1, startedAt: "Mon Jul  6 12:00:00 2026" }],
    "linux",
    {
      snapshotProcessRows: async () => [
        { pid: 777, parentPid: 1, startedAt: "Mon Jul  6 12:00:00 2026" }
      ],
      processExists: () => true,
      terminatePid: async (pid) => terminated.push(pid),
      forceTerminatePid: async (pid) => terminated.push(pid)
    }
  );
} catch (error) {
  errorCode = error.code;
}
await writeFile(process.argv[3], JSON.stringify({ terminated, errorCode }));
'@, $utf8NoBom)
        & node $probePath $runnerPath $probeResultPath 2> (Join-Path $TestDrive 'missing-tick-cleanup-stderr.log')
        $LASTEXITCODE | Should Be 0
        $probe = Get-Content $probeResultPath -Raw | ConvertFrom-Json
        $probe.errorCode | Should Be 'mcp_smoke_cleanup_failed'
        @($probe.terminated).Count | Should Be 0
    }

    It 'terminates matching descendants leaf-first after identity verification' {
        $probePath = Join-Path $TestDrive 'matching-cleanup-probe.mjs'
        $probeResultPath = Join-Path $TestDrive 'matching-cleanup-result.json'
        [IO.File]::WriteAllText($probePath, @'
import { writeFile } from "node:fs/promises";
import { pathToFileURL } from "node:url";
const runner = await import(pathToFileURL(process.argv[2]).href);
const live = new Set([10, 11]);
const terminated = [];
const rows = [
  { pid: 10, parentPid: 1, startTick: "1000" },
  { pid: 11, parentPid: 10, startTick: "1001" }
];
const residual = await runner.cleanupProcessTree(rows, "linux", {
  snapshotProcessRows: async () => rows.filter((row) => live.has(row.pid)),
  processExists: (pid) => live.has(pid),
  terminatePid: async (pid) => {
    terminated.push(pid);
    live.delete(pid);
  },
  forceTerminatePid: async (pid) => {
    terminated.push(pid);
    live.delete(pid);
  }
});
await writeFile(process.argv[3], JSON.stringify({ terminated, residual }));
'@, $utf8NoBom)
        & node $probePath $runnerPath $probeResultPath 2> (Join-Path $TestDrive 'matching-cleanup-stderr.log')
        $LASTEXITCODE | Should Be 0
        $probe = Get-Content $probeResultPath -Raw | ConvertFrom-Json
        ($probe.terminated -join ',') | Should Be '11,10'
        @($probe.residual).Count | Should Be 0
    }

    It 'does not block or disclose high-volume server stderr' {
        $run = Invoke-TestSmokeRunner -Mode 'stderr-flood' -TimeoutSeconds 2
        $run.ExitCode | Should Be 0
        $resultText = Get-Content $run.ResultPath -Raw
        $result = $resultText | ConvertFrom-Json
        $result.status | Should Be 'smoke_verified'
        $resultText | Should Not Match 'SENSITIVE_STDERR_MARKER'
        (Get-Content $run.StderrPath -Raw) | Should Not Match 'SENSITIVE_STDERR_MARKER'
    }

    It 'rejects malformed requests before starting a server' {
        $invalidRequests = @(
            @{ sdkClientPath = $null },
            @{ sdkStdioPath = $null },
            @{ command = $null },
            @{ args = 'not-an-array' },
            @{ toolName = '' },
            @{ arguments = @(1) },
            @{ timeoutSeconds = 0 },
            @{ timeoutSeconds = 1.5 },
            @{ timeoutSeconds = 2147484 },
            @{ timeoutSeconds = 'not-a-number' }
        )
        foreach ($overrides in $invalidRequests) {
            $run = Invoke-TestSmokeRunner -Mode 'success' -RequestOverrides $overrides
            $run.ExitCode | Should Be 1
            $result = Get-Content $run.ResultPath -Raw | ConvertFrom-Json
            $result.errorCode | Should Be 'mcp_smoke_invalid_request'
            $result.message | Should Be 'Invalid MCP smoke request.'
            $result.serverPid | Should BeNullOrEmpty
            $result.residualProcess | Should Be $false
        }
    }

    It 'writes only stable diagnostics for unexpected server errors' {
        $run = Invoke-TestSmokeRunner -Mode 'sensitive-error'
        $run.ExitCode | Should Be 1
        $resultText = Get-Content $run.ResultPath -Raw
        $result = $resultText | ConvertFrom-Json
        $result.errorCode | Should Be 'mcp_smoke_start_failed'
        $result.message | Should Be 'MCP smoke runner could not complete.'
        $resultText | Should Not Match 'SENSITIVE_SERVER_MARKER'
        (Get-Content $run.StderrPath -Raw) | Should Not Match 'SENSITIVE_SERVER_MARKER'
    }

    It 'reports native cleanup uncertainty but still terminates the direct server' {
        $run = Invoke-TestSmokeRunner -Mode 'stubborn' -HideNativeCommands
        $result = Get-Content $run.ResultPath -Raw | ConvertFrom-Json
        try {
            $run.ExitCode | Should Be 1
            $result.errorCode | Should Be 'mcp_smoke_cleanup_failed'
            $result.message | Should Be 'MCP server process cleanup could not be verified.'
            $result.serverPid | Should Not BeNullOrEmpty
            (Get-Process -Id $result.serverPid -ErrorAction SilentlyContinue) | Should BeNullOrEmpty
            $result.residualProcess | Should Be $true
        } finally {
            Stop-Process -Id $result.serverPid -Force -ErrorAction SilentlyContinue
        }
    }
}
