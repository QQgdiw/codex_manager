# 项目任务状态

> **更新时间**：2026-06-25

## 已完成

- [x] 建立仓库 `.gitignore` 和 Pester 3.4 兼容测试入口。
- [x] 使用隔离夹具验证默认 All、`-Unit` 和 `-Integration` 的测试选择。
- [x] 验证普通测试失败返回 1，没有匹配测试返回 2。
- [x] 忽略 `.env` 和 `.env.*`，并允许提交 `.env.example`。
- [x] 阅读并整理初始需求。
- [x] 明确首期范围为基础闭环。
- [x] 确认资源更新、白名单、部署、验证、回滚和凭据策略。
- [x] 完成产品定位、系统边界、核心工作流和交付物设计确认。
- [x] 编写 `Resources/PRD.md`。
- [x] 审计现有 Plugins、MCP、Skills、运行时和权限。
- [x] 编写 `Resources/PP.md`。
- [x] 验证用户级 Codex `auth.json` 可用于沙箱外认证。
- [x] 确认现有 MCP 和 Skills 纳入统一管理与验证。
- [x] 建立项目状态文件。
- [x] 建立结构化审批辅助表 `Resources/approval_review.toml` 和人类可读审批摘要 `Resources/approval_review.md`。
- [x] 按用户批准，将 `approve_now` 和 `needs_review` 对应白名单条目更新为 `approved`，当前批准工具数为 6。
- [x] 重建 `Resources/plugins_market.md`，记录本地缓存、CLI 和 GitHub `openai/plugins` 来源差异。
- [x] 扩展 `Resources/github_market.md` 为 2026-W01 至 2026-W26 工程候选池，并实现跨周去重规则说明。
- [x] 重写 `Resources/event_market.md`，从泛 AI 行业事件调整为工程工作流事件市场。
- [x] 完成市场与审批强化验收：全量测试、TOML 解析、敏感 token 扫描和 Git 空白检查。

## 下一阶段

- [x] 定义 `tool_whitelist.toml` Schema。
- [x] 实现并验证变更日志与受管回滚安全机制（PP Task 5）。
- [x] 设计 PowerShell 入口和部署适配器。
- [x] 定义 `verify_record.md` 模板。
- [x] 首次填充五类市场文档。
- [x] 评审并批准首批白名单工具。
- [x] 编写六类场景化配置。
- [x] 执行首批 approved 工具的部署 dry-run 和静态分层验证。
- [x] 完成首期端到端验收：全量测试、TOML 解析、敏感内容扫描和 PRD 覆盖核对。
- [x] 接入 plugin 类型真实部署适配器和 load verifier，首批覆盖 `browser` 与 `superpowers`。
- [x] 接入 Skill 真实部署适配器和 load verifier；当前只证明受管安装与内容 hash 正确。
- [ ] 为 Skill 补充真正的运行时 smoke verifier；当前不伪造 Codex 运行时执行成功。
- [x] 接入 MCP 真实部署适配器和 load verifier；自动 load verifier 当前只证明 Codex MCP 配置可查询到该 MCP。
- [x] 完成 sequential-thinking MCP 的用户级真实环境部署与 load verification；真实配置已登记绝对启动路径，静态验证和 load verification 均通过。
- [ ] 为 MCP 补充自动化功能性 smoke verifier；sequential-thinking 已完成人工协议 smoke，但管理器仍因 `smoke_verifier_missing` 保守返回 blocked。
- [ ] 为插件补充真正的功能性 smoke verifier；当前只证明 load 可见，不伪造插件功能成功。
- [ ] 后续如做审批可视化，应以 `Resources/approval_review.toml` 为数据源，而不是解析 Markdown。
- [ ] 下一次更新 `Resources/github_market.md` 时继续执行跨周去重，已收录仓库不参与后续周榜名额。

## 后续路线

- [ ] 设想 A：MCP 或 App 形式的自动工具管理。
- [ ] 设想 B：工具管理与行业事件可视化。
- [ ] 设想 C：行业事件中的工具发现、部署和测试联动。
