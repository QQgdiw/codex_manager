# 插件真实部署与验证最小闭环实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将入口命令的 `plugin` 类型从 planning-only 接入真实插件部署和 load verification，首批覆盖 `browser + superpowers`，同时保持 Skill/MCP blocked。

**Architecture:** 复用现有 `PluginAdapter.ps1` 的 `Get-PluginInstallPlan`、`Install-ManagedPlugin` 和 `Test-ManagedPlugin`。入口层新增 Codex CLI executor 和 plugin adapter 接线；测试通过临时 `codex.cmd` 注入到 `PATH`，不调用真实 Codex CLI。

**Tech Stack:** Windows PowerShell 5.1、Pester 3.4、TOML 白名单、现有 PowerShell 部署/验证引擎。

---

## 文件结构

- 修改：`scripts/Invoke-CodexToolManager.ps1`
  - 新增 Codex CLI executor。
  - 将 plugin 部署接到 `Install-ManagedPlugin`。
  - 将 plugin load verification 接到 `Test-ManagedPlugin`。
  - 保持 skill/mcp blocked。
- 修改：`tests/integration/EntryPoint.Tests.ps1`
  - 新增插件 fixture。
  - 新增 fake `codex.cmd`。
  - 新增 deploy 与 verify 入口测试。
- 修改：`state/README.md`
  - 记录插件真实路径接入后的状态。
- 修改：`state/TODO.md`
  - 标记插件最小闭环完成，保留 Skill/MCP 后续项。
- 修改：`state/LOG.md`
  - 记录验证证据和剩余限制。

---

### Task 1: 入口插件测试夹具

**Files:**
- Modify: `tests/integration/EntryPoint.Tests.ps1`

- [ ] **Step 1: 新增 fake Codex CLI 工具函数**

在 `ConvertFrom-EntryPointJson` 函数后追加：

```powershell
function New-FakeCodexCli {
    param([string]$Root)

    $bin = Join-Path $Root 'fake-bin'
    New-Item -ItemType Directory -Path $bin -Force | Out-Null
    $log = Join-Path $Root 'fake-codex.log'
    $script = Join-Path $bin 'codex.cmd'
    Set-Content -LiteralPath $script -Encoding ASCII -Value @"
@echo off
echo %*>>"%CODEX_TOOL_MANAGER_FAKE_LOG%"
if "%1"=="plugin" if "%2"=="marketplace" if "%3"=="add" (
  echo {"ok":true}
  exit /b 0
)
if "%1"=="plugin" if "%2"=="add" (
  echo {"ok":true}
  exit /b 0
)
if "%1"=="plugin" if "%2"=="list" (
  echo [{"plugin":"browser","marketplace":"openai-bundled"},{"plugin":"superpowers","marketplace":"openai-curated"}]
  exit /b 0
)
echo unsupported fake codex command: %* 1>&2
exit /b 3
"@

    return [pscustomobject]@{
        Bin = $bin
        Log = $log
    }
}
```

- [ ] **Step 2: 新增插件 fixture**

在 `New-EntryPointFixture` 后追加：

```powershell
function New-EntryPointPluginFixture {
    param(
        [string]$Root,
        [string]$ToolId = 'plugin.openai-bundled.browser',
        [string]$Selector = 'browser',
        [string]$Marketplace = 'openai-bundled'
    )

    $configPath = Join-Path $Root 'config.toml'
    $whitelistPath = Join-Path $Root 'whitelist.toml'
    $hash = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
    Write-EntryPointTextFile -Path $configPath -Text @"
schema_version = 1
name = "plugin-entrypoint"
enabled_tools = ["$ToolId"]
"@
    Write-EntryPointTextFile -Path $whitelistPath -Text @"
schema_version = "1.0"

[[tools]]
id = "$ToolId"
name = "Entry Point Plugin"
type = "plugin"
source = "https://github.com/example/plugin-market"
version = "v1.0.0"
sha256 = "$hash"
license = "MIT"
approval = "approved"
risk = "low"
install_target = "Plugins/$Marketplace/$Selector"
credential_refs = []
conflicts = []
dependencies = []
permissions = []
external_changes = []
rollback_capability = "managed_files"
marketplace_name = "$Marketplace"
plugin_selector = "$Selector"
"@

    return [pscustomobject]@{
        Config = $configPath
        Whitelist = $whitelistPath
        ToolId = $ToolId
        Selector = $Selector
        Marketplace = $Marketplace
    }
}
```

- [ ] **Step 3: 新增插件 dry-run 测试，确认 fake Codex 未被调用**

在现有 `deploy WhatIf reports planned work and leaves the target absent` 测试后追加：

```powershell
It 'keeps approved plugin deploy dry-run from calling Codex CLI' {
    $root = Join-Path $TestDrive 'plugin-dryrun'
    $fixture = New-EntryPointPluginFixture -Root $root
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
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-plugin-fixture.log
```

