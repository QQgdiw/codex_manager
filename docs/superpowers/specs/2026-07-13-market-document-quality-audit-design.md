# 市场文档质量审计与整理设计

> 状态：已获用户确认
> 设计日期：2026-07-13
> 适用范围：`plugins_market.md`、`github_market.md`、`MCP_market.md`、`tool_market.md` 及其直接相关的需求、计划、生成规则和状态记录

## 1. 背景与问题

当前四份市场文档已经建立基本结构，但存在来源过时、事实陈旧、分类不准和文档口径混杂等问题。

最重要的变化是：`https://github.com/openai/plugins.git` 不再能够代表 Codex `/plugins` 展示的完整插件目录。本机验证结果如下：

- Codex CLI 版本为 `0.144.1`。
- `codex plugin list --available --json` 返回 183 个可用插件，其中 `openai-curated` 本地快照为 179 个。
- Codex app-server 的 `plugin/list` 返回 4 个 marketplace、1984 条插件记录，且没有 marketplace 加载错误。
- 1984 条记录中，`openai-curated-remote` 为 1974 条，`openai-primary-runtime` 为 5 条，`openai-bundled` 为 4 条，`context-mode` 为 1 条。
- `metabase@openai-curated-remote` 存在两条不同版本、不同 `remotePluginId` 和不同可用状态的上游记录，因此 1984 条记录对应 1983 个唯一限定 ID。

以上事实证明：GitHub 仓库和 `codex plugin list` 只能反映本地 marketplace snapshot，不能继续决定 `plugins_market.md` 的收录集合。当前官方手册将 `/plugins` 定义为浏览已安装和可发现插件的入口；本机 app-server 诊断记录也确认 `/plugins` 使用 `plugin/list` 并加载远程插件目录。

另外三份文档也存在明显质量问题：

- `github_market.md` 将仓库创建周近似为历史热门周，虽然已经标记为 C 级近似数据，但正文仍容易被误解为真实历史 Trending；部分条目与研发者工作身份明显无关，描述大量使用未整理的英文截断文本。
- `MCP_market.md` 仍声称 filesystem 和 sequential-thinking MCP 尚未真实部署或动态验证，与当前验证记录冲突。
- `tool_market.md` 混合了 GitHub 派生候选和本地受管 Skill，且部署、加载和 smoke 状态已经过时。

## 2. 目标

本阶段实现以下结果：

1. 为四份市场文档建立明确、可追溯且互不冲突的资料源口径。
2. 让 `plugins_market.md` 的插件记录集合与采集时 `/plugins` 背后的 `plugin/list` 响应严格一致。
3. 提高 GitHub 候选与研发者实际工作场景的相关性，并清楚区分可验证历史数据和近似回溯数据。
4. 让 MCP、Skills 和其他工具的市场候选、白名单审批、部署状态及验证状态各自有清晰边界。
5. 使用简体中文整理人类编写的说明、判断和结论；插件名、仓库名、官方描述等原始证据允许保留源语言。
6. 提供可重复执行的采集与一致性检查规则，避免后续再次依赖人工计数或过时仓库。

## 3. 非目标

本阶段不执行以下工作：

- 不因市场文档更新自动批准、安装、升级或卸载任何工具。
- 不为约 2000 个插件逐一进行真实安装或 smoke 验证。
- 不把 GitHub 当前 Star 数伪装成历史周榜当时的精确 Star 数。
- 不为达到每周 20 至 30 个候选而降低 1000 Star、相关性或来源要求。
- 不把 Plugins、MCP、Skills 和工具市场改造成可视化产品。
- 不读取、打印、复制或提交 `auth.json` 正文。

## 4. 总体资料源模型

每份市场文档都区分三类信息：

- **收录权威**：决定某个对象是否进入该市场的唯一或最高优先级来源。
- **信息补充源**：只补充描述、版本、许可证、部署条件和风险，不得擅自增加或删除权威清单中的对象。
- **运行状态源**：只说明对象是否已批准、部署或验证，不决定市场收录。

