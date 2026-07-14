# 市场文档质量审计与整理实施计划

> **面向智能体执行者：** 必须使用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans` 逐任务实施。所有步骤使用复选框跟踪。

**目标：** 建立可重复采集和验证的市场文档维护链路，并完成 `plugins_market.md`、`github_market.md`、`MCP_market.md`、`tool_market.md` 的首次高质量整理。

**架构：** 使用 Node.js 标准库实现市场数据采集与文档一致性验证，不新增第三方依赖。Plugins 以 Codex app-server `plugin/list` 为唯一收录权威；GitHub 文档使用结构化隐藏标记承载可验证元数据，MCP 和工具文档通过派生标记回溯 GitHub 总表。人工语义判断和中文整理由分批子代理执行，主代理负责合并、事实核验、状态文件和最终提交。

**技术栈：** Node.js ESM、Codex app-server JSON-RPC、GitHub REST API、Markdown、PowerShell 5.1/Pester 3.4 兼容测试入口、Git。

## 全局约束

- 当前实现工作区固定为 `E:\codex\.worktrees\phase1-foundation`，分支为 `feat/phase1-foundation`。
- 所有供人类阅读的新建或修改 Markdown 文档使用简体中文；官方名称、标识符、URL 和原始描述允许保留源语言。
- 不读取、打印、复制或提交 `auth.json` 正文，不在日志中写入 Token、Cookie 或认证响应。
- `Resources/tool_whitelist.toml` 仍是唯一部署授权来源；市场文档更新不得改变批准或部署状态。
- Plugins 清单不得使用 `openai/plugins.git`、`codex plugin list` 或本地缓存替代 `plugin/list`。
- `plugin/list` 失败、marketplace 加载错误、schema 不兼容或完整性校验失败时，不得覆盖上一版有效文档。
- GitHub 项目必须满足采集时 `stars >= 1000`，同一规范化 `owner/name` 不得跨周重复，不得为凑够数量降低标准。
- 子代理只读 `state/README.md`、`state/TODO.md`、`state/LOG.md`；确需提交状态材料时只能写入 `state/subagents/<task>/`。正式三个状态文件只能由主代理修改。
- 子代理不得同时编辑同一文件；并行审阅结果写入各自独立的 `.tmp/market-audit/` 文件，由主代理合并。
- 实现子代理先提交任务代码，再进行需求符合性和代码/文档质量审查；两轮通过后，主代理单独提交正式状态文件更新。
- Commit Message 使用 `<type>[scope]: <description>`；没有对应 GitHub Issue 时不得编造 `Fixes #...` 页脚。

---

## 文件职责图

### 新建文件

- `scripts/markets/plugin-catalog.mjs`：app-server 生命周期、`plugin/list` 校验、记录身份和 Plugins Markdown 渲染纯函数。
- `scripts/markets/export-plugins-market.mjs`：命令行参数、原子写入、检查模式和错误退出码。
- `scripts/markets/github-market.mjs`：GitHub API 候选采集、GitHub 记录解析、派生关系和跨文档验证。
- `tests/node/plugin-catalog.test.mjs`：Plugins 采集和渲染的 Node 单元测试。
- `tests/node/github-market.test.mjs`：GitHub 采集与文档验证的 Node 单元测试。
- `tests/unit/MarketScripts.Tests.ps1`：把两组 Node 测试纳入现有 Pester 总入口。
- `docs/superpowers/plans/2026-07-14-market-document-quality-audit.md`：本实施计划。

### 修改文件

- `Resources/PRD.md`：更新 Plugins 权威来源、完整收录和重点索引要求。
- `Resources/PP.md`：替换旧仓库克隆步骤，加入采集器和一致性验证流程。
- `Resources/plugins_market.md`：由同次 `plugin/list` 响应生成完整清单和重点索引。
- `Resources/github_market.md`：重做来源等级、中文条目、研发相关性、W01-W29 和跨周去重。
- `Resources/MCP_market.md`：重做 GitHub 派生候选和当前受管基线。
- `Resources/tool_market.md`：重做 GitHub 派生候选和当前受管基线。
- `Resources/GUIDE.md`：增加四份市场文档的按需更新和复核命令。
- `docs/superpowers/specs/2026-06-25-market-approval-hardening-design.md`：增加被新设计取代的提示。
- `docs/superpowers/plans/2026-06-25-market-approval-hardening.md`：增加禁止继续执行旧 Plugins 来源步骤的提示。
- `state/README.md`、`state/TODO.md`、`state/LOG.md`：由主代理记录阶段、进度和经验。

