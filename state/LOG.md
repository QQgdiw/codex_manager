# 项目关键记录

## 2026-07-18：事件市场重建设计

- 核实 `Resources/event_market.md` 共 186 行，但内容仅为收录边界、候选类别、维护规则和输出模板，没有经本轮联网核验的正式事件条目。
- 用户确认覆盖 2026-01-01 至 2026-07-18；目标约 35 项但以价值为准，避免凑数和过度排除；只收录已实际发生且至少有一个官方一手来源的事件。
- 采用“组织归档 + 主题索引”：正文同组织归组、组内日期倒序；跨领域事件只保留一个正文主条目，可进入多个主题索引。
- 同一产品的连续小版本合并为阶段性事件；只有权限、接口、兼容性、安全边界或工程能力发生独立重大变化时拆分。
- 设计说明提交为 `docs/superpowers/specs/2026-07-18-event-market-rebuild-design.md`；正式调研和文档重建须等待用户审阅设计并确认实施计划。
- 用户已审阅确认设计；实施计划提交为 `docs/superpowers/plans/2026-07-18-event-market-rebuild.md`，拆分为验证器、三组调研、主代理裁决、两轮内容审阅、正式提升和最终交付 8 个任务，当前等待用户确认执行。
- 用户已确认实施计划；Task 1 由独立实现代理按 TDD 执行，写入范围仅限事件市场脚本与测试，正式事件文档和三个状态文件仍由主代理负责。
- Task 1 已完成：`scripts/markets/event-market.mjs` 支持 JSONL 策展校验、确定性组织归档与多主题索引、严格文档反向校验和原子写入；正式事件标记保持计划约定的 JSON 契约，并对 HTML 注释与 Markdown 块语法做安全编码。
- 四轮针对性返修关闭了字段注入、anchor 冲突、输入输出同文件破坏、物理行号、跨环境排序、索引/正文绑定、头部规则、路径别名和多主题索引等问题。最终主代理复验 Node 23/23、Pester 6/6、`node --check` 和 `git diff --check` 均通过，独立复审无高、中问题。
- 已知低风险边界：文件身份检查与最终原子替换之间仍存在同用户并发写入导致的 TOCTOU 窗口；当前按需手动、单用户策展流程不扩大该风险，也不将其表述为完全消除。
- Tasks 2-4 由三个独立调研代理并行完成：Agent/扩展生态 25 条（初筛 keep 21）、机器人/ROS 14 条（初筛 keep 8）、硬件工程 25 条（初筛 keep 22）。每个临时总账均由代理和主代理分别运行 `validate-curation`，退出码均为 0。
- 三份临时总账合计 64 条候选、36 个组织；跨文件重复 ID、重复官方来源 URL 和重复 keep `mergeKey` 均为 0。代理初筛不代表正式收录，Task 5 仍须由主代理重新打开来源、合并连续版本并执行工程价值裁决。
- Task 5 由主代理逐项 GET 64 个原始官方 URL，全部成功；另打开 PX4、MuJoCo、Isaac ROS 辅助来源和 Anthropic 官方 changelog。事实关键词审计覆盖拟保留的底层事件，并对审计未命中的条目逐项读取正文复核。
- GitHub 页面机器可读 UTC 时间显示 9 条候选日期需要修正；Isaac ROS 4.5 采用官方发布索引明确写出的 2026-07-06，而不是 GitHub tag 的后续创建时间。最终总账为 69 条记录，其中 34 keep、35 exclude，5 个阶段事件合并了 15 条连续版本候选。
- 候选文档已渲染为 834 行并通过 `validate-doc`；事实一致性与简体中文质量两轮独立审阅仍在执行，不能将候选视为正式文档。
- Task 6 首轮事实审阅发现 4 个中问题：Agentic Autofix 被夸大为跨仓库、TensorRT 样例与插件混淆、PX4 Zenoh 缺少实验性限定、Zephyr 普通维护补丁缺乏独立事件粒度；中文审阅发现 5 条阶段记录机械拼接、优先级膨胀和导航不足。全部问题均回写 JSONL 总账，Zephyr 改为 exclude，最终为 33 keep、36 exclude。
- 最终 33 项中 priority 为 high 18、medium 15。工程文档方向仅 1 项通过来源与价值复核，正式文档明确披露该限制，没有用泛文档 AI 新闻补数。
- 事件渲染器新增面向工程身份的主题顺序、主题引用计数、组织导航、组织排序说明和稀疏覆盖提示，并强化重复主题、正文/索引主题绑定、组织块顺序、异常 Unicode 和提示条件校验。代码复审发现的 3 个中问题和 2 个低问题均已修复，真实 EDA 主题组合回归通过。
- `Resources/event_market.md` 已从同一总账原子生成，共 33 个事件标记；与最终候选逐字节一致。`Resources/GUIDE.md` 和 `Resources/PP.md` 已加入按需手动更新、官方来源复核、连续版本合并、失败保留旧版和市场不产生部署授权的真实维护流程。Task 7 专项审阅无高、中问题。
- Task 8 最终独立审阅发现 2 个中问题：来源 `verifiedAt` 被错误限制在事件覆盖期内，以及 `validate-doc` 未严格校验协作方、来源元数据和章节唯一性。两项均按 TDD 修复，原审阅者复跑覆盖期后复核日期、删除协作方、伪造来源类型/日期、重复章节和非结构化来源文本反例后确认关闭；最终独立审阅无高、中问题。
- 修复后最终验收：事件 Node 测试 31/31、市场 Pester 6/6；四个市场 Node 测试 67/67；Pester `-All` 362/362，通过，耗时约 225 秒；正式文档 `validate-doc` 返回 33；`git diff --check` 通过；Resources、Notes、state、scripts、tests 的凭据模式扫描 0 命中。
- 当前限制：文件身份检查与原子替换之间仍有同用户并发写入 TOCTOU 低风险；工程文档主题本期覆盖仅 1 项；调研 JSONL、下载正文和来源审计位于 `.tmp/`，作为本次工作证据而非长期提交内容，后续按需更新必须重新采集和复核。