Expected: PASS。新 fixture 只覆盖 dry-run，不要求真实 adapter 已接入。

- [ ] **Step 5: 提交测试夹具**

```powershell
git add tests\integration\EntryPoint.Tests.ps1
git diff --cached --check
git commit -m "test[plugin]: add entrypoint plugin fixtures"
```

---

### Task 2: 接入插件真实部署 adapter

**Files:**
- Modify: `scripts/Invoke-CodexToolManager.ps1`
- Test: `tests/integration/EntryPoint.Tests.ps1`

- [ ] **Step 1: 新增 RED 测试：非 dry-run 插件部署应执行 fake Codex**

在 `deploy without an adapter reports blocked business failure` 测试后追加：

```powershell
It 'deploys an approved plugin through the Codex plugin adapter' {
    $root = Join-Path $TestDrive 'plugin-deploy'
    $fixture = New-EntryPointPluginFixture -Root $root
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
    $log | Should Match 'plugin marketplace add'
    $log | Should Match 'plugin add browser@openai-bundled'
}
```

- [ ] **Step 2: 运行测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-plugin-deploy-red.log
```

Expected: FAIL。新增测试应看到入口仍返回 blocked 或未执行 fake Codex log，因为 `plugin` 仍是 blocked adapter。

- [ ] **Step 3: 新增 Codex CLI executor**

在 `New-ManagerBlockedAdapter` 前追加：

```powershell
function New-ManagerCodexExecutor {
    param([int]$TimeoutSeconds = 120)

    return {
        param([object]$Command)

        $filePath = Get-ProjectMember -InputObject $Command -Name 'FilePath'
        $arguments = Get-ProjectMember -InputObject $Command -Name 'Arguments'
        if (-not $filePath.Exists -or [string]::IsNullOrWhiteSpace([string]$filePath.Value)) {
            throw 'Managed command is missing FilePath.'
        }

        $argumentValues = if ($arguments.Exists) {
            @($arguments.Value | ForEach-Object { [string]$_ })
        }
        else {
            @()
        }

        Invoke-ManagedProcess `
            -FilePath ([string]$filePath.Value) `
            -Arguments $argumentValues `
            -TimeoutSeconds $TimeoutSeconds
    }.GetNewClosure()
}
```

- [ ] **Step 4: 新增插件 deployment adapter factory**

在 `New-ManagerBlockedAdapter` 后追加：

```powershell
function New-ManagerPluginAdapter {
    param([scriptblock]$Executor)

    return {
        param([object]$Item)

        $plan = Get-PluginInstallPlan -Tool $Item
        Install-ManagedPlugin -Plan $plan -Executor $Executor
    }.GetNewClosure()
}
```

- [ ] **Step 5: 修改 adapter map，只接入 plugin**

将 `New-ManagerAdapterMap` 改为：

```powershell
function New-ManagerAdapterMap {
    param([AllowNull()][scriptblock]$Executor)

    if ($null -eq $Executor) {
        $Executor = New-ManagerCodexExecutor
    }

    $map = @{}
    $map['plugin'] = New-ManagerPluginAdapter -Executor $Executor
    $map['mcp'] = New-ManagerBlockedAdapter -Type 'mcp'
    $map['skill'] = New-ManagerBlockedAdapter -Type 'skill'
    return $map
}
```

- [ ] **Step 6: 保持 deploy 调用点兼容**

确认 `Invoke-ManagerDeploy` 仍调用：

```powershell
-AdapterMap (New-ManagerAdapterMap)
```

不需要新增用户参数。

- [ ] **Step 7: 运行集成测试确认 GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-plugin-deploy-green.log
```

Expected: PASS。新增插件部署测试通过；原 Skill blocked 测试仍通过。

- [ ] **Step 8: 运行相关单元测试**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\task-plugin-deploy-unit.log
```

Expected: PASS。

- [ ] **Step 9: 提交插件部署接入**

```powershell
git add scripts\Invoke-CodexToolManager.ps1 tests\integration\EntryPoint.Tests.ps1
git diff --cached --check
git commit -m "feat[plugin]: enable entrypoint plugin deployment"
```

---

### Task 3: 接入插件 load verification

**Files:**
- Modify: `scripts/Invoke-CodexToolManager.ps1`
- Modify: `tests/integration/EntryPoint.Tests.ps1`

- [ ] **Step 1: 新增 RED 测试：verify 能执行插件 load 检查**

在 `verify is conservative when no load or smoke verifier is present` 后追加：

```powershell
It 'verifies an approved plugin through the Codex plugin list output' {
    $root = Join-Path $TestDrive 'plugin-verify'
    $fixture = New-EntryPointPluginFixture -Root $root
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
    $log | Should Match 'plugin list --json'
}
```

- [ ] **Step 2: 运行测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-plugin-verify-red.log
```

Expected: FAIL。当前入口转换出的 verification tool 没有 load verifier，load 仍 blocked。

- [ ] **Step 3: 新增插件 load verifier factory**

在 `New-ManagerPluginAdapter` 后追加：

```powershell
function New-ManagerPluginLoadVerifier {
    param([scriptblock]$Executor)

    return {
        param([object]$Tool)

        $plan = Get-PluginInstallPlan -Tool $Tool
        Test-ManagedPlugin -Plan $plan -Executor $Executor
    }.GetNewClosure()
}
```

- [ ] **Step 4: 扩展 verification tool 转换**

将 `ConvertTo-ManagerVerificationTool` 改为接收 executor，并在 plugin 上附加 `LoadVerifier`：

```powershell
function ConvertTo-ManagerVerificationTool {
    param(
        [object]$Item,
        [AllowNull()][scriptblock]$Executor
    )

    $tool = [pscustomobject][ordered]@{
        id = "$($Item.Id)"
        name = "$($Item.Name)"
        type = "$($Item.Type)"
        source = "$($Item.Source)"
        version = "$($Item.Version)"
        credential_refs = @($Item.CredentialRefs)
        sensitive_redactions = @()
        ApprovedSnapshot = $Item.ApprovedSnapshot
    }

    if ($Item.Type -eq 'plugin') {
        $tool | Add-Member -NotePropertyName LoadVerifier `
            -NotePropertyValue (New-ManagerPluginLoadVerifier -Executor $Executor)
    }

    return $tool
}
```

- [ ] **Step 5: 修改 verify 调用点传入 executor**

在 `Invoke-ManagerVerify` 中创建 executor：

```powershell
$executor = New-ManagerCodexExecutor
```

并将转换调用改为：

```powershell
$tool = ConvertTo-ManagerVerificationTool -Item $item -Executor $executor
```

- [ ] **Step 6: 运行集成测试确认 GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-plugin-verify-green.log
```

Expected: PASS。插件 load 为 `load_verified`，smoke 仍 blocked；Skill/MCP 仍按原保守路径 blocked。

- [ ] **Step 7: 运行单元测试**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\task-plugin-verify-unit.log
```

Expected: PASS。

- [ ] **Step 8: 提交插件验证接入**

```powershell
git add scripts\Invoke-CodexToolManager.ps1 tests\integration\EntryPoint.Tests.ps1
git diff --cached --check
git commit -m "feat[plugin]: enable entrypoint plugin load verification"
```

---

### Task 4: 状态文档与最终验证

**Files:**
- Modify: `state/README.md`
- Modify: `state/TODO.md`
- Modify: `state/LOG.md`

- [ ] **Step 1: 更新状态文件**

在 `/state` 中记录：

```markdown
2026-06-25 已接入插件真实部署与 load verification 最小闭环。当前真实路径仅覆盖 plugin 类型，首批目标为 browser 与 superpowers；Skill 和 MCP 仍保持 blocked adapter，尚未接入真实安装、加载验证或 smoke 验证。
```

在 `state/TODO.md` 中保留后续项：

```markdown
- [ ] 接入 Skill 真实部署适配器和 load/smoke verifier。
- [ ] 接入 MCP 真实部署适配器和 load/smoke verifier。
- [ ] 为插件补充真正的功能性 smoke verifier；当前只证明 load 可见，不伪造插件功能成功。
```

- [ ] **Step 2: 运行最终验证**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -All *> .\task-plugin-real-all.log
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
git diff --check
```

Expected: no errors.

- [ ] **Step 3: 读取测试摘要**

Run:

```powershell
Select-String -Path .\task-plugin-real-all.log -Pattern 'Tests completed|Passed:|Failed:'
```

Expected: `Failed: 0`。

- [ ] **Step 4: 提交状态记录**

```powershell
git add state\README.md state\TODO.md state\LOG.md
git diff --cached --check
git commit -m "docs[state]: record plugin deployment milestone"
```

- [ ] **Step 5: 推送分支**

```powershell
git status --short
git push
```

Expected: 工作树干净，`feat/phase1-foundation` 推送到 `origin/feat/phase1-foundation`。

---

## 自审

- 规格覆盖：计划覆盖 plugin deploy、plugin load verify、dry-run 保持不变、Skill/MCP blocked、状态记录和验证。
- 无未决后补项或含糊承诺。
- 类型一致：入口使用 `Item.ApprovedSnapshot` 给 `PluginAdapter`，executor 使用现有 `Invoke-ManagedProcess` 返回字段。
- 测试隔离：集成测试通过临时 `codex.cmd` 和临时 `PATH` 注入，不调用真实 Codex CLI，不修改用户插件配置。
- 风险边界：不读取认证文件正文，不新增用户必须记忆的命令参数，不把 smoke 伪造成成功。