---

### Task 1：实现 Plugins 目录采集器和完整性验证器

**Files:**
- Create: `scripts/markets/plugin-catalog.mjs`
- Create: `scripts/markets/export-plugins-market.mjs`
- Create: `tests/node/plugin-catalog.test.mjs`
- Create: `tests/unit/MarketScripts.Tests.ps1`

**Interfaces:**
- Produces: `collectPluginCatalog({ codexCommand, cwd, timeoutMs, spawnImpl }) -> Promise<Catalog>`
- Produces: `validatePluginListResult(result) -> Catalog`
- Produces: `pluginRecordKey(marketplaceName, plugin) -> string`
- Produces: `renderPluginsMarket(catalog, metadata) -> string`
- Produces CLI: `node scripts/markets/export-plugins-market.mjs --cwd <absolute> --output <path> [--check <path>] [--codex-command <path>]`
- `Catalog.records` 保持 app-server 返回顺序，每项包含 `marketplaceName`、`id`、`remotePluginId`、`version`、`interface`、`availability`、`installPolicy`、`authPolicy` 和 `keywords`。

- [ ] **Step 1：编写失败测试，覆盖记录身份和上游重复**

在 `tests/node/plugin-catalog.test.mjs` 使用 `node:test` 和 `node:assert/strict` 建立最小 fixture：两个相同插件 ID、不同 `remotePluginId`/版本的 Metabase 记录，以及一个本地插件。测试必须断言三条记录全部保留、记录键均唯一、渲染结果含三个 `plugin-record` 标记。

```js
test('preserves upstream duplicate ids as distinct records', () => {
  const catalog = validatePluginListResult(fixtureResult);
  assert.equal(catalog.records.length, 3);
  assert.equal(new Set(catalog.records.map((record) => record.recordKey)).size, 3);
  assert.match(renderPluginsMarket(catalog, metadata), /原始记录数：3/);
  assert.equal((renderPluginsMarket(catalog, metadata).match(/<!-- plugin-record:/g) ?? []).length, 3);
});
```

- [ ] **Step 2：编写失败测试，覆盖失败不覆盖和 Markdown 转义**

测试 `marketplaceLoadErrors` 非空、缺少 `marketplaces`、重复完整记录键、超时和无效 JSON 均拒绝；测试描述中的 `|`、换行和 HTML 控制字符不会破坏表格。CLI 测试先写入 sentinel 输出文件，模拟失败后断言 sentinel 未变化。

```js
await assert.rejects(
  () => runCliWithFixture({ marketplaceLoadErrors: [{ marketplace: 'broken' }] }),
  /marketplace load error/i,
);
assert.equal(await readFile(outputPath, 'utf8'), 'sentinel');
```

- [ ] **Step 3：运行 Node 测试并确认 RED**

Run:

```powershell
node --test .\tests\node\plugin-catalog.test.mjs *> .\.tmp\plugin-catalog-red.log
```

Expected: exit code 非 0，失败原因是目标模块或导出函数不存在。只读取日志末尾不超过 30 行。

- [ ] **Step 4：实现 app-server JSON-RPC 生命周期**

`collectPluginCatalog` 使用 `spawn` 启动 `codex app-server --stdio`，按顺序发送 `initialize`、`initialized`、`plugin/list`。只接受请求 ID 对应的 JSON-RPC 响应；超时后终止子进程并抛出 `plugin_catalog_timeout`。`finally` 必须关闭 stdin，并在进程仍存活时终止进程。

```js
const initialize = {
  id: 1,
  method: 'initialize',
  params: {
    clientInfo: { name: 'codex-market-audit', version: '1.0.0' },
    capabilities: { experimentalApi: true },
  },
};
const listRequest = { id: 2, method: 'plugin/list', params: { cwds: [cwd] } };
```

- [ ] **Step 5：实现严格校验和记录键**

