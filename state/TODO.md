# 项目任务状态

> **更新时间**：2026-07-13

## 当前任务：市场文档质量审计与整理

- [x] 核实 `openai/plugins.git`、`codex plugin list` 与 `/plugins` 数据范围差异。
- [x] 通过 Codex app-server `plugin/list` 复现 1984 条插件记录，并确认 1 组上游重复限定 ID。
- [x] 明确四份市场文档的收录权威、补充来源和运行状态来源。
- [x] 编写 `docs/superpowers/specs/2026-07-13-market-document-quality-audit-design.md`。
- [ ] 用户审阅并确认市场文档质量审计设计说明。
- [ ] 编写详细实施计划。
- [ ] 执行四份市场文档及相关需求、计划和生成规则的整理。
- [ ] 完成一致性、来源、状态、去重、中文质量和敏感信息检查。

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
- [x] 为 MCP 补充自动化功能性 smoke verifier；sequential-thinking 已通过管理器自动 smoke 验证。
- [x] 自动 MCP smoke verifier Task 1：扩展白名单 smoke schema，并把批准 smoke profile 写入 approved snapshot。
- [x] 自动 MCP smoke verifier Task 2：为受管进程增加显式环境隔离，清空继承环境后只传入白名单变量。
- [x] 自动 MCP smoke verifier Task 3：让静态验证器支持适配器注入，并修复 StaticVerifier 异常脱敏和类型错误边界。
- [x] 自动 MCP smoke verifier Task 4：实现通用 Node MCP stdio smoke runner，并完成人工质量门禁；目标集成测试 14/14、全量集成测试 43/43 通过。
- [x] 自动 MCP smoke verifier Task 5：实现 MCP smoke plan 生成与静态安全校验。
- [x] 自动 MCP smoke verifier Task 6：加固 MCP load verifier，校验 enabled、transport、command 和 args。
- [x] 自动 MCP smoke verifier Task 7：执行 prepare、runner、validate、cleanup 生命周期，并处理 cleanup/residual 失败边界。
- [x] 自动 MCP smoke verifier Task 8：接线入口，并为 sequential-thinking 添加 lifecycle script 和白名单 smoke profile。
- [x] 自动 MCP smoke verifier Task 9：完成真实环境自动 smoke 验证、残留检查和记录更新。
- [ ] 为插件补充真正的功能性 smoke verifier；当前只证明 load 可见，不伪造插件功能成功。
- [ ] 后续如做审批可视化，应以 `Resources/approval_review.toml` 为数据源，而不是解析 Markdown。
- [ ] 下一次更新 `Resources/github_market.md` 时继续执行跨周去重，已收录仓库不参与后续周榜名额。

## 后续路线

- [ ] 设想 A：MCP 或 App 形式的自动工具管理。
- [ ] 设想 B：工具管理与行业事件可视化。
- [ ] 设想 C：行业事件中的工具发现、部署和测试联动。
## 2026-07-06 Task 4 quality review follow-up

- [x] Fix MCP smoke runner cleanup so captured processes are stored with PID identity metadata and revalidated before termination.
- [x] Remove Windows `taskkill /T` usage; cleanup now terminates verified processes one at a time.
- [x] Reject non-integer and above-Node-timer-limit `timeoutSeconds` values with `mcp_smoke_invalid_request`.
- [x] Verification: RED target test failed 4 expected checks; GREEN target `McpSmokeRunner.Tests.ps1` passed 16/16; `node --check` and `git diff --check` exit code 0.
## 2026-07-06 Task 4 POSIX identity review follow-up

- [x] Replace POSIX cleanup identity matching with high precision Linux `/proc/<pid>/stat` field 22 `starttime` ticks where available.
- [x] Fail cleanup verification with `mcp_smoke_cleanup_failed` when a non-Windows process lacks high precision identity.
- [x] Verification: RED target test failed 5 expected checks; GREEN target `McpSmokeRunner.Tests.ps1` passed 18/18; `node --check` and `git diff --check` exit code 0.

## 2026-07-06 Final review smoke hardening

- [x] Fail MCP smoke verification when the server root disappears before cleanup can refresh and prove the process tree.
- [x] Revalidate MCP smoke operation root path and reparse status before recursive deletion.
- [x] Align MCP smoke plan timeout validation with whitelist schema maximum of 30 seconds.
- [x] Verification: RED target log captured expected failures; final target passed 54/54; final all passed 355/355; `node --check` and `git diff --check` passed.

## 2026-07-12 Filesystem MCP 受限真实试运行

- [x] 为 `mcp.modelcontextprotocol.filesystem` 增加受限 smoke profile，启动参数固定为 `E:\codex`。
- [x] 新增 `scripts/smoke/mcp/filesystem.mjs` 生命周期脚本，验证 `write_file` 仅写入 `.tmp\mcp-smoke` operation root。
- [x] 为 MCP smoke 参数增加 `${MCP_SMOKE_TEMP_ROOT}` 和 `${MCP_SMOKE_RESULT_PATH}` 运行时替换。
- [x] 完成真实部署：`modelcontextprotocol-filesystem` 已写入用户级 Codex MCP 配置。
- [x] 完成真实验证：static=`static_verified`，load=`load_verified`，smoke=`smoke_verified`。
- [x] 完成残留核验：目标 filesystem Node 进程数为 0，`.tmp\mcp-smoke` operation root 数量为 0。
- [x] 修复 rollback 并发测试在真实机器负载下 30 秒锁等待不足的问题，将等待上限提高到 120 秒。
- [x] 验证：目标测试通过；最终全量测试 `356 passed / 0 failed`。
- [ ] 下一步进入文档质量审计与整理阶段，统一当前工程状态和长期维护口径。
