# MCP 自动 Smoke Verifier 设计

## 1. 背景

项目已经完成 MCP 的真实部署适配器和 load verification。`sequential-thinking` 已部署到用户级 Codex 配置，并通过一次独立客户端完成 MCP 初始化、工具发现和最小工具调用。

当前管理器尚未注入 MCP `SmokeVerifier`，因此入口执行 `verify` 时，static 和 load 可以通过，但 smoke 仍返回 `blocked / smoke_verifier_missing`。本设计把已验证的手工流程固化为通用、声明式、可复用的自动验证能力。

## 2. 目标

- 在 `tool_whitelist.toml` 中为 MCP 声明最小 smoke 调用。
- 将 smoke 声明固化到批准快照，避免运行时配置覆盖审批内容。
- 使用通用 MCP stdio 协议运行器完成初始化、工具发现和最小调用。
- 支持经过审批并固定 SHA-256 的生命周期脚本。
- 把生命周期脚本的文件访问限制在管理器创建的专用临时目录。
- 对超时、协议错误、结果不匹配、清理失败和残留进程进行明确分类。
- 首个实现覆盖 `mcp.modelcontextprotocol.sequential-thinking`，后续复用于 filesystem MCP。

## 3. 非目标

- 本任务不部署 filesystem MCP。
- 本任务不修改 filesystem MCP 的允许根目录；后续真实部署时按已确认方案使用 `E:\codex`。
- 本任务不为 plugin 或 Skill 实现 smoke verifier。
- Smoke verifier 不执行 `codex mcp remove`，也不自行决定部署回滚。
- 白名单不允许内联 shell 命令。
- 首期不支持 HTTP transport 的 MCP smoke；仅覆盖 stdio。

## 4. 已确认决策

1. 采用通用声明式 MCP smoke，而不是 sequential-thinking 专用实现。
2. Smoke 声明位于对应 `[[tools]]` 下的 `[tools.smoke]`，并进入批准快照。
3. 生命周期扩展只能使用仓库内固定脚本，脚本必须校验 SHA-256。
4. 生命周期脚本不能接收任意命令，只能接收固定动作和管理器生成的临时路径。
5. 临时目录位于 `<项目根>\.tmp\mcp-smoke\<operation-id>`。
6. 无论验证成功或失败都必须执行 cleanup，并终止 MCP 子进程。
7. 清理失败或发现残留进程时，整体 smoke 状态为 `failed`。
8. Smoke verifier 只检测和报告；部署编排根据安装前快照决定是否回滚。

## 5. 方案选择

### 5.1 采用方案

采用“通用协议运行器 + 固定生命周期脚本”：

- 通用 Node 运行器负责 MCP stdio 协议、超时和进程生命周期。
- PowerShell 适配器负责批准快照、路径与哈希校验、状态映射和记录脱敏。
- 每个 MCP 可选一个固定生命周期脚本，负责 prepare、validate 和 cleanup。

### 5.2 未采用方案

- 每个 MCP 独立实现完整协议客户端：会重复协议和进程管理逻辑。
- 纯 PowerShell MCP 客户端：stdio 并发、JSON-RPC 和跨进程超时处理复杂。
- 任意前后置 shell：会把白名单扩展成通用命令执行入口。

## 6. 组件设计

### 6.1 白名单 Smoke 声明

`Resources/tool_whitelist.toml` 的 MCP 条目增加 `[tools.smoke]`：

```toml
[tools.smoke]
tool_name = "sequentialthinking"
timeout_seconds = 10
expected_content_types = ["text"]
script_path = "scripts/smoke/mcp/sequential-thinking.mjs"

[tools.smoke.arguments]
thought = "Codex tool manager automated smoke verification."
nextThoughtNeeded = false
thoughtNumber = 1
totalThoughts = 1
```

正式条目还必须包含 `script_sha256`。实施时先完成脚本并冻结内容，再计算真实 SHA-256、写入白名单并进入审批；缺少该字段时 Schema 校验必须失败，因此不存在未固定哈希的真实执行路径。

字段约束：

- `tool_name`：非空字符串，必须与 `tools/list` 返回的工具名精确匹配。
- `timeout_seconds`：整数，允许范围为 1 至 30 秒。
- `expected_content_types`：非空、去重数组，首期只允许 MCP SDK 已知内容类型。
- `script_path`：项目根目录下的相对路径，必须位于 `scripts/smoke/mcp/`，扩展名必须是 `.mjs`。
- `script_sha256`：64 位小写十六进制 SHA-256。
- `arguments`：TOML 结构化对象；禁止保存凭据，禁止转换为命令字符串。

