# 工具与 Skill 市场

> 采集时间：2026-06-23
> 范围：`Resources/github_market.md` 派生项、当前主工作区 `E:\codex\Skills\AgentSkillsforContextEngineering`。

## 当前结论

首版工具市场优先记录 AI agent 工作流、Skill、代码评审和设计辅助工具。白名单只加入当前本地可读、可计算哈希、且具备 `SKILL.md` 的代表性 Skill；外部 GitHub 项目暂不加入白名单，直到补齐可重复安装来源、许可证和内容哈希。

## 当前主工作区 Skill 集合

本地路径：`E:\codex\Skills\AgentSkillsforContextEngineering`
上游：`https://github.com/muratcankoylan/Agent-Skills-for-Context-Engineering.git`
本地 commit：`25e1fa79a33f0985793bcab3c64dde8d020c5132`
状态：源码存在；未配置；未部署；已静态确认 15 个 `SKILL.md`；未动态验证。

首批纳入 `proposed` 的代表 Skill：

| ID | 价值 | 风险 |
| --- | --- | --- |
| `context-fundamentals` | 上下文工程基础概念和判断框架 | 低 |
| `context-optimization` | token 预算、检索范围和上下文效率优化 | 中 |
| `context-compression` | 长会话压缩和交接摘要 | 中 |
| `filesystem-context` | 文件化上下文、scratchpad 和工具输出离线化 | 中 |
| `tool-design` | agent tool schema、错误边界和 MCP/tool 设计 | 中 |
| `multi-agent-patterns` | 多代理隔离、协作和调度模式 | 中 |
| `harness-engineering` | agent harness、日志、回滚和人工审批边界 | 中 |

暂未纳入白名单的同仓库 Skill：`advanced-evaluation`、`bdi-mental-states`、`context-degradation`、`evaluation`、`hosted-agents`、`latent-briefing`、`memory-systems`、`project-development`。这些后续可按场景补充。

## GitHub 市场派生候选

| 来源周次 | 仓库 | 类型判断 | 当前处理 |
| --- | --- | --- | --- |
| 2026-W01 | `kepano/obsidian-skills` | Obsidian agent skills | 暂不纳白名单；需确认安装结构和许可证 |
| 2026-W07 | `addyosmani/agent-skills` | 编码 agent skills | 暂不纳白名单；需固定目录快照 |
| 2026-W15 | `google-labs-code/design.md` | 设计系统格式和 agent 指令 | 暂不纳白名单；更像规范/工具输入 |
| 2026-W18 | `nexu-io/open-design` | 本地设计 agent 工作台 | 暂不纳白名单；需评估桌面应用依赖 |
| 2026-W19 | `BigPizzaV3/CodexPlusPlus` | CodexApp 增强工具 | 暂不纳白名单；需确认与当前 Codex CLI 兼容 |
| 2026-W21 | `alibaba/open-code-review` | LLM agent 代码评审工具 | 暂不纳白名单；需确认部署方式和数据边界 |
| 2026-W25 | `vercel/eve` | agent 框架 | 暂不纳白名单；需确认成熟度和 API 稳定性 |

## 排除原则

- 不纳入基础模型训练、模型权重或纯研究训练仓库。
- 不把 README/说明文档仓库直接标为可部署工具。
- 不把当前 stars 当作历史热度精确值。
- 不为缺少许可证、安装入口或内容哈希的外部项目生成白名单条目。
