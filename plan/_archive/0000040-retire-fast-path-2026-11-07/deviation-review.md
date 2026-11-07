# Deviation Review

Feature: 0000040-retire-fast-path. Reviewer: `ravintio-reversal-assessor`, fresh context, not the maker. Baseline: `plan/current/design.md` as confirmed on 2026-11-05 at 23:36 GMT (commit `6ddafb9f`), plus the P0 exchanges and Scope Lock lines in the build log. Later design.md edits come from the P2 deviation (row 2) and P5 exception 001 (row 26).

This feature has no database, so no line carries the `schema` flag. A line that deletes files in a consumer repo or the pack carries the `destructive` flag.

Rows 1 to 25 are the 25 `Deviation (` lines in the build log, in log order. Row 26 is the `Exception resolved (P5, altering design)` line. It is not a `Deviation (` line, but the human on the loop decided it, so it needs a class on the record.

| # | Phase | Build-log line (short) | Class | Flags | Exception-list item | Evidence |
|---|-------|------------------------|-------|-------|---------------------|----------|
| 1 | P1 | req-007 also supersedes 0000035 ADR 003, which the design's list of four ADRs omits | additive | none | no | Confirmed scope removes the scope record from the three hooks. ADR 003 reads only the scope record, so it falls with ADR 002 (req-007 line 51). The note records a consequence of confirmed scope and adds no behaviour. |
| 2 | P2 | req-005 step 3: the human on the loop runs the scope record delete, and the migrator checks the result | additive | destructive | yes | Confirmed: "The migration deletes one marker file ... only after the human on the loop confirms." Now the human runs `rm` and the migrator checks the path is gone (migration step 3). The end state and the human's consent stay. Who runs the delete changes, because Hard Limit 8 names no delete route (backlog 0000366). No gate reads the file from 0.38.0, so a leftover admits nothing. The delete removes a consumer file, so it stays on the exception list. The P2 critic approved it. No new decision is needed. |
| 3 | P3 | req-005 migration adds a seventh step, Record the outcome, and a section holding the quoted exemption block | additive | none | no | The confirmed Scope Lock error path requires every outcome recorded with its reason. A record step and a quoted block serve that and the confirmed CI removal. |
| 4 | P3 | req-005 edits test-0000035-req-007 and test-0000035-req-010 to count the 0.38.0 migration | additive | none | no | Test upkeep for the confirmed new migration. The suites keep their checks. |
| 5 | P3 | req-005 no match case names each line holding the exemption markers | additive | none | no | Confirmed: on no match, "the migration names the file and the lines to delete". An edited block has no known bounds, so naming each marker line meets that. |
| 6 | P3 | req-001 re-pinned baseline hashes in test-0000038-req-004 and test-0000038-req-007 | additive | none | no | The suites pin files that confirmed one-track routing rewrites. A re-pin follows the confirmed change. The suites keep their checks. |
| 7 | P3 | req-001 adds to ship Hard Limit 6 that a step meeting a standalone skill trigger names that skill | additive | none | no | The confirmed Routing line keeps triage for the standalone skills. req-001 Step 11 already names them. Hard Limit 6 now matches. |
| 8 | P3 | req-001 suite also checks that orchestrator SKILL.md holds no retired-track words | additive | none | no | A stricter test than criterion 1. Confirmed scope removes the tracks from the orchestrator. |
| 9 | P3 | req-003 CI fails closed when origin/{base_ref} is missing | additive | none | no | Stricter than the confirmed source folder rule. Every pull request has a base ref, and both CI files fetch with depth 0. Pre-push keeps the P2 warn-and-pass rule. |
| 10 | P3 | req-003 treats a product.yml path starting with a backslash or drive letter as absolute, and ignores it with a warning | additive | none | no | req-003 and ADR-003 already ignore absolute paths with a warning. The line widens what counts as absolute to Windows forms. Such a path can't name a folder in the repo, and `src/` stays covered. |
| 11 | P3 | req-003 ends the components block at a column 1 comment line, and a blank line doesn't end it | additive | none | no | ADR-003 ends the block at the next line that starts in column 1. A comment in column 1 meets that rule. A blank line holds no text, so the parser reads on, which can only add source folders. |
| 12 | P3 | req-004 adds a Windows skip table row in tests/README.md, which test-0000037-req-010 needs | additive | none | no | Test documentation for the new suite. No behaviour changes. |
| 13 | P3 | req-004 changes the skill count in test-0000039-req-001 from 21 to 20 | additive | none | no | Confirmed scope deletes `ravintio-change-agent`. The count follows that deletion. |
| 14 | P3 | req-004 cleanup skips an empty skills folder, so opencode never checks a path at the project root | additive | none | no | req-004 states opencode installs no skills. The skip narrows where cleanup can delete and keeps every confirmed removal. |
| 15 | P3 | req-007 widens the 0.37-only version check in test-0000039-req-010 to 0.37 or a later 0.x release, and keeps every equality check | additive | none | no | The confirmed version is 0.38.0. The equality checks stay, and P7 sets the version (backlog 0000368). |
| 16 | P3 | req-007 capitalises superseding notes in the architecture overview, and adds one component.yml responsibility line | additive | none | no | Wording and one line that records confirmed one-track routing. No scope change. |
| 17 | P3 | req-006 widens the 0000040 suite entry to test-0000040-req-00[1-57]- | additive | none | no | The req-007 suite plants history-line cases that name the retired words. The entry covers one more 0000040 suite and no live doc. The guard stays a closed allowlist (ADR-007). |
| 18 | P3 | req-006 adds an entry for one 0000038 req-004 history comment that req-001 wrote | additive | none | no | Confirmed constraints keep history as written. The entry admits one history line, and the stale-entry check removes it if the line goes. |
| 19 | P3 | req-006 gives entries only to req-002 rewrite-table suites that still name a track | additive | none | no | Fewer entries make the guard stricter. |
| 20 | P3 | req-006 makes every entry, .* included, go stale when it covers no match | additive | none | no | Stricter than the approach 2 rule. req-006 records it in "What P3 built". |
| 21 | P3 | req-006 fixes a stale Fast Path comment in test-0000039-req-008-emitted-names.sh | additive | none | no | A comment fix in a test file. Confirmed scope removes track text from live files. |
| 22 | P4 | setup.sh and setup.ps1 manifest prunes skip names on the retired skills list, so only the retired-track cleanup removes them | additive | none | no | The confirmed retired list removes the change agent in every tool folder. The skip stops the prune deleting a refused folder through a linked skills folder (P4 verify-by-execution). It narrows deletes, and ADR-005 and req-004 record it. |
| 23 | P4 | the 5.1 CI run of the req-004 suite skips the link and failed-delete cases under Git Bash on Windows | additive | none | no | A test coverage gap, not a design change. req-004 criterion 3 asks for parity on PowerShell 5.1 and 7. PowerShell 7 runs the two cases on macOS and Linux. Backlog 0000381 tracks the gap. |
| 24 | P5 | migration 0.38.0 steps 3, 5, and 7 and migrator Named paths add skipped reasons blocked and refused and a linked plan check | additive | none | no | Verdict 001 placed these inside the current design. The Scope Lock error path says an outcome never reads as success. The linked `plan` check stops `rm` reaching a target outside the repo. The altering part of S-1 sits in row 26. |
| 25 | P6 | process: the component-docs agent ran `git stash` and `git stash pop` for a baseline | additive | none | no | A process breach of the Write-or-Edit rule (boot Hard Limit 8), not a design change. The pop restored every file, and the orchestrator confirmed the living-docs edits survived. The agent ran in a parallel batch, so a stash could have taken a sibling's edits. Backlog 0000225 (shell guard passes `git stash`), 0000304 (git hygiene for parallel subagents), and 0000113 (name git writers in Hard Limit 8) track it. No new entry is needed. The run summary must still list it as a Hard Limit 8 breach. |
| 26 | P5 | Exception resolved (P5, altering design): a blocked CI edit records skipped with reason blocked, and the block stays | altering | none | yes | Confirmed at P0: the migration removes the CI block with confirmation, and the human rejected a hand-delete route. In a hooked consumer with no design, `blocked` is now the normal outcome, so the exemption stays until someone deletes it (R-014, accepted). The human on the loop chose option 3 on 2026-11-07. design.md, execution-plan.md, ADR-006, req-005, and the risk register record it. No new decision is needed. The final report must list it as a gross deviation. |

