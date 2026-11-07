# Design-Critic Verdict (iteration 3)
**Mode:** on
**Mechanical check:** clean. `node ravintio-framework/scripts/consistency-check.mjs plan/current` printed one warning, `req-002-release-script.md: 4 acceptance criteria (aim for 3 — consider splitting the story)`, then `consistency-check: clean`, exit 0. The recorded keep answer covers the warning (see item 9). <!-- ravintio-em-dash-allow --> The dash sits in the quoted tool output.
**Overall:** REJECT

Phase is P1. No ADRs exist, so items 3 and 4 are not applicable and do not count against the verdict. Both iteration 2 findings are resolved. The REJECT rests on item 8 and one new minor finding. It has a direct fix.

## Iteration 2 findings

| # | Finding | Status | Evidence |
|---|---------|--------|----------|
| 1 | The req-005 suite needs the resolver before the resolver exists | resolved | `execution-plan.md` Build order step 2 says the req-005 suite "finds the pack from its own folder until the resolver exists, as req-008 states". `req-005` Tests and `req-008` Dependencies both say the `project-kind.mjs` cases come first and find the pack from `$(dirname "$0")/..`, then move onto the resolver. Build log line 147 records it. Step 6 moves the suite onto the resolver. |
| 2 | Five `**Skill:**` links resolve to no file | resolved | `grep -n "Skill:" requirements/*.md` shows all eight files use `../../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md`. From `plan/current/requirements/` that resolves to the repo root `ravintio-framework/skills/`, which exists today. `scope.md` and `execution-plan.md` use `../../ravintio-framework/...`, which is correct from `plan/current/`. Build log line 148 records it. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC names an observable outcome and a `Verified by:` mode. Examples: req-005 AC1 (printed kind per fixture, exit 0 or 2), req-005 AC3 (record outcome per fixture, byte match to `v0.38.0`), req-008 AC1 (variables set per layout, FAIL line and exit 1), req-008 AC3 (exit code and named file per change type, skip notice). |
| 2 Traceability | pass | Each requirement carries a `Source:` of US-001, US-002, or US-003. `execution-plan.md` Functional Requirements Directory maps every story to a requirement. `feature-brief.md` holds three stories and seven criteria, and none is orphaned. req-007 and req-008 quote US-001 word for word. |
| 3 ADRs record real decisions | not applicable | No ADRs exist at P1. |
| 4 Consequences are honest | not applicable | No ADRs exist at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes plausible work: rewriting `plan/_archive/` and released migrations, renaming the 134-file consumer runtime path, any Write or Edit to the root copy, unconfirmed removal of a consumer manifest, and backlog 0000364. Each carries a reason. |
| 6 Risks specific and mitigated | pass | `risk-register.md` R-001 to R-014 name files and mechanisms, and each mitigation is an action tied to a requirement, a probe, or a backlog ID. R-005 states 1,184 tracked files, and `git ls-files ravintio-framework \| wc -l` returns 1184. |
| 7 NFRs measurable | pass | `execution-plan.md` NFR-001 to NFR-004 carry a number or a deterministic check and name the measuring test. `feature-brief.md` NFR table does the same. |
| 8 Internal consistency | fail | Paths, step names, exit codes, and the `release.yml` format agree across the design, scope, brief, execution plan, and req-001 to req-008. One conflict remains: finding 1 below. |
| 9 Split step | pass | Only req-002 exceeds three criteria (four, by AC count). Its file holds `Split step: keep` and `build-log.md` line 112 holds the matching Decision. req-001, 003, 004, 005, 006, 007, and 008 each hold three criteria, a keep note, and a Decision line (lines 97, 113, 121, 124, 128, 105, 107). |

## Findings (severity-ordered)
- [minor] execution-plan.md File ownership versus Build order: the migrator `SKILL.md` row says req-005 owns Step 1b, the header, and the table, and req-003 edits the `framework-version` row, the Step 5 template, and the Order and old paths rule "after req-005". Build order step 5 runs req-003 in full, but step 6 runs the req-005 migrator rule. The order of the two edits is reversed, so the stated "after req-005" cannot hold. Either split req-003 so its migrator edits land in step 6 after req-005's, or change the ownership row to say req-003 edits first and req-005 second. State the same order in req-003's Dependencies and req-005's Dependencies, which now say only that the two edits touch different sections.
- [minor] requirements/req-008-tests-and-ci-from-src.md AC2: the criterion ends with `Verified by: integration`, then a sub-bullet repeats `Verified by: integration - the new suite runs the scan...`. The line states the verification mode twice, and the second line holds the real explanation. Merge the explanation into the criterion and keep one `Verified by:`.

No critical or major findings. The existing backlog entries (0000382, 0000383, 0000384, 0000386, 0000387) cover the out-of-scope problems I met, so I filed no new entry.
