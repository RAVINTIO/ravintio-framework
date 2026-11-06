---
title: "Build Log - 0000040-retire-fast-path"
summary: "Working log file maintained by the orchestrator throughout the pipeline run."
---
# Build Log - 0000040-retire-fast-path

> Created at P0. Appended by the orchestrator at each phase boundary. Survives session changes.

## Header

| Field | Value |
|-------|-------|
| Feature ID | `0000040-retire-fast-path` |
| Pipeline start | `2026-11-01T02:39:39Z` |
| Tool | `claude-code` |
| Primary model | `claude-opus-5-5` |
| Cheaper model | `sonnet` |
| Run mode | autonomous |
| Parallel streams | pending |

---

## Phase Log

### P0: Assess & Coach

| Field | Value |
|-------|-------|
| Start | `2026-11-01T02:39:39Z` |
| End | `2026-11-05T23:36:16Z` |
| Wall-clock | 4d 20h 57m (includes idle time between sessions) |
| Streams | n/a |
| Model tier | primary |
| Skills loaded | ravintio-orchestrator |
| Agents spawned | 4 |
| MCP calls | 0 |
| Parallel task batches | 1 |
| P0 questions asked | 9 |
| Brief complete | no |
| Stack unchanged | yes |
| Notes | F1 from backlog 0000355 section 5. |

P0 references loaded: ravintio-framework/skills/ravintio-orchestrator/references/phase-0-assess-and-coach.md, ravintio-framework/skills/ravintio-orchestrator/references/adoption-modes.md
Resume detection: no pending migrations (12 of 12 recorded), skill-drift-check exit 0, run-mode.mjs printed interactive with no run active.
P0 exchange (pre-flight): Q: Main matches origin/main and no PRs are open. Create feat/0000040-retire-fast-path? / A: confirmed. Branch created.
Backlog pickup: pulled in 0000358 (retire Fast Path), 0000152 (stale scope record), and 0000200 (flaky scope suite), per F1 in 0000355 section 5. 0000308 stays in the backlog and P7 narrows it. Every other entry is left untouched, per the F1 row.
Strict-mode ack: no session_id in context, so plan/.orchestrator-ack holds the UTC timestamp. The strict-mode banner later supplied session ID 121d9a6e-e20f-42b7-a97d-d3c9514c11b7, and the ack now holds it.
P0 exchange (no-src route): Q: Relax the Change Pipeline prerequisite so it accepts a change with no src/ target, or add a lighter tier? / A: Relax the prerequisites. Changes with no src/ target go to the Change Pipeline or the Feature Pipeline. No lighter tier or other path.
P0 exchange (CI file, superseded): Q: Should the migration remove the fix(fast-path): block from the consumer CI file, or should setup overwrite it? / A: Not answered. The human widened the scope instead, see the next line.
P0 exchange (scope): A: Not the Change Pipeline either. The feature retires the Change Pipeline as well as Fast Path. Correction to the no-src route line above: every change, with or without a src/ target, goes to the Feature Pipeline. Requirement change at P0: the brief, discovery, and scope now cover the Change Pipeline. Feature ID kept as 0000040-retire-fast-path.
P0 exchange (CI file): Q: Should the new migration remove the fix(fast-path): block from the consumer CI file, with the migrator applying it on confirmation, or should setup overwrite the file? / A: Confirmed. The migration removes the block with confirmation. Setup keeps its copy-if-absent rule.
Agents spawned: 4 ravintio-scope-lock-agent drafts (sonnet tier), 1 parallel batch. All four returned. Flags folded into the design draft: setup needs a named retired list for commands and skills, the migration must be safe to repeat, an unfinished Change Pipeline run gets a warning, and a declined or unmatched CI edit is recorded with its reason. One flag needs the human: migrator rule 1 limits migrations to plan/, docs/, and ravintio-framework/, so it can't edit .github/workflows/ravintio.yml.
P0 exchange (migrator scope): Q: Widen migrator rule 1 so a migration can name extra paths it may edit, with confirmation per edit, or have setup replace the CI file only on an exact template match? / A: Yes, widen rule 1 for named paths. src/ stays closed.
P0 exchange (lighter tier): Q: The human asked why 0000358 still asked about a lighter Change Pipeline tier. / A: The open question predates the widened scope. The design keeps one track, and pickup deletes 0000358.
P0 exchange (CI exemption): Q: The human asked whether the consumer CI template still needs any separate exemption. / A: No. Every branch takes the standard check, and 0000359 owns any hotfix rule.
P0 exchange (source folders): Q: The human said the check must cover any folder that works as source, such as ravintio-framework/ in this repo. Add a rule that reads component folders from product.yml? / A: Yes. Each source folder holds a versioned component.yml, and src/ is the default but not the only one. The manifest counts as source, not as a record.
P0 exchange (fit and setup): Q: Does it all fit, and does setup need the folder list? / A (agent): It fits in US-002, so three stories hold. Setup needs no list, because CI reads product.yml at run time and gate-write already judges every path outside plan/ and docs/ against the design. Found: design.md had no ## Component Paths section, so gate-write would allow every write with a warning. Added the section.
P0 exchange (vendored pack): Q: The human asked how a copied ravintio-framework/ in a consumer is handled, and said consumer runs have counted it as source. / A (agent): Confirmed. The codegen close-out and the ship fallback name ravintio-framework/component.yml. The human proposed moving the pack source under src/ and releasing the folder without the manifest. Filed backlog 0000361, because the move needs its own design. The 0000040 source folder rule stays valid after the move.
P0 exchange (combined confirmation): Q: Confirm the design, accept, edit, or reject each Scope Lock draft, and pick a run mode. / A: Design yes. All four Scope Lock drafts accepted. Run mode autonomous.
Scope Lock (happy path): any change, with or without a src/ target, routes to the Feature Pipeline, and a consumer upgrade removes the old commands, skill, and scope record with a notice. [source: agent-draft-accepted]
Scope Lock (first-run path): a fresh install never receives either track or the CI exemption, and a first upgrade from 0.37.x removes them through the setup retired list and the migration. [source: agent-draft-accepted]
Scope Lock (error path): an unmatched or declined CI edit makes the migration name the file and lines and record the outcome with its reason, never as success. A declined edit is the consumer's recorded choice. [source: agent-draft-accepted]
Scope Lock (cross-session path): an interrupted migration runs again because every step is safe to repeat, and an unfinished consumer run gets a restart warning. A skipped setup re-run leaves old commands until setup runs. [source: agent-draft-accepted]
Scope Lock complete. All four scenario paths captured.
Adoption mode: standard-iterative, confirmed by human on 2026-11-05
Version confirmed: 0.38.0
Backlog pickup: deleted plan/backlog/0000358, 0000152, and 0000200 in the P0 confirmation commit.
Autonomous checks: branch is feat/0000040-retire-fast-path, and ravintio-overrides/loop-toggles.yml is absent, so every checker reads on.
P0 questions asked: 9
Brief complete: no
Stack unchanged: yes
Run mode confirmed: autonomous (2026-11-05T23:36:16Z)
Credential scan (P0): clean (regex only, gitleaks not found)
Gate passed: P0 (2026-11-05T23:36:16Z)

