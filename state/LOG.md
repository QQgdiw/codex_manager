# 项目关键记录

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
- Codex CLI 未登录，且 Doctor 报告部分服务端点不可达。真实加载验证前需要用户登录，并可能需要网络策略配合。
- 工作区内读写权限已验证。工作区外用户 Codex 目录、联网下载、系统级安装和管理员操作需要按次申请。