`validatePluginListResult` 必须拒绝非对象结果、非数组 marketplaces、任何 marketplace load error、非数组 plugins 和缺少 `id`/marketplace 名称的记录。记录键对四元组进行 JSON 序列化后计算 SHA-256，不把插件 ID 本身当作唯一键。

```js
const identity = JSON.stringify([
  marketplaceName,
  String(plugin.id),
  plugin.remotePluginId == null ? '' : String(plugin.remotePluginId),
  plugin.version == null ? '' : String(plugin.version),
]);
return createHash('sha256').update(identity, 'utf8').digest('hex');
```

- [ ] **Step 6：实现简体中文 Markdown 渲染**

渲染器输出采集摘要、来源边界、异常记录、研发者重点索引和完整清单。每条记录输出一个 `<!-- plugin-record:<64位SHA-256> -->` 标记及一行表格；列包含记录键、插件 ID、marketplace、版本、展示名称、开发者、中文类别、官方简述、能力、可用状态、安装策略、认证策略和网站。类别映射无法识别时使用“其他”，不得改写原始类别字段。

- [ ] **Step 7：实现原子写入和检查模式**

CLI 先在内存完成采集、校验和渲染，再写入输出文件同目录的唯一临时文件，最后使用 `rename` 替换目标。`--check` 重新采集后只比较文档中的记录键集合和记录数，不写文件。退出码：参数错误 2、采集失败 3、完整性不一致 4、写入失败 5。

- [ ] **Step 8：把 Node 测试纳入 Pester**

`tests/unit/MarketScripts.Tests.ps1` 分别调用 `node --test`，捕获输出并断言退出码 0；失败时只显示末尾 20 行。保持 PowerShell 5.1 和 Pester 3.4 兼容，不使用 `Should -BeTrue` 等新语法。

- [ ] **Step 9：运行 GREEN 验证**

Run:

```powershell
node --check .\scripts\markets\plugin-catalog.mjs
node --check .\scripts\markets\export-plugins-market.mjs
node --test .\tests\node\plugin-catalog.test.mjs *> .\.tmp\plugin-catalog-green.log
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\.tmp\market-task1-unit.log
```

Expected: 两个 `node --check` 退出 0；Node 测试 0 failed；Pester unit 0 failed。

- [ ] **Step 10：实现子代理提交任务代码，主代理审查后单独提交状态**

子代理提交任务代码，不包含正式状态文件：

```powershell
git add scripts/markets/plugin-catalog.mjs scripts/markets/export-plugins-market.mjs tests/node/plugin-catalog.test.mjs tests/unit/MarketScripts.Tests.ps1
git commit -m "feat[market]: add plugin catalog collector"
```

两轮审查通过后，主代理更新并单独提交 `state/README.md`、`state/TODO.md`、`state/LOG.md`。

---

### Task 2：更新正式需求、计划和旧设计边界

**Files:**
- Modify: `Resources/PRD.md:170`
- Modify: `Resources/PP.md:1`
- Modify: `Resources/PP.md:721`
- Modify: `docs/superpowers/specs/2026-06-25-market-approval-hardening-design.md:1`
- Modify: `docs/superpowers/plans/2026-06-25-market-approval-hardening.md:1`
- Modify: `Resources/GUIDE.md:34`

**Interfaces:**
- Consumes: Task 1 的 CLI 和记录键定义。
- Produces: 当前有效的 Plugins 资料源合同和人工操作说明。

- [ ] **Step 1：先增加文档合同测试**

在 `tests/unit/MarketScripts.Tests.ps1` 增加断言：PRD 包含 `plugin/list` 唯一收录权威、完整清单和重点索引；PP 不再要求克隆 `openai/plugins.git`；两个 2026-06-25 历史文件首屏包含“已被 2026-07-13 设计取代”。

