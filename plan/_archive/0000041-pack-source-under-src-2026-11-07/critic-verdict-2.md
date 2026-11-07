# Design-Critic Verdict (iteration 2)
**Mode:** on
**Mechanical check:** clean. `node ravintio-framework/scripts/consistency-check.mjs plan/current` printed one warning, `req-002-release-script.md: 4 acceptance criteria (aim for 3 — consider splitting the story)`, then `consistency-check: clean`, exit 0. The recorded keep answer covers the warning (see item 9). <!-- ravintio-em-dash-allow --> The dash sits in the quoted tool output.
**Overall:** REJECT

Phase is P1. No ADRs exist, so items 3 and 4 are not applicable and do not count against the verdict. All four iteration 1 findings are resolved. The REJECT rests on item 8 and on one link defect, both minor. Each has a direct fix.

## Iteration 1 findings

| # | Finding | Status | Evidence |
|---|---------|--------|----------|
| 1 | req-007 and req-008 user stories match no story | resolved | Both `## User Story` sections now quote US-001 word for word, as `design.md` and `feature-brief.md` do. Each adds a separate paragraph on how it serves US-001. Build log line 142 records it. |
| 2 | req-005 is should-have but must-have req-002 and req-008 import `project-kind.mjs` | resolved | req-005 `Priority` reads must-have and states the reason. Build log line 143 records it. |
| 3 | req-004 and req-006 trace to US-002 with no brief criterion | resolved | `feature-brief.md` now holds 7 acceptance criteria. Criterion 6 names the req-004 outcome and criterion 7 names the req-006 outcome. Each requirement says which criterion it serves. `design.md` line 14 records the change from 5 to 7. Build log line 144 records the deviation. |
| 4 | R-005 says 1,186 files, `git ls-files` lists 1,184 | resolved | `risk-register.md` R-005 reads 1,184 tracked files. I re-ran `git ls-files ravintio-framework \| wc -l` and got 1184. The only remaining 1,186 sits in `discovery.md` line 42, which holds raw P0 findings and is not under review. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC names an observable outcome and a `Verified by:` mode. Examples: req-002 AC1 (exit 0, byte-identical rerun, `summary:` counts, under 30 seconds), req-003 AC1 (named output lines and exit codes), req-005 AC1 (printed kind per fixture, exit 0 or 2), req-006 AC2 (record outcome per fixture), req-007 AC1 and AC2 (three `SKIP (open run):` lines, FAIL lines), req-008 AC3 (exit codes per fixture). req-002 AC4 is manual but checks a named Decision line and a named recommendation. |
| 2 Traceability | pass | Every requirement carries a `Source:` of US-001, US-002, or US-003. `execution-plan.md` maps every story to a requirement. `feature-brief.md` holds no orphan story. The seven brief criteria each map to a requirement. req-007 and req-008 now quote US-001 verbatim. |
| 3 ADRs record real decisions | not applicable | No ADRs exist at P1. |
| 4 Consequences are honest | not applicable | No ADRs exist at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes plausible work: rewriting `plan/_archive/` and released migrations (the 0.38.0 migration names `ravintio-framework/component.yml`), renaming the 134-file consumer runtime path, hand edits to the root copy, and backlog 0000364. Each has a stated reason. |
| 6 Risks specific and mitigated | pass | `risk-register.md` R-001 to R-014 name files and mechanisms. Examples: `markedRoot` in `path-rules.mjs` (R-006), `eol=lf` in `.gitattributes` (R-008), CRLF hashing (R-009), `em-dash-guard.mjs` scope (R-011). Each mitigation is an action tied to a requirement, a probe, or a backlog ID. |
| 7 NFRs measurable | pass | `execution-plan.md` NFR-001 to NFR-004 each carry a number or deterministic check: under 30 seconds, 100% hash match, 0 bytes outside three folders, 0 files changed on rerun. Each names its measuring test. |
| 8 Internal consistency | fail | Paths, step names, exit codes, and the `release.yml` format agree across the design, scope, execution plan, and req-001 to req-008. I confirmed 33 files at mode `100755`, tag `v0.38.0`, and today's seven-script `Sanctioned scripts:` sentence in `standard-boot.md`. One conflict remains: finding 1 below. |
| 9 Split step | pass | Only req-002 exceeds three criteria (four). Its file holds `Split step: keep, at four criteria` with the one concern named. `build-log.md` line 112 holds the matching `Decision (P1): split step for req-002: keep`. req-001, 003, 004, 005, 006, 007, and 008 each hold a keep note and a matching Decision line (lines 97, 113, 121, 124, 128, 105, 107), and each has three criteria. |

## Findings (severity-ordered)
- [minor] execution-plan.md Build order versus requirements/req-008-tests-and-ci-from-src.md and requirements/req-005-applies-to-header.md: step 2 builds `project-kind.mjs` and step 3 builds the resolver. req-008 says "Every new 0000041 suite sources this resolver" and the resolver runs `project-kind.mjs`. The req-005 suite therefore needs a helper that does not exist until step 3, and the helper needs a script whose tests come first. A red test at step 2 would fail for a missing helper, not for the missing script. Either say the req-005 script suite lands after step 3, or exempt the req-005 script unit test from the resolver rule and name how it finds the pack.
- [minor] requirements/req-002-release-script.md, req-003-release-yml-readers.md, req-004-component-path-rule.md, req-005-applies-to-header.md, and req-006-consumer-migration.md: the `**Skill:**` link reads `../skills/ravintio-spec-agent/SKILL.md`. From `plan/current/requirements/` that path resolves to no file. req-001, req-007, and req-008 use `../../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md`, which is correct. Change the five links to match. No rubric item names links, so this finding does not fail a row by itself.

No critical or major findings. The existing backlog entries (0000382, 0000383, 0000384, 0000386, 0000387) cover the out-of-scope problems I met, so I filed no new entry.
