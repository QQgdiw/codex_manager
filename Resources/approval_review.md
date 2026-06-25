# 审批辅助表

`Resources/tool_whitelist.toml` 仍然是自动部署的唯一权威来源。本文件只用于帮助人工理解和审批，不直接改变工具是否允许部署。若需要改变批准状态，应修改 `Resources/tool_whitelist.toml`。

## 使用方式

- `当前状态`：来自白名单中的现有审批状态。
- `建议动作`：本项目根据首期闭环、风险和使用场景给出的建议。
- `风险等级`：用于提醒是否需要额外复核，不等同于禁止使用。
- `主要用途`：说明该工具为什么会被纳入管理。
- `建议理由`：说明现在批准、暂缓批准或继续复核的原因。

建议动作含义：

| 建议动作 | 含义 |
| --- | --- |
| `approve_now` | 建议现在批准，适合进入当前最小闭环。 |
| `needs_review` | 建议人工复核后再决定，通常涉及文件、记忆、权限或数据边界。 |
| `approve_later` | 建议暂缓批准，等对应场景真正进入范围后再处理。 |

## 审批清单

| ID | 类型 | 当前状态 | 建议动作 | 风险等级 | 主要用途 | 建议理由 |
| --- | --- | --- | --- | --- | --- | --- |
| `plugin.openai-bundled.browser` | plugin | approved | approve_now | medium | 应用内浏览器验证 | 已在首期批准，且本地 Web 检查和页面验证需要该能力。 |
| `mcp.modelcontextprotocol.filesystem` | mcp | approved | approve_now | high | 文件系统 MCP 访问 | 用户已在复核文件系统风险后批准；真实部署仍必须限制根目录、写入范围和回滚边界。 |
| `mcp.modelcontextprotocol.memory` | mcp | proposed | approve_later | medium | 持久化 MCP 记忆 | 后续可能有用，但应先确定记忆保留周期、数据边界和清理策略。 |
| `mcp.modelcontextprotocol.sequential-thinking` | mcp | approved | approve_now | medium | 结构化推理支持 | 已在首期批准，相比文件或记忆类工具，外部副作用较小。 |
| `skill.context-engineering.context-fundamentals` | skill | approved | approve_now | low | 上下文工程基础指导 | 已在首期批准，属于指导性能力，风险较低。 |
| `skill.context-engineering.context-optimization` | skill | proposed | approve_later | medium | 上下文和提示优化 | 基础流程稳定后再启用更合适；白名单中许可证信息仍未知。 |
| `skill.context-engineering.context-compression` | skill | proposed | approve_later | medium | 上下文压缩与交接摘要 | 后续长任务交接可能有用；白名单中许可证信息仍未知。 |
| `skill.context-engineering.filesystem-context` | skill | approved | approve_now | medium | 基于文件系统的上下文收集 | 用户已在复核文件系统上下文风险后批准；使用时必须遵守数据最小化边界，避免过度读取工作区文件。 |
| `skill.context-engineering.tool-design` | skill | proposed | approve_later | medium | Agent 工具接口设计 | 与后续工具开发相关，但不是首期基础闭环必需项；白名单中许可证信息仍未知。 |
| `skill.context-engineering.multi-agent-patterns` | skill | proposed | approve_later | medium | 多 Agent 工作流指导 | 当前阶段不是必需项，过早启用可能增加流程复杂度。 |
| `skill.context-engineering.harness-engineering` | skill | proposed | approve_later | medium | Agent 评测与验证框架指导 | 等真实部署和验证体系成熟后再考虑；白名单中许可证信息仍未知。 |
| `plugin.openai-curated.superpowers` | plugin | approved | approve_now | medium | TDD、计划和验证工作流 | 已在首期批准，直接支持计划、测试驱动开发和完成前验证。 |
| `plugin.openai-primary-runtime.documents` | plugin | proposed | approve_later | medium | 文档工件创建与质量检查 | 文档处理场景进入范围后会有价值，但不是当前审批基础设施必需项。 |
| `plugin.openai-primary-runtime.presentations` | plugin | proposed | approve_later | medium | 演示文稿创建与质量检查 | 演示文稿场景进入范围后再批准更合适。 |
| `plugin.openai-primary-runtime.spreadsheets` | plugin | proposed | approve_later | medium | 表格工件创建与分析 | 表格数据处理场景进入范围后再批准更合适。 |
