# MCP 真实部署与验证最小闭环实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将入口命令的 `mcp` 类型从 planning-only 接入真实 Codex MCP add 和 load verification，同时保持 smoke verification blocked。

**Architecture:** 复用现有 `McpAdapter.ps1` 的 `Get-McpInstallPlan`、`Install-ManagedMcp` 和 `Test-ManagedMcp`。先让部署引擎的 approved snapshot 保留 MCP 专用字段，再在入口层新增 MCP deploy adapter 和 MCP load verifier；集成测试使用临时白名单、临时 stdio 启动文件和 fake `codex.cmd`，不修改真实用户 Codex 配置。

**Tech Stack:** Windows PowerShell 5.1、Pester 3.4、TOML 白名单、现有 PowerShell 部署/验证引擎、Codex CLI MCP 命令。

---

## 文件结构

- 修改：`scripts/lib/DeploymentEngine.ps1`
  - 在 `type = "mcp"` 时将 `mcp_transport`、`mcp_name`、`stdio`、`http` 写入 `ApprovedSnapshot`。
  - 保持 plugin、skill、mcp adapter-specific 字段按 type 隔离。
- 修改：`tests/unit/DeploymentEngine.Tests.ps1`
  - 新增 MCP snapshot 字段保留和跨类型隔离测试。
- 修改：`tests/integration/EntryPoint.Tests.ps1`
  - 新增 MCP fixture。
  - 扩展 fake Codex CLI 支持 `mcp add` 和 `mcp get`。
  - 新增 MCP dry-run、deploy、verify 入口测试。
- 修改：`scripts/Invoke-CodexToolManager.ps1`
  - 新增 MCP deploy adapter。
  - 新增 MCP load verifier。
  - 将 `mcp` 从 blocked adapter 切换到真实 adapter。
  - 在 verification tool 转换时为 mcp 附加 `LoadVerifier`。
- 修改：`state/README.md`
  - 记录 MCP 真实部署与 load verification 当前状态。
- 修改：`state/TODO.md`
  - 标记 MCP 最小闭环完成，保留 smoke 后续项。
- 修改：`state/LOG.md`
  - 记录 RED/GREEN 验证证据和剩余限制。

---

### Task 1: 部署引擎保留 MCP approved snapshot 字段

**Files:**
- Modify: `scripts/lib/DeploymentEngine.ps1`
- Modify: `tests/unit/DeploymentEngine.Tests.ps1`

- [ ] **Step 1: 新增 RED 单元测试：MCP snapshot 只保留 MCP 专用字段**

在 `tests/unit/DeploymentEngine.Tests.ps1` 中 `preserves only skill-specific approved fields for skill snapshots` 测试后追加：

```powershell
    It 'preserves only mcp-specific approved fields for mcp snapshots' {
        $tool = New-TestTool -Id 'mcp.entry'
        $tool.type = 'mcp'
        $tool.install_target = 'MCP/modelcontextprotocol/entry'
        $tool | Add-Member -NotePropertyName 'mcp_transport' `
            -NotePropertyValue 'stdio'
        $tool | Add-Member -NotePropertyName 'mcp_name' `
            -NotePropertyValue 'entry-mcp'
        $tool | Add-Member -NotePropertyName 'stdio' `
            -NotePropertyValue ([pscustomobject]@{
                command = 'node'
                args = @('dist/index.js')
                working_directory = 'E:\codex\MCP\servers\src\entry'
            })
        $tool | Add-Member -NotePropertyName 'marketplace_name' `
            -NotePropertyValue 'openai-curated'
        $tool | Add-Member -NotePropertyName 'skill_id' `
            -NotePropertyValue 'unsafe-skill'

        $plan = New-DeploymentPlan `
            -Config (New-TestConfig @('mcp.entry')) `
            -Whitelist (New-TestWhitelist @($tool)) `
            -CredentialMetadata @()

        $snapshot = $plan.Items[0].ApprovedSnapshot
        $snapshot.mcp_transport | Should Be 'stdio'
        $snapshot.mcp_name | Should Be 'entry-mcp'
        $snapshot.stdio.command | Should Be 'node'
        @($snapshot.stdio.args)[0] | Should Be 'dist/index.js'
        $snapshot.PSObject.Properties['marketplace_name'] | Should Be $null
        $snapshot.PSObject.Properties['skill_id'] | Should Be $null
        (Test-DeploymentPlan -Plan $plan).IsValid | Should Be $true
    }
```