四份文档的资料源边界如下：

| 文档 | 收录权威 | 信息补充源 | 运行状态源 |
| --- | --- | --- | --- |
| `plugins_market.md` | 当前账户、当前 Codex 环境的 app-server `plugin/list` 完整响应 | 插件 interface 字段、官方网页、manifest、项目仓库 | `tool_whitelist.toml`、部署记录、`verify_record.md` |
| `github_market.md` | 可验证周度快照；不足时使用明确标级的 GitHub API 或第三方历史资料近似回溯 | 仓库 API、README、Release、许可证 | 不适用 |
| `MCP_market.md` | `github_market.md` 中通过 Codex 无源码修改部署判断的 MCP 和 Skill 候选 | 上游仓库、包清单、官方文档 | 白名单、部署记录、`verify_record.md` |
| `tool_market.md` | `github_market.md` 中排除 Plugins、MCP、Skills 和模型研发项目后的 AI 工作流工具 | 上游仓库、官方文档 | 白名单、部署记录、`verify_record.md` |

## 5. `plugins_market.md` 设计

### 5.1 唯一收录权威

使用 Codex app-server JSON-RPC `plugin/list` 作为唯一收录权威。调用时传入当前项目工作目录，使返回范围与当前 Codex 环境一致。

`https://github.com/openai/plugins.git` 不再作为收录源，也不再用于推断 `/plugins` 的完整数量。若某条插件记录提供可验证的 GitHub 仓库，该仓库只能作为描述、许可证或实现信息的补充来源。

### 5.2 完整性与记录身份

文档必须保留 `plugin/list` 返回的每一条记录，不按名称、插件 ID 或展示名称直接去重。记录身份使用以下组合：

```text
marketplace + plugin.id + remotePluginId + version
```

字段为空时保留空值参与记录身份，不自行猜测。Metabase 的两条上游记录均保留，并在异常说明中解释版本和可用状态差异。

相关性不再决定是否收录。它只决定插件出现在“研发者重点索引”中的优先级，从而解决“完整目录不能多也不能少”与“优先服务研发工作”的冲突。

### 5.3 文档结构

`plugins_market.md` 采用以下结构：

1. 采集摘要：时间、Codex 版本、账户环境口径、marketplace 数量、记录总数、加载错误数。
2. 来源和限制：说明 `plugin/list`、CLI marketplace snapshot 和旧 GitHub 仓库之间的区别。
3. 异常记录：列出重复限定 ID、缺失字段、管理员禁用和加载错误。
4. 研发者重点索引：按软件开发、嵌入式与硬件、文档与数据、浏览器与自动化、协作与项目管理等场景整理高相关插件。
5. 完整插件清单：按 marketplace 和官方类别分组，每条响应记录对应一条清单记录。

完整清单至少保留：记录身份、插件 ID、展示名称、marketplace、版本、开发者、官方类别、官方简述、能力、关键词、可用状态、安装策略、认证策略和官方网站。人类编写的分类与说明使用简体中文；官方名称、URL、标识符和原始描述保留源语言，避免把机器翻译误当成官方事实。

### 5.4 采集失败边界

`plugin/list` 当前属于 app-server 实验性接口，未来可能改变 schema。采集器必须执行以下保护：

- 初始化失败、JSON-RPC 错误、marketplace 加载错误或必需字段结构变化时返回失败。
- 失败时不得覆盖上一版有效 `plugins_market.md`。
- 不把 `codex plugin list`、本地缓存或旧 GitHub 仓库自动降级为完整清单。
- 将失败原因写入本地采集日志，但不得记录认证内容或完整敏感响应。
- 只有在完整性校验通过后，才允许替换生成区块。

## 6. `github_market.md` 设计

### 6.1 来源等级

GitHub 周度候选按以下优先级采集：

