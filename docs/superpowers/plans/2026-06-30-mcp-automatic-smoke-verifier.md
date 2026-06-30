# MCP 自动 Smoke Verifier 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 stdio MCP 接入通用声明式自动 smoke verifier，使已部署的 sequential-thinking 在 static、load 和最小协议调用全部成功后返回 `smoke_verified`。

**Architecture:** 在 TOML 白名单中声明受批准快照保护的 smoke profile；PowerShell 负责 Schema、路径、哈希、生命周期和状态映射，通用 Node 运行器负责 MCP initialize、`tools/list`、`tools/call` 与子进程关闭。生命周期脚本固定在仓库内并校验 SHA-256，通过 Node permission 模式只能读写管理器创建的临时根；verifier 只报告失败，不卸载 MCP。

**Tech Stack:** Windows PowerShell 5.1、Pester 3.4、Node.js 24、`@modelcontextprotocol/sdk` 1.29.0、TOML 白名单、Codex CLI 0.142.4。

---

## 文件结构

- 修改：`scripts/lib/Read-Toml.ps1`
  - 校验可选 `[tools.smoke]` 的字段、类型、范围和未知字段。
- 修改：`tests/unit/Whitelist.Tests.ps1`
  - 覆盖有效 profile、非法字段、超时、内容类型、脚本路径和哈希。
- 修改：`scripts/lib/DeploymentEngine.ps1`
  - 将 mcp `smoke` 写入 `ApprovedSnapshot`，保持跨类型隔离。
- 修改：`tests/unit/DeploymentEngine.Tests.ps1`
  - 覆盖 smoke snapshot、深复制和篡改保护。
- 修改：`scripts/lib/Common.ps1`
  - 为受管进程增加工作目录、最小环境和清空继承环境的能力。
- 修改：`tests/unit/Common.Tests.ps1`
  - 覆盖环境隔离和显式环境传递。
- 修改：`scripts/lib/VerificationEngine.ps1`
  - 支持可选 `StaticVerifier`，与现有 Load/Smoke verifier 模型一致。
- 修改：`tests/unit/VerificationEngine.Tests.ps1`
  - 覆盖自定义 static 成功、失败和异常。
- 新增：`scripts/node/mcp-smoke-runner.mjs`
  - 通用 stdio MCP 协议运行器。
- 新增：`.gitattributes`
  - 固定受管 Node 脚本为 LF，保证跨检出的 SHA-256 稳定。
- 新增：`tests/integration/McpSmokeRunner.Tests.ps1`
  - 使用 fake stdio MCP 验证协议成功、工具缺失、超时和无残留进程。
- 修改：`scripts/lib/adapters/McpAdapter.ps1`
  - 构建 smoke plan、校验固定脚本、加固 load 配置比较、执行生命周期和协议运行器。
- 修改：`tests/unit/McpAdapter.Tests.ps1`
  - 覆盖 smoke plan、安全边界、错误码、清理和 load 一致性。
- 新增：`scripts/smoke/mcp/sequential-thinking.mjs`
  - 实现 prepare、validate、cleanup 三个固定动作。
- 修改：`scripts/Invoke-CodexToolManager.ps1`
  - 为有 smoke profile 的 MCP 注入 StaticVerifier 和 SmokeVerifier；executor 读取命令级安全参数。
- 修改：`tests/integration/EntryPoint.Tests.ps1`
  - 覆盖入口自动 smoke 成功和无 profile 继续 blocked。
- 修改：`Resources/tool_whitelist.toml`
  - 为 sequential-thinking 增加最终 profile 和真实脚本 SHA-256。
- 修改：`Notes/verify_record.md`
  - 记录自动 smoke 真实结果，不记录完整调用正文。
- 修改：`Resources/GUIDE.md`
  - 将下一步切换到 filesystem MCP 根目录与读写范围实施。
- 修改：`state/README.md`、`state/TODO.md`、`state/LOG.md`
  - 记录能力、测试证据、限制和后续工作。

---

### Task 1: 校验并固化 MCP Smoke Profile

**Files:**
- Modify: `scripts/lib/Read-Toml.ps1:176`
- Modify: `tests/unit/Whitelist.Tests.ps1`
- Modify: `scripts/lib/DeploymentEngine.ps1:121-200`
- Modify: `tests/unit/DeploymentEngine.Tests.ps1:180-220`

- [ ] **Step 1: 新增 RED 白名单测试**

在 `tests/unit/Whitelist.Tests.ps1` 中追加完整测试：

```powershell
    It 'accepts a bounded MCP smoke profile' {
        $tool = New-ValidWhitelistTool
        $tool.type = 'mcp'
        $tool.smoke = @{
            tool_name = 'sequentialthinking'
            timeout_seconds = 10
            expected_content_types = @('text')
            script_path = 'scripts/smoke/mcp/sequential-thinking.mjs'
            script_sha256 = ('a' * 64)
            arguments = @{
                thought = 'smoke'
                nextThoughtNeeded = $false
                thoughtNumber = 1
                totalThoughts = 1
            }
        }
        $document = @{ schema_version = '1.0'; tools = @($tool) }

        (Test-WhitelistDocument -Document $document).IsValid | Should Be $true
    }

    It 'rejects unsafe or malformed MCP smoke profiles' {
        $cases = @(
            @{ Field = 'unknown'; Value = 'value'; Match = 'unknown' },
            @{ Field = 'timeout_seconds'; Value = 0; Match = '1 and 30' },
            @{ Field = 'timeout_seconds'; Value = 31; Match = '1 and 30' },
            @{ Field = 'expected_content_types'; Value = @(); Match = 'non-empty array' },
            @{ Field = 'script_path'; Value = '..\unsafe.mjs'; Match = 'scripts/smoke/mcp' },
            @{ Field = 'script_path'; Value = 'scripts/smoke/mcp/test.ps1'; Match = '.mjs' },
            @{ Field = 'script_sha256'; Value = 'BAD'; Match = '64 lowercase' }
        )
        foreach ($case in $cases) {
            $tool = New-ValidWhitelistTool
            $tool.type = 'mcp'
            $tool.smoke = @{
                tool_name = 'test-tool'
                timeout_seconds = 10
                expected_content_types = @('text')
                script_path = 'scripts/smoke/mcp/test.mjs'
                script_sha256 = ('a' * 64)
                arguments = @{}
            }
            $tool.smoke[$case.Field] = $case.Value
            $result = Test-WhitelistDocument -Document @{
                schema_version = '1.0'; tools = @($tool)
            }
            $result.IsValid | Should Be $false
            ($result.Errors -join '; ') | Should Match $case.Match
        }
    }
```