## 2026-07-15：市场文档质量审计完成

- `Resources/GUIDE.md` 已改为四份重点市场文档的维护与协作入口，说明文档职责、更新顺序、真实命令、人工审阅点、失败保留旧版和白名单审批边界。
- PRD 与 PP 已统一职责：`MCP_market.md` 负责 MCP 派生候选和受管 MCP 基线，`tool_market.md` 负责 Skill/Tool 派生候选和受管 Skill 基线；市场收录不改变白名单。
- 使用 Codex CLI `0.144.4` 的真实 app-server `plugin/list` 原子刷新 `plugins_market.md`：1 个 marketplace、2,039 条记录、加载错误 0；正式目录即时 `--check` 通过。
- 采集器现在优先记录 `initialize.serverInfo.version`，缺失时通过受控 `codex --version` 回溯；版本查询超时或输出超限会终止进程树，Windows `.cmd` 真实挂起测试确认后代 Node PID 已退出。`taskkill` 失败会明确返回 `codex_version_cleanup_failed`，不把降级清理误报为成功。
- 最终验证：Plugins 一致性检查退出 0；GitHub 236 条记录、跨周重复 0、派生缺失 0、未标记条目 0；Node 36/36、Pester `-All` 361/361；`git diff --check` 通过，真实形态 key/token 扫描 0 命中。
- 宽模式敏感扫描唯一 `auth.json {…}` 命中位于日志脱敏测试夹具，使用 `RAW-AUTH-TOKEN` 占位符，并由测试断言不进入结果；未读取任何真实认证文件正文。

## 2026-07-15：MCP 与工具派生市场重建

- 对 GitHub 总表中的 66 条 MCP、Skill、Codex 或 Agent 相关候选进行分类审阅；MCP 派生候选为 0，工具与 Skill 市场保留 `Weizhena/Deep-Research-skills` 和 `Dimillian/CodexMonitor` 两条 `needs_review` 候选，其余 64 条排除。
- 市场文档严格区分白名单审批、历史验证和当前运行状态。filesystem 与 sequential-thinking 虽为 `approved` 且曾通过 static/load/smoke，但 2026-07-15 的 `codex mcp list` 中未注册；两个 approved context-engineering Skill 的当前受管目标均不存在。
- 独立规格与中文质量复审后，修正了候选权限边界、`node_repl` 受管归属、proposed Skill 逐项可追溯性和源码哈希证据措辞。
- 派生验证通过：236 条 GitHub 记录、跨周重复 0、派生缺失 0、未标记条目 0；Node 测试 15/15、Pester unit 312/312 通过。

