# Plugins 市场

> 采集时间：2026-06-23
> 采集范围：当前会话可见的 OpenAI/Codex 插件缓存与 Codex CLI 插件市场能力。
> 当前结论：本次只生成 `proposed` 白名单候选，不自动批准、不自动安装。

## 采集证据

- `codex --version`：`codex-cli 0.139.0`。
- `codex plugin marketplace list --json`：`marketplaces` 为空。
- `codex plugin list --available --json`：`installed` 和 `available` 均为空。
- `git ls-remote https://github.com/openai/codex.git HEAD`：`d2484697b1f9ce33d1d818ccad859ca3a4d721c6`。
- 浅克隆 `openai/codex` 到临时目录后确认同一 commit；该仓库当前未枚举出 `.codex-plugin/plugin.json`。
- `openai/codex` 源码中存在 `openai-curated-remote` 与工具建议允许列表，但该列表只是发现/推荐策略，不等同于本机 CLI 可安装市场清单。
- 本机 `$CODEX_HOME/plugins/cache` 下存在 5 个可读 `plugin.json` manifest，可作为本次首批候选来源。

## 采集边界

- 未读取、复制或记录 `auth.json` 内容。
- 本次未执行真实插件安装，也未写入用户级 Codex 配置。
- 因 CLI 当前不能列出远程 available catalog，本文件不声称远程市场完整清单已被采集。
- 白名单中的 `sha256` 字段记录的是本机 `plugin.json` manifest 哈希，用于固定本次采集证据；不是完整插件包哈希。批准部署前需要补齐可安装来源与完整包级校验。

## 候选插件

| ID | 名称 | 市场/来源 | 版本 | 能力 | 相关度 | 成熟度 | 风险 | 状态 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `plugin.openai-bundled.browser` | Browser | `openai-bundled` 本机缓存；manifest repository 指向 `https://github.com/openai/openai/tree/master/lib/browser_use/plugin` | `26.609.41114` | in-app browser 控制；本地页面导航、点击、输入、截图和验证 | 高 | 当前会话已启用 | 可交互读写浏览器；可能访问外部站点；需要限制目标 URL 与敏感输入 | `proposed` |
| `plugin.openai-curated.superpowers` | Superpowers | `openai-curated` 本机缓存；manifest repository 指向 `https://github.com/obra/superpowers` | `5.1.3` | 计划、TDD、调试、子代理、复审等开发流程技能 | 高 | 当前会话已启用 | 会影响代理工作流；技能指令质量直接影响执行路径 | `proposed` |
| `plugin.openai-primary-runtime.documents` | Documents | `openai-primary-runtime` 本机缓存；manifest repository 指向 `https://github.com/openai/openai` | `26.601.10930` | 创建、编辑、渲染与验证文档工件 | 中 | 当前会话已启用 | 写文件能力；需限制输出目录和渲染临时文件 | `proposed` |
| `plugin.openai-primary-runtime.presentations` | Presentations | `openai-primary-runtime` 本机缓存；manifest repository 指向 `https://github.com/openai/openai` | `26.601.10930` | 创建、编辑、渲染与导出演示文稿 | 中 | 当前会话已启用 | 写文件能力；可能生成大量二进制工件 | `proposed` |
| `plugin.openai-primary-runtime.spreadsheets` | Spreadsheets | `openai-primary-runtime` 本机缓存；manifest repository 指向 `https://github.com/openai/openai` | `26.601.10930` | 创建、编辑、分析和渲染表格工件 | 中 | 当前会话已启用 | 写文件能力；公式和数据处理需防止泄露敏感数据 | `proposed` |

## 排除和暂缓项

- `openai-curated-remote`：源码中可见远程 catalog 名称和部分建议 ID，但本机 CLI 不能列出远程 available catalog，因此暂不写入白名单。
- `github@openai-curated-remote`、`gmail@openai-curated-remote`、`google-drive@openai-curated-remote` 等：只在工具建议允许列表中出现，缺少可安装 manifest、版本、许可证与包级哈希，暂缓。
- `openai/codex` 仓库本身：已固定 commit 用于验证 CLI 行为和源码线索，但不是本次可安装插件市场目录。

## 后续批准前检查

1. 对候选项取得可重复安装来源，优先使用 `codex plugin marketplace add <source> --ref <version> --json` 可执行的源。
2. 将 `sha256` 从 manifest 哈希升级为完整发布包或目录快照哈希。
3. 用隔离 `$CODEX_HOME` 执行 dry-run 或模拟安装，确认不会写入用户真实配置。
4. 对 Browser 类插件补充 URL 范围和敏感输入限制。
5. 对文档类插件补充输出目录、临时文件清理和大文件上限。
