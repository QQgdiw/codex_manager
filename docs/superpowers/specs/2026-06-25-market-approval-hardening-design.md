# Market And Approval Hardening Design

## Background

Phase 1 established the minimum closed loop for market documents, whitelist approval, scenario configs, deployment dry-run, static verification, rollback records, and credential boundaries. The remaining quality gap is not the automation core; it is the breadth and usability of the market intelligence and approval workflow.

The next work strengthens the human-facing decision layer while keeping `Resources/tool_whitelist.toml` as the only machine-readable deployment authority.

## Goals

- Provide a clearer human approval workflow before changing whitelist entries to `approved`.
- Add a TOML approval review data source that can later back a visualization, MCP tool, App, or CLI.
- Expand plugin market coverage beyond the current local/cache-derived subset.
- Expand GitHub market coverage from one representative project per week to a broad weekly candidate pool with a `stars >= 1000` hard filter.
- Reframe event collection around the user's engineering work identity, not general AI news.
- Remove or demote obsolete product events when a newer event fully supersedes them.

## Non-Goals

- Do not approve new whitelist entries automatically.
- Do not implement a UI in this pass.
- Do not perform real deployment or load/smoke verification in this pass.
- Do not treat GitHub search results as official historical trending data.
- Do not collect AI events focused only on model training, tuning, consumer entertainment, or pure benchmark marketing.

## Approval Review Model

Create `Resources/approval_review.toml` as the primary structured data source for approval decisions. Create `Resources/approval_review.md` as the human-readable companion generated from the same review model or manually kept in the same structure.

Each review entry should include these fields:

```toml
[[reviews]]
id = "plugin.example"
name = "Example"
type = "plugin"
source = "https://example.invalid/tool"
version = "1.0.0"
license = "MIT"
whitelist_status = "proposed"
implementation_method = "Codex plugin installed through the Codex plugin system."
dependencies = ["Codex CLI", "network during install"]
permissions = ["workspace read", "network"]
primary_use = "Short description of the main job this tool does."
scenario_fit = ["basic", "file"]
risk_level = "medium"
risk_reason = "Why this is medium risk."
verification_status = "static_verified"
recommended_action = "approve_later"
recommendation_reason = "Why this should or should not be approved now."
approval_command_hint = "Approve id plugin.example after reviewing risk and dependencies."
```

Allowed `recommended_action` values:

- `approve_now`
- `approve_later`
- `reject`
- `needs_review`

Allowed `risk_level` values should match the whitelist vocabulary:

- `low`
- `medium`
- `high`

This format is intentionally simple: one table array, scalar strings, and string arrays. It is easy to parse with the existing TOML reader and easy to map into a future table UI.

## Plugin Market Rework

`Resources/plugins_market.md` should be rebuilt from two source classes:

- Codex-visible plugin availability, including the user's `/plugins` view where 177 available plugins are visible.
- The public `https://github.com/openai/plugins/tree/main` repository.

The output should distinguish source visibility:

- `codex_available`
- `github_available`
- `both`
- `codex_only`
- `github_only`

The document should not assume the GitHub repository and the in-product plugin list are identical. Differences are expected and must be recorded as source divergence, not silently collapsed.

For each plugin family or plugin entry, record:

- name and stable identifier when available
- source location
- implementation method
- runtime or install dependencies
- likely permissions
- primary use
- recommended approval posture
- known gaps or fields that could not be verified

## GitHub Market Rework

`Resources/github_market.md` should become a broad candidate pool instead of a single weekly representative list.

Collection rules:

- Use `stars >= 1000` as a hard filter.
- Collect at least 20 candidates per 2026 week where the search source returns enough relevant projects.
- Deduplicate repositories across weeks. If a repository was already included in an earlier week, skip it for later weeks, do not count it toward that later week's 20-30 target, and continue down the candidate list until the weekly quota is filled or the source is exhausted.
- Preserve the method limitation: GitHub has no official historical Trending API, so results are GitHub-search-based approximate candidates, not canonical historical trending.
- Prefer projects related to engineering workflows: coding agents, developer tools, MCP, IDE integrations, automation, testing, documents, EDA-adjacent tooling, embedded workflow support, and repo operations.
- Exclude consumer-only and unrelated AI demos unless they clearly affect engineering workflows.

The output should include enough structured fields for later filtering:

- week
- repository
- stars at collection time
- created or pushed date when available
- relevance category
- why it matters
- source confidence

## Event Market Rework

`Resources/event_market.md` should be filtered through the user's engineering role.

Include events about:

- AI coding agents and developer agents
- Codex, Claude Code, GitHub Copilot, Cursor, Gemini CLI, and similar engineering tools
- MCP, plugins, skills, tool calling, and agent configuration ecosystems
- developer workflow automation
- permissions, audit, security, enterprise governance, and rollback boundaries
- long-context impact on engineering documents, datasheets, PDFs, and repo-scale analysis
- file, document, spreadsheet, browser, and research workflows used by engineering work
- hardware, embedded, FPGA, EDA, documentation, and lab-adjacent toolchain changes when relevant

Exclude events primarily about:

- model pretraining methods
- fine-tuning recipes
- benchmark-only marketing
- consumer entertainment features
- general AI funding or corporate news without engineering workflow impact
- old product versions fully superseded by a newer event

Supersession rule:

When a newer event fully supersedes an older product-release event, keep the newer event as the main record. The older event may be removed or moved to a short "superseded events" section only if it helps explain migration or compatibility risk.

Example: if GPT-5.5 is the current relevant release, GPT-5.4 should not remain a main event unless it introduced a still-relevant migration, deprecation, or compatibility boundary not covered by GPT-5.5.

## Validation

Add focused tests for the new approval review TOML:

- `Resources/approval_review.toml` parses with the existing TOML parser.
- Every `reviews[].id` exists in `Resources/tool_whitelist.toml`.
- `recommended_action` values are in the approved enum.
- `risk_level` values are in the approved enum.
- Entries include human decision fields: implementation method, dependencies, permissions, primary use, risk reason, and recommendation reason.

Existing tests for whitelist, scenario configs, deployment dry-run, verification records, and TOML parsing should continue to pass.

## Delivery

The implementation should be delivered as several small commits:

1. Add approval review TOML schema tests and initial review files.
2. Rebuild plugin market coverage from Codex-visible and GitHub-visible sources.
3. Expand GitHub market weekly candidate coverage with the `stars >= 1000` filter.
4. Rework event market around the user's engineering role and supersession rule.
5. Update state records and run final validation.

## Open Constraint

The user's `/plugins` list may only be visible inside the Codex product UI and may not be directly available through the current shell environment. If it cannot be queried programmatically, the implementation should use all accessible CLI, local cache, and GitHub sources, then explicitly record the missing `/plugins` UI source as a collection gap.
