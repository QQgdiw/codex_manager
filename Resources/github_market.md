# GitHub 研发项目市场

> 采集与审阅时间：2026-07-15T00:00:00.000Z
> 历史候选为近似回溯，不代表对应周的精确 Trending 排名或历史 Star。

## 2026-W29

- 原始候选：0
- 保留：0
- 排除：0
- 候选不足：保留 0 条，不降低 Star 门槛补足。
- 周次状态：截至采集日的部分周数据。

## 2026-W28

- 原始候选：6
- 保留：1
- 排除：5
- 候选不足：保留 1 条，不降低 Star 门槛补足。

### Robbyant/lingbot-world-v2
<!-- github-record:{"week":"2026-W28","repository":"Robbyant/lingbot-world-v2","stars":1130,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Robbyant/lingbot-world-v2
- 采集时可见 Star：1130
- 项目属性：交互式世界模型与 Agent harness
- 周次依据：候选清单标注为 2026-W28（github-search）；当前公开 README 和技术报告链接仅用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：生成可持续演进的交互式世界，并使用角色规划 Agent 与环境生成 Agent 驱动行为和场景。
- 适用工作流：研发人员加载模型与交互输入，在虚拟世界中运行角色规划和环境生成 Agent，观察和评估长时程交互结果。
- 输入：文本驱动事件、角色动作或交互指令，以及模型权重和推理配置。
- 输出：连续交互式世界状态、视频流和由 Agent 生成的角色行为及环境元素。
- 部署条件：需按仓库当前说明获取模型权重并配置具备相应显存、推理框架和许可条件的运行环境。
- 风险：模型许可为 CC BY-NC-SA，存在非商业限制；世界模型输出可能失真，且实时推理需要评估显存、算力与内容安全边界。
- 保留理由：公开 README 明确包含可规划角色行为和生成环境元素的 Agent harness，适用于具身智能与交互式 AI 工程；按 C 级候选收录。

## 2026-W27

- 原始候选：14
- 保留：5
- 排除：9
- 候选不足：保留 5 条，不降低 Star 门槛补足。

### anthropics/jacobian-lens
<!-- github-record:{"week":"2026-W27","repository":"anthropics/jacobian-lens","stars":1333,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/anthropics/jacobian-lens
- 采集时可见 Star：1333
- 项目属性：大语言模型表征研究实现
- 周次依据：2026-W27 候选，Star 1,333（输入记录）。
- 来源等级：C
- 核心功能：提供 Jacobian lens 的参考实现，用于读取内部激活可表达的语言模型表征。
- 适用工作流：在研究模型内部表征时加载实现与相应激活，运行分析以检查激活对模型输出的影响。
- 输入：兼容模型、内部激活、研究代码和计算环境。
- 输出：内部表征的分析结果、可复现实验代码和研究结论辅助材料。
- 部署条件：按仓库说明配置研究运行环境和所需模型资源；项目标注为参考实现且不维护。
- 风险：该实现不再维护，实验结论可能受模型版本、方法假设和复现条件影响；不能直接用于生产决策。
- 保留理由：由 Anthropic 发布的模型内部表征研究实现，可直接支持 AI 模型与 Agent 研发中的可解释性实验。

### JustVugg/colibri
<!-- github-record:{"week":"2026-W27","repository":"JustVugg/colibri","stars":13026,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/JustVugg/colibri
- 采集时可见 Star：13026
- 项目属性：轻量 MoE 本地推理运行时
- 周次依据：2026-W27 候选，Star 13,026（输入记录）。
- 来源等级：C
- 核心功能：以纯 C 和零第三方依赖实现 MoE 模型运行时，通过磁盘流式加载专家并统一管理显存、内存和存储层级。
- 适用工作流：在资源受限机器上配置模型权重与存储层级，按运行时策略流式加载专家并执行本地推理。
- 输入：受支持的 MoE 模型权重、计算设备、内存和本地存储资源。
- 输出：本地模型推理结果及受内存层级管理约束的运行状态。
- 部署条件：按项目文档在目标机器编译或运行纯 C 实现，并准备足够的存储和模型文件。
- 风险：大模型推理仍会消耗显存、内存、磁盘带宽和电力；模型来源、权重许可和输出安全需单独核验。
- 保留理由：提供面向消费级资源的大模型运行时，可直接支持 AI 工程中的本地推理与性能研究。

### oomol-lab/open-connector
<!-- github-record:{"week":"2026-W27","repository":"oomol-lab/open-connector","stars":2403,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/oomol-lab/open-connector
- 采集时可见 Star：2403
- 项目属性：AI Agent 连接与认证基础设施
- 周次依据：候选清单标注为 2026-W27（github-search）；当前公开仓库元数据仅用于判断用途，未验证该周历史状态。
- 来源等级：C
- 核心功能：统一封装 AI Agent 访问外部 SaaS 服务所需的认证和连接接口。
- 适用工作流：研发人员为 Agent 配置所需服务连接，再经 SDK、CLI、MCP、HTTP 或 OpenAPI 在 Agent 工作流中调用。
- 输入：服务提供方凭据、授权配置和 Agent 工具调用请求。
- 输出：已认证的服务连接与可供 Agent 调用的接口。
- 部署条件：需按仓库当前文档部署网关并配置服务授权、密钥存储和访问策略。
- 风险：会处理第三方服务授权和敏感凭据；上线前必须核验权限范围、密钥保管、审计能力及依赖版本。
- 保留理由：公开说明明确其为 AI Agent 的认证与连接基础设施，可直接用于研发 Agent 框架本体；按 C 级候选收录。

### synthetic-sciences/openscience
<!-- github-record:{"week":"2026-W27","repository":"synthetic-sciences/openscience","stars":2429,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/synthetic-sciences/openscience
- 采集时可见 Star：2429
- 项目属性：科研 AI Agent 工作台
- 周次依据：候选清单标注为 2026-W27（github-search）；当前公开 README 仅用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：在一个连续会话中编排科研 Agent、文献资料、代码和计算资源，覆盖研究闭环。
- 适用工作流：用户提交研究目标，工作台调用研究及领域 Agent 进行资料检索、代码和实验执行、分析与报告撰写。
- 输入：研究目标、论文资料、数据集、代码、模型提供方 API 密钥和计算资源配置。
- 输出：实验代码、分析结果、图表、研究记录和可继续编辑的文档。
- 部署条件：需按仓库说明在浏览器工作台中配置模型提供方、API 密钥、计算资源及所需领域依赖。
- 风险：会处理研究数据、代码和模型 API 密钥，并可能产生模型与云计算成本；实验结论和生成内容必须人工复核。
- 保留理由：公开 README 展示了可执行的科研 Agent、代码实验与文档闭环，直接服务 AI 工程研发；按 C 级候选收录。

### yynxxxxx/Codex-X
<!-- github-record:{"week":"2026-W27","repository":"yynxxxxx/Codex-X","stars":1047,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/yynxxxxx/Codex-X
- 采集时可见 Star：1047
- 项目属性：Codex 开发环境管理工具
- 周次依据：候选清单标注为 2026-W27（github-search）；当前公开 README 仅用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：通过桌面界面管理 Codex 配置、提示词模板、Provider、会话以及 Skills/MCP。
- 适用工作流：研发人员在工具中维护本地 Codex 配置和提示词，切换 Provider 并整理会话及 Skills/MCP，再回到 Codex 工作流执行任务。
- 输入：本地 Codex 配置、提示词模板、Provider 设置、会话记录和 Skills/MCP 配置。
- 输出：更新后的 Codex 本地配置、可复用提示词和整理后的研发会话。
- 部署条件：按仓库当前说明安装跨平台桌面应用，并在本地环境中授予其访问 Codex 配置所需的最小权限。
- 风险：工具可读取或管理本地认证与会话信息；使用前必须审查配置文件访问范围、数据删除行为和第三方 Provider 安全性。
- 保留理由：公开 README 明确其服务 Codex CLI 与桌面端的配置、Skills/MCP 和会话管理，能直接加速 Agent 研发工作流；按 C 级候选收录。

## 2026-W26

- 原始候选：1
- 保留：0
- 排除：1
- 候选不足：保留 0 条，不降低 Star 门槛补足。

## 2026-W25

- 原始候选：2
- 保留：1
- 排除：1
- 候选不足：保留 1 条，不降低 Star 门槛补足。

### vercel/eve
<!-- github-record:{"week":"2026-W25","repository":"vercel/eve","stars":2551,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/vercel/eve
- 采集时可见 Star：2551
- 项目属性：持久 AI Agent 框架
- 周次依据：2026-W25 候选，Star 2,551（输入记录）。
- 来源等级：C
- 核心功能：提供以文件系统为优先作者界面的持久 AI Agent 框架，使 Agent 能力更易检查、扩展和运维。
- 适用工作流：将 Agent 能力、状态和项目约定放入约定文件位置，构建可检查、可延续运行的 Agent 项目。
- 输入：Agent 定义、任务状态、工具配置、文件系统和模型服务。
- 输出：可持久运行、可检查和可扩展的 Agent 能力及任务产物。
- 部署条件：按项目文档在相应 JavaScript 或服务端运行环境中安装和配置。
- 风险：持久状态和文件系统能力可能处理敏感代码或凭据；需要定义访问边界、状态审计和恢复策略。
- 保留理由：项目明确提供耐久 Agent 的框架能力，直接服务研发 Agent 框架本体。

## 2026-W24

- 原始候选：11
- 保留：8
- 排除：3
- 候选不足：保留 8 条，不降低 Star 门槛补足。

### BuilderIO/skills
<!-- github-record:{"week":"2026-W24","repository":"BuilderIO/skills","stars":2584,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/BuilderIO/skills
- 采集时可见 Star：2584
- 项目属性：编码 Agent 技能库
- 周次依据：2026-W24 候选，Star 2,584（输入记录）。
- 来源等级：C
- 核心功能：提供可供编码 Agent 安装和复用的技能集合。
- 适用工作流：根据研发任务选择技能并接入兼容 Agent，使其按技能定义完成实现、设计或工程辅助工作。
- 输入：编码任务、代码库上下文和兼容的 Agent 宿主。
- 输出：由已安装技能约束和辅助的代码、文档或其他研发产物。
- 部署条件：按仓库说明将所选技能安装到兼容的编码 Agent 环境。
- 风险：第三方技能可能引入不可信指令、文件访问或依赖；安装前应审查内容并限制权限。
- 保留理由：技能库可直接扩展编码 Agent 的工程能力，适用于 AI 工程工作流和 Agent 能力研发。

### cobusgreyling/loop-engineering
<!-- github-record:{"week":"2026-W24","repository":"cobusgreyling/loop-engineering","stars":1273,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/cobusgreyling/loop-engineering
- 采集时可见 Star：1273
- 项目属性：Agent 循环工程工具
- 周次依据：2026-W24 候选，Star 1,273（输入记录）。
- 来源等级：C
- 核心功能：通过脚手架、状态文件、预算文件和评分机制设计可评估的 Agent 执行循环。
- 适用工作流：运行 loop-init 初始化循环工程资产，选择 Claude、Codex 或 OpenCode 等工具，再依据评分迭代 Agent 系统。
- 输入：研发目标、Agent 工具选择、技能配置、状态与预算约束。
- 输出：结构化 Agent 循环配置、评分结果和后续执行命令。
- 部署条件：在命令行安装并按项目说明初始化对应 Agent 工作区。
- 风险：自动循环会增加模型调用成本和错误累积风险；应设置预算上限、验收指标和人工审批节点。
- 保留理由：项目直接关注 Agent 循环的设计、评估和运行，属于研发 Agent 框架与工作流的基础能力。

### DietrichGebert/ponytail
<!-- github-record:{"week":"2026-W24","repository":"DietrichGebert/ponytail","stars":56415,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/DietrichGebert/ponytail
- 采集时可见 Star：56415
- 项目属性：精简编码 Agent 技能
- 周次依据：2026-W24 候选，Star 56,415（输入记录）。
- 来源等级：C
- 核心功能：为 Claude Code 等编码 Agent 提供强调最小改动的技能，并保留安全防护约束。
- 适用工作流：在代码任务中启用技能，引导 Agent 以短小、聚焦的实现完成需求并保留必要的安全检查。
- 输入：代码任务、现有代码库和兼容的编码 Agent。
- 输出：范围受控的代码改动及相应的 Agent 执行结果。
- 部署条件：按仓库说明安装到兼容的编码 Agent 宿主。
- 风险：追求最小实现可能遗漏边界条件或非功能需求；仍需执行测试、审查和安全验证。
- 保留理由：直接改善 AI 编码 Agent 的实现范围控制和效率，具有明确的研发工作流价值。

### Forward-Future/loop-library
<!-- github-record:{"week":"2026-W24","repository":"Forward-Future/loop-library","stars":1614,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Forward-Future/loop-library
- 采集时可见 Star：1614
- 项目属性：Agent 循环模式库
- 周次依据：2026-W24 候选，Star 1,614（输入记录）。
- 来源等级：C
- 核心功能：提供 Agent 循环目录及 Loopy 技能，用于发现、审计、修复、构建、运行和复盘循环。
- 适用工作流：在 Agent 任务中通过 Loopy 查找或创建循环模式，对循环进行运行、审计和复盘后沉淀可复用方案。
- 输入：Agent 任务、循环目标、兼容的技能宿主和可选的目录访问。
- 输出：可执行或可发布的循环方案、审计结果和复盘记录。
- 部署条件：按仓库说明接入 Loopy 技能或使用其循环目录。
- 风险：复用的循环可能不符合本项目权限边界和验收条件；应审查循环内容并限制自动化执行范围。
- 保留理由：为 Agent 工作流提供循环发现、审计和沉淀机制，可直接支撑研发 Agent 框架的迭代。

### omnigent-ai/omnigent
<!-- github-record:{"week":"2026-W24","repository":"omnigent-ai/omnigent","stars":4796,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/omnigent-ai/omnigent
- 采集时可见 Star：4796
- 项目属性：多 Agent 元编排框架
- 周次依据：2026-W24 候选，Star 4,796（输入记录）。
- 来源等级：C
- 核心功能：提供用于组织和运行多种 AI Agent 的开源元编排框架。
- 适用工作流：接入不同 Agent 与任务配置，由统一编排层调度、观察和组合其执行结果。
- 输入：Agent 配置、研发任务、模型服务和运行环境。
- 输出：被编排的 Agent 执行结果、任务状态和可组合的自动化流程。
- 部署条件：按项目文档在本地或受控服务环境中部署，并配置所需 Agent 与模型连接。
- 风险：多 Agent 编排会集中处理代码、提示词和凭据，并放大调用成本与错误传播；需隔离权限和审计执行。
- 保留理由：项目定位为所有 AI Agent 的元运行框架，直接服务研发 Agent 框架本体。

### plannotator/effective-html
<!-- github-record:{"week":"2026-W24","repository":"plannotator/effective-html","stars":1158,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/plannotator/effective-html
- 采集时可见 Star：1158
- 项目属性：工程可视化 HTML 技能集
- 周次依据：2026-W24 候选，Star 1,158（输入记录）。
- 来源等级：C
- 核心功能：提供生成自包含 HTML 可视化交付物的技能，面向图表和其他实用视觉产物。
- 适用工作流：将工程说明、计划或数据交给兼容 Agent，生成可直接分发和查看的 HTML 图表或可视化文档。
- 输入：工程文本、结构化数据、展示需求和兼容的 Agent 环境。
- 输出：自包含 HTML 视觉交付物、图表或工程说明页面。
- 部署条件：按仓库说明把所需技能安装到兼容 Agent 宿主。
- 风险：自动生成的图表和说明可能误述工程事实；第三方技能内容与生成结果均需人工复核。
- 保留理由：可直接把工程信息转化为可交付的 HTML 可视化文档，适合工程文档工作流。

### Waishnav/devspace
<!-- github-record:{"week":"2026-W24","repository":"Waishnav/devspace","stars":2423,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Waishnav/devspace
- 采集时可见 Star：2423
- 项目属性：自托管编码 Agent MCP 服务
- 周次依据：2026-W24 候选，Star 2,423（输入记录）。
- 来源等级：C
- 核心功能：通过自托管 MCP 服务让 ChatGPT 安全连接本机项目，读取、编辑、搜索代码并运行工具。
- 适用工作流：在本机启动服务并经受控隧道连接 ChatGPT，使用密码授权后由用户发起代码浏览、修改和终端操作。
- 输入：本地项目、开发工具、终端环境、MCP 配置和受控连接凭据。
- 输出：代码检索与修改结果、命令执行结果和 AI 辅助研发会话。
- 部署条件：在本机自托管服务，配置用户控制的隧道和访问密码。
- 风险：服务可暴露本地文件和终端能力；必须限制网络暴露、保管访问凭据并对每项修改执行审查。
- 保留理由：直接把对话式模型接入受控的本地编码工作流，是具体的 AI 工程基础设施。

### XiaomiMiMo/MiMo-Code
<!-- github-record:{"week":"2026-W24","repository":"XiaomiMiMo/MiMo-Code","stars":10671,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/XiaomiMiMo/MiMo-Code
- 采集时可见 Star：10671
- 项目属性：终端 AI 编码助手
- 周次依据：2026-W24 候选，Star 10,671（输入记录）。
- 来源等级：C
- 核心功能：提供可读写代码、运行命令、管理 Git 并跨会话保留项目记忆的终端原生 AI 编码助手。
- 适用工作流：在代码库中提交开发任务，Agent 利用持久记忆理解项目并执行代码、命令和 Git 操作。
- 输入：代码仓库、研发任务、模型服务配置和受控终端权限。
- 输出：代码改动、命令与 Git 操作结果、跨会话项目记忆。
- 部署条件：按项目文档在终端环境安装，并配置 MiMo 或兼容的模型服务。
- 风险：Agent 能修改代码、执行命令和管理 Git；需隔离凭据、限制工具权限并在提交前验证全部改动。
- 保留理由：具备完整且明确的 AI 编码工作流，直接用于软件与 AI 工程研发。

## 2026-W23

- 原始候选：9
- 保留：5
- 排除：4
- 候选不足：保留 5 条，不降低 Star 门槛补足。

### 12britz/awesome-free-models
<!-- github-record:{"week":"2026-W23","repository":"12britz/awesome-free-models","stars":1008,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/12britz/awesome-free-models
- 采集时可见 Star：1008
- 项目属性：免费 AI 模型、API 与工具选型目录
- 周次依据：候选清单标注为 2026-W23；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：汇总可自托管的开放权重模型、免费 API 套餐和本地 AI 工具，并维护可用链接。
- 适用工作流：AI 工程人员按模型部署、接口或本地运行需求检索候选资源，再对成本、能力、许可和兼容性进行项目级选型。
- 输入：模型能力需求、部署约束、预算和目标 AI 工程环境。
- 输出：可进一步核验的免费模型、API 和工具候选清单。
- 部署条件：作为静态文档仓库直接浏览；实际采用任一条目时需分别完成安装、密钥和许可证配置。
- 风险：免费套餐、链接和模型许可会变化，目录不替代供应商安全审查、性能评测或生产 SLA 验证。
- 保留理由：虽为资源目录，但其模型、API 和本地工具选型流程明确，可直接缩短 AI 工程方案调研。

### diffusionstudio/lottie
<!-- github-record:{"week":"2026-W23","repository":"diffusionstudio/lottie","stars":3756,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/diffusionstudio/lottie
- 采集时可见 Star：3756
- 项目属性：AI 编码 Agent 动画生成框架
- 周次依据：2026-W23 候选，Star 3,756（输入记录）。
- 来源等级：C
- 核心功能：为支持 Claude Code、Codex 等编码 Agent 的工作流生成可用于生产环境的 Lottie 动画。
- 适用工作流：在前端或产品研发任务中描述所需动效，由兼容的编码 Agent 生成、修改并集成 Lottie 动画资产。
- 输入：界面动效需求、目标代码库以及兼容的编码 Agent 环境。
- 输出：可在应用中使用的 Lottie 动画定义和相关代码改动。
- 部署条件：按仓库文档作为编码 Agent 的框架或技能接入项目环境。
- 风险：生成动画可能不满足性能、无障碍或品牌规范；第三方 Agent 指令和写入的代码仍需审查。
- 保留理由：提供面向编码 Agent 的可复用动效生成能力，可直接缩短 AI 工程中界面实现与迭代时间。

### Fullive-AI/Anima
<!-- github-record:{"week":"2026-W23","repository":"Fullive-AI/Anima","stars":1101,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Fullive-AI/Anima
- 采集时可见 Star：1101
- 项目属性：智能硬件 Agent 操作系统
- 周次依据：2026-W23 候选，Star 1,101（输入记录）。
- 来源等级：C
- 核心功能：提供开源 Agent OS，为智能硬件加入感知、决策、学习和可扩展的 AI 能力。
- 适用工作流：在目标硬件上接入设备能力与 Agent 配置，使其基于输入感知环境、执行决策并扩展功能。
- 输入：受支持的硬件设备、传感器或控制能力、Agent 配置和运行环境。
- 输出：可在硬件侧运行的智能交互、决策结果和可扩展设备能力。
- 部署条件：按项目文档在目标智能硬件及其配套运行环境中部署。
- 风险：设备控制和自主决策可能造成安全、隐私与误动作风险；上线前必须限制执行权限并在仿真或受控硬件上验证。
- 保留理由：项目明确定位为智能硬件的开源 Agent OS，直接关联硬件智能化研发工作流。

### JimLiu/baoyu-design
<!-- github-record:{"week":"2026-W23","repository":"JimLiu/baoyu-design","stars":1878,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/JimLiu/baoyu-design
- 采集时可见 Star：1878
- 项目属性：本地编码 Agent 设计技能
- 周次依据：2026-W23 候选，Star 1,878（输入记录）。
- 来源等级：C
- 核心功能：让 Cursor、Claude Code、Claude Desktop 等可访问文件的本地编码 Agent 执行 Claude Design 设计工作流。
- 适用工作流：将界面或视觉需求交给已接入的本地 Agent，由其读取项目上下文并生成或迭代设计相关产物。
- 输入：界面需求、项目文件和兼容的本地编码 Agent。
- 输出：设计建议、界面资产或项目内相关文件改动。
- 部署条件：按仓库说明安装到支持文件访问的本地 Agent 宿主中。
- 风险：Agent 可能读取或修改项目文件，设计结果也可能偏离产品规范；应限制目录权限并进行人工审阅。
- 保留理由：将设计能力以可复用技能接入编码 Agent，可直接辅助 AI 工程中的产品界面研发。

### yorgai/ORG2
<!-- github-record:{"week":"2026-W23","repository":"yorgai/ORG2","stars":1261,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/yorgai/ORG2
- 采集时可见 Star：1261
- 项目属性：可审计编码 Agent 集成开发环境
- 周次依据：2026-W23 候选，Star 1,261（输入记录）。
- 来源等级：C
- 核心功能：提供类似 Cursor 的开源 Agent IDE，重点支持编码过程的可审查性、可追溯性和创作自由度。
- 适用工作流：在 IDE 中让 Agent 参与代码任务，同时检查其上下文、变更和执行轨迹以完成可审计交付。
- 输入：代码仓库、研发任务、模型配置和本地开发环境。
- 输出：可追溯的 Agent 代码变更、任务记录和研发产物。
- 部署条件：按项目文档构建或安装 IDE，并配置所需模型服务与本地工程访问。
- 风险：编码 Agent 能读取或修改工程并可能执行工具调用；应实行最小权限、代码审查和测试验证。
- 保留理由：直接面向可追溯的 AI 编码工作流，适合作为研发 Agent 工具链的一部分。

## 2026-W22

- 原始候选：12
- 保留：3
- 排除：9
- 候选不足：保留 3 条，不降低 Star 门槛补足。

### 2aronS/Duel-Agents
<!-- github-record:{"week":"2026-W22","repository":"2aronS/Duel-Agents","stars":1002,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/2aronS/Duel-Agents
- 采集时可见 Star：1002
- 项目属性：IDE 内多模型 Agent 路由层
- 周次依据：候选清单标注为 2026-W22；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：在 IDE 中将提示请求发送给多个模型，并选择满足结果质量的较低成本响应。
- 适用工作流：开发者或 Agent 提交提示后，路由层并行比较模型回答并返回选定结果，用于研发 Agent 的模型调用策略。
- 输入：IDE 提示、候选模型配置、质量或成本选择策略。
- 输出：选定的模型响应、路由决策及相关调用结果。
- 部署条件：当前 README 表示为官方 IDE 集成包；接入前需核实其服务依赖、模型密钥和 IDE 权限。
- 风险：多模型调用会扩大代码或提示数据暴露面并增加成本；自动质量判断可能不符合工程任务要求。
- 保留理由：项目的职责是研发 Agent 的多模型路由，属于具备明确输入输出的 Agent 框架组件。

### code-yeongyu/lazycodex
<!-- github-record:{"week":"2026-W22","repository":"code-yeongyu/lazycodex","stars":1944,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/code-yeongyu/lazycodex
- 采集时可见 Star：1944
- 项目属性：复杂代码库的 Codex Agent 执行框架
- 周次依据：候选清单标注为 2026-W22；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：为 Codex 提供项目记忆、计划、执行与完成验证的代码库工作框架。
- 适用工作流：将复杂代码任务组织为可保存的项目上下文和计划，驱动 Codex 执行后再进行完成条件验证。
- 输入：复杂代码库、开发需求、Codex 环境、模型配置和工程权限。
- 输出：任务计划、项目记忆、代码改动及验证结果。
- 部署条件：需按当前 README 安装到 Codex 工作环境，并审查其模型配置、Hook 和项目目录访问权限。
- 风险：框架会引导 Agent 读取和修改复杂项目；错误记忆、计划失真、命令执行和模型成本需受到控制。
- 保留理由：README 明确将项目记忆、计划和验证用于 Codex 的复杂代码库研发，是具体的 Agent 工程工作流。

### StarTrail-org/PixelRAG
<!-- github-record:{"week":"2026-W22","repository":"StarTrail-org/PixelRAG","stars":5206,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/StarTrail-org/PixelRAG
- 采集时可见 Star：5206
- 项目属性：网页截图检索增强生成研究实现
- 周次依据：候选清单标注为 2026-W22；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：实现以网页截图作为检索信息源的检索增强生成方法。
- 适用工作流：将网页截图和查询组织为检索增强实验或 Agent 检索组件，比较视觉检索对下游生成任务的影响。
- 输入：网页截图、文本查询、检索语料、模型配置和实验环境。
- 输出：检索结果、生成结果及方法评测或复现实验产物。
- 部署条件：当前 README 将其标注为论文官方代码库；需按项目依赖部署，并先核验模型、数据集和许可证条件。
- 风险：研究复现的指标与生产效果可能不同；截图数据可能含敏感信息，模型和数据依赖还会带来成本与许可风险。
- 保留理由：项目为可复现的 RAG 组件研究实现，可直接支持研发 Agent 的网页视觉检索方案验证。

## 2026-W21

- 原始候选：17
- 保留：9
- 排除：8
- 候选不足：保留 9 条，不降低 Star 门槛补足。

### alibaba/open-code-review
<!-- github-record:{"week":"2026-W21","repository":"alibaba/open-code-review","stars":9208,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/alibaba/open-code-review
- 采集时可见 Star：9208
- 项目属性：AI 代码审查工具
- 周次依据：候选清单标注为 2026-W21；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：对代码变更执行自动化审查并生成问题反馈。
- 适用工作流：向审查任务提供仓库代码、变更差异和审查配置，由工具分析上下文后产出可处理的审查意见。
- 输入：代码仓库、提交或拉取请求差异、审查规则和模型配置。
- 输出：代码问题、审查评论及相应的分析结果。
- 部署条件：当前 README 提供 npm 包与项目安装入口，需按其文档配置受控的代码访问和模型服务。
- 风险：待审查源码和差异可能发送给模型或外部服务；自动评论仍需由维护者复核。
- 保留理由：功能边界明确为代码审查，可直接服务嵌入式、机器人和 AI 工程的软件质量工作流。

### Doorman11991/smallcode
<!-- github-record:{"week":"2026-W21","repository":"Doorman11991/smallcode","stars":1926,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Doorman11991/smallcode
- 采集时可见 Star：1926
- 项目属性：本地小模型 AI 编程 Agent
- 周次依据：候选清单标注为 2026-W21；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：让消费级硬件上的小型语言模型执行终端内编码任务。
- 适用工作流：在本地模型与代码仓库之间运行 Agent，通过工具调用、上下文管理和多步骤反馈完成编码工作。
- 输入：本地代码仓库、开发任务、小型语言模型及终端工具权限。
- 输出：代码改动、命令执行结果和任务会话记录。
- 部署条件：需按当前 README 安装终端应用并配置本地模型运行环境与项目目录权限。
- 风险：Agent 可读取或修改代码并执行命令；本地模型能力不足时可能产生错误改动或不完整结论。
- 保留理由：README 明确面向本地 AI 编程，能直接降低受限硬件环境中的研发自动化门槛。

### KunAgent/Kun
<!-- github-record:{"week":"2026-W21","repository":"KunAgent/Kun","stars":4796,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/KunAgent/Kun
- 采集时可见 Star：4796
- 项目属性：需求驱动的 AI 编程工作流
- 周次依据：候选清单标注为 2026-W21；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：将需求澄清、设计、编码和写作串成可执行的研发闭环。
- 适用工作流：先澄清开发需求，再生成设计和代码，并将过程材料沉淀为可继续迭代的研发产物。
- 输入：功能需求、代码库上下文、兼容模型服务和本地项目权限。
- 输出：需求分析、设计材料、代码改动及研发文档。
- 部署条件：可按当前 README 使用发布版本或从源码运行，并配置模型提供方与工程访问权限。
- 风险：多阶段生成可能放大错误假设；模型凭据、代码权限和自动改动须在受控环境中审查。
- 保留理由：其工作流明确覆盖软件工程的需求、设计、实现与文档，可直接支撑 AI 辅助研发。

### MoonshotAI/kimi-code
<!-- github-record:{"week":"2026-W21","repository":"MoonshotAI/kimi-code","stars":2773,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/MoonshotAI/kimi-code
- 采集时可见 Star：2773
- 项目属性：终端 AI 编程 Agent
- 周次依据：候选清单标注为 2026-W21；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：在终端中读取和编辑代码、执行命令、搜索文件及获取网页资料。
- 适用工作流：对代码任务收集仓库和命令反馈，由 Agent 选择下一步工具操作并生成实现结果。
- 输入：代码仓库、开发任务、终端环境、模型服务和网页访问配置。
- 输出：代码改动、命令结果、文件检索结果及任务会话。
- 部署条件：当前 README 提供各平台安装方式；使用前需配置模型提供方并限制工程和网络权限。
- 风险：工具可修改工程并运行命令，网页内容还可能引入提示注入；应保护模型凭据并复核改动。
- 保留理由：README 明确界定为代码读写与命令执行的终端 Agent，直接服务 AI 辅助工程实现。

### open-gsd/gsd-core
<!-- github-record:{"week":"2026-W21","repository":"open-gsd/gsd-core","stars":5043,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/open-gsd/gsd-core
- 采集时可见 Star：5043
- 项目属性：AI 编程 Agent 的上下文工程与规格驱动开发框架
- 周次依据：候选清单标注为 2026-W21；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：为多种 AI 编程 Agent 提供元提示、上下文工程和规格驱动开发流程。
- 适用工作流：把研发任务分阶段表达为规格、计划和执行上下文，驱动兼容编码 Agent 完成可验证的开发工作。
- 输入：代码库、功能规格、研发约束以及兼容的编码 Agent 环境。
- 输出：结构化规格、任务计划、代码实现和过程上下文。
- 部署条件：按当前 README 安装到 Claude Code、Codex 等兼容宿主，并核验宿主版本、模型配置和项目权限。
- 风险：提示和自动化流程会影响 Agent 的文件与命令操作；错误规格可能被系统化地传播到实现。
- 保留理由：项目直接提供研发 Agent 的上下文与规格工作流基础设施，范围清晰且可复用。

### perplexityai/bumblebee
<!-- github-record:{"week":"2026-W21","repository":"perplexityai/bumblebee","stars":4627,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/perplexityai/bumblebee
- 采集时可见 Star：4627
- 项目属性：开发端点软件供应链清单采集工具
- 周次依据：候选清单标注为 2026-W21；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：只读采集 macOS 和 Linux 开发端点中的包、扩展和开发工具元数据。
- 适用工作流：收到软件包或版本通告后，扫描锁文件、包管理器元数据、扩展清单和受支持工具配置，定位受影响开发机器。
- 输入：安全通告中的包或版本标识，以及可访问的开发端点元数据。
- 输出：匹配的软件包、扩展或开发工具库存结果。
- 部署条件：需按当前 README 在 macOS 或 Linux 开发端点部署，并授予最小化的只读元数据访问权限。
- 风险：本地元数据可暴露内部依赖与开发工具信息；扫描结果应限定访问范围并按版本复核。
- 保留理由：针对研发端点的供应链响应，能直接缩短工程依赖排查和漏洞处置流程。

### study8677/awesome-architecture
<!-- github-record:{"week":"2026-W21","repository":"study8677/awesome-architecture","stars":1568,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/study8677/awesome-architecture
- 采集时可见 Star：1568
- 项目属性：软件架构案例与工程文档知识库
- 周次依据：候选清单标注为 2026-W21；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：整理真实热门系统的架构模板，并提供架构设计教程与配套 Agent 技能入口。
- 适用工作流：研发人员从架构案例和教程中选择参考模式，形成设计决策并在兼容编码 Agent 中使用配套技能辅助设计。
- 输入：系统需求、架构约束和待参考的工程问题。
- 输出：架构参考材料、设计教程和可用于 Agent 的架构设计提示。
- 部署条件：可直接浏览仓库或在线文档；接入配套技能前需按其各自说明核验兼容宿主。
- 风险：案例不能替代当前系统的容量、合规和安全设计；引用模式前应进行项目级技术评审。
- 保留理由：项目明确服务架构设计与工程文档沉淀，且提供面向编码 Agent 的架构辅助入口。

### sybil-solutions/codex-shim
<!-- github-record:{"week":"2026-W21","repository":"sybil-solutions/codex-shim","stars":1016,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/sybil-solutions/codex-shim
- 采集时可见 Star：1016
- 项目属性：Codex 模型适配与本地代理层
- 周次依据：候选清单标注为 2026-W21；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：通过本地兼容端点让 Codex Desktop 路由到可配置的 BYOK 模型或兼容上游。
- 适用工作流：在本机声明模型路由，Codex 向本地代理发起 Responses 兼容请求，代理转换并转发流式响应。
- 输入：Codex Desktop 请求、模型路由配置、上游模型端点及相应凭据。
- 输出：兼容 Codex 的流式模型响应和本地路由日志。
- 部署条件：当前 README 指明以本地 Python 和 aiohttp 服务运行，需限制回环监听并安全保存上游凭据。
- 风险：代理会处理代码上下文和模型凭据；协议转换、上游兼容性和第三方模型的数据边界均需验证。
- 保留理由：它是 Codex 研发 Agent 的模型适配基础设施，具有明确且可审查的工程集成边界。

### thananon/9arm-skills
<!-- github-record:{"week":"2026-W21","repository":"thananon/9arm-skills","stars":2893,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/thananon/9arm-skills
- 采集时可见 Star：2893
- 项目属性：AI 编程 Agent 工程技能库
- 周次依据：候选清单标注为 2026-W21；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：以独立 SKILL.md 目录组织可加载到 Claude Code 等宿主的工程与生产力技能。
- 适用工作流：选择工程类技能并通过技能安装工具加载到兼容 Agent，再在日常代码任务中调用相应流程和脚本。
- 输入：兼容的编码 Agent、目标工程任务和所选技能配置。
- 输出：可被 Agent 调用的工程技能说明、脚本和任务执行辅助。
- 部署条件：当前 README 提供技能目录布局和 npx 安装方式；应只启用已审查的工程技能并锁定脚本来源。
- 风险：仓库含个人、草稿和废弃技能，质量与权限需求不一致；第三方脚本可能读取项目文件或执行命令。
- 保留理由：虽为个人维护集合，但 Star 数达到门槛且工程技能、安装方式和 Agent 接入流程均明确。

## 2026-W20

- 原始候选：27
- 保留：13
- 排除：14
- 候选不足：保留 13 条，不降低 Star 门槛补足。

### deeplethe/forkd
<!-- github-record:{"week":"2026-W20","repository":"deeplethe/forkd","stars":2704,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/deeplethe/forkd
- 采集时可见 Star：2704
- 项目属性：AI Agent 微虚拟机扇出运行时
- 周次依据：候选清单标注为 2026-W20；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：基于 Firecracker 快照和写时复制快速派生 KVM 隔离的 AI Agent 子微虚拟机。
- 适用工作流：预热父微虚拟机并加载依赖或模型，将其暂停为快照；按任务分支出多个隔离子实例并并行执行 Agent 工作。
- 输入：具备 KVM 的 Linux 主机、父虚拟机快照、Agent 运行时依赖和并行任务请求。
- 输出：快速启动的隔离子微虚拟机及其并行 Agent 执行环境。
- 部署条件：作为基于 Firecracker 的本地或服务器端微虚拟机运行时部署在支持硬件虚拟化的 Linux 环境。
- 风险：需要硬件虚拟化、内核和镜像权限；应隔离宿主资源、限制网络与挂载，并控制并发资源消耗。
- 保留理由：项目本体解决研发 Agent 并发执行的隔离与启动开销，运行时边界具体。

### gi-dellav/zerostack
<!-- github-record:{"week":"2026-W20","repository":"gi-dellav/zerostack","stars":1355,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/gi-dellav/zerostack
- 采集时可见 Star：1355
- 项目属性：Rust 轻量级编码 Agent
- 周次依据：候选清单标注为 2026-W20；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：以 Rust 实现低内存占用的编码 Agent，并提供子 Agent 和记忆设计。
- 适用工作流：在代码仓库中配置模型和工具权限，由编码 Agent 理解项目、分配子任务、编辑文件并执行开发命令。
- 输入：本地代码仓库、模型访问配置、任务提示和允许的开发工具权限。
- 输出：代码变更、命令执行结果及 Agent 记忆或子任务处理结果。
- 部署条件：作为本地 Rust 编译或发布的命令行编码 Agent 在开发环境运行。
- 风险：具备读写代码和执行命令能力；应在版本控制下使用，限制命令权限并审查生成变更。
- 保留理由：项目本体是编码 Agent 运行时，直接服务于研发任务执行，且具备明确的工程操作边界。

### google-antigravity/antigravity-cli
<!-- github-record:{"week":"2026-W20","repository":"google-antigravity/antigravity-cli","stars":1295,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/google-antigravity/antigravity-cli
- 采集时可见 Star：1295
- 项目属性：终端 AI 编码 Agent
- 周次依据：候选清单标注为 2026-W20；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：将 Antigravity Agent 的代码库理解、多文件编辑、工具调用和持久历史能力直接提供给终端。
- 适用工作流：在本地代码库中提出研发任务，审阅 Agent 请求的权限后允许其读取、编辑和执行命令，并检查变更结果。
- 输入：本地代码仓库、研发任务、模型登录状态和用户授予的工具权限。
- 输出：代码修改、命令结果、任务执行记录和持久会话历史。
- 部署条件：通过终端 CLI 在本地开发环境中运行，并连接 Antigravity Agent 服务。
- 风险：可修改代码并执行命令；应使用最小权限、受保护分支、变更审查和敏感文件排除规则。
- 保留理由：功能直接面向代码库研发和终端工程操作，属于明确的研发 Agent 本体。

### HermannBjorgvin/Clawdmeter
<!-- github-record:{"week":"2026-W20","repository":"HermannBjorgvin/Clawdmeter","stars":1700,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/HermannBjorgvin/Clawdmeter
- 采集时可见 Star：1700
- 项目属性：ESP32 Claude Code 用量桌面仪表盘
- 周次依据：候选清单标注为 2026-W20；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：在 ESP32-S3 触摸 AMOLED 硬件上通过蓝牙显示 Claude Code 用量，并提供语音模式和模式切换的 HID 按键。
- 适用工作流：烧录并配置 ESP32 设备，与主机蓝牙配对；编码时在实体屏幕查看用量，并用硬件按键触发 Claude Code 常用操作。
- 输入：兼容的 ESP32-S3 开发板、固件、主机蓝牙连接和 Claude Code 使用状态。
- 输出：实体化的编码用量状态显示及蓝牙 HID 快捷操作。
- 部署条件：运行在 Waveshare ESP32-S3-Touch-AMOLED-2.16 及 README 列出的兼容开发板上。
- 风险：蓝牙 HID 会向已配对主机发送按键；应仅与受信任设备配对，并在共享办公环境注意用量信息可见性。
- 保留理由：小众但星标和工作流均具备门槛，直接结合嵌入式硬件与 AI 编码工作台操作。

### LocoreMind/locoagent
<!-- github-record:{"week":"2026-W20","repository":"LocoreMind/locoagent","stars":1017,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/LocoreMind/locoagent
- 采集时可见 Star：1017
- 项目属性：LocoAgent 智能代理
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：面向 Agent 应用构建与运行的智能代理项目。
- 适用工作流：项目名称和定位直接指向 Agent，符合泛 Agent 收录标准。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：项目名称和定位直接指向 Agent，符合泛 Agent 收录标准。

### OpenNSWM-Lab/FAROS
<!-- github-record:{"week":"2026-W20","repository":"OpenNSWM-Lab/FAROS","stars":1161,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/OpenNSWM-Lab/FAROS
- 采集时可见 Star：1161
- 项目属性：FAROS 自主系统项目
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：面向自主系统研究与开发的项目。
- 适用工作流：属于自主系统研发方向，具备 Agent 研究和工程工具的相关性。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：属于自主系统研发方向，具备 Agent 研究和工程工具的相关性。

### simonlin1212/TradingAgents-astock
<!-- github-record:{"week":"2026-W20","repository":"simonlin1212/TradingAgents-astock","stars":1412,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/simonlin1212/TradingAgents-astock
- 采集时可见 Star：1412
- 项目属性：TradingAgents A 股交易代理
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：面向 A 股交易分析的 TradingAgents 项目。
- 适用工作流：明确包含 TradingAgents，属于垂直领域 Agent 应用，符合泛 Agent 标准。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：明确包含 TradingAgents，属于垂直领域 Agent 应用，符合泛 Agent 标准。

### tinyfish-io/bigset
<!-- github-record:{"week":"2026-W20","repository":"tinyfish-io/bigset","stars":1582,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/tinyfish-io/bigset
- 采集时可见 Star：1582
- 项目属性：Bigset Agent 数据集
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：面向智能代理任务或能力评测的数据集项目。
- 适用工作流：服务于 Agent 数据或评测研发，属于 Agent 研发基础设施。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：服务于 Agent 数据或评测研发，属于 Agent 研发基础设施。

### vercel-labs/zerolang
<!-- github-record:{"week":"2026-W20","repository":"vercel-labs/zerolang","stars":5122,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/vercel-labs/zerolang
- 采集时可见 Star：5122
- 项目属性：ZeroLang AI 编程工具
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：面向 AI 编程和软件开发自动化的语言或工具项目。
- 适用工作流：属于 AI 编程研发工具，符合泛 Agent 及研发相关性规则。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：属于 AI 编程研发工具，符合泛 Agent 及研发相关性规则。

### yetone/native-feel-skill
<!-- github-record:{"week":"2026-W20","repository":"yetone/native-feel-skill","stars":1806,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/yetone/native-feel-skill
- 采集时可见 Star：1806
- 项目属性：Native Feel 技能
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：面向 Agent 的 Native Feel 技能项目。
- 适用工作流：明确是 Agent skill，直接符合泛 Agent 收录标准。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：明确是 Agent skill，直接符合泛 Agent 收录标准。

### zarazhangrui/lark-coding-agent-bridge
<!-- github-record:{"week":"2026-W20","repository":"zarazhangrui/lark-coding-agent-bridge","stars":1469,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/zarazhangrui/lark-coding-agent-bridge
- 采集时可见 Star：1469
- 项目属性：Lark 编程代理桥接器
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：连接 Lark 与 coding agent 的桥接工具。
- 适用工作流：明确服务于 coding agent 集成，属于 Agent 研发工具。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：明确服务于 coding agent 集成，属于 Agent 研发工具。

### zhaoxuya520/reverse-skill
<!-- github-record:{"week":"2026-W20","repository":"zhaoxuya520/reverse-skill","stars":6001,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/zhaoxuya520/reverse-skill
- 采集时可见 Star：6001
- 项目属性：逆向技能
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：面向 Agent 的逆向工程技能项目。
- 适用工作流：明确是可供 Agent 使用的技能，且面向研发工作流。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：明确是可供 Agent 使用的技能，且面向研发工作流。

### zLanqing/codex-claude-academic-skills
<!-- github-record:{"week":"2026-W20","repository":"zLanqing/codex-claude-academic-skills","stars":1040,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/zLanqing/codex-claude-academic-skills
- 采集时可见 Star：1040
- 项目属性：学术研发 Agent 技能集
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：为 Codex 和 Claude 提供学术研究、资料处理和写作辅助技能。
- 适用工作流：用于研究资料整理、技术文档分析和学术研发任务编排。
- 输入：论文、研究资料、任务说明和 Agent 配置。
- 输出：结构化研究结果、文档草稿或可复用技能流程。
- 部署条件：需审查技能指令、外部服务依赖和数据访问范围后按需启用。
- 风险：学术结论可能受来源质量和模型幻觉影响，敏感资料还涉及外部服务与数据边界。
- 保留理由：能够加速工程研究与文档处理，并提供可复用的 Agent 技能实现。

## 2026-W19

- 原始候选：19
- 保留：8
- 排除：11
- 候选不足：保留 8 条，不降低 Star 门槛补足。

### BigPizzaV3/CodexPlusPlus
<!-- github-record:{"week":"2026-W19","repository":"BigPizzaV3/CodexPlusPlus","stars":21552,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/BigPizzaV3/CodexPlusPlus
- 采集时可见 Star：21552
- 项目属性：Codex 桌面应用会话与供应商管理工具
- 周次依据：候选清单标注为 2026-W19；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：为 OpenAI Codex/ChatGPT 桌面应用提供外部启动、供应商配置、协议转换、会话管理和界面增强。
- 适用工作流：研发人员在本地配置供应商和会话选项，通过外部启动器打开官方桌面应用，并在编码过程中使用会话与界面增强功能。
- 输入：已安装的 Codex 或 ChatGPT 桌面应用、本地供应商配置及用户授权的服务凭据。
- 输出：带有会话管理、供应商切换和界面增强能力的编码助手桌面工作流。
- 部署条件：作为 Windows 或 macOS 本地外部启动器和辅助服务运行，不修改官方应用安装文件。
- 风险：涉及第三方服务配置和会话数据；应审查凭据存储、服务端点及供应商数据处理边界。
- 保留理由：直接改善 AI 编码助手的本地启动、会话管理和供应商接入流程，研发工作流明确。

### elementalsouls/Claude-BugHunter
<!-- github-record:{"week":"2026-W19","repository":"elementalsouls/Claude-BugHunter","stars":2704,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/elementalsouls/Claude-BugHunter
- 采集时可见 Star：2704
- 项目属性：授权漏洞研究与红队测试技能包
- 周次依据：候选清单标注为 2026-W19；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：为 Claude Code 提供漏洞排查、已公开报告模式、攻击面矩阵、项目脚手架和 Burp MCP 集成。
- 适用工作流：在明确授权的目标和范围内建立测试项目，调用技能执行排查与证据整理，再由人工验证和报告发现。
- 输入：书面授权的测试目标、测试范围、项目资料及安全测试工具配置。
- 输出：漏洞测试线索、结构化发现材料和待人工确认的安全报告内容。
- 部署条件：作为 Claude Code 技能包配合本地安全测试工具和受控测试环境运行。
- 风险：包含红队与漏洞测试流程；仅可在书面授权、隔离环境及人工审查下使用，不能将自动化结果视为已验证漏洞。
- 保留理由：将安全测试活动限定为漏洞发现和工程验证，直接服务于具体的软件安全研发流程。

### LiteLLM-Labs/litellm-agent-control-plane
<!-- github-record:{"week":"2026-W19","repository":"LiteLLM-Labs/litellm-agent-control-plane","stars":1010,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/LiteLLM-Labs/litellm-agent-control-plane
- 采集时可见 Star：1010
- 项目属性：多 Agent 调用控制平面
- 周次依据：候选清单标注为 2026-W19；仅依据当前公开仓库描述作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：为 OpenCode、Claude、Cursor 等不同 Agent 提供统一的调用、接入和控制入口。
- 适用工作流：研发团队连接多个 Agent 提供方或运行时，通过控制平面统一发起调用并管理其接入方式。
- 输入：Agent 提供方配置、运行时端点和调用请求。
- 输出：经统一控制平面路由的 Agent 调用结果与管理入口。
- 部署条件：作为多 Agent 基础设施接入现有研发环境和 Agent 运行时。
- 风险：统一入口会集中凭据、权限和调用数据；应实施最小权限、租户隔离、审计和成本限制。
- 保留理由：项目本体是多 Agent 接入与控制基础设施，可直接支撑研发 Agent 的运行和治理。

### microsoft/AI-Engineering-Coach
<!-- github-record:{"week":"2026-W19","repository":"microsoft/AI-Engineering-Coach","stars":3037,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/microsoft/AI-Engineering-Coach
- 采集时可见 Star：3037
- 项目属性：AI 编码会话工程效能分析工具
- 周次依据：候选清单标注为 2026-W19；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：分析本地 AI 编码助手会话日志，识别提示、会话卫生、代码审查、工具使用和上下文管理中的工程改进点。
- 适用工作流：读取本地编码会话日志，按规则生成练习评分、趋势和反模式分析，再据此调整研发人员的 AI 编码使用方式。
- 输入：本地 AI 编码会话日志和工具使用记录。
- 输出：工程效能指标、趋势视图及会话质量改进建议。
- 部署条件：在本地读取会话日志并提供分析仪表盘，README 表示分析数据不离开本机。
- 风险：会话日志可能包含代码和提示内容；应限制本地访问权限、保留周期和共享范围。
- 保留理由：针对 AI 编码过程提供可执行的会话质量分析，直接加速软件研发工作。

### microsoft/SkillOpt
<!-- github-record:{"week":"2026-W19","repository":"microsoft/SkillOpt","stars":9227,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/microsoft/SkillOpt
- 采集时可见 Star：9227
- 项目属性：Agent 技能优化与评估框架
- 周次依据：候选清单标注为 2026-W19；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：通过轨迹驱动编辑和验证门控迭代，训练可部署的自然语言 Agent 技能，而不更新底层模型权重。
- 适用工作流：准备任务轨迹和验证条件，按批次运行技能优化，再将通过验证的 best_skill.md 用于 Agent 执行。
- 输入：任务轨迹、初始技能文本、评估数据和验证配置。
- 输出：经验证的可复用 Agent 技能及对应优化评估结果。
- 部署条件：以 Python 工具链和版本化文档提供的数据准备、训练和评估命令在研发环境中运行。
- 风险：技能优化可能对特定评测集过拟合；应使用独立任务验证，并人工审查会影响权限或外部操作的技能改动。
- 保留理由：项目本体是面向 Agent 能力迭代的优化与验证框架，研发边界和产物明确。

### opensquilla/opensquilla
<!-- github-record:{"week":"2026-W19","repository":"opensquilla/opensquilla","stars":4721,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/opensquilla/opensquilla
- 采集时可见 Star：4721
- 项目属性：高令牌效率 AI Agent 微内核
- 周次依据：候选清单标注为 2026-W19；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：提供面向命令行、Web UI 和聊天渠道的微内核 AI Agent，并以本地模型路由提升令牌使用效率。
- 适用工作流：配置模型与路由策略，将任务交给 Agent 执行；运行时依据请求分配模型并返回工具调用和任务处理结果。
- 输入：任务提示、模型提供方配置、工具权限和路由策略。
- 输出：Agent 执行结果、模型路由决策和相应的工具交互。
- 部署条件：作为可接入 CLI、Web UI 或聊天渠道的 Agent 运行时部署。
- 风险：模型路由和多渠道接入会扩大数据与工具权限边界；应隔离凭据、限制工具权限并审计任务流量。
- 保留理由：项目本体为 Agent 运行时和模型路由框架，可直接支撑研发 Agent 的构建与运行。

### PaperGuru-AI/PaperGuru-Benchmark
<!-- github-record:{"week":"2026-W19","repository":"PaperGuru-AI/PaperGuru-Benchmark","stars":1214,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/PaperGuru-AI/PaperGuru-Benchmark
- 采集时可见 Star：1214
- 项目属性：长程 LLM Agent 记忆评测基准
- 周次依据：候选清单标注为 2026-W19；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：评估具生命周期语义的长程 Agent 记忆能力，并报告在 PaperBench 和 SurveyBench 上的表现。
- 适用工作流：选择受测 Agent 和记忆方案，按基准任务运行评测，再对比任务完成表现和记忆机制结果。
- 输入：受测 LLM Agent、记忆实现、基准任务数据和评测配置。
- 输出：长程记忆能力的基准分数、对比结果和可复现实验材料。
- 部署条件：以代码仓库和公开基准数据形式在 Agent 研发环境中运行。
- 风险：基准覆盖范围和数据污染会影响结论；不得把单一分数外推为真实生产任务能力。
- 保留理由：为 Agent 记忆研发提供边界清晰的评测工作流，而非面向终端用户的泛 Agent 产品。

### strukto-ai/mirage
<!-- github-record:{"week":"2026-W19","repository":"strukto-ai/mirage","stars":3241,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/strukto-ai/mirage
- 采集时可见 Star：3241
- 项目属性：AI Agent 统一虚拟文件系统
- 周次依据：候选清单标注为 2026-W19；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：将 S3、Google Drive、Slack、Gmail 和 Redis 等数据源挂载为统一文件系统，供 Agent 以 Bash 语义访问。
- 适用工作流：在工作区声明数据后端及访问权限，执行文件系统命令跨后端读取、检索和处理数据，再将结果交给 Agent 工作流。
- 输入：资源挂载定义、数据后端连接配置、Agent 命令和受限访问凭据。
- 输出：统一文件路径视图以及跨数据源的命令执行和检索结果。
- 部署条件：作为 TypeScript 工作区库嵌入 Agent 运行时和本地或服务端开发环境。
- 风险：统一挂载易聚合敏感企业数据；应按后端最小授权、隔离工作区、过滤输出并审计 Agent 命令。
- 保留理由：项目为 Agent 数据访问层基础设施，可直接降低研发 Agent 集成多数据源的实现成本。

## 2026-W18

- 原始候选：30
- 保留：4
- 排除：26
- 候选不足：保留 4 条，不降低 Star 门槛补足。

### cursor/cookbook
<!-- github-record:{"week":"2026-W18","repository":"cursor/cookbook","stars":3946,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/cursor/cookbook
- 采集时可见 Star：3946
- 项目属性：AI 编码 Agent 开发示例库
- 周次依据：2026-W18 周榜候选项目
- 来源等级：C
- 核心功能：提供 Cursor Agent 的钩子、云端运行和 SDK 集成示例。
- 适用工作流：选择钩子、云端 Worker 或 SDK 示例，在项目中接入 Agent 事件审计、自动检查和任务执行流程。
- 输入：代码仓库、Agent 任务定义、运行环境与必要的云端配置。
- 输出：可复用的编码 Agent 集成代码、钩子配置和部署示例。
- 部署条件：作为团队 AI 编码 Agent 的本地开发、CI 或自托管云端工作流参考。
- 风险：示例需要结合权限、成本控制和代码审查策略进行生产化加固。
- 保留理由：覆盖编码 Agent SDK、事件钩子和自托管执行，能直接加速 AI 工程团队构建研发 Agent 工作流。

### google-antigravity/antigravity-sdk-python
<!-- github-record:{"week":"2026-W18","repository":"google-antigravity/antigravity-sdk-python","stars":2007,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/google-antigravity/antigravity-sdk-python
- 采集时可见 Star：2007
- 项目属性：AI Agent 开发 SDK
- 周次依据：2026-W18 周榜候选项目
- 来源等级：C
- 核心功能：提供 Python 库以构建并运行基于 Google Antigravity 的 AI Agent。
- 适用工作流：在 Python 项目中定义 Agent、模型与工具调用，接入技能和 MCP 能力后运行、观测并迭代任务。
- 输入：Agent 指令、模型配置、工具接口、技能与任务数据。
- 输出：可运行的 Agent 应用、执行结果与可集成的 SDK 调用代码。
- 部署条件：作为 AI 工程服务或研发 Agent 平台的 Python 依赖部署。
- 风险：依赖外部模型服务与平台能力，需评估凭据管理、配额、延迟和供应商锁定。
- 保留理由：官方 Agent SDK 直接提供构建、编排和集成研发 Agent 的基础能力，属于研发 Agent 框架本体。

### jherrodthomas/automotive-skills-suite
<!-- github-record:{"week":"2026-W18","repository":"jherrodthomas/automotive-skills-suite","stars":1755,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/jherrodthomas/automotive-skills-suite
- 采集时可见 Star：1755
- 项目属性：汽车嵌入式与系统工程 Agent 技能套件
- 周次依据：2026-W18 周榜候选项目
- 来源等级：C
- 核心功能：提供覆盖功能安全、网络安全、AUTOSAR、诊断、标定、MBSE 与验证确认的汽车工程技能。
- 适用工作流：针对工程任务选择技能生成工件，再由配套审阅技能按标准和 KPI 对产出进行确认。
- 输入：系统需求、架构与接口资料、适用标准、验证约束和项目上下文。
- 输出：安全、质量、诊断、MBSE 与验证确认等工程文档和审阅结果。
- 部署条件：安装到兼容的研发 Agent 环境，作为汽车嵌入式和系统工程流程的技能库。
- 风险：标准符合性结论必须由具备资质的工程师复核，且需按项目版本核对法规与标准。
- 保留理由：面向汽车嵌入式、系统工程和工程文档，提供可执行技能与审阅闭环，可直接加速硬件研发工作。

### jingyaogong/minimind-o
<!-- github-record:{"week":"2026-W18","repository":"jingyaogong/minimind-o","stars":1961,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/jingyaogong/minimind-o
- 采集时可见 Star：1961
- 项目属性：轻量大语言模型训练与推理工程
- 周次依据：2026-W18 周榜候选项目
- 来源等级：C
- 核心功能：提供小型语言模型从训练到推理的可复现实验与实现。
- 适用工作流：准备数据和训练配置，运行预训练、微调或推理实验，并依据日志和评测迭代模型参数。
- 输入：训练语料、模型与训练超参数、计算资源和评测数据集。
- 输出：模型检查点、训练日志、推理结果和可复现的实验实现。
- 部署条件：作为 AI 模型研发中的本地实验、教学验证或原型训练项目部署。
- 风险：小规模复现结果不等同于生产模型能力，训练数据许可、算力成本和评测偏差需单独控制。
- 保留理由：直接覆盖语言模型训练、微调和推理的工程实践，可用于 AI 工程研发与实验迭代。

## 2026-W17

- 原始候选：30
- 保留：7
- 排除：23
- 候选不足：保留 7 条，不降低 Star 门槛补足。

### crynta/terax-ai
<!-- github-record:{"week":"2026-W17","repository":"crynta/terax-ai","stars":7339,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/crynta/terax-ai
- 采集时可见 Star：7339
- 项目属性：终端优先的 AI 原生开发工作区
- 周次依据：候选清单标注为 2026-W17；以当前公开 README 作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：提供轻量级终端优先工作区，承载 AI 编码、项目操作和开发会话。
- 适用工作流：开发者在工作区中打开代码任务并调用 AI 能力完成编辑、命令执行和项目开发。
- 输入：代码仓库、开发任务、模型配置和本地工具权限。
- 输出：代码修改、终端执行结果和可持续的 AI 开发会话。
- 部署条件：按仓库说明在 Windows、macOS 或 Linux 的本地开发环境安装运行。
- 风险：Agent 的文件和命令权限、模型凭据及第三方工具接入需按项目最小权限控制。
- 保留理由：项目本体是 AI 原生开发工作区，可直接缩短 AI 工程的编码与终端协作流程。

### earthtojake/text-to-cad
<!-- github-record:{"week":"2026-W17","repository":"earthtojake/text-to-cad","stars":6905,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/earthtojake/text-to-cad
- 采集时可见 Star：6905
- 项目属性：CAD、机器人与硬件设计 Agent 技能库
- 周次依据：候选清单标注为 2026-W17；以当前公开 README 作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：为 Agent 提供从自然语言需求生成、预览和迭代 CAD 几何的技能。
- 适用工作流：工程师描述零件、机构或设计约束，设计 Agent 调用技能生成并检查 CAD 模型，再按反馈迭代。
- 输入：自然语言设计需求、尺寸参数、几何约束和目标 CAD 工程上下文。
- 输出：可预览和继续编辑的 CAD 几何、设计脚本或模型产物。
- 部署条件：作为兼容 Agent 的技能库安装，并接入本地 CAD 与预览环境。
- 风险：自动生成的几何、尺寸、公差和可制造性必须经工程师复核，不可直接替代设计验证。
- 保留理由：README 明确覆盖 CAD、机器人和硬件设计 Agent，可直接加速硬件与机器人研发。

### esengine/DeepSeek-Reasonix
<!-- github-record:{"week":"2026-W17","repository":"esengine/DeepSeek-Reasonix","stars":24532,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/esengine/DeepSeek-Reasonix
- 采集时可见 Star：24532
- 项目属性：DeepSeek 原生终端 AI 编码 Agent
- 周次依据：候选清单标注为 2026-W17；以当前公开 README 作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：提供带文件系统、受控 Shell、技能和子 Agent 能力的终端编码 Agent，并针对缓存稳定性优化执行循环。
- 适用工作流：在目标代码目录启动 Agent，读取与编辑文件、按门控执行命令，并通过技能或子 Agent 处理研发任务。
- 输入：代码仓库、开发需求、DeepSeek 模型配置和受限本地工具权限。
- 输出：代码变更、命令结果、会话记录和可复用技能执行结果。
- 部署条件：按仓库说明在本地终端或配套 Tauri 客户端运行，并配置模型密钥。
- 风险：Agent 可访问工程文件与 Shell；应限制工作目录、审批命令执行并保护模型凭据。
- 保留理由：项目本体是可运行的 AI 编码 Agent，直接服务 AI 工程开发与 Agent 实现研究。

### GammaLabTechnologies/harmonist
<!-- github-record:{"week":"2026-W17","repository":"GammaLabTechnologies/harmonist","stars":1963,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/GammaLabTechnologies/harmonist
- 采集时可见 Star：1963
- 项目属性：可移植多 Agent 编排框架
- 周次依据：候选清单标注为 2026-W17；以当前公开 README 作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：为多种 AI 编码助手提供带机械化协议约束的多 Agent 协作与任务编排能力。
- 适用工作流：将框架集成到工程后，按协议分派角色、执行子任务、交换产物并进行流程门控。
- 输入：研发任务、工程上下文、Agent 配置和协作协议。
- 输出：受协议约束的多 Agent 执行记录、任务产物和协作结果。
- 部署条件：作为项目级框架接入 Cursor、Claude Code、Copilot、Windsurf、Aider 等兼容编码助手。
- 风险：多 Agent 协调会增加上下文、权限和调试复杂度，协议须与现有研发规范共同审查。
- 保留理由：README 明确定位为多 Agent 框架本体，可直接提供 AI 工程研发编排能力。

### Imbad0202/academic-research-skills-codex
<!-- github-record:{"week":"2026-W17","repository":"Imbad0202/academic-research-skills-codex","stars":4741,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Imbad0202/academic-research-skills-codex
- 采集时可见 Star：4741
- 项目属性：Codex 科研与实验工作流技能套件
- 周次依据：候选清单标注为 2026-W17；以当前公开 README 作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：将深度调研、论文撰写、论文审阅和实验 Agent 等科研流程打包为可安装的 Codex Skill。
- 适用工作流：研发人员提供研究问题、资料或实验任务，Agent 调用对应技能完成调研、实验编排、文档撰写与审阅。
- 输入：研究问题、论文资料、实验约束和项目上下文。
- 输出：调研结论、实验工作流、论文草稿和审阅意见。
- 部署条件：按仓库说明作为单一 Codex Skill 安装到本地 Agent 环境。
- 风险：调研、引用、实验建议和论文文本均须人工验证，且非商业许可证需核对使用边界。
- 保留理由：提供可复用的实验与科研文档工作流，可直接支持 AI 工程研究和研发 Agent 实践。

### NVlabs/cuda-oxide
<!-- github-record:{"week":"2026-W17","repository":"NVlabs/cuda-oxide","stars":2822,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/NVlabs/cuda-oxide
- 采集时可见 Star：2822
- 项目属性：Rust CUDA GPU 内核编译后端
- 周次依据：候选清单标注为 2026-W17；以当前公开 README 作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：通过自定义 rustc 后端将纯 Rust 的 GPU 内核编译为 CUDA PTX，并支持主机与设备代码单源构建。
- 适用工作流：AI 或高性能工程师在 Rust 工程中编写标记内核，使用 cargo oxide 构建并将生成内核集成到计算任务。
- 输入：Rust 主机代码、带内核标记的 GPU 代码、CUDA 工具链和构建配置。
- 输出：CUDA PTX、可调用 GPU 内核和构建结果。
- 部署条件：作为 Rust 工具链扩展集成到需要 CUDA 加速的本地 AI 或高性能计算工程。
- 风险：依赖特定 Rust、CUDA 与 GPU 环境；须用目标硬件验证数值正确性、性能和内存安全边界。
- 保留理由：直接提供 AI 工程常用的 GPU 内核开发与编译能力，且来自 NVIDIA Labs。

### Yuan1z0825/nature-skills
<!-- github-record:{"week":"2026-W17","repository":"Yuan1z0825/nature-skills","stars":23131,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Yuan1z0825/nature-skills
- 采集时可见 Star：23131
- 项目属性：科研 Agent 技能库
- 周次依据：候选清单标注为 2026-W17；以当前公开 README 作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：提供论文阅读、图文对照翻译、文献汇报、论文润色、科研绘图等可安装科研技能。
- 适用工作流：将论文、段落、审稿意见或科研任务交给 Agent，按技能生成带来源的笔记、文档、汇报和图示草稿。
- 输入：论文 PDF、研究资料、审稿意见、实验或写作任务描述。
- 输出：论文阅读笔记、科研文档草稿、文献汇报和科研图示。
- 部署条件：按仓库说明保留完整技能目录，并安装或映射到 Codex、Claude Code 等兼容 Agent。
- 风险：论文结论、引用、翻译和图示必须由领域专家复核；外部论文和脚本处理需遵守数据与版权边界。
- 保留理由：提供具名的科研阅读、实验文档与论文产出流程，可直接加速 AI 工程研究和研发文档工作。

## 2026-W16

- 原始候选：30
- 保留：0
- 排除：30
- 候选不足：保留 0 条，不降低 Star 门槛补足。

## 2026-W15

- 原始候选：30
- 保留：0
- 排除：30
- 候选不足：保留 0 条，不降低 Star 门槛补足。

## 2026-W14

- 原始候选：30
- 保留：16
- 排除：14
- 候选不足：保留 16 条，不降低 Star 门槛补足。

### claude-code-best/claude-code
<!-- github-record:{"week":"2026-W14","repository":"claude-code-best/claude-code","stars":20360,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/claude-code-best/claude-code
- 采集时可见 Star：20360
- 项目属性：本地 AI 编码 Agent 工程实现
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：提供可运行、构建和调试的 Claude Code 风格编码 Agent 工程实现。
- 适用工作流：开发者在本地构建并运行 Agent，对代码任务进行交互、工具调用和调试。
- 输入：代码仓库、开发任务、模型配置及本地工具权限。
- 输出：代码修改、命令执行结果和编码会话产物。
- 部署条件：按仓库提供的工程说明在本地开发环境构建和运行。
- 风险：需核验上游来源、许可证、模型凭据和执行权限，避免将不可信实现接入生产代码库。
- 保留理由：核心对象是可构建的编码 Agent，直接服务 AI 工程开发与 Agent 实现研究。

### drona23/claude-token-efficient
<!-- github-record:{"week":"2026-W14","repository":"drona23/claude-token-efficient","stars":5697,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/drona23/claude-token-efficient
- 采集时可见 Star：5697
- 项目属性：AI 编码 Agent 上下文与输出约束配置
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：通过单个 CLAUDE.md 约束 Claude Code 在高负载流程中保持简洁输出。
- 适用工作流：将配置放入工程后，编码 Agent 在任务执行时遵循输出与上下文约束。
- 输入：CLAUDE.md 配置和 Claude Code 编码会话。
- 输出：更短的 Agent 响应及较低的上下文消耗。
- 部署条件：作为项目级 CLAUDE.md 放入本地代码仓库。
- 风险：过度压缩输出可能遗漏推理、异常或验收信息，需按任务风险调整约束。
- 保留理由：直接优化编码 Agent 的上下文使用和工程交互效率，属于 AI 工程工作流。

### google/skills
<!-- github-record:{"week":"2026-W14","repository":"google/skills","stars":14098,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/google/skills
- 采集时可见 Star：14098
- 项目属性：Google 技术栈 Agent 技能库
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：提供面向 Google 产品和技术的 Agent Skills。
- 适用工作流：开发者选择并安装相应技能，使 Agent 按技术栈约束完成开发或运维任务。
- 输入：支持 Skills 的 Agent、Google 技术栈任务及项目上下文。
- 输出：可复用的技能指令和受技能约束的任务执行结果。
- 部署条件：作为兼容 Agent 环境中的本地技能包或项目配置使用。
- 风险：技能可能依赖外部服务、权限或版本假设，接入前需审阅指令与凭据边界。
- 保留理由：技能包直接扩展研发 Agent 在具体技术栈中的能力，属于 Agent 框架生态。

### HKUDS/OpenHarness
<!-- github-record:{"week":"2026-W14","repository":"HKUDS/OpenHarness","stars":14139,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/HKUDS/OpenHarness
- 采集时可见 Star：14139
- 项目属性：开放 Agent Harness 框架
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：提供带内置个人 Agent 的开放 Agent Harness。
- 适用工作流：配置 Agent、模型、工具和任务，在 Harness 中运行并管理 Agent 执行。
- 输入：任务目标、模型服务、工具连接和运行配置。
- 输出：Agent 执行结果、运行状态和可复用的 Harness 能力。
- 部署条件：按项目运行说明部署为本地或受控环境中的 Agent 运行框架。
- 风险：Agent 工具调用可能访问文件、网络或外部服务，需实施最小权限和运行审计。
- 保留理由：项目明确以 Agent Harness 为核心，属于研发 Agent 框架本体。

### kevinrgu/autoagent
<!-- github-record:{"week":"2026-W14","repository":"kevinrgu/autoagent","stars":4506,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/kevinrgu/autoagent
- 采集时可见 Star：4506
- 项目属性：自主 Agent Harness 工程框架
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：提供自主 Harness Engineering 能力，用于构建和运行 Agent。
- 适用工作流：定义任务和运行约束，由 Harness 编排模型、工具与执行循环完成任务。
- 输入：任务目标、Agent 配置、工具权限和模型服务。
- 输出：Agent 执行记录、任务结果及可迭代的 Harness 配置。
- 部署条件：作为本地或受控基础设施中的 Agent 工程运行组件部署。
- 风险：自动化执行会放大工具权限和错误规划的影响，需隔离环境并保留人工门禁。
- 保留理由：公开定位明确为自主 Harness Engineering，直接属于研发 Agent 框架本体。

### Kuberwastaken/claurst
<!-- github-record:{"week":"2026-W14","repository":"Kuberwastaken/claurst","stars":9860,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Kuberwastaken/claurst
- 采集时可见 Star：9860
- 项目属性：面向交付的 Agentic Coding 工具
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：为开发者提供以 Agent 驱动的编码与交付能力。
- 适用工作流：开发者给出工程任务，编码 Agent 在项目环境中规划、实施并反馈任务进展。
- 输入：代码仓库、开发任务、模型配置和本地工具权限。
- 输出：代码改动、任务执行反馈和交付产物。
- 部署条件：按项目安装说明作为本地开发工具运行。
- 风险：编码 Agent 可改动代码或执行命令，需限制工作区、密钥访问和自动提交权限。
- 保留理由：功能明确限定为 Agentic Coding，可直接加速 AI 工程实现工作。

### lintsinghua/claude-code-book
<!-- github-record:{"week":"2026-W14","repository":"lintsinghua/claude-code-book","stars":3757,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/lintsinghua/claude-code-book
- 采集时可见 Star：3757
- 项目属性：Agent Harness 架构工程文档
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：系统拆解 Claude Code 的 Agent Harness 架构，并说明如何构建自身 Harness。
- 适用工作流：研发人员阅读对话循环、工具调用和 Harness 架构分析，将结论用于设计或实现 Agent。
- 输入：Agent 架构研究需求和工程学习上下文。
- 输出：可用于 Agent 设计、实现和评审的架构知识与文档材料。
- 部署条件：作为在线或仓库内工程文档用于研发团队学习和设计评审。
- 风险：对特定产品的分析可能随版本变化失效，设计决策应以实际接口和测试验证为准。
- 保留理由：直接解释并支持构建研发 Agent Harness，符合研发 Agent 框架与工程文档范围。

### MemPalace/mempalace
<!-- github-record:{"week":"2026-W14","repository":"MemPalace/mempalace","stars":56335,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/MemPalace/mempalace
- 采集时可见 Star：56335
- 项目属性：开源 AI Agent 记忆系统
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：提供经基准评测的开源 AI 记忆能力。
- 适用工作流：Agent 写入交互或任务记忆，在后续任务中检索相关信息以维持长期上下文。
- 输入：Agent 对话、任务事件、文档片段和记忆查询。
- 输出：可检索的记忆记录及供 Agent 使用的上下文结果。
- 部署条件：作为 Agent 系统的记忆服务或应用内组件集成。
- 风险：记忆库可能保存敏感代码和业务数据，需设置保留期、访问控制、脱敏与删除机制。
- 保留理由：Agent 长期记忆是研发 Agent 框架的基础组件，可直接用于 AI 工程系统。

### open-multi-agent/open-multi-agent
<!-- github-record:{"week":"2026-W14","repository":"open-multi-agent/open-multi-agent","stars":6436,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/open-multi-agent/open-multi-agent
- 采集时可见 Star：6436
- 项目属性：TypeScript 多 Agent 动态编排框架
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：基于任务目标在运行时规划 DAG，并跨多种模型编排多个 Agent。
- 适用工作流：输入目标后协调器生成任务 DAG，调度 Agent 与所选 LLM 执行并汇总结果。
- 输入：任务目标、Agent 配置、模型选择和工具权限。
- 输出：动态任务图、Agent 执行结果和编排状态。
- 部署条件：作为 TypeScript AI Agent 服务或研发自动化组件部署。
- 风险：动态规划和跨模型执行会增加成本、可观测性和权限治理复杂度。
- 保留理由：提供多 Agent 规划与执行的明确框架能力，属于研发 Agent 框架本体。

### openai/codex-plugin-cc
<!-- github-record:{"week":"2026-W14","repository":"openai/codex-plugin-cc","stars":21607,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/openai/codex-plugin-cc
- 采集时可见 Star：21607
- 项目属性：Codex 与 Claude Code 协作插件
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：使 Claude Code 调用 Codex 进行代码审阅或任务委派。
- 适用工作流：在 Claude Code 会话中将审阅或子任务委派给 Codex，再接收其结果用于研发决策。
- 输入：代码任务、代码上下文、Claude Code 会话及 Codex 配置。
- 输出：代码审阅意见、受委派任务结果和协作记录。
- 部署条件：作为 Claude Code 中的 Codex 插件安装和配置。
- 风险：跨 Agent 委派会传递代码上下文，需控制模型凭据、敏感信息和外部工具权限。
- 保留理由：直接实现编码 Agent 的协作与审阅，能加速 AI 工程研发流程。

### safishamsi/graphify
<!-- github-record:{"week":"2026-W14","repository":"safishamsi/graphify","stars":71779,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/safishamsi/graphify
- 采集时可见 Star：71779
- 项目属性：代码与技术资料知识图谱 Agent 技能
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：将代码、SQL、脚本、文档、论文及媒体资料转换为可查询的知识图谱。
- 适用工作流：选择工程目录或资料，技能解析跨层资产并构建统一图谱供编码 Agent 查询。
- 输入：代码目录、数据库模式、脚本、技术文档或研究资料。
- 输出：可查询知识图谱及代码与基础设施关联上下文。
- 部署条件：作为兼容 Claude Code、Codex 等编码助手的本地技能安装。
- 风险：解析过程可能读取敏感源码和文档，需控制索引范围、存储位置和访问权限。
- 保留理由：直接解决代码库与工程资料的结构化理解问题，可加速 AI 工程和技术文档工作。

### sanbuphy/learn-coding-agent
<!-- github-record:{"week":"2026-W14","repository":"sanbuphy/learn-coding-agent","stars":12041,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/sanbuphy/learn-coding-agent
- 采集时可见 Star：12041
- 项目属性：编码 Agent 研究资料
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：整理编码 Agent 的研究内容。
- 适用工作流：研发人员以研究材料理解编码 Agent 的方法、设计与评估，并用于方案验证。
- 输入：编码 Agent 研究问题和学习需求。
- 输出：编码 Agent 研究资料及可复用的技术认知。
- 部署条件：作为仓库资料用于 AI 工程研发、设计评审或培训。
- 风险：研究资料可能过时或缺少实验复现，结论需结合原始论文、实现和评测验证。
- 保留理由：主题明确限定为 Coding Agents，直接服务研发 Agent 的研究与实现工作。

### tvytlx/ai-agent-deep-dive
<!-- github-record:{"week":"2026-W14","repository":"tvytlx/ai-agent-deep-dive","stars":5793,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/tvytlx/ai-agent-deep-dive
- 采集时可见 Star：5793
- 项目属性：AI Agent 源码研究报告
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：提供 AI Agent 源码的深度研究报告。
- 适用工作流：研发人员阅读源码分析，提取任务循环、工具调用和架构设计要点用于 Agent 方案实现。
- 输入：AI Agent 架构研究需求和源码分析问题。
- 输出：结构化源码研究结论和 Agent 设计参考材料。
- 部署条件：作为仓库内技术研究文档用于 Agent 研发和架构评审。
- 风险：源码分析的适用性受目标版本和实现细节影响，关键结论需回到原实现验证。
- 保留理由：直接面向 AI Agent 源码与架构研究，可支持研发 Agent 框架设计。

### VoltAgent/awesome-design-md
<!-- github-record:{"week":"2026-W14","repository":"VoltAgent/awesome-design-md","stars":92956,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/VoltAgent/awesome-design-md
- 采集时可见 Star：92956
- 项目属性：编码 Agent 设计规范文档库
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：汇集品牌设计系统的 DESIGN.md 分析，供编码 Agent 生成匹配的界面。
- 适用工作流：开发者选择设计规范文件放入项目，编码 Agent 据此生成或调整产品界面实现。
- 输入：DESIGN.md 设计约束、项目代码和界面开发需求。
- 输出：与指定设计系统一致的界面代码和设计参考文档。
- 部署条件：以项目内 DESIGN.md 的形式接入支持该约定的编码 Agent 工作流。
- 风险：设计规范的许可、品牌使用边界和生成 UI 的可访问性均需人工审查。
- 保留理由：为编码 Agent 提供具体的设计文档输入，可直接加速软件工程中的界面实现与文档对齐。

### withcoral/coral
<!-- github-record:{"week":"2026-W14","repository":"withcoral/coral","stars":5099,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/withcoral/coral
- 采集时可见 Star：5099
- 项目属性：面向 Agent 的跨源 SQL 数据接口
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：以统一 SQL 接口连接 API、文件和实时数据源，供 Agent 查询。
- 适用工作流：配置数据源后，Agent 通过 SQL 访问和组合多类数据以完成分析或任务决策。
- 输入：API、文件、实时数据源连接配置及 SQL 查询。
- 输出：跨源查询结果和供 Agent 使用的结构化数据上下文。
- 部署条件：作为 Agent 系统的数据访问层部署并连接受控数据源。
- 风险：跨源查询可能扩大数据暴露范围，需实施凭据隔离、行列级权限和查询审计。
- 保留理由：提供面向 Agent 的数据访问基础设施，可直接支撑 AI 工程与研发 Agent 工作流。

### yasasbanukaofficial/claude-code
<!-- github-record:{"week":"2026-W14","repository":"yasasbanukaofficial/claude-code","stars":3589,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/yasasbanukaofficial/claude-code
- 采集时可见 Star：3589
- 项目属性：开源终端 AI 编码 Agent 骨架
- 周次依据：候选清单标注为 2026-W14；以当前公开仓库页面摘要及旧元数据作 C 级用途归类，不将其表述为当周历史排名事实。
- 来源等级：C
- 核心功能：提供含 LLM 工具调用、Agent 工作流和终端 UI 的开发者编码 Agent 骨架。
- 适用工作流：开发者配置模型与工具调用，将骨架扩展为可在终端处理工程任务的 Agent。
- 输入：开发任务、代码仓库、模型服务配置和工具权限。
- 输出：可定制的编码 Agent 实现、终端交互和任务执行结果。
- 部署条件：作为 TypeScript 工程在本地构建，并配置受控的模型与工具访问。
- 风险：仓库声明为骨架且来源说明有限，接入前必须核验许可证、代码来源、依赖安全和工具权限。
- 保留理由：明确包含工具调用和 Agentic 工作流的编码 Agent 骨架，可直接用于研发 Agent 实现研究。

## 2026-W13

- 原始候选：30
- 保留：10
- 排除：20
- 候选不足：保留 10 条，不降低 Star 门槛补足。

### 0xNyk/awesome-hermes-agent
<!-- github-record:{"week":"2026-W13","repository":"0xNyk/awesome-hermes-agent","stars":4200,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/0xNyk/awesome-hermes-agent
- 采集时可见 Star：4200
- 项目属性：Hermes Agent 资源库
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：面向 Hermes Agent 的资源、工具与实践集合。
- 适用工作流：可直接用于调研和构建 Agent 工程框架，辅助研发 Agent 本体。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：可直接用于调研和构建 Agent 工程框架，辅助研发 Agent 本体。

### alvinreal/awesome-opensource-ai
<!-- github-record:{"week":"2026-W13","repository":"alvinreal/awesome-opensource-ai","stars":3948,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/alvinreal/awesome-opensource-ai
- 采集时可见 Star：3948
- 项目属性：开源 AI 资源库
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：整理开源人工智能项目、工具和资料。
- 适用工作流：可辅助 AI 工程选型、调研和原型开发，直接服务 AI 研发工作。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：可辅助 AI 工程选型、调研和原型开发，直接服务 AI 研发工作。

### deusyu/harness-engineering
<!-- github-record:{"week":"2026-W13","repository":"deusyu/harness-engineering","stars":4105,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/deusyu/harness-engineering
- 采集时可见 Star：4105
- 项目属性：Harness 工程
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：围绕 AI Agent harness 的工程方法、工具和实践。
- 适用工作流：直接用于研发 Agent 框架本体，提升 Agent 的执行、评测和工程化能力。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：直接用于研发 Agent 框架本体，提升 Agent 的执行、评测和工程化能力。

### nashsu/AutoCLI
<!-- github-record:{"week":"2026-W13","repository":"nashsu/AutoCLI","stars":2799,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/nashsu/AutoCLI
- 采集时可见 Star：2799
- 项目属性：AutoCLI
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：用于自动化生成或驱动命令行接口的开发工具。
- 适用工作流：可用于构建 Agent 的工具调用和 CLI 适配层，直接辅助 Agent 框架工程化。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：可用于构建 Agent 的工具调用和 CLI 适配层，直接辅助 Agent 框架工程化。

### nicedreamzapp/claude-code-local
<!-- github-record:{"week":"2026-W13","repository":"nicedreamzapp/claude-code-local","stars":2826,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/nicedreamzapp/claude-code-local
- 采集时可见 Star：2826
- 项目属性：Claude Code Local
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：面向本地环境运行和集成 Claude Code 的工具。
- 适用工作流：直接服务编码 Agent 的本地化运行与集成，可用于研发 Agent 框架本体。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：直接服务编码 Agent 的本地化运行与集成，可用于研发 Agent 框架本体。

### repowise-dev/repowise
<!-- github-record:{"week":"2026-W13","repository":"repowise-dev/repowise","stars":2524,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/repowise-dev/repowise
- 采集时可见 Star：2524
- 项目属性：RepoWise
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：面向代码仓库理解、分析或知识检索的开发工具。
- 适用工作流：可辅助大型工程代码理解、维护和工程文档整理，对 AI 工程研发有直接帮助。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：可辅助大型工程代码理解、维护和工程文档整理，对 AI 工程研发有直接帮助。

### revfactory/harness
<!-- github-record:{"week":"2026-W13","repository":"revfactory/harness","stars":7882,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/revfactory/harness
- 采集时可见 Star：7882
- 项目属性：Harness
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：用于构建和运行 AI Agent 工作流的工程框架或工具。
- 适用工作流：直接用于研发和验证 Agent 框架本体，适合工程化工作流建设。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：直接用于研发和验证 Agent 框架本体，适合工程化工作流建设。

### walkinglabs/awesome-harness-engineering
<!-- github-record:{"week":"2026-W13","repository":"walkinglabs/awesome-harness-engineering","stars":3335,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/walkinglabs/awesome-harness-engineering
- 采集时可见 Star：3335
- 项目属性：Harness 工程资源库
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：整理 AI Agent harness 工程相关的资料、工具和实践。
- 适用工作流：直接辅助 Agent 框架本体的设计、实现和评测，具备研发参考价值。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：直接辅助 Agent 框架本体的设计、实现和评测，具备研发参考价值。

### walkinglabs/learn-harness-engineering
<!-- github-record:{"week":"2026-W13","repository":"walkinglabs/learn-harness-engineering","stars":9184,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/walkinglabs/learn-harness-engineering
- 采集时可见 Star：9184
- 项目属性：学习 Harness 工程
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：面向 AI Agent harness 工程的学习资料和实践指南。
- 适用工作流：可用于建立 Agent 框架工程能力和研发规范，直接服务 Agent 本体建设。
- 输入：项目配置、源代码、研发资料或任务说明。
- 输出：可用于研发流程的工具结果、配置或结构化资料。
- 部署条件：需按仓库当前文档核验依赖、权限和运行环境后再试用。
- 风险：当前功能和兼容性仅依据 C 级历史候选信息，使用前需复核代码、许可证、权限和数据边界。
- 保留理由：可用于建立 Agent 框架工程能力和研发规范，直接服务 Agent 本体建设。

### yvgude/lean-ctx
<!-- github-record:{"week":"2026-W13","repository":"yvgude/lean-ctx","stars":2911,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/yvgude/lean-ctx
- 采集时可见 Star：2911
- 项目属性：Agent 上下文工程工具
- 周次依据：历史周次来自旧 GitHub Search 近似候选池，不代表当周精确排名。
- 来源等级：C
- 核心功能：精简和管理 Agent 上下文，降低无关信息对执行的影响。
- 适用工作流：用于 Agent 框架开发中的上下文裁剪、成本控制和执行稳定性优化。
- 输入：Agent 会话、工具输出和上下文配置。
- 输出：压缩或筛选后的上下文及相关执行配置。
- 部署条件：需按仓库当前文档核验运行环境、依赖和集成方式后再试用。
- 风险：上下文裁剪可能删除关键约束或证据，需保留原始记录并进行回归验证。
- 保留理由：直接支持 Agent 本体的上下文工程研发，能够改善当前长任务工作流。

## 2026-W12

- 原始候选：30
- 保留：15
- 排除：15
- 候选不足：保留 15 条，不降低 Star 门槛补足。

### CoderLuii/HolyClaude
<!-- github-record:{"week":"2026-W12","repository":"CoderLuii/HolyClaude","stars":2362,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/CoderLuii/HolyClaude
- 采集时可见 Star：2362
- 项目属性：AI 工程工作站
- 周次依据：2026-W12 候选，Star 2,362（输入记录）
- 来源等级：C
- 核心功能：以 Docker Compose 部署集成 Claude Code、多种 AI CLI、浏览器与开发工具的自托管 AI 开发环境。
- 适用工作流：启动容器化工作站，在统一 Web 与终端环境中调用编码 Agent、浏览器和开发工具完成项目开发。
- 输入：代码仓库、开发任务及已配置的模型订阅或 API 凭据。
- 输出：可运行的隔离式 AI 开发工作站与任务产物。
- 部署条件：Docker Compose 自托管部署。
- 风险：需要授予容器、浏览器和模型凭据权限；多工具集成会增加供应链与运维复杂度。
- 保留理由：直接提供可复用的 AI 编码开发环境，能缩短 AI 工程项目的环境配置与多工具协作时间。

### facebookresearch/HyperAgents
<!-- github-record:{"week":"2026-W12","repository":"facebookresearch/HyperAgents","stars":2603,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/facebookresearch/HyperAgents
- 采集时可见 Star：2603
- 项目属性：Agent 研发框架
- 周次依据：2026-W12 候选，Star 2,603（输入记录）
- 来源等级：C
- 核心功能：实现可自指和自我改进的 Agent，用于在可计算任务上研究与优化 Agent 行为。
- 适用工作流：配置模型后运行 Agent 实验，定义任务与评估目标，观察并迭代其自改进策略。
- 输入：任务定义、评估函数、模型 API 配置与实验环境。
- 输出：Agent 执行结果、优化过程与可复现实验代码。
- 部署条件：Python 项目环境，需配置模型 API。
- 风险：自改进循环的成本、稳定性和评估偏差需要严格控制，模型凭据不可写入仓库。
- 保留理由：由研究机构发布的开源 Agent 自我改进实现，直接服务 Agent 框架研发与实验验证。

### HKUDS/ClawTeam
<!-- github-record:{"week":"2026-W12","repository":"HKUDS/ClawTeam","stars":5349,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/HKUDS/ClawTeam
- 采集时可见 Star：5349
- 项目属性：多 Agent 编排框架
- 周次依据：2026-W12 候选，Star 5,349（输入记录）
- 来源等级：C
- 核心功能：让多个 CLI Agent 组成团队，进行任务委派、P2P 通信、协作执行与交付。
- 适用工作流：提交目标后创建 Agent 团队，按角色拆分任务并通过编排层汇总执行结果。
- 输入：研发目标、任务配置、可调用的 CLI Agent 与运行环境。
- 输出：多 Agent 分工执行结果、协作状态和交付物。
- 部署条件：命令行部署，可配合 Claude Code、Codex 等 CLI Agent 使用。
- 风险：并行 Agent 会放大模型调用成本与错误传播，需隔离权限并设置可验证的验收关卡。
- 保留理由：具备明确的多 Agent 编排、通信和任务分派机制，可直接用于研发 Agent 框架本体。

### jnMetaCode/superpowers-zh
<!-- github-record:{"week":"2026-W12","repository":"jnMetaCode/superpowers-zh","stars":5904,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/jnMetaCode/superpowers-zh
- 采集时可见 Star：5904
- 项目属性：AI 编码工作流 Skill 集
- 周次依据：2026-W12 候选，Star 5,904（输入记录）
- 来源等级：C
- 核心功能：为多种 AI 编码工具提供中文化及扩展的规划、TDD、调试和审查工作流 Skill。
- 适用工作流：安装后由兼容的编码 Agent 按需加载 Skill，执行需求澄清、实现、测试和代码审查。
- 输入：代码任务、代码库上下文与兼容的 AI 编码 Agent。
- 输出：受结构化开发流程约束的代码修改、测试和审查结果。
- 部署条件：通过 npm 全局安装或按工具说明接入兼容的 Agent。
- 风险：Skill 指令会影响 Agent 的工具权限和开发流程，应审查版本内容并避免与项目规则冲突。
- 保留理由：直接强化 AI 编码 Agent 的工程化流程，且具备多工具兼容和较广使用范围。

### louislva/claude-peers-mcp
<!-- github-record:{"week":"2026-W12","repository":"louislva/claude-peers-mcp","stars":2127,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/louislva/claude-peers-mcp
- 采集时可见 Star：2127
- 项目属性：Agent 通信 MCP 服务
- 周次依据：2026-W12 候选，Star 2,127（输入记录）
- 来源等级：C
- 核心功能：让多个 Claude Code 实例发现彼此并即时交换消息。
- 适用工作流：在多个项目或会话启动 MCP 服务，Agent 发现同伴后发送协调、状态和文件修改信息。
- 输入：并行的 Claude Code 会话、项目标识与协作消息。
- 输出：跨会话的 Agent 发现与即时通信通道。
- 部署条件：按 MCP 服务方式在本地 Agent 环境配置。
- 风险：跨项目消息可能泄露上下文或引入任务串扰，需限制发现范围和消息内容。
- 保留理由：补足并行编码 Agent 的协作通信层，可直接用于多 Agent 研发工作流。

### mattpocock/sandcastle
<!-- github-record:{"week":"2026-W12","repository":"mattpocock/sandcastle","stars":6399,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/mattpocock/sandcastle
- 采集时可见 Star：6399
- 项目属性：隔离式编码 Agent 编排库
- 周次依据：2026-W12 候选，Star 6,399（输入记录）
- 来源等级：C
- 核心功能：以 TypeScript API 在隔离沙箱和分支中运行、合并多个编码 Agent 的修改。
- 适用工作流：调用 sandcastle.run 启动 Agent，在 Docker、Podman 或 Vercel 隔离环境完成变更，再审核并合并分支。
- 输入：Agent 提示词、Git 仓库、分支策略和沙箱提供者配置。
- 输出：隔离分支上的 Agent 提交、审查流水线结果与合并后的代码。
- 部署条件：TypeScript 库，依赖 Git 与 Docker、Podman 或 Vercel 等沙箱提供者。
- 风险：自动分支合并与容器执行需要最小权限、资源限额和人工审查，避免未验证代码进入主线。
- 保留理由：提供可编程的隔离、并行与合并机制，是直接可用的编码 Agent 研发基础设施。

### modem-dev/hunk
<!-- github-record:{"week":"2026-W12","repository":"modem-dev/hunk","stars":5626,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/modem-dev/hunk
- 采集时可见 Star：5626
- 项目属性：Agent 代码审查终端工具
- 周次依据：2026-W12 候选，Star 5,626（输入记录）
- 来源等级：C
- 核心功能：为 Agent 生成的多文件变更提供终端内优先审查、注释和 Git difftool 工作流。
- 适用工作流：将 Agent 变更接入 Hunk，在终端逐文件审阅、查看注释并通过 Git 工作流处理差异。
- 输入：Git 变更集、Agent 生成的补丁及可选 AI 注释。
- 输出：可审阅的差异视图与人工确认后的代码变更决策。
- 部署条件：通过 npm 全局安装，在终端或 Git difftool 中使用。
- 风险：仅改善审查界面而不替代测试；AI 注释可能错误，合并前仍需执行项目验证。
- 保留理由：专门服务 Agent 编写代码的人工审查环节，可直接提升 AI 工程交付质量。

### nv-tlabs/kimodo
<!-- github-record:{"week":"2026-W12","repository":"nv-tlabs/kimodo","stars":2742,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/nv-tlabs/kimodo
- 采集时可见 Star：2742
- 项目属性：机器人运动生成模型
- 周次依据：2026-W12 候选，Star 2,742（输入记录）
- 来源等级：C
- 核心功能：基于运动扩散模型从文本和运动学约束生成高质量人形与机器人三维动作。
- 适用工作流：提供文本提示、关键帧、末端位姿或路径约束，运行推理、交互演示或基准评测。
- 输入：文本动作描述、机器人骨架及运动学约束或基准数据。
- 输出：受约束的三维运动序列、评测结果和可视化演示。
- 部署条件：Python 模型推理环境，按项目要求准备模型权重和计算资源。
- 风险：生成动作在真实机器人上执行前必须经过运动学、碰撞、安全边界和硬件仿真验证。
- 保留理由：直接面向机器人动作生成，提供推理、约束控制和评测代码，适合机器人 AI 研发。

### NVIDIA/SkillSpector
<!-- github-record:{"week":"2026-W12","repository":"NVIDIA/SkillSpector","stars":10488,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/NVIDIA/SkillSpector
- 采集时可见 Star：10488
- 项目属性：Agent Skill 安全扫描器
- 周次依据：2026-W12 候选，Star 10,488（输入记录）
- 来源等级：C
- 核心功能：扫描 Agent Skill 中的漏洞、恶意模式和安全风险，支持仓库、URL、压缩包、目录和单文件输入。
- 适用工作流：在安装或接入 Skill 前执行扫描，审阅检测结果后决定隔离、修复或拒绝该 Skill。
- 输入：Skill Git 仓库、URL、压缩包、本地目录或单个文件。
- 输出：安全发现、风险信号和供审查的扫描报告。
- 部署条件：按项目文档安装为命令行工具或 Pi 扩展。
- 风险：静态检测存在漏报和误报，不能替代对高权限 Skill 的人工代码审查与最小权限隔离。
- 保留理由：直接覆盖 Agent 框架的 Skill 供应链安全，是研发与部署 Agent 能力时的关键保障。

### outsourc-e/hermes-workspace
<!-- github-record:{"week":"2026-W12","repository":"outsourc-e/hermes-workspace","stars":5842,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/outsourc-e/hermes-workspace
- 采集时可见 Star：5842
- 项目属性：多 Agent 研发工作台
- 周次依据：2026-W12 候选，Star 5,842（输入记录）
- 来源等级：C
- 核心功能：为 Hermes Agent 提供会话、文件、记忆、Skill、终端、任务和多 Agent 调度的统一控制面。
- 适用工作流：连接 Hermes Agent 后在工作台组织任务、管理持久工作者、分配角色并利用审查关卡交付结果。
- 输入：Hermes Agent 安装、研发任务、工作区、Skill 与 MCP 配置。
- 输出：多 Agent 任务状态、终端执行结果、记忆和可审查的交付物。
- 部署条件：基于官方 Hermes Agent 安装的本地 Web 工作台。
- 风险：集中工作台具有终端、文件和记忆访问面，需实施访问控制并验证自动调度的提交。
- 保留理由：提供多 Agent 研发执行的控制面与审查机制，能直接加速 Agent 工程协作。

### rohitg00/ai-engineering-from-scratch
<!-- github-record:{"week":"2026-W12","repository":"rohitg00/ai-engineering-from-scratch","stars":36291,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/rohitg00/ai-engineering-from-scratch
- 采集时可见 Star：36291
- 项目属性：AI 工程开源课程与工件库
- 周次依据：2026-W12 候选，Star 36,291（输入记录）
- 来源等级：C
- 核心功能：以多阶段课程和可复用的提示词、Skill、Agent、MCP 服务工件教授 AI 工程实践。
- 适用工作流：按阶段学习并运行对应项目工件，将提示词、Skill、Agent 或 MCP 样例改造到研发项目。
- 输入：学习路径选择、本地 Python/TypeScript/Rust/Julia 开发环境及课程任务。
- 输出：可复用的 AI 工程工件、练习项目和实现经验。
- 部署条件：按课程仓库说明在本地开发环境运行。
- 风险：教育样例不等于生产方案，采用前需独立审查依赖、密钥处理、测试和运行成本。
- 保留理由：覆盖面广且使用范围显著，提供可运行的 Agent 与 MCP 工件，可直接支撑 AI 工程能力建设。

### samber/cc-skills-golang
<!-- github-record:{"week":"2026-W12","repository":"samber/cc-skills-golang","stars":2282,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/samber/cc-skills-golang
- 采集时可见 Star：2282
- 项目属性：Go 编码 Agent Skill 集
- 周次依据：2026-W12 候选，Star 2,282（输入记录）
- 来源等级：C
- 核心功能：提供面向 Go 语言、测试、安全和可观测性的可按需加载 Agent Skill。
- 适用工作流：安装到兼容的编码 Agent 后，在 Go 项目任务中加载语言与质量相关 Skill 生成和审查改动。
- 输入：Go 代码库、开发任务和兼容 Agent Skills 协议的编码 Agent。
- 输出：遵循 Go 工程实践的 Agent 编码与审查结果。
- 部署条件：通过 skills.sh CLI 或兼容 Agent 的 Skill 安装机制接入。
- 风险：Skill 内容需要随 Go 版本和项目规范校验，不能替代编译、测试、静态检查和人工审查。
- 保留理由：针对生产级 Go 研发的 Agent 能力包，能直接增强 AI 编码工程的语言、测试和安全工作流。

### stablyai/orca
<!-- github-record:{"week":"2026-W12","repository":"stablyai/orca","stars":7089,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/stablyai/orca
- 采集时可见 Star：7089
- 项目属性：并行编码 Agent 工作台
- 周次依据：2026-W12 候选，Star 7,089（输入记录）
- 来源等级：C
- 核心功能：在独立 Git worktree 中并排运行和管理 Codex、Claude Code、OpenCode 或 Pi 等多个编码 Agent。
- 适用工作流：将同一研发任务分发给多个隔离 worktree 的 Agent，对比结果、跟进任务并选择合并方案。
- 输入：Git 仓库、编码任务、已配置的 CLI Agent 和本地工作树环境。
- 输出：并行 Agent 结果、工作树状态、终端会话与可合并的代码变更。
- 部署条件：桌面应用配合本地 Git worktree 和各 Agent 订阅或凭据运行。
- 风险：并发 Agent 会产生重复成本和冲突变更；移动端控制不应暴露代码、终端或模型凭据。
- 保留理由：直接针对并行 AI 编码与 worktree 隔离设计，可提升 AI 工程研发吞吐与对比审查效率。

### VoltAgent/awesome-codex-subagents
<!-- github-record:{"week":"2026-W12","repository":"VoltAgent/awesome-codex-subagents","stars":5313,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/VoltAgent/awesome-codex-subagents
- 采集时可见 Star：5313
- 项目属性：Codex 子 Agent 工作流库
- 周次依据：2026-W12 候选，Star 5,313（输入记录）
- 来源等级：C
- 核心功能：汇集覆盖开发场景的专用 Codex 子 Agent 定义，供任务分工和复用。
- 适用工作流：从集合中选择与项目任务匹配的子 Agent，接入 Codex 多 Agent 工作流并按结果审查调整。
- 输入：研发任务、代码库上下文与 Codex 子 Agent 配置。
- 输出：按专业角色拆分的 Agent 提示与任务执行结果。
- 部署条件：按仓库说明将子 Agent 配置导入兼容的 Codex 工作流。
- 风险：集合中的第三方提示和工具权限质量不一，接入前需审查指令、数据访问和项目适配性。
- 保留理由：专门面向 Codex 子 Agent 分工，具有较广使用范围，可直接加速 AI 工程协作。

### zarazhangrui/codebase-to-course
<!-- github-record:{"week":"2026-W12","repository":"zarazhangrui/codebase-to-course","stars":4979,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/zarazhangrui/codebase-to-course
- 采集时可见 Star：4979
- 项目属性：代码库工程文档 Skill
- 周次依据：2026-W12 候选，Star 4,979（输入记录）
- 来源等级：C
- 核心功能：将代码库转换为包含导航、可视化、测验和代码解释的自包含交互式 HTML 课程。
- 适用工作流：对目标仓库调用 Claude Code Skill，生成可浏览的代码工作原理课程，用于理解、交接和审阅。
- 输入：代码库及其代码结构、Claude Code 运行环境。
- 输出：自包含的交互式 HTML 代码库说明文档。
- 部署条件：作为 Claude Code Skill 在本地 Agent 环境中使用。
- 风险：自动生成的解释和图示可能偏离实际代码；发布前需由维护者核对敏感信息、准确性和许可边界。
- 保留理由：直接把代码库知识转化为工程说明与交接材料，能加速工程文档和 AI 编码审查工作。

## 2026-W11

- 原始候选：30
- 保留：16
- 排除：14
- 候选不足：保留 16 条，不降低 Star 门槛补足。

### aiming-lab/AutoResearchClaw
<!-- github-record:{"week":"2026-W11","repository":"aiming-lab/AutoResearchClaw","stars":13588,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/aiming-lab/AutoResearchClaw
- 采集时可见 Star：13588
- 项目属性：自主科研 Agent 框架
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：将科研想法转化为可验证的研究与论文产出
- 适用工作流：输入研究设想，Agent 进行资料检索、论证、实验编排与论文生成
- 输入：研究问题、假设、数据与实验约束
- 输出：研究方案、验证记录和论文草稿
- 部署条件：作为 AI 研发团队的自主研究工作流组件部署
- 风险：自动生成的论证、引用和实验结论仍需人工复核
- 保留理由：面向自主科研与实验迭代，可直接支持 AI 工程研究和研发 Agent 工作流。

### aiming-lab/MetaClaw
<!-- github-record:{"week":"2026-W11","repository":"aiming-lab/MetaClaw","stars":3440,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/aiming-lab/MetaClaw
- 采集时可见 Star：3440
- 项目属性：自进化 Agent 框架
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：让 Agent 从交互中持续学习并演化技能
- 适用工作流：执行任务并收集反馈，学习模块更新技能或策略后用于后续任务
- 输入：任务对话、执行轨迹和反馈信号
- 输出：更新后的 Agent 技能、策略或微调结果
- 部署条件：集成到需要持续优化能力的研发 Agent 运行环境
- 风险：在线学习和自动更新可能引入能力漂移，需要评估与回滚机制
- 保留理由：直接提供 Agent 持续学习与技能演化能力，属于研发 Agent 框架本体。

### Egonex-AI/Understand-Anything
<!-- github-record:{"week":"2026-W11","repository":"Egonex-AI/Understand-Anything","stars":67699,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Egonex-AI/Understand-Anything
- 采集时可见 Star：67699
- 项目属性：代码库知识图谱与 Agent 开发工具
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：把代码库转换为可探索、搜索和问答的知识图谱
- 适用工作流：解析工程代码并建立关系图，开发者或编码 Agent 查询结构与上下文
- 输入：源代码仓库和代码理解问题
- 输出：交互式知识图谱、检索结果和代码库问答上下文
- 部署条件：作为 Codex、Claude Code 等编码 Agent 的代码理解组件接入 AI 工程流程
- 风险：大仓库解析成本和图谱准确性依赖语言覆盖及索引质量
- 保留理由：直接缩短代码库理解和 Agent 上下文构建时间，适用于 AI 工程。

### garrytan/gstack
<!-- github-record:{"week":"2026-W11","repository":"garrytan/gstack","stars":115196,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/garrytan/gstack
- 采集时可见 Star：115196
- 项目属性：编码 Agent 工程工作流工具集
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：为编码 Agent 提供设计、研发管理、发布、文档和质量保障工具
- 适用工作流：在研发任务中按角色调用工具完成设计、实现、测试、发布和文档步骤
- 输入：产品需求、代码变更和研发上下文
- 输出：研发产物、质量检查结果和发布文档
- 部署条件：作为 Claude Code 等编码 Agent 的工程工作流扩展部署
- 风险：工作流带有特定方法论，需与现有研发规范校准
- 保留理由：覆盖编码、测试、发布和文档等研发环节，可直接加速 AI 工程工作。

### gsd-build/gsd-2
<!-- github-record:{"week":"2026-W11","repository":"gsd-build/gsd-2","stars":7742,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/gsd-build/gsd-2
- 采集时可见 Star：7742
- 项目属性：长程 Agent 上下文与规格驱动开发框架
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：通过元提示、上下文工程和规格驱动流程维持 Agent 的长期任务一致性
- 适用工作流：将需求拆为规格与阶段任务，持续维护上下文并驱动 Agent 执行和验收
- 输入：产品规格、任务计划和项目上下文
- 输出：可追踪的 Agent 执行计划、上下文和研发产物
- 部署条件：作为长程研发 Agent 的任务编排与上下文管理框架部署
- 风险：提示词与流程设计质量会直接影响执行稳定性
- 保留理由：解决研发 Agent 长任务的上下文与规划问题，属于 Agent 框架基础能力。

### iflytek/skillhub
<!-- github-record:{"week":"2026-W11","repository":"iflytek/skillhub","stars":3591,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/iflytek/skillhub
- 采集时可见 Star：3591
- 项目属性：企业级 Agent 技能注册与治理平台
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：发布、版本化、治理和审计 Agent 技能包
- 适用工作流：维护者发布技能包，平台通过权限、版本和审计机制向 Agent 环境分发
- 输入：技能包、版本元数据、权限和审计配置
- 输出：受治理的技能目录、版本记录和审计日志
- 部署条件：以 Docker 或 Kubernetes 在研发内网部署为 Agent 技能基础设施
- 风险：企业权限模型和技能依赖治理需要与现有平台集成
- 保留理由：提供研发 Agent 技能的注册、版本和治理能力，属于框架基础设施。

### iOfficeAI/OfficeCLI
<!-- github-record:{"week":"2026-W11","repository":"iOfficeAI/OfficeCLI","stars":8017,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/iOfficeAI/OfficeCLI
- 采集时可见 Star：8017
- 项目属性：Agent 可调用的 Office 文档自动化工具
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：让 Agent 无需安装 Office 即可读写和自动化 Word、Excel、PowerPoint 文件
- 适用工作流：Agent 接收文档处理需求，调用单文件 CLI 读取、编辑或生成 Office 文档
- 输入：DOCX、XLSX、PPTX 文件和文档修改要求
- 输出：更新后的 Office 文件及结构化处理结果
- 部署条件：作为研发 Agent 的工程文档、表格和汇报材料处理工具部署
- 风险：复杂版式和公式兼容性需在目标文档上验证
- 保留理由：可直接自动化工程报告、BOM 表格和演示文档，符合工程文档方向。

### lucas-maes/le-wm
<!-- github-record:{"week":"2026-W11","repository":"lucas-maes/le-wm","stars":3948,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/lucas-maes/le-wm
- 采集时可见 Star：3948
- 项目属性：视觉世界模型 AI 研究实现
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：实现从像素学习的端到端联合嵌入预测世界模型
- 适用工作流：输入视觉序列进行模型训练和预测，用于复现实验和研究模型行为
- 输入：图像或视频序列、训练配置和计算资源
- 输出：训练后的世界模型、预测结果和研究实验数据
- 部署条件：作为 AI 研发中的视觉世界模型实验代码部署
- 风险：研究代码的可复现性、算力需求和数据前处理需要独立验证
- 保留理由：提供前沿视觉世界模型的开源实现，可直接支持 AI 工程研究。

### millionco/expect
<!-- github-record:{"week":"2026-W11","repository":"millionco/expect","stars":3516,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/millionco/expect
- 采集时可见 Star：3516
- 项目属性：编码 Agent 浏览器端到端测试工具
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：在真实浏览器中验证 Agent 生成或修改的代码
- 适用工作流：Agent 完成代码改动后运行浏览器测试，根据结果迭代修复
- 输入：待验证的 Web 应用、测试期望和 Agent 代码变更
- 输出：真实浏览器测试结果与失败反馈
- 部署条件：接入 AI 工程的 Agent 自检和持续验证步骤
- 风险：测试覆盖范围和浏览器环境配置会影响验证可信度
- 保留理由：把真实浏览器反馈接入编码 Agent 循环，可直接提升 AI 工程验证效率。

### NousResearch/hermes-agent-self-evolution
<!-- github-record:{"week":"2026-W11","repository":"NousResearch/hermes-agent-self-evolution","stars":4327,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/NousResearch/hermes-agent-self-evolution
- 采集时可见 Star：4327
- 项目属性：Agent 自进化优化框架
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：使用 DSPy 和 GEPA 优化 Hermes Agent 的技能、提示词和代码
- 适用工作流：采集 Agent 任务表现，执行进化优化并评估候选改动后保留有效版本
- 输入：Agent 技能、提示词、代码和评估反馈
- 输出：经评估优化的 Agent 配置与实现
- 部署条件：作为 Hermes 或兼容研发 Agent 的持续优化流水线部署
- 风险：自动优化依赖可靠评估集，错误奖励信号可能导致回归
- 保留理由：直接实现研发 Agent 的技能、提示词和代码自优化，属于框架本体能力。

### NVIDIA/NemoClaw
<!-- github-record:{"week":"2026-W11","repository":"NVIDIA/NemoClaw","stars":21398,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/NVIDIA/NemoClaw
- 采集时可见 Star：21398
- 项目属性：安全 Agent 运行时与推理管理工具
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：在 NVIDIA OpenShell 中隔离运行多种 Agent 并管理推理
- 适用工作流：配置 Agent、沙箱与推理资源，在受控环境中执行任务
- 输入：Agent 配置、工具权限、模型推理配置和任务
- 输出：隔离的 Agent 执行环境及运行结果
- 部署条件：部署在需要安全隔离和受管推理的研发 Agent 平台
- 风险：依赖 NVIDIA OpenShell 与相关基础设施，需评估部署兼容性
- 保留理由：提供 Agent 沙箱与运行管理，属于研发 Agent 框架运行时基础设施。

### sentrux/sentrux
<!-- github-record:{"week":"2026-W11","repository":"sentrux/sentrux","stars":2566,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/sentrux/sentrux
- 采集时可见 Star：2566
- 项目属性：Agent 代码架构反馈与静态分析工具
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：实时分析代码架构，为 Agent 提供可用于递归改进的质量反馈
- 适用工作流：扫描代码库生成架构与质量信号，Agent 据此定位问题并迭代修改
- 输入：源代码库和架构分析配置
- 输出：架构可视化、质量反馈和可操作的改进信号
- 部署条件：以 Rust 工具或 MCP 组件接入编码 Agent 的反馈闭环
- 风险：静态分析规则和语言支持范围需与项目技术栈匹配
- 保留理由：为编码 Agent 提供架构级质量反馈，可直接加速 AI 工程的自改进循环。

### TianyiDataScience/openclaw-control-center
<!-- github-record:{"week":"2026-W11","repository":"TianyiDataScience/openclaw-control-center","stars":3991,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/TianyiDataScience/openclaw-control-center
- 采集时可见 Star：3991
- 项目属性：OpenClaw Agent 本地控制与可观测性工具
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：为 OpenClaw 提供本地可视化、控制和可信运行界面
- 适用工作流：连接本地 OpenClaw 实例，查看运行状态并执行控制与配置操作
- 输入：本地 OpenClaw 实例、运行状态和控制指令
- 输出：Agent 运行可视化、控制结果和配置状态
- 部署条件：作为研发 Agent 平台的本地运维与调试控制台部署
- 风险：与 OpenClaw 版本和本地权限模型存在兼容性风险
- 保留理由：直接服务 Agent 运行时的观测与控制，属于研发 Agent 基础设施。

### tw93/Waza
<!-- github-record:{"week":"2026-W11","repository":"tw93/Waza","stars":6042,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/tw93/Waza
- 采集时可见 Star：6042
- 项目属性：编码 Agent 工程实践技能集
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：将工程设计、开发和质量习惯封装为可执行的 Claude 技能
- 适用工作流：编码 Agent 在任务阶段调用相应技能执行设计、实现、审查和验证
- 输入：研发任务、代码上下文和工程约束
- 输出：遵循工程实践的代码改动、审查与验证结果
- 部署条件：作为 Claude Code 等研发 Agent 的工程技能包接入
- 风险：技能流程需与团队既有规范和工具链校准
- 保留理由：面向工程实践而非泛个人助手，可直接提升编码 Agent 的研发工作流质量。

### uditgoenka/autoresearch
<!-- github-record:{"week":"2026-W11","repository":"uditgoenka/autoresearch","stars":5172,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/uditgoenka/autoresearch
- 采集时可见 Star：5172
- 项目属性：编码 Agent 自主迭代技能
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：让 Claude Code 按修改、验证、保留或丢弃的循环自主推进目标
- 适用工作流：定义目标后持续产生改动、执行验证、保留有效结果并重复迭代
- 输入：研发目标、代码库、验证命令和约束
- 输出：经验证的渐进式代码改动和迭代记录
- 部署条件：作为 Claude Code 或兼容研发 Agent 的自主研发循环部署
- 风险：验证命令覆盖不足时可能保留表面正确的改动
- 保留理由：将验证驱动的自主迭代落到编码 Agent 工作流，可直接加速 AI 工程。

### wanshuiyin/Auto-claude-code-research-in-sleep
<!-- github-record:{"week":"2026-W11","repository":"wanshuiyin/Auto-claude-code-research-in-sleep","stars":12603,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/wanshuiyin/Auto-claude-code-research-in-sleep
- 采集时可见 Star：12603
- 项目属性：自主机器学习研究技能集
- 周次依据：2026-W11 周榜候选项目
- 来源等级：C
- 核心功能：以轻量技能实现跨模型审查、研究创意发现和实验自动化
- 适用工作流：Agent 组织研究问题、交叉审查和实验执行，持续汇总研究结论
- 输入：机器学习研究主题、代码、实验配置和模型反馈
- 输出：研究思路、评审结果、实验方案和结果记录
- 部署条件：作为 Codex、Claude Code 等 AI 研发 Agent 的研究自动化技能部署
- 风险：实验质量依赖评审模型、数据和可复现验证，不能替代研究人员判断
- 保留理由：明确面向机器学习研究和实验自动化，可直接支持 AI 工程研发。

## 2026-W10

- 原始候选：30
- 保留：4
- 排除：26
- 候选不足：保留 4 条，不降低 Star 门槛补足。

### Agents365-ai/drawio-skill
<!-- github-record:{"week":"2026-W10","repository":"Agents365-ai/drawio-skill","stars":4624,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Agents365-ai/drawio-skill
- 采集时可见 Star：4624
- 项目属性：Agent 工程文档与架构图技能
- 周次依据：2026-W10 周榜候选项目
- 来源等级：C
- 核心功能：辅助 Agent 创建和编辑 draw.io 工程图
- 适用工作流：输入图表需求或系统结构，生成或调整可视化工程图
- 输入：架构描述、流程关系和图表修改要求
- 输出：draw.io 图表及工程架构可视化结果
- 部署条件：作为 Agent 技能接入研发文档工作流
- 风险：依赖图表工具格式和 Agent 的结构化表达能力
- 保留理由：可直接加速工程架构、流程和设计文档产出，符合工程文档方向。

### karpathy/autoresearch
<!-- github-record:{"week":"2026-W10","repository":"karpathy/autoresearch","stars":88506,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/karpathy/autoresearch
- 采集时可见 Star：88506
- 项目属性：AI 研究自动化 Agent 框架
- 周次依据：2026-W10 周榜候选项目
- 来源等级：C
- 核心功能：自动运行实验并迭代 AI 研究代码与配置
- 适用工作流：读取研究代码，执行实验，评估结果并保留改进方案
- 输入：研究代码、实验配置和评价指标
- 输出：实验结果、改进后的代码或配置及研究记录
- 部署条件：在本地或计算环境中作为 AI 研发自动化工具运行
- 风险：实验成本、资源消耗和自动修改代码带来的结果可靠性风险
- 保留理由：直接加速 AI 工程和研究研发流程，属于目标范围。

### microsoft/agent-governance-toolkit
<!-- github-record:{"week":"2026-W10","repository":"microsoft/agent-governance-toolkit","stars":4511,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/microsoft/agent-governance-toolkit
- 采集时可见 Star：4511
- 项目属性：研发 Agent 治理工具包
- 周次依据：2026-W10 周榜候选项目
- 来源等级：C
- 核心功能：为 Agent 研发和运行提供治理、策略与合规控制
- 适用工作流：配置治理策略，接入 Agent 生命周期并检查运行行为
- 输入：Agent 配置、策略规则、运行事件和审计要求
- 输出：治理决策、合规检查结果和审计记录
- 部署条件：部署在 Agent 工程平台或研发流水线中
- 风险：策略配置错误可能阻断合法工作或放过不合规行为
- 保留理由：属于研发 Agent 基础设施，可直接支撑 AI 工程系统的安全和可控交付。

### paperclipai/paperclip
<!-- github-record:{"week":"2026-W10","repository":"paperclipai/paperclip","stars":71478,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/paperclipai/paperclip
- 采集时可见 Star：71478
- 项目属性：多 Agent 编排与研发框架
- 周次依据：2026-W10 周榜候选项目
- 来源等级：C
- 核心功能：编排多个 Agent 的任务、协作和执行流程
- 适用工作流：定义任务与 Agent，调度执行，收集状态并汇总结果
- 输入：任务描述、Agent 配置、工具权限和执行上下文
- 输出：任务结果、执行状态、协作记录和可审计信息
- 部署条件：部署为 AI 工程平台或研发自动化服务
- 风险：编排错误、权限配置不当和多 Agent 结果一致性风险
- 保留理由：属于研发 Agent 框架本体，可直接支撑 AI 工程工作流。

## 2026-W09

- 原始候选：30
- 保留：12
- 排除：18
- 候选不足：保留 12 条，不降低 Star 门槛补足。

### 34306/vphone-aio
<!-- github-record:{"week":"2026-W09","repository":"34306/vphone-aio","stars":3818,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/34306/vphone-aio
- 采集时可见 Star：3818
- 项目属性：iOS 虚拟设备研究工具
- 周次依据：C级近似回溯：仅以旧榜单候选记录归入 2026-W09；当前公开 README 仅用于判断用途，不作为当周历史事实。
- 来源等级：C
- 核心功能：以脚本启动已配置的虚拟 iPhone 环境，服务于 iOS 运行环境研究与调试。
- 适用工作流：研发人员准备宿主依赖和虚拟设备镜像，执行脚本启动环境，再在隔离设备中进行调试或复现。
- 输入：macOS 宿主环境、虚拟 iPhone 镜像及所需依赖。
- 输出：可启动的虚拟 iPhone 研究与调试环境。
- 部署条件：在具备 Apple 虚拟化能力的本地 macOS 主机运行。
- 风险：涉及越狱和系统级配置；仅应在自有、隔离且获授权的研究设备中使用。
- 保留理由：提供明确的 iOS 虚拟化与调试工作流，属于具体移动端研发环境工具。

### chenhg5/cc-connect
<!-- github-record:{"week":"2026-W09","repository":"chenhg5/cc-connect","stars":13039,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/chenhg5/cc-connect
- 采集时可见 Star：13039
- 项目属性：AI 编码助手协作桥接工具
- 周次依据：C级近似回溯：仅以旧榜单候选记录归入 2026-W09；当前公开 README 仅用于判断用途，不作为当周历史事实。
- 来源等级：C
- 核心功能：将本地 AI 编码助手桥接到企业和即时通信平台，支持远程接收与处理研发任务。
- 适用工作流：开发者在本机运行桥接服务，将编码助手会话连接到消息平台后，通过消息触发、跟进和回收开发任务。
- 输入：本地 AI 编码助手、消息平台配置及项目工作区。
- 输出：消息平台中的开发任务交互与本地编码助手执行结果。
- 部署条件：在开发者本地计算机部署，按所选消息平台完成授权与连接配置。
- 风险：消息渠道可能暴露代码上下文或触发高权限操作；应实施最小权限、项目隔离和人工确认。
- 保留理由：目标明确限定为 AI 编码助手的远程研发协作，而非通用 agent 平台。

### cloudflare/vinext
<!-- github-record:{"week":"2026-W09","repository":"cloudflare/vinext","stars":8252,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/cloudflare/vinext
- 采集时可见 Star：8252
- 项目属性：前端框架兼容构建工具
- 周次依据：C级近似回溯：仅以旧榜单候选记录归入 2026-W09；当前公开 README 仅用于判断用途，不作为当周历史事实。
- 来源等级：C
- 核心功能：以 Vite 插件方式复现 Next.js API 表面，支持前端应用迁移和多环境部署。
- 适用工作流：开发团队在 Vite 项目中接入插件，兼容既有 Next.js API 后构建并部署应用。
- 输入：采用或迁移自 Next.js API 的前端项目源码与构建配置。
- 输出：由 Vite 构建、可部署到目标运行环境的前端应用产物。
- 部署条件：作为项目构建依赖接入 Node.js 前端工程，并部署到所选平台。
- 风险：兼容层可能与原 Next.js 行为存在差异；迁移前应执行路由、服务端渲染和边缘运行时回归测试。
- 保留理由：提供具体的前端工程兼容与构建能力，直接服务软件研发和部署。

### coleam00/excalidraw-diagram-skill
<!-- github-record:{"week":"2026-W09","repository":"coleam00/excalidraw-diagram-skill","stars":3869,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/coleam00/excalidraw-diagram-skill
- 采集时可见 Star：3869
- 项目属性：技术文档图表生成工具
- 周次依据：C级近似回溯：仅以旧榜单候选记录归入 2026-W09；当前公开 README 仅用于判断用途，不作为当周历史事实。
- 来源等级：C
- 核心功能：为编码助手生成并验证 Excalidraw 技术图，产出可用于设计说明和工程沟通的图表。
- 适用工作流：开发者提供技术描述或代码上下文，技能生成图表并通过渲染校验迭代修正布局。
- 输入：自然语言技术说明、架构关系、代码片段或 JSON 示例。
- 输出：经渲染校验的 Excalidraw 图表文件。
- 部署条件：作为兼容编码助手的本地 skill 安装并在项目文档流程中调用。
- 风险：自动生成内容可能误读技术关系或泄露输入代码；发布前应由工程负责人复核并避免提交敏感上下文。
- 保留理由：功能聚焦于技术图表和研发文档产物，工作流具体可验证。

### Lakr233/vphone-cli
<!-- github-record:{"week":"2026-W09","repository":"Lakr233/vphone-cli","stars":6956,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Lakr233/vphone-cli
- 采集时可见 Star：6956
- 项目属性：iOS 虚拟化研发命令行工具
- 周次依据：C级近似回溯：仅以旧榜单候选记录归入 2026-W09；当前公开 README 仅用于判断用途，不作为当周历史事实。
- 来源等级：C
- 核心功能：通过 Apple Virtualization.framework 和 PCC 研究 VM 基础设施启动虚拟 iPhone。
- 适用工作流：开发者准备兼容 Apple Silicon 主机和指定系统镜像，使用 CLI 启动虚拟机以复现和调试 iOS 环境。
- 输入：兼容 macOS 主机、PCC 研究 VM 基础设施和 iPhone 系统镜像。
- 输出：运行中的虚拟 iPhone 实例及其调试环境。
- 部署条件：在支持 Apple Virtualization.framework 的本地 macOS 环境执行。
- 风险：依赖研究性质的虚拟化基础设施和系统镜像，可能受平台条款与访问权限限制。
- 保留理由：提供可复现的移动端虚拟化测试环境，直接服务 iOS 研发与系统研究。

### mksglu/context-mode
<!-- github-record:{"week":"2026-W09","repository":"mksglu/context-mode","stars":18134,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/mksglu/context-mode
- 采集时可见 Star：18134
- 项目属性：AI 编码工具上下文优化组件
- 周次依据：C级近似回溯：仅以旧榜单候选记录归入 2026-W09；当前公开 README 仅用于判断用途，不作为当周历史事实。
- 来源等级：C
- 核心功能：为 AI 编码工具隔离工具输出、持久化会话记忆并管理跨平台上下文路由。
- 适用工作流：开发团队在编码助手中安装 MCP 与 hooks，压缩和隔离工具输出，再将必要上下文供代码实现或审阅使用。
- 输入：编码助手会话、工具输出、代码库上下文和 MCP 或 hook 配置。
- 输出：经过筛选的编码上下文、持久会话状态和路由结果。
- 部署条件：作为 MCP 服务或编码助手扩展配置在本地研发环境。
- 风险：上下文持久化和外部路由可能携带源代码或凭据；应控制存储位置、访问权限并执行敏感信息脱敏。
- 保留理由：功能明确服务代码实现和大型仓库研发上下文管理，非通用 agent 编排。

### mukul975/Anthropic-Cybersecurity-Skills
<!-- github-record:{"week":"2026-W09","repository":"mukul975/Anthropic-Cybersecurity-Skills","stars":20743,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/mukul975/Anthropic-Cybersecurity-Skills
- 采集时可见 Star：20743
- 项目属性：网络安全研发技能库
- 周次依据：C级近似回溯：仅以旧榜单候选记录归入 2026-W09；当前公开 README 仅用于判断用途，不作为当周历史事实。
- 来源等级：C
- 核心功能：提供映射到 MITRE、NIST 等框架的结构化网络安全技能，用于安全工程与分析自动化。
- 适用工作流：安全研发人员选择对应威胁建模、检测、响应或防护主题的技能，在获授权环境中辅助安全分析任务。
- 输入：获授权的安全评估目标、组织安全流程和所选框架要求。
- 输出：结构化安全分析、检测或响应步骤与可复用技能定义。
- 部署条件：作为支持 skills 的编码助手或安全自动化环境中的本地技能库使用。
- 风险：技能可能涉及攻击、取证或高权限操作；仅限合法授权范围，并应保留审计记录和人工审批。
- 保留理由：内容明确围绕安全工程框架和具体安全研发活动，不是泛用 agent 平台。

### NVIDIA/OpenShell
<!-- github-record:{"week":"2026-W09","repository":"NVIDIA/OpenShell","stars":7262,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/NVIDIA/OpenShell
- 采集时可见 Star：7262
- 项目属性：自主程序隔离运行时
- 周次依据：C级近似回溯：仅以旧榜单候选记录归入 2026-W09；当前公开 README 仅用于判断用途，不作为当周历史事实。
- 来源等级：C
- 核心功能：为自主执行程序提供安全、私有的隔离运行时。
- 适用工作流：研发团队将需要自动执行的任务配置到隔离运行时，按环境策略执行并收集运行结果。
- 输入：待执行任务、运行时镜像或依赖、网络与文件系统安全策略。
- 输出：隔离环境内的任务执行结果与运行边界。
- 部署条件：部署为本地或受控基础设施中的隔离运行时，按组织安全策略配置。
- 风险：隔离策略配置不当仍可能造成代码、网络或凭据暴露；需要最小权限、镜像审查和运行审计。
- 保留理由：核心价值是自主执行任务的安全运行时基础设施，具有明确的研发部署与安全边界。

### open-pencil/open-pencil
<!-- github-record:{"week":"2026-W09","repository":"open-pencil/open-pencil","stars":6286,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/open-pencil/open-pencil
- 采集时可见 Star：6286
- 项目属性：开源产品设计编辑器
- 周次依据：C级近似回溯：仅以旧榜单候选记录归入 2026-W09；当前公开 README 仅用于判断用途，不作为当周历史事实。
- 来源等级：C
- 核心功能：提供 AI 原生的协作设计编辑能力，作为开源 Figma 替代方案支持产品界面设计。
- 适用工作流：产品与前端团队创建或导入界面设计，在协作编辑器中迭代页面和组件，再将设计交付给工程实现。
- 输入：界面设计稿、组件资源和协作项目数据。
- 输出：可审阅、协作和交付的产品界面设计资产。
- 部署条件：以其支持的桌面或 Web 运行方式部署到团队设计工作流。
- 风险：AI 生成设计可能引入版权、品牌或可用性问题；团队协作数据也需设置访问控制。
- 保留理由：是具备实际工程实现的产品界面设计工具，可直接服务软件研发交付。

### openai/symphony
<!-- github-record:{"week":"2026-W09","repository":"openai/symphony","stars":25594,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/openai/symphony
- 采集时可见 Star：25594
- 项目属性：研发任务自动化编排工具
- 周次依据：C级近似回溯：仅以旧榜单候选记录归入 2026-W09；当前公开 README 仅用于判断用途，不作为当周历史事实。
- 来源等级：C
- 核心功能：将项目工作拆分为隔离的自主实现运行，并汇集 CI、评审和变更证明。
- 适用工作流：团队监控项目任务板，编排器启动隔离实现运行，收集 CI 与评审证据后由人员验收并合并变更。
- 输入：项目任务、代码库、编码执行环境和 CI 或评审集成。
- 输出：隔离实施运行结果、变更请求及其验证证据。
- 部署条件：在受信任的研发基础设施中部署，并连接任务管理、代码托管和 CI 系统。
- 风险：自主修改代码可能引入供应链、权限扩大和错误合并风险；必须隔离执行、限制令牌权限并保留人工合并门禁。
- 保留理由：工作流明确面向软件项目实施、验证与合并，属于具体研发自动化工具。

### tirth8205/code-review-graph
<!-- github-record:{"week":"2026-W09","repository":"tirth8205/code-review-graph","stars":18884,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/tirth8205/code-review-graph
- 采集时可见 Star：18884
- 项目属性：本地代码审阅智能分析工具
- 周次依据：C级近似回溯：仅以旧榜单候选记录归入 2026-W09；当前公开 README 仅用于判断用途，不作为当周历史事实。
- 来源等级：C
- 核心功能：构建持久化代码库图谱，为 MCP 和 CLI 的代码审阅及大型仓库上下文读取提供局部化代码智能。
- 适用工作流：开发者索引本地代码库，工具增量构建代码关系图，再在审阅或分析时检索相关上下文。
- 输入：本地代码仓库及其增量变更。
- 输出：持久代码关系图和面向审阅的相关上下文结果。
- 部署条件：在开发者机器或受控 CI 分析环境中以 CLI 或 MCP 服务运行。
- 风险：索引库可能包含专有源码；应使用本地受控存储、设置访问边界并审查 MCP 调用权限。
- 保留理由：直接实现代码理解和审阅工作流，研发用途具体且可验证。

### ylytdeng/wechat-decrypt
<!-- github-record:{"week":"2026-W09","repository":"ylytdeng/wechat-decrypt","stars":4206,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/ylytdeng/wechat-decrypt
- 采集时可见 Star：4206
- 项目属性：本地应用数据取证与逆向分析工具
- 周次依据：C级近似回溯：仅以旧榜单候选记录归入 2026-W09；当前公开 README 仅用于判断用途，不作为当周历史事实。
- 来源等级：C
- 核心功能：从运行进程提取数据库密钥并解密 SQLCipher 数据库，辅助本地应用数据格式与安全机制研究。
- 适用工作流：安全研究人员在获授权的测试环境中采集运行进程信息，提取密钥后解密数据库并进行格式或行为分析。
- 输入：获授权的本地应用进程、内存数据和加密数据库文件。
- 输出：可供取证或逆向分析的解密数据库及相关分析数据。
- 部署条件：在 Windows、macOS 或 Linux 的受控安全研究环境中本地运行。
- 风险：可访问私密通信数据并可能违反隐私、平台条款或法律；仅能处理自有或明确书面授权的数据，且须采取数据最小化和安全存储。
- 保留理由：功能具体用于本地应用安全研究、取证与逆向分析，具有明确研发关联和高风险边界。

## 2026-W08

- 原始候选：30
- 保留：12
- 排除：18
- 候选不足：保留 12 条，不降低 Star 门槛补足。

### delibae/claude-prism
<!-- github-record:{"week":"2026-W08","repository":"delibae/claude-prism","stars":1615,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/delibae/claude-prism
- 采集时可见 Star：1615
- 项目属性：本地优先的科研写作与 LaTeX 工作区
- 周次依据：候选清单标注为 2026-W08；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：在桌面端组织科研写作项目，提供本地 LaTeX 编译、Python 环境、文献与版本历史能力。
- 适用工作流：建立论文或报告项目，导入参考材料，在编辑器中编写、编译和审阅，并按需调用 AI 辅助。
- 输入：科研写作内容、LaTeX/BibTeX 文件、参考 PDF/图片及可选提示词。
- 输出：本地科研文稿、PDF 预览、Python 分析产物和 Git 历史。
- 部署条件：当前 README 提供 Windows、macOS 和 Linux 桌面发行包；本地保存和编译，AI 功能需连接 Anthropic 服务。
- 风险：AI 功能会向 Anthropic 服务发送其读取的提示和文件内容；生成的科学内容、引用和分析结果仍需人工核验。
- 保留理由：服务于科研文档、分析和可追溯写作的明确工程工作流。

### floci-io/floci
<!-- github-record:{"week":"2026-W08","repository":"floci-io/floci","stars":14420,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/floci-io/floci
- 采集时可见 Star：14420
- 项目属性：本地 AWS 服务仿真工具
- 周次依据：候选清单标注为 2026-W08；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：在本机模拟 AWS 形状的服务端点，供应用开发、自动化测试和 CI 使用。
- 适用工作流：启动本地服务，将 AWS SDK、CLI、IaC 或测试套件指向本地端点后执行开发和测试。
- 输入：AWS SDK/CLI 调用、IaC 配置、测试用例及本地服务配置。
- 输出：本地模拟服务状态、接口响应和测试/CI 结果。
- 部署条件：可使用官方 CLI 或 Docker Compose 启动；部分服务以 Docker 容器提供执行环境。
- 风险：服务覆盖和兼容性以当前实现为限，本地仿真结果不能替代目标 AWS 环境的最终验证。
- 保留理由：直接支撑云应用的本地开发、集成测试与持续集成。

### icebear0828/codex-proxy
<!-- github-record:{"week":"2026-W08","repository":"icebear0828/codex-proxy","stars":1454,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/icebear0828/codex-proxy
- 采集时可见 Star：1454
- 项目属性：本地编程助手协议代理
- 周次依据：候选清单标注为 2026-W08；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：将本地 Codex Desktop 能力以 OpenAI、Anthropic 和 Gemini 兼容协议提供给开发工具客户端。
- 适用工作流：启动本地代理，配置兼容客户端连接代理，再在既有编程工作流中调用 Codex 能力。
- 输入：客户端的兼容 API 请求、本地 Codex Desktop 会话及代理配置。
- 输出：兼容协议响应和编程助手调用结果。
- 部署条件：当前 README 标注 Node.js 18+、TypeScript 和 Docker 支持，依赖本地 Codex Desktop 可用。
- 风险：代理会扩大本地编程助手接口的可访问面；访问范围、监听地址和第三方客户端配置需受控。
- 保留理由：为具体软件研发工具链提供协议互操作能力。

### kenn-io/agentsview
<!-- github-record:{"week":"2026-W08","repository":"kenn-io/agentsview","stars":3286,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/kenn-io/agentsview
- 采集时可见 Star：3286
- 项目属性：本地编程 Agent 使用分析工具
- 周次依据：候选清单标注为 2026-W08；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：浏览、搜索并跟踪本地 AI 编程 Agent 的成本等使用信息。
- 适用工作流：在开发机运行二进制、桌面程序或 Docker 容器，汇集本地 Agent 数据后查询和分析。
- 输入：本地可发现的 AI 编程 Agent 使用数据。
- 输出：成本、使用情况和检索视图。
- 部署条件：当前 README 提供 macOS/Linux 安装脚本、Windows 安装命令、桌面发行包和 Docker 运行方式。
- 风险：仅能反映可被工具读取的本地使用数据，统计结果不能替代代码质量或交付验收。
- 保留理由：面向软件研发中 AI 编程工具的成本与使用治理，工作对象明确。

### Leonxlnx/taste-skill
<!-- github-record:{"week":"2026-W08","repository":"Leonxlnx/taste-skill","stars":50602,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Leonxlnx/taste-skill
- 采集时可见 Star：50602
- 项目属性：AI 辅助前端研发规范技能包
- 周次依据：候选清单标注为 2026-W08；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：为 AI 辅助的前端界面实现提供设计与代码质量约束。
- 适用工作流：在前端实现任务中加载技能指引，由 Agent 据此生成或修改界面代码，再由开发者审阅。
- 输入：前端功能需求、现有界面代码和 Agent 指令。
- 输出：遵循该技能约束的前端实现建议或代码变更。
- 部署条件：以 Agent 技能形式集成到支持该格式的本地开发环境。
- 风险：该项目提供的是生成约束而非自动验收；可用性、视觉质量和跨端兼容性仍需实际测试。
- 保留理由：目标限定为前端软件实现，具有具体研发关联而非通用 Agent 编排。

### nicobailon/visual-explainer
<!-- github-record:{"week":"2026-W08","repository":"nicobailon/visual-explainer","stars":8882,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/nicobailon/visual-explainer
- 采集时可见 Star：8882
- 项目属性：工程输出可视化与文档辅助技能
- 周次依据：候选清单标注为 2026-W08；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：将复杂终端输出、系统架构、代码差异或计划审阅结果生成独立 HTML 可视化页面。
- 适用工作流：在工程任务中请求架构说明、差异审阅或计划审阅，技能生成页面并在浏览器中打开。
- 输入：终端输出、架构信息、代码差异或工程计划文件。
- 输出：自包含 HTML 说明页面和可视化图示。
- 部署条件：以 Agent 技能形式在支持的开发环境中运行，并使用浏览器呈现结果。
- 风险：可视化说明可能遗漏或误解工程上下文，不能替代代码审查、测试和架构验收。
- 保留理由：直接支持软件工程文档、架构沟通和变更审阅。

### openclaw/acpx
<!-- github-record:{"week":"2026-W08","repository":"openclaw/acpx","stars":2894,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/openclaw/acpx
- 采集时可见 Star：2894
- 项目属性：编程 Agent 会话控制命令行工具
- 周次依据：候选清单标注为 2026-W08；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：通过命令行创建、提示、取消和配置 Codex 等编程 Agent 会话。
- 适用工作流：在项目目录创建或选择会话，提交修复测试、实现功能等任务，并获取或取消会话执行。
- 输入：项目目录、提示词、文件输入、会话名称及 Agent 配置。
- 输出：Agent 会话结果、任务执行状态和代码相关响应。
- 部署条件：当前 README 标注为 alpha，需安装相应 Agent 适配器和命令行运行环境。
- 风险：CLI 和运行时接口当前可能变化；自动执行仍受已安装 Agent、项目权限和提示质量限制。
- 保留理由：对软件项目内编程 Agent 会话提供明确的受控操作界面。

### phodal/routa
<!-- github-record:{"week":"2026-W08","repository":"phodal/routa","stars":1715,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/phodal/routa
- 采集时可见 Star：1715
- 项目属性：软件交付协作与看板编排平台
- 周次依据：候选清单标注为 2026-W08；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：以工作区和看板协调需求细化、实现、审查和验证等软件交付阶段。
- 适用工作流：输入功能目标，生成带验收条件的工作项，再按待办、开发、审查和完成等阶段推进。
- 输入：软件需求、约束、依赖关系和工作区上下文。
- 输出：规范化工作项、看板状态、实现与审查阶段的证据。
- 部署条件：当前 README 显示 TypeScript、Next.js 和 Rust 技术栈，作为工作区优先的平台运行。
- 风险：交付结论依赖角色提示、工作区上下文和外部 Agent 的实际执行，仍需人工代码审查与测试验收。
- 保留理由：流程直接限定于软件交付并包含可验证的需求到审查工作流。

### RightNow-AI/picolm
<!-- github-record:{"week":"2026-W08","repository":"RightNow-AI/picolm","stars":1660,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/RightNow-AI/picolm
- 采集时可见 Star：1660
- 项目属性：低资源嵌入式 LLM 推理引擎
- 周次依据：候选清单标注为 2026-W08；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：以 C11 实现轻量 LLaMA 架构模型的 GGUF 推理，在低内存嵌入式硬件上逐层流式运行。
- 适用工作流：编译单一二进制，提供兼容 GGUF 模型文件，在目标硬件上执行本地推理。
- 输入：GGUF 格式的 LLaMA 架构模型、提示词和目标硬件运行参数。
- 输出：本地模型推理文本与运行时输出。
- 部署条件：当前 README 描述 C11、零依赖构建，可在 Raspberry Pi、RISC-V 及 x86-64 等平台运行。
- 风险：仅适用于当前支持的模型架构和硬件能力；模型文件仍占用存储，生成内容需按应用场景验证。
- 保留理由：面向嵌入式硬件上的模型推理实现，属于明确的软硬件研发工具。

### vava-nessa/free-coding-models
<!-- github-record:{"week":"2026-W08","repository":"vava-nessa/free-coding-models","stars":2073,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/vava-nessa/free-coding-models
- 采集时可见 Star：2073
- 项目属性：编程模型与 API 端点发现配置工具
- 周次依据：候选清单标注为 2026-W08；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：追踪可用的免费或限额编程模型，并为多种 AI 编程工具安装相应 API 端点。
- 适用工作流：查询模型和提供方信息，选择端点后写入或生成目标编程工具的连接配置。
- 输入：模型筛选条件、提供方信息及目标 AI 编程工具配置。
- 输出：模型比较信息和已配置的 API 端点。
- 部署条件：当前 README 将其作为 Node.js/npm 工具提供，并面向多种本地 AI 编程客户端。
- 风险：免费额度、提供方可用性、速率限制和模型政策会变化；端点配置需要遵守各提供方的密钥与数据处理要求。
- 保留理由：直接服务于开发环境中编程模型的选择和接入，工作流明确。

### vmoranv/jshookmcp
<!-- github-record:{"week":"2026-W08","repository":"vmoranv/jshookmcp","stars":1689,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/vmoranv/jshookmcp
- 采集时可见 Star：1689
- 项目属性：JavaScript 分析与受控安全研究 MCP 工具
- 周次依据：候选清单标注为 2026-W08；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：通过 MCP 提供 JavaScript 分析、CDP 调试、网络拦截、源码映射和逆向分析等工具。
- 适用工作流：在 MCP 客户端配置服务，按需调用搜索、调试、代码分析或安全研究工具处理授权目标。
- 输入：授权目标的 JavaScript、浏览器会话、网络流量、二进制或源码映射数据。
- 输出：分析结果、调试信息、拦截记录和逆向辅助产物。
- 部署条件：当前 README 提供通过 npx 加入 MCP 客户端配置的方式，要求 Node.js 运行环境。
- 风险：网络拦截、浏览器自动化和逆向功能必须限于明确授权范围；工具面广，需最小权限配置并审查数据暴露。
- 保留理由：提供具体的 JavaScript 工程分析与受控安全验收能力。

### Zaneham/BarraCUDA
<!-- github-record:{"week":"2026-W08","repository":"Zaneham/BarraCUDA","stars":1700,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Zaneham/BarraCUDA
- 采集时可见 Star：1700
- 项目属性：异构 GPU 内核编译器
- 周次依据：候选清单标注为 2026-W08；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：将 CUDA C、HIP 或 Triton 源码编译为 AMD、NVIDIA、Tenstorrent 或 x86-64 等目标的可执行代码。
- 适用工作流：以 C99 工具链构建编译器，提供内核源码并选择后端目标，生成目标二进制后在对应环境验证。
- 输入：CUDA C、HIP 或 Triton 内核源码、目标后端和编译选项。
- 输出：GPU 二进制、PTX、目标平台代码或 x86-64 可执行结果。
- 部署条件：当前 README 要求 C99 编译器并使用 make 构建，不依赖 LLVM。
- 风险：后端功能和已验证硬件范围以当前项目文档为限，生成代码仍需在目标硬件上进行正确性与性能验证。
- 保留理由：直接用于 GPU 与异构计算软件的编译和硬件适配研发。

## 2026-W07

- 原始候选：30
- 保留：12
- 排除：18
- 候选不足：保留 12 条，不降低 Star 门槛补足。

### AlexsJones/llmfit
<!-- github-record:{"week":"2026-W07","repository":"AlexsJones/llmfit","stars":28573,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/AlexsJones/llmfit
- 采集时可见 Star：28573
- 项目属性：本地大模型硬件适配与基准测试工具
- 周次依据：候选输入将该仓库标注为 2026-W07；周次和星标仅保留为候选记录，不将当前 README 内容视为当周历史事实。
- 来源等级：C
- 核心功能：检测本机 CPU、内存和 GPU，评估并推荐可运行的本地大模型及量化配置。
- 适用工作流：扫描硬件配置，计算模型适配性与速度估计，交互式展示推荐；可运行基准并选择性提交测量结果。
- 输入：本机硬件信息、可选模型筛选条件和本地运行时配置。
- 输出：模型适配评分、速度估计、推荐量化方案及本地基准结果。
- 部署条件：Rust CLI/TUI，可接入 Ollama、llama.cpp、MLX、Docker Model Runner 和 LM Studio 等本地运行时。
- 风险：硬件和性能估计会随驱动、运行时与模型版本变化；共享基准结果前需核对公开范围。
- 保留理由：公开 README 明确描述其硬件探测、模型适配评估和本地运行时支持，属于可直接用于本地模型开发部署的具体工具。

### diegosouzapw/OmniRoute
<!-- github-record:{"week":"2026-W07","repository":"diegosouzapw/OmniRoute","stars":6875,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/diegosouzapw/OmniRoute
- 采集时可见 Star：6875
- 项目属性：AI 编码工具模型网关
- 周次依据：候选输入将该仓库标注为 2026-W07；周次和星标仅保留为候选记录，不将当前 README 内容视为当周历史事实。
- 来源等级：C
- 核心功能：将多个模型服务提供方聚合为统一端点，并为 AI 编码客户端提供路由、回退和上下文压缩。
- 适用工作流：配置上游模型提供方和凭据，将编码工具接入统一网关，由网关选择路由并在失败时回退。
- 输入：上游提供方配置、客户端请求及可选压缩策略。
- 输出：兼容客户端的模型 API 响应、路由状态和压缩后的上下文请求。
- 部署条件：本地或自托管 AI 网关，面向 Claude Code、Codex、Cursor、Cline 和 Copilot 等客户端。
- 风险：上游服务条款、免费额度、模型兼容性和令牌处理均可能变化；需妥善管理接入凭据。
- 保留理由：公开 README 将其定义为连接多家模型提供方的 AI Gateway，具有明确的编码工具接入和运行时路由功能。

### edison7009/EchoBird
<!-- github-record:{"week":"2026-W07","repository":"edison7009/EchoBird","stars":2620,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/edison7009/EchoBird
- 采集时可见 Star：2620
- 项目属性：跨平台 AI 工具安装与本地模型部署管理器
- 周次依据：候选输入将该仓库标注为 2026-W07；周次和星标仅保留为候选记录，不将当前 README 内容视为当周历史事实。
- 来源等级：C
- 核心功能：安装和修复 AI 开发工具，并统一管理本地大模型运行时、项目与模型连接配置。
- 适用工作流：选择安装、修复或本地模型场景，配置模型数据源，启动 bundled 推理运行时并管理项目。
- 输入：目标平台、本地或远程设备信息、模型配置和项目目录。
- 输出：已安装或修复的工具、本地推理服务状态和项目管理结果。
- 部署条件：基于 Tauri/Rust 的 Windows、macOS、Linux 桌面应用，集成 vLLM、SGLang 和 llama.cpp 等运行时。
- 风险：安装、远程修复和本地服务启动涉及系统权限、网络访问及模型资源占用，需要在目标环境验证。
- 保留理由：公开 README 明确列出工具安装修复、本地 LLM 启动和项目管理等可执行部署能力。

### jundot/omlx
<!-- github-record:{"week":"2026-W07","repository":"jundot/omlx","stars":17073,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/jundot/omlx
- 采集时可见 Star：17073
- 项目属性：macOS 本地大模型推理服务管理器
- 周次依据：候选输入将该仓库标注为 2026-W07；周次和星标仅保留为候选记录，不将当前 README 内容视为当周历史事实。
- 来源等级：C
- 核心功能：在 macOS 上托管本地 LLM 推理，提供连续批处理和分层 KV 缓存管理。
- 适用工作流：安装应用或 Homebrew 包，选择模型与上下文策略，启动后台服务并通过 CLI 或 MCP 控制。
- 输入：本地模型文件、推理参数、上下文限制和服务配置。
- 输出：本地模型 API 服务、缓存状态和推理结果。
- 部署条件：macOS 菜单栏应用与 CLI，可作为后台服务运行；可选安装 MCP 支持。
- 风险：仅面向 macOS，模型内存占用和自定义内核兼容性需要按设备与模型验证。
- 保留理由：公开 README 明确定位为 Mac 优化的 LLM inference 工具，提供服务管理、缓存和 CLI 集成。

### millionco/react-doctor
<!-- github-record:{"week":"2026-W07","repository":"millionco/react-doctor","stars":13127,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/millionco/react-doctor
- 采集时可见 Star：13127
- 项目属性：React 代码库静态诊断与 CI 审查工具
- 周次依据：候选输入将该仓库标注为 2026-W07；周次和星标仅保留为候选记录，不将当前 README 内容视为当周历史事实。
- 来源等级：C
- 核心功能：确定性扫描 React 代码库，发现状态、副作用、性能、架构、安全性和无障碍问题。
- 适用工作流：在项目根目录执行审计，可安装给编码代理使用，并配置 CI 在拉取请求中报告新增问题。
- 输入：React 项目源代码、规则配置及 CI 事件上下文。
- 输出：问题诊断报告、修复线索和拉取请求检查结果。
- 部署条件：通过 npx 运行，可安装为项目工具并集成 GitHub Actions 或 GitLab CI。
- 风险：静态规则可能产生误报或不覆盖运行时问题；CI 门禁策略需结合既有技术债配置。
- 保留理由：公开 README 描述了可执行代码扫描、代理集成与 PR CI 检查，研发用途明确且具体。

### open-webui/open-terminal
<!-- github-record:{"week":"2026-W07","repository":"open-webui/open-terminal","stars":2756,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/open-webui/open-terminal
- 采集时可见 Star：2756
- 项目属性：自托管远程终端与文件操作 API
- 周次依据：候选输入将该仓库标注为 2026-W07；周次和星标仅保留为候选记录，不将当前 README 内容视为当周历史事实。
- 来源等级：C
- 核心功能：通过 REST API 提供命令执行、文件管理和搜索能力，并可在隔离容器中运行。
- 适用工作流：以 Docker 沙箱或裸机模式部署服务，客户端调用 API 执行命令、管理文件和获取结果。
- 输入：API 请求、命令参数、工作目录和文件操作参数。
- 输出：命令执行结果、文件内容/元数据及搜索结果。
- 部署条件：自托管服务，支持预装工具链的 Docker 隔离模式或裸机模式。
- 风险：裸机模式可直接影响宿主机；即使容器部署也应限制 API 暴露、认证和挂载目录权限。
- 保留理由：公开 README 清楚定义了 API 化终端和文件管理功能，适用于自动化研发执行环境。

### PeonPing/peon-ping
<!-- github-record:{"week":"2026-W07","repository":"PeonPing/peon-ping","stars":4854,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/PeonPing/peon-ping
- 采集时可见 Star：4854
- 项目属性：编码代理事件通知工具
- 周次依据：候选输入将该仓库标注为 2026-W07；周次和星标仅保留为候选记录，不将当前 README 内容视为当周历史事实。
- 来源等级：C
- 核心功能：接收编码代理事件并以声音、系统通知、屏幕横幅和终端标题提示任务状态。
- 适用工作流：安装 CLI 或适配器，订阅支持工具的事件，在完成、提问或异常时输出可配置提醒。
- 输入：Claude Code、Codex、Cursor 等兼容工具的事件和本地通知配置。
- 输出：跨终端/桌面状态提醒、静音状态和调试日志。
- 部署条件：跨 Windows、macOS、Linux、WSL2、MSYS2 与 SSH 环境的 CLI/适配器。
- 风险：通知可能干扰工作环境；部分高级功能在 Windows 上尚未完全对齐，需根据平台验证。
- 保留理由：公开 README 显示其实现编码事件通知标准并提供多种编码工具适配，功能边界具体。

### pinchtab/pinchtab
<!-- github-record:{"week":"2026-W07","repository":"pinchtab/pinchtab","stars":9334,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/pinchtab/pinchtab
- 采集时可见 Star：9334
- 项目属性：轻量级浏览器自动化 HTTP 服务
- 周次依据：候选输入将该仓库标注为 2026-W07；周次和星标仅保留为候选记录，不将当前 README 内容视为当周历史事实。
- 来源等级：C
- 核心功能：以小型 Go 二进制和 HTTP API 暴露浏览器控制能力，供自动化程序调用。
- 适用工作流：启动本地服务，通过 HTTP 请求创建和控制浏览器标签页，获取页面状态并执行自动化操作。
- 输入：浏览器控制 API 请求、页面 URL、选择器和操作参数。
- 输出：页面内容、标签页状态、操作结果及浏览器自动化响应。
- 部署条件：单个 Go 二进制的本地服务，通过 HTTP API 集成；README 定位为 token-efficient。
- 风险：浏览器自动化可访问登录态和敏感页面，应限制 API 网络暴露并隔离浏览器配置文件。
- 保留理由：虽然面向 agent 集成，项目本体是可独立使用的具体浏览器控制服务，而非泛 agent 框架。

### rocketride-org/rocketride-server
<!-- github-record:{"week":"2026-W07","repository":"rocketride-org/rocketride-server","stars":4373,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/rocketride-org/rocketride-server
- 采集时可见 Star：4373
- 项目属性：AI 开发环境服务端
- 周次依据：候选输入将该仓库标注为 2026-W07；周次和星标仅保留为候选记录，不将当前 README 内容视为当周历史事实。
- 来源等级：C
- 核心功能：为 IDE 和终端提供构建、部署及运行 AI 解决方案的开发环境后端。
- 适用工作流：在 IDE 或 CLI 中连接服务端，配置项目和目标环境，构建、部署并管理 AI 解决方案。
- 输入：项目代码、开发环境配置、部署目标和命令行/IDE 请求。
- 输出：构建与部署结果、开发环境服务及运行状态。
- 部署条件：开源 AIDE 服务端，可由 IDE 或终端 CLI 使用。
- 风险：部署链路可能携带项目代码和环境凭据；应在接入生产目标前核查认证、权限与版本成熟度。
- 保留理由：公开 README 将其定义为 AI Development Environment，明确支持构建和部署 AI 解决方案。

### run-llama/liteparse
<!-- github-record:{"week":"2026-W07","repository":"run-llama/liteparse","stars":11003,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/run-llama/liteparse
- 采集时可见 Star：11003
- 项目属性：开源文档解析与 OCR 工具
- 周次依据：候选输入将该仓库标注为 2026-W07；周次和星标仅保留为候选记录，不将当前 README 内容视为当周历史事实。
- 来源等级：C
- 核心功能：解析 PDF 等文档并执行 OCR 与文本提取，为后续研发数据处理提供结构化文本。
- 适用工作流：将文档提交给解析器，执行页面解析和 OCR，消费提取出的文本或文档处理结果。
- 输入：PDF 等待解析文档及解析配置。
- 输出：OCR 识别文本、文档内容和解析结果。
- 部署条件：开源 Rust 项目，可作为文档处理组件或服务接入。
- 风险：OCR 和复杂版面解析存在准确性误差；上传或处理敏感文档时需评估数据驻留与访问控制。
- 保留理由：公开仓库描述将其定位为快速开源文档解析器，功能是明确的研发数据处理能力。

### unicity-astrid/astrid
<!-- github-record:{"week":"2026-W07","repository":"unicity-astrid/astrid","stars":10203,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/unicity-astrid/astrid
- 采集时可见 Star：10203
- 项目属性：能力安全的可组合软件运行时
- 周次依据：候选输入将该仓库标注为 2026-W07；周次和星标仅保留为候选记录，不将当前 README 内容视为当周历史事实。
- 来源等级：C
- 核心功能：提供可移植、以能力安全为核心的运行时，用于组合和隔离软件组件。
- 适用工作流：在运行时中定义组件能力与边界，部署组件并通过受控能力接口进行交互。
- 输入：组件代码、能力声明、运行时配置和 WebAssembly/系统接口需求。
- 输出：受隔离约束的组件执行结果、能力访问结果和运行时状态。
- 部署条件：Rust 实现的可移植运行时，README 标示支持 capability security、sandbox 与 WebAssembly 相关能力。
- 风险：安全边界取决于能力模型和宿主集成的正确配置；新运行时接入需进行隔离和兼容性验证。
- 保留理由：公开 README 定义其为可组合软件的能力安全操作系统，属于具体的底层研发基础设施。

### vercel-labs/portless
<!-- github-record:{"week":"2026-W07","repository":"vercel-labs/portless","stars":9942,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/vercel-labs/portless
- 采集时可见 Star：9942
- 项目属性：本地开发命名 URL 与 HTTPS 代理工具
- 周次依据：候选输入将该仓库标注为 2026-W07；周次和星标仅保留为候选记录，不将当前 README 内容视为当周历史事实。
- 来源等级：C
- 核心功能：为本地开发服务分配稳定的命名 .localhost URL，替代易变端口号并默认启用 HTTPS/HTTP2。
- 适用工作流：以全局 CLI 或项目开发依赖安装，在启动命令前调用 portless 并使用命名 URL 访问服务。
- 输入：应用启动命令、应用名称和本地开发服务端口。
- 输出：稳定的本地 URL、HTTPS 代理连接和服务访问入口。
- 部署条件：npm CLI，可全局安装或作为项目 dev dependency 使用。
- 风险：预发布阶段的状态目录格式可能变化；本地信任与证书状态需在团队环境中重新确认。
- 保留理由：公开 README 说明其直接解决本地开发服务的 URL、端口和 HTTPS 接入问题，研发工作流明确。

## 2026-W06

- 原始候选：30
- 保留：12
- 排除：18
- 候选不足：保留 12 条，不降低 Star 门槛补足。

### Ataraxy-Labs/sem
<!-- github-record:{"week":"2026-W06","repository":"Ataraxy-Labs/sem","stars":2981,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Ataraxy-Labs/sem
- 采集时可见 Star：2981
- 项目属性：语义化版本控制开发工具
- 周次依据：候选输入记录为 2026-W06；仅据此归档，当前公开 README 不作为该周历史状态证据。
- 来源等级：C
- 核心功能：在 Git 之上解析代码实体，以函数、方法和类等实体粒度展示变更。
- 适用工作流：开发者在代码仓库安装并运行 sem，对代码变更执行语义级比较；可接入支持 MCP 的编码代理。
- 输入：Git 仓库中的源代码与版本变更。
- 输出：实体级的代码变更信息。
- 部署条件：本地命令行工具，可在 Git 开发环境中使用。
- 风险：语义解析覆盖度受语言和代码结构影响；接入代理时需控制仓库数据暴露范围。
- 保留理由：当前 README 明确其为基于 Git 的语义化版本控制工具，直接服务软件研发中的代码审查与变更理解。

### dotnet/skills
<!-- github-record:{"week":"2026-W06","repository":"dotnet/skills","stars":3512,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/dotnet/skills
- 采集时可见 Star：3512
- 项目属性：.NET 编码代理技能与插件
- 周次依据：候选输入记录为 2026-W06；仅据此归档，当前公开 README 不作为该周历史状态证据。
- 来源等级：C
- 核心功能：为编码代理提供 .NET 开发技能、C# LSP 集成及特定 .NET 任务插件。
- 适用工作流：在兼容编码代理中安装所需插件，让代理在 .NET 项目中调用语言服务与领域技能。
- 输入：.NET 项目代码、开发任务和代理上下文。
- 输出：面向 .NET 开发的代理操作与辅助结果。
- 部署条件：作为编码代理的插件/技能集合安装。
- 风险：代理对代码和工具的操作需遵循项目权限边界；技能版本可能与目标 SDK 不兼容。
- 保留理由：当前 README 将其定位为 .NET 团队维护的编码代理核心技能和插件，直接对应 .NET 研发流程。

### excalidraw/excalidraw-mcp
<!-- github-record:{"week":"2026-W06","repository":"excalidraw/excalidraw-mcp","stars":4802,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/excalidraw/excalidraw-mcp
- 采集时可见 Star：4802
- 项目属性：Excalidraw MCP 图表服务
- 周次依据：候选输入记录为 2026-W06；仅据此归档，当前公开 README 不作为该周历史状态证据。
- 来源等级：C
- 核心功能：通过 MCP 流式提供 Excalidraw 手绘图表、视口控制和交互式编辑。
- 适用工作流：研发人员在支持 MCP Apps 的客户端连接远程服务或安装本地扩展，创建并编辑架构或流程图。
- 输入：客户端的图表创建、编辑和视口控制请求。
- 输出：可交互的 Excalidraw 图表与编辑会话。
- 部署条件：可使用 README 所列远程 MCP 地址，或下载扩展/从源码本地部署。
- 风险：远程连接与图表内容可能包含项目设计信息；客户端兼容性和服务可用性需要验证。
- 保留理由：当前 README 明确提供可连接的图表 MCP 服务，适用于研发设计文档和工程沟通。

### google-gemini/gemini-skills
<!-- github-record:{"week":"2026-W06","repository":"google-gemini/gemini-skills","stars":3697,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/google-gemini/gemini-skills
- 采集时可见 Star：3697
- 项目属性：Gemini API 开发技能库
- 周次依据：候选输入记录为 2026-W06；仅据此归档，当前公开 README 不作为该周历史状态证据。
- 来源等级：C
- 核心功能：提供构建 Gemini API 应用时所需的 API、SDK 和模型交互知识技能。
- 适用工作流：开发者将相关技能提供给兼容代理，在实现 Gemini API 应用时按技能中的当前接口与实践完成开发。
- 输入：Gemini API 应用需求、SDK 使用上下文和代理任务。
- 输出：面向 Gemini API 集成的开发指导与代理上下文。
- 部署条件：作为兼容 agent skills 标准的技能库使用。
- 风险：API、SDK 和模型行为会变化；实际调用仍需按目标账户、区域和凭据配置验证。
- 保留理由：当前 README 将范围限定为构建 Gemini API 应用的技能，具有明确的 AI 应用研发关联。

### jgraph/drawio-mcp
<!-- github-record:{"week":"2026-W06","repository":"jgraph/drawio-mcp","stars":4590,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/jgraph/drawio-mcp
- 采集时可见 Star：4590
- 项目属性：Draw.io MCP 图表集成
- 周次依据：候选输入记录为 2026-W06；仅据此归档，当前公开 README 不作为该周历史状态证据。
- 来源等级：C
- 核心功能：使 LLM 可在 draw.io 编辑器中创建和打开图表。
- 适用工作流：研发人员选择 MCP App Server、MCP Tool Server、Claude Code 插件或项目指令方式生成工程图表。
- 输入：自然语言图表需求和可选项目上下文。
- 输出：draw.io 文件、PNG/SVG/PDF 导出或浏览器编辑链接。
- 部署条件：可按 README 以 MCP 服务、插件或项目指令方式集成。
- 风险：自动生成的图表需人工校验技术准确性；图表内容可能暴露项目结构。
- 保留理由：当前 README 明确覆盖 draw.io 图表创建及工程文件导出，是具体研发文档工作流集成。

### matt1398/claude-devtools
<!-- github-record:{"week":"2026-W06","repository":"matt1398/claude-devtools","stars":3612,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/matt1398/claude-devtools
- 采集时可见 Star：3612
- 项目属性：Claude Code 会话调试工具
- 周次依据：候选输入记录为 2026-W06；仅据此归档，当前公开 README 不作为该周历史状态证据。
- 来源等级：C
- 核心功能：读取本机 Claude Code 会话记录，检查工具调用并跟踪 token 使用情况。
- 适用工作流：开发者在本机运行工具，对 Claude Code 日志中的会话和调用记录进行诊断。
- 输入：本机 Claude Code 会话日志。
- 输出：会话、工具调用和用量的调试视图。
- 部署条件：在保存 Claude Code 日志的本地开发环境使用。
- 风险：会话日志可能含代码或敏感上下文；应限制读取范围并避免共享原始记录。
- 保留理由：当前 README 将其定位为 Claude Code 调试工具，直接解决编码代理可观测性问题。

### mattpocock/skills
<!-- github-record:{"week":"2026-W06","repository":"mattpocock/skills","stars":145448,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/mattpocock/skills
- 采集时可见 Star：145448
- 项目属性：软件工程 agent skills 集合
- 周次依据：候选输入记录为 2026-W06；仅据此归档，当前公开 README 不作为该周历史状态证据。
- 来源等级：C
- 核心功能：提供可组合、可调整的工程实践技能，供兼容模型在实际应用开发中使用。
- 适用工作流：开发者通过 skills.sh 安装所选技能，再将其配置给兼容编码代理执行工程任务。
- 输入：工程开发任务、项目代码和选定技能。
- 输出：受工程实践约束的代理工作步骤与建议。
- 部署条件：作为技能包经 skills.sh 或兼容代理安装。
- 风险：技能文本不能替代项目测试和人工审查；安装来源与代理权限需评估。
- 保留理由：当前 README 明确称其为用于真实工程开发的可组合技能，研发用途具体而非面向通用个人助理。

### mitchellh/vouch
<!-- github-record:{"week":"2026-W06","repository":"mitchellh/vouch","stars":4827,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/mitchellh/vouch
- 采集时可见 Star：4827
- 项目属性：开发社区信任管理工具
- 周次依据：候选输入记录为 2026-W06；仅据此归档，当前公开 README 不作为该周历史状态证据。
- 来源等级：C
- 核心功能：以可解析的声明文件管理成员背书与拒绝名单，并提供 GitHub Actions 和 CLI 集成。
- 适用工作流：项目维护者维护背书记录，并在代码托管项目的交互或自动化流程中执行信任规则。
- 输入：项目成员的背书/拒绝记录与受保护的交互规则。
- 输出：允许或阻止参与项目指定部分的信任决策。
- 部署条件：通过 CLI 和 GitHub Actions 集成到代码托管项目。
- 风险：错误的信任记录会影响社区参与；需建立透明的治理、审计和申诉流程。
- 保留理由：当前 README 描述了面向代码托管项目的可配置社区信任控制，直接服务研发协作治理。

### rmyndharis/OpenWA
<!-- github-record:{"week":"2026-W06","repository":"rmyndharis/OpenWA","stars":9921,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/rmyndharis/OpenWA
- 采集时可见 Star：9921
- 项目属性：WhatsApp API 网关
- 周次依据：候选输入记录为 2026-W06；仅据此归档，当前公开 README 不作为该周历史状态证据。
- 来源等级：C
- 核心功能：为开发者提供可插拔的开源 WhatsApp API 网关及会话、Webhook 和 API key 管理能力。
- 适用工作流：开发团队配置数据库、存储和缓存适配器，部署网关并通过 API/Webhook 接入消息系统。
- 输入：WhatsApp 会话、API 请求、Webhook 配置及基础设施适配器配置。
- 输出：可供应用调用的消息 API、Webhook 事件和运维管理界面。
- 部署条件：作为可配置的服务部署，README 指出可替换 SQLite/PostgreSQL、Local/S3 与 Memory/Redis 等后端。
- 风险：消息内容和凭据敏感；需遵守 WhatsApp 平台条款并保护 API key、Webhook 与持久化数据。
- 保留理由：当前 README 明确定位为开发者可控的消息 API 网关，属于具体系统集成研发项目。

### SimoneAvogadro/android-reverse-engineering-skill
<!-- github-record:{"week":"2026-W06","repository":"SimoneAvogadro/android-reverse-engineering-skill","stars":6196,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/SimoneAvogadro/android-reverse-engineering-skill
- 采集时可见 Star：6196
- 项目属性：Android 逆向与 API 提取开发技能
- 周次依据：候选输入记录为 2026-W06；仅据此归档，当前公开 README 不作为该周历史状态证据。
- 来源等级：C
- 核心功能：反编译 APK/XAPK/JAR/AAR，并提取 Retrofit、OkHttp、URL 和认证模式等 HTTP API 线索。
- 适用工作流：在获得授权的 Android 产物上运行 Claude Code 技能，分析反编译结果并整理可复现的 API 文档。
- 输入：经授权的 Android APK、XAPK、JAR 或 AAR 文件。
- 输出：HTTP API 端点、调用模式及相关文档线索。
- 部署条件：作为 Claude Code 技能在本地逆向分析环境中使用。
- 风险：逆向活动受授权、许可和法规约束；产物及提取结果可能包含敏感接口或凭据。
- 保留理由：当前 README 将功能限定为 Android 二进制逆向和 API 提取，属于具体的软件研发与兼容性分析工作。

### tw93/Kaku
<!-- github-record:{"week":"2026-W06","repository":"tw93/Kaku","stars":5466,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/tw93/Kaku
- 采集时可见 Star：5466
- 项目属性：AI 编码终端
- 周次依据：候选输入记录为 2026-W06；仅据此归档，当前公开 README 不作为该周历史状态证据。
- 来源等级：C
- 核心功能：提供面向 AI 编码的终端，基于 WezTerm 定制默认体验并保留 Lua 配置能力。
- 适用工作流：开发者安装终端后，在其中运行 shell、编码代理和常用开发命令，并按需调整配置。
- 输入：开发者的终端命令、代码仓库和终端配置。
- 输出：用于 AI 辅助编码的本地终端交互环境。
- 部署条件：本地桌面终端应用。
- 风险：终端会继承用户权限并可访问敏感环境变量；应遵循最小权限和命令审查。
- 保留理由：当前 README 明确定位为 AI 编码终端，直接支持日常软件研发执行环境。

### Yeachan-Heo/oh-my-codex
<!-- github-record:{"week":"2026-W06","repository":"Yeachan-Heo/oh-my-codex","stars":31329,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Yeachan-Heo/oh-my-codex
- 采集时可见 Star：31329
- 项目属性：Codex 工程工作流扩展
- 周次依据：候选输入记录为 2026-W06；仅据此归档，当前公开 README 不作为该周历史状态证据。
- 来源等级：C
- 核心功能：为 Codex 增加工程提示、工作流和运行时辅助能力。
- 适用工作流：开发者在满足 README 所列 Node.js 版本要求的环境安装 OMX，并在 Codex 工程任务中启用其 agents、skills 或集成。
- 输入：Codex 工程任务、项目上下文和 OMX 配置。
- 输出：增强的工程提示、工作流步骤和运行时辅助。
- 部署条件：Node.js 包形式的本地 Codex 扩展，README 当前标注 Node.js 20 或更高版本。
- 风险：扩展会影响代理指令与工具调用范围；应审查第三方提示、集成配置和项目访问权限。
- 保留理由：当前 README 将其定位为加强 Codex 工程提示、工作流和运行时支持的扩展，直接关联研发工作流。

## 2026-W05

- 原始候选：30
- 保留：13
- 排除：17
- 候选不足：保留 13 条，不降低 Star 门槛补足。

### Alishahryar1/free-claude-code
<!-- github-record:{"week":"2026-W05","repository":"Alishahryar1/free-claude-code","stars":36885,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Alishahryar1/free-claude-code
- 采集时可见 Star：36885
- 项目属性：编码模型接入与代理工具
- 周次依据：候选清单仅标注为 2026-W05（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：通过本地代理为 Claude Code、Codex 等编码工具接入可选模型提供方。
- 适用工作流：开发者配置模型提供方和客户端，再由本地代理统一转发编码工具请求。
- 输入：编码客户端请求、模型提供方配置和访问凭据。
- 输出：兼容客户端协议的模型响应与本地管理配置。
- 部署条件：按当前 README 在本地部署代理和管理界面，并连接目标编码客户端。
- 风险：涉及模型访问凭据、转发数据及供应商使用条款；需审查密钥存储、数据流向和账号合规性。
- 保留理由：当前公开资料将其定位为编码工具的模型接入代理，直接服务软件研发环境；仅按 C 级候选收录。

### always-further/nono
<!-- github-record:{"week":"2026-W05","repository":"always-further/nono","stars":2804,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/always-further/nono
- 采集时可见 Star：2804
- 项目属性：编码 agent 最小权限沙箱
- 周次依据：候选清单仅标注为 2026-W05（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：为编码 agent 提供无需常驻服务的最小权限隔离运行环境。
- 适用工作流：开发者选择或定制沙箱配置后，在受限环境中启动编码 agent 并共享团队配置。
- 输入：编码 agent、项目目录和沙箱权限配置。
- 输出：隔离的 agent 执行环境及可复用配置包。
- 部署条件：按当前 README 在 macOS、Linux 或 WSL2 安装命令行工具并应用沙箱配置。
- 风险：沙箱配置错误仍可能暴露源码、凭据或宿主资源；需验证权限策略、挂载范围和网络访问。
- 保留理由：它提供的是开发自动化的具体安全隔离能力，而非通用 agent 本体；仅按 C 级候选收录。

### BenedictKing/ccx
<!-- github-record:{"week":"2026-W05","repository":"BenedictKing/ccx","stars":3724,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/BenedictKing/ccx
- 采集时可见 Star：3724
- 项目属性：多模型 API 协议代理
- 周次依据：候选清单仅标注为 2026-W05（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：在 Claude、OpenAI、Codex、Gemini 等接口之间提供统一入口与协议转换。
- 适用工作流：研发团队配置后端模型渠道和路由规则，客户端经统一代理调用所需接口。
- 输入：模型 API 请求、渠道配置、路由策略和密钥。
- 输出：协议兼容的模型响应、故障切换结果和管理数据。
- 部署条件：按当前 README 部署代理服务及其 Web 管理界面，并配置受控的后端渠道。
- 风险：集中保存多家模型密钥并转发请求；需限制管理界面、审查日志脱敏和供应商合规性。
- 保留理由：当前公开资料表明其是可部署的模型 API 集成基础设施，可用于研发系统接入；仅按 C 级候选收录。

### callstack/agent-device
<!-- github-record:{"week":"2026-W05","repository":"callstack/agent-device","stars":2902,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/callstack/agent-device
- 采集时可见 Star：2902
- 项目属性：多端应用验证自动化 CLI
- 周次依据：候选清单仅标注为 2026-W05（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：让自动化流程在移动端、桌面端和 Web 应用上检查界面、执行操作并采集证据。
- 适用工作流：启动真实设备或模拟器中的应用，CLI 读取可访问性快照并执行确定性操作，再输出验证证据。
- 输入：待测应用、设备或模拟器会话、测试任务和界面元素引用。
- 输出：结构化界面快照、交互结果和可审查的调试证据。
- 部署条件：作为本地 CLI 接入应用开发或 QA 环境，并配置受支持的设备、模拟器或浏览器会话。
- 风险：自动化会操作真实应用和测试账户；需隔离测试数据、控制设备权限并审查采集内容。
- 保留理由：当前 README 明确其用于多端应用验证和调试证据采集，属于具体的软件测试研发工具；仅按 C 级候选收录。

### dwzhu-pku/PaperBanana
<!-- github-record:{"week":"2026-W05","repository":"dwzhu-pku/PaperBanana","stars":6622,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/dwzhu-pku/PaperBanana
- 采集时可见 Star：6622
- 项目属性：学术论文插图生成辅助工具
- 周次依据：候选清单仅标注为 2026-W05（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：辅助为学术论文生成和迭代技术插图。
- 适用工作流：研究人员提供论文内容或图示需求，系统调用现有模型生成候选插图并供人工筛选修订。
- 输入：论文上下文、技术概念、图示要求和参考材料。
- 输出：用于论文或技术报告的候选插图资产。
- 部署条件：按当前仓库说明配置运行环境及所需模型服务后运行。
- 风险：生成内容可能误表达实验结论或引入版权问题；需人工核验科学准确性、来源和模型许可。
- 保留理由：当前公开资料聚焦学术论文插图这一明确科研产出，而非模型训练、微调或纯能力展示；仅按 C 级候选收录。

### EvoScientist/EvoScientist
<!-- github-record:{"week":"2026-W05","repository":"EvoScientist/EvoScientist","stars":3780,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/EvoScientist/EvoScientist
- 采集时可见 Star：3780
- 项目属性：科研任务协作系统
- 周次依据：候选清单仅标注为 2026-W05（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：围绕科研问题组织规划、检索、编程、调试等研究步骤。
- 适用工作流：研究者定义研究问题和可用资料，系统分配研究步骤并沉淀过程信息，研究者审核结果。
- 输入：研究问题、文献和数据资料、实验或代码环境及人工约束。
- 输出：研究过程记录、实验或代码产物及待人工审阅的结论材料。
- 部署条件：按当前 README 配置模型、工具和运行环境后接入研究工作流。
- 风险：自动研究可能产生不可靠结论或执行高成本任务；需保留人工审核、限制工具权限并保护未公开研究数据。
- 保留理由：当前公开资料将其限定于科研研究流程，而非面向任意任务的个人助理；仅按 C 级候选收录。

### Galaxy-Dawn/claude-scholar
<!-- github-record:{"week":"2026-W05","repository":"Galaxy-Dawn/claude-scholar","stars":4404,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Galaxy-Dawn/claude-scholar
- 采集时可见 Star：4404
- 项目属性：学术研究与软件研发协作助手
- 周次依据：候选清单仅标注为 2026-W05（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：为计算机科学和 AI 研究提供文献、编码、实验、报告及项目知识管理流程支持。
- 适用工作流：研究者组织文献和项目上下文，调用兼容的编码工具完成研究任务，并人工复核阶段结果。
- 输入：文献资料、项目代码、实验需求、研究计划和工具配置。
- 输出：研究任务上下文、实验和编码过程材料、报告草稿及知识记录。
- 部署条件：按当前 README 在本地配置兼容的编码 CLI 和研究项目环境后使用。
- 风险：会处理未发表研究、源码和模型凭据；输出需经作者审查，且应限制自动命令和外部数据访问。
- 保留理由：当前公开资料明确面向学术研究与软件开发，任务范围具体，不是面向日常事务的泛 agent；仅按 C 级候选收录。

### manaflow-ai/cmux
<!-- github-record:{"week":"2026-W05","repository":"manaflow-ai/cmux","stars":22882,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/manaflow-ai/cmux
- 采集时可见 Star：22882
- 项目属性：编码 agent 终端工作台
- 周次依据：候选清单仅标注为 2026-W05（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：提供带垂直标签和通知机制的 macOS 终端，以便开发者跟踪编码 agent 的状态。
- 适用工作流：开发者在终端窗格中运行编码 agent，工作台汇总待处理通知并帮助切换到相应会话。
- 输入：本地终端会话、编码 agent 进程和其通知事件。
- 输出：多会话终端界面、通知面板和待处理状态。
- 部署条件：按当前 README 在 macOS 安装桌面终端应用并连接本地开发会话。
- 风险：终端会话可能显示源码、命令和凭据；需遵守本机访问控制并审查第三方插件权限。
- 保留理由：这是针对编码 agent 协作的具体开发终端工具，不是 agent 编排或个人助理；仅按 C 级候选收录。

### mindfold-ai/Trellis
<!-- github-record:{"week":"2026-W05","repository":"mindfold-ai/Trellis","stars":11066,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/mindfold-ai/Trellis
- 采集时可见 Star：11066
- 项目属性：AI 辅助软件项目规范与任务管理工具
- 周次依据：候选清单仅标注为 2026-W05（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：在代码库内维护规范、任务上下文、审阅信息和项目记忆，并将相关上下文提供给开发会话。
- 适用工作流：团队在项目中编写规范和任务材料，工具按任务关联上下文，开发会话据此实施并记录进展。
- 输入：项目规范、PRD、任务状态、审阅上下文和源码工作区。
- 输出：按任务组织的开发上下文、项目记忆和可追踪工作材料。
- 部署条件：按当前 README 在目标代码仓库初始化 `.trellis` 目录并接入开发会话。
- 风险：项目上下文可能包含专有源码和规划信息；需控制仓库访问权限并审核自动写入行为。
- 保留理由：它解决代码项目的规范、任务和上下文管理这一具体研发流程，不是泛 agent 本体；仅按 C 级候选收录。

### robinebers/openusage
<!-- github-record:{"week":"2026-W05","repository":"robinebers/openusage","stars":2953,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/robinebers/openusage
- 采集时可见 Star：2953
- 项目属性：AI 编码订阅用量观测工具
- 周次依据：候选清单仅标注为 2026-W05（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：在 macOS 菜单栏汇总 AI 编码服务的会话、周额度、积分和支出使用情况。
- 适用工作流：开发者连接受支持的编码服务账户，在本机查看用量并据此安排研发工具使用。
- 输入：受支持 AI 编码服务的本地账户或用量信息。
- 输出：会话额度、周用量、积分和支出的本地状态视图。
- 部署条件：按当前 README 通过 macOS 安装包或 Homebrew 安装本地应用。
- 风险：用量读取可能涉及账户令牌和消费信息；需核实本地存储、网络访问和服务商授权方式。
- 保留理由：当前公开资料明确服务于 AI 编码工具的用量观测，能支持研发环境成本与额度管理；仅按 C 级候选收录。

### TabularisDB/tabularis
<!-- github-record:{"week":"2026-W05","repository":"TabularisDB/tabularis","stars":3341,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/TabularisDB/tabularis
- 采集时可见 Star：3341
- 项目属性：数据库桌面管理与 MCP 查询工具
- 周次依据：候选清单仅标注为 2026-W05（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：在桌面应用中管理数据库模式和查询，并向开发工具提供 MCP 查询能力。
- 适用工作流：开发者连接目标数据库，在界面中检查模式和执行查询，受控的开发工具可经 MCP 使用相同数据库上下文。
- 输入：数据库连接配置、模式信息、SQL 查询和 MCP 客户端请求。
- 输出：查询结果、数据库模式视图和供开发工具使用的查询响应。
- 部署条件：按当前 README 安装桌面应用，并在受控环境中配置数据库连接和 MCP 客户端。
- 风险：数据库凭据和查询结果可能包含敏感数据；应使用最小权限账号、隔离生产环境并审查 agent 查询权限。
- 保留理由：这是明确的数据库研发与调试工具，MCP 只是集成方式，不属于泛 agent；仅按 C 级候选收录。

### unicity-sphere/sphere-sdk
<!-- github-record:{"week":"2026-W05","repository":"unicity-sphere/sphere-sdk","stars":5446,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/unicity-sphere/sphere-sdk
- 采集时可见 Star：5446
- 项目属性：Unicity Layer 3 钱包开发 SDK
- 周次依据：候选清单仅标注为 2026-W05（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：为 Unicity Layer 3 的钱包密钥、支付、发票和账户功能提供 TypeScript 开发接口。
- 适用工作流：应用开发者在代码中调用 SDK 创建或管理钱包状态、构造支付及处理相关账户逻辑。
- 输入：应用调用、钱包状态、密钥材料、支付参数和网络配置。
- 输出：钱包操作结果、支付请求及账户相关数据结构。
- 部署条件：作为 TypeScript SDK 安装到目标应用，并按当前说明配置网络与密钥管理。
- 风险：涉及私钥、资金操作和实验性功能；必须使用安全密钥保管、测试环境和交易前人工核验。
- 保留理由：当前公开资料显示其为明确区块链应用研发 SDK；其支付领域不等同于股票投机项目；仅按 C 级候选收录。

### zarazhangrui/frontend-slides
<!-- github-record:{"week":"2026-W05","repository":"zarazhangrui/frontend-slides","stars":22950,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/zarazhangrui/frontend-slides
- 采集时可见 Star：22950
- 项目属性：前端技术演示文稿生成技能
- 周次依据：候选清单仅标注为 2026-W05（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：让编码 agent 从头创建 HTML 演示文稿或转换 PowerPoint 文件。
- 适用工作流：研发人员提供演示主题或源文件，编码 agent 按技能生成可编辑的前端演示文稿并供人工修改。
- 输入：演示需求、文本资料、品牌约束或 PowerPoint 源文件。
- 输出：HTML 演示文稿及其前端源码。
- 部署条件：按当前 README 作为 Claude Code 插件或供兼容编码 agent 读取的技能安装。
- 风险：输入演示材料可能包含未公开技术信息；生成内容应核查准确性、版权和组织发布规范。
- 保留理由：它提供的是可执行、范围明确的技术沟通产物生成流程，不是泛 agent 或纯展示仓库；仅按 C 级候选收录。

## 2026-W04

- 原始候选：30
- 保留：11
- 排除：19
- 候选不足：保留 11 条，不降低 Star 门槛补足。

### AvdLee/SwiftUI-Agent-Skill
<!-- github-record:{"week":"2026-W04","repository":"AvdLee/SwiftUI-Agent-Skill","stars":3103,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/AvdLee/SwiftUI-Agent-Skill
- 采集时可见 Star：3103
- 项目属性：SwiftUI 开发专家技能
- 周次依据：候选清单仅标注为 2026-W04（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：为 AI 编码助手提供 SwiftUI 开发模式与实现约束。
- 适用工作流：在 SwiftUI 应用的界面实现、代码审查和问题修正中向编码助手注入框架专用知识。
- 输入：SwiftUI 工程、界面需求、现有代码与兼容的编码助手。
- 输出：符合 SwiftUI 模式的实现建议、代码改动和审查结果。
- 部署条件：按当前仓库 README 将技能接入兼容的 AI 编码环境，并在目标工程中验证其规则。
- 风险：第三方技能可能造成不符合项目架构的代码改动；应审查指令来源、依赖版本和本地文件权限。
- 保留理由：功能明确绑定 SwiftUI 软件开发，具有具体的前端研发工作流边界。

### ColeMurray/background-agents
<!-- github-record:{"week":"2026-W04","repository":"ColeMurray/background-agents","stars":2049,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/ColeMurray/background-agents
- 采集时可见 Star：2049
- 项目属性：后台编码 Agent 系统
- 周次依据：候选清单仅标注为 2026-W04（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：在受控开发环境中后台执行代码任务，并使用 Node.js、Python、Git、浏览器自动化和 VS Code 等开发工具。
- 适用工作流：开发者提交代码任务后由后台任务执行环境处理，开发者可继续进行其他研发工作并查看结果。
- 输入：开发任务、代码仓库、开发环境权限和必要的模型服务配置。
- 输出：代码改动、命令执行结果、任务状态和研发环境中的验证产物。
- 部署条件：需按当前 README 部署其后台服务和开发环境，并最小化授予仓库、浏览器和模型访问权限。
- 风险：后台 Agent 可读写代码并运行命令，存在凭据暴露、提示注入、误改和资源消耗风险。
- 保留理由：README 明确限定为后台编码任务与完整开发环境，而非无边界的通用 Agent。

### Hmbown/CodeWhale
<!-- github-record:{"week":"2026-W04","repository":"Hmbown/CodeWhale","stars":38989,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Hmbown/CodeWhale
- 采集时可见 Star：38989
- 项目属性：本地终端 AI 编程 Agent
- 周次依据：候选清单仅标注为 2026-W04（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：在本地终端读取代码、编辑文件、运行命令并检查结果，支持交互式与脚本化编码任务。
- 适用工作流：开发者提供模型、任务和代码目录，工具在终端中执行连续的软件实现与核验步骤。
- 输入：本地代码库、开发任务、模型服务配置和受控终端权限。
- 输出：代码改动、命令结果、检查结果和可用于 CI 的执行状态。
- 部署条件：按当前 README 安装 Rust 程序并配置模型提供方；应在隔离工作树中授予最小目录与命令权限。
- 风险：工具可修改代码并执行命令，涉及模型凭据、供应链、误改和自动化成本风险。
- 保留理由：当前 README 明确其为本地终端编码工具，直接服务软件研发而非泛化任务代理。

### PerryTS/perry
<!-- github-record:{"week":"2026-W04","repository":"PerryTS/perry","stars":3859,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/PerryTS/perry
- 采集时可见 Star：3859
- 项目属性：Rust 实现的原生 TypeScript 编译器
- 周次依据：候选清单仅标注为 2026-W04（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：将 TypeScript 编译为不依赖 Node.js 或浏览器引擎的原生可执行文件。
- 适用工作流：研发者输入 TypeScript 源码并调用编译命令，产出目标平台可运行的原生二进制。
- 输入：TypeScript 源文件、编译命令、构建配置和目标平台工具链。
- 输出：原生可执行文件及相关编译诊断。
- 部署条件：需按当前 README 安装编译器，并在目标平台验证 LLVM、系统依赖和生成程序兼容性。
- 风险：编译器成熟度、平台兼容性和调试支持需实际验证；生成的原生程序仍须接受安全与功能测试。
- 保留理由：提供确定的 TypeScript 编译与交付能力，直接属于软件研发工具链。

### rorkai/App-Store-Connect-CLI
<!-- github-record:{"week":"2026-W04","repository":"rorkai/App-Store-Connect-CLI","stars":4892,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/rorkai/App-Store-Connect-CLI
- 采集时可见 Star：4892
- 项目属性：App Store Connect 发布自动化 CLI
- 周次依据：候选清单仅标注为 2026-W04（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：通过 App Store Connect API 在终端自动化 iOS、macOS、tvOS 和 visionOS 的发布流程。
- 适用工作流：研发团队在构建与发布阶段以脚本调用 CLI 管理应用商店交付相关操作。
- 输入：App Store Connect API 配置、应用标识、发布参数和受控认证信息。
- 输出：发布工作流的 API 操作结果、状态信息和自动化脚本执行结果。
- 部署条件：按当前 README 安装 CLI，并通过受控环境变量或密钥管理提供 App Store Connect 凭据。
- 风险：错误操作可能影响应用发布状态；API 密钥、商店权限、服务条款和自动化发布步骤需要最小授权与人工复核。
- 保留理由：README 明确其为移动与桌面软件发布自动化工具，直接服务研发交付流程。

### rtk-ai/rtk
<!-- github-record:{"week":"2026-W04","repository":"rtk-ai/rtk","stars":65904,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/rtk-ai/rtk
- 采集时可见 Star：65904
- 项目属性：LLM Token 压缩 CLI 代理
- 周次依据：候选清单仅标注为 2026-W04（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：提供高性能 CLI 代理以减少 LLM 调用中的 Token 消耗。
- 适用工作流：将 AI 辅助研发工具的模型请求接入代理层，压缩上下文后转发并观察成本与响应效果。
- 输入：模型请求、上下文内容、上游模型端点和代理配置。
- 输出：压缩后的请求、上游模型响应及用量优化结果。
- 部署条件：需依照当前 README 安装 CLI 并配置模型端点；生产接入前应验证压缩策略与数据边界。
- 风险：代理会处理代码与模型请求，压缩可能丢失关键上下文；还存在凭据泄露、计费、兼容性和供应链风险。
- 保留理由：该项目提供具体的 LLM 工程基础设施，可用于 AI 辅助研发的上下文和成本控制。

### skyhook-io/radar
<!-- github-record:{"week":"2026-W04","repository":"skyhook-io/radar","stars":2472,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/skyhook-io/radar
- 采集时可见 Star：2472
- 项目属性：开源 Kubernetes 运维 UI
- 周次依据：候选清单仅标注为 2026-W04（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：以单一二进制提供 Kubernetes 拓扑、资源、Helm、GitOps、流量、审计和 Agent 上下文查看能力。
- 适用工作流：平台研发或运维人员连接本地或集群环境，检查资源状态并辅助部署、排障和审计。
- 输入：Kubernetes 集群连接、kubeconfig、集群资源及可选的集群内运行配置。
- 输出：集群拓扑与资源视图、审计和运维操作结果。
- 部署条件：需按当前 README 运行单一二进制，并以最小 RBAC 权限接入本地或集群内环境。
- 风险：Kubernetes 管理工具可暴露集群资源与凭据；错误权限或操作会影响工作负载、密钥和生产可用性。
- 保留理由：提供边界明确的 Kubernetes 研发运维能力，不是泛 Agent 编排。

### supermemoryai/claude-supermemory
<!-- github-record:{"week":"2026-W04","repository":"supermemoryai/claude-supermemory","stars":2681,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/supermemoryai/claude-supermemory
- 采集时可见 Star：2681
- 项目属性：Claude Code 跨会话工程记忆插件
- 周次依据：候选清单仅标注为 2026-W04（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：为 Claude Code 保存跨会话、跨项目的工程上下文，并提供团队和项目级记忆配置。
- 适用工作流：编码助手结束会话时捕获项目上下文，后续研发会话按项目配置检索和使用相关记忆。
- 输入：Claude Code 会话内容、项目配置、仓库上下文和 Supermemory 服务访问配置。
- 输出：跨会话记忆、项目知识和供编码助手使用的上下文。
- 部署条件：需按当前 README 在 Claude Code 中安装插件，并配置所需的 Supermemory 服务与受控的项目访问范围。
- 风险：服务可能持久保存代码、会话和项目配置；应审查数据留存、API 密钥、外部服务合规性和提示注入风险。
- 保留理由：项目明确服务 Claude Code 的跨项目工程记忆，具有具体 AI 编程研发用途。

### tanweai/wooyun-legacy
<!-- github-record:{"week":"2026-W04","repository":"tanweai/wooyun-legacy","stars":1721,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/tanweai/wooyun-legacy
- 采集时可见 Star：1721
- 项目属性：授权安全测试案例参考技能
- 周次依据：候选清单仅标注为 2026-W04（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：将 WooYun 公开业务逻辑漏洞案例与统计数据用于安全测试报告的证据和测试优先级参考。
- 适用工作流：授权安全团队在代码审计或安全测试中调用技能，以历史公开案例辅助风险说明和测试优先级判断。
- 输入：授权测试任务、安全报告草稿、业务逻辑测试上下文和技能中的公开案例数据。
- 输出：带案例引用和统计信息的安全报告补充材料及测试优先级建议。
- 部署条件：按当前 README 接入 Claude Code，并仅用于授权测试、内部安全评估或代码审计；其数据时效性需独立核验。
- 风险：旧案例数据覆盖范围有限且可能被误用于未授权测试；输出不可替代当前漏洞验证、法律合规和人工安全审查。
- 保留理由：README 明确面向白帽研究、安全团队和企业内部授权测试，服务于具体的安全研发流程。

### vuejs-ai/skills
<!-- github-record:{"week":"2026-W04","repository":"vuejs-ai/skills","stars":2636,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/vuejs-ai/skills
- 采集时可见 Star：2636
- 项目属性：Vue 3 开发 Agent Skills
- 周次依据：候选清单仅标注为 2026-W04（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：向 AI Agent 提供来源于实际问题的 Vue 3 开发专用技能。
- 适用工作流：在 Vue 3 项目中加载技能，使编码助手参考框架问题、模式和实现约束完成开发任务。
- 输入：Vue 3 代码库、前端需求、现有问题上下文和兼容的 AI 编码环境。
- 输出：Vue 3 实现建议、代码改动和框架相关的开发结果。
- 部署条件：按当前 README 以兼容的 Agent Skills 方式接入，并在项目中验证技能内容与框架版本。
- 风险：README 标记为早期社区实验，技能可能不完整或含错误；自动生成代码仍需进行版本、质量和安全审查。
- 保留理由：功能直接限定于 Vue 3 前端开发，属于具体软件研发辅助能力。

### WordPress/agent-skills
<!-- github-record:{"week":"2026-W04","repository":"WordPress/agent-skills","stars":1746,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/WordPress/agent-skills
- 采集时可见 Star：1746
- 项目属性：WordPress 开发 Agent Skills
- 周次依据：候选清单仅标注为 2026-W04（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：向 AI 编码助手提供 WordPress 开发模式、安全要求和最佳实践的指令、检查清单与脚本。
- 适用工作流：在主题、区块或插件开发中加载技能，帮助编码助手遵循现代 WordPress 模式并避免常见错误。
- 输入：WordPress 工程、插件或主题需求、现有代码和兼容的 AI 编码助手。
- 输出：开发约束、检查结果和符合 WordPress 模式的代码建议或改动。
- 部署条件：按当前仓库文档将技能接入兼容的编码助手，并结合目标 WordPress 与 Gutenberg 版本进行验证。
- 风险：技能内容及生成代码可能与项目版本或安全要求不完全一致；应审查第三方指令并执行测试、代码审查和安全验证。
- 保留理由：README 明确面向 WordPress 编程助手和插件/主题开发，具备具体软件研发边界。

## 2026-W03

- 原始候选：30
- 保留：10
- 排除：20
- 候选不足：保留 10 条，不降低 Star 门槛补足。

### benjitaylor/agentation
<!-- github-record:{"week":"2026-W03","repository":"benjitaylor/agentation","stars":4012,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/benjitaylor/agentation
- 采集时可见 Star：4012
- 项目属性：开发协作反馈工具
- 周次依据：候选清单仅标注为 2026-W03（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：在界面上采集视觉反馈并交给编码 agent 处理。
- 适用工作流：开发者在待改页面标注问题并提交，工具将反馈组织为 agent 可消费的任务上下文。
- 输入：浏览器页面、截图或视觉标注反馈。
- 输出：结构化的界面修改反馈与开发任务上下文。
- 部署条件：作为项目开发依赖通过 npm 安装，并在本地开发流程中接入。
- 风险：会把页面内容和反馈交给 agent；需核实数据边界、模型提供方与依赖版本。
- 保留理由：当前公开资料将其定位为面向 agent 的可视化反馈工具，能服务前端研发迭代；仅按 C 级候选收录。

### BIT-DataLab/Edit-Banana
<!-- github-record:{"week":"2026-W03","repository":"BIT-DataLab/Edit-Banana","stars":5367,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/BIT-DataLab/Edit-Banana
- 采集时可见 Star：5367
- 项目属性：科研图表与静态内容可编辑化工具
- 周次依据：候选清单仅标注为 2026-W03（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：将静态统计图等内容重建为可编辑资产，并保留图形细节和逻辑关系。
- 适用工作流：输入固定格式内容，调用多模态模型进行识别和重建，再输出可继续编辑的结果。
- 输入：静态图表、图像或固定格式内容。
- 输出：可操作、可修改的图表或内容资产。
- 部署条件：Python 项目，需按仓库当前说明配置模型与运行环境。
- 风险：依赖多模态模型及其许可和资源消耗；重建结果需人工校验，不能作为原始数据证据。
- 保留理由：当前公开 README 显示其聚焦科研/数据图表的可编辑重建，而非模型训练或纯展示；与工程文档和数据处理相关。

### ChartGPU/ChartGPU
<!-- github-record:{"week":"2026-W03","repository":"ChartGPU/ChartGPU","stars":3141,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/ChartGPU/ChartGPU
- 采集时可见 Star：3141
- 项目属性：WebGPU 高性能图表库
- 周次依据：候选清单仅标注为 2026-W03（legacy-table）；当前公开仓库描述只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：提供基于 WebGPU 的开源高性能图表渲染能力。
- 适用工作流：研发应用传入数据与图表配置，由浏览器 GPU 渲染交互式可视化。
- 输入：结构化数据、图表类型与渲染配置。
- 输出：浏览器内的高性能图表视图。
- 部署条件：TypeScript/Web 前端依赖，需在目标浏览器验证 WebGPU 可用性。
- 风险：受 WebGPU、显卡驱动和浏览器兼容性影响；大数据渲染需评估显存与性能。
- 保留理由：这是具体的数据可视化研发组件，适用于实验、遥测和工程数据展示；金融图表只是其支持场景之一。

### colbymchenry/codegraph
<!-- github-record:{"week":"2026-W03","repository":"colbymchenry/codegraph","stars":54381,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/colbymchenry/codegraph
- 采集时可见 Star：54381
- 项目属性：本地代码知识图谱索引工具
- 周次依据：候选清单仅标注为 2026-W03（legacy-table）；当前公开仓库描述只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：为代码库建立预索引知识图谱，并随代码变更自动同步。
- 适用工作流：本地扫描代码并建立索引，编码工具或 agent 查询索引以获得代码上下文。
- 输入：本地源码仓库及其后续文件变更。
- 输出：可供开发工具查询的本地代码知识图谱和上下文。
- 部署条件：TypeScript 工具，按仓库说明在本地代码库初始化并运行索引服务。
- 风险：索引可能包含专有源码；需审查联网行为、忽略规则、资源占用及工具权限。
- 保留理由：当前仓库描述明确其提供本地代码索引，直接服务代码理解和研发效率，不是泛 agent 本体。

### github/copilot-sdk
<!-- github-record:{"week":"2026-W03","repository":"github/copilot-sdk","stars":9447,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/github/copilot-sdk
- 采集时可见 Star：9447
- 项目属性：GitHub Copilot 集成 SDK
- 周次依据：候选清单仅标注为 2026-W03（legacy-table）；当前公开仓库描述只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：为应用和服务集成 GitHub Copilot Agent 提供多平台 SDK。
- 适用工作流：研发应用通过 SDK 发起 Copilot 会话或任务，并处理返回的 agent 结果。
- 输入：应用中的任务请求、代码上下文和 SDK 配置。
- 输出：Copilot Agent 的响应、会话事件或任务结果。
- 部署条件：按目标语言安装官方 SDK，并配置 Copilot 可用的认证和运行条件。
- 风险：依赖外部服务、认证和许可；不得将密钥或专有代码上下文无控制地发送到服务端。
- 保留理由：当前仓库描述表明它是明确的官方集成 SDK，可用于构建研发辅助能力，而非独立的泛 agent 产品。

### google-labs-code/stitch-skills
<!-- github-record:{"week":"2026-W03","repository":"google-labs-code/stitch-skills","stars":6156,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/google-labs-code/stitch-skills
- 采集时可见 Star：6156
- 项目属性：Google Stitch 设计技能库
- 周次依据：候选清单仅标注为 2026-W03（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：为 Stitch MCP 提供遵循 Agent Skills 开放标准的设计与前端生成技能。
- 适用工作流：在支持该标准的编码工具中加载技能，再经 Stitch MCP 执行相应设计工作流。
- 输入：界面设计任务、提示词和 Stitch MCP 可访问的项目上下文。
- 输出：由 Stitch 工作流生成或整理的设计与前端相关结果。
- 部署条件：作为技能库接入支持 Agent Skills 的编码环境，并按 Stitch 的当前接入要求配置 MCP。
- 风险：依赖外部 Stitch 服务和工具权限；生成结果需进行代码质量、许可和安全审查。
- 保留理由：该库绑定具体的 Google Stitch 设计工具链，能支持研发中的界面原型和前端实现，非通用 agent 编排。

### jlcodes99/cockpit-tools
<!-- github-record:{"week":"2026-W03","repository":"jlcodes99/cockpit-tools","stars":12064,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/jlcodes99/cockpit-tools
- 采集时可见 Star：12064
- 项目属性：AI IDE 账号与配额管理工具
- 周次依据：候选清单仅标注为 2026-W03（legacy-table）；当前公开仓库描述只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：管理多个 AI IDE 的账号切换、配额监控和实例运行。
- 适用工作流：开发者在本机登记支持的 IDE 账号，工具展示配额并执行切换或实例管理操作。
- 输入：本地 AI IDE 安装、账号信息和运行状态。
- 输出：账号切换、配额状态与 IDE 实例控制结果。
- 部署条件：Rust 桌面/本地工具，需依照当前仓库说明安装并授予必要的本机访问权限。
- 风险：涉及账号凭据、服务条款和多实例自动化；应隔离凭据、最小授权并核验合规性。
- 保留理由：当前仓库描述对应具体的 AI IDE 开发环境运维需求，可在严格凭据和合规控制下评估。

### owu/wsl-dashboard
<!-- github-record:{"week":"2026-W03","repository":"owu/wsl-dashboard","stars":2827,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/owu/wsl-dashboard
- 采集时可见 Star：2827
- 项目属性：WSL 开发环境仪表板
- 周次依据：候选清单仅标注为 2026-W03（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：为 Windows 上的 WSL 环境提供可视化状态与操作入口。
- 适用工作流：开发者查看 WSL 发行版和运行状态，并从仪表板执行相应环境管理操作。
- 输入：本机 WSL 发行版、系统状态和用户操作。
- 输出：WSL 环境状态视图与管理操作结果。
- 部署条件：本地桌面/开发环境工具，需按当前 README 的安装说明部署并验证 Windows/WSL 兼容性。
- 风险：可能要求系统级访问或调用 WSL 命令；应先在非生产开发环境测试。
- 保留理由：当前 README 明确定位为 WSL Dashboard，直接服务 Windows 本地开发环境管理。

### trailofbits/skills
<!-- github-record:{"week":"2026-W03","repository":"trailofbits/skills","stars":5856,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/trailofbits/skills
- 采集时可见 Star：5856
- 项目属性：安全研发技能市场
- 周次依据：候选清单仅标注为 2026-W03（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：提供面向 AI 辅助安全分析、测试和开发工作流的 Trail of Bits 技能市场。
- 适用工作流：在兼容的编码环境中加载该市场，并按任务调用安全分析或测试技能。
- 输入：安全研发任务、受控的代码/配置上下文和技能参数。
- 输出：安全分析、测试或开发辅助结果。
- 部署条件：通过兼容的技能市场机制加载；部署前需审阅每项技能的来源、权限和依赖。
- 风险：安全技能可能读取源码、执行命令或产生高影响操作；必须最小授权、隔离测试并审查提示注入风险。
- 保留理由：当前 README 明确限定其安全分析、测试和开发用途，适合具体安全研发工作流，而非泛化 agent。

### vercel-labs/skills
<!-- github-record:{"week":"2026-W03","repository":"vercel-labs/skills","stars":23475,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/vercel-labs/skills
- 采集时可见 Star：23475
- 项目属性：开放 Agent Skills 生态 CLI
- 周次依据：候选清单仅标注为 2026-W03（legacy-table）；当前公开 README 只用于判断功能，未验证该周历史状态。
- 来源等级：C
- 核心功能：提供开放 Agent Skills 生态的命令行管理能力。
- 适用工作流：研发者通过 CLI 查找、安装或管理面向编码环境的技能。
- 输入：技能标识、项目上下文和 CLI 配置。
- 输出：本地可用的技能配置或管理结果。
- 部署条件：作为 Node.js CLI 按当前仓库说明安装；在受管工作区内固定版本并验证行为。
- 风险：技能安装可引入第三方指令和依赖；需审查来源、版本、权限以及与原生能力的冲突。
- 保留理由：当前 README 将其定位为技能生态 CLI，是可具体部署和评估的研发工具，而非单一泛 agent。

## 2026-W02

- 原始候选：30
- 保留：19
- 排除：11
- 候选不足：保留 19 条，不降低 Star 门槛补足。

### 1jehuang/jcode
<!-- github-record:{"week":"2026-W02","repository":"1jehuang/jcode","stars":7737,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/1jehuang/jcode
- 采集时可见 Star：7737
- 项目属性：AI 编程 Agent 运行框架
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：提供面向多会话开发任务的 AI 编程 Agent 运行与定制能力。
- 适用工作流：用于代码库理解、连续开发任务和本地研发自动化。
- 输入：代码仓库、开发任务、模型服务配置和本地工具权限。
- 输出：代码改动、命令执行结果及会话任务记录。
- 部署条件：需按当前仓库文档安装指定运行时，并配置模型服务和受控的本地工程访问。
- 风险：Agent 可读取或修改代码并执行命令；存在模型凭据、供应链和误操作风险。
- 保留理由：明确服务于软件研发中的多会话 AI 编程工作流。

### 1rgs/nanocode
<!-- github-record:{"week":"2026-W02","repository":"1rgs/nanocode","stars":2441,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/1rgs/nanocode
- 采集时可见 Star：2441
- 项目属性：轻量终端 AI 编程工具
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：以单文件、低依赖实现提供类似 Claude Code 的终端代码协作能力。
- 适用工作流：用于受限环境中的代码修改、命令辅助和 AI 编程工具原型研究。
- 输入：源代码目录、开发任务、兼容的模型配置和终端环境。
- 输出：代码修改建议、文件改动和命令执行结果。
- 部署条件：需要 Python 运行环境及模型访问配置；具体依赖和权限以当前 README 为准。
- 风险：可访问本地文件和执行命令，且模型调用会带来凭据、成本和误改风险。
- 保留理由：具有明确的终端软件研发用途，并可用于轻量化 AI 编程工作流评估。

### apify/agent-skills
<!-- github-record:{"week":"2026-W02","repository":"apify/agent-skills","stars":2176,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/apify/agent-skills
- 采集时可见 Star：2176
- 项目属性：Web 抓取与自动化 Agent Skills
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：提供用于网页抓取和自动化操作的可复用技能。
- 适用工作流：为研发中的公开资料采集、网页信息核验和自动化数据准备提供技能组件。
- 输入：目标网页、抓取或自动化任务，以及兼容的 AI 编程 Agent 环境。
- 输出：提取的网页数据、自动化操作结果和结构化任务产物。
- 部署条件：需按仓库的技能安装方式接入兼容宿主，并审查网页访问权限和外部服务配置。
- 风险：网页内容可能包含提示注入或不可信数据；自动化访问还受站点条款、隐私和速率限制约束。
- 保留理由：功能边界明确为网页自动化，能直接辅助资料调研和研发数据工作流。

### axtonliu/axton-obsidian-visual-skills
<!-- github-record:{"week":"2026-W02","repository":"axtonliu/axton-obsidian-visual-skills","stars":3064,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/axtonliu/axton-obsidian-visual-skills
- 采集时可见 Star：3064
- 项目属性：工程知识可视化 Skills 包
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：从文本生成 Obsidian Canvas、Excalidraw 和 Mermaid 图表。
- 适用工作流：将需求、架构、接口和工程笔记转化为可维护的设计图与文档。
- 输入：工程文本、结构化说明和兼容的 Claude Code 或 Obsidian 工作区。
- 输出：Canvas、Excalidraw 或 Mermaid 可视化文件与图表定义。
- 部署条件：需按当前仓库文档安装技能，并准备兼容宿主和 Obsidian 可读取的工作区。
- 风险：自动生成的图可能误述接口或依赖关系，工程结论仍需人工复核；第三方技能指令也需审查。
- 保留理由：直接支持工程文档处理和研发设计沟通，并非纯视觉展示。

### Dammyjay93/interface-design
<!-- github-record:{"week":"2026-W02","repository":"Dammyjay93/interface-design","stars":5125,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Dammyjay93/interface-design
- 采集时可见 Star：5125
- 项目属性：AI 辅助界面设计技能
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：为编码 Agent 保存和复用界面间距、颜色与层级等设计决策，减少跨会话漂移。
- 适用工作流：用于研发项目的前端界面实现、设计约束沉淀和迭代一致性控制。
- 输入：现有代码库、界面需求、设计约束和兼容的编码 Agent。
- 输出：可复用的界面设计规则、项目内记忆文件和实现建议。
- 部署条件：需按仓库安装说明接入宿主编码 Agent，并允许其在项目中读取或写入设计规则文件。
- 风险：自动化界面决策可能与产品规范不一致；第三方技能可读写项目文件，需在受控仓库中审查。
- 保留理由：当前 README 明确面向编码 Agent 的项目级 UI 研发约束管理。

### decolua/9router
<!-- github-record:{"week":"2026-W02","repository":"decolua/9router","stars":18424,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/decolua/9router
- 采集时可见 Star：18424
- 项目属性：AI 模型路由与用量优化服务
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：提供 AI 服务路由和 Token 节省能力。
- 适用工作流：为多模型研发工具接入、成本控制和请求路由策略提供基础服务。
- 输入：模型请求、上游服务配置、路由策略和可选访问凭据。
- 输出：路由后的模型响应、请求统计和节省信息。
- 部署条件：需依据当前仓库文档部署服务并配置上游模型端点；凭据应通过受控环境变量或密钥管理提供。
- 风险：代理层可接触模型请求和凭据，存在数据泄露、上游兼容性、计费和服务中断风险。
- 保留理由：属于具体的 AI 工程基础设施，可用于研发模型服务的路由与成本管理。

### Dimillian/CodexMonitor
<!-- github-record:{"week":"2026-W02","repository":"Dimillian/CodexMonitor","stars":4080,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Dimillian/CodexMonitor
- 采集时可见 Star：4080
- 项目属性：Codex 多工作区编排与监控桌面应用
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：通过 Codex app-server 协议管理本地工作区中的多个 Codex Agent 会话。
- 适用工作流：用于并行研发任务的项目切换、会话观察和操作集中管理。
- 输入：本地工作区、Codex app-server 连接和用户发起的任务。
- 输出：Agent 会话视图、项目状态和任务操作结果。
- 部署条件：需要按当前 README 构建或安装 Tauri 应用，并连接可用的 Codex app-server 和本地工作区。
- 风险：应用可访问本地工程与 Agent 会话；多任务编排会放大误操作、敏感上下文暴露和资源消耗风险。
- 保留理由：面向 Codex 驱动的软件研发多工作区管理，具备具体工程工作流。

### headroomlabs-ai/headroom
<!-- github-record:{"week":"2026-W02","repository":"headroomlabs-ai/headroom","stars":50282,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/headroomlabs-ai/headroom
- 采集时可见 Star：50282
- 项目属性：AI 上下文压缩库、代理与 MCP 工具
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：在内容到达 LLM 前压缩工具输出、日志、检索片段、文件和会话历史，以降低上下文消耗。
- 适用工作流：用于 AI 编程 Agent 的长任务上下文管理、日志处理和模型成本控制。
- 输入：Agent 的工具输出、文件、日志、检索内容和会话上下文。
- 输出：可恢复或压缩后的上下文内容及相应的服务接口。
- 部署条件：可按当前文档以库、代理或 MCP 方式安装；接入前需核验运行时、数据边界和宿主兼容性。
- 风险：压缩可能丢失关键工程上下文并影响决策；中间层还可能处理敏感代码、日志或模型请求。
- 保留理由：提供可验证的上下文处理基础能力，直接服务于 AI 辅助研发的成本与上下文管理。

### nicobailon/pi-subagents
<!-- github-record:{"week":"2026-W02","repository":"nicobailon/pi-subagents","stars":2314,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/nicobailon/pi-subagents
- 采集时可见 Star：2314
- 项目属性：Pi 编码 Agent 子任务插件
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：让 Pi 将代码审查、调研、实现和审计等工作委派给专门的子 Agent。
- 适用工作流：将研发任务分解为代码审查、实现和并行核验等可追踪子任务。
- 输入：代码任务、项目上下文、Pi 环境和模型服务配置。
- 输出：子 Agent 的任务结果、代码改动、审查意见和后台作业记录。
- 部署条件：需在 Pi 宿主中按当前 README 安装插件，并配置模型访问与项目目录权限。
- 风险：并行子 Agent 可同时读取或修改工程；会增加模型成本、提示注入、误改和任务失控风险。
- 保留理由：README 明确列出代码审查、实现和审计等具体研发用途，不属于无边界的通用 Agent。

### ophub/fnnas
<!-- github-record:{"week":"2026-W02","repository":"ophub/fnnas","stars":3122,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/ophub/fnnas
- 采集时可见 Star：3122
- 项目属性：ARM64 NAS 固件与设备系统项目
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：为 Amlogic、Rockchip 和 Allwinner 等 ARM64 设备提供基于 Linux 的 NAS 系统适配与固件。
- 适用工作流：用于 ARM64 设备系统适配、存储服务原型和嵌入式平台部署参考。
- 输入：受支持的 ARM64 设备、固件镜像、存储介质和网络配置。
- 输出：可启动的 NAS 系统、设备存储服务和升级后的内核环境。
- 部署条件：需要核验目标 SoC 与设备兼容性，并按仓库说明写入 eMMC 或其他启动介质。
- 风险：刷写或内核更新可能导致设备无法启动、数据丢失或网络暴露；应先备份并在可恢复硬件上验证。
- 保留理由：公开 README 明确面向 ARM64 SoC 和设备系统，直接关联嵌入式平台研发。

### snarktank/ralph
<!-- github-record:{"week":"2026-W02","repository":"snarktank/ralph","stars":20594,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/snarktank/ralph
- 采集时可见 Star：20594
- 项目属性：AI 编程任务迭代执行框架
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：反复运行 AI 编程工具，以 PRD 条目和 Git 历史维持任务进度。
- 适用工作流：用于将代码需求拆分为可连续执行、复盘和验收的 AI 辅助研发循环。
- 输入：代码仓库、PRD 任务项、AI 编程工具配置和 Git 历史。
- 输出：迭代产生的代码改动、进度记录和任务完成状态。
- 部署条件：需要安装 README 指定的兼容 AI 编程工具并完成认证，且应在隔离工作树中运行。
- 风险：连续自动执行可放大错误修改、成本和本地命令风险；PRD 或仓库上下文中的不可信指令也需隔离。
- 保留理由：具备明确的代码任务执行与 Git 过程追踪边界，直接对应软件研发自动化。

### Soju06/codex-lb
<!-- github-record:{"week":"2026-W02","repository":"Soju06/codex-lb","stars":2032,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Soju06/codex-lb
- 采集时可见 Star：2032
- 项目属性：Codex 兼容请求代理与用量监控服务
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：为兼容客户端提供账户池负载均衡、请求代理、用量跟踪和仪表板。
- 适用工作流：用于研究多客户端接入、请求代理和 AI 编程服务的用量观测。
- 输入：兼容客户端请求、账户授权信息、路由配置和用量策略。
- 输出：代理后的接口响应、用量统计、负载状态和管理界面。
- 部署条件：需按当前 README 部署服务并安全保存授权信息；接入前还需核验服务条款与账户使用限制。
- 风险：服务会处理授权数据和请求内容，且账户池化可能违反服务条款；存在凭据泄露、封禁、计费和代理安全风险。
- 保留理由：提供面向 Codex 兼容客户端的具体服务代理与用量观测能力，适用于受控的研发工具基础设施评估。

### teng-lin/notebooklm-py
<!-- github-record:{"week":"2026-W02","repository":"teng-lin/notebooklm-py","stars":16822,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/teng-lin/notebooklm-py
- 采集时可见 Star：16822
- 项目属性：NotebookLM 非官方 Python API 与 CLI
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：通过 Python、CLI 和 Agent 提供对 NotebookLM 功能的程序化访问。
- 适用工作流：用于工程资料整理、文档问答、研究笔记自动化和知识检索流程。
- 输入：NotebookLM 资料、文档内容、Python 或 CLI 调用以及必要的账户访问。
- 输出：NotebookLM 任务结果、文档分析结果和可被 Agent 消费的接口响应。
- 部署条件：需安装当前发布的 Python 包或 CLI，并按实际版本完成账户访问配置。
- 风险：非官方接口可能随服务变更失效或违反服务条款；上传资料还涉及隐私、访问控制和数据留存风险。
- 保留理由：明确支持工程文档与知识处理的程序化自动化，和研发资料工作流直接相关。

### vercel-labs/agent-browser
<!-- github-record:{"week":"2026-W02","repository":"vercel-labs/agent-browser","stars":37101,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/vercel-labs/agent-browser
- 采集时可见 Star：37101
- 项目属性：面向 AI Agent 的浏览器自动化 CLI
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：提供原生 Rust CLI 形式的浏览器自动化能力。
- 适用工作流：用于网页应用回归核验、公开文档检索和研发流程中的受控网页操作。
- 输入：浏览器自动化命令、目标网页、选择器和可选认证会话。
- 输出：页面交互结果、提取内容、截图或自动化执行状态。
- 部署条件：需按 README 安装 CLI 及其浏览器依赖；认证信息应由受控环境提供。
- 风险：自动化会访问外部网页，可能遇到提示注入、隐私泄露、站点条款和误提交表单等风险。
- 保留理由：浏览器自动化是可复用的软件研发与资料核验能力，功能边界明确。

### vercel-labs/opensrc
<!-- github-record:{"week":"2026-W02","repository":"vercel-labs/opensrc","stars":2626,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/vercel-labs/opensrc
- 采集时可见 Star：2626
- 项目属性：开源依赖源码访问 CLI
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：让编码 Agent 定位并读取任意软件包的源码。
- 适用工作流：用于依赖行为排查、接口实现核验和代码审查时的第三方源码追踪。
- 输入：软件包名称、源码查询模式和本地命令环境。
- 输出：可供检索的依赖源码路径和匹配结果。
- 部署条件：需要安装当前 npm CLI，并准备其支持的软件包解析与本地检索工具。
- 风险：下载或解析第三方包会引入供应链、磁盘占用和不可信源码内容风险；结果仍需按版本复核。
- 保留理由：直接改善软件研发中的依赖源码检查与问题定位工作流。

### volcengine/OpenViking
<!-- github-record:{"week":"2026-W02","repository":"volcengine/OpenViking","stars":26033,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/volcengine/OpenViking
- 采集时可见 Star：26033
- 项目属性：AI Agent 上下文与记忆管理平台
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：管理和压缩会话内容、资源引用、工具调用、长期记忆及本地技能文件。
- 适用工作流：用于长周期 AI 研发任务的上下文检索、记忆管理和本地技能同步。
- 输入：会话内容、文件或资源引用、工具调用记录、技能文件和知识库数据。
- 输出：可检索的上下文、长期记忆、压缩结果和本地管理界面。
- 部署条件：可按当前 README 通过 Python 包或 CLI 安装；接入本地文件与会话前需核验数据范围和版本兼容性。
- 风险：平台可能集中保存代码、会话和规则文件；存在敏感数据留存、上下文错误关联和外部服务暴露风险。
- 保留理由：具备明确的 AI 工程上下文管理功能，可用于持续研发任务，不是仅提供泛化 Agent 对话。

### Yeachan-Heo/oh-my-claudecode
<!-- github-record:{"week":"2026-W02","repository":"Yeachan-Heo/oh-my-claudecode","stars":36940,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Yeachan-Heo/oh-my-claudecode
- 采集时可见 Star：36940
- 项目属性：Claude Code 多 Agent 编排工具
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：在 Claude Code 中提供多 Agent 协作与预设工作流。
- 适用工作流：用于代码实现、审查、测试和任务拆分等 AI 辅助软件研发流程。
- 输入：代码仓库、开发任务、Claude Code 环境和模型访问配置。
- 输出：多 Agent 的代码改动、任务结果和工作流执行记录。
- 部署条件：需按当前文档安装到 Claude Code，并审查其技能、Hook、模型配置及本地目录权限。
- 风险：多 Agent 协作会放大代码误改、命令执行、提示注入、模型成本和凭据风险。
- 保留理由：README 明确绑定 Claude Code 的多 Agent 研发工作流，具有具体的软件工程用途。

### yifanfeng97/Hyper-Extract
<!-- github-record:{"week":"2026-W02","repository":"yifanfeng97/Hyper-Extract","stars":2199,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/yifanfeng97/Hyper-Extract
- 采集时可见 Star：2199
- 项目属性：智能知识提取 CLI
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：提供智能知识提取命令行工具。
- 适用工作流：用于从工程资料、技术文档或研究材料中提取可复用知识并辅助资料整理。
- 输入：待处理的文档或知识材料，以及 CLI 指定的提取任务。
- 输出：抽取后的结构化知识、文本结果或可供后续处理的文件。
- 部署条件：需按当前 README 安装 Python 包或 CLI，并在实际部署时核验支持的文件格式和模型依赖。
- 风险：提取结果可能遗漏或误解技术事实；输入资料的上传、模型调用和第三方依赖需按数据敏感性评估。
- 保留理由：公开 README 将其定位为知识提取 CLI，直接对应工程文档处理工作流。

### zenc-lang/zenc
<!-- github-record:{"week":"2026-W02","repository":"zenc-lang/zenc","stars":4300,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/zenc-lang/zenc
- 采集时可见 Star：4300
- 项目属性：现代系统编程语言
- 周次依据：输入标注为 2026-W02；周归属来自近似候选池，不能视为当周精确 Star 排名。
- 来源等级：C
- 核心功能：将 Zen C 编译为可读的 GNU C/C11，并提供类型推断、泛型、异步和 RAII 等系统编程能力。
- 适用工作流：用于系统软件、嵌入式相关原型和 C ABI 兼容模块的语言与工具链评估。
- 输入：Zen C 源文件、构建配置和目标平台工具链。
- 输出：人类可读的 C/C11 源码及相应编译产物。
- 部署条件：需按当前 README 安装编译器和目标平台 C 工具链，并验证代码生成与交叉编译兼容性。
- 风险：语言和工具链成熟度、调试支持及生态兼容性需实际验证；生成代码仍可能引入内存和并发缺陷。
- 保留理由：README 明确其系统编程与 C ABI 兼容定位，和嵌入式及底层软件研发直接相关。

## 2026-W01

- 原始候选：30
- 保留：10
- 排除：20
- 候选不足：保留 10 条，不降低 Star 门槛补足。

### AgentAlphaAGI/Idea2Paper
<!-- github-record:{"week":"2026-W01","repository":"AgentAlphaAGI/Idea2Paper","stars":1352,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/AgentAlphaAGI/Idea2Paper
- 采集时可见 Star：1352
- 项目属性：科研写作与论文生成工作流
- 周次依据：候选清单标注为 2026-W01；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：将研究想法组织为研究提案和论文产物。
- 适用工作流：研究想法或故事输入后，经提案/论文生成流程形成可编辑的科研写作结果。
- 输入：研究想法、课题背景及写作约束。
- 输出：研究提案、论文草稿及相关写作材料。
- 部署条件：当前 README 提供本地 Web UI 与项目安装说明。
- 风险：生成内容需由研究人员核验事实、引用、方法和署名合规性。
- 保留理由：面向科研选题到论文产出的明确工作流，研发关联边界具体。

### benchflow-ai/skillsbench
<!-- github-record:{"week":"2026-W01","repository":"benchflow-ai/skillsbench","stars":1387,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/benchflow-ai/skillsbench
- 采集时可见 Star：1387
- 项目属性：AI 技能调用评测基准
- 周次依据：候选清单标注为 2026-W01；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：评估 AI Agent 使用模块化技能的效果。
- 适用工作流：定义评测任务和技能条件，运行受测 Agent，并汇总其任务完成与技能使用表现。
- 输入：评测任务、技能定义及受测 Agent 配置。
- 输出：技能使用效果与 Agent 表现的基准评测结果。
- 部署条件：当前 README 提供代码仓库、数据集和关联 SDK 入口。
- 风险：基准覆盖范围、任务污染和评测配置会影响结论可比性。
- 保留理由：虽涉及 Agent，但核心是边界明确的研发评测基准，而非泛用 Agent 产品。

### entireio/cli
<!-- github-record:{"week":"2026-W01","repository":"entireio/cli","stars":4551,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/entireio/cli
- 采集时可见 Star：4551
- 项目属性：Git 与 AI 编码会话可追溯工具
- 周次依据：候选清单标注为 2026-W01；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：将 AI 编码会话与 Git 提交关联并建立可检索记录。
- 适用工作流：在 Git 工作流中捕获会话、关联提交与受影响文件，再提供检索和回退能力。
- 输入：本地 Git 仓库、AI 编码会话及提交记录。
- 输出：与提交关联的会话索引、变更原因记录和检查点。
- 部署条件：作为命令行工具接入本地 Git 工作流。
- 风险：会话可能包含源代码或提示内容，需评估存储、访问控制和数据保留策略。
- 保留理由：功能直接服务于软件研发过程的可追溯性和变更恢复。

### EtienneLescot/n8n-as-code
<!-- github-record:{"week":"2026-W01","repository":"EtienneLescot/n8n-as-code","stars":1398,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/EtienneLescot/n8n-as-code
- 采集时可见 Star：1398
- 项目属性：n8n 工作流开发与 GitOps 工具链
- 周次依据：候选清单标注为 2026-W01；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：在编辑器中构建、编辑、部署和调试 n8n 工作流。
- 适用工作流：读取 n8n 上下文与节点模式，在编辑器编写 TypeScript 工作流，并同步或部署至 n8n 环境。
- 输入：n8n 环境、节点模式、工作流定义和编辑器操作。
- 输出：可版本控制的工作流代码、同步结果与部署后的 n8n 流程。
- 部署条件：当前 README 提供 VS Code/Cursor Agent、n8n 环境和 GitOps 集成入口。
- 风险：工作流部署可触发外部系统操作，需隔离凭据、审批生产变更并核验环境目标。
- 保留理由：具备明确的工作流开发、部署和运维边界。

### huseyinbabal/taws
<!-- github-record:{"week":"2026-W01","repository":"huseyinbabal/taws","stars":2239,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/huseyinbabal/taws
- 采集时可见 Star：2239
- 项目属性：AWS 资源终端运维工具
- 周次依据：候选清单标注为 2026-W01；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：在终端界面中浏览、观察和管理 AWS 资源。
- 适用工作流：选择 AWS 配置与区域，查看资源状态，并在终端界面执行资源管理操作。
- 输入：AWS 凭据配置、区域选择和资源操作请求。
- 输出：资源视图、状态信息及相应的管理操作结果。
- 部署条件：本地终端 UI，连接用户配置的 AWS 账户。
- 风险：具备资源管理能力，错误账户、区域或权限范围可能造成生产资源变更。
- 保留理由：面向云基础设施研发运维，资源对象与操作边界明确。

### jarrodwatts/claude-hud
<!-- github-record:{"week":"2026-W01","repository":"jarrodwatts/claude-hud","stars":25738,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/jarrodwatts/claude-hud
- 采集时可见 Star：25738
- 项目属性：AI 编码会话可观测性插件
- 周次依据：候选清单标注为 2026-W01；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：在 Claude Code 输入区下方展示上下文、工具、子任务和待办进度。
- 适用工作流：监听编码会话状态，汇总上下文占用、活动工具、运行中任务和待办，再持续呈现。
- 输入：Claude Code 会话事件与状态信息。
- 输出：会话内的状态 HUD。
- 部署条件：通过 Claude Code marketplace 安装的插件。
- 风险：展示内容可能暴露项目活动和上下文元数据，使用时需注意屏幕共享与访问边界。
- 保留理由：功能聚焦研发过程中的编码会话观测，非泛用 Agent 本体。

### pixlcore/xyops
<!-- github-record:{"week":"2026-W01","repository":"pixlcore/xyops","stars":4509,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/pixlcore/xyops
- 采集时可见 Star：4509
- 项目属性：工作流自动化与服务器运维平台
- 周次依据：候选清单标注为 2026-W01；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：组合任务调度、工作流自动化、服务器监控、告警和事件响应。
- 适用工作流：配置作业与自动化流程，采集服务器状态，触发告警并支持事件响应处置。
- 输入：作业计划、自动化定义、服务器指标和告警规则。
- 输出：调度执行结果、监控状态、告警与事件响应记录。
- 部署条件：当前 README 表示可自托管并运行于用户选择的环境。
- 风险：自动化和事件响应可能影响生产系统，需设置权限、变更审批和告警降噪。
- 保留理由：覆盖明确的开发运维工作流和基础设施对象。

### samugit83/redamon
<!-- github-record:{"week":"2026-W01","repository":"samugit83/redamon","stars":2029,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/samugit83/redamon
- 采集时可见 Star：2029
- 项目属性：授权安全测试与修复自动化框架
- 周次依据：候选清单标注为 2026-W01；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：串联侦察、漏洞利用、后渗透、发现分诊、代码修复和 PR 创建的安全测试流程。
- 适用工作流：在授权范围内执行安全测试链路，对发现进行分诊，并将可修复问题转化为代码改动和 PR。
- 输入：明确授权的测试目标、范围和代码仓库访问权限。
- 输出：安全发现、分诊结果、修复改动及拉取请求。
- 部署条件：以安全测试框架接入授权目标与代码仓库。
- 风险：含侦察和利用能力；只能在书面授权、隔离环境和人工关键节点审查下使用。
- 保留理由：虽采用自动化 Agent 技术，但目标与交付物限定为安全测试和工程修复，边界具体。

### Universal-Commerce-Protocol/ucp
<!-- github-record:{"week":"2026-W01","repository":"Universal-Commerce-Protocol/ucp","stars":3156,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Universal-Commerce-Protocol/ucp
- 采集时可见 Star：3156
- 项目属性：通用商业协议规范与文档
- 周次依据：候选清单标注为 2026-W01；仅依据当前公开仓库页的规范与文档定位作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：提供 Universal Commerce Protocol 的规范和实施文档。
- 适用工作流：协议参与方依据规范实现消息、接口或商业流程的互操作，并通过文档进行集成。
- 输入：协议实现需求、商业系统数据及协议版本约束。
- 输出：协议实现、集成文档与互操作行为。
- 部署条件：作为规范仓库供系统实现者集成，不构成独立托管服务。
- 风险：协议版本差异、实现不一致和商业数据处理会带来互操作与合规风险。
- 保留理由：项目对象是边界明确的技术协议规范，而非泛 Agent 应用。

### Weizhena/Deep-Research-skills
<!-- github-record:{"week":"2026-W01","repository":"Weizhena/Deep-Research-skills","stars":1317,"capturedAt":"2026-07-15T00:00:00.000Z","sourceLevel":"C"} -->

- 链接：https://github.com/Weizhena/Deep-Research-skills
- 采集时可见 Star：1317
- 项目属性：受控深度研究工作流技能
- 周次依据：候选清单标注为 2026-W01；仅依据当前公开 README 作 C 级归类，未将当前内容表述为当周历史事实。
- 来源等级：C
- 核心功能：以人类参与控制的两阶段流程支持深度研究。
- 适用工作流：先构建可扩展研究大纲，再执行资料调研与归纳，并保留人工控制环节。
- 输入：研究问题、范围约束、资料来源和人工决策。
- 输出：结构化研究大纲、调研过程信息与研究结论材料。
- 部署条件：作为兼容 Claude Code、OpenCode 和 Codex 的技能安装使用。
- 风险：外部资料可能不可靠或受提示注入影响，结论和引用须由研究人员复核。
- 保留理由：工作流限定于受控深度研究，输入、产出与人工审核边界明确。
