# Design-Critic Verdict (iteration 5)
**Mode:** on
**Mechanical check:** clean (`node ravintio-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** REJECT

Phase is P1. No ADRs exist, so rubric items 3 and 4 are not applicable. This is approach 2, iteration 2, and the fifth critic pass overall. All five iteration 4 findings are resolved. One new major finding remains in the same area: the history-line rule does not cover the heading of the new decisions-index section.

## Status of iteration 4 findings

| # | Iteration 4 finding | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | The history-line rule leaves `component.yml` line 264 unmatched (major) | Resolved | `req-006` "Approach 2 iteration 1 revision" defines a history block. It starts at a `# Updated by` line and runs over the next `#` lines. I checked `ravintio-framework/component.yml`. Line 262 starts the 0000033 block and line 264 sits inside it. The only other live match is line 66, which `req-007` rewrites. |
| 2 | The history-line rule is ambiguous for `docs/about.md` (minor) | Resolved | The same revision gives one test per file. `about.md` passes on a feature ID alone. The decisions index and architecture overview need a feature ID with `ADR`, or `[Ss]upersed`. |
| 3 | `req-002`, `req-003` and `req-005` name no suite file (minor) | Resolved | The three requirements now name `test-0000040-req-002-gates-ignore-scope-record.sh`, `test-0000040-req-003-no-commit-subject-exemption.sh` and `test-0000040-req-005-consumer-migration.sh`. `req-006` holds one glob entry for `test-0000040-req-00[1-5]-...`. |
| 4 | The comment above `FAST_PATH_ENFORCEMENT_PATHS` is not in the removal list (minor) | Resolved | `req-002` "Approach 2 iteration 1 revision" requires a rewritten comment with no retired-track words. |
| 5 | `req-004` claims `path-rules.mjs` lists `workflows/fast-path.md` (minor) | Resolved | `req-004` Dependencies carries a "Correction" line. It says the list holds no such entry and only the comment cites the file. `req-006` repeats the correction. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC in `req-001` to `req-007` names an observable result and a `Verified by:` method. Example: `req-003` AC2 lists seven fixture verdicts. |
| 2 Traceability | pass | Each requirement carries a `Source:` of US-001, US-002 or US-003. `execution-plan.md` maps all seven. `feature-brief.md` holds three stories and no orphan. |
| 3 ADRs record real decisions | n/a | No ADRs at P1. |
| 4 Consequences are honest | n/a | No ADRs at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes 0000359, 0000308, 0000361 and the 0000355 re-routing. Someone could plausibly build each. |
| 6 Risks specific and mitigated | pass | `risk-register.md` names concrete failures with actions. `design.md` Risks agrees. |
| 7 NFRs measurable | pass | NFR-001 to NFR-004 in `execution-plan.md` give counts or named suites. |
| 8 Internal consistency | fail | See finding 1. |
| 9 Split step | pass | Each requirement holds three ACs and one `Split step: keep` note. `build-log.md` holds a matching Decision (P1) line for `req-001` to `req-007`, plus the `req-006` criterion 3 line. |

## Findings (severity-ordered)
- [major] `requirements/req-007-docs-and-adr-supersede.md` and `requirements/req-006-residue-guard.md`: the new decisions-index section heading would fail the guard at P6. `req-007` says "Add a Feature 0000040 section". Existing headings read `### Feature 0000039: ravintio-rebrand`, so the new one reads `### Feature 0000040: retire-fast-path`. That line matches `fast[ _-]?path`. The strip step removes only the exact string `0000040-retire-fast-path`, and this heading is not that string. The decisions-index test needs a feature ID with `ADR`, or `[Ss]upersed`, and the heading has neither. The first criterion runs after P6, so it would fail on a line `req-007` tells the docs agent to write. Fix by one of these. State in `req-007` that the heading reads `### Feature 0000040-retire-fast-path`, which the strip step removes. Or let the `req-006` decisions-index test also pass a line that starts `### Feature 0000040`.
- [minor] `requirements/req-006-residue-guard.md`: the entry for "every suite in req-002's rewrite table" gives no line regex. A suite that no longer names the words, such as `test-0000039-req-008-emitted-names.sh` after a rename, adds no stale-entry risk by itself because the entry is one regex pair. State the line regex so the stale-entry check has a defined match. This does not block approval once finding 1 is fixed.