## 2026-07-15：Windows PowerShell 测试启动方式

- 通过当前 PowerShell 进程使用 `Start-Process powershell.exe` 执行 Pester 曾产生 60 个模块加载失败，包括 `Get-FileHash` 不可用和 Security TypeData 重复；同一工作树改用直接 `powershell.exe ...` 子进程后，定向测试 57/57、完整 unit 312/312 通过。
- 后续 Windows PowerShell 5.1 回归应使用直接子进程并重定向输出，不用 `Start-Process` 包裹测试入口；遇到同类模块错误先做独立命令探针和定向重跑，不能误报为代码回归。

## 2026-07-15：GitHub 历史档案正式重建

- W01-W29 共审阅 658 条唯一候选，保留 236 条、排除 422 条；正式文档包含 29 个周标题和 236 个 `github-record` 标记。
- W15、W16、W26 为零保留周；W29 是截至 2026-07-15 的部分周且原始候选为 0。零记录周仍必须渲染，不能因验证器只统计有标记周而从文档省略。
- 正式验证结果为跨周重复 0、派生缺失 0、未标记条目 0；236 个保留项的中文字段、GitHub 链接和 C 级来源均完整，敏感信息扫描 0 命中。
- 最终回归为 GitHub Node 7/7、归档 Node 8/8、Pester unit 312/312。

## 2026-07-15：GitHub 历史档案重建范围

- 旧 `github_market.md` 的 W01-W26 是 638 条粗粒度近似候选表，缺少可解析标记，并含有当前排除规则不允许的项目；不能仅追加 W27-W29 后宣称文档已完成质量重整。
- 用户确认 W01-W26 也必须逐项重审。没有可验证历史榜单证据的历史项采用 C 级近似回溯，当前 README 或仓库元数据不得被写成历史周事实。

## 2026-07-15：GitHub 市场采集与派生验证

- GitHub Search 采集请求和结果都必须限制 `stars >= 1000`；分页响应只能提供后续页码，后续 URL 必须从初始受控查询重新构造，不能接受响应中改变的查询条件。
- `github-record` 日期与 `capturedAt` 必须作严格日历校验，不能只依赖 JavaScript 对日期字符串的规范化解析。
- MCP 与工具市场的派生冲突以规范化仓库名和周次为身份，不包含 `kind`；同一项目不得通过分别标记 `mcp` 和 `tool` 绕过跨市场排重。

## 2026-07-15：Plugins 目录正式重建

- 正式文档由同次 app-server `plugin/list` 原子生成，包含 2,034 条记录和 1,047 条重点索引；每条重点索引均携带完整清单中的 `recordKey`，用于区分同一插件 ID 的上游重复记录。
- 本次响应中 `metabase@openai-curated-remote` 保留两条版本、可用状态不同的记录，不能按插件 ID 去重。
- `tests/Run-Tests.ps1 -Unit` 的完整运行时间受当前机器负载影响较大；本次通过运行耗时约 197 秒、310 通过且 0 失败。外层自动化超时应预留至少 300 秒，不能把 120 或 240 秒的外层中止误报为测试失败。

## 2026-07-15：Plugins 真实 interface 元数据

- app-server `plugin/list` 的展示名称、简述、开发者、类别、能力和网站等字段位于 `plugin.interface`，不能只读取顶层、manifest 或 metadata。
- 上游类别使用 `Developer Tools`、`Data & Analytics`、`Productivity`、`Communication` 等多词值；类别映射必须支持精确值，重点索引再结合插件标识、关键词和描述分组。
- 目录会随当前 Codex 环境变化；本次临时真实采集返回 1 个 marketplace、2,033 条记录。该数量只能作为本次采集证据，不能固化为后续成功阈值。

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

## 2026-07-06：自动 MCP smoke verifier Task 1-4