- [ ] **Step 2: 运行单元测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\task-mcp-snapshot-red.log
```

Expected: FAIL。新增测试应显示 `mcp_transport` 或 `mcp_name` 为空，因为当前 `New-DeploymentApprovedSnapshot` 未保留 MCP 专用字段。

- [ ] **Step 3: 修改 `New-DeploymentApprovedSnapshot`**

在 `scripts/lib/DeploymentEngine.ps1` 的 adapter field 分支中添加 MCP 分支：

```powershell
    elseif ($type -eq 'mcp') {
        $adapterFields = @(
            'mcp_transport',
            'mcp_name',
            'stdio',
            'http'
        )
    }
```

不要把 MCP 字段加入 plugin 或 skill 分支。

- [ ] **Step 4: 运行单元测试确认 GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\task-mcp-snapshot-green.log
```

Expected: PASS。

- [ ] **Step 5: 提交部署快照字段**

```powershell
git -c safe.directory=E:/codex/.worktrees/phase1-foundation add -- scripts\lib\DeploymentEngine.ps1 tests\unit\DeploymentEngine.Tests.ps1
git -c safe.directory=E:/codex/.worktrees/phase1-foundation diff --cached --check
git -c safe.directory=E:/codex/.worktrees/phase1-foundation commit -m "fix[mcp]: preserve approved mcp snapshot fields"
```

---

### Task 2: 入口 MCP 测试夹具和 dry-run 覆盖

**Files:**
- Modify: `tests/integration/EntryPoint.Tests.ps1`

- [ ] **Step 1: 新增 MCP fixture**

在 `New-EntryPointSkillFixture` 后追加：

```powershell
function New-EntryPointMcpFixture {
    param(
        [string]$Root,
        [string]$ToolId = 'mcp.entry',
        [string]$McpName = 'entry-mcp'
    )

    $serverRoot = Join-Path $Root 'server'
    $dist = Join-Path $serverRoot 'dist'
    New-Item -ItemType Directory -Path $dist -Force | Out-Null
    Write-EntryPointTextFile -Path (Join-Path $dist 'index.js') -Text @"
console.log('entry mcp fixture');
"@

    $configPath = Join-Path $Root 'config.toml'
    $whitelistPath = Join-Path $Root 'whitelist.toml'
    $hash = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
    Write-EntryPointTextFile -Path $configPath -Text @"
schema_version = 1
name = "mcp-entrypoint"
enabled_tools = ["$ToolId"]
"@
    Write-EntryPointTextFile -Path $whitelistPath -Text @"
schema_version = "1.0"

[[tools]]
id = "$ToolId"
name = "Entry MCP"
type = "mcp"
source = "local"
version = "1.0.0"
sha256 = "$hash"
license = "MIT"
approval = "approved"
risk = "medium"
install_target = "MCP/entry"
credential_refs = []
conflicts = []
dependencies = []
permissions = []
external_changes = []
rollback_capability = "managed_files"
mcp_transport = "stdio"
mcp_name = "$McpName"

[tools.stdio]
command = "node"
args = ["dist/index.js"]
working_directory = "$($serverRoot.Replace('\', '\\'))"
"@

    return [pscustomobject]@{
        Config = $configPath
        Whitelist = $whitelistPath
        ServerRoot = $serverRoot
        StartupFile = Join-Path $dist 'index.js'
        McpName = $McpName
    }
}
```

- [ ] **Step 2: 扩展 fake Codex CLI 支持 MCP 命令**

在 `New-FakeCodexCli` 的 batch 脚本中，plugin list 分支后、unsupported 分支前追加：

```batch
if "%~1"=="mcp" if "%~2"=="add" (
  echo {"ok":true,"name":"%~3"}
  exit /b 0
)
if "%~1"=="mcp" if "%~2"=="get" (
  echo {"name":"%~3","configured":true}
  exit /b 0
)
```

- [ ] **Step 3: 新增 MCP dry-run 测试**

在 Skill dry-run 测试后追加：

