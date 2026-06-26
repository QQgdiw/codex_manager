# Skill 真实部署与验证最小闭环实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将入口命令的 `skill` 类型从 planning-only 接入真实受管安装和 load verification，同时保持 MCP blocked。

**Architecture:** 复用现有 `SkillAdapter.ps1` 的 `Get-SkillInstallPlan`、`Install-ManagedSkill` 和 `Test-ManagedSkill`。入口层只新增 Skill adapter 和 Skill load verifier 接线；测试使用临时 Skill source 和临时 workspace，不触碰真实 `E:\codex\Skills`。

**Tech Stack:** Windows PowerShell 5.1、Pester 3.4、TOML 白名单、现有 PowerShell 部署/验证引擎。

---

## 文件结构

- 修改：`scripts/Invoke-CodexToolManager.ps1`
  - 新增 Skill deploy adapter。
  - 新增 Skill load verifier。
  - 在 verification tool 转换时为 skill 附加 `LoadVerifier`。
  - 保持 plugin 既有真实路径，保持 mcp blocked。
- 修改：`tests/integration/EntryPoint.Tests.ps1`
  - 新增 Skill fixture。
  - 新增 Skill dry-run、deploy、verify 入口测试。
- 修改：`state/README.md`
  - 记录 Skill 真实部署与 load verification 的当前状态。
- 修改：`state/TODO.md`
  - 标记 Skill 最小闭环完成，保留 MCP 和 smoke 后续项。
- 修改：`state/LOG.md`
  - 记录 RED/GREEN 验证证据和剩余限制。

---

### Task 1: 入口 Skill 测试夹具

**Files:**
- Modify: `tests/integration/EntryPoint.Tests.ps1`

- [ ] **Step 1: 新增测试用 Skill source 生成函数**

在 `New-EntryPointPluginFixture` 后追加：

```powershell
function New-EntryPointSkillSource {
    param(
        [string]$Root,
        [string]$SkillId = 'entry-skill'
    )

    $source = Join-Path $Root "source-$SkillId"
    New-Item -ItemType Directory -Path $source -Force | Out-Null
    Write-EntryPointTextFile -Path (Join-Path $source 'SKILL.md') -Text @"
---
name: Entry Skill
description: Entry point integration test skill.
---

# Entry Skill

This is an integration-test-only skill.
"@
    New-Item -ItemType Directory -Path (Join-Path $source 'docs') -Force | Out-Null
    Write-EntryPointTextFile -Path (Join-Path $source 'docs\usage.md') -Text 'Usage.'
    return $source
}
```

- [ ] **Step 2: 新增 Skill fixture**

在 `New-EntryPointSkillSource` 后追加：

```powershell
function New-EntryPointSkillFixture {
    param(
        [string]$Root,
        [string]$ToolId = 'skill.entry-skill',
        [string]$SkillId = 'entry-skill'
    )

    $source = New-EntryPointSkillSource -Root $Root -SkillId $SkillId
    $workspace = Join-Path $Root 'workspace'
    New-Item -ItemType Directory -Path $workspace -Force | Out-Null
    $hashRun = & powershell -NoProfile -ExecutionPolicy Bypass -Command (
        ". '$projectRoot\scripts\lib\adapters\SkillAdapter.ps1'; " +
        "Get-SkillSourceHash -SourcePath '$($source.Replace(\"'\", \"''\"))'"
    )
    $hash = [string]($hashRun | Select-Object -Last 1)
    $configPath = Join-Path $Root 'config.toml'
    $whitelistPath = Join-Path $Root 'whitelist.toml'
    Write-EntryPointTextFile -Path $configPath -Text @"
schema_version = 1
name = "skill-entrypoint"
enabled_tools = ["$ToolId"]
"@
    Write-EntryPointTextFile -Path $whitelistPath -Text @"
schema_version = "1.0"

[[tools]]
id = "$ToolId"
name = "Entry Skill"
type = "skill"
source = "local"
version = "1.0.0"
sha256 = "$hash"
license = "MIT"
approval = "approved"
risk = "low"
install_target = "Skills/$SkillId"
credential_refs = []
conflicts = []
dependencies = []
permissions = []
external_changes = []
rollback_capability = "managed_files"
skill_id = "$SkillId"
source_path = "$($source.Replace('\', '\\'))"
managed_workspace_root = "$($workspace.Replace('\', '\\'))"
skill_manifest = "SKILL.md"
"@

    return [pscustomobject]@{
        Config = $configPath
        Whitelist = $whitelistPath
        Source = $source
        Workspace = $workspace
        Target = (Join-Path $workspace "Skills\$SkillId")
        SkillId = $SkillId
    }
}
```