- A 级：可验证的对应周 GitHub Trending 快照或等价官方周度记录。
- B 级：具备日期、原始链接和可复核采集方法的第三方历史快照。
- C 级：GitHub Search API、仓库创建时间、当前 Star 和仓库事件等组合得到的近似回溯。

如果只能得到 C 级数据，标题、周摘要和条目都必须明确写明“近似候选”，不得称为已验证的历史 Trending 入榜记录。

### 6.2 周次、Star 与去重

- 周次使用 ISO week，按时间倒序排列，更新至采集日所在周；当前目标为 2026-W01 至 2026-W29。
- Star 必须在采集时达到 1000，记录采集时间，并明确它是当前值而非历史周值。
- 使用不区分大小写的规范化 `owner/name` 作为跨周去重键。
- 某仓库在较早周已经收录时，后续周不再收录，也不占后续周 20 至 30 个候选目标名额。
- 少于 20 个合格候选时如实记录，不使用无关项目、训练项目或不足 1000 Star 的项目补位。

### 6.3 研发相关性

保留与以下场景直接相关的项目：

- 通用软件开发、代码审查、测试、调试、CI/CD 和仓库维护。
- MCU、设备驱动、PX4、机器人、ROS、嵌入式和边缘计算。
- FPGA、Zynq、EDA、芯片设计、原理图和 PCB 工作流。
- Codex、coding agent、MCP、Skills、开发者自动化和上下文工程。
- PDF、Word、Excel、网页、知识检索和工程资料处理。

消费娱乐、小说生成、股票投机、视觉小说、纯展示 Demo、基础模型训练、权重微调及与研发工作无直接关系的项目应排除。边界不明确的条目必须给出保留理由，不能只靠关键词分类。

### 6.4 条目质量

每条候选至少包含仓库、当前 Star、采集时间、周次依据、来源等级、项目类型、简体中文核心说明、适用工作流、输入输出、部署条件、主要风险和保留理由。官方英文描述可以作为证据附带，但不能代替中文说明。

## 7. `MCP_market.md` 设计

文档分为两个明确区域：

1. **GitHub 市场派生候选**：只收录 `github_market.md` 中可在 Codex 内不修改上游源码部署使用的 MCP 和 Skill。
2. **当前受管基线**：记录本项目已经管理的 MCP 和 Skill，即使它们不属于 2026 年 GitHub 周度候选。

派生候选必须保留原周次、原仓库和来源等级，并补充安装方式、入口、运行时、凭据、权限、许可证、Codex 兼容性和风险。无法确认无需修改源码即可部署的对象不进入候选正文，只记录在排除说明中。

当前受管基线的状态从白名单、部署记录和 `Notes/verify_record.md` 读取。文档必须使用统一状态词：`approved`、`deployed`、`static_verified`、`load_verified`、`smoke_verified` 和 `blocked`。市场收录、审批、部署和验证不得互相替代。

已知事实必须更新为：sequential-thinking 和 filesystem MCP 均已完成真实部署、加载验证和最小功能 smoke 验证；filesystem 允许根目录仅为 `E:\codex`。memory MCP 仍不得描述为已部署或已验证。

## 8. `tool_market.md` 设计

`tool_market.md` 同样分为“GitHub 市场派生候选”和“当前受管基线”。

派生候选排除 Plugins、MCP、Skills、基础模型训练、模型权重、纯研究训练框架和与研发者工作无关的项目。每个条目保留来源周次，并说明它如何改善开发、测试、文档、数据、硬件或自动化工作流。

当前受管基线主要用于说明已有 Skills 和其他工具的真实状态。Skill 的受管安装和内容 hash 验证只能表述为 load 层证据；没有真正运行时调用时，smoke 状态必须保持 `blocked`。插件功能 smoke 也不得因 load 可见而写成成功。

## 9. 生成与审计流程

### 9.1 Plugins 流程