- [ ] **Step 2: 运行测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module Pester; Invoke-Pester .\tests\unit\Whitelist.Tests.ps1 -PassThru" *> .\task-smoke-schema-red.log
```

Expected: 至少一个新增用例 FAIL，因为当前白名单校验器忽略 `smoke`。

- [ ] **Step 3: 实现 `Test-McpSmokeProfile` 并接入白名单校验**

在 `scripts/lib/Read-Toml.ps1` 的 `Test-WhitelistDocument` 前新增：

```powershell
function Test-McpSmokeProfile {
    param(
        [object]$Profile,
        [string]$Label,
        [System.Collections.Generic.List[string]]$Errors
    )

    if (-not (Test-ProjectObject -Value $Profile)) {
        $Errors.Add("$Label must be an object.")
        return
    }
    $allowed = @(
        'tool_name', 'timeout_seconds', 'expected_content_types',
        'script_path', 'script_sha256', 'arguments'
    )
    $propertyNames = if ($Profile -is [System.Collections.IDictionary]) {
        @($Profile.Keys | ForEach-Object { [string]$_ })
    }
    else {
        @($Profile.PSObject.Properties.Name)
    }
    foreach ($property in $propertyNames) {
        if ($allowed -notcontains $property) {
            $Errors.Add("$Label contains unknown field '$property'.")
        }
    }
    foreach ($field in @('tool_name', 'script_path', 'script_sha256')) {
        $member = Get-ProjectMember -InputObject $Profile -Name $field
        if (-not $member.Exists -or $member.Value -isnot [string] -or
            [string]::IsNullOrWhiteSpace([string]$member.Value)) {
            $Errors.Add("$Label field '$field' must be a non-empty string.")
        }
    }
    $timeout = Get-ProjectMember -InputObject $Profile -Name 'timeout_seconds'
    if (-not $timeout.Exists -or
        ($timeout.Value -isnot [int] -and $timeout.Value -isnot [long]) -or
        [long]$timeout.Value -lt 1 -or [long]$timeout.Value -gt 30) {
        $Errors.Add("$Label field 'timeout_seconds' must be an integer between 1 and 30.")
    }
    $types = Get-ProjectMember -InputObject $Profile -Name 'expected_content_types'
    if (-not $types.Exists -or $types.Value -isnot [System.Array] -or
        @($types.Value).Count -eq 0) {
        $Errors.Add("$Label field 'expected_content_types' must be a non-empty array.")
    }
    else {
        foreach ($value in @($types.Value)) {
            if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) {
                $Errors.Add("$Label expected content types must be non-empty strings.")
            }
        }
    }
    $scriptPath = [string](Get-ProjectMember -InputObject $Profile -Name 'script_path').Value
    if (-not $scriptPath.StartsWith('scripts/smoke/mcp/', [StringComparison]::Ordinal) -or
        -not $scriptPath.EndsWith('.mjs', [StringComparison]::Ordinal)) {
        $Errors.Add("$Label field 'script_path' must be a .mjs path below scripts/smoke/mcp/.")
    }
    $scriptHash = [string](Get-ProjectMember -InputObject $Profile -Name 'script_sha256').Value
    if ($scriptHash -cnotmatch '^[0-9a-f]{64}$') {
        $Errors.Add("$Label field 'script_sha256' must be 64 lowercase hexadecimal characters.")
    }
    $arguments = Get-ProjectMember -InputObject $Profile -Name 'arguments'
    if (-not $arguments.Exists -or -not (Test-ProjectObject -Value $arguments.Value)) {
        $Errors.Add("$Label field 'arguments' must be an object.")
    }
}
```

在每个工具的基础字段校验后调用：

```powershell
        $smokeMember = Get-ProjectMember -InputObject $tool -Name 'smoke'
        if ($smokeMember.Exists) {
            if ($typeMember.Value -cne 'mcp') {
                $errors.Add("$label field 'smoke' is supported only for mcp tools.")
            }
            else {
                Test-McpSmokeProfile -Profile $smokeMember.Value `
                    -Label "$label.smoke" -Errors $errors
            }
        }
```

- [ ] **Step 4: 新增 RED approved snapshot 测试**

在 `tests/unit/DeploymentEngine.Tests.ps1` 的 MCP snapshot 测试中给工具增加 `smoke`，并追加断言：

```powershell
        $tool | Add-Member -NotePropertyName 'smoke' -NotePropertyValue ([pscustomobject]@{
            tool_name = 'entry-tool'
            timeout_seconds = 10
            expected_content_types = @('text')
            script_path = 'scripts/smoke/mcp/entry.mjs'
            script_sha256 = ('a' * 64)
            arguments = [pscustomobject]@{ value = 'approved' }
        })

        $snapshot.smoke.tool_name | Should Be 'entry-tool'
        $snapshot.smoke.arguments.value | Should Be 'approved'
        $tool.smoke.arguments.value = 'tampered-after-plan'
        $snapshot.smoke.arguments.value | Should Be 'approved'
```

- [ ] **Step 5: 运行 DeploymentEngine 测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module Pester; Invoke-Pester .\tests\unit\DeploymentEngine.Tests.ps1 -PassThru" *> .\task-smoke-snapshot-red.log
```

Expected: 新增 snapshot 断言 FAIL，`ApprovedSnapshot.smoke` 不存在。

- [ ] **Step 6: 将 smoke 加入 MCP adapter fields**

在 `New-DeploymentApprovedSnapshot` 的 mcp 分支中使用：

```powershell
    elseif ($type -eq 'mcp') {
        $adapterFields = @(
            'mcp_transport',
            'mcp_name',
            'stdio',
            'http',
            'smoke'
        )
    }
```

- [ ] **Step 7: 运行 GREEN 测试并提交**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\task-smoke-schema-green.log
```

Expected: `Failed: 0`。

```powershell
git add -- scripts/lib/Read-Toml.ps1 scripts/lib/DeploymentEngine.ps1 tests/unit/Whitelist.Tests.ps1 tests/unit/DeploymentEngine.Tests.ps1
git diff --cached --check
git commit -m "feat[mcp]: preserve approved smoke profiles"
```

---

### Task 2: 为受管进程增加环境隔离

**Files:**
- Modify: `scripts/lib/Common.ps1:444-523`
- Modify: `tests/unit/Common.Tests.ps1:79-230`

- [ ] **Step 1: 新增 RED 环境隔离测试**

在 `tests/unit/Common.Tests.ps1` 的 `Invoke-ManagedProcess` Describe 中追加：

```powershell
    It 'clears inherited environment and passes only explicit values' {
        $env:CODEX_SMOKE_SECRET = 'must-not-leak'
        try {
            $result = Invoke-ManagedProcess -FilePath $powerShellPath -Arguments @(
                '-NoProfile', '-Command',
                '[Console]::Write("$env:CODEX_SMOKE_SECRET|$env:SMOKE_ACTION")'
            ) -TimeoutSeconds 10 -ClearEnvironment `
                -Environment @{ SMOKE_ACTION = 'prepare' }
        }
        finally {
            Remove-Item Env:\CODEX_SMOKE_SECRET -ErrorAction SilentlyContinue
        }

        $result.Succeeded | Should Be $true
        $result.StdOut | Should Be '|prepare'
    }

    It 'uses an explicit working directory' {
        $work = Join-Path $TestDrive 'managed-working-directory'
        New-Item -ItemType Directory -Path $work | Out-Null
        $result = Invoke-ManagedProcess -FilePath $powerShellPath -Arguments @(
            '-NoProfile', '-Command', '[Console]::Write((Get-Location).Path)'
        ) -TimeoutSeconds 10 -WorkingDirectory $work

        $result.Succeeded | Should Be $true
        [IO.Path]::GetFullPath($result.StdOut) | Should Be ([IO.Path]::GetFullPath($work))
    }
```

- [ ] **Step 2: 运行测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module Pester; Invoke-Pester .\tests\unit\Common.Tests.ps1 -PassThru" *> .\task-smoke-process-red.log
```

Expected: FAIL，`Invoke-ManagedProcess` 不识别 `ClearEnvironment` 或 `WorkingDirectory`。

- [ ] **Step 3: 扩展 `Invoke-ManagedProcess`**

在参数列表追加：

```powershell
        [AllowNull()][string]$WorkingDirectory,
        [AllowNull()][System.Collections.IDictionary]$Environment,
        [switch]$ClearEnvironment
```

