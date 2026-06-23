# GitHub 周榜回溯市场

> 采集时间：2026-06-23 10:40:11Z
> 采集范围：2026-W01 至 2026-W25。
> 当前结论：本文档是 AI/研发工具方向的 GitHub 趋势近似回溯，不是 GitHub 官方历史 Trending 周榜复刻。

## 方法和证据等级

GitHub 当前没有公开的官方历史 Trending 周榜 API。官方可访问的是当前 Trending 页面 `https://github.com/trending?since=weekly`，GitHub REST Search API 可搜索仓库，但不能还原历史 Trending 排名。

本次首版采用以下证据分层：

- A 级：官方或稳定历史快照，例如 Internet Archive 对 `github.com/trending?since=weekly` 的快照。首版尚未逐周解析快照，仅记录为后续优先补强来源。
- B 级：第三方历史 Trending 归档，例如 `bonfy/github-trending`、`vitalets/github-trending-repos`。首版尚未将第三方归档并入条目。
- C 级：GitHub Search API 近似回溯。本次使用 `stars:>=1000 created:<week_start>..<week_end>`，按当前 stars 排序，再用 AI/LLM/agent/MCP 等关键词过滤并按仓库去重。

重要限制：

- `stars_current` 是采集时当前星标数，不是历史当周星标数。
- `week` 是仓库创建周近似，不等于官方 Trending 入榜周。
- 老仓库在 2026 年某周突然爆火不会被 `created:<week>` 查询覆盖。
- GitHub Search 排序和 GitHub Trending 黑盒算法不同，不能恢复官方排序。
- 关键词过滤可能漏掉描述不含 AI 词的相关项目，也可能纳入边界模糊的工作流工具。

## 周度代表候选

下表每周取当前 stars 最高的 AI/研发工具相关候选。所有条目当前 stars 均已达到 1,000；可信度均为 C 级近似。

| 周次 | 代表仓库 | 当前 Stars | 语言 | 创建日期 | 说明 |
| --- | --- | ---: | --- | --- | --- |
| 2026-W01 | [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) | 37,131 | 未标注 | 2026-01-02 | Obsidian agent skills。 |
| 2026-W02 | [koala73/worldmonitor](https://github.com/koala73/worldmonitor) | 58,738 | TypeScript | 2026-01-08 | AI 驱动的全球情报和新闻监控界面。 |
| 2026-W03 | [affaan-m/ECC](https://github.com/affaan-m/ECC) | 220,144 | JavaScript | 2026-01-18 | agent harness 和编码代理工作流优化。 |
| 2026-W04 | [rtk-ai/rtk](https://github.com/rtk-ai/rtk) | 65,220 | Rust | 2026-01-22 | 面向开发命令的 LLM token 压缩代理。 |
| 2026-W05 | [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) | 180,750 | 未标注 | 2026-01-27 | 面向 Claude Code 的技能和行为约束文件。 |
| 2026-W06 | [mattpocock/skills](https://github.com/mattpocock/skills) | 142,669 | Shell | 2026-02-03 | 工程师工作流 skills 集合。 |
| 2026-W07 | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | 65,696 | Shell | 2026-02-15 | 面向编码代理的生产级工程技能。 |
| 2026-W08 | [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | 49,382 | JavaScript | 2026-02-19 | 约束 AI 生成质量和设计品味的 skill。 |
| 2026-W09 | [Panniantong/Agent-Reach](https://github.com/Panniantong/Agent-Reach) | 38,262 | Python | 2026-02-24 | 给 AI agent 提供多平台读取和搜索能力。 |
| 2026-W10 | [karpathy/autoresearch](https://github.com/karpathy/autoresearch) | 88,231 | Python | 2026-03-06 | AI agent 自动运行研究任务。 |
| 2026-W11 | [garrytan/gstack](https://github.com/garrytan/gstack) | 113,609 | TypeScript | 2026-03-11 | 面向 Claude Code 的多角色工具栈。 |
| 2026-W12 | [rohitg00/ai-engineering-from-scratch](https://github.com/rohitg00/ai-engineering-from-scratch) | 35,817 | Python | 2026-03-18 | AI engineering 学习和构建材料。 |
| 2026-W13 | [larksuite/cli](https://github.com/larksuite/cli) | 14,556 | Go | 2026-03-25 | Lark/Feishu CLI，含多业务命令和 agent skills。 |
| 2026-W14 | [ultraworkers/claw-code](https://github.com/ultraworkers/claw-code) | 194,196 | Rust | 2026-03-31 | agent 管理的软件项目实验。 |
| 2026-W15 | [google-labs-code/design.md](https://github.com/google-labs-code/design.md) | 16,105 | TypeScript | 2026-04-10 | 面向编码 agent 的设计系统描述格式。 |
| 2026-W16 | [alchaincyf/huashu-design](https://github.com/alchaincyf/huashu-design) | 19,529 | HTML | 2026-04-19 | 面向 Claude Code 的 HTML 原生设计 skill。 |
| 2026-W17 | [esengine/DeepSeek-Reasonix](https://github.com/esengine/DeepSeek-Reasonix) | 24,022 | Go | 2026-04-21 | 面向终端的 AI coding agent。 |
| 2026-W18 | [nexu-io/open-design](https://github.com/nexu-io/open-design) | 69,645 | TypeScript | 2026-04-28 | 本地优先的开源设计 agent 工作台。 |
| 2026-W19 | [BigPizzaV3/CodexPlusPlus](https://github.com/BigPizzaV3/CodexPlusPlus) | 21,062 | Rust | 2026-05-06 | CodexApp 增强工具。 |
| 2026-W20 | [nexu-io/html-anything](https://github.com/nexu-io/html-anything) | 7,147 | HTML | 2026-05-11 | agentic HTML 编辑和发布工具。 |
| 2026-W21 | [alibaba/open-code-review](https://github.com/alibaba/open-code-review) | 8,550 | Go | 2026-05-18 | LLM agent 与确定性流程结合的代码评审工具。 |
| 2026-W22 | [pewdiepie-archdaemon/odysseus](https://github.com/pewdiepie-archdaemon/odysseus) | 76,575 | Python | 2026-05-31 | 自托管 AI workspace。 |
| 2026-W23 | [unicity-astrid/book](https://github.com/unicity-astrid/book) | 4,694 | Perl | 2026-06-06 | Astrid OS 参考文档，AI 相关性较弱，后续需二次筛选。 |
| 2026-W24 | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) | 51,040 | JavaScript | 2026-06-12 | 约束 AI agent 编码行为的规则集。 |
| 2026-W25 | [vercel/eve](https://github.com/vercel/eve) | 2,348 | TypeScript | 2026-06-16 | 构建 agent 的框架。 |

## 后续补强路径

1. 优先从 Internet Archive CDX API 获取每周 `github.com/trending?since=weekly` 快照，并解析页面中仓库列表。
2. 用 `bonfy/github-trending` 和 `vitalets/github-trending-repos` 交叉验证缺失周次。
3. 对候选仓库逐项确认许可证、安装方式、是否仍维护、是否适合 Codex 管理对象。
4. 对明显不是 AI/研发工具的条目降级或移除，例如 W23 的 `unicity-astrid/book`。
5. 后续进入 Task 14 时，从本文档中筛选 MCP、Skill 和其他 AI 工作流辅助工具。
