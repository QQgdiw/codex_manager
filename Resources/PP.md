# Codex 工具资源管理与自动部署 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在当前 Windows 工作区中建立资源调研、白名单审批、场景配置生成、自动部署、分层验证、失败回滚和凭据保护的首期闭环。

**Architecture:** Codex 负责联网调研、语义筛选与 Markdown 内容维护；TOML 白名单和场景配置作为机器可读输入；PowerShell 5.1 负责流程编排，Python 3.11+ 仅使用标准库 `tomllib` 将 TOML 转换为 JSON；Plugin、MCP、Skill 通过独立适配器接入；所有外部变更先生成计划和快照，再执行、验证和记录。

**Tech Stack:** Windows PowerShell 5.1、Python 3.11+ 标准库、Pester 3.4 兼容测试、Codex CLI 0.139+、Git、Markdown、TOML、Windows DPAPI。

---

## 1. 计划依据

- 产品需求文档：`Resources/PRD.md`
- 初始需求：`需求文档.txt`
- 当前配置参考：`Templates/config_toml.txt`
- 当前环境：Windows 11、PowerShell 5.1、Codex CLI 0.139.0
- 当前仓库：`origin/main`

## 2. 已确认的能力与权限

### 2.1 当前能力

当前会话已经具备完成首期开发所需的核心能力：

- 工作区文件读取、编辑和结构化补丁。
- PowerShell 命令执行。
- Git 本地版本管理和远程仓库连通性检查。
- 网页检索、来源核验和浏览器访问。
- Markdown、Word、Excel、PDF 等文档处理能力。
- Superpowers 规划、TDD、调试和验证工作流。

当前不需要额外安装 Plugin、MCP 或 Skill。

### 2.2 已发现的环境事实

- `codex plugin list` 当前返回无 marketplace plugin。
- `codex mcp list` 当前返回无已配置 MCP。
- 根目录 `config.toml` 不是当前 Codex CLI 自动识别的项目配置位置，不能视为已经生效。
- `MCP/servers` 和 `Skills/AgentSkillsforContextEngineering` 已有源码，但它们是嵌套 Git 仓库，且未在当前 Codex 配置中启用。
- Puppeteer MCP 的预期 `dist/index.js` 不存在，不能标记为可用。
- Codex CLI 当前未登录，`codex doctor` 同时报告部分服务端点不可达。
- `gh` CLI 未安装，但 Git 和网页/GitHub API 能力足以完成首期，不将其列为依赖。

### 2.3 后续授权门槛

以下操作必须在执行时单独申请或由用户介入：

1. Codex 交互登录：由用户执行 `codex login`，不得由自动化脚本代填凭据。
2. 用户级 Plugin 安装：写入用户 Codex 配置和缓存时申请工作区外写权限。
3. 联网下载：Git、npm、uv、pip 或其他安装器访问外部网络时申请联网权限。
4. 系统级依赖：需要管理员权限、驱动、系统服务或全局环境变量时先展示变更清单并申请。
5. Git 推送：本地提交完成后，只有在用户要求同步远程时执行 `git push`。

## 3. 文件结构

计划新增或维护以下文件：

```text
Resources/
  PRD.md
  PP.md
  tool_whitelist.toml
  plugins_market.md
  github_market.md
  MCP_market.md
  tool_market.md
  event_market.md
  config_note.toml
  config_basic.toml
  config_mcu.toml
  config_zynq.toml
  config_hardware.toml
  config_file.toml
Notes/
  verify_record.md
scripts/
  Invoke-CodexToolManager.ps1
  lib/
    Common.ps1
    Read-Toml.ps1
    CredentialStore.ps1
    ChangeJournal.ps1
    DeploymentEngine.ps1
    VerificationEngine.ps1
    adapters/
      PluginAdapter.ps1
      McpAdapter.ps1
      SkillAdapter.ps1
  python/
    toml_to_json.py
tests/
  Run-Tests.ps1
  fixtures/
    whitelist.valid.toml
    whitelist.invalid.toml
    config.valid.toml
  unit/
    Toml.Tests.ps1
    Whitelist.Tests.ps1
    CredentialStore.Tests.ps1
    ChangeJournal.Tests.ps1
    DeploymentEngine.Tests.ps1
    VerificationEngine.Tests.ps1
    PluginAdapter.Tests.ps1
    McpAdapter.Tests.ps1
    SkillAdapter.Tests.ps1
  integration/
    DryRun.Tests.ps1
    Rollback.Tests.ps1
state/
  README.md
  TODO.md
  LOG.md
.gitignore
```