### 6.2 批准快照

`New-DeploymentApprovedSnapshot` 对 mcp 类型保留完整 smoke 声明。部署计划校验必须比较顶层条目和 `ApprovedSnapshot.smoke`，后续验证只读取批准快照。

脚本内容或 smoke 参数发生变化时，SHA-256 或批准快照必然变化，必须重新审批后才能真实执行。

### 6.3 Load Verification 加固

Smoke 不能只证明某个本地服务器可以运行，还必须证明 Codex 中登记的配置与批准计划一致。因此 MCP load verifier 除名称存在外，还必须比较：

- transport 类型；
- stdio command；
- 解析后的参数数组；
- 与安全相关的可比较字段。

配置与批准快照不一致时，load verification 失败，禁止进入 smoke。比较和错误输出不得泄露环境变量值或其他敏感字段。

### 6.4 通用协议运行器

新增项目内受管 Node 模块，职责限定为：

1. 使用批准并解析后的 command 和参数启动 stdio MCP。
2. 完成 MCP initialize 和客户端能力协商。
3. 调用 `tools/list` 并查找 `tool_name`。
4. 使用结构化 `arguments` 调用 `tools/call`。
5. 将结果写入临时目录内的 JSON 文件。
6. 输出不含完整业务内容的结构化摘要。
7. 在成功、失败和超时路径关闭连接并终止子进程。

协议运行器不得通过 shell 拼接命令。所有可执行文件和参数必须使用结构化进程 API 传递。

### 6.5 生命周期脚本

生命周期脚本只支持三个固定动作：

- `prepare`：准备临时夹具。
- `validate`：读取临时目录内的结果文件并进行工具特定校验。
- `cleanup`：清理脚本创建的临时内容。

管理器通过参数数组传递动作和临时根，不传递任意命令文本。脚本使用 JSON 向标准输出返回简短状态，标准错误仅用于脱敏诊断。

脚本由 Node permission 模式运行：

- 只读脚本自身和专用临时目录；
- 只写专用临时目录；
- 不授予 child process、Worker 和 WASI 权限；
- 使用最小环境变量，不继承凭据、Token 和代理变量。

Node permission 模式不能可靠阻断网络访问。该限制通过人工审查、固定 SHA-256、最小环境变量和禁止脚本变更后免审批来缓解，但不宣称具备网络硬隔离。

## 7. 验证数据流

1. 读取场景配置和白名单。
2. 校验 smoke Schema，并写入批准快照。
3. static verification 校验脚本路径、真实路径、reparse point、扩展名和 SHA-256。
4. load verification 确认 Codex 配置与批准计划一致。
5. 创建唯一 operation ID 和专用临时目录。
6. 执行生命周期 `prepare`。
7. 启动 MCP 并完成 initialize。
8. 执行 `tools/list`，确认预期工具存在。
9. 执行最小 `tools/call`。
10. 保存临时结果并执行生命周期 `validate`。
11. 在 `finally` 路径关闭 MCP、终止进程并执行 `cleanup`。
12. 删除专用临时目录并检查残留进程。
13. 返回结构化 smoke 结果，由 VerificationEngine 映射为最终状态。

## 8. 错误边界

建议错误码：

| 阶段 | 错误码 | 结果 |
| --- | --- | --- |
| 未声明 smoke | `smoke_verifier_missing` | blocked |
| 声明字段非法 | `mcp_smoke_profile_invalid` | failed |
| 路径逃逸或 reparse point | `mcp_smoke_script_path_rejected` | failed |
| 脚本哈希不匹配 | `mcp_smoke_script_hash_mismatch` | failed |
| prepare 失败 | `mcp_smoke_prepare_failed` | failed |
| MCP 启动失败 | `mcp_smoke_start_failed` | failed |
| 操作超时 | `mcp_smoke_timeout` | failed |
| 未发现工具 | `mcp_smoke_tool_missing` | failed |
| MCP 调用返回错误 | `mcp_smoke_call_failed` | failed |
| 通用结果不匹配 | `mcp_smoke_result_mismatch` | failed |
| validate 失败 | `mcp_smoke_validate_failed` | failed |
| cleanup 失败 | `mcp_smoke_cleanup_failed` | failed |
| 子进程残留 | `mcp_smoke_residual_process` | failed |

