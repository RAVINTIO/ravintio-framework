# Recommendations - retire Fast Path and the Change Pipeline

**Skill:** [docs-agent](../../ravintio-framework/skills/ravintio-docs-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Version:** 0.38.0

> These are not blockers. They are opportunities for future work.

## Recommendations

| ID | Category | Priority | Component | Recommendation | Rationale | Effort |
|----|----------|----------|-----------|---------------|-----------|--------|
| REC-001 | security | high | ravintio-framework | Add a P0 design check for each migration edit outside `plan/` and `docs/`. Ask whether `gate-write` admits it in a hooked consumer with no design. | P5 found S-1 only after P3 and P4 had passed. Reversal verdict 001 placed the root in `design.md`, where two confirmed lines can't both hold. Exception 001 then held P5 for most of its 10h50m. | small |
| REC-002 | testing | high | ravintio-framework | Have verify-by-execution build its consumer fixture as a git repo with the hooks installed. Run each migration edit through the real hooks. | Defect report 001 records that the P4 consumer fixture sat outside a git repo. `gate-write` never gates a path outside the repo, so P4 missed the blocked CI edit. | small |
| REC-003 | maintainability | medium | ravintio-framework | When a requirement defines a matching algorithm, prototype it against fixtures before the first P1 critic pass. | The P1 critic rejected nine passes across three approaches, and exception 6 cost about 1h29m. Approaches 1 and 2 kept prose rules that interacted. Approach 3 tested an ordered algorithm on 13 fixtures and held at P3. | medium |
| REC-004 | maintainability | medium | ravintio-framework | Have the codegen agent classify each deviation as cosmetic, additive, or contradictory when it logs it. | The build log holds 24 `Deviation` lines, 19 of them in P3, and every one reads `unclassified`. P6 and P8 must judge each one again. | small |
| REC-005 | testing | medium | ravintio-framework | Make the 0000039 req-010 version equality checks hold only on a released tree. Backlog 0000368. | The suite failed on 3 checks from P3 to P7. P4 had to pass its gate on a red full suite and note the cause at each join. | small |
| REC-006 | maintainability | medium | ravintio-framework | Have the P9 ship step confirm that the release tag reached `origin`. Backlog 0000371. | No `v0.37.2` tag exists, though `main` carries 0.37.2. Verify-by-execution had to build its 0.37.2 fixture with `git archive main`. | small |
| REC-007 | security | medium | ravintio-framework | Fix the source folder rule's path matching in one change: quoted names, renames, case variants, and non-normalised paths. Backlog 0000372. | Security findings C-1, C-2, C-3, and C-6 share one diff read in `hooks/pre-push` and both CI files. | medium |
| REC-008 | security | low | ravintio-framework | Close the migrator's named-path gaps and reconcile its autonomous confirmation with `autonomous-run-standards.md`. Backlog 0000377. | Security findings S-2 and S-3. The migrator rule 1 widening (ADR-006) is new, so a later migration with a `**May edit:**` line meets these gaps first. | small |
| REC-009 | security | low | ravintio-framework | Harden `setup.ps1` removal under PowerShell 5.1, and match the `setup.sh` result for a linked parent inside the project. Backlogs 0000375 and 0000376. | Security findings S-7 and S-8. Both affect the retired list cleanup that ADR-005 adds. | small |
| REC-010 | security | low | ravintio-framework | Have pre-push check each pushed ref, and give the `validate-branch` job `contents: read`. Backlogs 0000373 and 0000374. | Security findings C-4 and C-7. Both predate the feature, and CI catches the pre-push gap. | small |
| REC-011 | maintainability | low | ravintio-framework | Add the refused-folder case to backlog 0000272. The setup manifest listed a skill folder that cleanup had refused, and the next prune deleted it through a link. | P4 cycle 1 fixed it for retired names only. The verification report notes that the 0000255 fix would not stop it. Any other refused folder still meets the gap. | small |
| REC-012 | maintainability | medium | ravintio-framework | Give boot Hard Limit 8 a sanctioned delete route and the regression pack a retire step. Backlogs 0000366 and 0000365. | The run used `git rm` for tracked pack files, a human-run delete for `plan/.fast-path-scope`, and a kept name for `test-0000017-req-007`. Each was a workaround logged as a decision. | medium |
| REC-013 | maintainability | medium | ravintio-framework | Fix the consistency check's reading of cross-feature ADR references. Backlog 0000252. | P1 again wrote other features' ADRs as `ADR NNN` without the hyphen to dodge a false local match. 0000039 met the same problem. | small |
| REC-014 | maintainability | low | ravintio-framework | Skip the migration scan in the framework source repo. Backlog 0000378. | The 0.38.0 migration adds only a `not applicable` record here, and each consumer-only migration costs this repo a test update. | medium |

## Deferred Items

| Scope Item | Recommendation | When to Address |
|-----------|---------------|-----------------|
| The incident hotfix path | Backlog 0000359 | Its own feature, before a regulated consumer needs a hotfix |
| Move the pack source under `src/` and release the folder without its manifest | Backlog 0000361 | Its own feature. The 0000040 source folder rule stays valid after the move |
| The advisory pre-commit and presence-only checks | Backlog 0000308, which P7 narrows | P7 of this run, then its own feature |
| Re-route the 0000355 feature rows marked Change | Backlog 0000355, whose table P7 updates | P7 of this run |
| Refresh an installed consumer CI file, so an upgraded consumer gets the source folder rule | Backlog 0000364 | The next change to `hooks/ravintio.yml` |
| A hooked consumer keeps the `fix(fast-path):` CI exemption after a `blocked` edit (R-014, exception 001) | Backlog 0000379 | Before 1.0.0, or with the next migration that names a path outside `plan/` and `docs/` |

## Tech Debt

| ID | Component | Description | Impact if Ignored | Suggested Fix |
|----|-----------|-------------|-------------------|--------------|
| TD-001 | ravintio-framework | The 0000039 req-010 suite fails on 3 version checks from P3 to P7. Backlog 0000368. | Every pack feature runs P4 on a red full suite, which can hide a real failure. | Run the equality checks only on a released tree. |
| TD-002 | ravintio-framework | The req-007 suite copies the residue guard's matching logic. Backlog 0000369. | A guard rule change must land in two places, or the suites disagree. | Have the req-007 suite call the req-006 guard. |
| TD-003 | ravintio-framework | Pre-push and the CI step print a false empty path warning for `components: []`. Backlog 0000370. | A reader learns to ignore the warning, and a real empty path then goes unread. | Warn only when a `path:` key has an empty value, and add a `components: []` fixture. |
| TD-004 | ravintio-framework | The regression pack has no retire step, so `test-0000017-req-007-change-agent-archive.sh` keeps its name and now checks absence. Backlog 0000365. | Suite names stop describing what they test, and the pack grows. | Add a sanctioned retire step to `promote-to-regression.sh` or a sibling script. |
| TD-005 | ravintio-framework | Boot Hard Limit 8 names no delete route. Backlog 0000366. | Each removal needs a logged workaround, such as `git rm` or a human-run `rm`. | Name a sanctioned delete route in Hard Limit 8. |
| TD-006 | ravintio-framework | Pre-push hard-codes `origin/main` and checks nothing when that ref is missing. Backlog 0000367. | A consumer on `master`, or before its first push, gets no local check. CI still runs the rule. | Read the default branch from `origin/HEAD`. |
| TD-007 | ravintio-framework | The `setup-powershell-51` job now runs three `.ps1` passes inside a 10-minute cap that the 0000037 req-011 suite pins. Nobody has timed the req-004 pass on Windows (R-013). Backlog 0000380. | The job can time out and turn CI red with no code fault. | Time the job from the P9 check read. Raise the cap and the req-011 pin together if needed. |
| TD-008 | ravintio-framework | The req-004 suite skips its two link cases and its failed-delete case on Windows. Only PowerShell 7 on macOS and Linux covers them for `setup.ps1`. Backlog 0000381. | A Windows-only defect in retired-path cleanup ships unseen. | Build real links on the runner, as backlog 0000210 suggests, and use an ACL deny for the failed delete. |
