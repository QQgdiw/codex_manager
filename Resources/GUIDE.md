# 项目协作与市场维护指南

本文档说明当前成果、五份市场文档的职责，以及你在后续更新、审批和真实部署时需要做什么。

## 当前状态

- 首期基础闭环已经完成，市场采集、白名单审批、场景配置、部署计划、分层验证、回滚和凭据保护均有受管入口。
- `plugins_market.md`、`github_market.md`、`MCP_market.md` 和 `tool_market.md` 已完成首轮质量重建。
- `event_market.md` 已按工程工作身份重建为经过官方来源复核的事件档案；更新方式为按需手动触发。
- 2026-07-15 的只读核对中，当前 Codex 只注册了未纳入项目白名单的 `node_repl`。filesystem 与 sequential-thinking 曾通过 static/load/smoke 验证，但当前未注册；重新部署并再次验证前不能称为当前可用。
- approved context-engineering Skill 的当前受管目标不存在，没有功能性 smoke 证据。
- 最新测试数量和阶段结论以 `state/README.md`、`state/TODO.md` 和 `state/LOG.md` 为准，不在本指南固化容易过时的计数。

## 文档职责

| 文档 | 用途 | 权威来源 |
| --- | --- | --- |
| `Resources/plugins_market.md` | 当前账户和工作区可见的完整 Plugins 目录，以及研发者重点索引 | Codex app-server `plugin/list` 的同次完整响应 |
| `Resources/github_market.md` | 从 2026-W01 起按周整理、跨周去重的工程开源项目档案 | GitHub 公开元数据、可验证历史来源和明确标注的 C 级近似回溯 |
| `Resources/MCP_market.md` | GitHub 总表派生的 MCP 候选和当前受管 MCP 基线 | `github_market.md`、白名单、验证记录和只读运行状态 |
| `Resources/tool_market.md` | GitHub 总表派生的 Skill/Tool 候选和当前受管 Skill 基线 | `github_market.md`、白名单、验证记录和本地受管目标 |
| `Resources/event_market.md` | 已发生、能改变用户工程工作或决策的事件档案 | 官方公告、官方文档、官方 changelog、官方 release 和标准组织来源 |

Plugins 和事件市场可以分别按需更新。GitHub 总表更新后，必须再检查 MCP 与 Tool/Skill 派生文档；后两者不得收录 GitHub 总表中不存在的派生项目，也不得重复分类同一仓库。

## 按需更新 Plugins

先生成临时候选并执行即时一致性检查：

```powershell
New-Item -ItemType Directory -Force .\.tmp\market-audit | Out-Null
node .\scripts\markets\export-plugins-market.mjs --cwd (Resolve-Path .).Path --output .\.tmp\market-audit\plugins_market.candidate.md
node .\scripts\markets\export-plugins-market.mjs --cwd (Resolve-Path .).Path --check .\.tmp\market-audit\plugins_market.candidate.md
```

人工复核采集时间、Codex 版本、marketplace 数量、原始记录数、加载错误和上游重复记录。只有采集与检查均返回 `0`、无加载错误且候选内容完整时，维护者才执行正式原子更新并立即复核：

```powershell
node .\scripts\markets\export-plugins-market.mjs --cwd (Resolve-Path .).Path --output .\Resources\plugins_market.md
node .\scripts\markets\export-plugins-market.mjs --cwd (Resolve-Path .).Path --check .\Resources\plugins_market.md
```

正式更新会重新采集一次实时目录，因此应紧接候选审阅执行，并以正式文档的采集摘要和最终 `--check` 结果作为本次证据。

失败时保留上一版 `plugins_market.md`。不得用旧 GitHub 仓库（包括 `openai/plugins.git`）、CLI snapshot（包括 `codex plugin list`）或本地缓存补齐后覆盖完整目录；这些来源只能补充说明。

## 按需更新 GitHub

GitHub 采集器只生成待审阅 JSON，不直接生成正式 Markdown。示例：

```powershell
node .\scripts\markets\github-market.mjs collect --from YYYY-MM-DD --to YYYY-MM-DD --output .\.tmp\market-audit\github-Wxx.json
```

维护者需要逐项核验仓库、采集时 Star、许可证、工程相关性、部署条件和风险，并应用以下规则：

- 采集时必须满足 `stars >= 1000`。
- 已在早期周收录的仓库不进入后续周，也不占后续周的候选名额。
- 历史证据不足时允许 C 级近似回溯，但不能把当前 README 或 Star 写成历史周事实。
- 对用户工作没有明确帮助、且不是 Agent 框架本体研发工具的泛 Agent 项目应排除。
- 数据不足的周如实保留不足 20 条或零条，不用无关项目补数。

结构化审阅记录采用 JSONL。渲染前后执行：

```powershell
node .\scripts\markets\github-market-archive.mjs validate-curation --input .\.tmp\market-audit\curation.jsonl
node .\scripts\markets\github-market-archive.mjs render --input .\.tmp\market-audit\curation.jsonl --output .\.tmp\market-audit\github_market.candidate.md --captured-at YYYY-MM-DDTHH:mm:ss.sssZ
node .\scripts\markets\github-market.mjs validate --github .\.tmp\market-audit\github_market.candidate.md --mcp .\Resources\MCP_market.md --tool .\Resources\tool_market.md
```

