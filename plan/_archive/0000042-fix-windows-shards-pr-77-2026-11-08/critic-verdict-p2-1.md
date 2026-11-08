# Design-Critic Verdict (iteration 1, P2 gate)
**Mode:** on
**Mechanical check:** clean (`node ravintio-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** REJECT

Scope: the combined P1 and P2 set for 0000042-fix-windows-shards-pr-77. P1 passed on iteration 2 (`critic-verdict-2.md`). This pass re-checks the P1 rows against the ADRs and judges rows 3 and 4 for the first time.

## Iteration 2 (P1) findings carried forward

| # | P1 iteration 2 finding | Status | Evidence |
|---|------------------------|--------|----------|
| 1 | [minor] FR 6 doesn't say how many assertions the two compares feed | resolved | `req-001` FR 7: "Both blob compares feed one assertion, so the suite's case count stays at 67." |
| 2 | [minor] R-001 mitigation doesn't reduce the Windows risk | accepted | `risk-register.md` R-001 status `accepted`. ADR-002 alternative 2 records the `test -L` probe and its rejection. |
| 3 | [minor] FR 4 static import can't take `pathToFileURL(...).href` | resolved | `req-001` FR 4 names `await import(pathToFileURL(...).href)` under `--input-type=module`. `test-0000036-req-008-non-regular-design-md.sh` line 296 uses the same form. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | AC1 is `gh pr checks 77` on the P9 head. AC2 fixes the counts at 67 and 127 with zero SKIP lines, and `build-log.md` Baseline (P1) records both on macOS. AC3 is the shard 5 and 6 logs plus a README search. |
| 2 Traceability | pass | The brief's Features table holds US-001 only. `req-001` **Source:** US-001. `design.md` Product Layer lists US-001. |
| 3 ADRs record real decisions | fail | ADR-002, ADR-003, and ADR-004 each name two or three genuine alternatives with reasons. ADR-001 rejects `cygpath -m` on a false premise. See finding 1. |
| 4 Consequences are honest | fail | ADR-002 (no Windows link coverage) and ADR-004 (a 15-minute CI wait, and the rebuild-head residual) state negatives that hurt. ADR-001 and ADR-003 do not. See findings 2 and 3. |
| 5 Scope boundaries matter | pass | `scope.md` Out of Scope excludes `project-kind.mjs` and the migrator, the 0000426 ship and gate change, backlog 0000425, and backlog 0000427. Each is a plausible change in this fix. ADR-004 Alternatives repeats the 0000426 exclusion. |
| 6 Risks are specific and mitigated | pass | R-001 to R-004 each name a file, a phase, or a backlog entry, and each mitigation is an action. ADR-004 adds a residual risk that the register lacks. See finding 5. |
| 7 NFRs are measurable | pass | NFR-001 is 14 of 14. The workflow holds nine `test-suite` matrix legs plus `validate-branch`, `self-description-check`, two PowerShell jobs, and `release-copy-integrity`. NFR-002 is 67 and 127 with 0 SKIP lines. NFR-003 is 0 files outside `mktemp -d`. |
| 8 Internal consistency | pass | ADR-002 matches `req-001` FR 5, FR 8, and FR 9 (one guard per suite, one SKIP line per case, two README rows). ADR-002 Context counts five link cases, and the suites hold four (req-005 lines 94, 109, 113, 117) plus one (req-006 line 371). ADR-003 matches FR 6 and FR 7. ADR-004 matches `design.md` Risks bullet 3, R-002, and the P1 Decision line. It adds a stricter P5 entry rule and contradicts none of them. |
| 9 Split step | pass | `req-001` has three criteria, so the trigger doesn't fire. The `Split step: keep` note and the matching P1 Decision line are both present. |

## Findings (severity-ordered)

- [major] `adr/ADR-001-stack-unchanged.md` Alternatives, row 1: the rejection of `cygpath -m` rests on two claims, and the second is false. The 0000035 suites do use `cygpath -m`. See `test-0000035-req-005-ratchet-check-shared-root.sh` line 27 and `test-0000035-req-003-links-judged-by-real-target.sh` line 29. `test-0000040-req-005-consumer-migration.sh` line 419 uses it too. Each guards the call with `command -v cygpath`, which also answers "not every MSYS install ships it". The alternative's pro, that it converts a file path, removes the workaround in ADR-001's own Negative consequence. Rewrite the row with a true reason, or switch the decision to the existing `command -v cygpath` helper pattern. If the decision changes, update `req-001` FR 3 and `design.md` req-005 bullet 2 to match. Neither is ratchet-guarded.
- [minor] `adr/ADR-001-stack-unchanged.md` Consequences, Negative: "the suite converts the folder and appends the file name" describes an implementation step, not a cost. Name a cost that hurts. For example, the new `IS_WIN` path code never runs on Linux or macOS, so a fault in it shows only on a Windows shard, a CI round trip of about 15 minutes (ADR-004).
- [minor] `adr/ADR-003-blob-id-compare-for-released-migration.md` Consequences, Negative: the current check already depends on git, because it runs `git show v0.38.0:...` and fails on empty output (suite lines 230 to 232). So the stated negative is not new. Name a real cost. For example, `git hash-object` applies `core.autocrlf`, so an uncommitted line-ending-only edit to the released file now passes. Another option is that the check needs two git reads where it had one.
- [minor] `adr/ADR-004-read-windows-ci-before-archive.md` Decision: "the fix loop runs while the design is still in `plan/current/`" names no loop and no cap. Name the loop that owns a red shard at this point, such as the P4 validate loop with its cap of 5. State whether a red non-Windows check at the pushed head also blocks P5. Today the ADR gates P5 on the two Windows shards only.
- [minor] `risk-register.md` R-002 and `adr/ADR-004-read-windows-ci-before-archive.md` Risks: ADR-004 names a residual risk that R-002's mitigation doesn't cover. The P7 rebuild changes the head, and a failure caused only by that rebuild still meets the 0000426 block. Add a mitigating action to R-002 or a new row. For example, run `node src/ravintio-framework/scripts/release-check.mjs --root . --files-only` after the P7 rebuild and before the push. That command is what the `release-copy-integrity` job runs.
- [minor] `adr/ADR-002-skip-link-cases-on-windows.md` Alternatives, row 2: "the critic accepted the gap under R-001" cites a reviewer, not a design reason. Keep the real reason, which is that the run path has no runner that can test it, and drop the appeal to the critic.

No finding needs a ratchet-guarded acceptance-criteria line or in-scope line reworded. Each fix edits an ADR or the risk register, or strengthens an FR.
