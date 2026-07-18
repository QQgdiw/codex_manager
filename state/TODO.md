# 项目任务状态

> **更新时间**：2026-07-18

## 当前任务：工程工作流事件市场正式重建

- [x] 核实现有 `event_market.md` 没有经联网核验的正式事件条目。
- [x] 确认覆盖 2026-01-01 至 2026-07-18，预计约 35 项但不设置硬数量。
- [x] 确认只收录已发生且有官方一手来源的工程相关事件。
- [x] 确认采用“组织归档 + 主题索引”，连续小版本合并为阶段性事件。
- [x] 编写并提交 `docs/superpowers/specs/2026-07-18-event-market-rebuild-design.md`。
- [x] 用户审阅并确认事件市场重建设计说明。
- [x] 编写详细实施计划 `docs/superpowers/plans/2026-07-18-event-market-rebuild.md`。
- [ ] 用户审阅并确认事件市场重建实施计划。
- [ ] 完成候选调研、逐项核验、正式文档重建和最终质量审计。

## 已完成任务：市场文档质量审计与整理

- [x] 核实 `openai/plugins.git`、`codex plugin list` 与 `/plugins` 数据范围差异。
- [x] 首次通过 Codex app-server `plugin/list` 复现 1,984 条插件记录，并确认 1 组上游重复限定 ID；该数量仅为历史探测快照。
- [x] 明确四份市场文档的收录权威、补充来源和运行状态来源。
- [x] 编写 `docs/superpowers/specs/2026-07-13-market-document-quality-audit-design.md`。
- [x] 用户审阅并确认市场文档质量审计设计说明。
- [x] 编写详细实施计划 `docs/superpowers/plans/2026-07-14-market-document-quality-audit.md`。
- [x] Task 1：实现 Plugins 目录采集器和完整性验证器；Node 10/10、Pester unit 308/308 通过。
- [x] Task 1 兼容性修复：真实 Codex envelope、Windows npm `.cmd` shim 和 `--throw-deprecation` 回归验证通过；Node 15/15、Pester unit 310/310。
- [x] Task 1 元数据修复：读取真实 `plugin.interface` 嵌套字段并生成五类研发者重点索引；Node 16/16、Pester unit 310/310，临时真实采集为 2,033 条记录。
- [x] Task 2：更新正式需求、计划、GUIDE 和旧设计边界；合同探针预期失败，正常 unit 310/310 通过。
- [x] Task 3：使用真实 `plugin/list` 生成并审阅完整 `plugins_market.md`；正式采集 2,034 条记录、1,047 条重点索引，记录键检查和即时一致性检查通过。
- [x] Task 4：实现 GitHub 候选采集和跨文档验证器；Node 5/5、市场脚本 Pester 4/4 通过。
- [x] Task 5 扩展：重审并重建 W01-W29 全部 GitHub 候选；658 条中保留 236、排除 422，29 周完整，硬校验通过。
- [x] Task 5 扩展设计与实施计划均已确认并执行。
- [x] Task 6：重建 `MCP_market.md` 和 `tool_market.md`；66 条相关候选保留 2 条工具/Skill、MCP 派生为 0，并区分白名单批准、历史验证和当前注册/部署状态。
- [x] Task 7：统一四份市场文档及相关需求、计划、GUIDE 和生成规则的术语与职责。
- [x] Task 7：完成一致性、来源、状态、去重、中文质量、敏感信息和全量测试检查；Node 36/36、Pester `-All` 361/361 通过。

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
- [x] 早期按本地缓存、CLI 和 GitHub `openai/plugins` 来源重建 `Resources/plugins_market.md`；该方案已被 app-server `plugin/list` 唯一权威规则取代。
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
- [x] 已进入文档质量审计与整理阶段；当前执行至 Task 7 最终跨文档审计。
