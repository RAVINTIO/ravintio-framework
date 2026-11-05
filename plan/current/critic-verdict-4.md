# Design-Critic Verdict (iteration 4)
**Mode:** on
**Mechanical check:** clean (`node ravintio-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** REJECT

Phase is P1. No ADRs exist, so rubric items 3 and 4 are not applicable. This is approach 2, iteration 1, and the fourth critic pass overall. Three of the four iteration 3 findings are resolved. The major finding is only partly resolved. The new history-line rule leaves one existing line uncovered, so rubric item 8 still fails.

## Status of iteration 3 findings

| # | Iteration 3 finding | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | The closed allowlist cannot cover the new 0000040 text that req-007 adds (major) | Partly resolved | `req-006` "Approach 2 revision, the history-line rule" replaces the per-line entries. `req-007` requires each new decision and release line to name its feature ID on the same line. That covers the new text. The rule drops the old `Fast Path for no-src changes` entry and leaves an existing line unmatched. See new finding 1. |
| 2 | `docs/architecture-overview.md` matched headings cannot hold `supersed` without a rewrite (minor) | Resolved | `req-007` "Approach 2 revision for `docs/architecture-overview.md`" deletes the two sections with their bodies, deletes the line 492 row, and keeps lines 547, 551 and 552 with `superseded by 0000040 ADR-{n}`. A grep of the file shows no other matching line. |
| 3 | The `hooks/CLAUDE.md` case in req-002 AC1 depends on Q-001 (minor) | Resolved | `req-002` "Approach 2 revision" states the case assumes P2 keeps the list and that P2 logs a deviation and states the verdict otherwise. |
| 4 | The Skill Map names the docs agent for REQ-007, and the build log does not record the owner change (minor) | Resolved | `design.md` Skill Map row for REQ-007 now shows the codegen agent at P3 and the docs agent at P6. `build-log.md` holds a matching Decision (P1) line. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC in req-001 to req-007 names an observable result and a `Verified by:` method. Example: req-005 AC2 lists four run outcomes with a byte-identical CI file check. |
| 2 Traceability | pass | Each requirement carries a `Source:` of US-001, US-002 or US-003. The `execution-plan.md` directory maps all seven. `feature-brief.md` holds three stories and no orphan. |
| 3 ADRs record real decisions | n/a | No ADRs at P1. |
| 4 Consequences are honest | n/a | No ADRs at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes 0000359, 0000308, 0000361 and the 0000355 re-routing. Someone could plausibly build each. |
| 6 Risks specific and mitigated | pass | R-001 to R-011 each name a concrete failure and an action. R-008 is accepted and says so. |
| 7 NFRs measurable | pass | NFR-001 to NFR-004 in `execution-plan.md` give counts or named suites. |
| 8 Internal consistency | fail | See findings 1 to 3. |
| 9 Split step | pass | Each requirement holds three ACs and carries a `Split step: keep` note. `build-log.md` holds a matching Decision line for req-001 to req-007, plus the req-006 criterion 3 line. |

## Findings (severity-ordered)
- [major] `requirements/req-006-residue-guard.md` and `requirements/req-007-docs-and-adr-supersede.md`: the history-line rule leaves `ravintio-framework/component.yml` line 264 unmatched. The line reads `# budget, Fast Path for no-src changes, parallel streams, and the`. It continues the 0000033 `# Updated by` comment that starts on line 262. It neither starts with `# Updated by` nor names a feature ID. The rule is per line, and approach 2 removed the old `Fast Path for no-src changes` entry. `req-007` rewrites only the capability line at line 66, so nothing edits line 264. The guard would fail at the end of P3 on a history comment that the design says stays as written. Fix by one of these. Extend the `component.yml` rule to every `#` comment line in a block that starts at a `# Updated by` line. Or restore a line-regex entry for `Fast Path for no-src changes`. Or have `req-007` reword line 264.
- [minor] `requirements/req-006-residue-guard.md`: the history-line rule is ambiguous for `docs/about.md`. The first bullet keys on a feature ID "together with `ADR`". An `about.md` release row names a feature ID and has no `ADR`. `req-007` says each new line names its feature ID. State which test applies to each file, so the P3 and P6 rows for `about.md` cannot fail the guard.
- [minor] `requirements/req-002-gates-ignore-scope-record.md`, `req-003-no-commit-subject-exemption.md` and `req-005-consumer-migration.md`: none names its new suite file. `req-002` says "a req-002 suite", `req-003` says "the new suite", and `req-005` names none. The `req-006` allowlist needs a path regex for each, and its closed list names none. State the file names, such as `test-0000040-req-002-...sh`, or add a glob entry `tests/test-0000040-req-00[235]-*.sh` with a reason.
- [minor] `requirements/req-002-gates-ignore-scope-record.md`: the comment above `FAST_PATH_ENFORCEMENT_PATHS` in `path-rules.mjs` (lines 492 to 494) names a Fast Path scope record and ADR 009. The removal list in the "Code that reads the scope record" section does not name it. If the list survives under a new name, that comment stays and the guard flags it, because `req-006` gives hooks no entry. Add the comment to the removal list, with a reworded replacement.
- [minor] `requirements/req-004-remove-track-files.md` and `requirements/req-006-residue-guard.md`: both claim `path-rules.mjs` lists `workflows/fast-path.md`. The Dependencies section of req-004 says req-002 "drops `workflows/fast-path.md` from the enforcement path list". The list holds no such entry. Only a comment cites that file. The brand guard entry at line 108 of `test-0000039-req-007-brand-guard.sh` concerns `planifest.yml`, not `fast-path.md`. Correct the dependency line so P3 does not search for an entry that does not exist.
