# Design-Critic Verdict (iteration 2)
**Mode:** on
**Mechanical check:** clean (`node ravintio-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** REJECT

Phase is P1. No ADRs exist, so rubric items 3 and 4 are not applicable. Rubric item 8 still fails on two contradictions. Seven of the eight iteration 1 findings are resolved.

## Status of iteration 1 findings

| # | Iteration 1 finding | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | req-006 guard scheduled for P3 but needs P6 docs work | Partly resolved | `execution-plan.md` Build order step 3 moves req-007's live-doc rewrites into P3. The decisions-index notes still land at P6 (step 5). See new finding 1. |
| 2 | Closed allowlist misses live matches | Resolved | `req-006` "P1 critic revision adds these entries" covers the change-agent archive suite, its manifest line, the absence-check suites and every suite in req-002's rewrite table. |
| 3 | Files with more than one owner | Mostly resolved | `execution-plan.md` "File ownership" gives each file one owner and says it replaces the build-log Decision line. The requirement files still state the old split. See new finding 2. |
| 4 | `scope.md` says four ADRs | Resolved | `scope.md` In Scope adds a "P1 clarification" line that states five ADRs. It governs the earlier line. |
| 5 | req-007 omits `quirks.md` and `tech-debt.md` | Resolved | `req-007` "P1 critic revision" adds both to the rewrite list. |
| 6 | `.gitignore` lines have no owner | Resolved | `req-006` names req-002 as owner. The ownership table lists `.gitignore` under req-002. |
| 7 | Shallow clone has no mitigation | Resolved | `risk-register.md` R-011 and `req-003` line 27 add a fail-closed check, a `fetch-depth: 0` message and a shallow-clone fixture. |
| 8 | req-006 AC3 bundles two checks | Resolved | `req-006` records "Split step for the third criterion: keep" with a reason. `build-log.md` line 123 holds the matching Decision line. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC in req-001 to req-007 names an observable result and a `Verified by:` method. Example: req-004 AC2 names the `(retired, removed)` line per path. |
| 2 Traceability | pass | Each requirement has a `Source:` of US-001, US-002 or US-003. The execution plan table maps all seven. The brief holds three stories and no orphan. |
| 3 ADRs record real decisions | n/a | No ADRs at P1. |
| 4 Consequences are honest | n/a | No ADRs at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes 0000359, 0000308, 0000361 and the 0000355 re-routing. Someone could plausibly build each. |
| 6 Risks specific and mitigated | pass | R-001 to R-011 each name a concrete failure and an action. R-008 is accepted and says so. |
| 7 NFRs measurable | pass | NFR-001 to NFR-004 in `execution-plan.md` give counts or named suites. |
| 8 Internal consistency | fail | See findings 1 and 2. |
| 9 Split step | pass | Each requirement holds three ACs and carries a `Split step: keep` note. `build-log.md` lines 95 to 123 hold a matching Decision line for all seven. |

## Findings (severity-ordered)
- [major] `requirements/req-006-residue-guard.md`, `requirements/req-007-docs-and-adr-supersede.md`, `execution-plan.md`: the guard still cannot pass at the end of P3. The plan runs req-006 last in P3 over a finished tree. Build order step 5 and req-007 defer the decisions-index notes to P6. Today `docs/decisions-index.md` lines 148, 320, 335 and 337 match the patterns and hold no `supersed` text. The req-006 allowlist covers only decisions-index lines that hold `[Ss]upersed`. The same holds for `docs/architecture-overview.md` lines 253 to 299, 492 and 547 to 552 unless req-007's P3 rewrite adds the note on those lines. Either move the decisions-index status edits into P3 (the P2 ADR numbers exist by then), or state that the full-tree pass moves to P6 and that req-006 AC1 and req-007 AC1 run there.
- [major] `requirements/req-001-one-track-routing.md` and `req-004-remove-track-files.md`: both requirements still claim files that the ownership table gives to req-007, with no clarifying line that narrows them. req-001 edits `getting-started.md` lines 103 and 104, `pipeline-reference.md`, `src/setup-hook-integration/docs/scope.md` and `README.md` line 138. req-004 edits `README.md` line 112 and `tool-setup-reference.md`. req-001 AC2 asserts `getting-started.md`, `scope.md` and `pipeline-reference.md` are free of the words. Build order puts req-007's rewrites after req-001, so that criterion cannot pass at req-001's step. req-002 line 61 also tells the `standard-boot.md` edit to req-002, though the table gives it to req-001. Add a line to req-001, req-002 and req-004 that names the table as governing. Narrow req-001 AC2 to the files req-001 owns, or move its verification after req-007.
- [minor] `requirements/req-007-docs-and-adr-supersede.md`: AC1 and AC2 verify "After P6" while the plan places the live-doc rewrites in P3. State which criterion runs at which phase, so the P3 exit does not rely on a P6 check.
- [minor] `requirements/req-006-residue-guard.md`: the entry "Every suite in req-002's rewrite table" is open to a stale-entry failure. The table row for `test-0000035-req-009-fast-path-enforcement-paths.sh` says "rewrite or retire" depending on Q-001. Say that a retired suite's entry is dropped, so the stale-entry check does not fail on it.