- [ ] **Step 3: 新增 Skill dry-run 测试**

在插件 dry-run 测试后追加：

```powershell
It 'keeps approved skill deploy dry-run from copying files' {
    $fixture = New-EntryPointSkillFixture -Root (Join-Path $TestDrive 'skill-dryrun')

    $run = Invoke-EntryPointProcess -Arguments @(
        'deploy', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist,
        '-DryRun'
    )

    $run.ExitCode | Should Be 0
    $body = ConvertFrom-EntryPointJson -Run $run
    $body.Command | Should Be 'deploy'
    $body.Status | Should Be 'succeeded'
    @($body.Results)[0].Status | Should Be 'dry_run'
    (Test-Path -LiteralPath $fixture.Target) | Should Be $false
}
```

- [ ] **Step 4: 运行集成测试确认夹具不破坏现有行为**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-skill-fixture.log
```

Expected: PASS。

- [ ] **Step 5: 提交测试夹具**

```powershell
git add tests\integration\EntryPoint.Tests.ps1
git diff --cached --check
git commit -m "test[skill]: add entrypoint skill fixtures"
```

---

### Task 2: 接入 Skill 真实部署 adapter

**Files:**
- Modify: `scripts/Invoke-CodexToolManager.ps1`
- Modify: `tests/integration/EntryPoint.Tests.ps1`

- [ ] **Step 1: 新增 RED 测试：非 dry-run Skill 部署应复制文件**

在 Skill dry-run 测试后追加：

```powershell
It 'deploys an approved skill through the managed Skill adapter' {
    $fixture = New-EntryPointSkillFixture -Root (Join-Path $TestDrive 'skill-deploy')

    $run = Invoke-EntryPointProcess -Arguments @(
        'deploy', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
    )

    $run.ExitCode | Should Be 0
    $body = ConvertFrom-EntryPointJson -Run $run
    $body.Command | Should Be 'deploy'
    $body.Status | Should Be 'succeeded'
    @($body.Results)[0].Status | Should Be 'succeeded'
    (Test-Path -LiteralPath (Join-Path $fixture.Target 'SKILL.md') -PathType Leaf) |
        Should Be $true
    (Test-Path -LiteralPath (Join-Path $fixture.Target 'docs\usage.md') -PathType Leaf) |
        Should Be $true
}
```

- [ ] **Step 2: 运行测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-skill-deploy-red.log
```

Expected: FAIL。新增测试应看到 skill 仍 blocked，目标目录不存在。

- [ ] **Step 3: 新增 Skill adapter factory**

在 `New-ManagerPluginLoadVerifier` 后追加：

```powershell
function New-ManagerSkillAdapter {
    return {
        param([object]$Item)

        $plan = Get-SkillInstallPlan -Tool $Item
        Install-ManagedSkill -Plan $plan
    }.GetNewClosure()
}
```

- [ ] **Step 4: 修改 adapter map，只将 skill 切到真实 adapter**

将 `New-ManagerAdapterMap` 中的 skill 分支从 blocked 改为：

```powershell
$map['skill'] = New-ManagerSkillAdapter
```

保留：

```powershell
$map['plugin'] = New-ManagerPluginAdapter -Executor $Executor
$map['mcp'] = New-ManagerBlockedAdapter -Type 'mcp'
```

- [ ] **Step 5: 运行集成测试确认 GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-skill-deploy-green.log
```

Expected: PASS。Skill deploy 测试通过；plugin 测试仍通过；MCP 未接入。

- [ ] **Step 6: 运行单元测试**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\task-skill-deploy-unit.log
```

Expected: PASS。

- [ ] **Step 7: 提交 Skill 部署接入**

```powershell
git add scripts\Invoke-CodexToolManager.ps1 tests\integration\EntryPoint.Tests.ps1
git diff --cached --check
git commit -m "feat[skill]: enable entrypoint skill deployment"
```

---

### Task 3: 接入 Skill load verification

**Files:**
- Modify: `scripts/Invoke-CodexToolManager.ps1`
- Modify: `tests/integration/EntryPoint.Tests.ps1`

- [ ] **Step 1: 新增 RED 测试：Skill verify load 应验证安装目录**

在插件 verify 测试后追加：

