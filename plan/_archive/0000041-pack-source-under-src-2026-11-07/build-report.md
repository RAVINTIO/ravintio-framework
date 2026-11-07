# Build Report (0000041-pack-source-under-src, 07 Nov 2026)

## Summary

- The run used `autonomous` mode. `run-mode.mjs` confirmed it against this archived log.
- The log holds no `Human touchpoint` lines. Nine `Exception waiting` lines (10 items) wait for the human on the loop.
- Three Write-or-Edit breaches (boot Hard Limit 8) occurred. The log records two of them in its gate summary.
- The run spawned 75 agents through P7. The phase rows total 432 minutes.
- The P8 entry in the build log is still pending. This report does not edit the log.

## Model Usage

| Model tier | Concrete model | Phases used | Agent call count |
|------------|---------------|-------------|-----------------|
| Primary | claude-opus-5-5 | P0 to P7 orchestration. Agents at primary: P0 (4), P1 (10), P2 (11), P3 (2 implementers), P4 (1), P5 (6), P6 (1 assessor) | 35 |
| Cheaper | sonnet (per header) | P3 (28 TDD agents), P5 (5), P6 (3 doc writers) | 36, plus 2 fixers whose tier the log does not record |
| Cross-model | claude-fable-5-1 | P6 cross-model review | 2 |

The header names `sonnet` as the cheaper model. The P8 assessment in this report runs as `claude-haiku-5-5`. The header does not list `claude-fable-5-1`.

## Skills Invoked

| Phase | Skill | Load pattern |
|-------|-------|-------------|
| P0 | ravintio-orchestrator | Session start |
| P0 | ravintio-orchestrator references: phase-0-assess-and-coach, adoption-modes | Phase start |
| P1 | ravintio-orchestrator, ravintio-spec-agent, ravintio-loop-runner | Phase start, spec subagents, loop mechanics |
| P1 | ravintio-design-critic | Spawned for 6 critic passes |
| P2 | ravintio-adr-agent | Spawned for 8 ADR subagents |
| P2 | ravintio-design-critic | Spawned for 3 critic passes |
| P3 | ravintio-codegen-agent, with ravintio-test-writer, ravintio-implementer, and ravintio-refactor | Phase start and TDD subagents |
| P4 | ravintio-validate-agent, with ravintio-verify-by-execution | Phase start, and verify-by-execution after CI checks |
| P5 | ravintio-security-agent | Phase start, reviewers and re-reviewers |
| P6 | ravintio-docs-agent | Phase start |
| P6 | ravintio-reversal-assessor | Spawned for the deviation review |
| P6 | Cross-model review | The log does not name a skill |
| P7 | ravintio-ship-agent | Phase start. The installed copy is 0.38.0, which has no Step 5c |
| P8 | ravintio-build-assessment-agent | Phase start |

## Subagent Dispatch

| Phase | Agent type | Count | Purpose |
|-------|-----------|-------|---------|
| P0 | Not recorded | 4 | Not recorded |
| P1 | Spec subagent | 4 | Requirements, scope, risk register, and glossary, in one batch |
| P1 | Design critic | 6 | Five REJECT passes and one APPROVE |
| P2 | ADR subagent | 8 | ADR-002 to ADR-009, in one batch |
| P2 | Design critic | 3 | Two REJECT passes and one APPROVE |
| P3 | Test-writer, implementer, refactor, and one full-suite fixer | 31 | TDD cycles for eight requirements, and the suite fixes |
| P4 | Verify-by-execution checker | 1 | Execution criteria for req-005, req-006, and req-007 |
| P5 | Security reviewer | 2 | Release script, and readers and CI |
| P5 | Security re-reviewer | 2 | Fixes from the first review |
| P5 | Test-writer | 3 | Security regression cases |
| P5 | Implementer | 4 | Security fixes |
| P6 | Doc writer | 3 | Living docs, pack component docs, and recommendations with the changelog |
| P6 | Reversal assessor | 1 | Deviation review of 19 lines |
| P6 | Cross-model reviewer | 2 | Review on claude-fable-5-1 |
| P6 | Fixer | 1 | Cross-model findings |
| P7 | None | 0 | Archive and release build run on the orchestrator thread |

**Total agents spawned:** 75 through P7. P8 is pending in the log.

## Phase Timing

| Phase | Subagents | Parallel batches | Streams | Wall-clock |
|-------|-----------|------------------|---------|------------|
| P0 | 4 | 1 | n/a | 161 min, including the human reply time |
| P1 | 10 | 1 | n/a | 32 min |
| P2 | 11 | 1 | n/a | 22 min |
| P3 | 31 | 7 | n/a | 96 min |
| P4 | 1 | 2 | n/a | 15 min |
| P5 | 11 | 3 | n/a | 44 min |
| P6 | 7 | 2 | n/a | 60 min |
| P7 | 0 | 1 | n/a | 2 min |
| P8 | pending | pending | n/a | pending |
| Total | 75 | 18 | | 432 min in the phase rows |