如果主调用和 cleanup 同时失败，保留主错误码，并把 cleanup 错误和残留加入 `Residuals`。如果主调用成功但 cleanup 失败，则使用 cleanup 错误码，整体不得返回 `smoke_verified`。

## 9. 记录与脱敏

验证记录允许保存：

- 工具 ID 和 MCP 工具名；
- 验证阶段、开始时间、结束时间和耗时；
- 内容类型、检查名称和错误码；
- 脱敏后的脚本退出状态；
- 无法清理的临时路径或 PID。

不得保存：

- 完整 MCP 返回正文；
- 可能包含用户数据的调用参数；
- 环境变量值；
- Token、Cookie、密码或认证文件内容。

## 10. Sequential-thinking 首个 Profile

首个 profile 使用以下最小调用：

- MCP 工具：`sequentialthinking`；
- `thought`：固定的无敏感验证文本；
- `nextThoughtNeeded`：`false`；
- `thoughtNumber`：`1`；
- `totalThoughts`：`1`；
- 超时：10 秒；
- 预期内容类型：至少一个 `text`。

生命周期脚本：

- prepare 确认临时目录为空且可写；
- validate 确认调用没有 MCP error，且包含 `text` 内容；
- cleanup 删除脚本创建的临时内容。

成功条件是 load 已通过、initialize 成功、公布预期工具、最小调用成功、结果匹配、cleanup 成功且没有残留 MCP 子进程。

## 11. 后续 Filesystem 复用

后续 filesystem MCP 的服务器允许根目录按用户确认设置为 `E:\codex`。生命周期脚本自身仍只能访问管理器专用临时目录，不因 MCP 根目录扩大而扩大脚本权限。

Filesystem smoke 的首期调用应只操作 `<项目根>\.tmp\mcp-smoke\<operation-id>` 内的夹具，并在 cleanup 后确认文件和目录均不存在。真实部署和具体读写测试将在独立设计与实施任务中完成。

## 12. 测试设计

### 12.1 单元测试

- Smoke TOML Schema 的必填字段、类型、范围和未知字段。
- Smoke 声明进入批准快照且不能被顶层可变字段覆盖。
- 脚本目录逃逸、绝对路径、reparse point、错误扩展名和哈希不匹配。
- Load verification 对 transport、command 和参数差异的判定。
- 所有错误码、状态映射和脱敏行为。

### 12.2 协议与生命周期测试

- fake stdio MCP 的 initialize、`tools/list` 和 `tools/call`。
- 工具缺失、错误响应、畸形响应和超时。
- prepare、validate、cleanup 的固定顺序。
- 主流程失败时 cleanup 仍执行。
- cleanup 失败时不得返回 `smoke_verified`。
- 所有路径结束后无残留子进程。

### 12.3 入口集成测试

- approved sequential-thinking profile 的 static、load 和 smoke 均通过。
- 入口 `verify` 返回 `succeeded`，退出码为 0。
- 缺少 profile 的其他 MCP 继续返回 `blocked / smoke_verifier_missing`。
- dry-run 不执行 lifecycle 或协议调用。

### 12.4 真实环境复核

- 对已部署的 `modelcontextprotocol-sequential-thinking` 执行自动 smoke。
- 确认配置仍启用且参数保持绝对启动路径。
- 确认结果为 `smoke_verified`。
- 确认没有残留 Node 进程和临时目录。

## 13. 实施影响

预计修改范围：

- `Resources/tool_whitelist.toml`；
- `scripts/Invoke-CodexToolManager.ps1`；
- `scripts/lib/DeploymentEngine.ps1`；
- `scripts/lib/adapters/McpAdapter.ps1`；
- 新增通用 MCP smoke 运行器；
- 新增 sequential-thinking 生命周期脚本；
- 对应 unit、integration 和真实环境验证记录。

不引入新的全局 npm 安装。运行器优先使用已固定 MCP 源目录中的 `@modelcontextprotocol/sdk`，并在执行前验证 SDK 文件存在；缺失时明确失败，不联网静默安装依赖。

## 14. 完成标准

- sequential-thinking 的 `verify` 自动返回 `smoke_verified`。
- 整体 `verify` 退出码为 0。
- 所有新增和既有测试通过。
- 失败、超时和清理路径均无残留进程。
- 正式验证记录不包含完整调用正文或敏感参数。
- 设计中的 Node 网络隔离限制在文档和状态记录中保持可见。
