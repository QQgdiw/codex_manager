# 工程工作流事件市场重建实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将只有规则和模板的 `Resources/event_market.md` 重建为覆盖 2026-01-01 至 2026-07-18、约 35 项经官方来源核验的工程工作流事件档案。

**Architecture:** 分领域调研只产生 `.tmp/event-market-audit/` 下的 JSONL 候选；主代理负责来源复核、价值判定、连续小版本合并和唯一正文归属。Node.js 标准库验证器检查结构、日期、来源、重复、组织内排序和主题索引，并从通过复核的总账原子渲染正式 Markdown；调研、验证或渲染失败时保留上一版正式文档。

**Tech Stack:** Node.js ESM 与 Node Test、Windows PowerShell 5.1/Pester 3.4、Markdown、JSONL、Git、官方网页与官方 GitHub release/changelog。

## Global Constraints

- 覆盖时间固定为 2026-01-01 至 2026-07-18，只收录已实际发生的事件。
- 正式结果预计约 35 项，但不设置硬数量；不得凑数，也不得因过度严格遗漏具有明确工程价值的事件。
- 每个正式事件至少包含一个已打开核验的官方一手来源；二手资料只能发现候选。
- 同一产品的连续小版本合并为阶段性事件；只有权限、接口、兼容性、安全边界或工程能力发生独立重大变化时拆分。
- 正文采用组织归档，同组织内日期倒序；主题索引可多重引用，但每个事件只有一个正文主条目。
- 客观事实、技术剖析、工作流影响、局限与风险必须分开书写。
- 子代理不得修改 `Resources/event_market.md`、`Resources/GUIDE.md`、`Resources/PP.md` 或三个正式状态文件；只能写自己的 `.tmp/event-market-audit/research/<domain>.jsonl`。
- 不读取、输出或提交 `auth.json`、Token、Cookie、API key 或其他凭据。
- 人类可读 Markdown 使用简体中文；官方名称、版本、标识符和 URL 可保留原语言。
- 不修改白名单、场景配置、部署状态或验证状态，不引入第三方运行时依赖。
- 大型输出写入 `.tmp/event-market-audit/logs/`，聊天和终端只显示不超过 50 行的关键摘要。

---

### Task 1：实现事件总账验证器与原子渲染器

**Files:**
- Create: `scripts/markets/event-market.mjs`
- Create: `tests/node/event-market.test.mjs`
- Modify: `tests/unit/MarketScripts.Tests.ps1`

**Interfaces:**
- Consumes: 一行一个 JSON 对象的 JSONL 总账。
- Produces: `validateCurationRecords(records, options)`、`renderEventMarket(records, metadata)`、`validateEventDocument(markdown, options)` 和三个 CLI 命令 `validate-curation`、`render`、`validate-doc`。

总账正式记录采用以下字段：

```json
{
  "id": "openai-codex-workflow-2026",
  "date": "2026-01-01",
  "organization": "OpenAI",
  "partners": [],
  "title": "事件标题",
  "occurred": true,
  "topics": ["coding-agent"],
  "priority": "high",
  "officialSources": [
    {
      "label": "官方公告",
      "url": "https://example.com/official",
      "type": "official-announcement",
      "verifiedAt": "2026-07-18"
    }
  ],
  "facts": ["来源直接支持的客观事实。"],
  "analysis": "技术边界和技术意义。",
  "workflowImpact": "对用户具体工程工作的影响。",
  "limitations": "技术、生态、商业或安全限制。",
  "followUp": "可执行的后续观察或验证动作。",
  "mergeKey": "openai-codex-workflow",
  "decision": "keep",
  "decisionReason": "具有独立工程影响且官方来源完整。"
}
```

keep 记录的 `occurred` 必须严格为 `true`。允许的 `topics` 固定为 `coding-agent`、`extension-security`、`robotics-ros`、`embedded-edge`、`eda-fpga-chip`、`engineering-docs`；`priority` 固定为 `high`、`medium`、`low`；来源类型固定为 `official-announcement`、`official-docs`、`official-changelog`、`official-release`、`standards-body`。

- [ ] **Step 1：编写失败测试，锁定总账硬约束**

在 `tests/node/event-market.test.mjs` 中覆盖：重复 `id`、重复 keep `mergeKey`、非法日历日期、日期越界、空官方来源、非 HTTPS URL、未知主题、缺字段、未来预告状态和组织内日期乱序。核心断言如下：

