# Task 1 报告：Plugins 目录采集器和完整性验证器

## 1. 状态

DONE

## 2. 修改文件

- `scripts/markets/plugin-catalog.mjs`
- `scripts/markets/export-plugins-market.mjs`
- `tests/node/plugin-catalog.test.mjs`
- `tests/unit/MarketScripts.Tests.ps1`

## 3. RED 证据

命令：

```powershell
node --test .\tests\node\plugin-catalog.test.mjs *> .\.tmp\plugin-catalog-red.log
```

结果：退出码 `1`（符合预期）。

预期失败原因：目标模块尚未实现。

证据：日志末尾显示 `ERR_MODULE_NOT_FOUND`，缺少 `scripts/markets/plugin-catalog.mjs`；Node 汇总为 `pass 0`、`fail 1`。

## 4. GREEN 证据

```powershell
node --check .\scripts\markets\plugin-catalog.mjs
node --check .\scripts\markets\export-plugins-market.mjs
node --test .\tests\node\plugin-catalog.test.mjs *> .\.tmp\plugin-catalog-final.log
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\.tmp\market-task1-unit-final.log
```

- 两个 `node --check` 均退出码 `0`。
- Node 测试退出码 `0`：7 通过，0 失败。
- Pester Unit 退出码 `0`：308 通过，0 失败。

## 5. 自审结果

- JSON-RPC 生命周期按 `initialize`、`initialized`、`plugin/list` 顺序发送，仅处理请求 ID `1` 和 `2` 的响应；超时、无效 JSON、子进程清理均有覆盖。
- 严格校验拒绝无效结果、marketplace 加载错误、缺失名称/ID、非数组 plugins 和完整记录键重复；记录顺序保持上游顺序。
- 记录身份使用 marketplace、id、remotePluginId、version 的 SHA-256；上游重复 ID 不会被去重。
- 渲染保留完整记录，并转义 Markdown 表格中的管道、换行和 HTML 控制字符；CLI 在采集和校验完成前不写目标文件，写入采用同目录临时文件加 rename。
- 已确认正式变更范围仅为四个指定文件，`git diff --check` 无输出，且代码与测试中没有 `auth.json` 引用。

## 6. Commit SHA

`07edc50`

## 7. 遗留顾虑

未执行账户依赖的 live `codex app-server` smoke；该接口是实验性接口，若未来 schema 变化，严格校验会以采集失败方式保护既有文档而非覆盖它。

---

## 审查修复：JSON-RPC 响应验证

### 修改文件

- `scripts/markets/plugin-catalog.mjs`
- `tests/node/plugin-catalog.test.mjs`

### RED 证据

命令：

```powershell
node --test .\tests\node\plugin-catalog.test.mjs *> .\.tmp\plugin-catalog-response-red.log
```

结果：退出码 `1`。新增的 `rejects matching responses that violate the JSON-RPC response contract` 失败，错误为 `Missing expected rejection`。该证据证明缺少 `jsonrpc`、但携带有效空目录 result 的匹配响应会被旧实现错误接受。

### 修复内容

- 对匹配 `id: 1` 和 `id: 2` 的消息强制要求 `jsonrpc === "2.0"`。
- 要求 `result` 与 `error` 恰好存在一个；错误必须为对象，并在错误响应时失败关闭。
- 初始化结果必须为对象；`plugin/list` result 继续经过目录严格校验，结构非法时失败关闭。
- 新增真实 CLI 子进程 `--check` 测试：记录数量不一致时退出码为 `4`，且被检查文件保持不变。

### GREEN 证据

```powershell
node --check .\scripts\markets\plugin-catalog.mjs
node --check .\scripts\markets\export-plugins-market.mjs
node --test .\tests\node\plugin-catalog.test.mjs *> .\.tmp\plugin-catalog-response-green.log
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\.tmp\market-task1-response-unit.log
```

- 两个 `node --check` 均退出码 `0`。
- Node 测试退出码 `0`：9 通过，0 失败。
- Pester Unit 退出码 `0`：308 通过，0 失败。

### 新 Commit SHA

`eadab19`

### 遗留顾虑

未执行账户依赖的 live `codex app-server` smoke；实验性接口若发生 schema 演进会失败关闭，避免覆盖现有市场文档。

