# 下一步协作指南

本文档用于说明当前项目已经完成什么、下一步建议做什么，以及你需要如何配合。

## 当前项目状态

首期基础闭环已经完成。当前系统具备：

- TOML 白名单与人工审批记录。
- plugin、skill、MCP 三类工具的部署计划、dry-run 和真实部署适配器。
- 三类工具的静态验证和 load verification。
- 变更日志、受管回滚、凭据保护和状态记录。
- 隔离测试环境；最近一次全量测试为 `356 passed / 0 failed`。

需要注意以下区别：

- **代码路径已经实现并测试**，不代表工具已经部署到你的用户级 Codex 环境。
- 集成测试使用临时目录和 fake `codex.cmd`，不会修改真实 Codex 配置。
- 当前 `Resources/config_*.toml` 中的 `enabled_tools` 均为空，直接运行这些场景配置不会部署任何工具。
- load verification 只证明工具已安装、内容正确或能被 Codex CLI 查询；sequential-thinking 和 filesystem MCP 已额外完成自动 smoke，但其他工具仍没有功能调用证据。

截至 2026-07-12，sequential-thinking MCP 和 filesystem MCP 均已写入用户级 Codex 配置，静态验证、load verification 和管理器自动 smoke verification 均已通过；自动 smoke 只记录工具名、内容类型和错误码，不记录完整 MCP 返回正文。

## 推荐下一步

sequential-thinking MCP 的自动化 smoke verifier 已接入并通过真实验证。filesystem MCP 也已完成受限真实试运行，当前边界为：

- 允许根目录：`E:\codex`
- smoke 写入仅发生在 `.tmp\mcp-smoke\<operation>` 临时目录。
- cleanup 后已确认无 operation root、目标 marker 文件和目标 Node 进程残留。

后续按以下顺序推进：

1. 进入文档质量审计与整理阶段，统一 PRD、PP、GUIDE、审批文档、market 文档、验证记录和 state 文件口径。
2. 分别为 plugin 和 skill 补充功能性 smoke verifier，或先明确哪些低优先级工具只要求 static/load。
3. 根据实际工作场景填写 `Resources/config_*.toml` 的 `enabled_tools`。

## 你需要如何配合

如果接受推荐顺序，直接告诉我：

```text
进入文档质量审计与整理阶段。
```

收到指示后，我会：

1. 建立文档地图，明确每份文档的用途和读者。
2. 统一术语和状态，例如 `approved/deployed/static/load/smoke`。
3. 清理过期描述，尤其是已经完成的 filesystem 和 sequential-thinking 状态。
4. 给出你下一步如何配合的最新操作口径。

如果暂时不希望进入文档整理，也可以告诉我：

```text
下一步先补 plugin smoke verifier。
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
- filesystem MCP 当前允许根目录为 `E:\codex`；后续扩大或收缩范围都应重新审批和验证。
- smoke verifier 必须执行真实、最小、低副作用的功能调用，不能用静态检查或配置可见性冒充成功。
- 涉及用户目录写入、真实 Codex 配置修改、联网下载或系统级操作时，我会按权限要求申请授权。

## 当前建议口令

若要继续推进，建议直接回复：

```text
进入文档质量审计与整理阶段。
```