### P1: Spec

| Field | Value |
|-------|-------|
| Start | `2026-11-05T23:37:38Z` |
| End | `2026-11-06T01:41:47Z` |
| Wall-clock | 2h 4m, including about 1h 29m waiting on exception item 6 |
| Streams | n/a |
| Model tier | primary |
| Skills loaded | ravintio-spec-agent, ravintio-loop-runner |
| Agents spawned | 13: 4 spec subagents and 9 design critics |
| MCP calls | 0 |
| Parallel task batches | 1 |
| Notes | Autonomous run. The critic budget ran out, and the human on the loop chose option 3. |

Skills inbox (P1): ravintio-framework/skills-inbox/ is empty, so nothing to process.
Toggle record (P1): ravintio-overrides/loop-toggles.yml is absent. In autonomous, design_critic, reversal_protocol, verify_by_execution, and cross_model_review read on (autonomous default). parallel_streams reads on (autonomous default). p0_completeness reads off (absent default).
Decision (P1): P1 ran as parallel subagents rather than stream files / reason: the requirement groups shared one design and joined at one commit set. P3 decides on streams per agent-dispatch-standards.
Agents spawned (P1): 4 spec subagents in 1 parallel batch, primary tier (req-001 and req-004, req-002, req-003 and req-005, req-006 and req-007).
Decision (P1): split step for req-002: keep / reason: one concern, the gates admit nothing through a scope record
Decision (P1): FAST_PATH_ENFORCEMENT_PATHS finding for P2 / reason: isAlwaysPermitted still reads it, so removing the list would weaken the permitted-name shortcut block
Decision (P1): split step for req-003: keep / reason: one concern, the verdict pre-push and CI give on a branch diff
Decision (P1): split step for req-005: keep / reason: one concern, the consumer upgrade through this migration. The migrator rule 1 widening serves only this migration
Decision (P1): source folder rule reads product.yml at the git top level from both the base commit and HEAD, taking the union / reason: a branch can't escape the check by dropping a component
Decision (P1): a migration declares extra paths on a new May edit line, and src/, absolute, .., and linked paths are refused / reason: rule 1 widens only for named paths
Decision (P1): a declined or unmatched CI edit records outcome skipped with the reason in the body / reason: never report success for a bypass left in place
Backlog filed (P1): 0000364, setup never refreshes an existing consumer CI file, so upgraded consumers don't get the source folder rule. req-005's notice points to the template.
Decision (P1): split step for req-006: keep / reason: the pattern scan, path check, and stale-entry check share one allowlist and one pass
Decision (P1): split step for req-007: keep / reason: one outcome, every live record of the release shows one track
Decision (P1): the residue guard joins the regression pack through promote-to-regression.sh at P7 / reason: same treatment as the 0000039 brand guard
Decision (P1): the residue guard also skips plan/_migrations/, plan/current/, plan/backlog/, and plan/reports/, and strips the feature ID and migration slug before matching / reason: those hold history or name the retired tracks as their subject
Decision (P1): ADR superseding notes go in docs/decisions-index.md and the new 0000040 ADRs, never in archived ADR files / reason: precedent from 0000033 ADR-010
Deviation (P1, unclassified): req-007 also supersedes 0000035 ADR-003, scope record staleness from git files, which the design's list of four ADRs omits
Backlog filed (P1): 0000365, the regression pack has no sanctioned retire step, so removing the test-0000017-req-007 regression copy and its manifest entry needs a recorded hand edit.
Decision (P1): split step for req-001: keep / reason: one concern, the route a request takes
Decision (P1): split step for req-004: keep / reason: one concern, no track file survives in the pack or a tool folder
Decision (P1): req-004 deletes templates/change-summary.template.md / reason: only the change agent reads it
Decision (P1): ownership split. req-001 owns routing text, req-002 hook code and gate text, req-003 the fix(fast-path): text, req-004 installed-file listings, req-007 ADR notes, architecture docs, and the version bump / reason: no file has two owners
Decision (P1): the retired list is RETIRED_TRACK_FILES with cleanup_retired_tracks in setup.sh, and $RetiredTrackFiles with Invoke-RetiredTrackCleanup in setup.ps1. It runs with or without a manifest and cleans only the folders of the tool it sets up / reason: this repo's manifest lists stale absolute paths, so the prune removes nothing (backlog 0000255)
Decision (P1): test-0000017-req-007-change-agent-archive.sh keeps its name and is rewritten to check the change agent is absent / reason: the regression manifest lists it, and no sanctioned step removes an entry (backlog 0000365)
Decision (P1): P3 lands req-002 and req-004 together / reason: test-0000035-req-001 and test-0000035-req-009 read workflows/fast-path.md
Decision (P1): wrote other features' ADR references as ADR NNN without the hyphen in design.md and the requirements / reason: consistency-check reads ADR-NNN as a local file (backlog 0000252). Notation only, no meaning changed
Loop armed (P1): design_critic, toggle on, cap 3, approach 1 of 3. consistency-check clean.
Critic verdict (P1, iteration 1): REJECT. 3 major and 5 minor findings, all on internal consistency. See critic-verdict-1.md.
Decision (P1): req-007's live-doc rewrites move into P3 before the req-006 guard, and the docs agent checks them at P6 / reason: the guard can't pass over a tree that P6 still rewrites
Decision (P1): the execution plan's file ownership table gives each file one owner and replaces the earlier ownership Decision line / reason: critic found files with two owners
Decision (P1): the source folder rule fails closed when the base commit can't be read / reason: stricter than a fallback, and both CI files use fetch-depth 0
Decision (P1): split step for req-006 criterion 3: keep / reason: the three-shard pass is the run condition of the stale-entry check
Critic verdict (P1, iteration 2): REJECT. 2 major and 2 minor findings. 6 of 8 iteration 1 findings resolved. See critic-verdict-2.md.
Decision (P1): decisions-index Status cells and superseding notes land in P3 after P2 numbers the ADRs / reason: the guard runs at the end of P3
Decision (P1): req-001 criterion 2 runs after req-007's P3 step, and each requirement states that the ownership table governs / reason: critic found requirement files still claiming files owned elsewhere
Critic verdict (P1, iteration 3): REJECT. 1 major and 3 minor findings. All 4 iteration 2 findings resolved. See critic-verdict-3.md.
Decision (P1): design_critic changes approach to 2 of 3 after the iteration cap / reason: the enumerated allowlist can't track text the feature writes later
Decision (P1): req-006 uses a history-line rule keyed on a feature ID or a superseding note for the decisions index, architecture overview, about.md, and component.yml comments / reason: covers new decision lines without growing a closed list
Decision (P1): the req-002 hooks/CLAUDE.md case is conditional on the P2 answer to Q-001 / reason: it assumes the enforcement path list survives
Decision (P1): Skill Map row for REQ-007 shows codegen agent at P3 and docs agent at P6 / reason: matches the build order. Skill Map updates at each phase gate.
Critic verdict (P1, approach 2 iteration 1): REJECT. 1 major and 4 minor findings. See critic-verdict-4.md.
Decision (P1): component.yml history comments pass as a block from a # Updated by line to the next one / reason: continuation lines name no feature ID
Decision (P1): new suites are test-0000040-req-002, req-003, and req-005 with named slugs, under one residue guard path entry / reason: the closed allowlist needs their paths
Critic verdict (P1, approach 2 iteration 2): REJECT. 1 major and 1 minor finding. All 5 iteration 4 findings resolved. See critic-verdict-5.md.
Decision (P1): the decisions-index heading and every new line naming the feature use the full ID 0000040-retire-fast-path / reason: the guard strips that exact ID
Decision (P1): the next critic pass runs on the skill text alone, without the orchestrator's calibration note / reason: the note set an approval threshold the skill doesn't state, which weakens the maker-checker split
Critic verdict (P1, approach 2 iteration 3): REJECT. 1 major and 1 minor finding. Both iteration 5 findings resolved. See critic-verdict-6.md.
Decision (P1): design_critic changes approach to 3 of 3 after the approach 2 cap / reason: prose guard rules kept interacting, so one ordered algorithm now governs, tested first as a scratchpad prototype on 13 fixtures
Decision (P1): the guard tests rules against the unstripped line, after a pattern match on the stripped copy / reason: the full feature ID must count as a feature ID for the history-line rule
Critic verdict (P1, approach 3 iteration 1): REJECT. 1 major and 4 minor findings. The iteration 6 major finding resolved. See critic-verdict-7.md.
Decision (P1): a root-level path component.yml makes every path outside plan/ and docs/ source / reason: stricter than ignoring it, and a diff with a record still passes
Decision (P1): every residue guard allowlist entry names a line regex, and the setup entry matches only quoted retired-list items / reason: a .* regex on setup.sh would admit lines outside the retired list
Critic verdict (P1, approach 3 iteration 2): REJECT. 1 major and 3 minor findings. See critic-verdict-8.md.
Decision (P1): no residue guard path regex holds a pipe, so the setup and released-migration suite entries split into two each / reason: the brand guard parser ends the path regex at the first pipe
Decision (P1): the retired list holds one quoted path per line in both setup scripts / reason: the guard's setup entry matches only that layout
Critic verdict (P1, approach 3 iteration 3): REJECT. 1 major and 3 minor findings. See critic-verdict-9.md.
Loop escalated (P1): design_critic, approach budget exhausted at 3 of 3. Escalation context: plan/current/loop-state-design_critic.md
Decision (P1): after escalation, wrote fixes for the four verdict 9 findings and marked them not yet reviewed / reason: each is a clear defect, and the setup regex failure was confirmed under /bin/bash 3.2.57
Exception waiting (P1, 6): design_critic budget exhausted after nine passes. Pick one: accept P1 with the four unreviewed fixes, grant one more critic pass, or leave the guard's matching detail to the P3 fixtures.
Human touchpoint (P1): the run waits for the human on the loop on the exhausted critic budget [exception: 6]
Progress: P1 blocked at 2026-11-06T00:12:39Z: seven requirements and the P1 set written, critic budget exhausted, waiting on exception item 6
Exception resolved (P1, 6): the human on the loop chose option 3 at 2026-11-06T01:41:47Z. P1 passes as it stands, and the P3 TDD fixtures settle the guard's matching rules.
Decision (P1): req-006 records that its P3 fixtures, run on all three CI shards, govern the guard's matching rules / reason: human choice on exception item 6
Gate passed: P1
Progress: P1 complete at 2026-11-06T01:41:47Z: seven requirements, critic loop escalated and resolved by the human on the loop, P2 next

