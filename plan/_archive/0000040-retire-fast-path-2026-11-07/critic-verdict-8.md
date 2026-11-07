# Design-Critic Verdict (iteration 8)
**Mode:** on
**Mechanical check:** clean (`node ravintio-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** REJECT

Phase is P1. No ADRs exist, so rubric items 3 and 4 are not applicable. This is approach 3, iteration 2, and the eighth critic pass overall. All four actionable iteration 7 findings are resolved. One new major finding appears: a stated allowlist path regex breaks the parser that the requirement tells the suite to use.

## Status of iteration 7 findings

| # | Iteration 7 finding | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | R-005 names a root-level `component.yml` test that `req-003` does not state (major) | Resolved | `req-003` now defines the case. A root-level `path: "component.yml"` gives folder `.`, every path outside `plan/` and `docs/` is source, and a diff with a record still passes. The second criterion lists the case with both verdicts. `risk-register.md` R-005 matches. The build log holds a matching Decision (P1) line. |
| 2 | Allowlist entries other than suites give no line regex (minor) | Resolved | `req-006` "Line regexes for the remaining entries" gives a line regex for each entry. The setup entry matches only a quoted retired name. Two fixtures cover it, one pass and one fail. I ran the setup regex on a quoted `"fast-path.md"` line and on a bare `ravintio-change-agent` line. It passed the first and rejected the second. |
| 3 | Orphan lines after the fixture table (minor) | Resolved | "The correction before this section continues here" restates the antecedent for the `path-rules.mjs` line. |
| 4 | `req-007` says "also holds `ADR`" without the full feature ID (minor) | Resolved | "Approach 3 iteration 1 clarification" says the line holds the full feature ID together with `ADR`, or a superseding note. |
| 5 | `design.md` lists four superseded ADRs, the other artifacts list five (minor) | Still present, no fix needed | `scope.md` "P1 clarification" and `req-007` name five, and the later lines govern. The human on the loop can align `design.md` at P2. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC in `req-001` to `req-007` names an observable result and a `Verified by:` method. Example: `req-003` AC2 lists eight fixture verdicts. |
| 2 Traceability | pass | Each requirement carries a `Source:` of US-001, US-002 or US-003. `execution-plan.md` maps all seven files. `feature-brief.md` holds three stories and no orphan. |
| 3 ADRs record real decisions | n/a | No ADRs at P1. |
| 4 Consequences are honest | n/a | No ADRs at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes 0000359, 0000308, 0000361 and the 0000355 re-routing. Someone could plausibly build each. |
| 6 Risks specific and mitigated | pass | R-005 now cites a case that `req-003` states. R-011 cites the shallow-clone fixture in `req-003`. Every mitigation is an action. |
| 7 NFRs measurable | pass | NFR-001 to NFR-004 in `execution-plan.md` give counts or named suites. |
| 8 Internal consistency | fail | See finding 1. The setup path regex in `req-006` contradicts the entry format that the same file names. |
| 9 Split step | pass | Each requirement holds three ACs and one `Split step: keep` note. `build-log.md` holds a matching Decision (P1) line for `req-001` to `req-007`, plus the `req-006` criterion 3 line. |

## Findings (severity-ordered)
- [major] `requirements/req-006-residue-guard.md`: the setup entry gives the path regex `^ravintio-framework/setup\.(sh|ps1)$`. The requirement says to use the `path_regex|line_regex|reason` form that the brand guard parses. That parser (`test-0000039-req-007-brand-guard.sh` lines 12 to 15 and 124 to 125) takes the text before the first `|` as the path regex. Its header states that the path regex holds no `|`. The table shows `\|`, which is a Markdown escape, but the entry as written splits at the alternation. The suite would read `^ravintio-framework/setup\.(sh` as the path regex. Fix by adding a line that gives a path regex with no pipe, for example `^ravintio-framework/setup\.(sh)$` plus a second entry for `setup.ps1`, or `^ravintio-framework/setup\.[sp][sh1]*$`. State that a path regex never holds `|`. Add one fixture that parses the setup entry and checks the path regex round-trips.
- [minor] `requirements/req-006-residue-guard.md`: the closing bullets sit under the heading "Line regexes for the remaining entries". They begin "No other file gets an entry", then the `.gitignore` block, the build order, the split-step note, the stale-entry rule and the regression pack note. They now read as part of the line regex section, and the table and fixture table sit between them and the Functional Requirements list. The ratchet blocks deletion, so add one line after the last fixture table: "The bullets below return to the main Functional Requirements list and apply to the whole requirement."
- [minor] `requirements/req-006-residue-guard.md`: the setup line regex accepts only a line that holds one quoted name. `req-004` does not fix the layout of `RETIRED_TRACK_FILES` or `$RetiredTrackFiles` to one item per line. An array written on one line, or an unquoted item, would fail the guard. Add a line to `req-004` that says one quoted item per line in both setup files, so the layout and the regex agree.
- [minor] `design.md` and `scope.md`: carried over from iteration 7 as finding 5. No fix needed.