The pipeline ran 445 minutes from the P0 start to the P7 end. The gaps between phases account for the remaining 13 minutes.

## MCP Tool Usage

| Tool | Call count | Purpose |
|------|-----------|---------|
| None recorded | 0 | Every phase logs `MCP calls: 0` |

## Parallel Task Bursts

| Phase | Batch count | Tasks parallelised |
|-------|------------|-------------------|
| P0 | 1 | Four agents. The log does not itemise the tasks |
| P1 | 1 | Four spec subagents |
| P2 | 1 | Eight ADR subagents |
| P3 | 7 | Five suite-edit implementers (step 3), and the steps 6 and 7 batch. The other five batches are not itemised |
| P4 | 2 | Not itemised. The log records one subagent |
| P5 | 3 | Two reviewers in one batch. The other two batches are not itemised |
| P6 | 2 | Three doc writers. The second batch is not itemised |
| P7 | 1 | None. The batch has no subagents |

**Phases with no parallelism:** P7 (no subagents) and P8 (not yet run). The P1 and P2 critic loops ran one pass at a time by design.

## Self-Corrections

| Phase | Count | Summary |
|-------|-------|---------|
| P3 | 4 | Full suite: five feature suites failed, and one fixer resolved them. Req-001 follow-ups: three assertions broke, and the orchestrator fixed them. RED suite: three test-writer defects, fixed by the orchestrator. SKILL.md: the first draft passed the byte cap, and the step shortened it |
| P5 | 1 | Portability lint: two GNU `stat -c` calls, replaced with a Node mode reader |
| P6 | 1 | Revalidation cycle 1: four doc lines cited Hard Limit 8 without the rule name, and the docs now name it |

**Total self-corrections:** 6. The log records one of them as a cycle (P6). The log records 0 cycles in P4.

Review rejections are not counted above. They are P1 (five REJECT passes), P2 (two REJECT passes), and P6 (one cross-model REJECT).

## Artefact Counts

| Category | Count |
|----------|-------|
| User stories | 3 (US-001 to US-003) |
| Requirements | 8 (req-001 to req-008) |
| Acceptance criteria | 25 |
| ADRs | 9 |
| Design critic passes | 9 (7 REJECT, 2 APPROVE) |
| Test suites run at P4 | 176 (139 feature, 37 regression) |
| New feature suites | 8 |
| New scripts | 3, plus the `pack-root.sh` resolver |
| Migrations | 1 (0.39.0), with this repo's not applicable record |
| Security findings | 19 (8 release script, 8 readers and CI, 3 re-review), overall rating High |
| Accepted residual risks | 2 (R-002 and R-015) |
| Deviation lines reviewed | 19 (9 additive, 10 altering, 5 destructive, 0 schema) |
| Backlog entries picked up | 6, plus 0000403 closed in P3 |
| Backlog entries filed | 19 by ID. The P1 gate says six, but lists five IDs |
| Exception items waiting | 10 items on 9 lines |
| Write-or-Edit breaches | 3 |

The design critic count is the sum of the P1 loop (six passes) and the P2 loop (three passes). The P6 cross-model review, with one REJECT and one APPROVE, is not in that count.

## Efficiency Observations

- **P3 is the largest cost.** It used 96 minutes, or 22 percent of the phase time, and 31 agents, or 41 percent of the total. Steps 1 to 5 ran in sequence by design.
- **The P1 spec loop needed six passes.** Each of the five REJECT passes reported zero major findings, all on wording and traceability. The approach 2 sweep, which checks the whole set in one review, cleared the loop. Running that sweep at approach 1 is the likely saving.
- **P2 ADR-002 conflicted with the approved exception.** Its reset line would have discarded work outside the P0-approved git pass. The fix came from the critic, not the ADR author.
- **The P6 reviews cost 60 minutes.** They found two major cross-model findings, so the time bought real fixes.
- **P7 ran a release step the installed ship skill does not hold.** The installed copy is 0.38.0 and has no Step 5c. The orchestrator ran `build-release.mjs` from a decision line. The step worked, but the record depends on that line.
- **The root copy has no `release.yml` yet.** The credential scan held the file back. Until the human commits it, the release-copy-integrity CI job on the pull request prints a skip notice.
- **The P0 wall-clock includes human reply time.** It does not measure agent time.
- **The header has two stale rows.** `Parallel streams` reads `pending` for the whole run, and the cheaper model reads `sonnet`.

## Critical Audit

**Model routing audit**

- The primary tier handled 35 agent calls. P1 and P2 are judgement work, so the primary tier fits there.
- P4 ran its verify-by-execution checker at the primary tier. Validation is cheaper-eligible, and the log gives no reason for the primary tier.
- P7 ran its scripted archive on the orchestrator thread, which runs at the primary tier. A subagent did not make that choice.
- The cheaper tier handled 36 known calls. It was used, so it is not zero. The two fixers' tiers are not recorded.
- The log records the tier per phase, with a split only in P3, P5, and P6. It does not record a tier decision per agent call. This is an accountability gap.

**Parallelism audit**

