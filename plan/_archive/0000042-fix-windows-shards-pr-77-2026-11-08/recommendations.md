---
title: "Recommendations - fix-windows-shards-pr-77"
summary: "Suggested improvements for future iterations, from the 0000042 run."
---
# Recommendations - fix-windows-shards-pr-77

## Recommendations

| ID | Category | Priority | Component | Recommendation | Rationale | Effort |
|----|----------|----------|-----------|---------------|-----------|--------|
| REC-001 | maintainability | high | ravintio-framework | Limit the `run-mode.mjs` history walk to the current run. Backlog 0000427 holds the work. | The 0000041 P7 archive commit makes every later autonomous run read as `interactive`, so skills fall back to interactive stops. | medium |
| REC-002 | maintainability | high | ravintio-framework | Read the PR checks before the P7 archive in the ship sequence, or let `gate-write` read the archived design during a P9 fix. Backlog 0000426 holds the work. | This run read the checks before P7 by its own ADR-004. The ship skill still reads them only at P9. | medium |
| REC-003 | security | medium | ravintio-framework | Give every suite one scratch-folder helper that stops on a failed `mktemp`. Backlog 0000429 holds the work. | Nine suites use the `cd "$(mktemp ...)"` form that S-1 showed can name the caller's folder. | medium |
| REC-004 | testing | medium | ravintio-framework | Shard the macOS test job or raise its timeout. Backlog 0000430 holds the work. | Two macOS runs on PR #77 took over 14 minutes, and one hit the 15-minute timeout. | low |
| REC-005 | testing | low | ravintio-framework | Pin the 0000040 req-007 archive check to its own pass. Backlog 0000428 holds the work. | The check fails in every local P4 on a feature branch after a P7. | low |
| REC-006 | testing | low | ravintio-framework | Test the Windows link refusal with a real junction from `mklink /J`. Backlog 0000431 holds the work. | ADR-002 skips the link cases on Windows, so no Windows run checks link refusal (security finding S-2). | medium |
| REC-007 | maintainability | low | ravintio-framework | Run `ravintio-refresh-setup` after PR #77 merges. | Six installed skills differ from their source copies, including the orchestrator, codegen, docs, and ship agents. | low |

## Deferred Items

| Item | Reason | Blocked until |
|------|--------|---------------|
| None new | Backlog 0000426 stays open for its ship and gate change, and 0000425 for the `release.yml` false positive. Both predate this run. | n/a |

## Tech Debt

| Item | Location | Backlog |
|------|----------|---------|
| No Windows coverage of link refusal in `project-kind.mjs` and the 0.39.0 migration | `src/ravintio-framework/tests/test-0000041-req-005-applies-to-header.sh`, `test-0000041-req-006-consumer-migration.sh` | 0000431 |