---

## 真实 app-server / Windows npm shim 兼容性修复

### 根因

- Codex app-server 的换行 JSON 协议响应可以省略 `jsonrpc`，而采集器错误地强制要求 `jsonrpc: "2.0"`。
- Windows npm 安装的 `codex` 是 `.cmd` shim，原生 `spawn('codex')` 失败，直接 `spawn()` `.cmd` 也不具备可执行边界。

### RED 证据

```powershell
node --test .\tests\node\plugin-catalog.test.mjs *> .\.tmp\task1-live-compat-red.log
```

- 无 `jsonrpc` 的 initialize/plugin-list response 在请求 `1` 被拒绝为 `invalid JSON-RPC response`。
- 完整 `.cmd` fake app-server 子进程以 `spawn EINVAL` 失败。
- 补充的错误 envelope 与 `.ps1` 边界测试同样在旧实现上失败。

### 修复与 GREEN 证据

- `jsonrpc` 变为可选字段；存在时仍必须严格等于 `"2.0"`。
- 继续要求 result/error 恰有一个、匹配且已发出的请求 ID；error 必须含整数 `code` 与字符串 `message`。
- Windows 默认 `codex` 及显式 `.cmd`/`.bat` 通过显式 `ComSpec` shell 启动，参数固定为 `app-server --stdio`；`.exe` 和 Node 保持无 shell，`.ps1` 明确拒绝。

```powershell
node --check .\scripts\markets\plugin-catalog.mjs
node --check .\scripts\markets\export-plugins-market.mjs
node --test .\tests\node\plugin-catalog.test.mjs
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit
```

- 两个 `node --check` 均退出 `0`。
- Node 测试：14 通过，0 失败。
- Pester Unit：310 通过，0 失败。

### 真实临时采集

默认 `codex` 命令成功生成 `.tmp/market-audit/plugins_market.next.md`：marketplace `1`、记录 `2015`、唯一键 `2015`、load error `0`。

### Commit SHA

`d601ee798c3c71e60c8ec259af64ed1878579ecd`

### 遗留顾虑

Node 在受控 `ComSpec` shell 启动时会输出 `DEP0190` 安全提示；采集器没有使用默认 `shell: true`，且 shell 参数固定，不包含插件目录或认证数据。未来 Node 若移除该启动模式，需要重新验证 npm `.cmd` shim 的 stdio 转发行为。

---

## 审查修复：请求生命周期顺序

### 修改文件

- `scripts/markets/plugin-catalog.mjs`
- `tests/node/plugin-catalog.test.mjs`

### RED 证据

命令：

```powershell
node --test .\tests\node\plugin-catalog.test.mjs *> .\.tmp\plugin-catalog-ordering-red.log
```

结果：退出码 `1`。新增的 `CLI rejects an out-of-order plugin list response without overwriting output` 失败：乱序的合法 `id: 2` 空目录响应使旧 CLI 退出码为 `0`，而测试要求采集失败的退出码 `3`。这证明旧实现会接受尚未发送 `plugin/list` 请求的响应。

### 修复内容

- 明确维护 `initializeRequestSent` 与 `pluginListRequestSent` 状态，仅在相应 JSON-RPC 请求成功写入 stdin 后置位。
- 接收匹配 `id: 1` 或 `id: 2` 前先检查对应请求已发送；任何提前响应立即以采集失败关闭，不缓存、不返回目录。
- 保持上一轮 JSON-RPC 版本、`result`/`error` 互斥和结果结构校验不变。

### GREEN 证据

```powershell
node --check .\scripts\markets\plugin-catalog.mjs
node --check .\scripts\markets\export-plugins-market.mjs
node --test .\tests\node\plugin-catalog.test.mjs *> .\.tmp\plugin-catalog-ordering-green.log
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -Unit *> .\.tmp\market-task1-ordering-unit.log
```

- 两个 `node --check` 均退出码 `0`。
- Node 测试退出码 `0`：10 通过，0 失败。
- Pester Unit 退出码 `0`：308 通过，0 失败。

### 新 Commit SHA

`c7ea3d4`

### 遗留顾虑

未执行账户依赖的 live `codex app-server` smoke；实验性接口若发生 schema 演进会失败关闭，避免覆盖现有市场文档。