各文件职责：

- `Invoke-CodexToolManager.ps1`：唯一用户入口，只负责参数解析和调用流程。
- `Common.ps1`：路径、日志脱敏、进程执行和统一结果对象。
- `Read-Toml.ps1`：调用 Python 标准库解析 TOML，不自行实现不完整 TOML 语法。
- `CredentialStore.ps1`：DPAPI 加密、解密、枚举和删除凭据。
- `ChangeJournal.ps1`：安装前快照、变更记录和反向回滚。
- `DeploymentEngine.ps1`：预检查、依赖排序、适配器调度和单项隔离。
- `VerificationEngine.ps1`：静态、加载/启动、最小功能调用三级验证。
- `adapters/*`：只封装具体工具类型的安装、卸载和验证命令。
- `tests/fixtures/*`：固定测试输入，不包含真实凭据或外部下载。

## 4. 执行阶段

项目分为六个里程碑：

1. **M0：仓库与测试基线**
2. **M1：Schema、凭据和变更日志**
3. **M2：部署、验证和回滚核心**
4. **M3：Plugin、MCP、Skill 适配**
5. **M4：市场文档与场景配置**
6. **M5：真实环境验证与首期收尾**

每个里程碑必须独立通过测试和文档检查后再进入下一阶段。

## 5. 实施任务

### Task 1: 建立仓库安全基线

**Files:**
- Create: `.gitignore`
- Create: `tests/Run-Tests.ps1`
- Create: `tests/unit/Baseline.Tests.ps1`
- Modify: `state/README.md`
- Modify: `state/TODO.md`
- Modify: `state/LOG.md`

- [ ] **Step 1: 编写忽略规则**

`.gitignore` 至少包含：

```gitignore
.secrets/
*.credential
*.dpapi
*.log
coverage/
TestResults/
__pycache__/
*.pyc
MCP/servers/node_modules/
```

- [ ] **Step 2: 建立 Pester 3.4 兼容测试入口**

`tests/Run-Tests.ps1` 接受 `-Unit`、`-Integration` 和 `-All`，默认执行全部测试；测试失败时返回非零退出码。

`tests/unit/Baseline.Tests.ps1` 至少包含：

```powershell
Describe 'Repository baseline' {
    It 'runs under Windows PowerShell 5.1 or later' {
        $PSVersionTable.PSVersion.Major | Should BeGreaterThan 4
    }
}
```

- [ ] **Step 3: 验证测试入口在无测试或示例测试下可预测退出**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -All
```

Expected: 至少执行 1 个测试，失败数为 0，进程退出码为 0。

- [ ] **Step 4: 检查敏感文件不会进入版本库**

Run:

```powershell
git check-ignore .secrets\credentials.dpapi
```

Expected: 输出 `.secrets/credentials.dpapi`。

- [ ] **Step 5: 提交**

```powershell
git add .gitignore tests\Run-Tests.ps1 tests\unit\Baseline.Tests.ps1 state
git commit -m "chore[repo]: establish test and security baseline"
```

### Task 2: 定义白名单与场景配置 Schema

**Files:**
- Create: `Resources/tool_whitelist.toml`
- Create: `tests/fixtures/whitelist.valid.toml`
- Create: `tests/fixtures/whitelist.invalid.toml`
- Create: `tests/fixtures/config.valid.toml`
- Create: `scripts/python/toml_to_json.py`
- Create: `scripts/lib/Read-Toml.ps1`
- Create: `tests/unit/Toml.Tests.ps1`
- Create: `tests/unit/Whitelist.Tests.ps1`

- [ ] **Step 1: 编写 TOML 解析失败测试**

覆盖有效 TOML、语法错误、缺少 Python 3.11+、解析输出不是对象四种情况。

- [ ] **Step 2: 运行测试确认失败**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit
```

