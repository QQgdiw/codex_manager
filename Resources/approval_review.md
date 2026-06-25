# Approval Review

`Resources/tool_whitelist.toml` remains the deployment authority. This document is a human-readable review companion only; update the whitelist to change deployable approval state.

| ID | Type | Current Status | Recommendation | Risk | Main Use | Why |
| --- | --- | --- | --- | --- | --- | --- |
| `plugin.openai-bundled.browser` | plugin | approved | approve_now | medium | In-app browser verification | Already approved for phase 1 and needed for local web checks. |
| `mcp.modelcontextprotocol.filesystem` | mcp | proposed | needs_review | high | Filesystem MCP access | Needs explicit root, write, and rollback review before enabling broad file operations. |
| `mcp.modelcontextprotocol.memory` | mcp | proposed | approve_later | medium | Persistent MCP memory | Useful later, but retention and data boundaries should be settled first. |
| `mcp.modelcontextprotocol.sequential-thinking` | mcp | approved | approve_now | medium | Structured reasoning support | Already approved and has limited external side effects compared with file or memory access. |
| `skill.context-engineering.context-fundamentals` | skill | approved | approve_now | low | Baseline context engineering guidance | Already approved, instructional, and low risk. |
| `skill.context-engineering.context-optimization` | skill | proposed | approve_later | medium | Context and prompt optimization | Useful after the base workflow is stable; license remains unknown in the whitelist. |
| `skill.context-engineering.context-compression` | skill | proposed | approve_later | medium | Context summarization guidance | Useful later for handoffs; license remains unknown in the whitelist. |
| `skill.context-engineering.filesystem-context` | skill | proposed | needs_review | medium | Filesystem-backed context gathering | Review data minimization expectations before approving filesystem-oriented guidance. |
| `skill.context-engineering.tool-design` | skill | proposed | approve_later | medium | Agent tool interface design | Relevant for future tool work; license remains unknown in the whitelist. |
| `skill.context-engineering.multi-agent-patterns` | skill | proposed | approve_later | medium | Multi-agent workflow guidance | Not required for phase 1 and can increase workflow complexity. |
| `skill.context-engineering.harness-engineering` | skill | proposed | approve_later | medium | Agent evaluation harness guidance | Useful after deployment review matures; license remains unknown in the whitelist. |
| `plugin.openai-curated.superpowers` | plugin | approved | approve_now | medium | TDD, planning, and verification workflows | Already approved and directly supports required engineering controls. |
| `plugin.openai-primary-runtime.documents` | plugin | proposed | approve_later | medium | Document artifact creation and QA | Useful when document workflows are in scope, but not needed for phase 1 approval infrastructure. |
| `plugin.openai-primary-runtime.presentations` | plugin | proposed | approve_later | medium | Presentation deck creation and QA | Useful when deck workflows are in scope, but not needed for phase 1 approval infrastructure. |
| `plugin.openai-primary-runtime.spreadsheets` | plugin | proposed | approve_later | medium | Spreadsheet artifact creation and analysis | Useful when spreadsheet workflows are in scope, but not needed for phase 1 approval infrastructure. |