- [ ] **Step 2：运行目标测试并确认 RED**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\.tmp\market-task2-red.log
```

Expected: 新增合同断言失败，旧测试保持通过。

- [ ] **Step 3：修改 PRD Plugins 需求**

明确最新需求覆盖旧的“排除无关插件”规则：所有 `plugin/list` 记录进入完整清单，研发相关性只影响重点索引。写明账户/工作区可见性边界、原始重复保留、失败不覆盖和简体中文/原始证据语言规则。

- [ ] **Step 4：重写 PP Task 12**

删除固定 GitHub Commit、克隆仓库和把 CLI snapshot 当完整市场的步骤。替换为：运行采集器到临时文件、检查摘要和异常、原子更新、执行 `--check`、审阅重点索引、更新状态和提交。

- [ ] **Step 5：标记历史设计和计划已被取代**

在两个旧文件标题后加入醒目说明，指向 `docs/superpowers/specs/2026-07-13-market-document-quality-audit-design.md`。历史内容保留，不改写成当前事实。

- [ ] **Step 6：更新 GUIDE 操作入口**

增加用户按需更新 Plugins 的简短步骤，说明运行命令、成功判据、失败时不得手动用旧仓库补齐，以及无需提供 `auth.json` 正文。

- [ ] **Step 7：运行 GREEN 和文本检查**

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\.tmp\market-task2-green.log
rg -n "openai/plugins\.git|OpenAI Plugins 官方仓库" Resources\PRD.md Resources\PP.md
git diff --check
```

Expected: unit 0 failed；`rg` 只允许出现在历史说明或“不得作为完整清单”的否定语境；`git diff --check` 退出 0。

- [ ] **Step 8：实现子代理提交文档，主代理审查后单独提交状态**

```powershell
git add Resources/PRD.md Resources/PP.md Resources/GUIDE.md docs/superpowers/specs/2026-06-25-market-approval-hardening-design.md docs/superpowers/plans/2026-06-25-market-approval-hardening.md tests/unit/MarketScripts.Tests.ps1
git commit -m "docs[requirements]: update plugin market authority"
```

两轮审查通过后，主代理单独提交正式状态文件更新。

---

### Task 3：生成并审阅完整 `plugins_market.md`

**Files:**
- Modify: `Resources/plugins_market.md`

**Interfaces:**
- Consumes: Task 1 的 `export-plugins-market.mjs`。
- Produces: 与同次 `plugin/list` 响应记录集合完全一致的 Plugins 市场文档。

- [ ] **Step 1：先生成临时候选文档**

Run:

```powershell
node .\scripts\markets\export-plugins-market.mjs --cwd E:\codex --output .\.tmp\market-audit\plugins_market.next.md
```

Expected: exit 0；摘要列出 marketplace、原始记录数、唯一限定 ID 数和加载错误数。不得预设记录数永远为 1984，以本次响应为准。

- [ ] **Step 2：核验当前已知异常**

检查 Metabase 两条记录是否分别保留 `remotePluginId`、版本和 availability；若本次远程目录已经变化，则记录变化而不是强行制造旧异常。

- [ ] **Step 3：执行重点索引语义审阅**

按软件开发、嵌入式/硬件、文档/数据、浏览器/自动化、协作/项目管理五类审阅重点索引。重点索引只能引用完整清单已有记录键，不得新增虚构插件或删除完整清单记录。若发现确定性分类规则存在误判，返回 Task 1 修改分类规则和对应测试，再重新生成，不得直接手改生成结果。

- [ ] **Step 4：生成正式文档并立即检查**

Run:

```powershell
node .\scripts\markets\export-plugins-market.mjs --cwd E:\codex --output .\Resources\plugins_market.md
node .\scripts\markets\export-plugins-market.mjs --cwd E:\codex --check .\Resources\plugins_market.md
```

Expected: 两条命令均退出 0；检查报告记录数和记录键集合一致，marketplace 加载错误为 0。

- [ ] **Step 5：文档质量抽样**

主代理从每个 marketplace 至少抽样 3 条，从官方十大类别各抽样至少 2 条，检查字段转义、链接、类别映射、官方描述和可用状态。抽样结果只写摘要，不复制大量插件正文到终端。

- [ ] **Step 6：提交**

```powershell
git add Resources/plugins_market.md
git commit -m "docs[market]: rebuild complete plugin catalog"
```

两轮审查通过后，主代理单独提交正式状态文件更新。

---

### Task 4：实现 GitHub 采集和跨文档验证工具

**Files:**
- Create: `scripts/markets/github-market.mjs`
- Create: `tests/node/github-market.test.mjs`
- Modify: `tests/unit/MarketScripts.Tests.ps1`