Expected: `Toml.Tests.ps1` 因 `Read-ProjectToml` 尚不存在而失败。

- [ ] **Step 3: 实现标准库 TOML 转 JSON**

Python 接口固定为：

```text
python scripts/python/toml_to_json.py <input.toml>
stdout: UTF-8 JSON
stderr: 可读错误摘要
exit 0: 成功
exit 2: 输入或 TOML 语法错误
exit 3: 运行时错误
```

PowerShell 接口固定为：

```powershell
Read-ProjectToml -Path <string> -> PSCustomObject
```

- [ ] **Step 4: 定义白名单必填字段**

每个 `[[tools]]` 条目至少包含：

```toml
id = "type.unique-name"
name = "Display Name"
type = "plugin"
source = "https://github.com/owner/repo"
version = "commit-or-tag"
sha256 = "64-char-lowercase-hex"
license = "SPDX-or-UNKNOWN"
approval = "approved"
risk = "low"
install_target = "managed-path"
credential_refs = []
conflicts = []
```

`type` 仅允许 `plugin`、`mcp`、`skill`；`approval` 仅允许 `proposed`、`approved`、`rejected`、`suspended`。

- [ ] **Step 5: 实现 Schema 校验**

接口固定为：

```powershell
Test-WhitelistDocument -Document <object> -> ValidationResult
```

`ValidationResult` 包含 `IsValid`、`Errors`、`Warnings`，不得通过抛出异常表示普通字段错误。

- [ ] **Step 6: 运行单元测试**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit
```

Expected: TOML 和白名单测试全部通过。

- [ ] **Step 7: 提交**

```powershell
git add Resources\tool_whitelist.toml scripts tests
git commit -m "feat[manifest]: add whitelist schema and TOML loader"
```

### Task 3: 实现统一结果、脱敏和进程执行

**Files:**
- Create: `scripts/lib/Common.ps1`
- Create: `tests/unit/Common.Tests.ps1`

- [ ] **Step 1: 编写失败测试**

覆盖命令成功、非零退出、超时、标准输出截断、敏感值脱敏和日志不超过预设行数。

- [ ] **Step 2: 运行测试确认失败**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit
```

Expected: 因 `Invoke-ManagedProcess` 和 `Protect-LogText` 不存在而失败。

- [ ] **Step 3: 实现公共接口**

```powershell
New-OperationResult -Status <string> -Message <string> -Data <object>
Protect-LogText -Text <string> -SensitiveValues <string[]>
Invoke-ManagedProcess -FilePath <string> -Arguments <string[]> -TimeoutSeconds <int>
```

进程结果必须包含退出码、超时状态、受限长度的 stdout/stderr 和执行时长。

- [ ] **Step 4: 运行测试并提交**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit
```

Expected: `Common.Tests.ps1` 全部通过。

```powershell
git add scripts\lib\Common.ps1 tests\unit\Common.Tests.ps1
git commit -m "feat[core]: add safe process and log utilities"
```

### Task 4: 实现 DPAPI 凭据管理

**Files:**
- Create: `scripts/lib/CredentialStore.ps1`
- Create: `tests/unit/CredentialStore.Tests.ps1`

- [ ] **Step 1: 编写失败测试**

覆盖当前用户加密解密、错误用户或损坏数据失败、凭据更新、删除、日志脱敏和存储目录权限检查。

- [ ] **Step 2: 运行测试确认失败**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit
```

Expected: 因凭据函数尚不存在而失败。

- [ ] **Step 3: 实现凭据接口**

```powershell
Set-ManagedCredential -Name <string> -Secret <SecureString>
Get-ManagedCredential -Name <string> -> SecureString
Remove-ManagedCredential -Name <string>
Get-ManagedCredentialMetadata -> object[]
```

默认存储位置为仓库根目录 `.secrets/credentials.dpapi`，文件只保存名称、密文、创建时间和更新时间。