```powershell
    It 'keeps approved mcp deploy dry-run from calling Codex CLI' {
        $root = Join-Path $TestDrive 'mcp-dryrun'
        $fixture = New-EntryPointMcpFixture -Root $root
        $fake = New-FakeCodexCli -Root $root
        $oldPath = $env:PATH
        $oldLog = $env:CODEX_TOOL_MANAGER_FAKE_LOG
        try {
            $env:PATH = "$($fake.Bin);$oldPath"
            $env:CODEX_TOOL_MANAGER_FAKE_LOG = $fake.Log

            $run = Invoke-EntryPointProcess -Arguments @(
                'deploy', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist,
                '-DryRun'
            )
        }
        finally {
            $env:PATH = $oldPath
            if ($null -eq $oldLog) {
                Remove-Item Env:\CODEX_TOOL_MANAGER_FAKE_LOG -ErrorAction SilentlyContinue
            }
            else {
                $env:CODEX_TOOL_MANAGER_FAKE_LOG = $oldLog
            }
        }

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'deploy'
        $body.Status | Should Be 'succeeded'
        @($body.Results)[0].Status | Should Be 'dry_run'
        (Test-Path -LiteralPath $fake.Log -PathType Leaf) | Should Be $false
    }
```

- [ ] **Step 4: 运行集成测试确认夹具不破坏现有行为**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-mcp-fixture.log
```

Expected: PASS。

- [ ] **Step 5: 提交测试夹具**

```powershell
git -c safe.directory=E:/codex/.worktrees/phase1-foundation add -- tests\integration\EntryPoint.Tests.ps1
git -c safe.directory=E:/codex/.worktrees/phase1-foundation diff --cached --check
git -c safe.directory=E:/codex/.worktrees/phase1-foundation commit -m "test[mcp]: add entrypoint mcp fixtures"
```

---

### Task 3: 接入 MCP 真实部署 adapter

**Files:**
- Modify: `scripts/Invoke-CodexToolManager.ps1`
- Modify: `tests/integration/EntryPoint.Tests.ps1`

- [ ] **Step 1: 新增 RED 测试：非 dry-run MCP 部署应调用 Codex MCP add**

在 plugin deploy 测试后追加：

```powershell
    It 'deploys an approved mcp through the managed MCP adapter' {
        $root = Join-Path $TestDrive 'mcp-deploy'
        $fixture = New-EntryPointMcpFixture -Root $root
        $fake = New-FakeCodexCli -Root $root
        $oldPath = $env:PATH
        $oldLog = $env:CODEX_TOOL_MANAGER_FAKE_LOG
        try {
            $env:PATH = "$($fake.Bin);$oldPath"
            $env:CODEX_TOOL_MANAGER_FAKE_LOG = $fake.Log

            $run = Invoke-EntryPointProcess -Arguments @(
                'deploy', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
            )
        }
        finally {
            $env:PATH = $oldPath
            if ($null -eq $oldLog) {
                Remove-Item Env:\CODEX_TOOL_MANAGER_FAKE_LOG -ErrorAction SilentlyContinue
            }
            else {
                $env:CODEX_TOOL_MANAGER_FAKE_LOG = $oldLog
            }
        }

        $run.ExitCode | Should Be 0
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'deploy'
        $body.Status | Should Be 'succeeded'
        @($body.Results)[0].Status | Should Be 'succeeded'
        $log = Get-Content -LiteralPath $fake.Log -Raw
        $log | Should Match 'mcp add entry-mcp'
    }
```

- [ ] **Step 2: 运行集成测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-mcp-deploy-red.log
```

Expected: FAIL。新增测试应看到 MCP 仍 blocked，未调用 fake `codex mcp add`。

- [ ] **Step 3: 新增 MCP adapter factory**

在 `New-ManagerSkillLoadVerifier` 后追加：

```powershell
function New-ManagerMcpAdapter {
    param([scriptblock]$Executor)

    return {
        param([object]$Item)

        $plan = Get-McpInstallPlan -Tool $Item
        Install-ManagedMcp -Plan $plan -Executor $Executor
    }.GetNewClosure()
}
```

- [ ] **Step 4: 修改 adapter map，只将 mcp 切到真实 adapter**

将 `New-ManagerAdapterMap` 中的 mcp 分支从 blocked 改为：

```powershell
$map['mcp'] = New-ManagerMcpAdapter -Executor $Executor
```

保留：

```powershell
$map['plugin'] = New-ManagerPluginAdapter -Executor $Executor
$map['skill'] = New-ManagerSkillAdapter
```