当前周尚未结束时，渲染命令额外传入 `--partial-week 2026-Wxx`。采集、人工审阅、渲染或验证任一步失败，都不得覆盖正式文档。

## 更新 MCP 与 Tool/Skill 派生市场

先完成 `github_market.md`，再审阅其中可能属于 MCP、Skill 或其他 AI 工作流工具的记录。每个保留项必须写明原仓库、周次、来源等级、安装入口、运行时、凭据、权限、许可证、Codex 兼容性、风险和处理建议。

更新后统一运行：

```powershell
node .\scripts\markets\github-market.mjs validate --github .\Resources\github_market.md --mcp .\Resources\MCP_market.md --tool .\Resources\tool_market.md
```

预期结果为跨周重复 `0`、派生缺失 `0`、未标记条目 `0`，并且命令退出码为 `0`。市场文档还必须分别记录白名单审批、历史验证和当前注册/部署状态，不用较旧的验证记录覆盖较新的只读运行事实。

## 按需更新工程事件市场

事件市场不做定时抓取，仅按需手动更新。收到明确时间范围后，维护者先在 `.tmp/event-market-audit/research/` 分领域收集候选，再合并为一行一个 JSON 对象的 `.tmp/event-market-audit/curation.jsonl`。每个保留项必须已经发生，至少打开并复核一个官方一手来源，并明确它会改变哪项嵌入式、硬件、机器人、ROS、EDA/FPGA、边缘 AI、编码 Agent 或工程文档工作。

同一产品的连续小版本默认合并为阶段事件。只有权限、接口、兼容性、安全边界或工程能力发生独立重大变化时才拆分；模型训练、榜单、融资、未来承诺和泛 AI 宣传不进入正式档案。以下命令中的 `YYYY-MM-DD` 是占位符，执行前必须替换为实际开始日期、结束日期和核验日期：

```powershell
node .\scripts\markets\event-market.mjs validate-curation --input .\.tmp\event-market-audit\curation.jsonl --start YYYY-MM-DD --end YYYY-MM-DD
node .\scripts\markets\event-market.mjs render --input .\.tmp\event-market-audit\curation.jsonl --output .\.tmp\event-market-audit\event_market.candidate.md --start YYYY-MM-DD --end YYYY-MM-DD --verified-at YYYY-MM-DD
node .\scripts\markets\event-market.mjs validate-doc --input .\.tmp\event-market-audit\event_market.candidate.md --start YYYY-MM-DD --end YYYY-MM-DD
```

候选文档必须完成事实与来源、简体中文与工程价值两轮独立审阅。所有高、中问题都回到 JSONL 总账修正并重新渲染；不得只改生成的 Markdown。候选全部通过后，使用同一条 `render` 命令把输出改为 `Resources/event_market.md`，随后立即运行 `validate-doc`。

采集、人工复核、渲染或验证任一步失败，都保留上一版正式文档。用户不需要手工编辑 JSONL 或生成区，只需确认范围、审阅策展结果和指出事实或价值判断问题。事件收录仍是信息整理，不会修改白名单、批准部署或触发工具安装。

## 人工审批边界

- 市场收录是信息整理，不等于 `needs_review`、白名单 `approved`、已部署或已验证。
- `Resources/tool_whitelist.toml` 是自动部署授权的唯一机器可读来源。市场文档不能改变其审批状态。
- 维护者可以生成审批建议；将候选加入白名单、修改批准状态或执行真实部署前，需要你明确批准。
- 用户不需要手工编辑采集器生成内容、候选 JSON、JSONL 或正式 Markdown。你只需审阅语义、风险和审批建议，并给出批准或驳回结论。
- 不提供 `auth.json` 正文、Token、Cookie、密码或其他凭据内容。真实流程只引用受管凭据，不在文档或日志中记录明文。

## 真实部署边界

- 白名单批准不等于当前已注册、已部署或可调用。
- dry-run 通过不等于真实命令执行成功；load verification 通过不等于功能性 smoke 通过。
- filesystem MCP 的批准边界为根目录 `E:\codex`。扩大范围必须重新审批；smoke 写入只能位于受管临时目录并在结束后清理。
- smoke verifier 必须执行真实、最小、低副作用的功能调用。不是每个工具都必须定制 verifier；低风险工具可按明确策略停留在 static/load，只有需要证明功能调用时才增加 smoke。
- 当前场景配置的 `enabled_tools` 仍为空。启用场景前，应先确定最小工具集合，再执行计划、真实部署、验证和失败回滚。

## 你如何发起下一步

更新市场时，请给出目标和时间范围，例如：

```text
按需更新 2026-W30 GitHub 市场，并同步复核 MCP 与 Tool/Skill 派生文档。
```

审批候选时，请明确条目和动作，例如：

```text
批准 approval_review.md 中指定条目的建议动作，并同步白名单。
```

真实部署时，请明确目标，例如：

```text
重新部署并验证 filesystem MCP，保持允许根目录为 E:\codex。
```