## Data and destructive decisions

| Decision | Needs a new human on the loop decision | Evidence |
|----------|----------------------------------------|----------|
| Delete `workflows/fast-path.md`, `workflows/change-pipeline.md`, `skills/ravintio-change-agent/`, and `templates/change-summary.template.md` (P1, P3) | no | The confirmed Removed line names each one. The template goes "if nothing else reads it", and the P1 decision found only the change agent reads it. |
| Setup retired-track cleanup removes installed track copies and the change agent skill in each tool folder (P1, P2, P3) | no | The confirmed Setup clean-up line names this. Cleanup leaves a linked skills folder whose target sits outside the project (req-004 criterion 2). |
| Manifest prune skips retired skill names (P4) | no | It narrows what setup deletes (row 22). |
| Orchestrator removed `test-0000033-req-011` with `git rm` (P3) | no | Confirmed scope removes or rewrites Fast Path and Change Pipeline tests. req-001 retires this suite. Backlog 0000366 tracks the missing delete route. |
| `test-0000017-req-007` keeps its name and is rewritten, not removed (P1) | no | Nothing is deleted. Backlog 0000365 tracks the missing regression retire step. |
| Migration step 3: human-run delete of `plan/.fast-path-scope` (P2) | no | Row 2. The human runs the delete, and the migrator never deletes. A linked `plan` gets no command (row 24). |
| Migration step 5: removal of the exemption block from a consumer `.github/workflows/ravintio.yml` after confirmation (P0, P5) | no | Confirmed at P0. When `gate-write` blocks the edit, the block stays, as the human chose on 2026-11-07 (row 26). |

## Result

Rows 1 to 25 are additive. None changes the confirmed problem, the users, or the in-scope list.

- Row 2 carries the `destructive` flag, so it goes on the exception list. It has a recorded basis and needs no new human decision.
- Row 25 needs no decision. It belongs in the run summary as a Hard Limit 8 breach, which existing backlog entries track.
- Row 26 is altering. It is already exception 001, and the human on the loop resolved it with option 3. It needs no new decision, but the final report must list it as a gross deviation.

No line touches a schema.
