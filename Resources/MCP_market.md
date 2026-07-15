# MCP 市场

> 更新时间：2026-07-15
>
> 来源边界：GitHub 派生候选仅来自 `github_market.md` 中已有的 `github-record`；当前受管基线仅来自 `tool_whitelist.toml`、验证记录和只读运行状态核对。

## 当前结论

- 本轮对 66 条 MCP、Skill、Codex 或 Agent 相关 GitHub 候选进行分片审阅，没有候选同时满足许可证、安装入口、权限边界和当前 Codex 兼容性证据要求，因此 GitHub 派生 MCP 为 0。
- 白名单中的 MCP 上游不在本期 GitHub 周度总表中，不能为其生成 `derived-record`；它们在“当前受管基线”中独立记录。
- 2026-07-15 只读执行 `codex mcp list` 时，仅发现 `node_repl`；该条目未列入本项目白名单，因此不属于下方受管基线。filesystem 与 sequential-thinking 的历史验证记录仍有效，但当前 Codex 配置中未注册，不能描述为当前已部署。

## GitHub 派生候选

无。全部候选因许可证、可重复安装入口、权限/凭据边界或当前 Codex 兼容性证据不足而排除。此结论不改变白名单审批状态。

## 当前受管基线

| 白名单 ID | 审批 | 本地入口 | 历史验证 | 当前 Codex 状态 | 处理建议 |
| --- | --- | --- | --- | --- | --- |
| `mcp.modelcontextprotocol.filesystem` | `approved` | `E:\codex\MCP\servers\src\filesystem\dist\index.js` 存在；允许根目录仅 `E:\codex` | 2026-07-12：`static_verified`、`load_verified`、`smoke_verified` | 当前未注册 | 保留批准；重新部署前继续强制根目录、临时写入和残留清理边界。 |
| `mcp.modelcontextprotocol.sequential-thinking` | `approved` | `E:\codex\MCP\servers\src\sequentialthinking\dist\index.js` 存在 | 2026-07-06：`static_verified`、`load_verified`、`smoke_verified` | 当前未注册 | 保留批准；需要使用管理器重新部署并重新执行 load/smoke 后才能恢复“当前可用”结论。 |
| `mcp.modelcontextprotocol.memory` | `proposed` | `E:\codex\MCP\servers\src\memory\dist\index.js` 存在 | 没有本轮真实部署和动态验证证据 | 当前未注册 | 保持 proposed；先明确持久化位置、清理策略和敏感信息边界。 |

## 状态解释

- `approved` 只表示用户批准，不能推出当前已部署、已注册或可调用。
- 历史 `smoke_verified` 证明对应日期和配置下完成过最小调用，不证明 2026-07-15 的当前运行状态。
- 本地入口存在只证明源产物仍在磁盘，不证明 Codex 配置已经加载它。

## 风险边界

- filesystem 具有直接文件读写能力，任何重新部署都必须把根目录固定为 `E:\codex`，不得扩大到用户目录。
- memory 可能持久化上下文、路径或敏感资料，未明确数据生命周期前不得自动部署。
- 市场文档不产生部署授权；所有部署仍由 `tool_whitelist.toml` 和受管部署流程控制。