### P2: ADRs

| Field | Value |
|-------|-------|
| Start | `2026-11-06T01:43:51Z` |
| End | `2026-11-06T01:58:00Z` |
| Wall-clock | 14m |
| Streams | n/a |
| Model tier | primary |
| Skills loaded | ravintio-adr-agent, ravintio-loop-runner |
| Agents spawned | 8: 6 ADR subagents and 2 design critics |
| MCP calls | 0 |
| Parallel task batches | 1 |
| Notes | Autonomous run. |

Decision (P2): seven ADRs. ADR-001 stack unchanged, ADR-002 one track, ADR-003 source folder rule, ADR-004 enforcement path list kept as ENFORCEMENT_PATHS, ADR-005 setup retired list, ADR-006 migrator named paths, ADR-007 residue guard / reason: each meets an adr-agent criterion, and the numbers are fixed first so parallel ADRs can cite each other
Decision (P2): Q-001 answer: the list survives, renamed ENFORCEMENT_PATHS / reason: isAlwaysPermitted reads it, so dropping it would admit a permitted file name inside hooks/ and break NFR-003
Decision (P2): ADR-001 written in the main thread, ADR-002 to ADR-007 by six parallel subagents / reason: ADR-001 needs no reads, under the size floor
Decision (P2): ADR-003 treats a product.yml with no readable path value as src/ only, with a warning / reason: matches req-003's rule for an unreadable file, and the check never drops below src/. The P2 critic reviews it.
Decision (P2): ADR-003 takes the merge base with origin/main as the base commit / reason: the hooks already diff with three dots
Decision (P2): ADR-005 status accepted and component ravintio-framework / reason: the human on the loop let the req-004 two-array form stand on 2026-11-06, and the design names ravintio-framework as the only component. The manifest prune path gap the subagent raised is backlog 0000255.
Deviation (P2, unclassified): req-005 step 3 changes from the migrator deleting plan/.fast-path-scope to the human on the loop running the delete, with the migrator checking the result. Hard Limit 8 names no delete route. Filed backlog 0000366.
Decision (P2): req-002 keeps test-0000039-req-008 unchanged and moves direct isEnforcementPath coverage before any retirement of test-0000035-req-009 / reason: ADR-004 keeps the function name, and the list's matching must keep its tests
Loop armed (P2): design_critic-p2, toggle on, cap 3, approach 1 of 3. consistency-check clean.
Critic verdict (P2, iteration 1): REJECT. 3 major and 4 minor findings. See critic-verdict-p2-1.md.
Decision (P2): pre-push checks nothing and warns when origin/main is missing, and fails closed only on an unreadable merge base / reason: keeps today's verdict for a master repo or first push, which CI still checks. Filed backlog 0000367 for the hard-coded ref.
Decision (P2): the req-004 two-array form governs, which replaces the P1 Decision line naming RETIRED_TRACK_FILES / reason: ADR-005 accepts it
Critic verdict (P2, iteration 2): APPROVE. 4 minor findings. All 7 iteration 1 findings resolved. See critic-verdict-p2-2.md.
Decision (P2): fixed the 4 minor findings by addition before the gate: criterion cases in req-003 and req-005, ADR-003 wording, and the delete wording in the glossary, design.md, and ADR-002 / reason: each is a clear wording gap, and none changes a decision
Loop closed (P2): design_critic-p2, status done after iteration 2.
Decision (P2): Skill Map unchanged at the P2 gate / reason: no ADR moves a requirement to another skill
Gate passed: P2
Progress: P2 complete at 2026-11-06T01:58:00Z: seven ADRs, critic approved at iteration 2, P3 next