在设置 `ProcessStartInfo` 后、启动进程前追加：

```powershell
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
```

- [ ] **Step 4: 运行 GREEN 测试并提交**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module Pester; Invoke-Pester .\tests\unit\Common.Tests.ps1 -PassThru" *> .\task-smoke-process-green.log
```

Expected: `Failed: 0`。

```powershell
git add -- scripts/lib/Common.ps1 tests/unit/Common.Tests.ps1
git diff --cached --check
git commit -m "feat[process]: isolate managed smoke environment"
```

---

### Task 3: 为验证引擎增加可注入 StaticVerifier

**Files:**
- Modify: `scripts/lib/VerificationEngine.ps1:281-359`
- Modify: `tests/unit/VerificationEngine.Tests.ps1`

- [ ] **Step 1: 新增 RED 测试**

在 `tests/unit/VerificationEngine.Tests.ps1` 追加：

```powershell
    It 'merges an injected static verifier result' {
        $tool = New-TestVerificationTool
        $tool | Add-Member -NotePropertyName StaticVerifier -NotePropertyValue {
            @{ Status = 'static_verified'; Message = 'profile ok'; Checks = @('smoke_profile_ok') }
        }

        $result = Invoke-StaticVerification -Tool $tool

        $result.Status | Should Be 'static_verified'
        @($result.Checks) | Should Contain 'smoke_profile_ok'
    }

    It 'returns static failure from an injected verifier' {
        $tool = New-TestVerificationTool
        $tool | Add-Member -NotePropertyName StaticVerifier -NotePropertyValue {
            @{ Status = 'failed'; Message = 'hash mismatch'; ErrorCode = 'mcp_smoke_script_hash_mismatch' }
        }

        $result = Invoke-StaticVerification -Tool $tool

        $result.Status | Should Be 'failed'
        $result.ErrorCode | Should Be 'mcp_smoke_script_hash_mismatch'
    }
```

- [ ] **Step 2: 运行测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module Pester; Invoke-Pester .\tests\unit\VerificationEngine.Tests.ps1 -PassThru" *> .\task-static-verifier-red.log
```

Expected: 新增 check 不存在，或失败结果仍为 `static_verified`。

- [ ] **Step 3: 在基础静态检查通过后调用 StaticVerifier**

在 `Invoke-StaticVerification` 返回默认成功结果前追加：

