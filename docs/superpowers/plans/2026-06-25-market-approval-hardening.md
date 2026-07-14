# Market Approval Hardening Implementation Plan

> **已被 2026-07-13 设计取代：** 本文件仅保留历史实施计划，不得继续按其中的 Plugins 来源或执行步骤实施。当前设计见 [市场文档质量审计与整理设计](../specs/2026-07-13-market-document-quality-audit-design.md)。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Strengthen Phase 1 market intelligence and approval review artifacts so the user can make informed whitelist decisions and future UI/MCP automation can consume structured TOML review data.

**Architecture:** Keep `Resources/tool_whitelist.toml` as the only deployment authority. Add `Resources/approval_review.toml` as a structured review source and `Resources/approval_review.md` as the human-readable companion. Rebuild market documents from accessible source evidence, preserving source limitations and avoiding automatic approvals.

**Tech Stack:** Windows PowerShell 5.1, Python standard library, existing TOML parser `scripts/python/toml_to_json.py`, Pester 3.4 tests, Markdown, TOML, Git, GitHub API or git clone where available.

---

## File Structure

- `Resources/approval_review.toml`: new machine-readable approval review data.
- `Resources/approval_review.md`: new human approval companion table.
- `tests/unit/ApprovalReview.Tests.ps1`: new unit tests for review TOML schema and whitelist ID alignment.
- `Resources/plugins_market.md`: rebuild with Codex-visible, local cache, and GitHub-visible plugin coverage.
- `Resources/github_market.md`: expand weekly GitHub candidate pool with `stars >= 1000` and cross-week dedupe.
- `Resources/event_market.md`: rework event list around the user's engineering role and supersession rule.
- `state/LOG.md`, `state/TODO.md`, `state/README.md`: update progress and residual limitations.

Temporary source data may be generated under `.tmp/market-hardening/` during implementation. Do not commit `.tmp` data.

---

### Task 1: Approval Review Schema And Initial Data

**Files:**
- Create: `Resources/approval_review.toml`
- Create: `Resources/approval_review.md`
- Create: `tests/unit/ApprovalReview.Tests.ps1`

- [ ] **Step 1: Write the failing approval review tests**

Create `tests/unit/ApprovalReview.Tests.ps1` with these checks:

