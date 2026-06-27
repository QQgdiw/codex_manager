# MCP 真实部署与验证最小闭环设计

## 背景

项目已经完成 plugin 和 skill 两类工具的真实部署与 load verification 最小闭环。当前剩余的主要类型是 MCP。白名单中已有足够进入下一阶段的 approved MCP，不需要扩大审批范围：

- `mcp.modelcontextprotocol.filesystem`
- `mcp.modelcontextprotocol.sequential-thinking`

两个条目都已经包含 `mcp_transport`、`mcp_name`、`stdio.command`、`stdio.args` 和 `stdio.working_directory`。本地对应的 `dist/index.js` 启动文件存在。现有 `scripts/lib/adapters/McpAdapter.ps1` 已经提供 `Get-McpInstallPlan`、`Install-ManagedMcp`、`Uninstall-ManagedMcp` 和 `Test-ManagedMcp`，下一步重点是把入口命令和部署快照接到这些现有能力上。

## 目标

- 将 `mcp` 类型接入真实部署路径。
- 首批覆盖两个已批准 MCP：
  - `mcp.modelcontextprotocol.filesystem`
  - `mcp.modelcontextprotocol.sequential-thinking`
- 部署时复用现有 `Get-McpInstallPlan` 和 `Install-ManagedMcp`。
- 验证时复用现有 `Test-ManagedMcp`。
- 保持 `-DryRun` 与 `-WhatIf` 无副作用。
- 保持 plugin 和 skill 已有真实路径不回退。
- load verification 只证明 Codex MCP 配置中能查询到该 MCP。

## 非目标

- 不批准新的白名单工具。
- 不把 `mcp.modelcontextprotocol.memory` 纳入本阶段真实部署；它仍为 `proposed`。
- 不实现 MCP 功能性 smoke verifier。
- 不调用文件系统 MCP 或 sequential-thinking MCP 的具体工具方法。
- 不读取、打印或提交 `auth.json` 正文。
- 不修改真实 MCP 源码或重新构建 `MCP/servers`。
- 不改变 approved 工具的权限、根目录、数据访问边界。
- 不实现审批可视化。

## 推荐方案

入口 `deploy`：

- `plugin` 保持现有真实部署路径。
- `skill` 保持现有真实部署路径。
- `mcp` 从 blocked adapter 切换为真实 MCP adapter。
- `-DryRun` 和 `-WhatIf` 继续只生成 dry-run 结果，不运行 `codex mcp add`。
- 非 dry-run 时，`mcp` 调用：
  - `Get-McpInstallPlan`
  - `Install-ManagedMcp`

入口 `verify`：

- `mcp` 的 load verification 调用 `Test-ManagedMcp`。
- load verification 通过 `codex mcp get <name> --json` 确认该 MCP 可被 Codex CLI 查询。
- smoke verification 继续 blocked，因为本阶段没有真实调用 MCP 工具方法，也没有证明其业务能力可用。

## 部署快照

部署计划仍必须只信任 approved snapshot。入口层不得从 plan item 的 top-level 可变字段补齐 MCP 执行字段。

`New-DeploymentApprovedSnapshot` 需要在 `type = "mcp"` 时保留 MCP 专用字段：

- `mcp_transport`
- `mcp_name`
- `stdio`
- `http`

字段保留必须按 type 分支处理，避免 plugin、skill、mcp 的 adapter-specific 字段互相污染。已有 plugin/skill 字段隔离原则继续保留。

## 安全边界

- 所有 MCP 命令必须通过结构化 executor 执行，不拼接 shell 字符串。
- `stdio.env` 和 `stdio.env_names` 继续不支持，避免把环境密钥写进计划或命令摘要。
- HTTP MCP 只能接受不含 userinfo、query、fragment 的绝对 `http` 或 `https` URL。
- Bearer token 只能通过环境变量名引用，不保存或输出 token 值。
- 命令输出、错误信息和验证记录必须经过现有 MCP adapter 的脱敏逻辑。
- filesystem MCP 的批准只允许本系统把它登记到 Codex MCP 配置并验证可查询，不代表允许本阶段调用它读取任意文件。
- sequential-thinking MCP 的批准只允许登记和查询，不代表本阶段声明其推理工具调用成功。

## 数据与接口

白名单仍是唯一部署权威：

- `Resources/tool_whitelist.toml`
- 只有 `approval = "approved"` 的 MCP 可以进入部署计划。

入口命令不新增用户必须记忆的参数：

```powershell
powershell -NoProfile -File .\scripts\Invoke-CodexToolManager.ps1 deploy -Config <config> -Whitelist <whitelist>
powershell -NoProfile -File .\scripts\Invoke-CodexToolManager.ps1 deploy -Config <config> -Whitelist <whitelist> -DryRun
powershell -NoProfile -File .\scripts\Invoke-CodexToolManager.ps1 verify -Config <config> -Whitelist <whitelist>
```

## 错误处理

- 白名单或配置无效：返回业务失败，状态为 `blocked`。
- MCP approved snapshot 缺少必需字段：返回 `failed` 或 plan validation failure，不执行 `codex mcp add`。
- MCP stdio 启动文件不存在：返回 validation failure，不执行真实部署。
- Codex CLI 缺失或 `codex mcp add` 失败：返回业务失败，记录失败步骤 `mcp_add`。
- `codex mcp get <name> --json` 失败或 JSON 不可解析：load verification 返回 failed。
- load verification 通过但 smoke verifier 缺失：整体 verify 仍保持 blocked，明确说明 smoke 未验证。

## 测试策略

- 单元测试：
  - 验证 deployment approved snapshot 按 `mcp` 类型保留 MCP 专用字段。
  - 验证 MCP 专用字段不会污染 plugin 或 skill snapshot。
  - 复用现有 `McpAdapter.Tests.ps1` 覆盖 MCP 命令生成、脱敏、安装和查询验证。

- 集成测试：
  - 新增 MCP fixture，使用临时白名单和 fake `codex.cmd`。
  - RED：非 dry-run MCP deploy 在入口仍 blocked。
  - GREEN：接入真实 adapter 后，入口调用 fake `codex mcp add` 并返回 succeeded。
  - RED：MCP verify load 当前 blocked。
  - GREEN：接入 load verifier 后，入口调用 fake `codex mcp get <name> --json`，load 返回 `load_verified`，smoke 仍 blocked，整体 verify 仍 blocked。
  - 继续验证 plugin 和 skill 既有路径不回退。

## 验收标准

- 两个 approved MCP 可通过入口真实部署路径生成并执行 `codex mcp add` 命令。
- MCP load verification 可通过入口调用 `codex mcp get <name> --json` 并返回 `load_verified`。
- MCP smoke verification 仍 blocked，且不会被伪造成成功。
- `-DryRun` 和 `-WhatIf` 不执行真实 Codex 命令。
- plugin 和 skill 既有真实部署与 load verification 测试继续通过。
- 全量测试通过，`Resources/*.toml` 可解析，`git diff --check` 无错误。

## 后续工作

- 为 MCP 设计真正的 smoke verifier，分别定义 filesystem 与 sequential-thinking 的最小安全调用。
- 若后续批准 `mcp.modelcontextprotocol.memory`，需要先明确记忆保留周期、数据边界和清理策略。
- 需要时再设计审批可视化，数据源应优先使用 `Resources/approval_review.toml`，不解析 Markdown。
