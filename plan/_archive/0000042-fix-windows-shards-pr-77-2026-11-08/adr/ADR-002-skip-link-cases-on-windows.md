---
title: "ADR 002: Skip link cases on Windows"
summary: "The 0000041 suites skip their link cases on Windows behind one guard per suite. Linux and macOS keep the link coverage."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Skip link cases on Windows

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000042-fix-windows-shards-pr-77
**Component:** ravintio-framework
**Date:** 2026-11-08

## Context

Five cases in the two 0000041 suites build a symbolic link with `ln -s`. Under Git Bash, `ln -s` makes a copy unless `MSYS=winsymlinks:nativestrict` is set. A real Windows link also needs Developer Mode or an elevated shell. The copy is a plain file or folder, so `project-kind.mjs` and the migrator treat it as the real thing, and the "linked" cases fail.

Other suites already skip link cases on Windows and print `SKIP (windows): {reason}`. `tests/README.md` lists each guard in its Windows skip table, one row per guard.

## Decision

Each suite gets one `IS_WIN` guard around its link cases.

- The req-005 suite moves its four link cases into one block. On Windows, the guard prints one `SKIP (windows)` line for each case.
- The req-006 suite puts Case 6 behind its guard and prints one `SKIP (windows)` line.
- `tests/README.md` gains one row per guard.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Set `MSYS=winsymlinks:nativestrict` in the suites | Runs the link cases on Windows | Fails without Developer Mode or admin rights, and no other suite does it | The runner's link rights aren't a contract the pack can rely on |
| Probe with `ln -s` and `test -L`, then run the cases when a real link results | Runs the cases wherever links work | Adds a case path that this run can't test on any runner it has | The `windows-latest` runner gives no real links to Git Bash today, so the probe path would never run in CI and its own faults would stay unseen |
| One guard per case, four in the req-005 suite | No reordering of cases | Four README rows for one cause | One guard per cause keeps the skip table short |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | The req-005 suite reorders four cases. Both suites gain a guard. `tests/README.md` gains two rows. |

## Consequences

**Positive:**
- Both Windows shards can pass without a change to `project-kind.mjs` or the migrator.
- Each skipped case still names itself in the log.

**Negative:**
- Windows gives no link coverage for `project-kind.mjs` or the 0.39.0 consumer migration.

**Risks:**
- A Windows-only link defect would go unseen. R-001 in the risk register tracks it.

## Related ADRs

- ADR-001 - depends-on

## Supersedes

- None

## Superseded By

- None