- Task 1 已扩展白名单 smoke schema，并将批准的 smoke profile 纳入 approved snapshot。后续审批快照必须保留数组形状，避免空数组丢失或单元素数组标量化。
- Task 2 已为受管进程增加 `ClearEnvironment`、`Environment` 和 `WorkingDirectory` 支持；清空后只传入显式环境变量，不能隐式恢复宿主 `SystemRoot`。
- Task 3 已允许适配器注入 `StaticVerifier`；异常路径必须传入敏感值脱敏列表，存在但类型错误的 `StaticVerifier` 必须失败，不能按未配置静默跳过。
- Task 4 已实现通用 Node MCP stdio smoke runner。runner 必须忽略服务端 stderr 以避免背压和敏感诊断泄漏，必须对输入结构和超时做显式校验，必须在成功、失败、超时路径执行有界进程树清理并检查残留。
- Task 4 的最终质量复核因子代理额度限制改由主会话人工完成；验证证据为 `node --check scripts/node/mcp-smoke-runner.mjs` 通过、目标集成测试 14/14 通过、全量 integration 43/43 通过、`git diff --check` 无输出。
## 2026-07-06 Task 4 cleanup identity hardening

- Review issue: `scripts/node/mcp-smoke-runner.mjs` kept bare PID lists and terminated them later, which could kill reused PIDs. Windows `taskkill /T /F` could also expand into an unrelated current process tree.
- RED evidence: `.task4-red-mcp-smoke.log` showed 4 expected failures: Windows terminate args still included `/T`, cleanup identity probe APIs were missing, and fractional/oversized timeout requests were accepted.
- Fix: process snapshots now include `startedAt` identity data from Windows CIM `CreationDate` or POSIX `ps ... lstart`; cleanup re-snapshots and matches identity immediately before each terminate/force-terminate action.
- Fix: Windows termination is now `taskkill.exe /PID <pid> /F` per verified process, not `/T`; stale/reused PIDs are treated as non-matching and are not terminated.
- Fix: `timeoutSeconds` must be an integer from 1 through 2147483 seconds; invalid values return `mcp_smoke_invalid_request`.
- GREEN evidence: `.task4-green-mcp-smoke.log` passed 16/16, `.task4-node-check.log` exit code 0, and `.task4-diff-check.log` exit code 0 with only a CRLF warning from Git.
## 2026-07-06 Task 4 POSIX start tick hardening

- Review issue: POSIX `lstart` is commonly second-granularity, so matching only `pid + lstart` can still misidentify a same-second reused PID.
- RED evidence: `.task4-posix-red-mcp-smoke.log` failed 5 expected checks, including same-second different `startTick` being terminated and missing high precision identity not returning `mcp_smoke_cleanup_failed`.
- Fix: Linux process snapshots now prefer `/proc/<pid>/stat` and use field 22 `starttime` as `startTick`; the portable `ps` fallback only supplies topology and is not considered kill-verifiable on POSIX.
- Fix: non-Windows cleanup identity requires `startTick`; if the expected or current process lacks it while the PID exists, cleanup throws `mcp_smoke_cleanup_failed` before any terminate call.
- GREEN evidence: `.task4-posix-green-mcp-smoke.log` passed 18/18, `.task4-posix-node-check.log` exit code 0, and `.task4-posix-diff-check.log` exit code 0 with only a CRLF warning from Git.

## 2026-07-06 Final review smoke hardening

- Runner cleanup pitfall: a detached child spawned after the initial process snapshot is unprovable if the root process exits before the cleanup refresh. In that state the runner must return `mcp_smoke_cleanup_failed` or residual failure, never `smoke_verified`.
- Adapter cleanup pitfall: `Remove-Item -Recurse` must not run until the operation root is freshly proven below `Plan.TempRootParent` and the parent/root path chain has no reparse point.
- Timeout schema pitfall: approved snapshots consumed by `Get-McpSmokePlan` must keep the whitelist `timeout_seconds` bound at 1..30, not widen it to runner/runtime limits.

## 2026-07-06：sequential-thinking MCP 自动 smoke 验证闭环

