# 工程工作流事件市场

> 覆盖时间：2026-01-01 至 2026-07-18
> 最后核验日期：2026-07-18
> 更新方式：按需手动触发，由受控 JSONL 记录经校验后生成。
> 收录数量：33
> 官方来源规则：每项必须提供经复核的 HTTPS 官方来源。
> 事实与分析：客观事实仅陈述来源支持的信息，技术剖析明确标注分析判断。

## 主题索引

同一事件可进入多个主题，计数为索引引用数，不等于唯一事件数。

- [机器人与 ROS（8）](#topic-robotics-ros)
- [嵌入式与边缘计算（10）](#topic-embedded-edge)
- [EDA、FPGA 与芯片（6）](#topic-eda-fpga-chip)
- [工程文档（1）](#topic-engineering-docs)
- [编码智能体（12）](#topic-coding-agent)
- [扩展安全（8）](#topic-extension-security)

<a id="topic-robotics-ros"></a>
**机器人与 ROS（8）**
- [2026-07-16｜Autoware 1\.8 至 1\.9 平台工作流阶段｜The Autoware Foundation](#event-autoware-18-19-platform-stage)
- [2026-07-10｜Universal Robots ROS 2 Driver 7\.0 增加负载惯量与机器人重力在线配置接口｜Universal Robots](#event-universal-robots-ros2-driver-7-0-2026)
- [2026-07-06｜Isaac ROS 4\.5 简化 NITROS 并扩展机器人操作、遥操作与数据转换工作流｜NVIDIA](#event-isaac-ros-4-5-release-2026)
- [2026-06-22｜MuJoCo 3\.10 引入仿真线程池与统一结构化日志 API｜Google DeepMind](#event-mujoco-3-10-release-2026)
- [2026-06-18｜ROS 2 Jazzy 补丁发布停止提供 Windows 二进制包｜Open Robotics](#event-ros-jazzy-20260618-platform-change)
- [2026-05-22｜ROS 2 Lyrical Luth 发布 Ubuntu 26\.04 与 RHEL 10 二进制发行包｜Open Robotics](#event-ros-lyrical-luth-release-2026)
- [2026-05-13｜PX4 v1\.17 稳定版扩展 ROS 2 控制接口并加入 Gazebo Jetty 支持｜PX4 Autopilot](#event-px4-v1-17-stable-2026)
- [2026-02-12｜Kenning 0\.8\.2 增加 ExecuTorch、tinygrad 与 ROS 2 集成｜Antmicro](#event-antmicro-kenning-082-2026)

<a id="topic-embedded-edge"></a>
**嵌入式与边缘计算（10）**
- [2026-07-02｜LiteRT 2\.1\.6 将 C\+\+ API 改为仅头文件形式并增加 Armv7 预构建包｜Google AI Edge](#event-google-litert-216-2026)
- [2026-06-24｜TensorRT 11\.1 更新 CUDA/Python 基线并增加调优与插件能力｜NVIDIA](#event-nvidia-tensorrt-111-2026)
- [2026-06-15｜ONNX 1\.22\.0 引入新算子并包含破坏性规范变化｜ONNX](#event-onnx-1220-2026)
- [2026-06-09｜Arduino IDE 2\.3\.10 增加干净编译并修复缓存误用｜Arduino](#event-arduino-ide-2310-2026)
- [2026-06-02｜OpenTitan 发布首个 Earl Grey 1\.0\.0 开发包｜lowRISC](#event-lowrisc-opentitan-earlgrey-devbundle-2026)
- [2026-03-30｜FreeRTOS Kernel 11\.3\.0 增加 Cortex-R82 MPU 与 STAR-MC3 端口｜FreeRTOS](#event-freertos-kernel-1130-2026)
- [2026-02-16｜Renode 1\.16\.1 增加 Cortex-M55 与 Arm Helium 仿真支持｜Renode](#event-renode-1161-2026)
- [2026-02-12｜Kenning 0\.8\.2 增加 ExecuTorch、tinygrad 与 ROS 2 集成｜Antmicro](#event-antmicro-kenning-082-2026)
- [2026-02-04｜PlatformIO Core 6\.1\.19 支持 Python 3\.14 并更新测试框架｜PlatformIO](#event-platformio-core-6119-2026)
- [2026-02-02｜Vitis AI 5\.0 明确已验证的 2025\.1 工具链兼容矩阵｜AMD/Xilinx](#event-amd-vitis-ai-50-2026)

<a id="topic-eda-fpga-chip"></a>
**EDA、FPGA 与芯片（6）**
- [2026-07-09｜Yosys 0\.67 提升构建基线并切换 SystemVerilog 展开路径｜YosysHQ](#event-yosys-067-2026)
- [2026-06-02｜OpenTitan 发布首个 Earl Grey 1\.0\.0 开发包｜lowRISC](#event-lowrisc-opentitan-earlgrey-devbundle-2026)
- [2026-06-01｜Chisel 7\.13 增加 ChiselTest 兼容层与调试元数据｜CHIPS Alliance](#event-chipsalliance-chisel-713-2026)
- [2026-03-12｜nextpnr 0\.10 扩展 FPGA 架构支持与路由资源模型｜YosysHQ](#event-yosys-nextpnr-010-2026)
- [2026-02-16｜Renode 1\.16\.1 增加 Cortex-M55 与 Arm Helium 仿真支持｜Renode](#event-renode-1161-2026)
- [2026-02-02｜Vitis AI 5\.0 明确已验证的 2025\.1 工具链兼容矩阵｜AMD/Xilinx](#event-amd-vitis-ai-50-2026)

<a id="topic-engineering-docs"></a>
**工程文档（1）**
- [2026-05-26｜MarkItDown 0\.1\.6 增加扫描 PDF OCR 并修复内存增长｜Microsoft](#event-microsoft-markitdown-016-2026)
本期工程文档方向仅有 1 项通过官方来源与工程价值复核，未用泛文档 AI 新闻补数。

<a id="topic-coding-agent"></a>
**编码智能体（12）**
- [2026-07-18｜Claude Code 2\.1 工作流与权限安全阶段｜Anthropic](#event-anthropic-claude-code-21-workflow-security-stage)
- [2026-07-17｜Cursor in Slack 支持计划反馈与多仓库环境｜Cursor](#event-cursor-slack-multirepo-agents)
- [2026-07-17｜Copilot code review 扩展自定义指令与组织运行器配置｜GitHub](#event-github-copilot-code-review-customization)
- [2026-07-16｜Gemini CLI 工作流与路径安全阶段｜Google](#event-google-gemini-cli-workflow-security-stage)
- [2026-07-16｜Codex 0\.143 至 0\.144\.5 插件与执行安全阶段｜OpenAI](#event-openai-codex-014x-extension-security-stage)
- [2026-07-14｜GitHub Copilot app 上线变更集安全审查｜GitHub](#event-github-copilot-security-review-app)
- [2026-07-10｜Cursor 增加并行 Side Chats 与代理记录搜索｜Cursor](#event-cursor-side-chats-transcript-search)
- [2026-07-10｜GitHub Agentic Autofix 可在代码库内跨文件修复代码扫描告警｜GitHub](#event-github-copilot-agentic-autofix)
- [2026-07-08｜Copilot VS Code 与 CLI 支持企业托管 OpenTelemetry 导出｜GitHub](#event-github-copilot-managed-otel)
- [2026-06-30｜Cursor 扩展配置与团队分发治理阶段｜Cursor](#event-cursor-extension-governance-stage)
- [2026-05-18｜Codex 0\.131 扩展插件工作流、Python SDK 与沙箱边界｜OpenAI](#event-openai-codex-0131-plugin-sdk-security)
- [2026-01-26｜MCP Apps 作为首个官方扩展上线｜Model Context Protocol](#event-mcp-apps-official-extension)

<a id="topic-extension-security"></a>
**扩展安全（8）**
- [2026-07-18｜Claude Code 2\.1 工作流与权限安全阶段｜Anthropic](#event-anthropic-claude-code-21-workflow-security-stage)
- [2026-07-16｜Gemini CLI 工作流与路径安全阶段｜Google](#event-google-gemini-cli-workflow-security-stage)
- [2026-07-16｜Codex 0\.143 至 0\.144\.5 插件与执行安全阶段｜OpenAI](#event-openai-codex-014x-extension-security-stage)
- [2026-07-14｜GitHub Copilot app 上线变更集安全审查｜GitHub](#event-github-copilot-security-review-app)
- [2026-07-10｜GitHub Agentic Autofix 可在代码库内跨文件修复代码扫描告警｜GitHub](#event-github-copilot-agentic-autofix)
- [2026-06-30｜Cursor 扩展配置与团队分发治理阶段｜Cursor](#event-cursor-extension-governance-stage)
- [2026-05-18｜Codex 0\.131 扩展插件工作流、Python SDK 与沙箱边界｜OpenAI](#event-openai-codex-0131-plugin-sdk-security)
- [2026-01-26｜MCP Apps 作为首个官方扩展上线｜Model Context Protocol](#event-mcp-apps-official-extension)

## 组织导航

- [Anthropic](#organization-QW50aHJvcGlj)
- [Cursor](#organization-Q3Vyc29y)
- [Google](#organization-R29vZ2xl)
- [OpenAI](#organization-T3BlbkFJ)
- [The Autoware Foundation](#organization-VGhlIEF1dG93YXJlIEZvdW5kYXRpb24)
- [Universal Robots](#organization-VW5pdmVyc2FsIFJvYm90cw)
- [YosysHQ](#organization-WW9zeXNIUQ)
- [NVIDIA](#organization-TlZJRElB)
- [Google DeepMind](#organization-R29vZ2xlIERlZXBNaW5k)
- [Open Robotics](#organization-T3BlbiBSb2JvdGljcw)
- [ONNX](#organization-T05OWA)
- [lowRISC](#organization-bG93UklTQw)
- [PX4 Autopilot](#organization-UFg0IEF1dG9waWxvdA)
- [AMD/Xilinx](#organization-QU1EL1hpbGlueA)
- [Model Context Protocol](#organization-TW9kZWwgQ29udGV4dCBQcm90b2NvbA)
- [GitHub](#organization-R2l0SHVi)
- [Google AI Edge](#organization-R29vZ2xlIEFJIEVkZ2U)
- [Arduino](#organization-QXJkdWlubw)
- [CHIPS Alliance](#organization-Q0hJUFMgQWxsaWFuY2U)
- [Microsoft](#organization-TWljcm9zb2Z0)
- [FreeRTOS](#organization-RnJlZVJUT1M)
- [Renode](#organization-UmVub2Rl)
- [Antmicro](#organization-QW50bWljcm8)
- [PlatformIO](#organization-UGxhdGZvcm1JTw)

## 组织归档

组织按最高优先级、最新事件日期、组织名排序；组内按日期倒序，再按事件 ID 排序。

<a id="organization-QW50aHJvcGlj"></a>
## Anthropic

<a id="event-anthropic-claude-code-21-workflow-security-stage"></a>
### Claude Code 2\.1 工作流与权限安全阶段
<!-- event-record:{"id":"anthropic-claude-code-21-workflow-security-stage","date":"2026-07-18","organization":"Anthropic"} -->

- 日期：2026-07-18
- 标题：Claude Code 2\.1 工作流与权限安全阶段
- 优先级：high
- 主题：编码智能体、扩展安全
- 协作方：无

#### 客观事实
- 2026-07-18（Claude Code 2\.1\.214）：修复 \`dir/\*\*\` 允许规则错误批准其他同名嵌套目录写入、Windows PowerShell 5\.1 命令权限检查绕过和 Bash 文件描述符重定向解析差异，并让超过一万字符的命令始终提示。
- 2026-06-02（Claude Code 2\.1\.160）：写入 \`\.zshenv\`、\`\.zlogin\`、\`\.bash\_login\` 和 \`~/\.config/git/\` 前新增提示；\`acceptEdits\` 模式写入 \`\.npmrc\`、\`bunfig\.toml\`、\`\.bazelrc\`、pre-commit 和 devcontainer 等可授予代码执行能力的配置时也改为提示。
- 2026-04-25（Claude Code 2\.1\.120）：Windows 缺少 Git for Windows 时可改用 PowerShell 作为命令解释器（shell）工具；新增 \`claude ultrareview\` 子命令，可从 CI 或脚本非交互运行审查并提供 JSON 输出与退出码；子进程设置 \`AI\_AGENT\` 供 \`gh\` 归因。
- 2026-01-07（Claude Code 2\.1\.0）：用户级和项目级技能（skills）修改后可自动热重载；技能的 frontmatter 可用 \`context: fork\` 在分叉子代理上下文运行，并通过 \`agent\` 字段指定代理类型。

#### 技术剖析
2\.1\.0 扩展技能的热更新和隔离执行；2\.1\.120 把审查变成可脚本化 CI 接口并增加 PowerShell 后备路径；2\.1\.160 保护可能形成持久执行链的配置文件；2\.1\.214 修复路径、shell 解析与超长命令的权限绕过。

#### 工作流影响
技能使用者应把 \`\.claude/skills\` 视为可执行配置；2\.1\.120 流水线需固定 JSON 与退出码合同并检查 Bash/PowerShell 差异；2\.1\.160 后高风险配置编辑会新增人工确认；2\.1\.214 后长命令、重定向和目录通配规则可能重新触发提示。

#### 局限与风险
热重载会改变长会话行为，分叉上下文仍可能继承敏感信息；自动审查退出码不代表代码无缺陷；2\.1\.160 的保护名单可能遗漏其他执行配置；2\.1\.214 的静态权限分析仍无法覆盖全部跨平台 shell 语义。

#### 后续关注
锁定技能来源并测试热重载与分叉继承；在 CI 验证 2\.1\.120 的 JSON schema、失败退出码和纯 PowerShell 环境；为 2\.1\.160 的高风险配置补充组织规则；用嵌套目录、重定向、超长命令和 PowerShell 5\.1 用例回归 2\.1\.214。

#### 官方来源
- [Claude Code 2\.1\.0 官方 GitHub release](<https://github.com/anthropics/claude-code/releases/tag/v2.1.0>)（official-release，复核：2026-07-18）
- [Claude Code 2\.1\.120 官方 GitHub release](<https://github.com/anthropics/claude-code/releases/tag/v2.1.120>)（official-release，复核：2026-07-18）
- [Claude Code 2\.1\.160 官方 GitHub release](<https://github.com/anthropics/claude-code/releases/tag/v2.1.160>)（official-release，复核：2026-07-18）
- [Claude Code 2\.1\.214 官方 GitHub release](<https://github.com/anthropics/claude-code/releases/tag/v2.1.214>)（official-release，复核：2026-07-18）
- [Claude Code 官方 CHANGELOG](<https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md>)（official-changelog，复核：2026-07-18）

<a id="organization-Q3Vyc29y"></a>
## Cursor

<a id="event-cursor-slack-multirepo-agents"></a>
### Cursor in Slack 支持计划反馈与多仓库环境
<!-- event-record:{"id":"cursor-slack-multirepo-agents","date":"2026-07-17","organization":"Cursor"} -->

- 日期：2026-07-17
- 标题：Cursor in Slack 支持计划反馈与多仓库环境
- 优先级：medium
- 主题：编码智能体
- 协作方：Slack

#### 客观事实
- Slack 中的 Cursor 在开始前先发布计划，并在执行中更新状态，用户可提前重定向。
- 代理可从 Slack 启动命名的多仓库环境，按请求访问前端、后端和共享代码所在的多个仓库。

#### 技术剖析
聊天入口从单仓库异步触发升级为可干预的多仓库代理执行，环境选择与跨仓库权限成为新的控制边界。

#### 工作流影响
团队可在 Slack 发起跨仓库任务并跟踪计划，但应为命名环境设置最小仓库集合和统一分支策略。

#### 局限与风险
Slack 身份、Cursor 环境和各仓库授权可能不同步；多仓库修改扩大审查范围和原子回滚难度。

#### 后续关注
验证成员身份映射、环境仓库白名单、计划重定向、跨仓库 PR 和部分失败恢复。

#### 官方来源
- [Cursor Slack 改进官方 changelog](<https://cursor.com/changelog/slack-improvements>)（official-changelog，复核：2026-07-18）

<a id="event-cursor-side-chats-transcript-search"></a>
### Cursor 增加并行 Side Chats 与代理记录搜索
<!-- event-record:{"id":"cursor-side-chats-transcript-search","date":"2026-07-10","organization":"Cursor"} -->

- 日期：2026-07-10
- 标题：Cursor 增加并行 Side Chats 与代理记录搜索
- 优先级：medium
- 主题：编码智能体
- 协作方：无

#### 客观事实
- Side Chat 可在主代理会话旁并行运行，并从主会话取得上下文。
- 每个 Side Chat 是可持久跟进的完整代理会话，可通过 \`@\` 提及带回主线程；同时新增代理会话记录（transcript）搜索。

#### 技术剖析
并行旁路会话减少主任务被探索性问题打断，但上下文复制和回流会增加信息来源、权限和状态一致性复杂度。

#### 工作流影响
开发者可并行调查方案并检索历史代理记录，再选择性带回主任务；应明确哪些结论和文件状态已过期。

#### 局限与风险
Side Chat 默认偏读操作但仍是完整代理会话；上下文回流可能携带陈旧假设或敏感信息，搜索也扩大历史数据暴露面。

#### 后续关注
测试并行会话的文件快照、权限继承、上下文引用和记录保留/删除策略。

#### 官方来源
- [Cursor Side Chats 官方 changelog](<https://cursor.com/changelog/side-chat>)（official-changelog，复核：2026-07-18）

<a id="event-cursor-extension-governance-stage"></a>
### Cursor 扩展配置与团队分发治理阶段
<!-- event-record:{"id":"cursor-extension-governance-stage","date":"2026-06-30","organization":"Cursor"} -->

- 日期：2026-06-30
- 标题：Cursor 扩展配置与团队分发治理阶段
- 优先级：high
- 主题：编码智能体、扩展安全
- 协作方：无

#### 客观事实
- 2026-06-30（Cursor Team Marketplace）：管理员可一次配置 Team MCP，并分发到 cloud agents、agents window、IDE 和 CLI；经批准的集成可通过团队插件市场（marketplace）供成员本地安装，无需成员分别配置服务器。
- 2026-06-22（Cursor Customize）：Customize 页面集中管理插件（plugins）、技能（skills）、MCP、子代理（subagents）、规则（rules）、命令（commands）和钩子（hooks）；这些扩展可在用户、团队或工作区层级配置，并支持自定义 MCP 和可复用的 plugin canvas。

#### 技术剖析
6 月 30 日的 Team Marketplace 面向管理员集中批准和跨执行面分发 MCP；6 月 22 日的 Customize 面向多类扩展及其用户、团队、工作区分层配置。前者放大供应链与凭据边界，后者增加配置覆盖和权限理解成本。

#### 工作流影响
Team Marketplace 需要建立 MCP 来源、版本、权限、认证和撤回流程；Customize 需要明确用户、团队与工作区层的优先级、所有者和变更审批，不能把两种入口视为同一治理动作。

#### 局限与风险
集中批准不代表 MCP 服务器持续可信，本地与云端环境的网络和秘密暴露不同；Customize 中不同扩展类型的隔离能力不等价，流行度也不是安全信号。

#### 后续关注
为 Team Marketplace 建立版本锁定、最小权限、分阶段发布和调用审计；为 Customize 维护批准清单，测试层级覆盖、卸载残留、钩子副作用和自定义 MCP 凭据隔离。

#### 官方来源
- [Cursor Team Marketplace 官方 changelog](<https://cursor.com/changelog/team-marketplace-updates>)（official-changelog，复核：2026-07-18）
- [Cursor Customize 官方 changelog](<https://cursor.com/changelog/customize>)（official-changelog，复核：2026-07-18）

<a id="organization-R29vZ2xl"></a>
## Google

<a id="event-google-gemini-cli-workflow-security-stage"></a>
### Gemini CLI 工作流与路径安全阶段
<!-- event-record:{"id":"google-gemini-cli-workflow-security-stage","date":"2026-07-16","organization":"Google"} -->

- 日期：2026-07-16
- 标题：Gemini CLI 工作流与路径安全阶段
- 优先级：high
- 主题：编码智能体、扩展安全
- 协作方：无

#### 客观事实
- 2026-07-16（Gemini CLI 0\.51\.0）：对敏感路径阻止列表（blocklist）实施大小写不敏感匹配，修复 VS Code 人在回路流程与 memory import processor 的符号链接目录逃逸，并将 macOS 沙箱中的 \`~/\.gitconfig\` 设为只读。
- 2026-05-22（Gemini CLI 0\.43\.0）：修复 context manager 的聊天损坏与异步上下文流水线迟滞，收紧私有 Auto Memory patch 允许列表（allowlist），随机化沙箱容器名，并改进非交互模式 \`AgentExecutionStopped\` 的 JSON 输出。
- 2026-03-24（Gemini CLI 0\.35\.0）：新增 \`SandboxManager\` 接口与配置 schema，将子代理上下文传播到策略引擎，并修复 \`argsPattern\` 安全问题、\`BeforeAgent\`/\`AfterAgent\` 代理前后钩子（hooks）不一致和会话恢复后动态工具描述丢失。
- 2026-01-28（Gemini CLI 0\.26\.0）：引入内置 \`skill-creator\` 技能（skill）与 CJS 管理工具，为技能安装增加安全同意提示，并加入代理启停能力及实验性扩展（extension）配置。

#### 技术剖析
0\.26\.0 建立技能创建、安装与启停闭环；0\.35\.0 对齐子代理、钩子、工具描述和沙箱策略的执行生命周期；0\.43\.0 改善长任务上下文、记忆写入与停止事件；0\.51\.0 收紧路径大小写、符号链接和 Git 全局配置边界。

#### 工作流影响
0\.26\.0 的自动化安装需处理同意流程；0\.35\.0 的多代理与恢复会话需重新测试策略继承和钩子顺序；0\.43\.0 使用者应复核 Auto Memory 写入及停止后的副作用；0\.51\.0 会阻止大小写变体、符号链接逃逸和 macOS 沙箱内的全局 Git 配置写入。

#### 局限与风险
安装同意不能验证发布者，0\.26\.0 的 extension 配置仍属实验性；0\.35\.0 不保证不同沙箱后端等价；0\.43\.0 的持久记忆和 JSON 停止事件不保证任务原子回滚；0\.51\.0 的路径防护仍需考虑挂载点、junction 和其他 Git 配置层。

#### 后续关注
为技能包记录来源与哈希；覆盖 0\.35\.0 的权限继承、恢复后工具 schema 和跨平台沙箱；对 0\.43\.0 构造压缩、恢复与记忆 patch 测试；用大小写混合路径、符号链接、junction 和各层 Git 配置回归 0\.51\.0。

#### 官方来源
- [Gemini CLI 0\.26\.0 官方 GitHub release](<https://github.com/google-gemini/gemini-cli/releases/tag/v0.26.0>)（official-release，复核：2026-07-18）
- [Gemini CLI 0\.35\.0 官方 GitHub release](<https://github.com/google-gemini/gemini-cli/releases/tag/v0.35.0>)（official-release，复核：2026-07-18）
- [Gemini CLI 0\.43\.0 官方 GitHub release](<https://github.com/google-gemini/gemini-cli/releases/tag/v0.43.0>)（official-release，复核：2026-07-18）
- [Gemini CLI 0\.51\.0 官方 GitHub release](<https://github.com/google-gemini/gemini-cli/releases/tag/v0.51.0>)（official-release，复核：2026-07-18）

<a id="organization-T3BlbkFJ"></a>
## OpenAI

<a id="event-openai-codex-014x-extension-security-stage"></a>
### Codex 0\.143 至 0\.144\.5 插件与执行安全阶段
<!-- event-record:{"id":"openai-codex-014x-extension-security-stage","date":"2026-07-16","organization":"OpenAI"} -->

- 日期：2026-07-16
- 标题：Codex 0\.143 至 0\.144\.5 插件与执行安全阶段
- 优先级：high
- 主题：编码智能体、扩展安全
- 协作方：无

#### 客观事实
- 2026-07-16（Codex 0\.144\.5）：扩大危险命令检测范围以覆盖更多强制 \`rm\` 形式，并在命令被拒绝时提供更清晰的原因。
- 2026-07-09（Codex 0\.144\.0）：新增 \`writes\` 应用审批模式，只读动作可直接执行而写操作触发提示；MCP 工具可直接交互请求认证，app-server host 可在运行时提供 Codex 认证；Windows 沙箱允许删除可写根目录中的文件并访问受管运行时。
- 2026-07-08（Codex 0\.143\.0）：远程插件改为默认启用，目录展示远程与本地版本并支持 npm 插件市场来源；MCP 工具默认通过工具搜索（tool search）发现，ChatGPT 托管 MCP 服务器可声明会话认证；app-server 增加环境检查、后代线程列表和按轮次分叉历史。

#### 技术剖析
0\.143\.0 将远程插件、延迟工具发现和会话认证带入常规扩展路径；0\.144\.0 进一步按动作副作用区分审批并标准化 MCP 登录；0\.144\.5 则收紧危险 shell 命令检测。三阶段分别改变扩展供应链、权限声明与本地执行边界。

#### 工作流影响
采用 0\.143\.0 后需审计插件市场来源、版本展示和会话认证；升级 0\.144\.0 时需验证工具对读写副作用的声明及 Windows 可写根目录策略；0\.144\.5 可能让强制删除自动化新增审批或被拒绝。

#### 局限与风险
0\.143\.0 的目录信息不能证明插件可信；0\.144\.0 的 \`writes\` 模式依赖工具元数据准确，交互认证还引入凭据生命周期风险；0\.144\.5 的语法检测不能替代文件系统权限、备份和人工确认。

#### 后续关注
固定插件市场来源并测试工具搜索、会话认证和线程分叉的失败路径；对 0\.144\.0 应用动作做只读与写入差分测试；在受控临时目录回归 0\.144\.5 的常见 \`rm\` 变体、拒绝原因和合法清理命令。

#### 官方来源
- [Codex 0\.143\.0 官方 GitHub release](<https://github.com/openai/codex/releases/tag/rust-v0.143.0>)（official-release，复核：2026-07-18）
- [Codex 0\.144\.0 官方 GitHub release](<https://github.com/openai/codex/releases/tag/rust-v0.144.0>)（official-release，复核：2026-07-18）
- [Codex 0\.144\.5 官方 GitHub release](<https://github.com/openai/codex/releases/tag/rust-v0.144.5>)（official-release，复核：2026-07-18）

<a id="event-openai-codex-0131-plugin-sdk-security"></a>
### Codex 0\.131 扩展插件工作流、Python SDK 与沙箱边界
<!-- event-record:{"id":"openai-codex-0131-plugin-sdk-security","date":"2026-05-18","organization":"OpenAI"} -->

- 日期：2026-05-18
- 标题：Codex 0\.131 扩展插件工作流、Python SDK 与沙箱边界
- 优先级：high
- 主题：编码智能体、扩展安全
- 协作方：无

#### 客观事实
- 0\.131\.0 增加插件市场（marketplace）命令行界面、按版本分享插件、默认启用插件钩子（hooks），并统一检索提及项（mentions）。
- 该版本为 \`openai-codex\` Python SDK 提供固定运行时类型、并发轮次（turn）路由和审批模式，并强化 Windows 拒绝读取规则（deny-read）、可写根目录与防火墙策略。

#### 技术剖析
这不是单一界面更新，而是同时改变扩展分发、SDK 编排和本地执行隔离三类能力，进而影响 Codex 嵌入自动化与团队插件治理的方式。

#### 工作流影响
团队可从命令行管理和分享插件，用 Python SDK 编排轮次与审批，并在 Windows 上获得更明确的读写边界；升级前应复测插件钩子、工作树 Git 辅助命令和沙箱策略。

#### 局限与风险
插件钩子与 SDK 扩大可执行扩展面；默认启用不等于扩展可信，Windows 沙箱仍依赖宿主防火墙和权限配置正确。

#### 后续关注
在隔离仓库验证插件安装、钩子信任、Python SDK 并发轮次路由，以及 Windows 拒绝读取规则和可写根目录回归。

#### 官方来源
- [Codex 0\.131\.0 官方 GitHub release](<https://github.com/openai/codex/releases/tag/rust-v0.131.0>)（official-release，复核：2026-07-18）

<a id="organization-VGhlIEF1dG93YXJlIEZvdW5kYXRpb24"></a>
## The Autoware Foundation

<a id="event-autoware-18-19-platform-stage"></a>
### Autoware 1\.8 至 1\.9 平台工作流阶段
<!-- event-record:{"id":"autoware-18-19-platform-stage","date":"2026-07-16","organization":"The Autoware Foundation"} -->

- 日期：2026-07-16
- 标题：Autoware 1\.8 至 1\.9 平台工作流阶段
- 优先级：high
- 主题：机器人与 ROS
- 协作方：无

#### 客观事实
- 2026-07-16（Autoware 1\.9\.0）：增加 NVIDIA Thor（Jetson 与 DRIVE）在 JetPack 7、SBSA CUDA 13 环境下的支持；开发容器迁移到 \`docker-compose\` 并增加 GUI 转发，同时新增 \`version\_lock\` 角色以支持可复现依赖安装。
- 2026-05-04（Autoware 1\.8\.0）：增加 Jazzy ARM Docker 镜像构建、Autoware System Designer、场景仿真演示和用于示例地图及 rosbag 的 \`demo\_artifacts\` 安装角色，并更新扩散规划模型及新增 Dockerfile、HCL bake 配置和 Ansible playbook。

#### 技术剖析
1\.9\.0 以 Thor 平台适配、CUDA 13 环境和依赖锁定为主，影响目标硬件构建与重复验证；1\.8\.0 以 ARM 镜像、系统设计和场景仿真为主，扩展环境准备与验证入口。

#### 工作流影响
面向 Jetson Thor 或 DRIVE Thor 的团队应按 1\.9\.0 路径锁定 JetPack、CUDA、容器和依赖；采用 1\.8\.0 的 ARM 团队可用官方镜像、Ansible 与场景演示建立可重复的开发和仿真环境。

#### 局限与风险
1\.9\.0 的 Thor 支持不代表所有传感器驱动、CUDA 算子和自定义模块均已验证；1\.8\.0 包含组件与模型工件联动，现有容器、数据目录和安装脚本可能需要迁移。

#### 后续关注
先在目标 Thor 硬件回归 1\.9\.0 的驱动、传感器吞吐、规划时延、GUI 转发和冷启动；再用同一地图、rosbag 与场景，在 ARM 和 x86\_64 上比较 1\.8\.0 的镜像构建与系统启动结果。

#### 官方来源
- [Autoware 1\.8\.0 官方 GitHub Release](<https://github.com/autowarefoundation/autoware/releases/tag/1.8.0>)（official-release，复核：2026-07-18）
- [Autoware 1\.9\.0 官方 GitHub Release](<https://github.com/autowarefoundation/autoware/releases/tag/1.9.0>)（official-release，复核：2026-07-18）

<a id="organization-VW5pdmVyc2FsIFJvYm90cw"></a>
## Universal Robots

<a id="event-universal-robots-ros2-driver-7-0-2026"></a>
### Universal Robots ROS 2 Driver 7\.0 增加负载惯量与机器人重力在线配置接口
<!-- event-record:{"id":"universal-robots-ros2-driver-7-0-2026","date":"2026-07-10","organization":"Universal Robots"} -->

- 日期：2026-07-10
- 标题：Universal Robots ROS 2 Driver 7\.0 增加负载惯量与机器人重力在线配置接口
- 优先级：high
- 主题：机器人与 ROS
- 协作方：无

#### 客观事实
- Universal Robots ROS 2 Driver 7\.0\.0 于 2026 年 7 月 10 日发布。
- 该版本允许更新机器人重力，并通过 \`set\_payload\` 服务设置负载惯量矩阵。
- 版本将 URScript 接口迁移到 primary client，并让 GPIO 控制器发布器及状态发布采用满足实时约束、可由实时线程安全调用的实现（real-time safe）。

#### 技术剖析
新接口把重力与负载动力学配置纳入 ROS 2 控制面，同时通信路径和实时发布实现发生变化，会影响操作规划、控制精度和集成测试。

#### 工作流影响
集成方可在任务换载荷或安装姿态变化时通过 ROS 2 更新动力学参数，并需验证 primary client 迁移及实时发布行为。

#### 局限与风险
URSim 的 effort control 仍有限制；动力学参数错误可能造成控制偏差，接口可用不代表无需现场安全校验。

#### 后续关注
针对典型工具和安装姿态验证重力、质量、质心与惯量参数，记录轨迹误差，并回归控制权切换、GPIO 和急停状态传播。

#### 官方来源
- [Universal Robots ROS 2 Driver 7\.0 官方 GitHub Release](<https://github.com/UniversalRobots/Universal_Robots_ROS2_Driver/releases/tag/7.0.0>)（official-release，复核：2026-07-18）

<a id="organization-WW9zeXNIUQ"></a>
## YosysHQ

<a id="event-yosys-067-2026"></a>
### Yosys 0\.67 提升构建基线并切换 SystemVerilog 展开路径
<!-- event-record:{"id":"yosys-067-2026","date":"2026-07-09","organization":"YosysHQ"} -->

- 日期：2026-07-09
- 标题：Yosys 0\.67 提升构建基线并切换 SystemVerilog 展开路径
- 优先级：high
- 主题：EDA、FPGA 与芯片
- 协作方：无

#### 客观事实
- Yosys 0\.67 要求 CMake 3\.28 及以上、Clang 16 或 GCC 13 及以上。
- 该版本的 SystemVerilog 支持改用基于 slang 的 \`sv-elab\` 展开（elaboration）路径，并改善包含 ABC 的 Visual Studio 构建。

#### 技术剖析
构建最低版本和 SystemVerilog 展开实现变化可能改变 CI 镜像、语法覆盖与生成网表。

#### 工作流影响
RTL 团队需更新构建环境，并针对 SystemVerilog 设计重跑解析、综合和等价性验证。

#### 局限与风险
新的展开路径可能与旧前端在边缘语法和诊断上不同，MinGW 仍是 Windows 推荐路径。

#### 后续关注
升级 CI 编译器和 CMake，并比较关键设计的日志、网表、形式等价，以及功耗、性能和面积（PPA）。

#### 官方来源
- [Yosys 0\.67 官方发布页](<https://github.com/YosysHQ/yosys/releases/tag/v0.67>)（official-release，复核：2026-07-18）

<a id="event-yosys-nextpnr-010-2026"></a>
### nextpnr 0\.10 扩展 FPGA 架构支持与路由资源模型
<!-- event-record:{"id":"yosys-nextpnr-010-2026","date":"2026-03-12","organization":"YosysHQ"} -->

- 日期：2026-03-12
- 标题：nextpnr 0\.10 扩展 FPGA 架构支持与路由资源模型
- 优先级：medium
- 主题：EDA、FPGA 与芯片
- 协作方：无

#### 客观事实
- nextpnr 0\.10 增加 resources API 表示互斥路由资源。
- 该版本为 Gowin 增加 GW5AST-138C 和 GW5 DSP 初始支持，并为 Xilinx 增加 Kintex-7 初始支持。

#### 技术剖析
资源模型与新器件后端会改变开源 FPGA 器件覆盖、布局布线能力和约束验证范围。

#### 工作流影响
FPGA 团队可评估更多 Gowin/Xilinx 器件，但需重新验证布局布线（P&amp;R）、时序和 bitstream 流程。

#### 局限与风险
多项器件支持标为初始状态，不能假定覆盖全部资源或生产可靠性。

#### 后续关注
用代表设计运行综合、布局布线、时序分析、硬件启动和接口压力测试。

#### 官方来源
- [nextpnr 0\.10 官方发布页](<https://github.com/YosysHQ/nextpnr/releases/tag/nextpnr-0.10>)（official-release，复核：2026-07-18）

<a id="organization-TlZJRElB"></a>
## NVIDIA

<a id="event-isaac-ros-4-5-release-2026"></a>
### Isaac ROS 4\.5 简化 NITROS 并扩展机器人操作、遥操作与数据转换工作流
<!-- event-record:{"id":"isaac-ros-4-5-release-2026","date":"2026-07-06","organization":"NVIDIA"} -->

- 日期：2026-07-06
- 标题：Isaac ROS 4\.5 简化 NITROS 并扩展机器人操作、遥操作与数据转换工作流
- 优先级：high
- 主题：机器人与 ROS
- 协作方：无

#### 客观事实
- NVIDIA 官方发布说明将 Isaac ROS 4\.5\.0 标注为 2026 年 7 月 6 日发布。
- 该版本停止使用 GXF 实现以降低 NITROS 构建与运行时复杂度，并为 NITROS 消息增加 CUDA streaming 支持。
- 发布增加 Flexiv Rizon 与自有机器人集成指南、Unitree G1 数据记录和 GR00T 部署工作流，以及 MCAP 到 LeRobot 的转换器。

#### 技术剖析
NITROS 底层实现、GPU 消息路径和机器人操作/数据工具链同时调整，会影响包构建、零拷贝数据流、机器人适配和具身数据准备。

#### 工作流影响
Isaac ROS 用户需要迁移 NITROS 构建假设，并可直接采用新的 Flexiv、Unitree G1、遥操作和 LeRobot 数据转换流程。

#### 局限与风险
支持清单针对官方工作流和指定固件；自定义 GXF 扩展、第三方机器人桥接及 CUDA 数据生命周期仍需单独验证。

#### 后续关注
在现有 ROS 2 计算图上比较 4\.4 与 4\.5 的 NITROS 构建和端到端延迟，检查自定义 GXF 依赖，并对目标机器人完成记录、转换、回放和部署闭环测试。

#### 官方来源
- [Isaac ROS 4\.5 官方发布说明](<https://nvidia-isaac-ros.github.io/releases/index.html>)（official-changelog，复核：2026-07-18）
- [Isaac ROS 4\.5 官方 GitHub Release](<https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_common/releases/tag/v4.5-0>)（official-release，复核：2026-07-18）

<a id="event-nvidia-tensorrt-111-2026"></a>
### TensorRT 11\.1 更新 CUDA/Python 基线并增加调优与插件能力
<!-- event-record:{"id":"nvidia-tensorrt-111-2026","date":"2026-06-24","organization":"NVIDIA"} -->

- 日期：2026-06-24
- 标题：TensorRT 11\.1 更新 CUDA/Python 基线并增加调优与插件能力
- 优先级：high
- 主题：嵌入式与边缘计算
- 协作方：无

#### 客观事实
- TensorRT 11\.1 默认 CUDA 版本更新至 13\.3，并增加 Ubuntu 26\.04 容器与 Python 3\.14 支持。
- 该版本为 \`trtexec\` 增加全局性能调优选项，新增 \`cute\_dsl\_plugin\` 样例和 \`topkLastDimPlugin\` 插件。

#### 技术剖析
运行环境基线和引擎调优接口同时变化，会影响构建镜像、插件开发和推理性能回归。

#### 工作流影响
边缘 GPU 团队需重建容器和自有插件，并重新测量 \`trtexec\` 调优策略生成的引擎。

#### 局限与风险
默认 CUDA 提升可能淘汰旧驱动或设备组合；\`topkLastDimPlugin\` 也有算子与精度适用边界。

#### 后续关注
核对驱动兼容矩阵，重建代表模型并比较引擎大小、精度、时延和峰值显存，同时分别验证 \`cute\_dsl\_plugin\` 样例与 \`topkLastDimPlugin\` 插件。

#### 官方来源
- [TensorRT 11\.1 官方发布页](<https://github.com/NVIDIA/TensorRT/releases/tag/v11.1>)（official-release，复核：2026-07-18）

<a id="organization-R29vZ2xlIERlZXBNaW5k"></a>
## Google DeepMind

<a id="event-mujoco-3-10-release-2026"></a>
### MuJoCo 3\.10 引入仿真线程池与统一结构化日志 API
<!-- event-record:{"id":"mujoco-3-10-release-2026","date":"2026-06-22","organization":"Google DeepMind"} -->

- 日期：2026-06-22
- 标题：MuJoCo 3\.10 引入仿真线程池与统一结构化日志 API
- 优先级：high
- 主题：机器人与 ROS
- 协作方：无

#### 客观事实
- MuJoCo 3\.10\.0 于 2026 年 6 月 22 日发布。
- 新增 \`mju\_threadpool\`，可在 \`mjData\` 上创建线程池，并行处理碰撞检测和跨约束岛（island）的约束求解。
- 新增统一结构化日志回调与配置 API，同时移除旧 \`mjthread\.h\` 和旧引擎线程 API。

#### 技术剖析
线程执行模型和日志边界同时变化，既提供新的性能调优入口，也带来明确的 C/C\+\+ API 迁移要求。

#### 工作流影响
仿真、强化学习和机器人验证流水线可显式配置线程池并接入结构化日志，但原先依赖旧线程头文件的原生扩展必须修改和重测。

#### 局限与风险
并行收益取决于模型拓扑和工作负载；旧日志回调虽仍可用但已弃用，未来升级会继续增加迁移压力。

#### 后续关注
使用代表性机器人模型比较不同线程数下的结果可重复性，并以 MuJoCo 3\.9 和 3\.10 单线程为基线比较吞吐与数值偏差；同时清理 \`mjthread\.h\` 依赖并接入新的日志处理器。

#### 官方来源
- [MuJoCo 3\.10 官方 GitHub Release](<https://github.com/google-deepmind/mujoco/releases/tag/3.10.0>)（official-release，复核：2026-07-18）
- [MuJoCo 3\.10 官方 changelog](<https://mujoco.readthedocs.io/en/3.10.0/changelog.html>)（official-changelog，复核：2026-07-18）

<a id="organization-T3BlbiBSb2JvdGljcw"></a>
## Open Robotics

<a id="event-ros-jazzy-20260618-platform-change"></a>
### ROS 2 Jazzy 补丁发布停止提供 Windows 二进制包
<!-- event-record:{"id":"ros-jazzy-20260618-platform-change","date":"2026-06-18","organization":"Open Robotics"} -->

- 日期：2026-06-18
- 标题：ROS 2 Jazzy 补丁发布停止提供 Windows 二进制包
- 优先级：high
- 主题：机器人与 ROS
- 协作方：无

#### 客观事实
- ROS 2 Jazzy 于 2026 年 6 月 18 日发布新的补丁二进制包。
- 官方说明本次补丁不再包含 Windows 二进制包，原因是 Jazzy 支持的 Windows 10 已结束生命周期，并引用 ROS 2 平台 EOL 政策。

#### 技术剖析
这不是普通补丁噪声，而是受支持二进制平台的实际收缩；依赖 Jazzy Windows 工件的构建与部署路径不再能跟随该补丁流。

#### 工作流影响
Windows 上的 Jazzy 项目需要冻结既有工件、转向源码自建或迁移到受支持平台，并调整 CI 与交付矩阵。

#### 局限与风险
官方页面未给出替代 Windows 版本或恢复二进制发布的计划；源码自建也不等同于获得官方平台支持。

#### 后续关注
盘点所有 Jazzy Windows 运行节点和 CI 作业，记录当前二进制版本，并制定迁移到 Linux 或后续受支持 ROS 2 发行版的验证计划。

#### 官方来源
- [ROS 2 Jazzy 2026-06-18 官方 GitHub Release](<https://github.com/ros2/ros2/releases/tag/release-jazzy-20260618>)（official-release，复核：2026-07-18）

<a id="event-ros-lyrical-luth-release-2026"></a>
### ROS 2 Lyrical Luth 发布 Ubuntu 26\.04 与 RHEL 10 二进制发行包
<!-- event-record:{"id":"ros-lyrical-luth-release-2026","date":"2026-05-22","organization":"Open Robotics"} -->

- 日期：2026-05-22
- 标题：ROS 2 Lyrical Luth 发布 Ubuntu 26\.04 与 RHEL 10 二进制发行包
- 优先级：high
- 主题：机器人与 ROS
- 协作方：无

#### 客观事实
- ROS 2 于 2026 年 5 月 22 日发布 Lyrical Luth 的二进制发行包。
- 官方发布页提供面向 Ubuntu 26\.04 的 Debian 包、面向 RHEL 10 的 RPM 包，并链接源码构建说明。

#### 技术剖析
这是新的 ROS 2 发行版和操作系统基线，直接改变二进制部署矩阵、依赖解析与持续集成镜像选择。

#### 工作流影响
机器人项目可开始为 Ubuntu 26\.04 或 RHEL 10 建立 Lyrical 构建、容器、硬件驱动和回归测试流水线，并验证上游包迁移。

#### 局限与风险
新发行版初期的第三方驱动、厂商 SDK 和二进制包覆盖可能落后于核心发行版；迁移前仍需逐包核验兼容性。

#### 后续关注
在目标硬件上建立 Jazzy/Kilted 与 Lyrical 双轨 CI，核验驱动、DDS、仿真器和部署镜像后再切换默认发行版。

#### 官方来源
- [ROS 2 Lyrical Luth 官方 GitHub Release](<https://github.com/ros2/ros2/releases/tag/release-lyrical-20260522>)（official-release，复核：2026-07-18）

<a id="organization-T05OWA"></a>
## ONNX

<a id="event-onnx-1220-2026"></a>
### ONNX 1\.22\.0 引入新算子并包含破坏性规范变化
<!-- event-record:{"id":"onnx-1220-2026","date":"2026-06-15","organization":"ONNX"} -->

- 日期：2026-06-15
- 标题：ONNX 1\.22\.0 引入新算子并包含破坏性规范变化
- 优先级：high
- 主题：嵌入式与边缘计算
- 协作方：无

#### 客观事实
- ONNX 1\.22\.0 的发布说明明确列出 breaking changes and deprecations。
- 该版本新增 LinearAttention-27 和 CausalConvWithState-27，并调整 qk\_matmul\_output\_mode 的取值语义以匹配计算顺序。

#### 技术剖析
模型交换规范和算子集变化会影响导出器、runtime、转换器及模型验证的一致性。

#### 工作流影响
模型流水线需要锁定 opset，并针对新算子和属性语义更新导出、检查和后端兼容测试。

#### 局限与风险
规范发布不代表所有边缘 runtime 已实现相同算子与 opset。

#### 后续关注
建立导出器到目标 runtime 的算子支持矩阵，并对属性变更执行数值回归。

#### 官方来源
- [ONNX 1\.22\.0 官方发布页](<https://github.com/onnx/onnx/releases/tag/v1.22.0>)（official-release，复核：2026-07-18）

<a id="organization-bG93UklTQw"></a>
## lowRISC

<a id="event-lowrisc-opentitan-earlgrey-devbundle-2026"></a>
### OpenTitan 发布首个 Earl Grey 1\.0\.0 开发包
<!-- event-record:{"id":"lowrisc-opentitan-earlgrey-devbundle-2026","date":"2026-06-02","organization":"lowRISC"} -->

- 日期：2026-06-02
- 标题：OpenTitan 发布首个 Earl Grey 1\.0\.0 开发包
- 优先级：high
- 主题：嵌入式与边缘计算、EDA、FPGA 与芯片
- 协作方：无

#### 客观事实
- 这是 Earl Grey 1\.0\.0 的首个 development bundle。
- 开发包包含 FPGA bitstream、Verilated simulation binary、OpenTitanTool、HSMTool、test ROM 和 FPGA ROM extension 二进制。

#### 技术剖析
统一开发包把 FPGA、Verilator 仿真、主机工具和 ROM 产物固定到同一版本，改善芯片验证环境复现。

#### 工作流影响
验证和固件团队可用同一包在仿真与 FPGA 原型间对齐工具和 ROM 版本。

#### 局限与风险
名称明确为 development bundle，不代表量产硅或最终生产软件资格。

#### 后续关注
校验包内版本清单，并在仿真和 FPGA 上运行相同启动、HSM 与 ROM 测试。

#### 官方来源
- [OpenTitan Earl Grey 开发包官方发布页](<https://github.com/lowRISC/opentitan/releases/tag/devbundle-2026-06-02-1>)（official-release，复核：2026-07-18）

<a id="organization-UFg0IEF1dG9waWxvdA"></a>
## PX4 Autopilot

<a id="event-px4-v1-17-stable-2026"></a>
### PX4 v1\.17 稳定版扩展 ROS 2 控制接口并加入 Gazebo Jetty 支持
<!-- event-record:{"id":"px4-v1-17-stable-2026","date":"2026-05-13","organization":"PX4 Autopilot"} -->

- 日期：2026-05-13
- 标题：PX4 v1\.17 稳定版扩展 ROS 2 控制接口并加入 Gazebo Jetty 支持
- 优先级：high
- 主题：机器人与 ROS
- 协作方：无

#### 客观事实
- PX4 v1\.17 于 2026 年 5 月 13 日作为稳定版发布。
- 该版本为固定翼和车辆新增 ROS 2 高层控制接口，实验性的 in-tree Zenoh 中间件推进到 \`rmw\_zenoh\` 兼容，并加入 Gazebo Jetty 与 Ackermann SIH 仿真支持。
- 升级说明要求重新检查遥控通道死区，并使用新的 PWM 中心参数重新校准舵机。

#### 技术剖析
发布同时改变自主控制 API、实验性中间件、仿真后端和飞控升级参数，覆盖从算法联调到实机校准的工程链路。

#### 工作流影响
PX4 用户可通过类型化 ROS 2 接口控制固定翼和车辆，并需更新 Gazebo、实验性 Zenoh、参数迁移和飞行前回归测试。

#### 局限与风险
in-tree Zenoh 和神经网络控制路径仍标为实验性；升级中的遥控死区与舵机中心变化可能引入实机风险，不能只做软件在环验证。

#### 后续关注
在 SITL/HITL 中验证新的 ROS 2 setpoint 类型和 Gazebo Jetty 场景，再按升级指南完成遥控、舵机、导航失效行为与故障保护（failsafe）的实机检查。

#### 官方来源
- [PX4 v1\.17 官方 GitHub Release](<https://github.com/PX4/PX4-Autopilot/releases/tag/v1.17.0>)（official-release，复核：2026-07-18）
- [PX4 v1\.17 官方发布说明](<https://docs.px4.io/main/en/releases/1.17>)（official-docs，复核：2026-07-18）

<a id="organization-QU1EL1hpbGlueA"></a>
## AMD/Xilinx

<a id="event-amd-vitis-ai-50-2026"></a>
### Vitis AI 5\.0 明确已验证的 2025\.1 工具链兼容矩阵
<!-- event-record:{"id":"amd-vitis-ai-50-2026","date":"2026-02-02","organization":"AMD/Xilinx"} -->

- 日期：2026-02-02
- 标题：Vitis AI 5\.0 明确已验证的 2025\.1 工具链兼容矩阵
- 优先级：high
- 主题：嵌入式与边缘计算、EDA、FPGA 与芯片
- 协作方：无

#### 客观事实
- Vitis AI 5\.0 分支的工具与 DPU IP 经官方验证兼容 Vitis、Vivado 和 PetaLinux 2025\.1。
- 发布说明要求旧版用户按各自版本兼容矩阵选择工具链，并移除 Ubuntu 18\.04 容器支持。

#### 技术剖析
该版本把 FPGA DPU、模型工具和板级 Linux 构建绑定到明确工具链组合，直接影响可复现构建。

#### 工作流影响
使用 AMD FPGA 做边缘推理的团队需要统一 Vitis/Vivado/PetaLinux 版本并重建容器与 DPU 产物。

#### 局限与风险
跨版本混用未获验证，旧 Ubuntu 构建环境需要迁移。

#### 后续关注
按目标板运行量化、编译、DPU bitstream 与 PetaLinux 镜像的端到端回归。

#### 官方来源
- [Vitis AI 5\.0 官方发布页](<https://github.com/Xilinx/Vitis-AI/releases/tag/v5.0>)（official-release，复核：2026-07-18）

<a id="organization-TW9kZWwgQ29udGV4dCBQcm90b2NvbA"></a>
## Model Context Protocol

<a id="event-mcp-apps-official-extension"></a>
### MCP Apps 作为首个官方扩展上线
<!-- event-record:{"id":"mcp-apps-official-extension","date":"2026-01-26","organization":"Model Context Protocol"} -->

- 日期：2026-01-26
- 标题：MCP Apps 作为首个官方扩展上线
- 优先级：high
- 主题：编码智能体、扩展安全
- 协作方：无

#### 客观事实
- MCP Apps 已上线为首个官方 MCP extension。
- 工具可返回直接在会话中渲染的交互式 UI 组件，包括表单、仪表盘、可视化和多步骤工作流。

#### 技术剖析
MCP 工具输出从结构化数据扩展为可交互界面，客户端需要处理 UI 资源、消息通道和用户操作带来的新信任边界。

#### 工作流影响
工具开发者可在代理会话内提供交互工作流，客户端和企业部署则需审查资源来源、内容安全策略与 UI 发起的后续调用。

#### 局限与风险
交互 UI 增加钓鱼、点击劫持、数据外传和客户端兼容性风险；官方扩展身份不等于任意 MCP App 安全。

#### 后续关注
在隔离客户端验证资源加载、CSP、消息校验、权限提示、离线失败和不支持扩展时的降级。

#### 官方来源
- [MCP Apps 官方发布文章](<https://blog.modelcontextprotocol.io/posts/2026-01-26-mcp-apps/>)（standards-body，复核：2026-07-18）

<a id="organization-R2l0SHVi"></a>
## GitHub

<a id="event-github-copilot-code-review-customization"></a>
### Copilot code review 扩展自定义指令与组织运行器配置
<!-- event-record:{"id":"github-copilot-code-review-customization","date":"2026-07-17","organization":"GitHub"} -->

- 日期：2026-07-17
- 标题：Copilot code review 扩展自定义指令与组织运行器配置
- 优先级：medium
- 主题：编码智能体
- 协作方：无

#### 客观事实
- Copilot code review 改为从拉取请求的头分支读取 \`copilot-instructions\.md\`、\`\*\.instructions\.md\`、\`AGENTS\.md\` 等自定义指令文件，允许在功能分支合并前测试并验证这些指令。
- 官方更新还增加自定义准备步骤（setup steps）、防火墙支持和组织级独立运行器（runner）配置。

#### 技术剖析
这些变化提高仓库审查规则与组织执行环境的可配置性，并让指令验证范围明确落在拉取请求头分支。

#### 工作流影响
团队可在功能分支验证审查指令，并按组织配置独立运行器、准备步骤和网络边界；相关配置应纳入版本控制与审计。

#### 局限与风险
头分支指令属于待审代码，独立运行器仍可能拥有仓库、网络和凭据权限；AI 审查不能替代强制测试与人工批准。

#### 后续关注
建立固定测试 PR 验证各类指令文件在头分支的生效范围，并审计运行器的准备步骤、权限、网络出口和秘密暴露。

#### 官方来源
- [GitHub Copilot code review 官方 changelog](<https://github.blog/changelog/2026-07-17-copilot-code-review-customization-and-configurability-improvements>)（official-changelog，复核：2026-07-18）

<a id="event-github-copilot-security-review-app"></a>
### GitHub Copilot app 上线变更集安全审查
<!-- event-record:{"id":"github-copilot-security-review-app","date":"2026-07-14","organization":"GitHub"} -->

- 日期：2026-07-14
- 标题：GitHub Copilot app 上线变更集安全审查
- 优先级：medium
- 主题：编码智能体、扩展安全
- 协作方：无

#### 客观事实
- GitHub Copilot app 公共预览 /security-review，可分析当前 workstream 变更。
- 结果包含按严重性和置信度排序的高置信安全发现，并可给出文件位置和修复建议。

#### 技术剖析
安全检查被放入编码代理的在途变更工作流，可更早反馈漏洞，但其输出仍是概率性审查而非确定性门禁。

#### 工作流影响
开发者可在提交前触发安全审查并修复高风险问题，组织可将结果作为 PR 前置证据之一。

#### 局限与风险
公共预览可能变化，且只报告模型识别到的问题；置信度评分不能覆盖业务逻辑、运行时环境和供应链全貌。

#### 后续关注
与 CodeQL、依赖扫描和人工 threat review 做同批样本对照，记录漏报与误报。

#### 官方来源
- [GitHub Copilot app 安全审查官方 changelog](<https://github.blog/changelog/2026-07-14-security-reviews-now-available-in-the-github-copilot-app>)（official-changelog，复核：2026-07-18）

<a id="event-github-copilot-agentic-autofix"></a>
### GitHub Agentic Autofix 可在代码库内跨文件修复代码扫描告警
<!-- event-record:{"id":"github-copilot-agentic-autofix","date":"2026-07-10","organization":"GitHub"} -->

- 日期：2026-07-10
- 标题：GitHub Agentic Autofix 可在代码库内跨文件修复代码扫描告警
- 优先级：medium
- 主题：编码智能体、扩展安全
- 协作方：无

#### 客观事实
- Agentic Autofix 对 CodeQL 和第三方代码扫描告警进入公共预览。
- 代理探索相关文件、提出修复、重新运行原扫描确认告警关闭，然后创建 PR 供审查。

#### 技术剖析
闭环从建议代码推进到跨文件修改和原扫描复验，减少人工修复成本，也把扫描配置与代理修改权限变成关键控制点。

#### 工作流影响
安全团队可把告警分配给 Copilot cloud agent 生成带验证的 PR，但仍应保留分支保护、测试和人工合并。

#### 局限与风险
需要 GitHub Code Security 或 Advanced Security、Copilot 许可和 cloud agent；关闭原告警不代表没有回归或旁路。

#### 后续关注
从低风险告警试点，比较修复正确率、扫描复验、测试回归和 PR 权限审计。

#### 官方来源
- [Agentic Autofix 公共预览官方 changelog](<https://github.blog/changelog/2026-07-10-agentic-autofix-for-code-scanning-alerts-in-public-preview>)（official-changelog，复核：2026-07-18）

<a id="event-github-copilot-managed-otel"></a>
### Copilot VS Code 与 CLI 支持企业托管 OpenTelemetry 导出
<!-- event-record:{"id":"github-copilot-managed-otel","date":"2026-07-08","organization":"GitHub"} -->

- 日期：2026-07-08
- 标题：Copilot VS Code 与 CLI 支持企业托管 OpenTelemetry 导出
- 优先级：medium
- 主题：编码智能体
- 协作方：OpenTelemetry

#### 客观事实
- 企业可通过托管设置强制 Copilot 将 OpenTelemetry 数据发送到批准的 collector。
- 设置同时作用于 VS Code Copilot Chat 扩展和支撑 Copilot CLI 的 agent host，无需每位开发者设置环境变量。

#### 技术剖析
集中遥测配置提高代理工具调用和运行行为的可观测性，也建立组织策略覆盖本地配置的部署路径。

#### 工作流影响
平台团队可统一采集 CLI 与编辑器代理遥测，用于故障、成本和审计分析；需同步 collector 容量和数据治理。

#### 局限与风险
遥测可能包含敏感元数据，集中强制导出增加隐私、跨境和 collector 可用性风险；并非所有行为都一定被埋点。

#### 后续关注
核对导出字段、脱敏、保留期和失败策略，并验证托管设置优先级及 collector 中断影响。

#### 官方来源
- [Copilot 企业托管 OTel 官方 changelog](<https://github.blog/changelog/2026-07-08-enterprise-managed-opentelemetry-export-for-vs-code-and-cli>)（official-changelog，复核：2026-07-18）

<a id="organization-R29vZ2xlIEFJIEVkZ2U"></a>
## Google AI Edge

<a id="event-google-litert-216-2026"></a>
### LiteRT 2\.1\.6 将 C\+\+ API 改为仅头文件形式并增加 Armv7 预构建包
<!-- event-record:{"id":"google-litert-216-2026","date":"2026-07-02","organization":"Google AI Edge"} -->

- 日期：2026-07-02
- 标题：LiteRT 2\.1\.6 将 C\+\+ API 改为仅头文件形式并增加 Armv7 预构建包
- 优先级：medium
- 主题：嵌入式与边缘计算
- 协作方：无

#### 客观事实
- LiteRT 2\.1\.6 将 C\+\+ API 重构为仅头文件形式（header-only），使用时不再需要链接 Abseil。
- 该版本发布 Armv7 预构建包，并扩展 Accelerator Test Suite 的单算子覆盖。

#### 技术剖析
链接依赖减少和 Armv7 二进制可用性降低嵌入式集成门槛，测试覆盖扩展有助于评估加速器委托正确性。

#### 工作流影响
边缘团队可简化 C\+\+ 构建并覆盖较旧 Armv7 设备，同时利用 ATS 检查后端算子。

#### 局限与风险
仅头文件形式不消除运行时和加速器驱动约束，实际模型仍可能回退 CPU。

#### 后续关注
对目标模型记录委托分区、回退算子、二进制体积、时延和数值误差。

#### 官方来源
- [LiteRT 2\.1\.6 官方发布页](<https://github.com/google-ai-edge/LiteRT/releases/tag/v2.1.6>)（official-release，复核：2026-07-18）

<a id="organization-QXJkdWlubw"></a>
## Arduino

<a id="event-arduino-ide-2310-2026"></a>
### Arduino IDE 2\.3\.10 增加干净编译并修复缓存误用
<!-- event-record:{"id":"arduino-ide-2310-2026","date":"2026-06-09","organization":"Arduino"} -->

- 日期：2026-06-09
- 标题：Arduino IDE 2\.3\.10 增加干净编译并修复缓存误用
- 优先级：medium
- 主题：嵌入式与边缘计算
- 协作方：无

#### 客观事实
- Arduino IDE 2\.3\.10 将 Arduino CLI 更新至 1\.5\.1，并增加通过 Shift 加验证按钮执行 clean compile/verify。
- 该版本修复草图修改后仍错误复用缓存产物，以及 CLI 目录默认值缺失导致的启动错误。

#### 技术剖析
干净编译入口和缓存修复提高固件构建结果可信度，减少旧目标文件掩盖源码变化。

#### 工作流影响
Arduino 固件排障时可直接执行 clean verify，并降低缓存造成的假通过风险。

#### 局限与风险
IDE 行为仍依赖捆绑 CLI、板卡核心和库版本，不能替代 CI 中的可复现构建。

#### 后续关注
升级后对常用板卡执行增量与干净构建对照，并固定 CI CLI 版本。

#### 官方来源
- [Arduino IDE 2\.3\.10 官方发布页](<https://github.com/arduino/arduino-ide/releases/tag/2.3.10>)（official-release，复核：2026-07-18）

<a id="organization-Q0hJUFMgQWxsaWFuY2U"></a>
## CHIPS Alliance

<a id="event-chipsalliance-chisel-713-2026"></a>
### Chisel 7\.13 增加 ChiselTest 兼容层与调试元数据
<!-- event-record:{"id":"chipsalliance-chisel-713-2026","date":"2026-06-01","organization":"CHIPS Alliance"} -->

- 日期：2026-06-01
- 标题：Chisel 7\.13 增加 ChiselTest 兼容层与调试元数据
- 优先级：medium
- 主题：EDA、FPGA 与芯片
- 协作方：无

#### 客观事实
- Chisel 7\.13\.0 为 Chisel 7 增加 ChiselTest compatibility layer。
- 该版本增加 circt\_debug 系列 intrinsic 以携带 Chisel 类型元数据，并将 FIRRTL 后端更新至 7\.0\.0。

#### 技术剖析
兼容层降低验证代码迁移成本，调试元数据则改善生成 RTL 与源级硬件描述之间的可追踪性。

#### 工作流影响
RTL 团队可逐步迁移 Chisel 7 测试，同时评估 CIRCT 调试信息对波形和问题定位的帮助。

#### 局限与风险
后端版本升级可能改变生成 RTL、诊断或优化结果，需要等价性和时序回归。

#### 后续关注
在代表模块上运行旧测试兼容回归，并比较升级前后的 FIRRTL/RTL 与综合结果。

#### 官方来源
- [Chisel 7\.13\.0 官方发布页](<https://github.com/chipsalliance/chisel/releases/tag/v7.13.0>)（official-release，复核：2026-07-18）

<a id="organization-TWljcm9zb2Z0"></a>
## Microsoft

<a id="event-microsoft-markitdown-016-2026"></a>
### MarkItDown 0\.1\.6 增加扫描 PDF OCR 并修复内存增长
<!-- event-record:{"id":"microsoft-markitdown-016-2026","date":"2026-05-26","organization":"Microsoft"} -->

- 日期：2026-05-26
- 标题：MarkItDown 0\.1\.6 增加扫描 PDF OCR 并修复内存增长
- 优先级：medium
- 主题：工程文档
- 协作方：无

#### 客观事实
- MarkItDown 0\.1\.6 增加对嵌入图片和 PDF 扫描件的 OCR layer service。
- 该版本通过关闭 PDF page 修复转换过程 O\(n\) 内存增长，并更新非本地接口绑定和安全姿态说明。

#### 技术剖析
OCR 与内存修复提升大体积扫描数据手册转文本的覆盖和稳定性，安全说明关系到资料服务暴露边界。

#### 工作流影响
工程资料流水线可处理扫描 PDF，并降低多页文档转换内存持续增长风险。

#### 局限与风险
OCR 结果仍可能误识别引脚名、数值和单位，不能替代原始数据手册核对。

#### 后续关注
用含表格、引脚图和扫描页的数据手册评测 OCR，保留页码引用并限制服务监听范围。

#### 官方来源
- [MarkItDown 0\.1\.6 官方发布页](<https://github.com/microsoft/markitdown/releases/tag/v0.1.6>)（official-release，复核：2026-07-18）

<a id="organization-RnJlZVJUT1M"></a>
## FreeRTOS

<a id="event-freertos-kernel-1130-2026"></a>
### FreeRTOS Kernel 11\.3\.0 增加 Cortex-R82 MPU 与 STAR-MC3 端口
<!-- event-record:{"id":"freertos-kernel-1130-2026","date":"2026-03-30","organization":"FreeRTOS"} -->

- 日期：2026-03-30
- 标题：FreeRTOS Kernel 11\.3\.0 增加 Cortex-R82 MPU 与 STAR-MC3 端口
- 优先级：medium
- 主题：嵌入式与边缘计算
- 协作方：无

#### 客观事实
- FreeRTOS Kernel 11\.3\.0 增加 Arm China STAR-MC3 port。
- 该版本为 Arm Cortex-R82 port 增加 MPU 支持。

#### 技术剖析
新增处理器端口和 MPU 能力扩展了可选器件范围，也影响安全隔离和任务权限设计。

#### 工作流影响
采用 Cortex-R82 或 STAR-MC3 的固件团队可基于上游端口评估移植，并将 MPU 纳入任务隔离。

#### 局限与风险
上游端口不等于具体 SoC BSP 完整可用，启动、缓存、中断和安全配置仍由平台集成负责。

#### 后续关注
在目标 SoC 上验证上下文切换、中断延迟、MPU fault、缓存一致性和压力负载。

#### 官方来源
- [FreeRTOS Kernel 11\.3\.0 官方发布页](<https://github.com/FreeRTOS/FreeRTOS-Kernel/releases/tag/V11.3.0>)（official-release，复核：2026-07-18）

<a id="organization-UmVub2Rl"></a>
## Renode

<a id="event-renode-1161-2026"></a>
### Renode 1\.16\.1 增加 Cortex-M55 与 Arm Helium 仿真支持
<!-- event-record:{"id":"renode-1161-2026","date":"2026-02-16","organization":"Renode"} -->

- 日期：2026-02-16
- 标题：Renode 1\.16\.1 增加 Cortex-M55 与 Arm Helium 仿真支持
- 优先级：medium
- 主题：嵌入式与边缘计算、EDA、FPGA 与芯片
- 协作方：无

#### 客观事实
- Renode 1\.16\.1 增加 Arm Helium M-Profile Vector Extension 初始支持，并向 GDB 暴露相关寄存器。
- 该版本增加 Cortex-M55 和 Armv8-M FPv5 支持，并向 GDB 暴露 FPv5 寄存器。

#### 技术剖析
新架构与调试寄存器支持让 Cortex-M55/MVE 固件更早进入虚拟平台自动测试和调试。

#### 工作流影响
固件团队可在硬件到位前运行启动、异常和向量代码测试，并通过 GDB 检查相关状态。

#### 局限与风险
初始 MVE 支持不等同于周期精确模型或全部外设/指令行为覆盖。

#### 后续关注
将关键测试在 Renode 与真实芯片上对照，重点检查向量、浮点、异常和寄存器语义。

#### 官方来源
- [Renode 1\.16\.1 官方发布页](<https://github.com/renode/renode/releases/tag/v1.16.1>)（official-release，复核：2026-07-18）

<a id="organization-QW50bWljcm8"></a>
## Antmicro

<a id="event-antmicro-kenning-082-2026"></a>
### Kenning 0\.8\.2 增加 ExecuTorch、tinygrad 与 ROS 2 集成
<!-- event-record:{"id":"antmicro-kenning-082-2026","date":"2026-02-12","organization":"Antmicro"} -->

- 日期：2026-02-12
- 标题：Kenning 0\.8\.2 增加 ExecuTorch、tinygrad 与 ROS 2 集成
- 优先级：medium
- 主题：机器人与 ROS、嵌入式与边缘计算
- 协作方：无

#### 客观事实
- Kenning 0\.8\.2 增加 tinygrad 模型和 ExecuTorch runtime 支持，并包含 Kenning Zephyr Runtime。
- 该版本改进 ROS 2 集成，可从 Kenning 层以 ROS 2 service 方式提供模型。

#### 技术剖析
同一工具链开始覆盖模型转换、Zephyr 端运行和 ROS 2 服务化，缩短边缘模型从评测到设备集成的路径。

#### 工作流影响
团队可用统一流水线比较模型/runtime，并将选定模型部署到 Zephyr 或 ROS 2 节点。

#### 局限与风险
新增后端的算子覆盖、资源占用和目标板支持仍需逐项目验证。

#### 后续关注
选取代表模型在目标 MCU/边缘板上验证转换正确性、时延和内存峰值。

#### 官方来源
- [Kenning 0\.8\.2 官方发布页](<https://github.com/antmicro/kenning/releases/tag/v0.8.2>)（official-release，复核：2026-07-18）

<a id="organization-UGxhdGZvcm1JTw"></a>
## PlatformIO

<a id="event-platformio-core-6119-2026"></a>
### PlatformIO Core 6\.1\.19 支持 Python 3\.14 并更新测试框架
<!-- event-record:{"id":"platformio-core-6119-2026","date":"2026-02-04","organization":"PlatformIO"} -->

- 日期：2026-02-04
- 标题：PlatformIO Core 6\.1\.19 支持 Python 3\.14 并更新测试框架
- 优先级：medium
- 主题：嵌入式与边缘计算
- 协作方：无

#### 客观事实
- PlatformIO Core 6\.1\.19 增加 Python 3\.14 支持。
- 该版本将 Doctest 更新至 2\.4\.12、GoogleTest 更新至 1\.17\.0、Unity 更新至 2\.6\.1，并改善 CCLS 编辑器集成。

#### 技术剖析
主机 Python 与嵌入式测试框架基线更新会影响开发机、CI 和测试结果一致性。

#### 工作流影响
固件项目可升级 Python 运行环境和测试组件，但需要重跑单元测试并检查自定义测试适配。

#### 局限与风险
平台、framework 和 board package 仍独立演进，Core 升级不能保证所有组合兼容。

#### 后续关注
在锁定的板卡矩阵上执行构建、上传、调试和三类测试框架回归。

#### 官方来源
- [PlatformIO Core 6\.1\.19 官方发布页](<https://github.com/platformio/platformio-core/releases/tag/v6.1.19>)（official-release，复核：2026-07-18）