**Interfaces:**
- Produces CLI collect: `node scripts/markets/github-market.mjs collect --from YYYY-MM-DD --to YYYY-MM-DD --output <json>`
- Produces CLI validate: `node scripts/markets/github-market.mjs validate --github <md> --mcp <md> --tool <md>`
- GitHub marker: `<!-- github-record:{"week":"2026-W01","repository":"owner/name","stars":1000,"capturedAt":"ISO-8601","sourceLevel":"C"} -->`
- Derived marker: `<!-- derived-record:{"repository":"owner/name","week":"2026-W01","kind":"mcp|skill|tool"} -->`

- [ ] **Step 1：编写失败测试**

覆盖：`stars < 1000` 拒绝、`owner/name` 大小写跨周重复拒绝、非法 week 拒绝、来源等级非 A/B/C 拒绝、派生记录找不到 GitHub 原记录拒绝、同一派生对象同时进入 MCP 和 tool 拒绝、GitHub API 分页和限流错误不产生半成品。

- [ ] **Step 2：运行 RED**

```powershell
node --test .\tests\node\github-market.test.mjs *> .\.tmp\github-market-red.log
```

Expected: exit code 非 0，原因是模块不存在。

- [ ] **Step 3：实现 GitHub API 采集**

使用 Node `fetch` 请求 `https://api.github.com/search/repositories`，固定 `Accept: application/vnd.github+json` 和 User-Agent。可选读取 `GITHUB_TOKEN` 作为 Authorization header，但任何日志和错误都不得输出 header。响应只保存公开仓库字段：`full_name`、`html_url`、`stargazers_count`、`description`、`created_at`、`updated_at`、`language`、`topics`、`license.spdx_id`。

- [ ] **Step 4：实现 Markdown 标记解析和验证**

逐行解析 `github-record` 和 `derived-record` JSON；错误包含文件和行号。规范化仓库键使用 `repository.toLowerCase()`。validate 命令输出总记录数、周数、低于 20 条的周、重复数和派生缺失数，任一硬错误退出 4。

- [ ] **Step 5：运行 GREEN**

```powershell
node --check .\scripts\markets\github-market.mjs
node --test .\tests\node\github-market.test.mjs *> .\.tmp\github-market-green.log
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\.tmp\market-task4-unit.log
```

Expected: 0 failed。

- [ ] **Step 6：实现子代理提交任务代码，主代理审查后单独提交状态**

```powershell
git add scripts/markets/github-market.mjs tests/node/github-market.test.mjs tests/unit/MarketScripts.Tests.ps1
git commit -m "feat[market]: add github market validation"
```

两轮审查通过后，主代理单独提交正式状态文件更新。

---

### Task 5：重建 `github_market.md`

**Files:**
- Modify: `Resources/github_market.md`
- Temporary only: `.tmp/market-audit/github-W01-W10.md`
- Temporary only: `.tmp/market-audit/github-W11-W20.md`
- Temporary only: `.tmp/market-audit/github-W21-W29.md`

**Interfaces:**
- Consumes: Task 4 的 GitHub marker 和验证规则。
- Produces: 2026-W01 至采集日所在周的研发相关 GitHub 候选总表。

- [ ] **Step 1：采集 W27-W29 候选**

分别运行 collect 命令，输出到 `.tmp/market-audit/`。W29 为未结束周，必须标注“截至采集日的部分周数据”。API 失败或 rate limit 时停止，不写正式文档。

- [ ] **Step 2：并行分派三个语义审阅子代理**

每个子代理只读原 `github_market.md` 和对应周次的公开采集数据，写入自己独立的临时审阅文件。子代理对每条记录给出 `保留/排除`、研发场景、中文核心说明、部署条件、主要风险和来源等级；不得修改 `Resources/github_market.md` 或 `state/`。

- [ ] **Step 3：主代理执行边界复核**

重点排除小说、股票投机、视觉小说、消费娱乐、纯 Demo、模型训练/微调和只有宽泛“agent”关键词但无研发用途的项目。对边界项目检查 README 或官方文档，不得只根据仓库名判断。

- [ ] **Step 4：按倒序周次合并正式文档**

文档从最新周到 W01。每条记录使用三级标题、一个 `github-record` 标记和中文字段：链接、当前 Star/采集时间、项目属性、周次依据、来源等级、核心功能、适用工作流、输入、输出、部署条件、风险、保留理由。官方英文描述可作为附注。