- 重新生成单工具 pilot 配置并执行 plan：退出码 0，计划条目 1，Errors 为空。
- 初次 verify 失败在 load 层：`codex mcp get modelcontextprotocol-sequential-thinking --json` 返回未找到该 MCP。根因是真实用户级 Codex MCP 配置中当时只存在 `node_repl`，sequential-thinking 条目已不存在。
- 使用管理器 `deploy -PlanPath .\.tmp\real-pilot\auto-smoke-plan.json` 重新部署 approved sequential-thinking MCP，部署状态为 `succeeded`；未手写 `codex mcp add`。
- 重新执行 verify 后整体状态为 `succeeded`：static=`static_verified`、load=`load_verified`、smoke=`smoke_verified`。
- 真实配置核验：`modelcontextprotocol-sequential-thinking` enabled=true，transport=`stdio`，command=`node`，args 为绝对路径 `E:\codex\MCP\servers\src\sequentialthinking\dist\index.js`。
- 残留核验：目标 sequential-thinking Node 服务器进程数量为 0；`.tmp\mcp-smoke` operation 子目录数量为 0。
- 记录边界：自动 smoke 只记录工具名、内容类型和错误码，不记录完整 thought 或 MCP 返回正文；Node permission 不提供网络硬隔离；verifier 不执行卸载。

## 2026-07-12：filesystem MCP 真实接入与 rollback 锁等待

- filesystem MCP 已接入自动 smoke：白名单启动参数从 `dist/index.js` 扩展为 `dist/index.js`, `E:\codex`，真实 Codex 配置核验显示 args 为绝对 `dist\index.js` 路径加 `E:\codex`。
- filesystem smoke 使用通用 MCP runner 调用 `write_file`，参数中的 `${MCP_SMOKE_TEMP_ROOT}` 会在运行时替换为本次 operation root，避免静态白名单写死临时路径。
- 生命周期脚本 `scripts/smoke/mcp/filesystem.mjs` 校验结果状态、内容类型、`write_file` 广告工具和 marker 文件内容，cleanup 删除 marker 与 result。
- 临时 TOML 配置不能用 Windows PowerShell 5 的 `Set-Content -Encoding UTF8` 生成；该方式会写入 BOM，当前 TOML 转换器会在第 1 列报 `Invalid statement`。临时 TOML 应使用 UTF-8 no BOM 或补丁方式生成。
- PowerShell 外层调用 `-Command` 时，`$r`、`-join " | "` 等片段容易被外层解释或破坏；复杂命令优先写成脚本文件或使用单层、简单输出。
- 全量测试首次失败在 rollback 并发写入用例：32 个子进程竞争同一 journal lock 时，30 秒等待上限在当前机器负载下会触发 `Change journal is busy.`。将锁等待上限提高到 120 秒后，单项 rollback 集成测试和全量测试均通过。
- 最终验证：filesystem 真实 verify 结果为 static=`static_verified`、load=`load_verified`、smoke=`smoke_verified`；目标 filesystem Node 进程数为 0；`.tmp\mcp-smoke` operation root 数量为 0；全量测试 `356 passed / 0 failed`。

## 2026-07-13：Plugins 市场资料源核实

- 本机 Codex CLI 版本为 `0.144.1`；`codex plugin list --available --json` 返回 183 个可用插件，其中 `openai-curated` 本地 snapshot 为 179 个。
- 通过 Codex app-server JSON-RPC `plugin/list` 成功取得 4 个 marketplace、1984 条插件记录，marketplace 加载错误为 0；其中 `openai-curated-remote` 为 1974 条。
- `metabase@openai-curated-remote` 返回两条不同版本、不同 `remotePluginId` 和不同 availability 的记录，因此原始记录数为 1984，唯一限定 ID 数为 1983。后续采集不得直接按插件 ID 破坏性去重。
- 已确认 `openai/plugins.git` 和 CLI marketplace snapshot 不能代表 `/plugins` 完整目录。后续以 `plugin/list` 为唯一收录权威，其他仓库只用于补充信息。
- app-server 接口仍属实验性能力；后续采集器必须执行版本记录、结构校验和失败时不覆盖上一版有效文档的保护。

## 2026-07-14：市场文档质量审计实施计划