```js
test('rejects duplicate kept merge keys and out-of-range dates', () => {
  const result = validateCurationRecords([
    validRecord({ id: 'event-a', date: '2026-01-10', mergeKey: 'same' }),
    validRecord({ id: 'event-b', date: '2025-12-31', mergeKey: 'same' }),
  ], { start: '2026-01-01', end: '2026-07-18' });
  assert.match(result.errors.join('\n'), /duplicate kept mergeKey: same/);
  assert.match(result.errors.join('\n'), /event-b: date outside coverage/);
});
```

- [ ] **Step 2：运行 Node 测试并确认 RED**

```powershell
node --test .\tests\node\event-market.test.mjs *> .\.tmp\event-market-audit\logs\task1-red.log
```

Expected: exit `1`，失败原因是 `scripts/markets/event-market.mjs` 或导出函数尚不存在。

- [ ] **Step 3：实现总账解析和验证**

实现严格日期解析、字段类型检查、枚举检查、HTTPS 来源检查、`id` 与 keep `mergeKey` 唯一性。`decision="exclude"` 的记录必须有 `decisionReason`，但不要求完整分析字段；`decision="keep"` 必须具备全部正式字段。

`validateCurationRecords` 返回：

```js
{
  kept: [],
  excluded: [],
  errors: [],
  summary: { total: 0, kept: 0, excluded: 0, organizations: 0, topics: {} }
}
```

- [ ] **Step 4：编写失败测试，锁定渲染与正式文档结构**

覆盖：主题索引锚点、组织分组、组织内日期倒序、唯一 `event-record` 标记、事实/分析/影响/局限/后续关注五段、来源链接、原子失败不覆盖和人工写入的无标记事件标题。

正式标记格式固定为：

```html
<!-- event-record:{"id":"openai-codex-workflow-2026","date":"2026-01-01","organization":"OpenAI"} -->
```

- [ ] **Step 5：实现确定性渲染、正式文档验证和原子写入**

组织按“最高事件优先级、最新事件日期、组织名”排序；组内按日期倒序，再按 `id` 排序。主题索引按主题固定顺序、事件日期倒序生成。写入使用同目录临时文件加 `rename`，验证失败或写入失败时删除临时文件并保留旧文档。

CLI 固定为：

```powershell
node .\scripts\markets\event-market.mjs validate-curation --input .\.tmp\event-market-audit\curation.jsonl --start 2026-01-01 --end 2026-07-18
node .\scripts\markets\event-market.mjs render --input .\.tmp\event-market-audit\curation.jsonl --output .\.tmp\event-market-audit\event_market.candidate.md --start 2026-01-01 --end 2026-07-18 --verified-at 2026-07-18
node .\scripts\markets\event-market.mjs validate-doc --input .\.tmp\event-market-audit\event_market.candidate.md --start 2026-01-01 --end 2026-07-18
```

- [ ] **Step 6：把事件市场 Node 测试接入 Pester 市场测试入口**

在 `tests/unit/MarketScripts.Tests.ps1` 中按现有 Node 测试模式新增一个 `It`，执行 `tests/node/event-market.test.mjs`，断言退出码为 `0`。

- [ ] **Step 7：运行 GREEN 验证**

