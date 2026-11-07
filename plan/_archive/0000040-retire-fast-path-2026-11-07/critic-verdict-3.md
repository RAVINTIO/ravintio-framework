# Design-Critic Verdict (iteration 3)
**Mode:** on
**Mechanical check:** clean (`node ravintio-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** REJECT

Phase is P1. No ADRs exist, so rubric items 3 and 4 are not applicable. All four iteration 2 findings are resolved. Rubric item 8 still fails on one new major finding. This is the third iteration, so the loop cap applies.

## Status of iteration 2 findings

| # | Iteration 2 finding | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | The guard cannot pass at the end of P3 because decisions-index notes land at P6 (major) | Resolved | `execution-plan.md` Build order step 5 says the Status cells and superseding notes land in P3 with step 3. `req-007` "P1 critic iteration 2 revision" adds the same for `docs/architecture-overview.md`. The four `docs/decisions-index.md` rows that match today (lines 148, 320, 335, 337) each hold their Status cell on the same line, so a "superseded" status puts `supersed` on the matching line. |
| 2 | req-001, req-002 and req-004 still claim files the ownership table gives to req-007 (major) | Resolved | Each of the three files carries a "P1 critic revision" line that names the ownership table as governing. req-001 also adds that its second criterion runs after req-007's P3 step. req-002 states the `standard-boot.md` bullets and says req-001 writes them. |
| 3 | req-007 criterion timing is unclear (minor) | Resolved | `req-007` "Criterion timing" line says criteria 1 and 2 first run at the end of P3 and run again after P6. Criterion 3 runs after P7. |
| 4 | A retired suite's allowlist entry could go stale (minor) | Resolved | `req-006` adds "If P2 or P3 retires a suite from that table, its entry goes in the same change". |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC in req-001 to req-007 names an observable result and a `Verified by:` method. Example: req-004 AC2 names the `(retired, removed)` line per path. |
| 2 Traceability | pass | Each requirement has a `Source:` of US-001, US-002 or US-003. The `execution-plan.md` directory maps all seven. `feature-brief.md` holds three stories and no orphan. |
| 3 ADRs record real decisions | n/a | No ADRs at P1. |
| 4 Consequences are honest | n/a | No ADRs at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes 0000359, 0000308, 0000361 and the 0000355 re-routing. Someone could plausibly build each. |
| 6 Risks specific and mitigated | pass | R-001 to R-011 each name a concrete failure and an action. R-008 is accepted and says so. |
| 7 NFRs measurable | pass | NFR-001 to NFR-004 in `execution-plan.md` give counts or named suites. |
| 8 Internal consistency | fail | See finding 1. |
| 9 Split step | pass | Each requirement holds three ACs and carries a `Split step: keep` note. `build-log.md` holds a matching Decision line for req-001 to req-007, plus the req-006 criterion 3 line. |

## Findings (severity-ordered)
- [major] `requirements/req-006-residue-guard.md` and `requirements/req-007-docs-and-adr-supersede.md`: the closed allowlist cannot cover the new 0000040 text that req-007 adds. req-007 adds a Feature 0000040 section to `docs/decisions-index.md`. Its rows will carry ADR titles that name Fast Path, the scope record or the Change Pipeline, as the existing rows for 0000033 and 0000035 do. The architecture-overview decision list gains matching entries, and the P6 `component.yml` history comment will name the retired tracks. The req-006 allowlist covers only lines in those two docs that hold `[Ss]upersed`, and one `component.yml` line (`Fast Path for no-src changes`). The guard strips only the feature ID and the migration slug. req-007 AC1 and its criterion timing line rerun the guard after P6, and `req-006` says "No other file gets an entry". The guard would fail on the new rows. Either add an allowlist entry for the Feature 0000040 section and the new ADR entries, with a reason, or state that those lines must hold `supersed` or avoid the matched words. Name the same rule for the P6 `component.yml` comment and the `docs/about.md` row.
- [minor] `requirements/req-007-docs-and-adr-supersede.md`: the `docs/architecture-overview.md` lines that match today include headings (lines 253 and 290) and body lines (255, 292, 297, 299, 492). A heading cannot hold `supersed` without a rewrite. The text says "rewrite", but it does not say whether each matched line is deleted or reworded. State one rule, such as "delete the section and keep one superseded decision-list line", so P3 does not log a deviation.
- [minor] `requirements/req-002-gates-ignore-scope-record.md`: AC1 asserts that a write to `ravintio-framework/hooks/CLAUDE.md` blocks with no design. That holds only if P2 keeps the enforcement path list (Q-001, and the requirement's own note that dropping it re-permits the file). Say that the `hooks/CLAUDE.md` case applies only when the list survives, or that P2's decision sets the expected result.
- [minor] `execution-plan.md` and `design.md`: the plan says the codegen agent writes req-007's live-doc rewrites in P3. The design's Skill Map names `ravintio-docs-agent` as best fit for REQ-007. The plan governs, but the build log should record the change of owner. State it in one line so P3 dispatch matches.