```powershell
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tomlLibrary = Join-Path $projectRoot 'scripts\lib\Read-Toml.ps1'

function Get-ApprovalReviewErrors {
    param(
        [Parameter(Mandatory = $true)][object]$ReviewDocument,
        [Parameter(Mandatory = $true)][object]$WhitelistDocument
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $allowedActions = @('approve_now', 'approve_later', 'reject', 'needs_review')
    $allowedRisk = @('low', 'medium', 'high')
    $requiredStrings = @(
        'id', 'name', 'type', 'source', 'version', 'license',
        'whitelist_status', 'implementation_method', 'primary_use',
        'risk_level', 'risk_reason', 'verification_status',
        'recommended_action', 'recommendation_reason', 'approval_command_hint'
    )
    $requiredArrays = @('dependencies', 'permissions', 'scenario_fit')

    $whitelistIds = @{}
    foreach ($tool in @($WhitelistDocument.tools)) {
        $whitelistIds[$tool.id] = $tool
    }

    if ($ReviewDocument.PSObject.Properties['reviews'] -eq $null -or
        $ReviewDocument.reviews -isnot [System.Array]) {
        $errors.Add("approval_review.toml must contain a reviews array.")
        return ,($errors.ToArray())
    }

    $seen = @{}
    foreach ($review in @($ReviewDocument.reviews)) {
        foreach ($field in $requiredStrings) {
            $property = $review.PSObject.Properties[$field]
            if ($null -eq $property -or $property.Value -isnot [string] -or
                [string]::IsNullOrWhiteSpace($property.Value)) {
                $errors.Add("review field '$field' must be a non-empty string.")
            }
        }
        foreach ($field in $requiredArrays) {
            $property = $review.PSObject.Properties[$field]
            if ($null -eq $property -or $property.Value -isnot [System.Array]) {
                $errors.Add("review field '$field' must be an array.")
                continue
            }
            foreach ($value in @($property.Value)) {
                if ($value -isnot [string] -or [string]::IsNullOrWhiteSpace($value)) {
                    $errors.Add("review field '$field' contains an empty value.")
                }
            }
        }

        if ($review.id -and $seen.ContainsKey($review.id)) {
            $errors.Add("duplicate review id '$($review.id)'.")
        }
        elseif ($review.id) {
            $seen[$review.id] = $true
        }

        if ($review.id -and -not $whitelistIds.ContainsKey($review.id)) {
            $errors.Add("review id '$($review.id)' is not present in tool_whitelist.toml.")
        }
        if ($review.recommended_action -and
            $allowedActions -notcontains $review.recommended_action) {
            $errors.Add("review '$($review.id)' has invalid recommended_action.")
        }
        if ($review.risk_level -and $allowedRisk -notcontains $review.risk_level) {
            $errors.Add("review '$($review.id)' has invalid risk_level.")
        }
    }

    return ,($errors.ToArray())
}

Describe 'Approval review data' {
    BeforeAll {
        . $tomlLibrary
    }

    It 'parses and validates the project approval review data' {
        $review = Read-ProjectToml -Path (
            Join-Path $projectRoot 'Resources\approval_review.toml'
        )
        $whitelist = Read-ProjectToml -Path (
            Join-Path $projectRoot 'Resources\tool_whitelist.toml'
        )

        $errors = Get-ApprovalReviewErrors -ReviewDocument $review `
            -WhitelistDocument $whitelist

        ($errors -join "`n") | Should Be ''
        @($review.reviews).Count | Should BeGreaterThan 0
    }

    It 'rejects bad actions and review ids' {
        $whitelist = Read-ProjectToml -Path (
            Join-Path $projectRoot 'Resources\tool_whitelist.toml'
        )
        $review = [pscustomobject]@{
            reviews = @([pscustomobject]@{
                id = 'missing.tool'
                name = 'Missing'
                type = 'plugin'
                source = 'https://example.invalid'
                version = '1.0.0'
                license = 'MIT'
                whitelist_status = 'proposed'
                implementation_method = 'none'
                dependencies = @('Codex')
                permissions = @('none')
                primary_use = 'invalid sample'
                scenario_fit = @('basic')
                risk_level = 'unknown'
                risk_reason = 'invalid risk'
                verification_status = 'not_verified'
                recommended_action = 'maybe'
                recommendation_reason = 'invalid action'
                approval_command_hint = 'do not approve'
            })
        }

        $errors = Get-ApprovalReviewErrors -ReviewDocument $review `
            -WhitelistDocument $whitelist

        ($errors -join "`n") | Should Match 'missing.tool'
        ($errors -join "`n") | Should Match 'recommended_action'
        ($errors -join "`n") | Should Match 'risk_level'
    }
}
```

- [ ] **Step 2: Run the failing test**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit *> .\task-approval-review-red.log
```

Expected: FAIL because `Resources/approval_review.toml` does not exist.

- [ ] **Step 3: Create initial `approval_review.toml`**

Create one review entry per current whitelist tool. Use actual values from `Resources/tool_whitelist.toml`; do not invent new IDs. Include at least these recommendations:

- `plugin.openai-bundled.browser`: `approve_now`, because browser retrieval is required in all scenarios and already approved.
- `plugin.openai-curated.superpowers`: `approve_now`, because it supports the development workflow and is already approved.
- `mcp.modelcontextprotocol.sequential-thinking`: `approve_now`, because it provides reasoning workflow support and is already approved.
- `skill.context-engineering.context-fundamentals`: `approve_now`, because it is low risk and already approved.
- `mcp.modelcontextprotocol.filesystem`: `needs_review`, because filesystem access is high risk.
- `mcp.modelcontextprotocol.memory`: `approve_later`, because persistent memory is useful but not required for the current minimal workflow.
- `plugin.openai-primary-runtime.documents`, `presentations`, `spreadsheets`: `approve_later`, because they fit file workflows but are not needed for the current approved baseline.

All other entries should use `approve_later` or `needs_review` with a concrete reason.

- [ ] **Step 4: Create `approval_review.md`**

Create a compact Markdown companion with columns:

```markdown
| ID | Type | Current Status | Recommendation | Risk | Main Use | Why |
|---|---|---|---|---|---|---|
```

The Markdown should be readable without scripts and should state that `tool_whitelist.toml` remains the deployment authority.

