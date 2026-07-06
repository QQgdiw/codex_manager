$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$runnerPath = Join-Path $projectRoot 'scripts\node\mcp-smoke-runner.mjs'
$sdkRoot = 'E:\codex\MCP\servers\src\sequentialthinking\node_modules\@modelcontextprotocol\sdk\dist\esm\client'
$utf8NoBom = New-Object Text.UTF8Encoding($false)

function Invoke-TestSmokeRunner {
    param(
        [ValidateSet('success', 'missing', 'timeout')][string]$Mode,
        [int]$TimeoutSeconds = 5
    )
    $root = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $root | Out-Null
    $serverPath = Join-Path $root 'fake-server.mjs'
    $requestPath = Join-Path $root 'request.json'
    $resultPath = Join-Path $root 'result.json'
    [IO.File]::WriteAllText($serverPath, @'
import readline from "node:readline";
const mode = process.argv[2];
const input = readline.createInterface({ input: process.stdin });
function send(value) { process.stdout.write(`${JSON.stringify(value)}\n`); }
for await (const line of input) {
  const message = JSON.parse(line);
  if (message.method === "initialize") {
    send({ jsonrpc: "2.0", id: message.id, result: {
      protocolVersion: "2025-03-26", capabilities: { tools: {} },
      serverInfo: { name: "fixture", version: "1.0.0" }
    }});
  } else if (message.method === "tools/list") {
    const name = mode === "missing" ? "other_tool" : "fixture_tool";
    send({ jsonrpc: "2.0", id: message.id, result: { tools: [{
      name, description: "fixture", inputSchema: { type: "object" }
    }] }});
  } else if (message.method === "tools/call" && mode !== "timeout") {
    send({ jsonrpc: "2.0", id: message.id, result: {
      content: [{ type: "text", text: "ok" }], isError: false
    }});
  }
}
'@, $utf8NoBom)
    $request = [ordered]@{
        sdkClientPath = Join-Path $sdkRoot 'index.js'
        sdkStdioPath = Join-Path $sdkRoot 'stdio.js'
        command = (Get-Command node).Source
        args = @($serverPath, $Mode)
        cwd = $root
        toolName = 'fixture_tool'
        arguments = [ordered]@{ value = 1 }
        timeoutSeconds = $TimeoutSeconds
    }
    [IO.File]::WriteAllText(
        $requestPath,
        ($request | ConvertTo-Json -Depth 12 -Compress),
        $utf8NoBom
    )
    & node $runnerPath $requestPath $resultPath 2> (Join-Path $root 'stderr.log')
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        ResultPath = $resultPath
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
}
