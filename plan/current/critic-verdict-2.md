# Design-Critic Verdict (iteration 2)
**Mode:** on
**Mechanical check:** clean (`node ravintio-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** APPROVE

## Iteration 1 findings

| # | Iteration 1 finding | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | [major] `$PK` stays in POSIX form inside `node -e` | resolved | `req-001` FR 3 converts `project-kind.mjs` with `pwd -W`. `design.md` req-005 fixes bullet 2 states it (P1 deviation). `design.md` Assumptions names `/d/a/...`. `pack-root.sh` line 15 confirms `pwd` builds `RAVINTIO_PACK_DIR`. |
| 2 | [major] SKIP-line count contradicts itself | resolved | One rule now holds everywhere: one guard per suite, one `SKIP (windows)` line per skipped case, one README row per guard. See `req-001` FR 5, FR 8, and FR 9, AC3, `design.md` req-005 bullet 3 and the README bullet, and the glossary "Windows skip" and "Guard" entries. The rule matches the `tests/README.md` line 56 "one row, one guard" rule. |
| 3 | [minor] R-001 and R-004 mitigations state facts | resolved | R-004 now names two actions: P3 builds the path from `$FW` relative to `RAVINTIO_REPO_ROOT`, and P4 runs the suite in the source repo. R-001 now names a P4 check. See new finding 2 for what R-001 still leaves open. |
| 4 | [minor] R-002 phase differs across three artefacts | resolved | `risk-register.md` R-002, `build-log.md` P1 Decision line 87, and `design.md` Risks bullet 3 all say "after the P4 CI pass, push the branch and read the Windows shards before P7". |
| 5 | [minor] brief and requirement compare different blobs | resolved | `req-001` FR 6 checks the `HEAD` blob and the `git hash-object` id, run inside the repo so `core.autocrlf` applies. The brief's ratchet-guarded line names `HEAD` and `v0.38.0` only. The requirement adds to it and contradicts nothing. Build log line 90 records the choice. |
| 6 | [minor] stale "byte-identical" label | resolved | `req-001` FR 7 rewords the label. The current label sits at suite lines 233 and 235. |
| 7 | [minor] A-003 names the wrong drive | resolved | `execution-plan.md` A-003, `risk-register.md` A-003, and `design.md` Assumptions now name `D:\tmp\...`. |

## Rubric (fresh pass)

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | AC1 is `gh pr checks 77` on the P9 head. AC2 gives fixed counts (67 and 127) with zero SKIP lines, and `build-log.md` Baseline (P1) line 85 records both. AC3 is the shard 5 and 6 logs plus a README search for one row per suite. Each states an observable outcome. |
| 2 Traceability | pass | The `feature-brief.md` Features table holds US-001 only. `req-001` **Source:** US-001. `design.md` Product Layer lists US-001. No orphan story exists. |
| 3 ADRs record real decisions | n/a | The P1 set holds no ADRs. The P2 gate covers this row. |
| 4 Consequences are honest | n/a | The P1 set holds no ADRs. The P2 gate covers this row. |
| 5 Scope boundaries matter | pass | `scope.md` Out of Scope excludes four items. Each is a change someone could plausibly make in this fix: `project-kind.mjs` and the migrator, the 0000426 ship and gate change, backlog 0000425, and backlog 0000427. |
| 6 Risks are specific and mitigated | pass | Each risk names a file, a phase, or a backlog entry. Each mitigation names an action with its phase (R-001 P4 check, R-002 pre-P7 push, R-003 final report, R-004 P3 build and P4 run). R-001 has the status `accepted`. |
| 7 NFRs are measurable | pass | NFR-001 is 14 of 14, which matches the nine `test-suite` matrix entries and the five other jobs in `.github/workflows/ravintio.yml`. NFR-002 is 67 and 127 with 0 SKIP lines. NFR-003 is 0 files outside `mktemp -d`, checked by the `EXIT` trap and `git status`. |
| 8 Internal consistency | pass | The SKIP rule, the blob compare, and the R-002 phase now match across `design.md`, the brief, `req-001`, the register, the glossary, and the build log. The test job checks out with `fetch-depth: 0` (workflow line 204), so the `v0.38.0` dependency in `req-001` holds. `.gitattributes` sets `eol=lf` for hook files only, so the CRLF reading in A-002 is plausible for the migration file. |
| 9 Split step | pass | `req-001` has three criteria, so the fourth-criterion trigger doesn't fire. The `Split step: keep` note is present, and `build-log.md` line 86 holds the matching Decision line. |

## Findings (severity-ordered)
- [minor] `requirements/req-001-windows-safe-0000041-suites.md` FR 6: the FR names two compares but doesn't say how many assertions they feed. AC2 holds the req-005 count at 67. It stays at 67 only if both compares feed the one existing assertion. Add that both compares feed one assertion, or AC2 fails at 68. This FR isn't ratchet-guarded, so the fix is a strengthening edit.
- [minor] `risk-register.md` R-001: the P4 check shows that Linux and macOS keep the link cases. It doesn't reduce the risk of a hidden Windows defect. If you want coverage on Windows, have the guard probe `ln -s` and `test -L` and run the cases when a real link results. The risk is `accepted`, so this finding doesn't block.
- [minor] `requirements/req-001-windows-safe-0000041-suites.md` FR 4: a static `import ... from` can't take `pathToFileURL(...).href`. The fix needs a dynamic `await import(...)` under `--input-type=module`. Name the dynamic import so P3 doesn't try a static form first.
