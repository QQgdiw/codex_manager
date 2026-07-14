# 项目状态说明

## 项目定位

本工作区用于管理 Codex Plugins、MCP、Skills 和其他 AI 工作流资源，并面向 Windows 环境提供场景化配置、自动部署、分层验证和失败回滚能力。

## 当前阶段

首期基础闭环已经完成端到端验收。正式需求和计划分别位于 `Resources/PRD.md` 与 `Resources/PP.md`；资源市场、白名单、审批辅助表、六类场景配置、PowerShell 管理入口、DPAPI 凭据、受管回滚、dry-run 部署和分层验证记录均已建立。

2026-07-14 已进入市场文档质量审计与整理阶段，重点覆盖 `plugins_market.md`、`github_market.md`、`MCP_market.md` 和 `tool_market.md`。本机已验证 Codex app-server `plugin/list` 当前返回 1984 条插件记录，其中远程官方目录 1974 条；旧 `openai/plugins.git` 和 `codex plugin list` 只覆盖约 179 至 183 个本地 marketplace snapshot，不能继续作为 `/plugins` 完整清单。用户已审阅并确认设计与实施计划。Task 1 已完成 Plugins 目录采集器、原子写入、检查模式和严格 JSON-RPC 生命周期验证；四份市场正文尚未改写。

2026-06-25 已完成市场与审批强化：`Resources/approval_review.toml` 和 `Resources/approval_review.md` 提供面向后续可视化的审批辅助数据；`Resources/plugins_market.md` 已按本地缓存、CLI 和 GitHub `openai/plugins` 来源重建；`Resources/github_market.md` 已扩展为 2026-W01 至 2026-W26 的工程候选池，并记录 `stars >= 1000`、近似回溯、跨周去重和候选不足周；`Resources/event_market.md` 已从泛 AI 行业事件改为工程工作流事件市场。

2026-06-25 用户批准 `approval_review.md` 中建议动作为 `approve_now` 和 `needs_review` 的条目，当前白名单共有 6 个 `approved` 工具；其中 `mcp.modelcontextprotocol.filesystem` 和 `skill.context-engineering.filesystem-context` 虽已批准，但真实部署必须继续执行文件系统根目录、写入范围、数据最小化和回滚边界约束。

2026-06-25 已接入插件真实部署与 load verification 最小闭环。当前真实路径仅覆盖 `plugin` 类型，首批目标为 `plugin.openai-bundled.browser` 和 `plugin.openai-curated.superpowers`；Skill 和 MCP 仍保持 blocked adapter，尚未接入真实安装、加载验证或 smoke 验证。插件 smoke verification 仍保守阻塞，不能宣称插件功能性调用已通过。

## 首期范围

- 首次填充并按需增量维护五类市场文档。
- 提供六类场景化配置。
- 使用 TOML 白名单控制自动部署。
- 使用 PowerShell 完成部署、验证、回滚和记录。
- 使用 Windows DPAPI 加密本地凭据。
- 仅支持并验证 Windows 环境。

## 关键原则

- 原生能力优先，选择最小充分工具集。
- 白名单由系统建议、用户批准。
- 工具固定版本，升级需重新确认。
- 资源信息必须可追溯，不完整历史数据明确标注。
- GitHub 市场周度候选必须跨周去重；早期 week 已收录的仓库，后续 week 不再计入 20-30 个候选目标。
- 严格区分收录、批准、部署和不同验证状态。
- 后续需要供人类阅读的 Markdown 文档默认使用简体中文。
- 设想 A、B、C 仅进入后续路线，首期不实现。

## 关键文档

- 初始需求：`需求文档.txt`
- 正式需求：`Resources/PRD.md`
- 项目计划：`Resources/PP.md`
- 配置参考：`Templates/config_toml.txt`
- 当前任务：`state/TODO.md`
- 排障记录：`state/LOG.md`

## 当前能力状态

