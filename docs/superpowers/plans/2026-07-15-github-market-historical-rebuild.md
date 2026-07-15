# GitHub 市场历史重建实施计划

> **面向智能体执行者：** 必须使用 `superpowers:subagent-driven-development`，每个任务完成后执行实现审查和独立验证。

**目标：** 将 `Resources/github_market.md` 从 W01-W29 的粗粒度候选表重建为逐项审阅、可验证来源、跨周去重的研发项目档案。

**架构：** 先从旧表格提取不修改原文档的临时候选总账，再将分批语义审阅结果写为结构化临时记录。归档渲染器只接受审阅通过的记录，生成带 `github-record` 标记的中文 Markdown。现有验证器检查标记、Star、来源等级、跨周重复和派生关系；新增结构规则阻止未标记项目标题进入正式档案。

**技术栈：** Node.js ESM、Node Test、PowerShell 5.1/Pester 3.4、GitHub REST API、Markdown、JSON 临时审阅材料。

## 全局约束

- 不改变 `Resources/tool_whitelist.toml`、审批、部署或回滚状态。
- 人类可读 Markdown 使用简体中文；URL、仓库标识和官方原文可保留原语言。
- 所有收录项必须满足采集时 `stars >= 1000`；不足 20 条的周如实记录，不补入无关项目。
- 同一规范化 `owner/name` 只有一个正式主条目，跨周重复不计入后续周数量。
- 无历史榜单证据的记录为 C 级近似回溯；当前 README 不能被写成历史事实。
- API、解析、审阅或硬校验失败时不得覆盖 `Resources/github_market.md`。
- 子代理只能写 `.tmp/market-audit/` 的独占材料，不得修改 `Resources/*.md` 或正式状态文件。
- 不读取、输出或提交 `auth.json`、令牌、Cookie、API key 或本地凭据路径。
- 完整 Pester 外层超时至少 300 秒。

---

### Task 1：强化正式档案结构验证

**文件：** 修改 `scripts/markets/github-market.mjs`、`tests/node/github-market.test.mjs`、`tests/unit/MarketScripts.Tests.ps1`。

**接口：** `validateMarketDocuments({ github, mcp, tool })` 的 `summary` 增加 `unmarkedEntries`。每个 `### owner/name` 到下一个同级或更高标题之间必须恰有一个 `github-record` 标记；缺失或重复均返回带文件和行号的硬错误。

- [ ] 写入失败测试：`### owner/example` 没有标记时，断言 `github.md:1: entry has no github-record marker`。
- [ ] 运行 `node --test .\tests\node\github-market.test.mjs`，确认 RED。
- [ ] 逐行实现标题和标记邻接检查；只有仓库形式标题参与检查，周标题不参与。
- [ ] 运行 `node --check .\scripts\markets\github-market.mjs`、Node 测试和 `MarketScripts.Tests.ps1`，确认 GREEN。
- [ ] 提交：`git commit -m "feat[market]: validate github archive structure"`。

### Task 2：实现历史提取与归档渲染器

**文件：** 新建 `scripts/markets/github-market-archive.mjs`、`tests/node/github-market-archive.test.mjs`；修改 `tests/unit/MarketScripts.Tests.ps1`。

**接口：**

```js
extractLegacyCandidates(markdown) // -> Candidate[]
validateCurationRecords(records) // -> { kept, excluded, errors }
renderGitHubMarketArchive({ records, capturedAt, partialWeeks }) // -> string
```

提供 CLI：`extract --input <md> --output <json>`、`validate-curation --input <ndjson>`、`render --input <ndjson> --output <md> --captured-at <ISO>`。写入必须使用临时文件加 rename。

- [ ] 写入失败测试：提取旧表格的 `week`、`repository`、`stars`；拒绝 Star 小于 1000、跨周大小写重复、缺少中文风险字段、无效 ISO 周和非原子写入失败。
- [ ] 运行 `node --test .\tests\node\github-market-archive.test.mjs`，确认模块缺失的 RED。
- [ ] 实现旧表格解析、审阅记录校验和渲染。审阅 NDJSON 的保留记录必须含 `week`、`repository`、`stars`、`sourceLevel`、`link`、`projectType`、`weekBasis`、`coreFunction`、`workflow`、`input`、`output`、`deployment`、`risk`、`reason`；排除记录必须含 `exclusionReason`。
- [ ] 渲染器按 W29 到 W01 输出周摘要、候选不足说明、三级标题和紧邻 `github-record`；W29 标注为部分周。
- [ ] 运行 Node 两组测试和市场脚本 Pester，确认全绿。
- [ ] 提交：`git commit -m "feat[market]: add github archive renderer"`。

### Task 3：冻结候选总账