- [ ] **Step 4: 验证明文未落盘**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit
```

Expected: 所有凭据测试通过，测试密钥文本不出现在密钥文件和测试输出中。

- [ ] **Step 5: 提交**

```powershell
git add scripts\lib\CredentialStore.ps1 tests\unit\CredentialStore.Tests.ps1
git commit -m "feat[security]: add DPAPI credential store"
```

### Task 5: 实现变更日志与回滚

**Files:**
- Create: `scripts/lib/ChangeJournal.ps1`
- Create: `tests/unit/ChangeJournal.Tests.ps1`
- Create: `tests/integration/Rollback.Tests.ps1`

- [ ] **Step 1: 编写失败测试**

覆盖新建文件、修改文件、删除文件、目录创建、配置备份、进程启动和不受管系统依赖残留记录。

- [ ] **Step 2: 运行测试确认失败**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -All
```

Expected: 回滚测试因变更日志接口不存在而失败。

- [ ] **Step 3: 实现变更日志接口**

```powershell
New-ChangeJournal -OperationId <string>
Add-FileChange -Journal <object> -Path <string> -Kind <string>
Add-ExternalChange -Journal <object> -Description <string> -RollbackCommand <string>
Invoke-JournalRollback -Journal <object> -> RollbackResult
```

回滚必须拒绝处理工作区、用户 Codex 目录和显式批准目标之外的路径。

- [ ] **Step 4: 运行测试并提交**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -All
```

Expected: 回滚后测试目录恢复到操作前哈希；无法回滚项进入 `Residuals`。

```powershell
git add scripts\lib\ChangeJournal.ps1 tests
git commit -m "feat[rollback]: add managed change journal"
```

### Task 6: 实现部署编排核心

**Files:**
- Create: `scripts/lib/DeploymentEngine.ps1`
- Create: `tests/unit/DeploymentEngine.Tests.ps1`
- Create: `tests/integration/DryRun.Tests.ps1`

- [ ] **Step 1: 编写失败测试**

覆盖未批准工具、哈希不匹配、冲突工具、缺少凭据、依赖排序、单项失败隔离和 `-WhatIf` 无副作用。

- [ ] **Step 2: 运行测试确认失败**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -All
```

Expected: 部署编排测试失败，且测试夹具没有被修改。

- [ ] **Step 3: 实现部署计划接口**

```powershell
New-DeploymentPlan -Config <object> -Whitelist <object> -> DeploymentPlan
Test-DeploymentPlan -Plan <object> -> ValidationResult
Invoke-DeploymentPlan -Plan <object> -WhatIf:<bool> -> OperationResult[]
```

`DeploymentPlan` 必须显式列出安装顺序、目标路径、权限、凭据引用、冲突、预期外部变更和回滚能力。

- [ ] **Step 4: 验证 Dry Run**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -All
```

Expected: `DryRun.Tests.ps1` 确认文件哈希、Codex 配置和已安装工具均未变化。

- [ ] **Step 5: 提交**

```powershell
git add scripts\lib\DeploymentEngine.ps1 tests
git commit -m "feat[deploy]: add whitelist-driven deployment engine"
```

### Task 7: 实现分层验证与记录

**Files:**
- Create: `scripts/lib/VerificationEngine.ps1`
- Create: `tests/unit/VerificationEngine.Tests.ps1`
- Create: `Notes/verify_record.md`

- [ ] **Step 1: 编写失败测试**

覆盖静态成功、启动失败、最小调用失败、缺少凭据、仅静态验证和记录脱敏。

- [ ] **Step 2: 运行测试确认失败**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit
```

Expected: 验证测试因接口不存在而失败。

- [ ] **Step 3: 实现验证接口**

```powershell
Invoke-StaticVerification -Tool <object> -> VerificationResult
Invoke-LoadVerification -Tool <object> -> VerificationResult
Invoke-SmokeVerification -Tool <object> -> VerificationResult
Write-VerificationRecord -Result <object> -Path <string>
```

状态只允许：

```text
not_verified
static_verified
load_verified
smoke_verified
partial
failed
blocked
```

