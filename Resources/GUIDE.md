# 下一步协作指南

本文档用于说明当前项目已经完成什么、下一步建议做什么，以及你需要如何配合。

## 当前项目状态

首期基础闭环已经完成。当前系统具备：

- TOML 白名单与人工审批记录。
- plugin、skill、MCP 三类工具的部署计划、dry-run 和真实部署适配器。
- 三类工具的静态验证和 load verification。
- 变更日志、受管回滚、凭据保护和状态记录。
- 隔离测试环境；最近一次全量测试为 `300 passed / 0 failed`。

需要注意以下区别：

- **代码路径已经实现并测试**，不代表工具已经部署到你的用户级 Codex 环境。
- 集成测试使用临时目录和 fake `codex.cmd`，不会修改真实 Codex 配置。
- 当前 `Resources/config_*.toml` 中的 `enabled_tools` 均为空，直接运行这些场景配置不会部署任何工具。
- load verification 只证明工具已安装、内容正确或能被 Codex CLI 查询；目前尚未证明实际功能调用成功。

截至 2026-06-29，sequential-thinking MCP 的 plan、dry-run 和临时 `CODEX_HOME` 真实 CLI add/get/remove 已通过；用户级真实部署仍等待提升权限执行通道恢复，本轮没有修改用户级 Codex 配置。

## 推荐下一步

建议先进行一次**单工具真实环境试运行**，首选：

```text
mcp.modelcontextprotocol.sequential-thinking
```

选择它的原因：

- 已在白名单中批准。
- 不需要文件系统访问权限。
- 相比 filesystem MCP，真实试运行的副作用和权限风险更低。
- 可以先验证真实 `codex mcp add`、`codex mcp get` 和失败处理链路。

试运行稳定后，再按以下顺序推进：

1. 为 sequential-thinking MCP 设计最小功能性 smoke verifier。
2. 明确 filesystem MCP 的允许根目录和读写范围。
3. 对 filesystem MCP 进行真实环境试运行和 smoke 验证。
4. 分别为 plugin 和 skill 补充功能性 smoke verifier。
5. 根据实际工作场景填写 `Resources/config_*.toml` 的 `enabled_tools`。

## 你需要如何配合

如果接受推荐顺序，直接告诉我：

```text
进行真实环境试运行，先部署并验证 sequential-thinking MCP。
```

收到指示后，我会：

1. 创建只启用该 MCP 的临时配置，不直接改动六类场景配置。
2. 先运行 plan 和 dry-run，确认命令、目标和回滚信息。
3. 在真正修改用户级 Codex 配置前申请所需权限。
4. 执行真实部署和 load verification。
5. 记录结果；失败时执行受管回滚或记录无法自动清理的残留。
6. 根据真实结果设计最小 smoke verifier。

如果暂时不希望修改真实用户环境，可以告诉我：

```text
暂不进行真实部署，先设计 sequential-thinking MCP 的 smoke verifier。
```

如果希望先处理其他类型，可以明确指定：

```text
下一步先为 browser 插件设计 smoke verifier。
```

或：

```text
下一步先为 context-fundamentals Skill 设计 smoke verifier。
```

## 你不需要做什么

- 不需要手动编辑白名单或场景配置，我会根据你确认的范围生成最小配置。
- 不需要把 `auth.json`、Token、密码或其他凭据发给我。
- 不需要手动运行测试，除非你希望自己复核。
- 不需要批准 `approval_review.md` 中的全部工具；当前 approved 工具已足够继续。
- 不需要一次部署全部工具，应继续采用小批量、可验证、可回滚的方式。

## 重要边界

- 白名单批准不等于已启用或已部署。
- dry-run 通过不等于真实命令执行成功。
- load verification 通过不等于功能性 smoke verification 通过。
- filesystem MCP 在未明确允许根目录前，不应进行真实功能调用。
- smoke verifier 必须执行真实、最小、低副作用的功能调用，不能用静态检查或配置可见性冒充成功。
- 涉及用户目录写入、真实 Codex 配置修改、联网下载或系统级操作时，我会按权限要求申请授权。

## 当前建议口令

若要继续推进，建议直接回复：

```text
进行真实环境试运行，先部署并验证 sequential-thinking MCP。
```