- [ ] **Step 5: Run approval review tests**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit *> .\task-approval-review-green.log
```

Expected: PASS with zero failed tests.

- [ ] **Step 6: Commit**

```powershell
git add Resources\approval_review.toml Resources\approval_review.md tests\unit\ApprovalReview.Tests.ps1
git diff --cached --check
git commit -m "feat[approval]: add structured review data"
```

---

### Task 2: Plugin Market Rebuild

**Files:**
- Modify: `Resources/plugins_market.md`
- Optionally create temporary scripts under `.tmp/market-hardening/` and do not commit them.

- [ ] **Step 1: Collect accessible plugin sources**

Run accessible CLI/local checks first:

```powershell
codex plugin list --available --json *> .\.tmp\market-hardening\codex-plugin-available.json
codex plugin marketplace list --json *> .\.tmp\market-hardening\codex-plugin-marketplace.json
Get-ChildItem -LiteralPath "$env:USERPROFILE\.codex\plugins\cache" -Recurse -Filter plugin.json |
    Select-Object -ExpandProperty FullName |
    Set-Content -LiteralPath .\.tmp\market-hardening\local-plugin-manifests.txt -Encoding UTF8
```

If a command returns empty or unsupported output, record that limitation in `plugins_market.md`.

- [ ] **Step 2: Clone or update the OpenAI plugins repository**

Use an approved network command if available; otherwise request escalation when sandbox blocks network:

```powershell
git clone https://github.com/openai/plugins.git .\.tmp\market-hardening\openai-plugins
```

If the directory already exists, use:

```powershell
git -C .\.tmp\market-hardening\openai-plugins pull --ff-only
```

- [ ] **Step 3: Generate a plugin inventory**

Use PowerShell to enumerate plugin manifests and obvious plugin directories from the cloned repository and local cache. Write temporary CSV or JSON under `.tmp/market-hardening/`.

Required output fields:

- stable ID when available
- display name
- source class: `codex_available`, `github_available`, `both`, `codex_only`, `github_only`, or `local_cache_only`
- source path or URL
- implementation method
- dependency notes
- likely permissions
- primary use
- approval posture
- verification gap

- [ ] **Step 4: Rewrite `Resources/plugins_market.md`**

The document must include:

- Collection timestamp and sources.
- Source divergence section explaining why `/plugins`, CLI JSON, local cache, and GitHub may differ.
- Summary counts by source class.
- A table or grouped sections for plugin candidates.
- Approval recommendations that align with `approval_review.toml`.
- Explicit gaps for unavailable `/plugins` UI data if CLI cannot reproduce the 177-item list.

- [ ] **Step 5: Validate and commit**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit *> .\task-plugin-market-unit.log
git diff --check
```

Expected: unit tests pass and diff check is clean.

Commit:

```powershell
git add Resources\plugins_market.md
git diff --cached --check
git commit -m "docs[market]: rebuild plugin source coverage"
```

---

### Task 3: GitHub Market Expansion

**Files:**
- Modify: `Resources/github_market.md`
- Optionally create temporary scripts under `.tmp/market-hardening/` and do not commit them.

- [ ] **Step 1: Write the collection script**

Create a temporary PowerShell script under `.tmp/market-hardening/fetch-github-market.ps1` that:

- Iterates ISO weeks for 2026 up to the current week.
- Uses GitHub Search API or `gh api` if available.
- Applies `stars:>=1000`.
- Pulls more than the target per week, for example top 100, so dedupe can fill 20-30 unique entries.
- Tracks a global `seenRepos` set.
- Skips any repository already included in an earlier week.
- Does not count skipped duplicates toward the weekly quota.
- Stops each week when 20-30 unique relevant candidates are selected or source data is exhausted.

- [ ] **Step 2: Run collection**

Run the script and save raw output under `.tmp/market-hardening/github-market-raw.json`.

If network access is blocked, rerun with escalation as required by the environment instructions.

- [ ] **Step 3: Filter for engineering relevance**

Keep candidates related to:

- coding agents
- developer tools
- MCP or tool calling
- IDE/editor integrations
- automation/testing
- document/data workflows
- repo operations
- embedded, hardware, FPGA, or EDA-adjacent development support

Exclude unrelated consumer demos and generic AI apps.

- [ ] **Step 4: Rewrite `Resources/github_market.md`**

The document must include:

- Collection method and limitations.
- `stars >= 1000` hard filter statement.
- Cross-week dedupe statement.
- Weekly sections with up to 20-30 unique repositories.
- Per entry: repository, stars at collection time, date field used, relevance category, why it matters, source confidence.
- A short list of weeks where fewer than 20 relevant unique candidates were available, if any.