- [ ] **Step 4: 验证记录格式**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit
```

Expected: 记录包含工具、版本、时间、层级、结果、回滚和残留，且不包含测试密钥。

- [ ] **Step 5: 提交**

```powershell
git add scripts\lib\VerificationEngine.ps1 tests\unit\VerificationEngine.Tests.ps1 Notes\verify_record.md
git commit -m "feat[verify]: add layered verification records"
```

### Task 8: 实现 Plugin 适配器

**Files:**
- Create: `scripts/lib/adapters/PluginAdapter.ps1`
- Create: `tests/unit/PluginAdapter.Tests.ps1`

- [ ] **Step 1: 编写命令生成测试**

测试必须确认适配器生成固定 `--ref` 的 marketplace 添加命令和精确 Plugin 选择器，不执行真实网络安装。

- [ ] **Step 2: 实现适配器接口**

```powershell
Get-PluginInstallPlan -Tool <object> -> AdapterPlan
Install-ManagedPlugin -Plan <object> -Journal <object> -> OperationResult
Uninstall-ManagedPlugin -Plan <object> -> OperationResult
Test-ManagedPlugin -Plan <object> -> VerificationResult
```

安装命令基于当前 CLI：

```text
codex plugin marketplace add <source> --ref <version> --json
codex plugin add <plugin>@<marketplace> --json
```

- [ ] **Step 3: 运行模拟测试并提交**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit
```

Expected: 不访问网络，不修改用户目录，命令参数与白名单完全一致。

```powershell
git add scripts\lib\adapters\PluginAdapter.ps1 tests\unit\PluginAdapter.Tests.ps1
git commit -m "feat[plugin]: add Codex plugin adapter"
```

### Task 9: 实现 MCP 适配器

**Files:**
- Create: `scripts/lib/adapters/McpAdapter.ps1`
- Create: `tests/unit/McpAdapter.Tests.ps1`

- [ ] **Step 1: 编写 stdio 与 HTTP 测试**

覆盖本地命令 MCP、远程 URL MCP、Bearer Token 环境变量、缺少启动文件和启动超时。

- [ ] **Step 2: 实现适配器接口**

```powershell
Get-McpInstallPlan -Tool <object> -> AdapterPlan
Install-ManagedMcp -Plan <object> -Journal <object> -> OperationResult
Uninstall-ManagedMcp -Plan <object> -> OperationResult
Test-ManagedMcp -Plan <object> -> VerificationResult
```

配置命令基于当前 CLI：

```text
codex mcp add <name> -- <command...>
codex mcp add <name> --url <url> --bearer-token-env-var <env>
codex mcp get <name> --json
```

- [ ] **Step 3: 运行模拟测试并提交**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit
```

Expected: 缺少 `dist/index.js` 的 MCP 在预检查阶段失败，不执行注册。

```powershell
git add scripts\lib\adapters\McpAdapter.ps1 tests\unit\McpAdapter.Tests.ps1
git commit -m "feat[mcp]: add Codex MCP adapter"
```

### Task 10: 实现 Skill 适配器

**Files:**
- Create: `scripts/lib/adapters/SkillAdapter.ps1`
- Create: `tests/unit/SkillAdapter.Tests.ps1`

- [ ] **Step 1: 编写 Skill 结构测试**

覆盖 `SKILL.md` 存在、YAML 前置元数据、相对引用、脚本路径、版本哈希和目标目录边界。

- [ ] **Step 2: 实现适配器接口**

```powershell
Get-SkillInstallPlan -Tool <object> -> AdapterPlan
Install-ManagedSkill -Plan <object> -Journal <object> -> OperationResult
Uninstall-ManagedSkill -Plan <object> -> OperationResult
Test-ManagedSkill -Plan <object> -> VerificationResult
```

Skill 源码安装在工作区 `Skills/<id>`。激活位置必须通过当前 Codex 版本的官方配置或 Plugin 清单验证后写入，不允许仅因目录存在就标记为加载成功。

- [ ] **Step 3: 运行模拟测试并提交**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit
```

Expected: 结构不完整的 Skill 被静态验证拒绝；有效 Skill 只完成受管目录安装。

```powershell
git add scripts\lib\adapters\SkillAdapter.ps1 tests\unit\SkillAdapter.Tests.ps1
git commit -m "feat[skill]: add managed Skill adapter"
```

### Task 11: 实现统一命令入口

**Files:**
- Create: `scripts/Invoke-CodexToolManager.ps1`
- Create: `tests/integration/EntryPoint.Tests.ps1`

- [ ] **Step 1: 编写参数与退出码测试**

