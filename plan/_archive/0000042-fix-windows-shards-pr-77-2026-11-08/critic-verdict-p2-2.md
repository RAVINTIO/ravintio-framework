# Design-Critic Verdict (iteration 2, P2 gate)
**Mode:** on
**Mechanical check:** clean (`node ravintio-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** APPROVE

Scope: the combined P1 and P2 set for 0000042-fix-windows-shards-pr-77. This pass checks each iteration 1 finding, then judges every rubric row again from the artefacts.

## Iteration 1 (P2) findings

| # | Iteration 1 finding | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | [major] ADR-001 rejected `cygpath -m` on a false claim | resolved | ADR-001 Decision now adopts the `native()` helper from `test-0000035-req-005-ratchet-check-shared-root.sh` lines 26 to 28. `req-001` FR 3, `design.md` Engineering Layer bullet 2, and the P2 Deviation line in `build-log.md` match it. |
| 2 | [minor] ADR-001 negative described a step, not a cost | resolved | ADR-001 Negative: Windows-only path code fails only on a Windows shard, at about 15 minutes a round trip. |
| 3 | [minor] ADR-003 negative was not new | resolved | ADR-003 Negative: `hash-object` applies `core.autocrlf`, so an uncommitted line-ending-only edit passes. |
| 4 | [minor] ADR-004 named no loop and no cap, and gated P5 on Windows only | resolved | ADR-004 Decision: any red check blocks P5. The P4 validate loop owns the fix with its cap of 5, and `autonomous` allows 3 approaches. This matches `ravintio-validate-agent` SKILL.md line 59. |
| 5 | [minor] R-002 lacked the P7 rebuild mitigation | resolved | R-002 Mitigation now runs `release-check.mjs --files-only` after the rebuild. ADR-004 Decision bullet 3 says the same. See finding 1 below for its placement. |
| 6 | [minor] ADR-002 row 2 cited the critic | resolved | ADR-002 Alternatives row 2 now gives the reason: the probe path would never run in CI, so its faults stay unseen. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | AC1 is `gh pr checks 77` on the P9 head. AC2 fixes 67 and 127 passes with zero SKIP lines, and `build-log.md` Baseline (P1) records both on macOS. AC3 is the shard 5 and 6 logs plus a README search. |
| 2 Traceability | pass | The brief's Features table holds US-001 only. `req-001` **Source:** US-001. `design.md` Product Layer lists US-001. |
| 3 ADRs record real decisions | pass | Each ADR names two or three alternatives with reasons. ADR-001 row 1 holds a small factual slip. See finding 2. |
| 4 Consequences are honest | pass | ADR-001 costs a 15-minute CI round trip per Windows fault. ADR-002 loses Windows link coverage. ADR-003 lets an uncommitted CRLF-only edit pass. ADR-004 adds a 15-minute CI wait at P4. |
| 5 Scope boundaries matter | pass | `scope.md` Out of Scope excludes `project-kind.mjs` and the migrator, the 0000426 ship and gate change, backlog 0000425, and backlog 0000427. Each is a plausible change in this fix. |
| 6 Risks are specific and mitigated | pass | R-001 to R-004 each name a file, a phase, or a backlog entry. Each mitigation is an action. R-002 now covers the P7 rebuild. |
| 7 NFRs are measurable | pass | NFR-001 is 14 of 14. `.github/workflows/ravintio.yml` holds nine `test-suite` legs plus `validate-branch`, `self-description-check`, two PowerShell jobs, and `release-copy-integrity`. NFR-002 is 67 and 127 with 0 SKIP lines. NFR-003 is 0 files outside `mktemp -d`. |
| 8 Internal consistency | pass | ADR-001 matches FR 2 and FR 3. `helpers/pack-root.sh` lines 14 and 15 build the pack folder with `pwd`, as FR 3 states. ADR-002 matches FR 5, FR 8, and FR 9. ADR-003 matches FR 6 and FR 7. ADR-004 matches R-002, `design.md` Risks bullet 3, and the P1 Decision line. |
| 9 Split step | pass | `req-001` has three criteria, so the trigger doesn't fire. The `Split step: keep` note and the matching P1 Decision line are both present. |

## Findings (severity-ordered)

- [minor] `adr/ADR-004-read-windows-ci-before-archive.md` Decision bullet 3 and `risk-register.md` R-002: both place the check "before the push". The push comes at P9, after P7 Step 6 has archived the design. The check helps only between Step 5c (`build-release.mjs`) and Step 6 (`archive-current.mjs`) in `src/ravintio-framework/skills/ravintio-ship-agent/SKILL.md`. Name that slot, and give the full command `node src/ravintio-framework/scripts/release-check.mjs --root . --files-only`. Also state the pass condition the CI job uses: exit 0, or exit 0 with `skipped: no ravintio-framework/release.yml`. The untracked `ravintio-framework/release.yml` exists locally, and R-003 expects P7 to hold it back. A local run then reads a file that CI never sees, so say how the run treats that difference.
- [minor] `adr/ADR-001-stack-unchanged.md` Alternatives, row 1: the row says `test-0000040-req-005-consumer-migration.sh` uses the `native()` helper. It calls `cygpath -m` inline at line 419 and defines no `native()`. The 0000032 and 0000036 suites do define `native()`. Correct the citation. The rejection reason still holds.

No finding needs a ratchet-guarded acceptance-criteria line or in-scope line reworded. Both fixes edit an ADR or the risk register.