- [ ] **Step 5：执行硬验证**

```powershell
node .\scripts\markets\github-market.mjs validate --github .\Resources\github_market.md
```

Expected: stars 硬错误 0、跨周重复 0、非法记录 0；不足 20 条的周作为信息摘要，不作为失败。

- [ ] **Step 6：人工抽样和规模核对**

每周至少抽样首条和末条；候选少于 5 条的周全部复核。确认没有把当前 Star 描述成历史周值，没有用 `created_at` 冒充 A/B 级 Trending 证据。

- [ ] **Step 7：提交**

```powershell
git add Resources/github_market.md
git commit -m "docs[market]: curate github engineering archive"
```

两轮审查通过后，主代理单独提交正式状态文件更新。

---

### Task 6：重建 MCP 和工具派生市场

**Files:**
- Modify: `Resources/MCP_market.md`
- Modify: `Resources/tool_market.md`
- Read: `Resources/tool_whitelist.toml`
- Read: `Notes/verify_record.md`

**Interfaces:**
- Consumes: Task 5 的规范化 GitHub 记录集合。
- Produces: 每条候选均可回溯的 MCP/Skill 和其他 AI 工作流工具市场。

- [ ] **Step 1：并行审阅 MCP/Skill 与其他工具候选**

两个子代理分别处理 MCP/Skill 和其他工具，不共享输出文件。每个候选必须先存在于 `github_market.md`，并确认无需修改上游源码即可用于 Codex；无法确认时排除并记录理由。

- [ ] **Step 2：主代理写入 GitHub 派生候选区**

每条记录包含 `derived-record` 标记、原周次、原仓库、来源等级、安装入口、运行时、凭据、权限、许可证、Codex 兼容性、风险和当前处理建议。MCP/Skill 与 tool 两份文档不得重复收录同一派生对象。

- [ ] **Step 3：主代理写入当前受管基线**

从白名单、部署记录和 `verify_record.md` 提取状态。明确：filesystem 与 sequential-thinking 为 `approved`、`deployed`、`static_verified`、`load_verified`、`smoke_verified`；filesystem 根目录仅 `E:\codex`。Skill 的受管安装/hash 只能支持 load 层结论，无运行时调用时 smoke 为 `blocked`。插件 load 不等于功能 smoke。

- [ ] **Step 4：执行派生关系验证**

```powershell
node .\scripts\markets\github-market.mjs validate --github .\Resources\github_market.md --mcp .\Resources\MCP_market.md --tool .\Resources\tool_market.md
```

Expected: 派生缺失 0、跨文档分类冲突 0、GitHub 硬错误 0。

- [ ] **Step 5：事实复核**

用只读命令核对当前 `codex mcp get` 结果和验证记录；不启动 smoke、不改用户配置。发现运行状态与记录冲突时，以较新高等级证据为准，并在文档中说明。

- [ ] **Step 6：提交**

```powershell
git add Resources/MCP_market.md Resources/tool_market.md
git commit -m "docs[market]: rebuild derived tool catalogs"
```

两轮审查通过后，主代理单独提交正式状态文件更新。

---

### Task 7：最终跨文档质量审计和交付

**Files:**
- Modify: `Resources/GUIDE.md`
- Modify: `state/README.md`
- Modify: `state/TODO.md`
- Modify: `state/LOG.md`
- Modify only if factual conflict exists: `Notes/verify_record.md`

**Interfaces:**
- Consumes: Tasks 1-6 的全部交付物。
- Produces: 可交接的文档地图、操作说明、最终验证证据和干净分支。

- [ ] **Step 1：统一术语和文档职责**

全局检索旧状态和旧来源。统一使用 `approved`、`deployed`、`static_verified`、`load_verified`、`smoke_verified`、`blocked`；清理“filesystem 未部署”“只有 sequential-thinking 有 smoke”“全量测试 300 passed”等过时当前态陈述。历史日志不篡改，只在当前文档中标明已被后续事实取代。

- [ ] **Step 2：更新 GUIDE**

说明四份文档各自用途、按需更新顺序、采集命令、人工审阅点、失败处理和用户需要参与的审批边界。GUIDE 不要求用户手工编辑生成区块。