```powershell
It 'verifies an approved managed skill through installed content hash' {
    $fixture = New-EntryPointSkillFixture -Root (Join-Path $TestDrive 'skill-verify')
    $deployRun = Invoke-EntryPointProcess -Arguments @(
        'deploy', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
    )
    $deployRun.ExitCode | Should Be 0

    $run = Invoke-EntryPointProcess -Arguments @(
        'verify', '-Config', $fixture.Config, '-Whitelist', $fixture.Whitelist
    )

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
}
```

- [ ] **Step 2: 运行测试确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-skill-verify-red.log
```

Expected: FAIL。当前入口没有给 skill 附加 load verifier，load 仍 blocked。

- [ ] **Step 3: 新增 Skill load verifier factory**

在 `New-ManagerSkillAdapter` 后追加：

```powershell
function New-ManagerSkillLoadVerifier {
    return {
        param([object]$Tool)

        $plan = Get-SkillInstallPlan -Tool $Tool
        Test-ManagedSkill -Plan $plan -Verifier {
            param($VerifierPlan)
            [pscustomobject]@{
                Status = 'load_verified'
                Message = "Managed Skill '$($VerifierPlan.SkillId)' content hash and manifest were verified."
                Checks = @('managed skill directory, SKILL.md, and source hash verified')
            }
        }
    }.GetNewClosure()
}
```

- [ ] **Step 4: 修改 verification tool 转换，为 skill 附加 LoadVerifier**

在 `ConvertTo-ManagerVerificationTool` 的 plugin LoadVerifier 分支后追加：

```powershell
    if ($Item.Type -eq 'skill') {
        $tool | Add-Member -NotePropertyName LoadVerifier `
            -NotePropertyValue (New-ManagerSkillLoadVerifier)
    }
```

确认 `ApprovedSnapshot = $Item.ApprovedSnapshot` 保留不变。

- [ ] **Step 5: 运行集成测试确认 GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Integration *> .\task-skill-verify-green.log
```

Expected: PASS。Skill load 为 `load_verified`，smoke 仍 blocked。

- [ ] **Step 6: 运行单元测试**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\task-skill-verify-unit.log
```

Expected: PASS。

- [ ] **Step 7: 提交 Skill load verification 接入**

```powershell
git add scripts\Invoke-CodexToolManager.ps1 tests\integration\EntryPoint.Tests.ps1
git diff --cached --check
git commit -m "feat[skill]: enable entrypoint skill load verification"
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
2026-06-26 已接入 Skill 真实部署与 load verification 最小闭环。当前真实路径覆盖 plugin 与 skill 类型；MCP 仍保持 blocked adapter，尚未接入真实安装、加载验证或 smoke 验证。Skill smoke verification 仍保守阻塞，不能宣称 Codex 运行时已实际加载并执行 Skill。
```

在 `state/TODO.md` 中调整后续项：

```markdown
- [x] 接入 Skill 真实部署适配器和 load verifier。
- [ ] 接入 MCP 真实部署适配器和 load/smoke verifier。
- [ ] 为 Skill 补充真正的运行时 smoke verifier；当前只证明受管安装与内容 hash 正确。
- [ ] 为插件补充真正的功能性 smoke verifier；当前只证明 load 可见，不伪造插件功能成功。
```

- [ ] **Step 2: 运行最终验证**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -All *> .\task-skill-real-all.log
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
Select-String -Path .\task-skill-real-all.log -Pattern 'Tests completed|Passed:|Failed:'
```

Expected: `Failed: 0`。

- [ ] **Step 4: 提交状态记录**

```powershell
git add state\README.md state\TODO.md state\LOG.md
git diff --cached --check
git commit -m "docs[state]: record skill deployment milestone"
```

- [ ] **Step 5: 推送分支**

```powershell
git status --short
git push
```

Expected: 工作树干净，`feat/phase1-foundation` 推送到 `origin/feat/phase1-foundation`。

---

## 自审

- 规格覆盖：计划覆盖 Skill deploy、Skill load verify、dry-run 保持不变、MCP blocked、状态记录和验证。
- 无未决后补项或含糊承诺。
- 类型一致：入口使用 `Item.ApprovedSnapshot` 给 `SkillAdapter`，不信任 top-level 可变字段覆盖 snapshot。
- 测试隔离：集成测试使用临时 Skill source 和临时 workspace，不修改真实 `E:\codex\Skills`。
- 风险边界：不读取认证文件正文，不扩大 `filesystem-context` 权限，不把 smoke 伪造成成功。