- 用户已审阅并确认市场文档质量审计设计，无需继续澄清设计边界。
- 实施计划拆分为 Plugins 采集器、需求口径、完整插件目录、GitHub 工具链、GitHub 文档、MCP/工具派生文档和最终跨文档审计七个任务。
- 执行方式沿用用户此前确认的子代理驱动；子代理不得修改 `state/`，正式文档共享文件由主代理合并，避免并行写入冲突。
- 市场工具链使用 Node.js 标准库，不增加第三方依赖；PowerShell 5.1 仅保留用于现有 Pester 3.4 测试入口。
- 用户确认子代理实现提交与主代理状态提交分离。子代理不得修改三个正式状态文件；确需提交状态材料时只能写入 `state/subagents/<task>/`，由主代理汇总。

## 2026-07-14：Task 1 Plugins 目录采集器

- 新增 `scripts/markets/plugin-catalog.mjs` 和 `scripts/markets/export-plugins-market.mjs`，通过 app-server JSON-RPC 采集 `plugin/list`，在完整校验后使用同目录临时文件和 rename 原子更新目标文档。
- 记录身份使用 marketplace、插件 ID、`remotePluginId`、版本四元组的 SHA-256；相同插件 ID 的不同上游记录不会被破坏性去重。
- 首轮审查发现匹配 ID 的消息未严格校验 `jsonrpc = 2.0` 和 `result/error` 互斥；修复后增加失败关闭测试。
- 第二轮审查发现合法 `id: 2` 响应可在 `plugin/list` 请求发出前被接受；修复为显式请求状态机，乱序响应立即失败且不覆盖 sentinel 输出。
- `--check` 模式已覆盖记录键或数量不一致时退出码 4，且不会改写被检查文档。
- 最终独立验证：两个 `node --check` 退出 0；Node 测试 10 passed / 0 failed；Pester unit 308 passed / 0 failed。真实账户目录生成保留到 Task 3 执行。

## 2026-07-14：Task 2 Plugins 资料源合同

- `Resources/PRD.md` 已将 app-server `plugin/list` 定义为唯一完整清单来源；所有返回记录进入完整清单，研发相关性只影响重点索引，并明确账户/工作区可见性、原始重复保留和失败不覆盖。
- `Resources/PP.md` 已用 Task 1 采集器的候选输出、正式输出和 `--check` 命令替代旧仓库克隆步骤；`Resources/GUIDE.md` 增加按需更新步骤并明确无需提供 `auth.json` 正文。
- 两份 2026-06-25 历史设计/计划仅增加被新设计取代的提示，历史正文未改写。
- 首轮审查发现合同测试只匹配孤立关键词，不能阻止旧来源回退。修复后，同一验证器既检查真实文档，也检查故意违规的内存样本。
- 独立验证：违规探针按预期退出 1，并指出 `codex plugin list` 完整目录替代违规；正常 Pester unit 为 310 passed / 0 failed。

## 2026-07-15：Task 1 真实 Codex app-server 兼容性修复

- Task 3 首次真实采集发现 Windows 默认 `codex` shim 无法被 Node 直接 spawn，且真实 app-server 成功响应没有 `jsonrpc` 字段。Codex 0.144.1 生成的 response/error schema 也确认该字段不是必需项。
- 响应校验改为允许缺失 `jsonrpc`，若字段存在则必须为 `2.0`；仍严格要求 result/error 互斥、错误对象 code/message、请求顺序、无效结果失败关闭和不覆盖输出。
- Windows `.cmd/.bat` shim 改由受控 `cmd.exe` 直接启动，固定 `/d /v:off /s /c` 与 `app-server --stdio` 参数；拒绝换行、引号和 cmd 元字符路径。未使用 Node `shell` 选项，避免 `DEP0190` 安全弃用警告。
- 一度误提交 `.superpowers/sdd/task-1-report.md`；后续仅取消 Git 跟踪并保留本地 ignored 报告，最终净差异不再包含 `.superpowers/`。
- 独立验证：`NODE_OPTIONS=--throw-deprecation` 下 Node 15 passed / 0 failed；Pester unit 310 passed / 0 failed；默认真实采集成功生成临时目录文档。