- [ ] **Step 5: 运行集成和单元测试确认 GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-mcp-deploy-green.log
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\task-mcp-deploy-unit.log
```

Expected: PASS。MCP deploy 测试通过；plugin 和 skill 测试仍通过。

- [ ] **Step 6: 提交 MCP 部署接入**

```powershell
git -c safe.directory=E:/codex/.worktrees/phase1-foundation add -- scripts\Invoke-CodexToolManager.ps1 tests\integration\EntryPoint.Tests.ps1
git -c safe.directory=E:/codex/.worktrees/phase1-foundation diff --cached --check
git -c safe.directory=E:/codex/.worktrees/phase1-foundation commit -m "feat[mcp]: enable entrypoint mcp deployment"
```

---

### Task 4: 接入 MCP load verification

**Files:**
- Modify: `scripts/Invoke-CodexToolManager.ps1`
- Modify: `tests/integration/EntryPoint.Tests.ps1`

- [ ] **Step 1: 新增 RED 测试：MCP verify load 应调用 Codex MCP get**

在 plugin verify 测试后追加：

```powershell
    It 'verifies an approved mcp through the Codex MCP get output' {
        $root = Join-Path $TestDrive 'mcp-verify'
        $fixture = New-EntryPointMcpFixture -Root $root
        $fake = New-FakeCodexCli -Root $root
        $oldPath = $env:PATH
        $oldLog = $env:CODEX_TOOL_MANAGER_FAKE_LOG
        try {
            $env:PATH = "$($fake.Bin);$oldPath"
            $env:CODEX_TOOL_MANAGER_FAKE_LOG = $fake.Log

            $run = Invoke-EntryPointProcess -Arguments @(
                'verify', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
            )
        }
        finally {
            $env:PATH = $oldPath
            if ($null -eq $oldLog) {
                Remove-Item Env:\CODEX_TOOL_MANAGER_FAKE_LOG -ErrorAction SilentlyContinue
            }
            else {
                $env:CODEX_TOOL_MANAGER_FAKE_LOG = $oldLog
            }
        }

        $run.ExitCode | Should Be 1
        $body = ConvertFrom-EntryPointJson -Run $run
        $body.Command | Should Be 'verify'
        $body.Status | Should Be 'blocked'
        @($body.Results | Where-Object { $_.Level -eq 'static' })[0].Status |
            Should Be 'static_verified'
        @($body.Results | Where-Object { $_.Level -eq 'load' })[0].Status |
            Should Be 'load_verified'
        @($body.Results | Where-Object { $_.Level -eq 'smoke' })[0].Status |
            Should Be 'blocked'
        $log = Get-Content -LiteralPath $fake.Log -Raw
        $log | Should Match 'mcp get entry-mcp --json'
    }
```

- [ ] **Step 2: 运行集成测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-mcp-verify-red.log
```

Expected: FAIL。当前入口没有给 mcp 附加 load verifier，load 仍 blocked。

- [ ] **Step 3: 新增 MCP load verifier factory**

在 `New-ManagerMcpAdapter` 后追加：

```powershell
function New-ManagerMcpLoadVerifier {
    param([scriptblock]$Executor)

    return {
        param([object]$Tool)

        $plan = Get-McpInstallPlan -Tool $Tool
        Test-ManagedMcp -Plan $plan -Executor $Executor
    }.GetNewClosure()
}
```

- [ ] **Step 4: 修改 verification tool 转换，为 mcp 附加 LoadVerifier**

在 `ConvertTo-ManagerVerificationTool` 的 skill LoadVerifier 分支后追加：

```powershell
    if ($Item.Type -eq 'mcp') {
        $tool | Add-Member -NotePropertyName LoadVerifier `
            -NotePropertyValue (New-ManagerMcpLoadVerifier -Executor $Executor)
    }
```

确认 `ApprovedSnapshot = $Item.ApprovedSnapshot` 保持不变。

- [ ] **Step 5: 运行集成和单元测试确认 GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-mcp-verify-green.log
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\task-mcp-verify-unit.log
```

Expected: PASS。MCP load 为 `load_verified`，smoke 仍 blocked。

- [ ] **Step 6: 提交 MCP load verification 接入**

```powershell
git -c safe.directory=E:/codex/.worktrees/phase1-foundation add -- scripts\Invoke-CodexToolManager.ps1 tests\integration\EntryPoint.Tests.ps1
git -c safe.directory=E:/codex/.worktrees/phase1-foundation diff --cached --check
git -c safe.directory=E:/codex/.worktrees/phase1-foundation commit -m "feat[mcp]: enable entrypoint mcp load verification"
```

