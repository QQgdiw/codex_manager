# 插件真实部署与验证最小闭环设计

## 背景

首期项目已经完成资源市场、白名单、审批辅助表、场景配置、部署 dry-run、静态验证、回滚记录和状态文件。当前剩余限制是：`scripts/Invoke-CodexToolManager.ps1` 的部署入口仍使用 planning-only blocked adapter，真实安装路径尚未接入；`verify` 命令能完成静态验证，但 load/smoke 阶段在入口层仍保守阻塞。

用户已经选择下一阶段首批目标为方案 A：只处理 `browser + superpowers` 两个已批准插件。Skill 和 MCP 的真实部署边界更复杂，本阶段不触碰它们。

## 目标

- 将插件类型的真实部署路径接入入口命令。
- 首批只支持 `plugin.openai-bundled.browser` 和 `plugin.openai-curated.superpowers` 两个已批准插件。
- 保持 `-DryRun` 和 `-WhatIf` 行为不变，仍只生成 dry-run 结果，不执行真实命令。
- 为插件接入 load verification，使用 `codex plugin list --json` 或可解析输出确认插件可见。
- smoke verification 不伪造功能成功；如果只能证明插件已加载，应明确返回保守状态或复用 load 结果说明“未声明功能性 smoke 能力”。
- 保留 Skill 和 MCP 的 blocked adapter，避免本阶段误装文件系统、MCP 或用户目录配置。

## 非目标

- 不实现 Skill 的真实安装、加载验证或 smoke 验证。
- 不实现 MCP 的真实配置、加载验证或 smoke 验证。
- 不读取、打印或提交 `auth.json` 正文。
- 不把插件出现在列表中等同于所有插件功能都可用。
- 不自动批准新的白名单条目。
- 不实现审批可视化界面。

## 推荐方案

本阶段只把 `plugin` 类型从 blocked adapter 切换为真实插件适配器。`mcp` 和 `skill` 继续使用 blocked adapter。

入口 `deploy` 的行为：

- 当传入 `-DryRun` 或 `-WhatIf` 时，继续沿用部署引擎的 dry-run 分支，不运行 `codex plugin marketplace add` 或 `codex plugin add`。
- 当不是 dry-run 时，`plugin` 类型调用 `Get-PluginInstallPlan` 和 `Install-ManagedPlugin`。
- 插件安装命令由已存在的 `scripts/lib/adapters/PluginAdapter.ps1` 生成，不在入口层拼接 shell 字符串。
- 命令执行必须通过结构化 executor，记录退出码、stdout/stderr 摘要和失败步骤，并执行脱敏。
- `skill` 和 `mcp` 类型仍返回 blocked，消息说明真实部署暂未接入。

入口 `verify` 的行为：

- 对每个 plan item 继续运行 static/load/smoke 三层验证。
- plugin 的 load 验证调用 `Test-ManagedPlugin`，默认通过 `codex plugin list --json` 检查插件是否可见。
- plugin 的 smoke 验证不发明交互式功能调用；如果没有专门 smoke verifier，则应保守说明没有功能性 smoke 能力被断言。
- skill 和 mcp 的 load/smoke 仍保持 blocked。

## 安全边界

- 不读取 `auth.json` 文件正文，只允许运行 Codex CLI 命令并记录脱敏后的命令结果。
- 所有命令输出必须通过现有插件适配器的脱敏和摘要函数处理。
- 不在日志中输出 token、secret、cookie、password、Bearer token 或认证文件正文。
- 插件真实部署失败时，结果必须包含失败步骤：`marketplace_add` 或 `plugin_add`。
- 如果插件安装部分成功、后续失败，应保留可回滚命令信息，后续 rollback 由已有 journal/rollback 机制处理或记录残留。
- 本阶段不扩大文件系统写入范围，不修改用户级 Codex 配置以外的受管插件状态。

## 数据与接口

白名单仍是唯一部署权威：

- `Resources/tool_whitelist.toml`
- `approval = "approved"` 的插件才允许进入部署计划。
- 首批插件为：
  - `plugin.openai-bundled.browser`
  - `plugin.openai-curated.superpowers`

入口命令保持不变：

```powershell
powershell -NoProfile -File .\scripts\Invoke-CodexToolManager.ps1 deploy -Config <config> -Whitelist <whitelist>
powershell -NoProfile -File .\scripts\Invoke-CodexToolManager.ps1 deploy -Config <config> -Whitelist <whitelist> -DryRun
powershell -NoProfile -File .\scripts\Invoke-CodexToolManager.ps1 verify -Config <config> -Whitelist <whitelist>
```

不新增用户必须记忆的新命令参数。

## 错误处理

- 配置或白名单无效：返回业务失败，状态为 `blocked`。
- 未批准工具进入部署计划：返回业务失败，状态为 `blocked`。
- 插件命令执行失败：返回业务失败，状态为 `blocked` 或 `failed`，并记录失败步骤。
- Codex CLI 缺失或命令不可用：返回业务失败，不抛出未处理异常。
- 插件列表输出无法解析：load verification 返回 `failed`，错误码为 `plugin_list_parse_failed`。
- 插件未出现在列表中：load verification 返回 `failed`，错误码为 `plugin_not_found`。
- Skill/MCP 真实部署被请求：继续返回 `blocked`，说明本阶段未接入。

## 测试策略

使用 TDD 实现：

1. 先写入口级失败测试，证明当前非 dry-run 插件部署仍被 blocked adapter 阻塞。
2. 接入 plugin 真实适配器后，让该测试通过，并确认 Skill/MCP 仍 blocked。
3. 增加入口级 verify 测试，使用测试 executor 模拟 `codex plugin list --json` 输出，证明插件 load verification 能通过。
4. 增加失败路径测试，覆盖插件列表解析失败、插件未找到、CLI 命令失败。
5. 保留 dry-run/WhatIf 测试，证明 dry-run 不执行真实命令。
6. 运行单元测试、相关集成测试和必要的全量测试。

## 交付物

- 更新 `scripts/Invoke-CodexToolManager.ps1`，将 plugin 接入真实适配器。
- 必要时小幅调整 `scripts/lib/DeploymentEngine.ps1` 或 `scripts/lib/VerificationEngine.ps1` 的接线逻辑，但不重构核心架构。
- 更新或新增入口集成测试。
- 更新 `/state` 文件记录真实插件路径的完成状态和仍保留的 Skill/MCP 限制。

## 通过标准

- `browser + superpowers` 插件路径可以从入口执行真实部署逻辑。
- `deploy -DryRun` 和 `deploy -WhatIf` 不执行真实命令。
- `verify` 能对插件执行 load verification。
- Skill/MCP 仍不会被真实部署。
- 测试输出证明新增行为已覆盖，且没有把 load 验证误报为功能性 smoke 成功。

## 自审结果

- 无未决后补项或含糊承诺。
- 范围限定为插件真实部署与验证，不包含 Skill/MCP 实现。
- 与用户选择的方案 A 一致。
- 风险边界明确：不读取认证文件正文，不扩大文件系统部署范围，不伪造 smoke 成功。
