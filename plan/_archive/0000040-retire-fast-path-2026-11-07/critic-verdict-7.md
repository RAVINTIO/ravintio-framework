# Design-Critic Verdict (iteration 7)
**Mode:** on
**Mechanical check:** clean (`node ravintio-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** REJECT

Phase is P1. No ADRs exist, so rubric items 3 and 4 are not applicable. This is approach 3, iteration 1, and the seventh critic pass overall. The iteration 6 major finding is resolved. One new major finding appears in a different area: a risk mitigation names a test that no requirement states.

## Status of iteration 6 findings

| # | Iteration 6 finding | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | The strip step and the history-line rule conflict on the full feature ID (major) | Resolved | `req-006` "Guard algorithm (approach 3, governing)" matches patterns on the stripped copy. Step 4 then tests the unstripped line against the allowlist and the history-line rule. A feature ID is seven digits, so `0000040-retire-fast-path` counts. Fixture 2 passes a `Fast Path retired (0000040-retire-fast-path)` row. `req-007` "Approach 3 revision" says the guard reads the unstripped line. The build log holds a matching Decision (P1) line. |
| 2 | `design.md` lists four superseded ADRs while the other artifacts list five (minor) | Still present, no fix needed | `design.md` Scope still says four. `scope.md` "P1 clarification" and `req-007` name five, and the later lines govern. The human on the loop can align `design.md` at P2. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC in `req-001` to `req-007` names an observable result and a `Verified by:` method. Example: `req-004` AC2 lists per-tool removals and one `(retired, removed)` line each. |
| 2 Traceability | pass | Each requirement carries a `Source:` of US-001, US-002 or US-003. `execution-plan.md` maps all seven files. `feature-brief.md` holds three stories and no orphan. |
| 3 ADRs record real decisions | n/a | No ADRs at P1. |
| 4 Consequences are honest | n/a | No ADRs at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes 0000359, 0000308, 0000361 and the 0000355 re-routing. Someone could plausibly build each. |
| 6 Risks specific and mitigated | fail | See finding 1. R-005 names a test that `req-003` does not state. |
| 7 NFRs measurable | pass | NFR-001 to NFR-004 in `execution-plan.md` give counts or named suites. |
| 8 Internal consistency | pass | The guard algorithm governs the earlier stripping and history-line lines. The ownership table governs file edits. I found no contradiction with `design.md` constraints. |
| 9 Split step | pass | Each requirement holds three ACs and one `Split step: keep` note. `build-log.md` holds a matching Decision (P1) line for each of `req-001` to `req-007`, plus the `req-006` criterion 3 line. |

## Residue check I ran

I listed every tracked file outside the six excluded prefixes that matches the guard patterns, by path and by content. Each is deleted, rewritten, or allowlisted by a requirement. I compared the lines in the ship, adr, optimise, both phase 0 references, both template guides, `getting-started.md`, `scope.md` and `auto-trigger-orchestrator.mjs` files with the line lists in `req-001`. They agree. The `decisions-index.md` lines 148, 320, 335 and 337 and the `architecture-overview.md` lines 253 to 299, 492, 547, 551 and 552 are all covered by a deletion or a superseding note. The `component.yml` line 66 is on the `req-007` rewrite list and lines 262 to 265 sit in a history block. The installed `.claude/` copies are untracked, so the guard does not see them.

## Findings (severity-ordered)
- [major] `risk-register.md` R-005 and `requirements/req-003-no-commit-subject-exemption.md`: R-005 says the source folder rule can misread "a path with no folder part" and that "tests cover a listed component, a missing file, and a root-level `component.yml` (req-003)". `req-003` states no rule and no criterion for a root-level `component.yml`. Its ignore list names only an empty value, an absolute path and a `..` part. A `path: "component.yml"` value gives a folder of `.`, which would make every diff a source diff. R-005 itself names that outcome, "blocks every diff". Fix by adding a line to `req-003` that says what the check does for a root-level path, and add that case to the second criterion. Either ignore it with a warning, or define it, and say which.
- [minor] `requirements/req-006-residue-guard.md`: most allowlist entries other than the suite entries give no line regex. This covers the setup retired-list entry, the new migration entry and the released-migration entry. The "Approach 2 iteration 2" line fixes `.*` only for suites. The requirement also says setup lines outside the retired list get no entry. A `.*` line regex on `setup.sh` would then allow them. Name a line regex for the setup entry, for example lines that hold `fast-path.md`, `change-pipeline.md`, `ravintio-change-agent`, or the 0000040 comment. Add one planted `Fast Path` line in a scratch `setup.sh` outside the list to the fixtures.
- [minor] `requirements/req-006-residue-guard.md`: the guard algorithm section sits inside the earlier bullet list. The orphan lines after the fixture table ("Only the comment above `FAST_PATH_ENFORCEMENT_PATHS` cites it...") now follow the table with no antecedent. The `Correction:` line they answer sits above the algorithm. The ratchet blocks deletion, so add one line after the table that restates the correction: "Correction restated: `path-rules.mjs` holds no entry for `workflows/fast-path.md`. Only the comment above `FAST_PATH_ENFORCEMENT_PATHS` cites it."
- [minor] `requirements/req-007-docs-and-adr-supersede.md`: the "Approach 3 revision" says each new line "also holds `ADR` or a superseding note". The guard needs a feature ID with `ADR`, or a superseding note. Add "together with the full feature ID" so the two lines agree.
- [minor] `design.md` and `scope.md`: carried over from iteration 6 as finding 2. No fix needed.
