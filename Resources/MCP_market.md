# MCP 市场

> 采集时间：2026-06-23
> 范围：`Resources/github_market.md` 派生项和当前主工作区 `E:\codex\MCP\servers`。

## 当前结论

`github_market.md` 首版中没有可直接确认的 MCP server 项目。本次 MCP 市场主要来自主工作区现有源码 `E:\codex\MCP\servers`，其上游为 `https://github.com/modelcontextprotocol/servers.git`，当前本地 commit 为 `64b1cb0208cc49a4f5ae55fa71df5cf67a3cdc3d`。

这些对象当前状态：

- 源码存在：是。
- 可部署：部分可部署，已有 `dist/index.js`，但尚未在隔离 Codex 配置中执行真实 `codex mcp add`。
- 已配置：否，`codex mcp list` 之前返回无已配置 MCP。
- 已静态验证：仅验证 package manifest、入口文件存在和本地 commit。
- 已动态验证：否。

## 候选 MCP

| ID | 包 | 版本 | 入口 | 价值 | 风险 | 白名单 |
| --- | --- | --- | --- | --- | --- | --- |
| `mcp.modelcontextprotocol.filesystem` | `@modelcontextprotocol/server-filesystem` | `0.6.3` | `src/filesystem/dist/index.js` | 文件读写和目录操作 MCP；需要严格根目录限制 | 高：直接文件系统读写 | `proposed` |
| `mcp.modelcontextprotocol.memory` | `@modelcontextprotocol/server-memory` | `0.6.3` | `src/memory/dist/index.js` | 知识图谱式 memory MCP，可辅助长期上下文 | 中：可能持久化敏感上下文 | `proposed` |
| `mcp.modelcontextprotocol.sequential-thinking` | `@modelcontextprotocol/server-sequential-thinking` | `0.6.2` | `src/sequentialthinking/dist/index.js` | 分步推理 MCP，适合复杂任务拆解 | 中：会影响推理流程但外部副作用较小 | `proposed` |
| `mcp.modelcontextprotocol.everything` | `@modelcontextprotocol/server-everything` | `2.0.0` | `src/everything/dist/index.js` | 协议覆盖测试服务器 | 高：测试面过宽，含不适合生产的协议演示能力 | 暂缓 |

## 许可证

仓库根 `LICENSE` 说明项目正从 MIT 迁移至 Apache-2.0。白名单中暂记为 `MIT/Apache-2.0 transition`，批准前需要按具体子包和文件确认最终许可证边界。

## 后续验证

1. 用隔离 `$CODEX_HOME` 执行 `codex mcp add` 和 `codex mcp get <name> --json`。
2. 对 filesystem MCP 明确 allowed roots 或 roots protocol 支持，不允许默认扩大到用户主目录。
3. 对 memory MCP 明确数据落盘位置、清理策略和敏感信息过滤。
4. 对 sequential-thinking MCP 验证启动、最小调用和失败返回。
5. `everything` 仅用于协议测试，不进入首批部署白名单。
