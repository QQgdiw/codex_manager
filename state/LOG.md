# 项目关键记录

## 2026-06-13：Task 1 测试入口审查修复

- 审查确认原基线中的 `2 + 2` 断言不能证明测试入口行为，已删除。
- 新测试将 `Run-Tests.ps1` 复制到独立临时目录，动态创建 unit/integration Pester 夹具，并通过子 PowerShell 进程检查真实退出码；临时 runner 不会发现仓库自身测试，因此不会递归调用。
- RED：入口级测试共 6 项，5 项通过；零匹配预期退出 2、实际退出 1，准确复现全局 `ErrorActionPreference = 'Stop'` 使 `Write-Error` 提前终止的问题。
- GREEN：移除全局 Stop 偏好，并使用 stderr 直接报告基础设施错误后，6 项全部通过；默认模式执行 unit 和 integration，选择器只执行目标范围，普通测试失败返回 1，零匹配返回 2。
- `.gitignore` 新增 `.env` 和 `.env.*`，并通过 `!.env.example` 保留可提交的示例配置。

## 2026-06-13：Task 1 仓库安全与测试基线

- RED：直接运行 `Baseline.Tests.ps1` 时共执行 4 项，2 项通过、2 项因 `tests/Run-Tests.ps1` 缺失而失败，确认测试能捕获缺失入口。
- GREEN：实现入口并修正 Pester 3.4 集合断言语法后，`-All` 共执行 4 项，4 项通过、0 项失败，退出码为 0。
- `-Unit` 和无参数默认模式退出码均为 0；当前没有集成测试时，`-Integration` 返回非零，未出现零测试假成功。
- Pester 3.4 的 `Should Contain` 用于检查文件内容，不适合直接检查集合成员；集合契约使用 PowerShell 原生 `-contains` 后再断言布尔值。
- 测试入口先枚举匹配的 `*.Tests.ps1` 文件；匹配数为 0、Pester 未执行测试、Pester 抛错或测试失败时均返回非零。
- `.gitignore` 保留 `.worktrees/`、`auth.json`、`.codex/auth.json` 和凭据规则，并补充测试产物、日志、Python 缓存及 `MCP/servers/node_modules/`。

## 2026-06-13：需求文档读取编码

- `需求文档.txt` 使用 UTF-8 编码。
- PowerShell 默认读取曾产生中文错译。
- 后续读取中文需求和 Markdown 文件时，应显式使用 `-Encoding UTF8`，并在需要时将控制台输出编码设置为 UTF-8。

## 2026-06-13：版本库状态

- 当前 `E:\codex` 已关联 Git 仓库 `origin/main`。
- 远程 `HEAD` 连通性已验证，当前远程提交为 `1a6c95924d3121674d1170dad15fb7a151bc5ef5`。
- `MCP/servers` 与 `Skills/AgentSkillsforContextEngineering` 是嵌套 Git 仓库，首次纳管前必须明确使用 submodule 或固定版本归档，不能直接含糊提交。

## 2026-06-13：关键风险边界

- GitHub 缺少满足本项目要求的完整官方历史周榜，2026 年既往数据可能只能近似回溯。
- 第三方系统级依赖无法保证完全回滚，必须记录未清理残留。
- 只完成静态检查的工具不得标记为完全可用。
- 凭据必须通过 Windows DPAPI 加密，禁止出现在配置、日志和版本库中。

## 2026-06-13：能力与权限审计

- 当前 Codex CLI 版本为 `0.139.0`。
- `codex plugin list` 返回无 marketplace plugin。
- `codex mcp list` 返回无已配置 MCP。
- 项目根目录 `config.toml` 不能视为当前 Codex CLI 已加载配置。
- 当前会话自带 Superpowers、浏览器、文件和文档能力，足以完成首期开发，不需要立即安装额外扩展。
- 本地 MCP 源码存在，但 Puppeteer 预期构建文件缺失；所有 MCP 均尚未在 Codex 中启用和验证。
- 沙箱内 `codex login status` 显示未登录，但沙箱外返回 `Logged in using ChatGPT`，说明用户级 `C:\Users\86178\.codex\auth.json` 可用，差异来自运行账户隔离。
- 禁止读取、输出或提交 `auth.json` 正文。认证验证只使用状态命令和脱敏诊断结果。
- Doctor 在沙箱内报告部分服务端点不可达，真实加载验证应在沙箱外和已授权网络环境复核。
- 工作区内读写权限已验证。工作区外用户 Codex 目录、联网下载、系统级安装和管理员操作需要按次申请。
- 用户已同意联网下载自动执行；首次遇到具体联网命令时应申请可复用的命令前缀授权。
- 现有 `MCP/servers` 与 `Skills/AgentSkillsforContextEngineering` 必须作为首批管理对象，和后续白名单项目一样完成来源、版本、审批、部署和分层验证。