### P3: Codegen

| Field | Value |
|-------|-------|
| Start | `2026-11-06T01:58:42Z` |
| End | pending |
| Wall-clock | pending |
| Streams | n/a |
| Model tier | primary |
| Skills loaded | ravintio-codegen-agent |
| Agents spawned | pending |
| MCP calls | 0 |
| Parallel task batches | pending |
| Notes | Autonomous run. |

Decision (P3): batch 1 runs four TDD subagents in parallel: req-002 with req-004, req-001, req-003, and req-005. Batch 2 is req-007's P3 step. Batch 3 is req-006 / reason: the file ownership table gives each batch 1 unit its own files. req-005 quotes the 0.37.2 exemption block from git, so it needn't wait for req-003. req-007 rewrites docs that state batch 1 results, and req-006 scans the finished tree.
Decision (P3): each TDD subagent runs the test-writer, implementer, and refactor steps in its own context, loading each step skill in turn / reason: one requirement per context keeps the red and green evidence together. Each subagent runs only its own suites, and the orchestrator runs the full suite at each join.
Decision (P3): subagents write files but never commit. The orchestrator scans and commits each requirement's TDD cycle after it returns / reason: parallel commits in one working tree would race on the git index.
TDD (P3, req-005): RED exit 1 (12 passed, 71 failed), GREEN exit 0 (83 passed) on attempt 1. test-0000040-req-005-consumer-migration.sh.
Deviation (P3, unclassified): req-005 migration adds a seventh step, Record the outcome, and a section that holds the quoted exemption block.
Deviation (P3, unclassified): req-005 edits test-0000035-req-007 and test-0000035-req-010, which count migration files, to add the 0.38.0 migration.
Deviation (P3, unclassified): req-005 no match case names each line holding the exemption markers, because an edited block has no known bounds.
TDD (P3, req-001): RED exit 1 (30 of 43 failed), then 38 of 43 pass. The 5 left read req-007 docs and wait for batch 2. Rewritten 0000032 req-003 and req-004 suites RED then GREEN in both copies.
Decision (P3): the orchestrator removed test-0000033-req-011 with git rm / reason: req-001 retires it, and git rm is the route req-004 uses for tracked pack files (backlog 0000366)
Deviation (P3, unclassified): req-001 re-pinned the baseline hashes in test-0000038-req-004 and test-0000038-req-007, which pin files req-001 changes.
Deviation (P3, unclassified): req-001 adds to ship Hard Limit 6 that a step meeting a standalone skill trigger names that skill.
Deviation (P3, unclassified): the req-001 suite also checks that the orchestrator SKILL.md holds no retired-track words, which is stricter than criterion 1.
TDD (P3, req-003): RED exit 1 (64 passed, 44 failed), GREEN exit 0 (108 passed). Rewritten test-0000019-req-002 RED then GREEN in both copies.
Deviation (P3, unclassified): req-003 CI fails closed when origin/{base_ref} is missing. Only pre-push warns and passes on a missing ref.
Deviation (P3, unclassified): req-003 treats a product.yml path starting with a backslash or a drive letter as absolute, and ignores it with a warning.
Deviation (P3, unclassified): req-003 ends the components block at a column 1 comment line, and a blank line doesn't end it.
TDD (P3, req-002 and req-004): RED exit 1 (183 and 72 failed), GREEN exit 0 (487 and 128 passed), with the ps1 cases run under pwsh. The req-002 no-assertion-change suites pass unchanged.
Deviation (P3, unclassified): req-004 adds a Windows skip table row for its suite in tests/README.md, which test-0000037-req-010 needs.
Deviation (P3, unclassified): req-004 changes the skill count in test-0000039-req-001 from 21 to 20.
Deviation (P3, unclassified): req-004 cleanup functions skip an empty skills folder, so opencode never checks a path at the project root.
Join (P3, batch 1): full suite 128 feature suites passed and 1 failed, 36 of 36 regression suites passed. The failing suite is test-0000040-req-001, on 5 checks that read req-007 docs.
TDD (P3, req-007): RED exit 1 (3 passed, 51 failed), GREEN exit 0. test-0000040-req-001 now exits 0. Full suite 129 feature suites passed and 1 failed, 36 of 36 regression suites passed.
Deviation (P3, unclassified): req-007 widens the 0.37-only version check in test-0000039-req-010 to accept 0.37 or a later 0.x release, and keeps every equality check.
Deviation (P3, unclassified): req-007 capitalises the superseding notes in the architecture overview decision list, and adds one component.yml responsibility line for 0000040 routing.
Decision (P3): accept the 3 equality failures in test-0000039-req-010 until P7 sets product.yml and docs/about.md to 0.38.0. P4 must not fix them / reason: set-product-release.mjs is sanctioned only at P7 Step 5b, and req-007 gives both files to the ship agent. Filed backlog 0000368.
Setup run (P3): ravintio-framework/setup.sh claude-code --strict-orchestrator, with the flags from .claude/.ravintio-setup-flags. Installed commands are feature-pipeline and retrofit, the change agent skill is gone, and the regenerated CLAUDE.md holds no scope record text. Only ravintio-overrides/setup-config/claude-code.md changed in git.
