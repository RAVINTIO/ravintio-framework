# Design-Critic Verdict (iteration 9)
**Mode:** on
**Mechanical check:** clean (`node ravintio-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** REJECT

Phase is P1. No ADRs exist, so rubric items 3 and 4 are not applicable. This is approach 3, iteration 3, and the ninth critic pass overall. All four actionable iteration 8 findings are resolved. One new major finding appears: the setup line regex uses `\s`, which Bash 3.2 on macOS does not read.

## Status of iteration 8 findings

| # | Iteration 8 finding | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | Setup path regex holds `\|`, which the brand guard parser splits (major) | Resolved | `req-006` "Path regex rule (approach 3 iteration 2, governing)" splits the setup entry into `^ravintio-framework/setup\.sh$` and `^ravintio-framework/setup\.ps1$`. It also splits the released-migration suite entry in two. It adds a parser fixture. I read the brand guard parser (`test-0000039-req-007-brand-guard.sh` lines 12 to 15 and 124 to 125). It takes the text before the first `\|` as the path regex, so the new path regexes round-trip. |
| 2 | Closing bullets read as part of the line regex section (minor) | Resolved | The heading "Functional Requirements, continued" states that the lines below continue the main list and are not part of the line regex section. |
| 3 | `req-004` does not fix the retired list layout (minor) | Resolved | `req-004` now has a "Layout" bullet. Each item sits on its own line as one quoted path with an optional trailing comma, in both setup files. The build log holds a matching Decision (P1) line. |
| 4 | `design.md` lists four superseded ADRs, the other artifacts list five (minor) | Still present, no fix needed | `scope.md` "P1 clarification" and `req-007` name five, and the later lines govern. The human on the loop can align `design.md` at P2. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | fail | Every AC in `req-001` to `req-007` names an observable result and a `Verified by:` method. But `req-006` AC1 and AC3 require the suite to pass on the macOS Bash 3.2 shard, and the setup line regex cannot match there (finding 1). The stated outcome cannot be observed as written. |
| 2 Traceability | pass | Each requirement carries a `Source:` of US-001, US-002 or US-003. `execution-plan.md` maps all seven files. `feature-brief.md` holds three stories and no orphan. |
| 3 ADRs record real decisions | n/a | No ADRs at P1. |
| 4 Consequences are honest | n/a | No ADRs at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes 0000359, 0000308, 0000361 and the 0000355 re-routing. Someone could plausibly build each. |
| 6 Risks specific and mitigated | pass | R-001 to R-011 each cite a requirement and an action. R-005 and R-011 match cases that `req-003` states. |
| 7 NFRs measurable | pass | NFR-001 to NFR-004 in `execution-plan.md` give counts or named suites. |
| 8 Internal consistency | fail | See finding 1. The setup entry in `req-006` contradicts the macOS Bash 3.2 requirement in the same file. See also findings 2 and 3. |
| 9 Split step | pass | Each requirement holds three ACs and one `Split step: keep` note. `build-log.md` holds a matching Decision (P1) line for `req-001` to `req-007`, plus the `req-006` criterion 3 line. |

I also ran the residue patterns over `git ls-files`, minus the excluded prefixes. Every matching file maps to a requirement, an allowlist entry, or the history-line rule. `plan/.orchestrator-active` holds only the feature ID, which the strip removes. No orphan file exists.

## Findings (severity-ordered)
- [major] `requirements/req-006-residue-guard.md`: the setup line regex is `^\s*['"][^'"]*(fast-path|change-pipeline|ravintio-change-agent)[^'"]*['"],?\s*$`. It uses `\s`. The suite matches with Bash `[[ =~ ]]`, as the brand guard does, and `\s` is not POSIX ERE. I ran it under `/bin/bash` 3.2.57 on macOS. `[[ "  x" =~ ^\s*x$ ]]` fails, and the setup regex rejects both the fixture line `  "commands/fast-path.md"` and a quoted `'ravintio-change-agent',` item. The requirement says the suite passes on the macOS Bash 3.2 shard and that the orchestrator tested the regex. The test used another engine. Every real retired-list line in `setup.sh` and `setup.ps1` would then fail the guard on macOS. Fix by adding a line that replaces `\s` with `[[:space:]]`: `^[[:space:]]*['"][^'"]*(fast-path|change-pipeline|ravintio-change-agent)[^'"]*['"],?[[:space:]]*$`. I ran this form under Bash 3.2 and it matches both pass lines and rejects `echo "Use Fast Path for small fixes"`. State that every regex in the file stays POSIX ERE with no `\s`, `\d` or `\w`. The existing fixture rows then run on macOS.
- [minor] `requirements/req-004-remove-track-files.md` and `req-006-residue-guard.md`: `req-004` says the list holds "paths relative to a tool folder", and `cleanup_retired_tracks` takes a skills folder and a workflow folder. The workflow folder differs per tool (`.claude/commands`, `.agent/workflows`, `.github/copilot-workflows`, `.agents/workflows`). The `req-006` fixture item `"commands/fast-path.md"` fits only `claude-code`. A reader cannot tell how one array maps each item to the right folder. Add a line to `req-004` that states the item form, for example a `workflows/` or `skills/` prefix, or two arrays. Align the fixture item.
- [minor] `execution-plan.md`: NFR-003 measures "the link, root, and parity suites named in req-002, unchanged". `req-002` rewrites `test-0000035-req-003-links-judged-by-real-target.sh`, which is a link suite. Add a line that limits NFR-003 to the suites in the `req-002` "must stay green with no change" list.
- [minor] `requirements/req-006-residue-guard.md`: AC1 says every remaining match falls under an excluded prefix or an allowlist entry. The governing algorithm also admits lines under the history-line rule. Add a line to AC1 or after it that names the history-line rule as a third cover.
- [minor] `design.md` and `scope.md`: carried over from iteration 8 as finding 4. No fix needed.