## 2026-06-14：Task 5 安全回滚重构

- 初始 RED：定向 33 项中 5 项失败，稳定复现 junction 删除、持久化根授权、备份换绑、重复键和 16 进程并发丢记录。
- 扩展 RED：加入 Schema v2、未知字段/类型、Integrity、Confirm、FileId、delete 前置条件和耐久临时清理后，41 项中 33 项失败；主要缺口是 v1 Schema、无可信根参数、无锁和无身份确认。
- GREEN：定向 41/41、Unit 122/122、Integration 3/3、All 125/125、攻击探针 15/15。
- 路径授权必须使用调用方传入的可信 `AllowedRoots` 加默认 git 根和用户 `.codex`；日志内 `AllowedRoots` 仅用于审计并纳入完整性，不得参与授权。
- 路径采用词法规范化，不解析 reparse 目标；从匹配根到目标任一现存组件含 reparse point 即拒绝。
- create/directory_create 未确认时不得删除；确认后若 VolumeSerial/FileId 不匹配则拒绝。modify 同样要求原始身份匹配，delete 只在目标仍缺失时恢复。
- DPAPI CurrentUser 不能抵御当前用户账户完全失陷；PowerShell 路径 API 仍无法彻底消除同用户微秒级 TOCTOU，但已修复可复现的替换攻击并在关键操作前重复检查。

## 2026-06-14：Task 5 journal 存储路径加固

- 规格审查发现 journal 内部路径可通过 `.state/journals`、`backups` 或 lock 父路径 junction 写入外部目录。
- RED：新增存储路径攻击组 7 项时 3 项失败，确认 journals junction、backups junction 和 lock 父路径替换会绕过原边界；外部目录可出现 journal、backup 或 lock 文件。
- 修复统一使用 `Validate-JournalStoragePath`：所有公开入口在锁前验证，锁、journal temp 和 backup 打开前再次验证。
- 缺失 StateRoot 及其内部目录从可信根开始逐级创建，每一级创建前后检查词法边界和 ReparsePoint；禁止将 StateRoot 注册为递归删除目标。
- GREEN：存储攻击组 8/8、Target 49/49、Unit 130/130、Integration 3/3、All 133/133、组合攻击探针 23/23。

## 2026-06-24：Task 17 首批白名单审批

- 用户明确批准首批 4 项进入 `approved` 状态：`plugin.openai-bundled.browser`、`plugin.openai-curated.superpowers`、`mcp.modelcontextprotocol.sequential-thinking`、`skill.context-engineering.context-fundamentals`。
- 本次审批仅覆盖首期最小闭环所需的浏览器检索、开发工作流、顺序思考 MCP 和上下文基础 Skill；其他候选项保持 `proposed`。
- 白名单审批不等同于已部署或已动态验证；后续仍需执行计划生成、部署、静态验证、加载验证和最小调用验证。

## 2026-06-24：Task 18 部署 dry-run 与分层验证

- 沙箱内 `codex login status` 返回 `Not logged in`；沙箱外用户上下文返回 `Logged in using ChatGPT`，未读取或记录 `auth.json` 正文。
- 沙箱内 `codex doctor` 受限于 restricted network，沙箱外 `codex doctor` 返回 15 ok、0 fail，但有 update probe timeout 和 WebSocket timeout 降级警告。
- 首批 4 个 approved 工具的部署计划生成成功；白名单补充 `rollback_capability = "managed_files"` 后，`deploy -DryRun` 对 4 项全部返回 `dry_run`。
- 分层验证结果：4 项 static verification 通过；4 项 load verification 因缺少 load verifier 被阻塞；4 项 smoke verification 因 load 未通过被阻塞。
- 当前入口 `Invoke-CodexToolManager.ps1` 的部署适配器仍为 planning-only blocked adapter，Task 18 未执行真实安装，不能宣称工具已部署完成。

## 2026-06-24：Task 19 首期端到端验收

- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -All` 完成，结果为 284 passed、0 failed、0 skipped。
- `Resources/*.toml` 全部通过 `scripts/python/toml_to_json.py` 解析。
- 敏感内容扫描未发现交付记录中的明文凭据；命中项仅包括 `TODO.md` 文件名、PP 中的扫描命令样例和脚本变量 `$token`。
- PRD 覆盖核对：五类市场文档、六类场景配置、TOML 白名单、审批记录、部署 dry-run、分层验证、回滚、DPAPI、状态记录和后续路线均已有对应实现、文档或明确限制。
- 剩余限制：真实部署适配器和 load/smoke verifier 尚未接入，当前首期闭环只能证明计划、dry-run、静态验证和阻塞边界。

## 2026-06-25：市场与审批强化

- 审批辅助数据改为 TOML 主数据源，新增 `Resources/approval_review.toml` 和 `Resources/approval_review.md`；白名单部署权威仍是 `Resources/tool_whitelist.toml`。
- `Resources/plugins_market.md` 已重建，记录 CLI、本地插件缓存与 GitHub `openai/plugins` 之间的来源差异；`/plugins` UI 的 177 项仍属于人工观察口径，不能当作已程序化采集事实。
- `Resources/github_market.md` 使用 GitHub Search API 近似回溯 2026-W01 至 2026-W26，硬过滤 `stars >= 1000`，当前共收录 638 个唯一仓库。2026-W19、W21、W22、W23、W24、W25、W26 因满足条件的唯一工程候选不足而低于 20 个。
- GitHub 市场必须跨周去重：若仓库已在更早 week 收录，后续 week 跳过且不计入 20-30 个目标名额。本次按 `created_at` 周切分后未出现跨周重复，但规则和说明已写入生成逻辑与文档。
- `Resources/event_market.md` 已从泛 AI 行业事件改为工程工作流事件市场；模型训练、微调、榜单和仅强调模型能力的旧版本发布不再作为主事件。
- 本轮验证：全量测试 287 passed、0 failed；`Resources/*.toml` 全部可解析；`git diff --check` 通过；精确敏感 token 扫描无命中。
- PowerShell 5.1 直接执行无 BOM 中文脚本会触发编码解析问题；后续涉及中文文本生成的临时脚本优先使用 Python 或确保 PowerShell 脚本编码明确。

## 2026-06-25：第二批白名单审批

- 用户批准 `approval_review.md` 中建议动作为 `approve_now` 和 `needs_review` 的条目。
- 新增批准 `mcp.modelcontextprotocol.filesystem` 和 `skill.context-engineering.filesystem-context`；白名单当前共有 6 个 `approved` 工具。
- 文件系统相关条目虽然已批准，但真实部署时仍必须执行根目录约束、写入范围约束、数据最小化、静态验证、加载验证、最小功能调用验证和失败回滚记录。
- 验证结果：`Resources/tool_whitelist.toml` 与 `Resources/approval_review.toml` 均可解析；单元测试 267 passed、0 failed；`git diff --check` 通过。

## 2026-06-25：插件真实部署与 load 验证最小闭环

- 按用户确认的方案 A，只接入 plugin 类型真实路径，首批目标为 `plugin.openai-bundled.browser` 和 `plugin.openai-curated.superpowers`。
- `scripts/Invoke-CodexToolManager.ps1` 已通过结构化 Codex CLI executor 接入 `Install-ManagedPlugin`；测试使用临时 `codex.cmd` 注入 `PATH`，未调用真实用户 Codex 配置。
- `verify` 已为 plugin 附加 load verifier，通过 `codex plugin list --json` 检查插件是否可见；smoke verification 仍因缺少功能性 verifier 保守阻塞。
- Skill 和 MCP 仍保持 blocked adapter，未进入真实安装或加载验证。
- TDD 证据：plugin deploy RED 为 21 passed / 1 failed，GREEN 为 22 passed / 0 failed；plugin verify RED 为 22 passed / 1 failed，GREEN 为 23 passed / 0 failed；相关单元测试均为 267 passed / 0 failed。

## 2026-06-26：Skill 真实部署与 load 验证最小闭环

- `skill` 类型已从 blocked adapter 切换到真实 `Install-ManagedSkill`；测试使用临时 Skill source 和临时 workspace，不写入真实 `E:\codex\Skills`。
- `New-DeploymentApprovedSnapshot` 现在按工具类型保留 adapter-specific 字段：plugin 仅保留 plugin 字段，skill 仅保留 `skill_id`、`source_path`、`managed_workspace_root` 和 `skill_manifest`，避免跨适配器字段污染。
- `Test-DeploymentPlan` 会在 skill approved snapshot 含 `skill_id` 时校验 `install_target` 必须匹配 `Skills/<skill_id>`，防止计划目标和实际受管安装目录不一致。
- `verify` 已为 skill 附加 load verifier，通过受管安装目录、`SKILL.md` 和源内容 hash 验证；smoke verification 仍保守阻塞，不能宣称 Codex 运行时已实际加载并执行 Skill。
- TDD 证据：Skill fixture 24 passed / 0 failed；Skill deploy RED 为 24 passed / 1 failed，修复后 integration 为 25 passed / 0 failed，unit 为 270 passed / 0 failed；Skill verify RED 为 25 passed / 1 failed，GREEN 为 26 passed / 0 failed，unit 为 270 passed / 0 failed。

## 2026-06-27：MCP 真实部署与 load 验证最小闭环

- `mcp` 类型已从 blocked adapter 切换到真实 `Install-ManagedMcp`；测试使用临时 MCP stdio server 文件和 fake `codex.cmd`，未修改真实用户 Codex MCP 配置。
- `New-DeploymentApprovedSnapshot` 现在按 `mcp` 类型保留 `mcp_transport`、`mcp_name`、`stdio` 和 `http`，并继续隔离 plugin、skill、mcp 的 adapter-specific 字段。
- `verify` 已为 mcp 附加 load verifier，通过 `codex mcp get <name> --json` 验证 MCP 在 Codex 配置中可查询；smoke verification 仍保守阻塞，不能宣称 MCP 工具方法已被安全调用。
- TDD 证据：MCP snapshot RED 为 270 passed / 1 failed，GREEN 为 271 passed / 0 failed；MCP fixture integration 为 27 passed / 0 failed；MCP deploy RED 为 27 passed / 1 failed，GREEN 为 28 passed / 0 failed，unit 为 271 passed / 0 failed；MCP verify RED 为 28 passed / 1 failed，GREEN 为 29 passed / 0 failed，unit 为 271 passed / 0 failed。

## 2026-06-29：sequential-thinking MCP 真实环境试运行预检

- 单工具配置的 plan 和 dry-run 均成功，目标为 `mcp.modelcontextprotocol.sequential-thinking`，dry-run 未修改用户配置。
- 预检发现 `codex mcp add` 不支持工作目录参数，原适配器虽然验证了 `working_directory\startup_file`，却仍登记相对参数 `dist/index.js`，实际运行时可能在错误目录解析脚本。
- 已将与 approved `startup_file` 对应的 stdio command/argument 转换为已验证的绝对路径；RED 为 269 passed / 2 failed，GREEN 为 271 passed / 0 failed，最终全量测试为 300 passed / 0 failed。
- 使用真实 Codex CLI `0.142.4` 和临时 `CODEX_HOME` 完成 `mcp add`、`mcp get --json`、`mcp remove`；查询结果确认参数为 `E:\codex\MCP\servers\src\sequentialthinking\dist\index.js`，临时配置已移除该 MCP。
- 用户级真实部署尚未执行：提升权限命令在 30 秒内未创建 START 标记或日志，说明命令没有进入真实用户执行通道。本轮没有修改用户级 Codex 配置。
- 临时 `.tmp` 目录被残留 runner 占用，已加入 `.gitignore` 防止误提交；待进程释放后再清理。

## 2026-06-29：sequential-thinking MCP 用户级真实部署与验证

- 权限恢复后重新执行单工具 plan 和 dry-run，二者退出码均为 0；计划仅包含 `mcp.modelcontextprotocol.sequential-thinking`。
- 部署前真实用户配置中不存在 `modelcontextprotocol-sequential-thinking`；部署命令退出码为 0，未产生标准错误。
- `codex mcp get modelcontextprotocol-sequential-thinking --json` 确认配置已启用，transport 为 stdio，command 为 `node`，参数为绝对路径 `E:\codex\MCP\servers\src\sequentialthinking\dist\index.js`；原有 MCP 配置未被删除。
- 管理器验证结果为 static=`static_verified`、load=`load_verified`、smoke=`blocked`；整体退出码为 1 的原因是尚未接入自动 smoke verifier，错误码为 `smoke_verifier_missing`，不是部署或 load 失败。
- 使用本地 `@modelcontextprotocol/sdk` 1.29.0 独立连接已部署服务器，完成初始化、`tools/list` 和一次低副作用 `sequentialthinking` 调用；进程退出码为 0，公布工具为 `sequentialthinking`，返回内容类型为 `text`。
- 当前最高证据为“人工协议 smoke 通过”；管理器自动 smoke verifier 仍待实现。由于 load 与人工 smoke 均成功，本次未执行回滚，也没有已知残留子进程。
