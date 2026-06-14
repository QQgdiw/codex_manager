# 项目关键记录

## 2026-06-13：Task 1 测试入口审查修复

- 审查确认原基线中的 `2 + 2` 断言不能证明测试入口行为，已删除。
- 新测试将 `Run-Tests.ps1` 复制到独立临时目录，动态创建 unit/integration Pester 夹具，并通过子 PowerShell 进程检查真实退出码；临时 runner 不会发现仓库自身测试，因此不会递归调用。
- RED：入口级测试共 6 项，5 项通过；零匹配预期退出 2、实际退出 1，准确复现全局 `ErrorActionPreference = 'Stop'` 使 `Write-Error` 提前终止的问题。
- GREEN：移除全局 Stop 偏好，并使用 stderr 直接报告基础设施错误后，6 项全部通过；默认模式执行 unit 和 integration，选择器只执行目标范围，普通测试失败返回 1，零匹配返回 2。
- `.gitignore` 新增 `.env` 和 `.env.*`，并通过 `!.env.example` 保留可提交的示例配置。

## 2026-06-13：Task 1 仓库安全与测试基线

- RED：直接运行 `Baseline.Tests.ps1` 时共执行 4 项，2 项通过、2 项因 `tests/Run-Tests.ps1` 缺失而失败，确认测试能捕获缺失入口。
- GREEN：实现入口并修正 Pester 3.4 集合断言语法后，`-All` 共执行 4 项，4 项通过、0 项失败，退出码为 0。
- `-Unit` 和无参数默认模式退出码均为 0；当前没有集成测试时，`-Integration` 返回非零，未出现零测试假成功。
- Pester 3.4 的 `Should Contain` 用于检查文件内容，不适合直接检查集合成员；集合契约使用 PowerShell 原生 `-contains` 后再断言布尔值。
- 测试入口先枚举匹配的 `*.Tests.ps1` 文件；匹配数为 0、Pester 未执行测试、Pester 抛错或测试失败时均返回非零。
- `.gitignore` 保留 `.worktrees/`、`auth.json`、`.codex/auth.json` 和凭据规则，并补充测试产物、日志、Python 缓存及 `MCP/servers/node_modules/`。

## 2026-06-13：需求文档读取编码

- `需求文档.txt` 使用 UTF-8 编码。
- PowerShell 默认读取曾产生中文错译。
- 后续读取中文需求和 Markdown 文件时，应显式使用 `-Encoding UTF8`，并在需要时将控制台输出编码设置为 UTF-8。

## 2026-06-13：版本库状态

- 当前 `E:\codex` 已关联 Git 仓库 `origin/main`。
- 远程 `HEAD` 连通性已验证，当前远程提交为 `1a6c95924d3121674d1170dad15fb7a151bc5ef5`。
- `MCP/servers` 与 `Skills/AgentSkillsforContextEngineering` 是嵌套 Git 仓库，首次纳管前必须明确使用 submodule 或固定版本归档，不能直接含糊提交。

## 2026-06-13：关键风险边界

- GitHub 缺少满足本项目要求的完整官方历史周榜，2026 年既往数据可能只能近似回溯。
- 第三方系统级依赖无法保证完全回滚，必须记录未清理残留。
- 只完成静态检查的工具不得标记为完全可用。
- 凭据必须通过 Windows DPAPI 加密，禁止出现在配置、日志和版本库中。

## 2026-06-13：能力与权限审计

- 当前 Codex CLI 版本为 `0.139.0`。
- `codex plugin list` 返回无 marketplace plugin。
- `codex mcp list` 返回无已配置 MCP。
- 项目根目录 `config.toml` 不能视为当前 Codex CLI 已加载配置。
- 当前会话自带 Superpowers、浏览器、文件和文档能力，足以完成首期开发，不需要立即安装额外扩展。
- 本地 MCP 源码存在，但 Puppeteer 预期构建文件缺失；所有 MCP 均尚未在 Codex 中启用和验证。
- 沙箱内 `codex login status` 显示未登录，但沙箱外返回 `Logged in using ChatGPT`，说明用户级 `C:\Users\86178\.codex\auth.json` 可用，差异来自运行账户隔离。
- 禁止读取、输出或提交 `auth.json` 正文。认证验证只使用状态命令和脱敏诊断结果。
- Doctor 在沙箱内报告部分服务端点不可达，真实加载验证应在沙箱外和已授权网络环境复核。
- 工作区内读写权限已验证。工作区外用户 Codex 目录、联网下载、系统级安装和管理员操作需要按次申请。
- 用户已同意联网下载自动执行；首次遇到具体联网命令时应申请可复用的命令前缀授权。
- 现有 `MCP/servers` 与 `Skills/AgentSkillsforContextEngineering` 必须作为首批管理对象，和后续白名单项目一样完成来源、版本、审批、部署和分层验证。

## 2026-06-14：Task 5 安全回滚重构

- 初始 RED：定向 33 项中 5 项失败，稳定复现 junction 删除、持久化根授权、备份换绑、重复键和 16 进程并发丢记录。
- 扩展 RED：加入 Schema v2、未知字段/类型、Integrity、Confirm、FileId、delete 前置条件和耐久临时清理后，41 项中 33 项失败；主要缺口是 v1 Schema、无可信根参数、无锁和无身份确认。
- GREEN：定向 41/41、Unit 122/122、Integration 3/3、All 125/125、攻击探针 15/15。
- 路径授权必须使用调用方传入的可信 `AllowedRoots` 加默认 git 根和用户 `.codex`；日志内 `AllowedRoots` 仅用于审计并纳入完整性，不得参与授权。
- 路径采用词法规范化，不解析 reparse 目标；从匹配根到目标任一现存组件含 reparse point 即拒绝。
- create/directory_create 未确认时不得删除；确认后若 VolumeSerial/FileId 不匹配则拒绝。modify 同样要求原始身份匹配，delete 只在目标仍缺失时恢复。
- DPAPI CurrentUser 不能抵御当前用户账户完全失陷；PowerShell 路径 API 仍无法彻底消除同用户微秒级 TOCTOU，但已修复可复现的替换攻击并在关键操作前重复检查。

## 2026-06-14：Task 5 journal 存储路径加固

- 规格审查发现 journal 内部路径可通过 `.state/journals`、`backups` 或 lock 父路径 junction 写入外部目录。
- RED：新增存储路径攻击组 7 项时 3 项失败，确认 journals junction、backups junction 和 lock 父路径替换会绕过原边界；外部目录可出现 journal、backup 或 lock 文件。
- 修复统一使用 `Validate-JournalStoragePath`：所有公开入口在锁前验证，锁、journal temp 和 backup 打开前再次验证。
- 缺失 StateRoot 及其内部目录从可信根开始逐级创建，每一级创建前后检查词法边界和 ReparsePoint；禁止将 StateRoot 注册为递归删除目标。
- GREEN：存储攻击组 8/8、Target 49/49、Unit 130/130、Integration 3/3、All 133/133、组合攻击探针 23/23。