入口命令支持：

```text
plan
deploy
verify
rollback
credential set|get|remove|list
status
```

- [ ] **Step 2: 实现入口**

示例：

```powershell
.\scripts\Invoke-CodexToolManager.ps1 plan `
  -Config .\Resources\config_basic.toml `
  -Whitelist .\Resources\tool_whitelist.toml
```

默认行为必须是只生成计划；只有显式 `deploy` 才能修改环境。

- [ ] **Step 3: 运行集成测试并提交**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -All
```

Expected: 未批准工具返回业务失败状态；致命配置错误返回非零退出码；Dry Run 无副作用。

```powershell
git add scripts\Invoke-CodexToolManager.ps1 tests\integration\EntryPoint.Tests.ps1
git commit -m "feat[cli]: add PowerShell management entry point"
```

### Task 12: 填充 Plugins 市场

**Files:**
- Create: `Resources/plugins_market.md`
- Modify: `Resources/tool_whitelist.toml`

- [ ] **Step 1: 固定 OpenAI Plugins 仓库 Commit**
- [ ] **Step 2: 枚举插件目录并收集官方名称、描述、功能和部署条件**
- [ ] **Step 3: 按“宽进严标”排除明显无关项**
- [ ] **Step 4: 记录来源、采集时间、Commit、相关度、成熟度和风险**
- [ ] **Step 5: 对建议白名单项生成 `proposed` 条目，不自动批准**
- [ ] **Step 6: 检查每个插件条目都有官方来源和 AI 调用参考**
- [ ] **Step 7: 提交**

该任务只在用户发出更新指令时执行，后续更新必须增量合并并保留历史状态，不创建定时任务。

```powershell
git add Resources\plugins_market.md Resources\tool_whitelist.toml
git commit -m "docs[market]: add initial OpenAI plugin catalog"
```

### Task 13: 回溯并填充 GitHub 周榜

**Files:**
- Create: `Resources/github_market.md`

- [ ] **Step 1: 建立 2026 年第 1 周至执行当周的周次清单**
- [ ] **Step 2: 优先采集可验证历史榜单和仓库记录**
- [ ] **Step 3: 对缺失周次执行近似回溯**
- [ ] **Step 4: 仅保留当前可确认达到 1,000 Star 的项目**
- [ ] **Step 5: 跨周去重并保留首次或最有代表性的入榜周次**
- [ ] **Step 6: 标记采集时间、当前 Star、历史数据性质和可信度**
- [ ] **Step 7: 检查不存在把当前 Star 冒充历史精确 Star 的表述**
- [ ] **Step 8: 提交**

该任务的首次执行负责回溯 2026 年历史；后续只按用户指令增量更新新增周次和已有条目状态。

```powershell
git add Resources\github_market.md
git commit -m "docs[market]: add 2026 GitHub trend history"
```

### Task 14: 派生 MCP、Skill 与其他工具市场

**Files:**
- Create: `Resources/MCP_market.md`
- Create: `Resources/tool_market.md`
- Modify: `Resources/tool_whitelist.toml`

- [ ] **Step 1: 从 `github_market.md` 筛选 MCP 和 Skill 项目**
- [ ] **Step 2: 验证是否可在不修改上游源码的情况下用于 Codex**
- [ ] **Step 3: 保留原周次、来源和可信度**
- [ ] **Step 4: 筛选其他 AI 工作流辅助工具**
- [ ] **Step 5: 排除模型训练和基础模型开发项目**
- [ ] **Step 6: 为建议项生成 `proposed` 白名单条目**
- [ ] **Step 7: 提交**

派生文档随 `github_market.md` 的按需更新同步增量维护，不独立定时抓取。

```powershell
git add Resources\MCP_market.md Resources\tool_market.md Resources\tool_whitelist.toml
git commit -m "docs[market]: derive Codex extension catalogs"
```

### Task 15: 填充 AI 行业事件市场

**Files:**
- Create: `Resources/event_market.md`

- [ ] **Step 1: 收集 2026 年以来官方或高可信重大事件**
- [ ] **Step 2: 按组织和技术方向归组，组内时间倒序**
- [ ] **Step 3: 分离客观事实、技术剖析、工作流影响和局限**
- [ ] **Step 4: 核查日期、组织、产品名称和性能数字来源**
- [ ] **Step 5: 删除与研发者工作明显无关的事件**
- [ ] **Step 6: 提交**

事件市场只按用户请求更新，已有事件原则上保留；事实修正需要记录来源变化。

```powershell
git add Resources\event_market.md
git commit -m "docs[event]: add initial AI engineering timeline"
```

### Task 16: 生成六类场景配置

**Files:**
- Create: `Resources/config_note.toml`
- Create: `Resources/config_basic.toml`
- Create: `Resources/config_mcu.toml`
- Create: `Resources/config_zynq.toml`
- Create: `Resources/config_hardware.toml`
- Create: `Resources/config_file.toml`
- Create: `tests/unit/ScenarioConfig.Tests.ps1`

- [ ] **Step 1: 编写配置引用测试**

测试要求每个启用工具都存在于白名单、状态为 `approved`、无未解决冲突，并保留浏览器检索能力。

- [ ] **Step 2: 运行测试确认空配置不满足场景要求**
- [ ] **Step 3: 生成全部注释的 `config_note.toml`**
- [ ] **Step 4: 按最小充分集生成五类启用配置**
- [ ] **Step 5: 检查同类能力只启用一个默认实现**
- [ ] **Step 6: 运行测试**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit
```

