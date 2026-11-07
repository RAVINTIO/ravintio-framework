# Design-Critic Verdict (iteration 4)
**Mode:** on
**Mechanical check:** clean. `node ravintio-framework/scripts/consistency-check.mjs plan/current` printed one warning, `req-002-release-script.md: 4 acceptance criteria (aim for 3 — consider splitting the story)`, then `consistency-check: clean`, exit 0. The recorded keep answer covers the warning (see item 9). <!-- ravintio-em-dash-allow --> The dash sits in the quoted tool output.
**Overall:** REJECT

Phase is P1. No ADRs exist, so items 3 and 4 are not applicable and do not count against the verdict. This is approach 2, iteration 1. Both iteration 3 findings are resolved. The REJECT rests on item 8 and two new minor findings. Each has a direct fix.

## Iteration 3 findings

| # | Finding | Status | Evidence |
|---|---------|--------|----------|
| 1 | Migrator edit order: the ownership row said req-003 edits "after req-005", but build order ran req-003 in full at step 5 | resolved | `execution-plan.md` Build order step 6 now reads "req-004, the req-005 migrator rule, req-003's migrator edits, then req-006", and step 5 holds only req-003's script, orchestrator, and update policy edits. The File ownership row for the migrator `SKILL.md` says req-003 edits after req-005. `req-003` Dependencies and `req-005` Dependencies both state the same order and cite step 6. Build log records the Decision. |
| 2 | req-008 AC2 states `Verified by: integration` twice | resolved by a recorded Decision | Build log: "Decision (P1): req-008 AC2 keeps both the inline and the indented Verified by". `ravintio-framework/templates/requirement.template.md` line 29 confirms the template allows both forms and says the indented line governs. The reason about ratchet-check editing a criterion line holds. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC names an observable outcome and a `Verified by:` mode. Examples: req-002 AC1 (key order, quoting, sort order, CRLF-as-LF hashes, byte-identical rerun, under 30 seconds), req-006 AC2 (record outcome and file state per fixture), req-007 AC1 (three `SKIP (open run):` lines and exit 0). |
| 2 Traceability | pass | Each requirement carries a `Source:` of US-001, US-002, or US-003. `execution-plan.md` Functional Requirements Directory maps every story to a requirement. `feature-brief.md` holds three stories and seven criteria, and req-004 and req-006 each name the criterion they serve. |
| 3 ADRs record real decisions | not applicable | No ADRs exist at P1. |
| 4 Consequences are honest | not applicable | No ADRs exist at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes plausible work: rewriting `plan/_archive/` and released migrations, renaming the consumer runtime path, any Write or Edit to the root copy, unconfirmed removal of a consumer manifest, and backlog 0000364. Each carries a reason. |
| 6 Risks specific and mitigated | pass | `risk-register.md` R-001 to R-014 name files and mechanisms. Each mitigation is an action tied to a requirement, a probe, or a backlog ID. Accepted risks R-006, R-010, and R-012 state why. |
| 7 NFRs measurable | pass | `execution-plan.md` NFR-001 to NFR-004 carry a number or a deterministic check and name the measuring test. The brief NFR table agrees. |
| 8 Internal consistency | fail | Paths, exit codes, the `release.yml` format, and the migrator order agree across the set. Findings 1 and 2 below remain. |
| 9 Split step | pass | Only req-002 exceeds three criteria (four). Its file holds `Split step: keep, at four criteria` and the build log holds "Decision (P1): split step for req-002: keep". req-001, 003, 004, 005, 006, 007, and 008 each hold three criteria, a keep note, and a matching Decision line. |

## Findings (severity-ordered)
- [minor] execution-plan.md Build order step 5 versus req-007 and req-008: req-008 AC2 says the static scan "flags no line in `tests/`" and that `run-tests.sh` exits 0. The plan closes AC2 at step 5. `test-0000039-req-010-version-bump.sh` lines 21 and 22 climb out of the pack (`FRAMEWORK/..`), which scan pattern 1 flags. req-008 leaves that suite to req-007, and req-007 runs at step 7. req-007 Dependencies already admit the scan passes only "once req-007 lands". After the pass, that suite also reads `src/` as the repo root, so `run-tests.sh` cannot exit 0 before step 7. Close req-008 AC2 at step 7 in Build order step 5 and the build log Decision, or move req-007's resolver edit to step 3. Step 3 also says req-008's "static scan" closes AC1, but the scan belongs to AC2. Reword step 3 to say the resolver closes AC1.
- [minor] requirements/req-004-component-path-rule.md versus design.md and scope.md: `design.md` (Codegen and ship) and `scope.md` say the codegen close-out reads the components "from `## Component Paths` and `product.yml`". req-004 reads them from the design's `## Engineering Layer` Components list and uses `## Component Paths` only to say a path with no listed manifest bumps nothing. Both are workable, but the design is the standard. Either align req-004 with the design wording, or record a Decision line and update `design.md` and `scope.md` as a P1 deviation.

No critical or major findings. The existing backlog entries (0000382, 0000383, 0000384, 0000386, 0000387) cover the out-of-scope problems I met, so I filed no new entry.
