# 工具与 Skill 市场

> 更新时间：2026-07-15
>
> 来源边界：GitHub 派生项必须存在于 `github_market.md`；白名单 Skill 作为当前受管基线独立记录，不能伪造 GitHub 派生关系。

## 当前结论

- 66 条相关 GitHub 候选中保留 2 条：1 个 Skill、1 个 Tool；其余 64 条因许可证、安装入口、权限/凭据边界或当前 Codex 兼容性证据不足而排除。
- 两条保留项的处理建议均为 `needs_review`；它们尚未进入白名单，也不会自动安装。
- 已批准的 context-engineering Skill 受管目标当前不存在；现有证据只覆盖白名单批准、本地源码哈希，以及个别 Skill 的历史静态/load 记录，未证明当前 Codex 已加载或执行。

## GitHub 派生候选

### Weizhena/Deep-Research-skills

<!-- derived-record:{"repository":"Weizhena/Deep-Research-skills","week":"2026-W01","kind":"skill"} -->

- 来源等级：C 级近似回溯；对应 GitHub 总表 W01 主条目。
- 类型：上游声称支持 Codex 的研究 Skill 候选。
- 安装入口：按上游 README 作为 Skill 安装；精确命令和目录布局待核验。
- 运行时：Codex Skill 宿主；外部资料源可能另需网络或认证。
- 凭据：项目本体未确认必需凭据；外部资料源凭据必须由受控环境按需提供。
- 权限：若进入隔离试运行，拟仅允许读取用户明确提供的研究问题和资料，不授予非必要的文件写入、命令执行或账户操作权限；这不是已核验的上游默认行为。
- 许可证：未确认，是进入白名单前的阻塞项。
- Codex 兼容性：GitHub 总表记录明确说明支持 Codex，未发现需要修改上游源码的证据。
- 风险：外部资料可能不可靠或包含提示注入；研究结论、引用和许可证均需人工复核。
- 处理建议：`needs_review`；核验 `SKILL.md`、许可证、安装布局和资料访问边界后再决定是否加入审批辅助表。

### Dimillian/CodexMonitor

<!-- derived-record:{"repository":"Dimillian/CodexMonitor","week":"2026-W02","kind":"tool"} -->

- 来源等级：C 级近似回溯；对应 GitHub 总表 W02 主条目。
- 类型：Codex app-server 桌面监控工具。
- 安装入口：按上游 README 构建或安装 Tauri 桌面应用；精确发布包和签名状态待核验。
- 运行时：Tauri 桌面运行时、可用的 Codex app-server 和本地工作区。
- 凭据：没有确认独立凭据；Codex 连接和认证处理方式待核验。
- 权限：可能读取 Codex 会话、任务、工作区或 app-server 状态，应限制到必要范围。
- 许可证：未确认，是进入白名单前的阻塞项。
- Codex 兼容性：功能目标明确面向 Codex app-server；当前 CLI/API 版本兼容性尚未实测。
- 风险：桌面应用供应链、会话数据暴露、app-server 接口变化和本地工作区访问。
- 处理建议：`needs_review`；先核验许可证、签名/构建链和只读权限，再进行隔离试运行。

## 当前受管 Skill 基线

| 白名单 ID | 审批 | 当前受管目标 | 可支持的结论 | Smoke | 处理建议 |
| --- | --- | --- | --- | --- | --- |
| `skill.context-engineering.context-fundamentals` | `approved` | 当前目标 `E:\codex\Skills\context-fundamentals\SKILL.md` 不存在 | 历史静态记录存在；当前未部署 | `blocked`：没有运行时功能调用证据 | 保留批准；重新部署后执行 hash/load，不能宣称功能 smoke。 |
| `skill.context-engineering.filesystem-context` | `approved` | 当前目标 `E:\codex\Skills\filesystem-context\SKILL.md` 不存在 | 白名单批准和本地源码哈希证据存在；当前未部署 | `blocked` | 保留批准；部署时限制文件上下文范围和敏感资料。 |
| `skill.context-engineering.context-optimization` | `proposed` | 未部署 | 固定上游提交和本地源码哈希证据 | `blocked` | 保持 proposed，按具体场景审批。 |
| `skill.context-engineering.context-compression` | `proposed` | 未部署 | 固定上游提交和本地源码哈希证据 | `blocked` | 保持 proposed，按具体场景审批。 |
| `skill.context-engineering.tool-design` | `proposed` | 未部署 | 固定上游提交和本地源码哈希证据 | `blocked` | 保持 proposed，按具体场景审批。 |
| `skill.context-engineering.multi-agent-patterns` | `proposed` | 未部署 | 固定上游提交和本地源码哈希证据 | `blocked` | 保持 proposed，按具体场景审批。 |
| `skill.context-engineering.harness-engineering` | `proposed` | 未部署 | 固定上游提交和本地源码哈希证据 | `blocked` | 保持 proposed，按具体场景审批。 |

## 状态解释

- Skill 的文件存在、内容 hash 和受管安装验证最多支持静态/load 层结论，不等于 Codex 运行时实际采用了 Skill 指令。
- 没有最小功能调用证据时，Smoke 必须保持 `blocked`。
- “市场候选”表示收录类别，`needs_review` 表示当前处理建议，白名单 `approved` 表示正式审批状态；市场文档不能改变审批结果。