- [ ] **Step 5: Validate and commit**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit *> .\task-github-market-unit.log
git diff --check
```

Expected: unit tests pass and diff check is clean.

Commit:

```powershell
git add Resources\github_market.md
git diff --cached --check
git commit -m "docs[market]: expand github candidate coverage"
```

---

### Task 4: Event Market Rework

**Files:**
- Modify: `Resources/event_market.md`

- [ ] **Step 1: Collect event sources**

Use official or high-trust sources first:

- OpenAI official release pages and Codex documentation.
- Anthropic official Claude Code and MCP-related pages.
- GitHub Blog, GitHub Changelog, and Microsoft developer tooling announcements.
- Google AI developer announcements for Gemini CLI/API changes that affect engineering workflows.
- MCP official announcements and repository releases.
- Cursor or other developer-tool official changelogs when directly relevant.
- arXiv or peer-reviewed papers only when they discuss developer workflow adoption, tooling, or governance, not model training internals.

- [ ] **Step 2: Apply engineering-role filter**

Include only events that affect:

- coding agents
- tools available to the developer
- configuration and approval workflows
- permissions, security, audit, or governance
- long-context engineering document use
- browser, PDF, Word, Excel, spreadsheet, and repo-scale workflows
- embedded, hardware, FPGA, EDA, or datasheet-heavy workflows

Exclude pure model training, fine-tuning, benchmark-only, consumer entertainment, and unrelated corporate news.

- [ ] **Step 3: Apply supersession rule**

For each product line, keep the latest relevant event as the main event when it fully supersedes older releases. Move older events to a "Superseded or background events" section only when they explain migration or compatibility risk.

Example: a current GPT-5.5 engineering release supersedes GPT-5.4 as a main event unless GPT-5.4 introduced a still-active API migration or compatibility boundary.

- [ ] **Step 4: Rewrite `Resources/event_market.md`**

The document must include:

- Collection timestamp.
- Scope statement centered on the user's engineering work.
- Main events grouped by vendor or workflow category.
- Superseded/background section.
- Each event split into facts, engineering impact, project impact, and limitations.
- Source URLs.

- [ ] **Step 5: Validate and commit**

Run:

```powershell
powershell -NoProfile -File .\tests\Run-Tests.ps1 -Unit *> .\task-event-market-unit.log
git diff --check
```

Expected: unit tests pass and diff check is clean.

Commit:

```powershell
git add Resources\event_market.md
git diff --cached --check
git commit -m "docs[market]: refocus engineering event coverage"
```

---

### Task 5: Final State And Full Validation

**Files:**
- Modify: `state/README.md`
- Modify: `state/TODO.md`
- Modify: `state/LOG.md`

- [ ] **Step 1: Run full tests**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1 -All *> .\task-market-hardening-all.log
```

Expected: all tests pass with zero failures.

- [ ] **Step 2: Validate all TOML**

Run:

```powershell
Get-ChildItem .\Resources\*.toml | ForEach-Object {
    python .\scripts\python\toml_to_json.py $_.FullName *> $null
    if ($LASTEXITCODE -ne 0) { throw "Invalid TOML: $($_.FullName)" }
}
```

Expected: no exception.

- [ ] **Step 3: Scan sensitive content and placeholders**

Run:

```powershell
rg -n "TBD|TODO|PLACEHOLDER|api[_-]?key\s*=|token\s*=|password\s*=|authorization\s*=|Bearer\s+" Resources Notes state
```

Expected: no unreviewed placeholders and no plaintext credentials. References in instructions or examples must be explicitly explained in the final state log.

- [ ] **Step 4: Update state files**

Update:

- `state/README.md`: describe the approval review TOML and market hardening state.
- `state/TODO.md`: mark market hardening tasks complete and keep real deployment/load-smoke verifier as future work.
- `state/LOG.md`: record test results, source limitations, and known gaps.

- [ ] **Step 5: Commit state update**

```powershell
git add state\README.md state\TODO.md state\LOG.md
git diff --cached --check
git commit -m "docs[state]: record market hardening validation"
```

---

## Execution Notes

- Do not commit `.tmp/market-hardening` data.
- Do not change any `approval` value in `Resources/tool_whitelist.toml` unless the user explicitly approves tool IDs.
- Do not claim `/plugins` UI coverage if it cannot be queried programmatically.
- Do not claim GitHub candidate pools are official historical trending.
- Do not keep obsolete model release events as main events when a newer event fully supersedes them.
