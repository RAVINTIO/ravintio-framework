# Design-Critic Verdict (iteration 6)
**Mode:** on
**Mechanical check:** clean (`node ravintio-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** REJECT

Phase is P1. No ADRs exist, so rubric items 3 and 4 are not applicable. This is approach 2, iteration 3, and the sixth critic pass overall. Both iteration 5 findings are resolved. One new major finding remains in the same area: the history-line rule and the strip step conflict on lines that carry the full feature ID.

## Status of iteration 5 findings

| # | Iteration 5 finding | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | The new decisions-index heading would fail the guard (major) | Resolved | `req-007` "Approach 2 iteration 2 revision" sets the heading to `### Feature 0000040-retire-fast-path`. `req-006` strips that exact ID before any check, so the heading holds no remaining match. The build log holds a matching Decision (P1) line. |
| 2 | No line regex for the suite entries (minor) | Resolved | `req-006` "Approach 2 iteration 2 revision" gives every suite entry the line regex `.*`. For these entries the stale-entry check fails when no tracked path matches the path regex. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC in `req-001` to `req-007` names an observable result and a `Verified by:` method. Example: `req-005` AC2 lists four scratch-run outcomes. |
| 2 Traceability | pass | Each requirement carries a `Source:` of US-001, US-002 or US-003. `execution-plan.md` maps all seven. `feature-brief.md` holds three stories and no orphan. |
| 3 ADRs record real decisions | n/a | No ADRs at P1. |
| 4 Consequences are honest | n/a | No ADRs at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes 0000359, 0000308, 0000361 and the 0000355 re-routing. Someone could plausibly build each. |
| 6 Risks specific and mitigated | pass | `risk-register.md` R-001 to R-011 name concrete failures with actions. R-008 is accepted by the owner and says so. |
| 7 NFRs measurable | pass | NFR-001 to NFR-004 in `execution-plan.md` give counts or named suites. |
| 8 Internal consistency | fail | See finding 1. |
| 9 Split step | pass | Each requirement holds three ACs and one `Split step: keep` note. `build-log.md` holds a matching Decision (P1) line for each of `req-001` to `req-007`, plus the `req-006` criterion 3 line. |

## Residue check I ran

I listed every tracked file outside the six excluded prefixes that matches the guard patterns. Each is either deleted, rewritten, or allowlisted by a requirement. `plan/.orchestrator-active` is tracked and holds only the feature ID, which the strip step removes. The live `docs/decisions-index.md`, `docs/architecture-overview.md` and `component.yml` matches are all covered by a rewrite, a deleted section or a superseding note. Nothing is left unowned.

## Findings (severity-ordered)
- [major] `requirements/req-006-residue-guard.md` and `requirements/req-007-docs-and-adr-supersede.md`: the strip step and the history-line rule conflict. `req-006` says to strip `0000040-retire-fast-path` "before any check". The history-line rule then asks whether a line "names a feature ID". `req-007` tells the docs agent to write new lines with the full ID `0000040-retire-fast-path`, so the guard will not see that ID on a line once it is stripped. A new decisions-index row, architecture-overview line or `about.md` row that holds `Fast Path` and only the full ID fails at P3. The short forms `0000040` and `0000033-ADR-009` survive the strip, but `req-007` does not require them. Fix by one of these. State in `req-006` that the history-line test reads the unstripped line. Or have `req-007` require the short form `0000040` on every new line that holds a retired-track word. Also state that a new `docs/decisions-index.md` or `docs/architecture-overview.md` line needs `ADR` beside the ID, because `req-007` only asks for the ID.
- [minor] `design.md` and `scope.md`: `design.md` Scope lists four superseded ADRs, while `scope.md`, `execution-plan.md` and `req-007` list five. `scope.md` carries a "P1 clarification" line that names 0000035 ADR 003, so the later line governs. No fix is needed beyond recording the confirmed design update at P2 if the human on the loop wants the two to agree.