Expected: 六个配置全部通过 Schema、白名单引用和冲突检查。

- [ ] **Step 7: 提交**

```powershell
git add Resources\config_*.toml tests\unit\ScenarioConfig.Tests.ps1
git commit -m "feat[config]: add scenario-specific Codex profiles"
```

### Task 17: 用户审批首批白名单

**Files:**
- Modify: `Resources/tool_whitelist.toml`
- Modify: `state/LOG.md`

- [ ] **Step 1: 输出候选工具的来源、版本、许可证、权限和风险摘要**
- [ ] **Step 2: 等待用户逐项批准或拒绝**
- [ ] **Step 3: 只更新明确回复的审批状态**
- [ ] **Step 4: 为批准项记录批准时间和固定哈希**
- [ ] **Step 5: 提交**

```powershell
git add Resources\tool_whitelist.toml state\LOG.md
git commit -m "chore[whitelist]: record approved tool baseline"
```

### Task 18: 真实部署与分层验证

**Files:**
- Modify: `Notes/verify_record.md`
- Modify: `state/LOG.md`
- Modify: `state/TODO.md`

- [ ] **Step 1: 用户完成 `codex login`**
- [ ] **Step 2: 执行 `codex doctor` 并保存不含敏感信息的摘要**
- [ ] **Step 3: 对首个批准工具执行 Dry Run**
- [ ] **Step 4: 展示工作区外写入、联网和系统依赖请求**
- [ ] **Step 5: 获得授权后执行单项部署**
- [ ] **Step 6: 依次执行静态、加载/启动和最小调用验证**
- [ ] **Step 7: 人工核查 `verify_record.md` 不含密钥**
- [ ] **Step 8: 对每种工具类型至少验证一个批准项目**
- [ ] **Step 9: 提交验证记录**

```powershell
git add Notes\verify_record.md state
git commit -m "test[deployment]: record initial tool verification"
```

### Task 19: 首期端到端验收

**Files:**
- Modify: `state/README.md`
- Modify: `state/TODO.md`
- Modify: `state/LOG.md`