- `tests/Run-Tests.ps1` 提供 Pester 3.4 兼容入口，支持 `-Unit`、`-Integration`、`-All`，默认执行全部测试，并在测试失败或零匹配时返回非零。
- `tests/unit/Baseline.Tests.ps1` 验证 Windows PowerShell 主版本不低于 5，并通过隔离的临时测试目录验证默认 All、Unit/Integration 选择、零匹配和失败退出码。
- 测试入口将普通测试失败返回为 1，将零匹配、Pester 加载异常或零执行等基础设施错误返回为 2。
- `.gitignore` 已覆盖本地凭据、认证文件、`.env` 文件、测试产物、日志、Python 缓存和 MCP 第三方依赖，同时允许提交 `.env.example`。
- 当前会话具备完成首期所需的检索、浏览器、文件、PowerShell、测试和 Git 能力，无需立即安装额外扩展。
- Codex CLI 当前未配置 marketplace plugin 和 MCP。
- 根目录 `config.toml` 当前不能视为 Codex 已加载配置。
- 用户级 Codex `auth.json` 已在沙箱外验证可用；认证检查不读取文件正文。
- 现有 `MCP/servers` 和 `Skills/AgentSkillsforContextEngineering` 将作为首批管理对象，按新项目相同规则进入白名单和验证流程。
- 联网下载可自动执行；首次按命令前缀申请并保存授权规则。用户目录写入或系统级变更仍需明确授权。
- `scripts/lib/ChangeJournal.ps1` 已实现严格 Schema v2、DPAPI CurrentUser 完整性认证、操作级跨进程锁、耐久原子写、受信根授权、reparse point 拒绝和文件身份校验。
- journal 自身存储路径从可信根到 StateRoot、journals、operation、backups、journal/temp/lock 父路径逐级验证；缺失目录逐级创建并在每一级创建后复检。
- create 与 directory_create 必须在实际创建后调用 `Confirm-FileChange` 记录身份；未确认项回滚时保留并进入 `Residuals`。
- 外部回滚命令只记录为残留信息，系统不会执行字符串 shell 命令。
- Task 19 最终验收：全量测试 284 passed / 0 failed；所有 `Resources/*.toml` 可解析；敏感扫描未发现交付记录中的明文凭据；PRD 覆盖项均有实现、记录或明确限制。
- 2026-06-25 市场与审批强化最终验收：全量测试 287 passed / 0 failed；所有 `Resources/*.toml` 可解析；精确敏感 token 扫描无命中。
- 2026-06-25 插件真实部署与验证最小闭环：入口已对 plugin 类型接入真实 Codex CLI executor、`Install-ManagedPlugin` 和 `Test-ManagedPlugin` load verifier；Skill/MCP 仍 blocked；插件 smoke verifier 尚未实现。
- 2026-06-26 Skill 真实部署与 load verification 最小闭环：入口已对 skill 类型接入 `Install-ManagedSkill` 和 `Test-ManagedSkill` load verifier；MCP 仍 blocked；Skill smoke verifier 尚未实现，不能宣称 Codex 运行时已实际加载并执行 Skill。
- 2026-06-27 MCP 真实部署与 load verification 最小闭环：入口已对 mcp 类型接入 `Install-ManagedMcp` 和 `Test-ManagedMcp` load verifier；plugin、skill、mcp 均已有真实部署和 load verification 最小闭环；MCP smoke verifier 尚未实现，不能宣称 MCP 工具方法已被安全调用。
- 2026-06-29 sequential-thinking MCP 已部署到用户级 Codex 配置；静态验证和 load verification 通过，并通过一次独立 MCP 客户端完成 `initialize`、`tools/list` 和最小 `sequentialthinking` 调用。该协议 smoke 仍是手工试运行证据，尚未接入管理器自动 smoke verifier。
- 2026-07-06 sequential-thinking MCP 自动 smoke verifier 已接入并通过真实验证；static=`static_verified`、load=`load_verified`、smoke=`smoke_verified`，内容类型为 `text`，无残留目标 Node 进程，operation root 数量为 0。
## 2026-07-06 Task 4 Quality Follow-up

- MCP smoke runner cleanup now carries PID identity metadata and revalidates it before termination.
- Windows cleanup intentionally avoids `taskkill /T`; timeout seconds are capped to positive integers within Node timer limits.
## 2026-07-06 Task 4 POSIX Identity Note

- POSIX MCP smoke cleanup must not rely on second-granularity `lstart`. Linux uses `/proc/<pid>/stat` field 22 `starttime` ticks; if high precision identity is unavailable, cleanup verification fails before terminate.

## 2026-07-06 Final Review Smoke Note

- MCP smoke verification now treats an exited server root before cleanup refresh as unverified cleanup and fails instead of reporting `smoke_verified`.
- MCP smoke operation-root deletion is guarded by a final within-parent and no-reparse check immediately before `Remove-Item -Recurse`.
- MCP smoke `timeout_seconds` remains aligned to whitelist schema `1..30` when approved snapshots are planned.

## 2026-07-12 Filesystem MCP Pilot

- `mcp.modelcontextprotocol.filesystem` 已完成受限真实部署，用户级 Codex MCP 名称为 `modelcontextprotocol-filesystem`。
- 真实启动参数为 `node E:\codex\MCP\servers\src\filesystem\dist\index.js E:\codex`，当前允许根目录限定为 `E:\codex`。
- 自动 smoke 使用 `write_file`，写入目标只允许落在本次 `.tmp\mcp-smoke\<operation>` 临时目录，并由 lifecycle cleanup 清理。
- 验证结果：static=`static_verified`，load=`load_verified`，smoke=`smoke_verified`。
- 残留核验：目标 filesystem Node 服务器进程数为 0；`.tmp\mcp-smoke` operation root 数量为 0；未发现 marker 文件残留。
- 当前工程已到“文档质量审计与整理阶段”前，下一步不应继续扩大工具接入范围，除非用户明确要求跳过文档整理。