1. 检查 Codex CLI 版本和 app-server 协议可用性。
2. 初始化 app-server，并调用一次 `plugin/list`。
3. 校验 marketplace 加载错误、必需字段和记录身份。
4. 生成采集摘要、异常区和完整清单。
5. 对生成结果重新解析，比较记录总数和完整身份集合。
6. 校验通过后更新文档；失败时保留上一版。

### 9.2 GitHub 流程

1. 收集周度来源并记录来源等级。
2. 执行 1000 Star 硬过滤。
3. 按研发身份进行人工语义审查，不能只依赖关键词。
4. 按规范化仓库名执行跨周去重。
5. 为每条记录补充中文说明和保留理由。
6. 生成 MCP/Skill 和其他工具派生候选。

### 9.3 状态同步

市场文档不得自行推断运行状态。受管状态必须来自：

- `Resources/tool_whitelist.toml`
- 部署和回滚记录
- `Notes/verify_record.md`
- 当前 Codex 配置的只读核验结果

来源发生冲突时，以时间较新且证据层级更高的记录为准，并在文档中指出冲突。

## 10. 相关文档调整

实施阶段同步修改：

- `Resources/PRD.md`：将 Plugins 市场的主要来源改为当前 `/plugins` 对应的完整目录；取消按相关性删除插件的旧规则，改为完整收录加重点索引。
- `Resources/PP.md`：替换克隆 `openai/plugins.git` 的旧实施步骤，增加 app-server 采集、失败保护和一致性检查。
- 旧市场设计与计划：增加已被本设计取代的醒目标记，保留历史记录但禁止继续按旧来源执行。
- `state/README.md`、`state/TODO.md`、`state/LOG.md`：更新当前阶段、事实结论、进度和资料源经验。

初始 `需求文档.txt` 作为历史输入保留，不回写改变原始需求；正式有效需求以更新后的 `Resources/PRD.md` 为准。

## 11. 验证原则

完成整理后至少验证：

- `plugins_market.md` 的记录数和记录身份集合与同次 `plugin/list` 响应一致。
- 没有把 marketplace 加载错误或采集失败写成成功。
- 四份文档中的来源、时间、状态和验证层级不存在互相矛盾的描述。
- `github_market.md` 不含低于 1000 Star 的条目，且规范化仓库名不存在跨周重复。
- MCP 和工具派生条目都能回溯到 `github_market.md` 原条目。
- 人类编写的 Markdown 说明使用简体中文。
- 文档和日志不包含密钥、Token、认证文件正文或其他敏感数据。

## 12. 已知限制与处理

1. `plugin/list` 是 app-server 实验性接口，未来升级可能破坏采集器。通过版本记录、schema 校验和失败时不覆盖旧文档控制风险。
2. `/plugins` 可见集合可能受账户、工作区策略、地区、feature flag 和管理员策略影响。因此文档只声称与本次采集环境一致，不声称是所有用户的全球统一目录。
3. app-server 返回集合不一定等于界面最终渲染后的卡片数量。当前设计以 `/plugins` 的直接数据请求 `plugin/list` 为可审计边界，并保留全部响应记录；若后续发现 UI 还有额外过滤规则，再单独记录并调整验证器。
4. GitHub 没有稳定公开的官方历史 Trending API。无法获得 A 级历史快照时允许使用 C 级近似数据，但必须降低结论强度。
5. 约 2000 条插件记录会使 Markdown 较大。完整清单用于精确检索，重点索引用于人类阅读，二者不能互相替代。

## 13. 最终决策

- 采用 app-server `plugin/list` 作为 `plugins_market.md` 唯一收录权威。
- 保留全部响应记录，不对上游重复执行破坏性去重。
- 旧 `openai/plugins.git` 仓库退出 Plugins 市场收录链路。
- Plugins 使用“完整清单加研发者重点索引”，不再按相关性删除目录项。
- GitHub 市场继续允许近似回溯，但必须显式标级、严格去重并提高研发相关性。
- MCP 和工具市场严格区分 GitHub 派生候选与当前受管基线。
- 所有状态结论采用统一术语，并由白名单、部署记录和验证记录提供证据。