```powershell
node --check .\scripts\markets\event-market.mjs
node --test .\tests\node\event-market.test.mjs
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { Import-Module Pester -ErrorAction Stop; `$r = Invoke-Pester -Script '.\tests\unit\MarketScripts.Tests.ps1' -PassThru; if (`$r.FailedCount -gt 0) { exit 1 } }"
```

Expected: 三个命令退出 `0`，Node 0 failed，市场 Pester 0 failed。

- [ ] **Step 8：提交 Task 1**

```powershell
git add scripts/markets/event-market.mjs tests/node/event-market.test.mjs tests/unit/MarketScripts.Tests.ps1
git commit -m "feat[market]: validate event archive"
```

---

### Task 2：调研编码 Agent、扩展生态与安全事件

**Files:**
- Create temporary: `.tmp/event-market-audit/research/agent-ecosystem.jsonl`

**Interfaces:**
- Consumes: Task 1 的 JSONL schema 和 2026-01-01 至 2026-07-18 时间边界。
- Produces: 约 18-25 条已打开官方来源的候选，不代表正式保留数量。

- [ ] **Step 1：派发独立调研子代理**

调研 OpenAI/Codex、Anthropic/Claude Code、GitHub Copilot、Google/Gemini CLI、Cursor，以及 MCP、Plugins、Skills、Agent 扩展安全和供应链。只打开官方发布页、开发者文档、官方 changelog、官方安全公告或官方 GitHub release。

- [ ] **Step 2：逐候选记录工程价值和排除理由**

候选必须明确落到编码、权限、工具调用、子代理、上下文、仓库操作、配置、兼容性、安全或部署工作流。只涉及模型训练、参数、榜单或泛能力宣传的候选写为 `decision="exclude"`。

- [ ] **Step 3：子代理自检并输出临时材料**

```powershell
node .\scripts\markets\event-market.mjs validate-curation --input .\.tmp\event-market-audit\research\agent-ecosystem.jsonl --start 2026-01-01 --end 2026-07-18
```

Expected: exit `0`；所有 keep 候选字段完整，exclude 候选有明确理由。

---

### Task 3：调研机器人、ROS、导航与自主系统事件

**Files:**
- Create temporary: `.tmp/event-market-audit/research/robotics-ros.jsonl`

**Interfaces:**
- Consumes: Task 1 schema。
- Produces: 约 12-18 条机器人/ROS 候选。

- [ ] **Step 1：派发独立调研子代理**

调研 ROS/Open Robotics、NVIDIA Robotics/Isaac、主要机器人平台、导航与仿真工具、多模态感知和自主系统的官方事件。只保留能改变开发、仿真、部署、硬件适配、接口或验证方式的事件。

- [ ] **Step 2：排除展示性和未发生内容**

机器人演示、概念视频、融资、未来量产承诺和只有媒体报道的发布不进入 keep；已发布 SDK、开发平台、标准、接口或可获得硬件才可保留。

- [ ] **Step 3：验证临时候选**

```powershell
node .\scripts\markets\event-market.mjs validate-curation --input .\.tmp\event-market-audit\research\robotics-ros.jsonl --start 2026-01-01 --end 2026-07-18
```

Expected: exit `0`。

---

### Task 4：调研嵌入式、边缘 AI、硬件、EDA/FPGA/芯片与工程资料事件

**Files:**
- Create temporary: `.tmp/event-market-audit/research/hardware-engineering.jsonl`

**Interfaces:**
- Consumes: Task 1 schema。
- Produces: 约 18-25 条硬件与工程基础设施候选。

- [ ] **Step 1：派发独立调研子代理**

调研 Arm、NVIDIA、AMD/Xilinx、Intel/Altera、主要 MCU/边缘 AI 平台、Cadence、Synopsys、Siemens EDA、KiCad、芯片设计验证工具，以及工程文档、数据手册、GitHub 协作和资料处理平台的官方事件。

- [ ] **Step 2：以用户实际工作路径筛选**

保留能影响器件选择、固件、边缘推理、RTL/FPGA、EDA、PCB、验证、数据手册、工程文档或仓库协作的事件。纯芯片商业新闻、性能宣传和与开发工具无关的产品发布写为 exclude。

- [ ] **Step 3：验证临时候选**

```powershell
node .\scripts\markets\event-market.mjs validate-curation --input .\.tmp\event-market-audit\research\hardware-engineering.jsonl --start 2026-01-01 --end 2026-07-18
```

Expected: exit `0`。

---

### Task 5：主代理合并、逐项核验和价值裁决

**Files:**
- Create temporary: `.tmp/event-market-audit/curation.jsonl`
- Create temporary: `.tmp/event-market-audit/exclusion-summary.md`

**Interfaces:**
- Consumes: Tasks 2-4 的三个候选 JSONL。
- Produces: 唯一、经主代理复核的正式总账。

- [ ] **Step 1：机械合并候选，不直接保留**

读取三个 JSONL，按规范化官方来源 URL、`mergeKey`、组织和标题识别重复。跨领域重复只保留一个候选身份，合并主题标签和来源。

- [ ] **Step 2：主代理逐项重新打开官方来源**

核对日期、组织、合作方、产品名、版本、接口、性能数字和已发生状态。官方来源不支持的数字或结论从 facts 删除；关键事实无法确认的记录改为 exclude。

- [ ] **Step 3：执行连续小版本合并**

同一 `mergeKey` 的短期小版本合并为一个阶段性事件，facts 中按时间描述关键变化。只有存在独立权限、接口、兼容性、安全或工程能力变化时才拆分并使用不同 `mergeKey`。

- [ ] **Step 4：执行价值复核**

每条 keep 必须明确回答“它会改变用户哪一项工程工作或决策”。不能回答的候选改为 exclude。结果自然接近 35 项即可，不用补数或强行删减。

- [ ] **Step 5：生成排除摘要**

`exclusion-summary.md` 按“未发生、非官方来源、泛 AI、重复/被合并、工程价值不足、事实冲突”统计数量并列候选 ID，不包含完整网页正文。

- [ ] **Step 6：验证正式总账**

```powershell
node .\scripts\markets\event-market.mjs validate-curation --input .\.tmp\event-market-audit\curation.jsonl --start 2026-01-01 --end 2026-07-18 *> .\.tmp\event-market-audit\logs\curation-validation.log
```

Expected: exit `0`；重复 `id` 0、重复 keep `mergeKey` 0、越界日期 0、缺少官方来源 0。

---

### Task 6：渲染候选并执行两轮独立内容审阅

**Files:**
- Create temporary: `.tmp/event-market-audit/event_market.candidate.md`
- Modify temporary as source of truth: `.tmp/event-market-audit/curation.jsonl`

**Interfaces:**
- Consumes: Task 5 总账。
- Produces: 经事实审阅和中文质量审阅通过的候选 Markdown。

- [ ] **Step 1：渲染并验证候选**

```powershell
node .\scripts\markets\event-market.mjs render --input .\.tmp\event-market-audit\curation.jsonl --output .\.tmp\event-market-audit\event_market.candidate.md --start 2026-01-01 --end 2026-07-18 --verified-at 2026-07-18
node .\scripts\markets\event-market.mjs validate-doc --input .\.tmp\event-market-audit\event_market.candidate.md --start 2026-01-01 --end 2026-07-18
```

Expected: 两个命令退出 `0`。

- [ ] **Step 2：事实与来源独立审阅**

审阅者只读核对每条正式事件的日期、官方来源、事实支持范围、组织主体、版本数字、已发生状态和合并粒度。按严重度返回 findings，不直接修改正式文件。

- [ ] **Step 3：中文质量与工程价值独立审阅**

第二名审阅者检查事实与分析是否分离、技术剖析是否过度断言、对用户工作的影响是否具体、局限是否真实、是否存在泛 AI 内容或重复事件。

- [ ] **Step 4：主代理修正总账并重新渲染**

所有高、中问题必须在 JSONL 源记录中修正，再重新渲染和验证；不得只修改生成的候选 Markdown。两轮复审无高、中问题后进入 Task 7。

---

### Task 7：提升正式文档并更新维护说明

**Files:**
- Modify: `Resources/event_market.md`
- Modify: `Resources/GUIDE.md`
- Modify: `Resources/PP.md`

**Interfaces:**
- Consumes: Task 6 通过审阅的候选和 Task 1 渲染器。
- Produces: 正式事件市场及可重复维护说明。

- [ ] **Step 1：从同一总账原子渲染正式文件**

```powershell
node .\scripts\markets\event-market.mjs render --input .\.tmp\event-market-audit\curation.jsonl --output .\Resources\event_market.md --start 2026-01-01 --end 2026-07-18 --verified-at 2026-07-18
node .\scripts\markets\event-market.mjs validate-doc --input .\Resources\event_market.md --start 2026-01-01 --end 2026-07-18
```

Expected: 两个命令退出 `0`，正式文档事件数与 keep 总账一致。

- [ ] **Step 2：更新 GUIDE**

将 `event_market.md` 加入市场文档职责表，并说明按需更新顺序、临时候选、官方来源人工复核、连续版本合并、失败保留旧版和用户无需手工编辑生成区。

- [ ] **Step 3：更新 PP Task 15**

把 Task 15 从粗粒度步骤更新为本计划的 `validate-curation`、`render` 和 `validate-doc` 真实命令；明确市场收录不改变白名单或部署授权。

- [ ] **Step 4：执行正式文档专项验证**

```powershell
node .\scripts\markets\event-market.mjs validate-curation --input .\.tmp\event-market-audit\curation.jsonl --start 2026-01-01 --end 2026-07-18
node .\scripts\markets\event-market.mjs validate-doc --input .\Resources\event_market.md --start 2026-01-01 --end 2026-07-18
```

Expected: 两个命令退出 `0`。

- [ ] **Step 5：提交正式文档**

```powershell
git add Resources/event_market.md Resources/GUIDE.md Resources/PP.md
git commit -m "docs[market]: rebuild engineering event archive"
```

---

### Task 8：最终质量审计、状态更新和交付

**Files:**
- Modify: `state/README.md`
- Modify: `state/TODO.md`
- Modify: `state/LOG.md`

**Interfaces:**
- Consumes: Tasks 1-7 全部正式交付物和验证日志。
- Produces: 可交接的完成状态、测试证据和同步远端分支。

- [ ] **Step 1：运行全部市场 Node 测试**

```powershell
node --test .\tests\node\plugin-catalog.test.mjs .\tests\node\github-market.test.mjs .\tests\node\github-market-archive.test.mjs .\tests\node\event-market.test.mjs *> .\.tmp\event-market-audit\logs\final-node-tests.log
```

Expected: exit `0`、0 failed。

- [ ] **Step 2：运行完整 Pester**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -All *> .\.tmp\event-market-audit\logs\final-all-tests.log
```

Expected: exit `0`、0 failed。

- [ ] **Step 3：运行文档、链接和敏感信息检查**

```powershell
git diff --check
node .\scripts\markets\event-market.mjs validate-doc --input .\Resources\event_market.md --start 2026-01-01 --end 2026-07-18
rg -n --pcre2 -i "(?<![A-Za-z0-9])sk-[A-Za-z0-9_-]{20,}|ghp_[A-Za-z0-9]{20,}|bearer\s+[A-Za-z0-9._-]{16,}" Resources Notes state scripts tests
```

Expected: 前两个命令退出 `0`；敏感扫描没有真实凭据命中。占位符命中必须逐条人工确认。

- [ ] **Step 4：更新三个状态文件**

`README.md` 写正式事件数、覆盖时间、组织数、主题分布和当前限制；`TODO.md` 关闭事件市场重建任务；`LOG.md` 记录候选数、排除原因、官方来源规则、合并决策、审阅 findings 和最终验证证据。

- [ ] **Step 5：最终独立审阅**

审阅从 Task 1 基线到当前 HEAD 的全部变更，重点检查来源证据、事件价值、生成器失败边界、正式文档中文质量和状态真实性。所有高、中问题修复并复审后提交状态。

- [ ] **Step 6：提交状态并推送**

```powershell
git add state/README.md state/TODO.md state/LOG.md
git commit -m "docs[state]: close event market rebuild"
git push origin feat/phase1-foundation
git status --short --branch
git rev-list --left-right --count HEAD...origin/feat/phase1-foundation
```

Expected: 推送成功，工作树干净，本地与远端差异 `0 0`。

## Review Gates

1. Task 1 完成后执行规格审阅和代码质量审阅，清理器与原子写入问题不得带入调研阶段。
2. Tasks 2-4 可并行，子代理输出路径必须互不重叠。
3. Task 5 只能由主代理执行，候选数量不能替代逐项来源核验。
4. Task 6 的事实审阅和中文质量审阅必须由不同上下文的审阅者执行。
5. Task 7 只有在两轮审阅无高、中问题后才能覆盖正式文档。
6. Task 8 的状态文件只能由主代理更新。

## Acceptance Summary

- `event_market.md` 不再只是规则模板，而是包含已核验正式事件的工程档案。
- 所有正式事件发生于 2026-01-01 至 2026-07-18，且至少有一个官方一手来源。
- 正文按组织归档、组内日期倒序，主题索引无悬空链接，正式事件无重复。
- 连续小版本已合并，事实、分析、工作流影响、局限和后续关注明确分离。
- 正式数量由价值和证据自然决定，预计约 35 项，不凑数也不过度排除。
- 调研、验证或渲染失败不会覆盖上一版正式文档。
- Node、Pester、文档结构和敏感信息检查全部通过。
