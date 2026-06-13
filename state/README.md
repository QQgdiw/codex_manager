# 项目状态说明

## 项目定位

本工作区用于管理 Codex Plugins、MCP、Skills 和其他 AI 工作流资源，并面向 Windows 环境提供场景化配置、自动部署、分层验证和失败回滚能力。

## 当前阶段

项目需求澄清和项目计划已经完成，正式文档分别位于 `Resources/PRD.md` 与 `Resources/PP.md`。PP Task 1 已建立仓库安全与测试基线；下一阶段将定义白名单 Schema 和 PowerShell 自动化核心。

## 首期范围

- 首次填充并按需增量维护五类市场文档。
- 提供六类场景化配置。
- 使用 TOML 白名单控制自动部署。
- 使用 PowerShell 完成部署、验证、回滚和记录。
- 使用 Windows DPAPI 加密本地凭据。
- 仅支持并验证 Windows 环境。

## 关键原则

- 原生能力优先，选择最小充分工具集。
- 白名单由系统建议、用户批准。
- 工具固定版本，升级需重新确认。
- 资源信息必须可追溯，不完整历史数据明确标注。
- 严格区分收录、批准、部署和不同验证状态。
- 设想 A、B、C 仅进入后续路线，首期不实现。

## 关键文档

- 初始需求：`需求文档.txt`
- 正式需求：`Resources/PRD.md`
- 项目计划：`Resources/PP.md`
- 配置参考：`Templates/config_toml.txt`
- 当前任务：`state/TODO.md`
- 排障记录：`state/LOG.md`

## 当前能力状态

- `tests/Run-Tests.ps1` 提供 Pester 3.4 兼容入口，支持 `-Unit`、`-Integration`、`-All`，默认执行全部测试，并在测试失败或零匹配时返回非零。
- `tests/unit/Baseline.Tests.ps1` 验证 Windows PowerShell 主版本不低于 5，并包含稳定、离线的真实断言。
- `.gitignore` 已覆盖本地凭据、认证文件、测试产物、日志、Python 缓存和 MCP 第三方依赖。
- 当前会话具备完成首期所需的检索、浏览器、文件、PowerShell、测试和 Git 能力，无需立即安装额外扩展。
- Codex CLI 当前未配置 marketplace plugin 和 MCP。
- 根目录 `config.toml` 当前不能视为 Codex 已加载配置。
- 用户级 Codex `auth.json` 已在沙箱外验证可用；认证检查不读取文件正文。
- 现有 `MCP/servers` 和 `Skills/AgentSkillsforContextEngineering` 将作为首批管理对象，按新项目相同规则进入白名单和验证流程。
- 联网下载可自动执行；首次按命令前缀申请并保存授权规则。用户目录写入或系统级变更仍需明确授权。
