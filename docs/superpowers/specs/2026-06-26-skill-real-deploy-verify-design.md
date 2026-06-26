# Skill 真实部署与验证最小闭环设计

## 背景

当前项目已经完成插件类型的真实部署与 load verification 最小闭环。`plugin` 类型已接入真实 Codex CLI executor、`Install-ManagedPlugin` 和 `Test-ManagedPlugin`；`-DryRun` 与 `-WhatIf` 仍保持无副作用。Skill 和 MCP 目前仍保持 blocked adapter。

用户确认下一步选择方案 A：接入 Skill 真实部署与验证。MCP 的真实配置和文件系统边界更复杂，本阶段不处理。

## 目标

- 将 `skill` 类型接入真实部署路径。
- 首批覆盖两个已批准 Skill：
  - `skill.context-engineering.context-fundamentals`
  - `skill.context-engineering.filesystem-context`
- 部署时复用现有 `Get-SkillInstallPlan` 和 `Install-ManagedSkill`。
- 验证时复用现有 `Test-ManagedSkill`。
- 保持 `-DryRun` 与 `-WhatIf` 无副作用。
- 保持 `plugin` 已有真实路径不回退。
- 保持 `mcp` blocked，不触碰 Codex MCP 配置。

## 非目标

- 不接入 MCP 真实部署、加载验证或 smoke 验证。
- 不实现 Skill 的功能性 smoke verifier。
- 不宣称 Skill 已被 Codex 运行时真正加载。
- 不读取、打印或提交 `auth.json` 正文。
- 不扩大 `filesystem-context` 的文件读取权限；本阶段只安装和校验 Skill 文件。
- 不实现审批可视化。

## 推荐方案

入口 `deploy`：

- `plugin` 保持现有真实部署路径。
- `skill` 从 blocked adapter 切换为真实 Skill adapter。
- `mcp` 继续 blocked。
- `-DryRun` 和 `-WhatIf` 继续只生成 dry-run 结果，不创建、删除或复制 Skill 文件。
- 非 dry-run 时，`skill` 调用：
  - `Get-SkillInstallPlan`
  - `Install-ManagedSkill`

入口 `verify`：

- `skill` 的 load verification 调用 `Test-ManagedSkill`。
- load verification 只证明：
  - 受管目标目录存在。
  - `SKILL.md` 存在。
  - 安装后内容 hash 与 approved snapshot 匹配。
  - 目标路径位于 `managed_workspace_root\Skills\<skill_id>` 内。
  - 目标目录不含 reparse point、junction 或 symlink。
- smoke verification 继续 blocked，因为本阶段没有可靠证据证明 Codex 运行时已实际加载并执行该 Skill。

## 安全边界

- Skill 只能安装到白名单 approved snapshot 指定的 `managed_workspace_root\Skills\<skill_id>`。
- `target_root` 不支持，避免把 Skill 写入任意目录。
- `target_subdir` 如存在，必须位于 `managed_workspace_root\Skills` 下。
- 源目录和目标目录均拒绝 reparse point、junction、symlink。
- 安装前后都必须使用 approved snapshot 中的 hash 和路径信息，不能信任 top-level 可变字段覆盖白名单快照。
- `filesystem-context` 的批准只允许安装和验证 Skill 文件，不代表允许无限制读取工作区文件。
- 删除或替换目标目录时只能操作受管 Skill 目录。

## 数据与接口

白名单仍是唯一部署权威：

- `Resources/tool_whitelist.toml`
- 只有 `approval = "approved"` 的 Skill 可以进入部署计划。

入口命令不新增用户必须记忆的参数：

```powershell
powershell -NoProfile -File .\scripts\Invoke-CodexToolManager.ps1 deploy -Config <config> -Whitelist <whitelist>
powershell -NoProfile -File .\scripts\Invoke-CodexToolManager.ps1 deploy -Config <config> -Whitelist <whitelist> -DryRun
powershell -NoProfile -File .\scripts\Invoke-CodexToolManager.ps1 verify -Config <config> -Whitelist <whitelist>
```

## 错误处理

- 白名单或配置无效：返回业务失败，状态为 `blocked`。
- 未批准 Skill 进入部署计划：返回业务失败，状态为 `blocked`。
- Skill source hash 与 approved snapshot 不匹配：部署计划失败。
- `SKILL.md` 缺失或 front matter 无效：部署计划失败。
- 目标路径越界：部署或验证失败。
- 源目录或目标目录包含 reparse point、junction、symlink：部署或验证失败。
- 安装后 hash 不匹配：load verification 失败。
- Skill smoke verification 缺失：返回 `blocked`，不伪造成功。

## 测试策略

使用 TDD 实现：

1. 新增入口级 Skill fixture，使用临时 source 和 workspace，不触碰真实 `E:\codex\Skills`。
2. 先验证 Skill dry-run 不创建目标目录。
3. 写 RED 测试证明当前非 dry-run Skill 部署仍 blocked。
4. 接入 Skill adapter 后，GREEN 测试证明 Skill 被复制到临时 workspace 的 `Skills\<skill_id>`。
5. 写 RED 测试证明当前 Skill verify load 仍 blocked。
6. 接入 Skill load verifier 后，GREEN 测试证明 load 为 `load_verified`，smoke 仍 blocked。
7. 运行单元测试、集成测试和最终全量测试。

## 交付物

- 更新 `scripts/Invoke-CodexToolManager.ps1`，接入 Skill deploy adapter 和 Skill load verifier。
- 更新 `tests/integration/EntryPoint.Tests.ps1`，增加 Skill 入口集成测试。
- 更新 `/state` 文件，记录 Skill 真实部署与 load verification 状态和剩余限制。

## 通过标准

- Skill 类型可以通过入口执行真实受管安装。
- Skill dry-run 不创建或修改目标目录。
- Skill load verification 能验证安装目录和 hash。
- Skill smoke verification 仍保守 blocked。
- MCP 仍保持 blocked。
- 全量测试通过。

## 自审结果

- 无未决后补项或含糊承诺。
- 范围只覆盖 Skill，不包含 MCP。
- 与用户确认的下一步一致。
- 不读取认证文件正文，不扩大 `filesystem-context` 权限，不伪造 smoke 成功。