```powershell
    $verifier = Get-VerificationMemberValue -Object $Tool `
        -Names @('StaticVerifier', 'static_verifier')
    if ($null -ne $verifier -and $verifier -is [scriptblock]) {
        try {
            $adapterResult = & $verifier $Tool
        }
        catch {
            return New-VerificationResult -Tool $Tool -Level 'static' `
                -Status 'failed' -Message $_.Exception.Message `
                -StartedAt $startedAt -Checks $checks `
                -ErrorCode 'static_verifier_exception'
        }
        $result = ConvertTo-VerificationResultFromAdapter `
            -Tool $Tool -Level 'static' -StartedAt $startedAt `
            -AdapterResult $adapterResult `
            -DefaultSuccessStatus 'static_verified'
        $result.Checks = @($checks) + @($result.Checks)
        return $result
    }
```

- [ ] **Step 4: 运行 GREEN 测试并提交**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\task-static-verifier-green.log
```

Expected: `Failed: 0`。

```powershell
git add -- scripts/lib/VerificationEngine.ps1 tests/unit/VerificationEngine.Tests.ps1
git diff --cached --check
git commit -m "feat[verify]: support adapter static verifiers"
```

---

### Task 4: 实现通用 Node MCP Smoke Runner

**Files:**
- Create: `.gitattributes`
- Create: `scripts/node/mcp-smoke-runner.mjs`
- Create: `tests/integration/McpSmokeRunner.Tests.ps1`

- [ ] **Step 1: 创建 RED 协议测试夹具**

在 `tests/integration/McpSmokeRunner.Tests.ps1` 中先加入完整 helper。Fake server 直接实现测试所需的最小 JSON-RPC，客户端仍使用本地 MCP SDK：

```powershell
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
```

随后加入三个可执行测试：

```powershell
Describe 'MCP smoke runner' {
    It 'initializes lists and calls the expected tool' {
        $run = Invoke-TestSmokeRunner -Mode 'success'
        $run.ExitCode | Should Be 0
        $result = Get-Content $run.ResultPath -Raw | ConvertFrom-Json
        $result.status | Should Be 'smoke_verified'
        @($result.advertisedTools) | Should Contain 'fixture_tool'
        @($result.contentTypes) | Should Contain 'text'
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
```

测试不得读取或输出 MCP 调用正文，只解析 runner 的结构化结果文件。

- [ ] **Step 2: 运行测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module Pester; Invoke-Pester .\tests\integration\McpSmokeRunner.Tests.ps1 -PassThru" *> .\task-smoke-runner-red.log
```

Expected: FAIL，runner 文件不存在。

- [ ] **Step 3: 固定 Node 脚本换行并实现 runner**

创建 `.gitattributes`：

```gitattributes
scripts/node/*.mjs text eol=lf
scripts/smoke/mcp/*.mjs text eol=lf
```

`scripts/node/mcp-smoke-runner.mjs` 必须实现以下完整骨架，不得输出调用正文：

```javascript
import { readFile, writeFile, realpath } from "node:fs/promises";
import { pathToFileURL } from "node:url";

class SmokeFailure extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

function withTimeout(promise, seconds, label) {
  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(
      () => reject(new SmokeFailure("mcp_smoke_timeout", `${label} timed out`)),
      seconds * 1000,
    );
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

function processExists(pid) {
  if (!pid) return false;
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

const [requestPath, resultPath] = process.argv.slice(2);
if (!requestPath || !resultPath) process.exit(2);

let client;
let transport;
let serverPid = null;
let output;
try {
  const request = JSON.parse(await readFile(requestPath, "utf8"));
  const clientPath = await realpath(request.sdkClientPath);
  const stdioPath = await realpath(request.sdkStdioPath);
  const { Client } = await import(pathToFileURL(clientPath).href);
  const { StdioClientTransport } = await import(pathToFileURL(stdioPath).href);
  client = new Client(
    { name: "codex-tool-manager-smoke", version: "1.0.0" },
    { capabilities: {} },
  );
  transport = new StdioClientTransport({
    command: request.command,
    args: request.args,
    cwd: request.cwd ?? undefined,
    stderr: "pipe",
  });
  await withTimeout(client.connect(transport), request.timeoutSeconds, "connect");
  serverPid = transport.pid;
  const listed = await withTimeout(client.listTools(), request.timeoutSeconds, "tools/list");
  const advertisedTools = listed.tools.map((tool) => tool.name);
  if (!advertisedTools.includes(request.toolName)) {
    throw new SmokeFailure("mcp_smoke_tool_missing", "Expected MCP tool was not advertised.");
  }
  const called = await withTimeout(
    client.callTool({ name: request.toolName, arguments: request.arguments }),
    request.timeoutSeconds,
    "tools/call",
  );
  if (called.isError === true) {
    throw new SmokeFailure("mcp_smoke_call_failed", "MCP tool returned an error result.");
  }
  output = {
    status: "smoke_verified",
    errorCode: null,
    advertisedTools,
    contentTypes: (called.content ?? []).map((item) => item.type),
    isError: false,
    serverPid,
  };
} catch (error) {
  output = {
    status: "failed",
    errorCode: error.code ?? "mcp_smoke_start_failed",
    message: error.message,
    advertisedTools: [],
    contentTypes: [],
    isError: true,
    serverPid,
  };
} finally {
  if (client) await client.close().catch(() => {});
  else if (transport) await transport.close().catch(() => {});
  await new Promise((resolve) => setTimeout(resolve, 50));
  output.residualProcess = processExists(serverPid);
  if (output.residualProcess) {
    output.status = "failed";
    output.errorCode = "mcp_smoke_residual_process";
  }
  await writeFile(resultPath, JSON.stringify(output), "utf8");
}
process.exit(output.status === "smoke_verified" ? 0 : 1);
```

- [ ] **Step 4: 运行 fake server 协议测试确认 GREEN**

测试 helper 已在 Step 1 完整定义。测试开始前增加 SDK 文件断言；不存在时应测试失败，不能跳过：

```powershell
BeforeAll {
    (Test-Path -LiteralPath (Join-Path $sdkRoot 'index.js') -PathType Leaf) |
        Should Be $true
    (Test-Path -LiteralPath (Join-Path $sdkRoot 'stdio.js') -PathType Leaf) |
        Should Be $true
}
```

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module Pester; Invoke-Pester .\tests\integration\McpSmokeRunner.Tests.ps1 -PassThru" *> .\task-smoke-runner-green.log
```

Expected: `Failed: 0`，三个场景均通过。

- [ ] **Step 5: 提交**

```powershell
git add -- .gitattributes scripts/node/mcp-smoke-runner.mjs tests/integration/McpSmokeRunner.Tests.ps1
git diff --cached --check
git commit -m "feat[mcp]: add generic stdio smoke runner"
```

---

### Task 5: 构建 MCP Smoke Plan 与静态安全校验

**Files:**
- Modify: `scripts/lib/adapters/McpAdapter.ps1:483-699`
- Modify: `tests/unit/McpAdapter.Tests.ps1`

- [ ] **Step 1: 扩展测试工具并新增 RED plan 测试**

给 `New-TestMcpTool` 的 snapshot 增加可覆盖 smoke profile，并新增：

```powershell
Describe 'Get-McpSmokePlan' {
    It 'resolves an approved lifecycle script below scripts smoke mcp' {
        $project = Join-Path $TestDrive 'project'
        $scriptDir = Join-Path $project 'scripts\smoke\mcp'
        New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
        $scriptPath = Join-Path $scriptDir 'test.mjs'
        Set-Content -LiteralPath $scriptPath -Encoding UTF8 -Value 'process.exit(0);'
        $runnerPath = Join-Path $project 'scripts\node\mcp-smoke-runner.mjs'
        New-Item -ItemType Directory -Path (Split-Path $runnerPath) -Force | Out-Null
        Set-Content -LiteralPath $runnerPath -Encoding UTF8 -Value 'process.exit(0);'
        $sdk = Join-Path $TestDrive 'node_modules\@modelcontextprotocol\sdk\dist\esm\client'
        New-Item -ItemType Directory -Path $sdk -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $sdk 'index.js') -Encoding UTF8 -Value 'export {};'
        Set-Content -LiteralPath (Join-Path $sdk 'stdio.js') -Encoding UTF8 -Value 'export {};'
        $hash = (Get-FileHash $scriptPath -Algorithm SHA256).Hash.ToLowerInvariant()
        New-TestStartupFile
        $install = Get-McpInstallPlan -Tool (New-TestMcpTool -SnapshotOverrides @{
            smoke = [pscustomobject]@{
                tool_name = 'local_tool'; timeout_seconds = 10
                expected_content_types = @('text')
                script_path = 'scripts/smoke/mcp/test.mjs'
                script_sha256 = $hash
                arguments = [pscustomobject]@{ value = 1 }
            }
        })

        $plan = Get-McpSmokePlan -InstallPlan $install -ProjectRoot $project

        $plan.Status | Should Be 'planned'
        $plan.ScriptPath | Should Be ([IO.Path]::GetFullPath($scriptPath))
        $plan.ToolName | Should Be 'local_tool'
    }

    It 'rejects a lifecycle script path that escapes the approved directory' {
        $project = Join-Path $TestDrive 'escape-project'
        $outside = Join-Path $project 'scripts\smoke\outside.mjs'
        New-Item -ItemType Directory -Path (Split-Path $outside) -Force | Out-Null
        Set-Content -LiteralPath $outside -Encoding UTF8 -Value 'process.exit(0);'
        New-TestStartupFile
        $install = Get-McpInstallPlan -Tool (New-TestMcpTool -SnapshotOverrides @{
            smoke = [pscustomobject]@{
                tool_name = 'local_tool'; timeout_seconds = 10
                expected_content_types = @('text')
                script_path = 'scripts/smoke/mcp/../outside.mjs'
                script_sha256 = (Get-FileHash $outside).Hash.ToLowerInvariant()
                arguments = [pscustomobject]@{}
            }
        })

        $plan = Get-McpSmokePlan -InstallPlan $install -ProjectRoot $project

        $plan.Status | Should Be 'failed'
        $plan.ErrorCode | Should Be 'mcp_smoke_script_path_rejected'
    }

    It 'rejects a lifecycle path containing a reparse point' {
        $project = Join-Path $TestDrive 'reparse-project'
        $approvedParent = Join-Path $project 'scripts\smoke'
        $outside = Join-Path $TestDrive 'outside-lifecycle'
        New-Item -ItemType Directory -Path $approvedParent -Force | Out-Null
        New-Item -ItemType Directory -Path $outside -Force | Out-Null
        $outsideScript = Join-Path $outside 'test.mjs'
        Set-Content -LiteralPath $outsideScript -Encoding UTF8 -Value 'process.exit(0);'
        New-Item -ItemType Junction -Path (Join-Path $approvedParent 'mcp') `
            -Target $outside | Out-Null
        New-TestStartupFile
        $install = Get-McpInstallPlan -Tool (New-TestMcpTool -SnapshotOverrides @{
            smoke = [pscustomobject]@{
                tool_name = 'local_tool'; timeout_seconds = 10
                expected_content_types = @('text')
                script_path = 'scripts/smoke/mcp/test.mjs'
                script_sha256 = (Get-FileHash $outsideScript).Hash.ToLowerInvariant()
                arguments = [pscustomobject]@{}
            }
        })

        $plan = Get-McpSmokePlan -InstallPlan $install -ProjectRoot $project

        $plan.Status | Should Be 'failed'
        $plan.ErrorCode | Should Be 'mcp_smoke_script_path_rejected'
    }

    It 'rejects a lifecycle script hash mismatch' {
        $project = Join-Path $TestDrive 'hash-project'
        $scriptDir = Join-Path $project 'scripts\smoke\mcp'
        New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $scriptDir 'test.mjs') `
            -Encoding UTF8 -Value 'process.exit(0);'
        New-TestStartupFile
        $install = Get-McpInstallPlan -Tool (New-TestMcpTool -SnapshotOverrides @{
            smoke = [pscustomobject]@{
                tool_name = 'local_tool'; timeout_seconds = 10
                expected_content_types = @('text')
                script_path = 'scripts/smoke/mcp/test.mjs'
                script_sha256 = ('0' * 64)
                arguments = [pscustomobject]@{}
            }
        })

        $plan = Get-McpSmokePlan -InstallPlan $install -ProjectRoot $project

        $plan.Status | Should Be 'failed'
        $plan.ErrorCode | Should Be 'mcp_smoke_script_hash_mismatch'
    }
}
```

- [ ] **Step 2: 运行测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module Pester; Invoke-Pester .\tests\unit\McpAdapter.Tests.ps1 -PassThru" *> .\task-smoke-plan-red.log
```

Expected: FAIL，`Get-McpSmokePlan` 未定义。

- [ ] **Step 3: 实现 smoke plan**

新增 `Get-McpSmokePlan`，返回结构至少包含：

```powershell
[pscustomobject][ordered]@{
    Status = 'planned'
    Message = 'MCP smoke verification is planned.'
    ErrorCode = $null
    InstallPlan = $InstallPlan
    ToolName = [string]$profile.tool_name
    Arguments = $profile.arguments
    TimeoutSeconds = [int]$profile.timeout_seconds
    ExpectedContentTypes = @($profile.expected_content_types)
    ScriptPath = $resolvedScriptPath
    ScriptSha256 = [string]$profile.script_sha256
    RunnerPath = (Join-Path $ProjectRoot 'scripts\node\mcp-smoke-runner.mjs')
    TempRootParent = (Join-Path $ProjectRoot '.tmp\mcp-smoke')
    SdkClientPath = (Join-Path $workingDirectory 'node_modules\@modelcontextprotocol\sdk\dist\esm\client\index.js')
    SdkStdioPath = (Join-Path $workingDirectory 'node_modules\@modelcontextprotocol\sdk\dist\esm\client\stdio.js')
    ServerFilePath = [string]@(
        Get-Command -Name $InstallPlan.ResolvedCommand -CommandType Application `
            -ErrorAction Stop
    )[0].Source
}
```

实现必须：

- 使用 `[IO.Path]::GetFullPath` 和 `Test-McpAdapterPathWithinRoot`；
- 对 `scripts`、`smoke`、`mcp`、脚本文件逐级拒绝 ReparsePoint；
- 使用 `Get-FileHash -Algorithm SHA256` 比较小写摘要；
- 校验 runner 和两个 SDK 文件存在；
- 将 stdio command 解析为绝对 Application 路径并保存到 `ServerFilePath`，使最小环境下的 runner 不依赖 PATH；
- profile 缺失时返回 `blocked / smoke_verifier_missing`；
- `InstallPlan.Transport` 不是 `stdio` 时返回 `failed / mcp_smoke_profile_invalid`；
- 不执行任何进程。

- [ ] **Step 4: 新增 static profile verifier**

实现：

```powershell
function Test-ManagedMcpSmokeProfile {
    param([object]$Plan)
    if ($Plan.Status -eq 'blocked') {
        return @{ Status = 'blocked'; Message = $Plan.Message; ErrorCode = $Plan.ErrorCode }
    }
    if ($Plan.Status -ne 'planned') {
        return @{ Status = 'failed'; Message = $Plan.Message; ErrorCode = $Plan.ErrorCode }
    }
    return @{
        Status = 'static_verified'
        Message = 'MCP smoke profile paths and hashes were verified.'
        Checks = @('mcp_smoke_profile_valid', 'mcp_smoke_script_hash_verified')
    }
}
```

- [ ] **Step 5: 运行 GREEN 测试并提交**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\task-smoke-plan-green.log
```

Expected: `Failed: 0`。

```powershell
git add -- scripts/lib/adapters/McpAdapter.ps1 tests/unit/McpAdapter.Tests.ps1
git diff --cached --check
git commit -m "feat[mcp]: validate approved smoke plans"
```

---

### Task 6: 加固 MCP Load Verification

**Files:**
- Modify: `scripts/lib/adapters/McpAdapter.ps1:483-699,925-997`
- Modify: `tests/unit/McpAdapter.Tests.ps1:482-560`
- Modify: `tests/integration/EntryPoint.Tests.ps1:293-335`

- [ ] **Step 1: 新增 RED 配置一致性测试**

将现有成功 JSON 改为真实结构，并新增 mismatch：

```powershell
    It 'requires codex MCP transport command and arguments to match the approved plan' {
        New-TestStartupFile
        $plan = Get-McpInstallPlan -Tool (New-TestMcpTool)
        $actual = @{
            name = 'local-docs'
            enabled = $true
            transport = @{
                type = 'stdio'
                command = 'node'
                args = @('E:\tampered\index.js')
                cwd = $null
            }
        } | ConvertTo-Json -Depth 8 -Compress

        $result = Test-ManagedMcp -Plan $plan -Executor {
            param($Command) New-SuccessProcessResult -StdOut $actual
        }

        $result.Status | Should Be 'failed'
        $result.ErrorCode | Should Be 'mcp_config_mismatch'
    }
```

- [ ] **Step 2: 运行测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module Pester; Invoke-Pester .\tests\unit\McpAdapter.Tests.ps1 -PassThru" *> .\task-mcp-load-hardening-red.log
```

Expected: mismatch 测试错误地返回 `load_verified`。

- [ ] **Step 3: 在 install plan 保留解析后的 stdio 字段**

在 planned 返回对象增加：

```powershell
        ResolvedCommand = $resolvedCommand
        ResolvedArguments = @($resolvedArgs)
        WorkingDirectory = $workingDirectory
```

新增 `Test-McpGetOutputMatchesPlan`，对 stdio 比较：

```powershell
function Test-McpAdapterStringArrayEqual {
    param([object[]]$Left, [object[]]$Right)
    $leftValues = @($Left | ForEach-Object { [string]$_ })
    $rightValues = @($Right | ForEach-Object { [string]$_ })
    if ($leftValues.Count -ne $rightValues.Count) { return $false }
    for ($index = 0; $index -lt $leftValues.Count; $index++) {
        if ($leftValues[$index] -cne $rightValues[$index]) { return $false }
    }
    return $true
}

return (
    [string]$JsonObject.name -ceq $Plan.McpName -and
    [bool]$JsonObject.enabled -and
    [string]$JsonObject.transport.type -ceq 'stdio' -and
    [string]$JsonObject.transport.command -ceq $Plan.ResolvedCommand -and
    (Test-McpAdapterStringArrayEqual `
        -Left @($JsonObject.transport.args) `
        -Right @($Plan.ResolvedArguments))
)
```

不比较 `cwd`，因为当前 `codex mcp add` 不支持工作目录；绝对启动路径已经消除 cwd 依赖。

- [ ] **Step 4: 更新 fake Codex get 输出**

`New-FakeCodexCli` 的 mcp get 必须输出 `enabled` 和 `transport`，参数使用 fixture 传入的绝对启动文件。不要继续使用只有 name/configured 的简化 JSON。

- [ ] **Step 5: 运行 GREEN 测试并提交**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -All *> .\task-mcp-load-hardening-green.log
```

Expected: `Failed: 0`。

```powershell
git add -- scripts/lib/adapters/McpAdapter.ps1 tests/unit/McpAdapter.Tests.ps1 tests/integration/EntryPoint.Tests.ps1
git diff --cached --check
git commit -m "fix[mcp]: verify deployed transport configuration"
```

---

### Task 7: 执行生命周期与自动 Smoke

**Files:**
- Modify: `scripts/lib/adapters/McpAdapter.ps1`
- Modify: `tests/unit/McpAdapter.Tests.ps1`

- [ ] **Step 1: 新增 RED 生命周期和错误映射测试**

新增完整的 `Describe 'Test-ManagedMcpSmoke'`：

```powershell
Describe 'Test-ManagedMcpSmoke' {
    BeforeEach {
        $script:project = Join-Path $TestDrive 'smoke-project'
        $script:runnerPath = Join-Path $script:project 'scripts\node\mcp-smoke-runner.mjs'
        $script:lifecyclePath = Join-Path $script:project 'scripts\smoke\mcp\test.mjs'
        New-Item -ItemType Directory -Path (Split-Path $script:runnerPath) -Force | Out-Null
        New-Item -ItemType Directory -Path (Split-Path $script:lifecyclePath) -Force | Out-Null
        Set-Content -LiteralPath $script:runnerPath -Encoding UTF8 -Value 'process.exit(0);'
        Set-Content -LiteralPath $script:lifecyclePath -Encoding UTF8 -Value 'process.exit(0);'
        $sdk = Join-Path $TestDrive 'node_modules\@modelcontextprotocol\sdk\dist\esm\client'
        New-Item -ItemType Directory -Path $sdk -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $sdk 'index.js') -Encoding UTF8 -Value 'export {};'
        Set-Content -LiteralPath (Join-Path $sdk 'stdio.js') -Encoding UTF8 -Value 'export {};'
        New-TestStartupFile
        $hash = (Get-FileHash $script:lifecyclePath -Algorithm SHA256).Hash.ToLowerInvariant()
        $install = Get-McpInstallPlan -Tool (New-TestMcpTool -SnapshotOverrides @{
            smoke = [pscustomobject]@{
                tool_name = 'local_tool'; timeout_seconds = 10
                expected_content_types = @('text')
                script_path = 'scripts/smoke/mcp/test.mjs'
                script_sha256 = $hash
                arguments = [pscustomobject]@{ value = 1 }
            }
        })
        $script:smokePlan = Get-McpSmokePlan `
            -InstallPlan $install -ProjectRoot $script:project
        $script:utf8NoBom = New-Object Text.UTF8Encoding($false)
    }

    It 'runs prepare runner validate cleanup in order' {
        $script:steps = New-Object System.Collections.Generic.List[string]
        $result = Test-ManagedMcpSmoke -Plan $script:smokePlan -Executor {
            param($Command)
            $args = @($Command.Arguments)
            if ($args -contains 'prepare') { $script:steps.Add('prepare'); return New-SuccessProcessResult -StdOut '{"status":"ok"}' }
            if ($args[0] -eq $script:smokePlan.RunnerPath) {
                $script:steps.Add('runner')
                [IO.File]::WriteAllText($args[2], '{"status":"smoke_verified","errorCode":null,"contentTypes":["text"],"isError":false,"residualProcess":false}', $script:utf8NoBom)
                return New-SuccessProcessResult -StdOut '{"status":"smoke_verified"}'
            }
            if ($args -contains 'validate') { $script:steps.Add('validate'); return New-SuccessProcessResult -StdOut '{"status":"ok"}' }
            if ($args -contains 'cleanup') { $script:steps.Add('cleanup'); return New-SuccessProcessResult -StdOut '{"status":"ok"}' }
            throw 'unexpected command'
        }

        $result.Status | Should Be 'smoke_verified'
        @($script:steps) | Should Be @('prepare', 'runner', 'validate', 'cleanup')
    }

    It 'runs cleanup after runner failure' {
        $script:cleanupCalled = $false
        $result = Test-ManagedMcpSmoke -Plan $script:smokePlan -Executor {
            param($Command)
            $args = @($Command.Arguments)
            if ($args -contains 'prepare') { return New-SuccessProcessResult -StdOut '{"status":"ok"}' }
            if ($args[0] -eq $script:smokePlan.RunnerPath) {
                [IO.File]::WriteAllText($args[2], '{"status":"failed","errorCode":"mcp_smoke_timeout","isError":true,"residualProcess":false}', $script:utf8NoBom)
                return New-FailedProcessResult -StdErr 'runner failed' -TimedOut $true
            }
            if ($args -contains 'cleanup') {
                $script:cleanupCalled = $true
                return New-SuccessProcessResult -StdOut '{"status":"ok"}'
            }
            throw 'unexpected command'
        }

        $script:cleanupCalled | Should Be $true
        $result.Status | Should Be 'failed'
        $result.ErrorCode | Should Be 'mcp_smoke_timeout'
    }

    It 'fails when cleanup fails after a successful call' {
        $result = Test-ManagedMcpSmoke -Plan $script:smokePlan -Executor {
            param($Command)
            $args = @($Command.Arguments)
            if ($args -contains 'prepare') { return New-SuccessProcessResult -StdOut '{"status":"ok"}' }
            if ($args[0] -eq $script:smokePlan.RunnerPath) {
                [IO.File]::WriteAllText($args[2], '{"status":"smoke_verified","errorCode":null,"contentTypes":["text"],"isError":false,"residualProcess":false}', $script:utf8NoBom)
                return New-SuccessProcessResult -StdOut '{"status":"smoke_verified"}'
            }
            if ($args -contains 'validate') { return New-SuccessProcessResult -StdOut '{"status":"ok"}' }
            if ($args -contains 'cleanup') { return New-FailedProcessResult -StdErr 'cleanup failed' }
            throw 'unexpected command'
        }

        $result.Status | Should Be 'failed'
        $result.ErrorCode | Should Be 'mcp_smoke_cleanup_failed'
        @($result.Residuals).Count | Should BeGreaterThan 0
    }
}
```

- [ ] **Step 2: 运行测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module Pester; Invoke-Pester .\tests\unit\McpAdapter.Tests.ps1 -PassThru" *> .\task-mcp-smoke-adapter-red.log
```

Expected: FAIL，`Test-ManagedMcpSmoke` 未定义。

- [ ] **Step 3: 实现固定 lifecycle command**

命令必须以数组方式构造：

```powershell
function New-McpSmokeLifecycleCommand {
    param([object]$Plan, [string]$Action, [string]$OperationRoot, [string]$ResultPath)
    $readRoots = "$($Plan.ScriptPath),$OperationRoot"
    $arguments = @(
        '--permission',
        "--allow-fs-read=$readRoots",
        "--allow-fs-write=$OperationRoot",
        $Plan.ScriptPath,
        '--action', $Action,
        '--temp-root', $OperationRoot,
        '--result-path', $ResultPath
    )
    return [pscustomobject][ordered]@{
        FilePath = 'node'
        Arguments = $arguments
        TimeoutSeconds = $Plan.TimeoutSeconds
        WorkingDirectory = $OperationRoot
        ClearEnvironment = $true
        Environment = @{ SMOKE_ACTION = $Action; SMOKE_TEMP_ROOT = $OperationRoot }
    }
}
```

每次执行生命周期脚本前重新计算 SHA-256；不匹配时不执行脚本并返回 `mcp_smoke_script_hash_mismatch`。

- [ ] **Step 4: 实现 `Test-ManagedMcpSmoke` 的 finally 清理**

实现顺序必须为：创建空 operation root → prepare → 写入 request JSON → runner → 读取 result JSON → validate；在 `finally` 中执行 cleanup、删除 operation root、检查 runner 返回的 `residualProcess`。Runner request 的 `command` 必须使用 `Plan.ServerFilePath`，不能依赖已清空环境中的 PATH。Runner command 的参数顺序固定为 `RunnerPath`、`RequestPath`、`ResultPath`，以匹配上述测试。返回对象必须包含 `Status`、`Message`、`Checks`、`Residuals`、`ErrorCode`，且不得包含完整 arguments 或 MCP 正文。

错误优先级：

```powershell
if ($null -ne $primaryError) {
    $errorCode = $primaryError.ErrorCode
}
elseif ($cleanupFailed) {
    $errorCode = 'mcp_smoke_cleanup_failed'
}
elseif ($residualProcess) {
    $errorCode = 'mcp_smoke_residual_process'
}
else {
    $status = 'smoke_verified'
}
```

- [ ] **Step 5: 运行 GREEN 测试并提交**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\task-mcp-smoke-adapter-green.log
```

Expected: `Failed: 0`。

```powershell
git add -- scripts/lib/adapters/McpAdapter.ps1 tests/unit/McpAdapter.Tests.ps1
git diff --cached --check
git commit -m "feat[mcp]: execute managed smoke lifecycle"
```

---

### Task 8: 接入入口并实现 Sequential-thinking 生命周期脚本

**Files:**
- Create: `scripts/smoke/mcp/sequential-thinking.mjs`
- Modify: `scripts/Invoke-CodexToolManager.ps1:190-223,225-260,402-411`
- Modify: `tests/integration/EntryPoint.Tests.ps1`
- Modify: `Resources/tool_whitelist.toml:77-105`

- [ ] **Step 1: 创建生命周期脚本**

`scripts/smoke/mcp/sequential-thinking.mjs` 使用以下完整行为：

```javascript
import { readFile, readdir, rm, writeFile } from "node:fs/promises";
import path from "node:path";

function option(name) {
  const index = process.argv.indexOf(name);
  if (index < 0 || index + 1 >= process.argv.length) throw new Error(`Missing ${name}`);
  return process.argv[index + 1];
}

const action = option("--action");
const tempRoot = path.resolve(option("--temp-root"));
const resultPath = path.resolve(option("--result-path"));
if (path.dirname(resultPath) !== tempRoot) throw new Error("Result path escaped temp root");
const markerPath = path.join(tempRoot, "lifecycle-marker.json");

if (action === "prepare") {
  const entries = await readdir(tempRoot);
  if (entries.length !== 0) throw new Error("Smoke temp root was not empty");
  await writeFile(markerPath, JSON.stringify({ prepared: true }), "utf8");
} else if (action === "validate") {
  const result = JSON.parse(await readFile(resultPath, "utf8"));
  if (result.status !== "smoke_verified" || result.isError === true) {
    throw new Error("Sequential-thinking smoke call did not succeed");
  }
  if (!Array.isArray(result.contentTypes) || !result.contentTypes.includes("text")) {
    throw new Error("Sequential-thinking smoke result did not contain text");
  }
} else if (action === "cleanup") {
  await rm(markerPath, { force: true });
  await rm(resultPath, { force: true });
} else {
  throw new Error("Unsupported lifecycle action");
}

process.stdout.write(JSON.stringify({ status: "ok", action }));
```

- [ ] **Step 2: 计算真实哈希并写入白名单**

Run:

```powershell
$scriptPath = '.\scripts\smoke\mcp\sequential-thinking.mjs'
git check-attr eol -- $scriptPath
$scriptHash = (Get-FileHash -LiteralPath $scriptPath -Algorithm SHA256).Hash.ToLowerInvariant()
$scriptHash
```

Expected: `eol: lf`，随后输出 64 位小写十六进制。生成带真实哈希的 profile 文本：

```powershell
$profile = @"
[tools.smoke]
tool_name = "sequentialthinking"
timeout_seconds = 10
expected_content_types = ["text"]
script_path = "scripts/smoke/mcp/sequential-thinking.mjs"
script_sha256 = "$scriptHash"

[tools.smoke.arguments]
thought = "Codex tool manager automated smoke verification."
nextThoughtNeeded = false
thoughtNumber = 1
totalThoughts = 1
"@
$profile
```

Expected: `script_sha256` 行含真实摘要。使用 `apply_patch` 将该输出原样加入 sequential-thinking 条目，随后运行 `Test-WhitelistDocument`；禁止提交示例哈希或未展开变量。

- [ ] **Step 3: 扩展命令级 executor 参数**

`New-ManagerCodexExecutor` 从 Command 读取 `TimeoutSeconds`、`WorkingDirectory`、`Environment`、`ClearEnvironment`；不存在时保留当前 120 秒和继承环境行为。使用以下代码计算参数：

```powershell
$timeoutMember = Get-ProjectMember -InputObject $Command -Name 'TimeoutSeconds'
$commandTimeout = if ($timeoutMember.Exists) { [int]$timeoutMember.Value } else { $TimeoutSeconds }
$workingMember = Get-ProjectMember -InputObject $Command -Name 'WorkingDirectory'
$commandWorkingDirectory = if ($workingMember.Exists) { [string]$workingMember.Value } else { $null }
$environmentMember = Get-ProjectMember -InputObject $Command -Name 'Environment'
$commandEnvironment = if ($environmentMember.Exists) { $environmentMember.Value } else { $null }
$clearMember = Get-ProjectMember -InputObject $Command -Name 'ClearEnvironment'
$clearEnvironment = $clearMember.Exists -and [bool]$clearMember.Value

Invoke-ManagedProcess -FilePath $resolvedFilePath `
    -Arguments $argumentValues `
    -TimeoutSeconds $commandTimeout `
    -WorkingDirectory $commandWorkingDirectory `
    -Environment $commandEnvironment `
    -ClearEnvironment:$clearEnvironment
```

- [ ] **Step 4: 注入 MCP StaticVerifier 和 SmokeVerifier**

新增工厂：

```powershell
function New-ManagerMcpStaticVerifier {
    param([string]$ProjectRoot)
    return {
        param([object]$Tool)
        $install = Get-McpInstallPlan -Tool $Tool
        $smoke = Get-McpSmokePlan -InstallPlan $install -ProjectRoot $ProjectRoot
        Test-ManagedMcpSmokeProfile -Plan $smoke
    }.GetNewClosure()
}

function New-ManagerMcpSmokeVerifier {
    param([scriptblock]$Executor, [string]$ProjectRoot)
    return {
        param([object]$Tool)
        $install = Get-McpInstallPlan -Tool $Tool
        $smoke = Get-McpSmokePlan -InstallPlan $install -ProjectRoot $ProjectRoot
        Test-ManagedMcpSmoke -Plan $smoke -Executor $Executor
    }.GetNewClosure()
}
```

`ConvertTo-ManagerVerificationTool` 只在 `ApprovedSnapshot.smoke` 存在时附加两个 verifier；没有 profile 的 MCP 保持 `smoke_verifier_missing`。

- [ ] **Step 5: 新增入口 RED/GREEN 集成测试**

先把 `New-FakeCodexCli` 的 mcp get 分支改为输出环境变量中的完整 JSON：

```batch
if "%~1"=="mcp" if "%~2"=="get" (
  echo %CODEX_TOOL_MANAGER_FAKE_MCP_GET_JSON%
  exit /b 0
)
```

然后新增测试。它使用项目正式白名单、真实 sequential-thinking 本地服务器和 fake `codex mcp get`：

```powershell
    It 'returns smoke verified for an approved sequential-thinking profile' {
        $root = Join-Path $TestDrive 'sequential-smoke'
        New-Item -ItemType Directory -Path $root | Out-Null
        $config = Join-Path $root 'config.toml'
        Write-EntryPointTextFile -Path $config -Text @"
schema_version = 1
name = "sequential-smoke"
enabled_tools = ["mcp.modelcontextprotocol.sequential-thinking"]
"@
        $startup = 'E:\codex\MCP\servers\src\sequentialthinking\dist\index.js'
        (Test-Path -LiteralPath $startup -PathType Leaf) | Should Be $true
        $fake = New-FakeCodexCli -Root $root
        $oldPath = $env:PATH
        $oldLog = $env:CODEX_TOOL_MANAGER_FAKE_LOG
        $oldGet = $env:CODEX_TOOL_MANAGER_FAKE_MCP_GET_JSON
        try {
            $env:PATH = "$($fake.Bin);$oldPath"
            $env:CODEX_TOOL_MANAGER_FAKE_LOG = $fake.Log
            $env:CODEX_TOOL_MANAGER_FAKE_MCP_GET_JSON = ([ordered]@{
                name = 'modelcontextprotocol-sequential-thinking'
                enabled = $true
                transport = [ordered]@{
                    type = 'stdio'; command = 'node'; args = @($startup); cwd = $null
                }
            } | ConvertTo-Json -Depth 8 -Compress)
            $run = Invoke-EntryPointProcess -Arguments @(
                'verify', '-Config', $config,
                '-Whitelist', (Join-Path $projectRoot 'Resources\tool_whitelist.toml')
            )
        }
        finally {
            $env:PATH = $oldPath
            if ($null -eq $oldLog) { Remove-Item Env:\CODEX_TOOL_MANAGER_FAKE_LOG -ErrorAction SilentlyContinue }
            else { $env:CODEX_TOOL_MANAGER_FAKE_LOG = $oldLog }
            if ($null -eq $oldGet) { Remove-Item Env:\CODEX_TOOL_MANAGER_FAKE_MCP_GET_JSON -ErrorAction SilentlyContinue }
            else { $env:CODEX_TOOL_MANAGER_FAKE_MCP_GET_JSON = $oldGet }
        }
        $body = ConvertFrom-EntryPointJson -Run $run
        $run.ExitCode | Should Be 0
        $body.Status | Should Be 'succeeded'
        @($body.Results | Where-Object Level -eq 'smoke')[0].Status |
            Should Be 'smoke_verified'
    }
```

另保留现有无 profile fixture，断言 smoke 仍为 `blocked / smoke_verifier_missing`。

- [ ] **Step 6: 运行全量测试并提交**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -All *> .\task-mcp-auto-smoke-all.log
```

Expected: `Failed: 0`，sequential 集成测试整体退出码为 0。

```powershell
git add -- scripts/Invoke-CodexToolManager.ps1 scripts/smoke/mcp/sequential-thinking.mjs Resources/tool_whitelist.toml tests/integration/EntryPoint.Tests.ps1
git diff --cached --check
git commit -m "feat[mcp]: enable sequential-thinking auto smoke"
```

---

### Task 9: 真实环境复核、记录和最终验收

**Files:**
- Modify: `Notes/verify_record.md`
- Modify: `Resources/GUIDE.md`
- Modify: `state/README.md`
- Modify: `state/TODO.md`
- Modify: `state/LOG.md`

- [ ] **Step 1: 重新生成单工具计划**

重新创建 `.tmp\real-pilot\sequential-thinking.toml`，确保真实复核不依赖旧临时文件：

```toml
schema_version = 1
name = "Sequential Thinking MCP automatic smoke verification"
enabled_tools = ["mcp.modelcontextprotocol.sequential-thinking"]
```

Run:

```powershell
$pilot = '.\.tmp\real-pilot'
New-Item -ItemType Directory -Path $pilot -Force | Out-Null
$utf8NoBom = New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText(
  (Join-Path $pilot 'sequential-thinking.toml'),
  "schema_version = 1`nname = `"Sequential Thinking MCP automatic smoke verification`"`nenabled_tools = [`"mcp.modelcontextprotocol.sequential-thinking`"]`n",
  $utf8NoBom
)
```

Run:

```powershell
powershell -NoProfile -File .\scripts\Invoke-CodexToolManager.ps1 plan `
  -Config .\.tmp\real-pilot\sequential-thinking.toml `
  -Whitelist .\Resources\tool_whitelist.toml `
  -OutputPath .\.tmp\real-pilot\auto-smoke-plan.json `
  *> .\.tmp\real-pilot\auto-smoke-plan.log
```

Expected: exit 0、Errors=0、Items=1。

- [ ] **Step 2: 对真实用户配置执行自动 verify**

Run:

```powershell
powershell -NoProfile -File .\scripts\Invoke-CodexToolManager.ps1 verify `
  -PlanPath .\.tmp\real-pilot\auto-smoke-plan.json `
  *> .\.tmp\real-pilot\auto-smoke-verify.json
```

Expected: exit 0；static=`static_verified`、load=`load_verified`、smoke=`smoke_verified`；整体 Status=`succeeded`。

- [ ] **Step 3: 核验配置和残留**

Run:

```powershell
codex mcp get modelcontextprotocol-sequential-thinking --json *> .\.tmp\real-pilot\mcp-get-after-auto-smoke.json
$left = Get-CimInstance Win32_Process | Where-Object {
  $_.Name -eq 'node.exe' -and
  $_.CommandLine -like '*sequentialthinking\dist\index.js*'
}
"RESIDUAL_SERVER_PROCESSES=$(@($left).Count)"
$operationRoots = if (Test-Path .\.tmp\mcp-smoke) {
  @(Get-ChildItem .\.tmp\mcp-smoke -Directory -Force)
} else { @() }
"TEMP_OPERATION_ROOTS=$($operationRoots.Count)"
```

Expected: MCP enabled，参数仍为绝对启动路径；残留进程为 0；临时父目录可以存在，但 operation 子目录必须为 0。

- [ ] **Step 4: 更新简体中文记录**

记录必须明确：

- 自动 smoke 已接入并通过；
- 使用的工具名、内容类型和错误码，不记录完整 thought/result；
- 生命周期脚本哈希已固定；
- Node permission 不提供网络硬隔离；
- verifier 未执行卸载；
- filesystem 后续允许根目录已确认为 `E:\codex`，但尚未部署。

- [ ] **Step 5: 最终验证**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -All *> .\task-mcp-auto-smoke-final.log
Select-String -Path .\task-mcp-auto-smoke-final.log -Pattern 'Tests completed','Passed:','Failed:'
git diff --check
git status --short
```

Expected: 全量测试 `Failed: 0`；`git diff --check` 无输出；只有本任务记录文件未提交。

- [ ] **Step 6: 提交并推送记录**

```powershell
git add -- Notes/verify_record.md Resources/GUIDE.md state/README.md state/TODO.md state/LOG.md
git diff --cached --check
git commit -m "docs[mcp]: record automatic smoke verification"
git push
```

Expected: 推送成功，功能分支工作树干净，上游 HEAD 与本地 HEAD 一致。

---

## 最终自审清单

- [ ] 每个实现任务先有可观察的 RED，再做最小 GREEN。
- [ ] Smoke profile 只来自 `ApprovedSnapshot`。
- [ ] 未声明 profile 的 MCP 继续返回 `smoke_verifier_missing`。
- [ ] Load verifier 比较实际 transport、command 和参数。
- [ ] 生命周期脚本固定路径、固定 SHA-256、无内联 shell。
- [ ] 生命周期脚本只获得临时根文件权限和最小环境。
- [ ] 主流程失败时仍执行 cleanup。
- [ ] cleanup 失败或残留进程时不得返回 `smoke_verified`。
- [ ] verifier 不调用 `codex mcp remove`。
- [ ] 验证记录不包含完整 MCP 调用正文或敏感参数。
- [ ] Sequential-thinking 真实自动 smoke 返回 `smoke_verified`。
