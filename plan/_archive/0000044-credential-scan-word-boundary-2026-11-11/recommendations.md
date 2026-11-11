---
title: "Recommendations - credential-scan-word-boundary"
summary: "Suggested improvements for future iterations, from the 0000044 run."
---
# Recommendations - credential-scan-word-boundary

## Recommendations

| ID | Category | Priority | Component | Recommendation | Rationale | Effort |
|----|----------|----------|-----------|---------------|-----------|--------|
| REC-001 | security | high | repository CI | Run `credential-scan.mjs` and gitleaks on every PR. Backlog 0000435 holds the work. | The regex rule is the only scan on a machine without gitleaks, and risk R-001 counts on gitleaks as its fallback. | medium |
| REC-002 | security | medium | ravintio-framework | Add a rule for underscore-style secret keys. Backlog 0000436 holds the work. | No rule matches `sk` followed by an underscore, and the gap predates this run. | low |
| REC-003 | security | low | ravintio-framework | Add `\x` escapes and ANSI colour codes to the `api-secret-key` lookbehind. Backlog 0000437 holds the work. | The P5 re-review found both still miss, and the rule before 0000044 caught them. | low |
| REC-004 | maintainability | low | ravintio-framework | Bound the key-class run, or catch a `RangeError` per line. Backlog 0000438 holds the work. | A 10 MB line makes the scan exit 2. It fails closed, but it stops the commit. | low |
| REC-005 | testing | medium | repository CI | Rebalance the Windows shards. Backlog 0000432 holds the work. | Windows shard 3 took about 19.5 minutes of its 20-minute cap on the PR #78 rerun. | medium |
| REC-006 | testing | medium | ravintio-framework | Make the shell guard 200 ms timing check robust on Windows. Backlog 0000275 holds the work. | It failed one PR #78 shard at 278 ms with no code change. | medium |
| REC-007 | maintainability | low | ravintio-framework | Run `ravintio-refresh-setup` after PR #78 merges. | Six installed skills differ from their source copies, including the orchestrator, codegen, docs, and ship agents. | low |

## Deferred Items

| Item | Reason | Blocked until |
|------|--------|---------------|
| None new | Nothing in this run's scope was deferred. P5 filed backlogs 0000435 to 0000438 for out-of-scope findings. | n/a |

## Tech Debt

| Item | Location | Backlog |
|------|----------|---------|
| None new | The escape list in the `api-secret-key` lookbehind is a deliberate ADR-002 trade-off, recorded in the ADR amendment. | n/a |
