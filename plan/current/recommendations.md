---
title: "Recommendations - macos-test-job-timeout"
summary: "Suggested improvements for future iterations, from the 0000043 run."
---
# Recommendations - macos-test-job-timeout

## Recommendations

| ID | Category | Priority | Component | Recommendation | Rationale | Effort |
|----|----------|----------|-----------|---------------|-----------|--------|
| REC-001 | testing | medium | repository CI | Rebalance the Windows shards by measured suite time, or add an eighth shard. Backlog 0000432 holds the work. | Windows shard 3 took 14 min 36 s of its 20-minute cap and printed the new margin warning. Shards 6 and 7 took under 10 minutes. | medium |
| REC-002 | testing | medium | ravintio-framework | Make the 200 ms hook timing checks robust on Windows, together with backlogs 0000265 and 0000275. Backlog 0000433 holds the third case. | `test-0000032-req-003` failed one PR #77 shard at 269 ms with no code change. | medium |
| REC-003 | maintainability | high | ravintio-framework | Limit the `run-mode.mjs` history walk to the current run. Backlog 0000427 holds the work. | This run read as `interactive` again after its own anchor commit, as in 0000042. | medium |
| REC-004 | maintainability | high | ravintio-framework | Read the PR checks before the P7 archive in the ship sequence. Backlog 0000426 holds the work. | This run and 0000042 both needed their own ADR-004 to keep a CI fix possible before the archive. | medium |
| REC-005 | maintainability | low | repository CI | Move `actions/checkout` to a release that targets Node.js 24. Backlog 0000434 holds the work. | Every job in run `42490766491` carries a Node.js 20 deprecation annotation. | low |
| REC-006 | testing | low | repository CI | Use the elapsed lines to watch the macOS margin. If a macOS shard passes 10 minutes, add a third shard as ADR-002 describes. | The shards take 6.5 and 4.7 minutes now, and each new suite adds time. | low |
| REC-007 | maintainability | low | ravintio-framework | Run `ravintio-refresh-setup` after PR #77 merges. | Six installed skills differ from their source copies, including the orchestrator, codegen, docs, and ship agents. | low |

## Deferred Items

| Item | Reason | Blocked until |
|------|--------|---------------|
| None new | Nothing in this run's scope was deferred. Backlogs 0000425, 0000426, 0000427, and 0000428 predate this run. | n/a |

## Tech Debt

| Item | Location | Backlog |
|------|----------|---------|
| None new | The step-extraction coupling in `test-0000043-req-002-job-margin.sh` is a deliberate ADR-003 trade-off, recorded in `src/ravintio-framework/docs/quirks.md`. | n/a |