- P0, P1, and P2 each ran their independent units in one batch.
- P1 and P2 ran their critic loops in sequence. Each pass reviewed the previous fixes, so sequence is justified.
- P3 steps 1 to 5 ran in sequence, and the log gives the reason. Steps 6 and 7 ran as one batch, as the execution plan allows.
- The three step 6 TDD cycles ran one after another. The log does not state why. They share the migrator file, so the order is defensible.
- P4 records two batches and one subagent. The log does not say what the second batch was.
- P7 records one batch and zero subagents. This is a log entry with no matching agent.
- The `Parallel streams` header reads `pending`. The streams audit cannot be evaluated. The run had eight requirements, below the threshold of ten, so the scalability flag does not apply.

**Phase gate audit**

- The P0 combined confirmation set `autonomous` and confirmed the design. The Scope Lock drafts were accepted in a second turn. Both turns are recorded.
- Each gate from P1 to P6 has a passed line and a progress line.
- P6 Gate B was auto-accepted under the continuous run mode. The run mode allows that.
- No gate was skipped without a condition.

**P0 question audit**

- The P0 block records `P0 questions asked: 5`.
- The brief is not complete (`Brief complete: no`). The count therefore needs no flag.
- The P0 section lists seven question and answer exchanges, not five. The count does not match the exchanges. This is a build-log gap.

**Self-correction audit**

- **P3 full suite (5 failures).** Avoidable. The failures came from the feature's own changes. A full-suite run per step would have caught them before the gate.
- **P3 req-001 follow-ups (3 assertions).** Partly avoidable. The intended changes should have updated these assertions in the same commit.
- **P3 RED suite (3 defects).** Avoidable. A RED check should catch test-writer defects before handoff.
- **P3 SKILL.md byte cap.** Avoidable. The first draft exceeded a cap that a test checks.
- **P5 portability lint.** Avoidable. The portability lint exists, and the new cases used GNU `stat -c`.
- **P6 revalidation.** Avoidable. The four doc lines broke an existing suite that requires the rule name.
- **P1 review rejections.** Five REJECT passes, all with zero major findings. These were wording and traceability gaps in the spec set.
- **P2 review rejections.** Two REJECT passes, with four major findings in iteration 1. One of them, the ADR-002 reset line, contradicted the approved exception and Hard Limit 8. The ADR author should have caught it.
- **Overall.** Six corrections is a moderate count. The review rejections point to wording gaps in the spec and ADR set.

**Build log integrity**

- P0 to P7 each have the full field set and a progress line.
- The P8 block and its progress line are pending. This matches the phase's state.
- The log has no `Human touchpoint` lines. The touchpoint audit below covers this.
- **Maker-assigned labels.** Ten `Deviation` lines carry labels such as `additive`, `altering`, or `destructive`. P1 has five, P2 has three, and P5 has two. The standards say the maker writes `unclassified`, and the assessor sets the class. The P6 deviation review lists these same rows as `unclassified`, so the log and the review disagree.
- **Backlog count.** The P1 gate says six entries were filed. Its list names five IDs: 0000382, 0000383, 0000384, 0000386, and 0000387. The log does not explain the gap.
- **Breach summary.** The P5 gate says two Write-or-Edit breaches occurred, both by subagents. It omits the P0 `git rm` by the orchestrator. The P0 `git rm` makes three breaches in total.
- **P4 wording.** The log says "CI green first time." No pull request existed at P4, so the claim refers to local checks. The record should name the checks.
- **Exception count.** The P6 gate says 10 items. The log holds 8 P6 lines, and those lines cover the 10 items. The P6 gate and the review agree.

**Human touchpoint audit** (`autonomous` only)

- **Recorded `Human touchpoint` lines:** 0.
- **Exception lines:** 9, covering 10 items. Labels: item 1 on 3 lines, item 2 on 4 lines, item 3 on 1 line, and item 7 on 1 line.
- **Outside the list:** none by label. Two labels need a check, as set out below.
- **Item 3 on a deletion approval.** The P0 `git rm` approval carries item 3, human review of the running result. A deletion fits item 1, the destructive-operation item. Check the label.
- **Item 1 on a residual-risk acceptance.** The RS-F02 to RS-F04 entry carries item 1, which covers destructive operations. The log gives no reason for a destructive label. Check the label.
- **Session starts.** The P1 start followed the reset that P0 asked for, so it counts as part of the P0 turn. The P2 session start has no stated cause in the log. If the human started it, that is one touchpoint outside the list, because no item covers a session start.
- **PR state.** Under the ship skill, the pull request raises as a draft while any `Exception waiting` line stands.

## Actions for the human on the loop

1. Review the nine exception lines in the build log. Two labels need a check, the P0 `git rm` approval and the RS-F02 to RS-F04 entry.
2. Review the two credential-scan lines the log names by path and line number, then commit `ravintio-framework/release.yml` if the match is a false positive. Backlog 0000425 tracks the rule.
3. Correct the build-log gaps listed above, including the header rows, the P0 question count, and the backlog count.