- [ ] **Step 3：运行所有专项验证**

```powershell
node .\scripts\markets\export-plugins-market.mjs --cwd E:\codex --check .\Resources\plugins_market.md *> .\.tmp\final-plugin-check.log
node .\scripts\markets\github-market.mjs validate --github .\Resources\github_market.md --mcp .\Resources\MCP_market.md --tool .\Resources\tool_market.md *> .\.tmp\final-market-check.log
node --test .\tests\node\plugin-catalog.test.mjs .\tests\node\github-market.test.mjs *> .\.tmp\final-node-tests.log
```

Expected: 三项退出 0；Plugins 记录集合一致；GitHub 和派生硬错误均为 0；Node 0 failed。

- [ ] **Step 4：运行全量项目测试**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -All *> .\.tmp\final-all-tests.log
```

Expected: exit 0、0 failed。只向用户报告最终 passed/failed 数，不打印完整日志。

- [ ] **Step 5：运行文档和敏感信息检查**

```powershell
git diff --check
rg -n -i "auth\.json.*\{|sk-[A-Za-z0-9]|ghp_[A-Za-z0-9]|bearer [A-Za-z0-9._-]+" Resources Notes state scripts tests
```

Expected: `git diff --check` 退出 0；敏感扫描没有真实凭据命中。示例占位符命中必须逐条人工确认，不能直接忽略。

- [ ] **Step 6：主代理更新三个状态文件**

`README.md` 写当前能力和限制；`TODO.md` 标记本阶段完成项与后续工作；`LOG.md` 记录 app-server 实验接口、Metabase 重复、GitHub 历史来源等级和失败不覆盖规则。子代理不得执行此步骤。

- [ ] **Step 7：最终审查、提交和推送**

```powershell
git add Resources/GUIDE.md state/README.md state/TODO.md state/LOG.md
git diff --quiet -- Notes/verify_record.md
if ($LASTEXITCODE -ne 0) { git add Notes/verify_record.md }
git commit -m "docs[market]: complete catalog quality audit"
git push origin feat/phase1-foundation
git status --short --branch
```

Expected: push 成功；本地分支与远端同步；工作树干净。

---

## 实施顺序和并行边界

1. Task 1 和 Task 2 顺序执行，因为 Task 2 引用 Task 1 的真实 CLI。
2. Task 3 必须在 Task 1、Task 2 完成后执行。
3. Task 4 可在 Task 3 文档审阅期间开始，但不得与 Task 1 同时修改 `tests/unit/MarketScripts.Tests.ps1`。
4. Task 5 的三个周次审阅子代理可并行，只能写各自临时文件。
5. Task 6 的两个分类审阅子代理可并行，只能返回审阅结果，由主代理修改正式文件。
6. Task 7 必须在前六项全部通过两轮审查后执行。

## 子代理审查门禁

每个实现任务采用以下固定顺序：

1. 实现子代理读取设计、当前任务和相关文件，完成实现、目标测试和任务代码提交，不修改三个正式状态文件；确需状态交接时只能写入 `state/subagents/<task>/`。
2. 需求审查子代理只判断是否完整符合设计和任务，不进行风格扩展。
3. 若需求审查失败，原实现子代理修复后重新审查。
4. 质量审查子代理检查正确性、错误边界、测试充分性、文档事实和可维护性。
5. 若质量审查失败，原实现子代理修复后重新审查。
6. 主代理独立运行验证、更新三个正式状态文件并单独提交，然后关闭全部子代理。

## 完成判据

- `plugins_market.md` 与同次 `plugin/list` 的记录数和记录键集合完全一致。
- `github_market.md` 覆盖 2026-W01 至采集周，所有记录达到 1000 Star，跨周重复为 0，近似数据明确标级。
- `MCP_market.md` 和 `tool_market.md` 的派生记录全部能回溯 GitHub 总表，分类冲突为 0。
- 四份市场文档的当前状态与白名单、部署记录和验证记录一致。
- PRD、PP、GUIDE 和历史设计提示不再指导使用旧 GitHub 仓库作为完整 Plugins 来源。
- Node 专项测试、Pester 全量测试、Markdown 空白检查和敏感信息扫描均通过。
- 三个状态文件已更新，提交已推送，工作树干净。