**文件：** 仅临时文件：`.tmp/market-audit/github-legacy-candidates.json`、`.tmp/market-audit/github-W01-W10.ndjson`、`.tmp/market-audit/github-W11-W20.ndjson`、`.tmp/market-audit/github-W21-W29.ndjson`、`.tmp/market-audit/github-ledger-summary.md`。

- [ ] 运行：

```powershell
node .\scripts\markets\github-market-archive.mjs extract --input .\Resources\github_market.md --output .\.tmp\market-audit\github-legacy-candidates.json
```

- [ ] 使用 `github-market.mjs collect` 重新采集 W27、W28 和截至实际采集日的 W29；任一限流或网络错误即停止。
- [ ] 合并旧候选与新 JSON，按小写仓库键去重。后续周重复项写为 `exclude`，理由固定为“跨周重复，主条目在 YYYY-Www”。
- [ ] 输出总候选数、唯一仓库、跨周重复和各周候选数；无效行非零时停止后续审阅。

### Task 4：分批审阅 W01-W10

**文件：** `.tmp/market-audit/reviews/W01-W10/<slice>.ndjson` 与 `summary.md`。

- [ ] 将候选按每片最多 30 条划分并分派子代理。每个子代理只读候选、PRD 和公开 README，写独占 NDJSON。
- [ ] 每条记录都必须得到 `keep` 或 `exclude`；保留项补齐 Task 2 全部字段，排除项说明具体原因。
- [ ] 主代理复核安全、模型、金融、创作、消费和泛 agent 边界项；无法证明具体研发用途时排除。
- [ ] 运行：`node .\scripts\markets\github-market-archive.mjs validate-curation --input .\.tmp\market-audit\reviews\W01-W10\*.ndjson`，要求没有缺失候选、重复保留或字段缺失。

### Task 5：分批审阅 W11-W20

**文件：** `.tmp/market-audit/reviews/W11-W20/<slice>.ndjson` 与 `summary.md`。

- [ ] 按 Task 4 相同规则审阅 W11-W20；候选少于 5 条的周由主代理逐条复核。
- [ ] 运行对应 `validate-curation` 命令，要求 0 个缺失候选、0 个重复保留和 0 个缺字段。

### Task 6：分批审阅 W21-W29

**文件：** `.tmp/market-audit/reviews/W21-W29/<slice>.ndjson` 与 `summary.md`。

- [ ] 按 Task 4 相同规则审阅 W21-W29，将已有 W27-W29 初审材料转换为 Task 2 的 NDJSON 格式。
- [ ] W29 必须保留“截至采集日的部分周数据”事实，即使没有符合门槛的候选。
- [ ] 运行对应 `validate-curation` 命令，要求 0 个缺失候选、0 个重复保留和 0 个缺字段。

### Task 7：候选文档、正式更新和质量审计

**文件：** 临时 `.tmp/market-audit/github_market.next.md`；修改 `Resources/github_market.md`。

- [ ] 合并三批已验证 NDJSON，运行：

```powershell
node .\scripts\markets\github-market-archive.mjs render --input .\.tmp\market-audit\github-curation.ndjson --output .\.tmp\market-audit\github_market.next.md --captured-at 2026-07-15T00:00:00.000Z
node .\scripts\markets\github-market.mjs validate --github .\.tmp\market-audit\github_market.next.md
```

- [ ] 每周抽样首条和末条；候选少于 5 条的周逐条检查链接、中文字段、Star 表述、来源等级、部署条件和风险。
- [ ] 仅在候选验证成功后以原子方式替换正式文档，再运行 `node .\scripts\markets\github-market.mjs validate --github .\Resources\github_market.md`。
- [ ] 运行 `node --test .\tests\node\github-market.test.mjs`、`node --test .\tests\node\github-market-archive.test.mjs`、`powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit`。
- [ ] 更新三个正式状态文件，记录候选、保留、排除、重复、不足周、W29 部分周和 C 级限制。
- [ ] 分两次提交：代码使用 `feat[market]: support github archive rebuild`；文档和状态使用 `docs[market]: rebuild github engineering archive`。

## 最终检查清单

- [ ] W01-W29 均有周摘要，W29 明确为部分周。
- [ ] 每个三级项目标题恰有一个 `github-record` 标记。
- [ ] 所有保留项 `stars >= 1000`、来源等级 A/B/C 且中文字段完整。
- [ ] 无跨周重复主条目，后续周重复不计数。
- [ ] 没有股票投机、网文、视觉小说、消费娱乐、纯演示、模型训练或微调条目。
- [ ] 历史 C 级条目没有把当前数据写成历史事实。
- [ ] 临时材料未提交，正式文档与状态均已提交。