- [ ] **Step 1: 运行完整自动化测试**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -All
```

Expected: 失败数为 0。

- [ ] **Step 2: 验证所有 TOML 可解析**

Run:

```powershell
Get-ChildItem .\Resources\*.toml | ForEach-Object {
    python .\scripts\python\toml_to_json.py $_.FullName | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Invalid TOML: $($_.FullName)" }
}
```

Expected: 无异常。

- [ ] **Step 3: 扫描敏感内容和占位符**

Run:

```powershell
rg -n "TBD|TODO|PLACEHOLDER|api[_-]?key\s*=|token\s*=|password\s*=" Resources Notes scripts state
```

Expected: 不存在未解释占位符和明文凭据；状态文件中的任务词语不视为占位符。

- [ ] **Step 4: 核对 PRD 覆盖**

逐项确认五类市场、六类配置、白名单、部署、三级验证、回滚、DPAPI、记录和后续路线均有对应实现或明确非目标。

- [ ] **Step 5: 检查 Git 状态**

Run:

```powershell
git status --short
git log --oneline -10
```

Expected: 只有已明确说明的本地数据或用户文件未提交；实现文件均已提交。

- [ ] **Step 6: 更新状态并提交**

```powershell
git add state
git commit -m "docs[state]: close first delivery milestone"
```

## 6. 测试策略

### 6.1 单元测试

- TOML 解析和 Schema 校验。
- 日志脱敏和进程执行。
- DPAPI 凭据生命周期。
- 变更日志和路径边界。
- 部署计划、依赖排序和冲突检测。
- 验证状态转换。
- 三类适配器的命令生成和预检查。

### 6.2 集成测试

- Dry Run 不产生副作用。
- 受管文件修改后能够恢复原始哈希。
- 单项失败不阻断无依赖项目。
- 验证记录完整且不泄露凭据。
- 场景配置只引用已批准项目。

### 6.3 真实环境测试

- 每种工具类型至少选择一个低风险批准项目。
- 每次只安装一个新工具，验证通过后再继续。
- 系统级安装前必须单独授权。
- 真实网络失败、登录失败和凭据缺失必须记录为失败或阻塞，不允许降级为成功。

## 7. 提交与分支策略

- 当前工作直接在 `main` 上进行文档基线提交。
- 进入实现阶段前，为每个里程碑创建独立功能分支。
- 提交信息使用 `<type>[scope]: <description>`。
- 有对应 GitHub Issue 时，在提交 Footer 使用 `Fixes #N` 或 `Resolves #N`。
- 没有 Issue 编号时不得虚构关联。
- 不将 DPAPI 密钥、Token、下载缓存、测试输出和第三方 `node_modules` 提交。
- `MCP/servers` 与 `Skills/AgentSkillsforContextEngineering` 的版本纳管方式必须在首次改动前确定为 Git submodule 或固定版本归档，不能把嵌套 `.git` 状态含糊提交。

## 8. 风险与应对

| 风险 | 影响 | 应对 |
|---|---|---|
| Codex CLI 未登录或服务端点不可达 | 无法完成真实加载验证 | 实现阶段先完成离线测试；真实验证前由用户登录并检查网络 |
| Codex 配置格式随版本变化 | 配置生成失效 | 用当前 CLI 帮助和实际命令验证；固定最低版本并在执行时记录版本 |
| PowerShell 5.1 无 TOML 解析器 | 清单无法可靠读取 | 使用当前 Python 3.14 的标准库 `tomllib`，不引入第三方解析依赖 |
| GitHub 历史周榜不完整 | 历史数据无法精确还原 | 可验证来源优先，近似数据明确标注推导方法和可信度 |
| 第三方安装器修改系统 | 无法完全回滚 | 强回滚受管文件，系统级依赖尽力回滚并记录残留 |
| 嵌套 Git 仓库直接纳管 | 版本状态混乱 | 在使用前明确 submodule 或固定归档策略 |
| Plugin、MCP、Skill 能力重叠 | 指令冲突和资源浪费 | 原生优先、最小充分集、白名单冲突字段和配置测试 |
| 凭据泄露 | 安全事故 | DPAPI、`.gitignore`、日志脱敏和敏感内容扫描 |

## 9. 完成定义

首期只有同时满足以下条件才可标记完成：

1. 五类市场文档已首次填充并包含可追溯来源。
2. 六类场景配置通过 Schema、白名单引用和冲突检查。
3. 白名单条目具有固定版本、哈希、风险和审批状态。
4. PowerShell 入口能够完成计划、部署、验证、回滚、凭据和状态操作。
5. 自动测试全部通过。
6. Plugin、MCP、Skill 每类至少一个批准项目完成真实分层验证，或明确记录外部阻塞且不宣称完成。
7. `Notes/verify_record.md` 无敏感信息。
8. `state` 文件反映真实进度、风险和残留。
9. Git 提交结构清晰，工作区没有未说明的实现改动。