---

### Task 5: 状态文档与最终验证

**Files:**
- Modify: `state/README.md`
- Modify: `state/TODO.md`
- Modify: `state/LOG.md`

- [ ] **Step 1: 更新状态文件**

在 `state/README.md` 当前能力状态末尾追加：

```markdown
- 2026-06-27 MCP 真实部署与 load verification 最小闭环：入口已对 mcp 类型接入 `Install-ManagedMcp` 和 `Test-ManagedMcp` load verifier；plugin、skill、mcp 均已有真实部署和 load verification 最小闭环；MCP smoke verifier 尚未实现，不能宣称 MCP 工具方法已被安全调用。
```

在 `state/TODO.md` 中调整后续项：

```markdown
- [x] 接入 MCP 真实部署适配器和 load verifier；当前只证明 Codex MCP 配置可查询到该 MCP。
- [ ] 为 MCP 补充真正的功能性 smoke verifier；当前不伪造 MCP 工具调用成功。
```

在 `state/LOG.md` 末尾追加：

```markdown
## 2026-06-27：MCP 真实部署与 load 验证最小闭环

- `mcp` 类型已从 blocked adapter 切换到真实 `Install-ManagedMcp`；测试使用临时 MCP stdio server 文件和 fake `codex.cmd`，未修改真实用户 Codex MCP 配置。
- `New-DeploymentApprovedSnapshot` 现在按 `mcp` 类型保留 `mcp_transport`、`mcp_name`、`stdio` 和 `http`，并继续隔离 plugin、skill、mcp 的 adapter-specific 字段。
- `verify` 已为 mcp 附加 load verifier，通过 `codex mcp get <name> --json` 验证 MCP 在 Codex 配置中可查询；smoke verification 仍保守阻塞，不能宣称 MCP 工具方法已被安全调用。
- TDD 证据记录在 `task-mcp-*.log` 文件中；最终验收以全量测试、TOML 解析和 `git diff --check` 为准。
```

- [ ] **Step 2: 运行最终验证**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -All *> .\task-mcp-real-all.log
```

Expected: PASS。

Run:

```powershell
Get-ChildItem -LiteralPath Resources -Filter *.toml | ForEach-Object {
    python .\scripts\python\toml_to_json.py $_.FullName *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Output $_.Name
        exit $LASTEXITCODE
    }
}
'TOML_OK'
```

Expected: `TOML_OK`。

Run:

```powershell
git -c safe.directory=E:/codex/.worktrees/phase1-foundation diff --check
```

Expected: no errors.

- [ ] **Step 3: 读取测试摘要**

Run:

```powershell
Select-String -Path .\task-mcp-real-all.log -Pattern 'Tests completed|Passed:|Failed:'
```

Expected: `Failed: 0`。

- [ ] **Step 4: 提交状态记录**

```powershell
git -c safe.directory=E:/codex/.worktrees/phase1-foundation add -- state\README.md state\TODO.md state\LOG.md
git -c safe.directory=E:/codex/.worktrees/phase1-foundation diff --cached --check
git -c safe.directory=E:/codex/.worktrees/phase1-foundation commit -m "docs[state]: record mcp deployment milestone"
```

- [ ] **Step 5: 推送分支**

```powershell
git -c safe.directory=E:/codex/.worktrees/phase1-foundation status --short
git -c safe.directory=E:/codex/.worktrees/phase1-foundation push
```

Expected: 工作树干净，`feat/phase1-foundation` 推送到 `origin/feat/phase1-foundation`。

---

## 自审

- 规格覆盖：计划覆盖 MCP deploy、MCP load verify、dry-run 保持无副作用、smoke blocked、状态记录和最终验证。
- 白名单边界：不批准新工具，不纳入 `mcp.modelcontextprotocol.memory`。
- 类型一致：入口使用 `Item.ApprovedSnapshot` 给 `McpAdapter`，不信任 top-level 可变字段覆盖 snapshot。
- 测试隔离：集成测试使用临时 MCP stdio 启动文件和 fake `codex.cmd`，不修改真实 Codex MCP 配置。
- 风险边界：不读取认证文件正文，不调用 MCP 工具方法，不把 load 可查询伪造成 smoke 成功。
