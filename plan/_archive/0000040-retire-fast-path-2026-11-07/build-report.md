# Build report (0000040-retire-fast-path, 07 Nov 2026)

Source: `plan/_archive/0000040-retire-fast-path-2026-11-07/build-log.md`. Run mode is `autonomous`, as `run-mode.mjs` reports. Every figure comes from the build log unless the text marks it as inferred.

## Summary

The run reached P7 with every phase gate passed. P8 is this report. Three findings need attention:

- Cheaper-tier routing was low, and the log records no tier for 40 of 45 agent calls.
- The log records one Hard Limit 8 breach (`git stash`, P6). It also shows one probable breach (`git rm`, P3).
- The P5 security defect caused the longest phase, at 10h 50m wall-clock. The log has no touchpoint line for that wait.

## Model usage

| Model tier | Concrete model | Phases used | Agent call count |
|------------|---------------|-------------|-----------------|
| Primary | `claude-opus-5-5` | P0 to P7, excluding the sonnet calls below | 39 |
| Cheaper | `claude-sonnet-5-5` | P0 (scope-lock drafts), P6 (cross-model review) | 5 |
| Other | `claude-haiku-5-5` | P8 (this report) | 1 |

The primary count excludes five calls that the notes place on sonnet. The P0 and P6 phase fields both read `primary`, so those fields undercount the cheaper tier. The header names the cheaper model as the alias `sonnet` and does not list a haiku tier.

## Skills invoked

| Phase | Skill | Load pattern |
|-------|-------|-------------|
| P0 | ravintio-orchestrator | Session start |
| P0 | ravintio-scope-lock-agent | Four parallel drafts, not recorded in the skills field |
| P1 | ravintio-spec-agent | Four subagents |
| P1 | ravintio-design-critic | Nine runs, not recorded in the skills field |
| P1, P2 | ravintio-loop-runner | Loop mechanics |
| P2 | ravintio-adr-agent | Six subagents |
| P2 | ravintio-design-critic | Two runs, not recorded in the skills field |
| P3 | ravintio-codegen-agent, ravintio-test-writer, ravintio-implementer, ravintio-refactor | Inside six subagents |
| P4 | ravintio-validate-agent | Phase start |
| P4 | ravintio-verify-by-execution | Subagent |
| P5 | ravintio-security-agent | Three subagents |
| P5, P6 | ravintio-reversal-assessor | Subagent, for defect 001 (P5) and the deviation review (P6) |
| P6 | ravintio-docs-agent | Three subagents |
| P6 | ravintio-migrator | Migration step |
| P6 | Cross-model review skill | Not named in the log |
| P7 | ravintio-ship-agent | Phase start |
| P8 | ravintio-build-assessment-agent | Subagent |

## Subagent dispatch

| Phase | Agent type | Count | Purpose |
|-------|-----------|-------|---------|
| P0 | ravintio-scope-lock-agent | 4 | One Scope Lock draft per item |
| P1 | ravintio-spec-agent | 4 | Requirement groups in one batch |
| P1 | ravintio-design-critic | 9 | Critic loop across three approaches |
| P2 | ravintio-adr-agent | 6 | ADR-002 to ADR-007 |
| P2 | ravintio-design-critic | 2 | ADR critic loop |
| P3 | ravintio-codegen-agent (TDD steps) | 6 | One TDD unit per requirement, or per pair |
| P4 | Validate and verify agents | 2 | Coverage table, verify-by-execution |
| P4 | TDD fix agent | 1 | Cycle 1 fix |
| P5 | ravintio-security-agent | 3 | Hooks, pre-push and CI, setup and migrator |
| P5 | ravintio-reversal-assessor | 1 | Defect 001 verdict (DENY, altering) |
| P5 | TDD fix agent | 1 | Req-005 fix for findings S-1, S-4, and S-5 |
| P6 | ravintio-docs-agent | 3 | Living docs, component docs, recommendations and changelog |
| P6 | Deviation review | 1 | Review of 26 deviation rows. The log names no skill. |
| P6 | Cross-model review | 1 | Sonnet reviewer, opus implementer |
| P8 | ravintio-build-assessment-agent | 1 | This report |

**Total agents spawned:** 45, including this report agent.

## Phase timing

| Phase | Subagents | Parallel batches | Streams | Wall-clock |
|-------|-----------|------------------|---------|------------|
| P0 | 4 | 1 | n/a | 4d 20h 57m (includes idle time between sessions) |
| P1 | 13 | 1 | n/a | 2h 04m (includes about 1h 29m waiting on exception 6) |
| P2 | 8 | 1 | n/a | 14m |
| P3 | 6 | 3 | n/a | 1h 40m |
| P4 | 3 | 2 | n/a | 52m (excludes a session break of about 12h 40m) |
| P5 | 5 | 1 | n/a | 10h 50m (wait duration not captured) |
| P6 | 5 | 2 | n/a | 1h 19m (includes about 55m waiting on exception 1) |
| P7 | 0 | 1 | n/a | 18m |
| P8 | 1 | 0 | n/a | Not captured (open when this report ran) |
| Total | 45 | 12 | | 6d 3h 01m from pipeline start to P7 end |

## MCP tool usage

| Tool | Call count | Purpose |
|------|-----------|---------|
| None recorded | 0 | Every phase reads `MCP calls: 0`. |

## Parallel task bursts

| Phase | Batch count | Tasks parallelised |
|-------|------------|-------------------|
| P0 | 1 | Four Scope Lock drafts |
| P1 | 1 | Four spec subagents |
| P2 | 1 | Six ADR subagents. ADR-001 was written in the main thread. |
| P3 | 3 | Batch 1: four TDD units. Batch 2: req-007. Batch 3: req-006. Batches 2 and 3 each hold one unit, for a recorded dependency reason. |
| P4 | 2 | Batch 1: coverage table and verify-by-execution, with the full suite run inline. Batch 2 is not described. The log order suggests it held the cycle 1 fix (inferred). |
| P5 | 1 | Three security reviewers |
| P6 | 2 | Batch 1: three docs agents. Batch 2 is not described. |
| P7 | 1 | Not described. The phase spawned no agents. |
| P8 | 0 | Single task |

**Phases with no parallelism:** P7 (no agents, one batch with no recorded contents) and P8 (single task).

## Self-corrections

| Phase | Count | Summary |
|-------|-------|---------|
| P4 | 1 | Cycle 1 added a PowerShell 5.1 test, link and failed-delete cases, and a check for the linked-folder rerun deletion. |
| P5 | 1 | Defect 001 fix. The migration could record a blocked CI edit as applied. The fix adds `blocked` and `refused` skipped reasons. |
| P6 | 6 | Three doc drift fixes, one glossary term added, and two stale verification notes closed (X-001, X-002). |

**Total self-corrections:** 8

The P1 critic loop (nine REJECT passes) and the P2 critic loop (one REJECT pass, then one APPROVE) are review revisions. The report does not count them as self-corrections.

## Artefact counts

| Category | Count |
|----------|-------|
| Requirements | 7 |
| ADRs | 7 (ADR-001 to ADR-007) |
| Critic verdicts | 11 (9 in P1, 2 in P2) |
| Cross-model verdicts | 1 |
| Security findings | 15 (1 Medium, 12 Low, 2 Info) |
| Verification criteria | 21 (17 verified, 0 failed, 4 not verifiable at P4) |
| Defect reports | 1 (001) |
| Deviation rows | 26 (25 additive, 1 altering) |
| Decision lines | 76 |
| Exception waits | 3 (P1, P5, P6) |
| Human touchpoint lines | 1 |
| Backlog entries created | 19 (0000361, and 0000364 to 0000381) |
| Feature suites | 131 at P4 (130 passed, 1 failed on version checks, cleared at P7) |
| Regression suites | 36 at P4, 37 after P7 promotion |

## Critical audit

### Model routing audit

- Primary tier ran every phase except the calls the notes place on sonnet. The P0 and P6 fields record `primary` for those calls, so the fields are wrong.
- Cheaper-eligible tasks ran on primary. These include the P4 coverage table, the P6 docs agents, the P5 secrets scan (run inline), and the P7 changelog and test report (written inline).
- Expected: cheaper tier for those tasks. Actual: primary. The log records no routing decision for them.
- The cheaper tier handled 5 of 45 calls, or 11%. It was not zero, but it was low.
- Per-call tier is recorded for 5 calls only. The other 40 calls have no tier record. This is an accountability gap.
- The header omits the haiku tier that P8 used.

### Parallelism audit

- P8 has zero batches. It is a single task, so no parallelism applies.
- P7 recorded one batch and zero agents. The log does not name the batch. The test report, changelog, and cross-reference check had no recorded dependency on each other. Parallelism is not evidenced for P7.
- P4 batch 2 and P6 batch 2 record no contents. This is a log gap.
- P0, P1, P2, and P5 each dispatched their independent units in one batch. Not flagged.
- The nine P1 critic passes and two P2 critic passes ran in sequence. Each pass reviewed a revised design, so the passes were not independent. Not flagged.
- P3 batches 2 and 3 each held one unit, and the log records why. Not flagged.
- The header row `Parallel streams` reads `pending` from P0 onward and never changes. P1 chose subagents over stream files (P1 decision, line 93). No stream comparison is possible.
- The run has 7 requirements. The 10-requirement scalability check does not apply.

### Phase gate audit

- The human set `autonomous` at P0 on 2026-11-05. That choice pre-authorised the run. `continuous_run` does not apply.
- Gate lines exist for P0 to P6. P7 has no gate line. This is a log gap.
- P1 passed after the human chose option 3 for exception 6. The four fixes written after escalation were marked unreviewed. P3 fixtures tested them later, with 13 of 13 algorithm fixtures passing. This was a recorded human choice, not a violation.
- P6 Gate B (docs update assessment) was auto-accepted under `autonomous`. The log records it, but it produced no touchpoint line.
- No gate was skipped without a condition.

### P0 question audit

- P0 questions asked: 9. Brief complete: no. Stack unchanged: yes.
- Not flagged. The NFR-002 flag needs both lines to read `yes`.
- The log holds 12 P0 exchange lines, not 9. The counter may not match the exchanges. This is a log gap.

### Self-correction audit

- **P4 cycle 1: avoidable.** Criterion 3 needed a PowerShell 5.1 test, and the req-004 suite hard-coded `pwsh`. Two cleanup branches had no tests. P3 TDD should have caught both. Verify-by-execution also found the linked-folder rerun deletion, which the P3 suite missed. The cause is a test coverage gap, not a spec gap.
- **P5 fix: avoidable with a spec change.** Req-005 and ADR-006 defined no outcome for a blocked or refused CI edit. The design also contradicted itself on the no-design `gate-write` case. P4 verify-by-execution used a scratch consumer built from `main`, which did not exercise a hooked consumer. The cause is a spec gap and a verification gap.
- **P6 drift: partly avoidable.** P3 changed behaviour, and the living docs drifted in three places. The P3 rewrite did not cover those lines.
- **P1 critic loop (not counted as self-corrections):** Most findings concerned internal consistency, mainly file ownership and cross-references. The consistency check reported clean at iteration 1 (line 118), so it did not test ownership. This is a spec-clarity signal.
- **Overall:** 8 self-corrections on a seven-requirement feature. The P1 findings and the P5 gap point at the spec and ADRs. The log records no codegen-agent assumption that should have been escalated.

### Build log integrity

- Phases P0 to P7 are present. P8 is open, so its end and wall-clock are blank. P9 is absent, which is expected because P9 follows P8.
- Progress lines exist for P1, P2, P3, P4, P6, and P7. **P5 has no progress line.** This is a finding.
- Per-phase fields are populated for P0 to P7. The `Streams` row reads `n/a` in every phase, while the header reads `pending`.
- The skills field omits the design critic (11 runs), the Scope Lock agent (4 runs), and the cross-model review skill.
- The P6 agent list names a deviation review. The P6 skills field names the reversal assessor. The log does not say which agent ran the review.
- **Deviation label (P2):** Row 2 reads `additive, destructive`. The deviating agent set the label. The autonomous standards say the deviating agent never classifies its own deviation. The P6 review superseded the label, so the end state is unchanged. This finding is low.
- **Hard Limit 8, P6:** The component-docs agent ran `git stash` and `git stash pop` for a baseline. The log records this as a breach. The pop restored every file.
- **Hard Limit 8, P3:** The orchestrator ran `git rm` on `test-0000033-req-011`. The log records this as a decision and files backlog 0000366. Under Hard Limit 8, a deletion through git is a Bash change to a project file. This is a probable breach.
- **Hard Limit 8, P7:** The log does not record the route for the `product.yml` and `docs/about.md` edits. The route must be Write, Edit, or a sanctioned script.
- **Backlog IDs:** The run created 19 entries. IDs 0000362 and 0000363 do not appear in this log. An untracked folder, `plan/backlog/0000362-subagent-task-classifier/`, exists in the working tree at session start. It is outside this run's record, so the orchestrator should check it.

### Human touchpoint audit (autonomous)

- Touchpoint lines recorded: 1 (P1, exception 6). Touchpoints outside the exception list: 0.
- **Two waits have no `Human touchpoint` line.** P5 (altering design, line 304) matches item 2, gross deviation, by its altering label. The log names no item number. P6 (exception 1, destructive, line 335) matches item 1. Both items are on the list. The standard requires a touchpoint line for each wait, so this is a finding.

## Efficiency observations

- **P5 was the longest phase.** It ran 10h 50m, and the log records no wait duration. The spec gap behind it sits in ADR-006 and req-005. P1 to P4 reviewed both documents without finding it. A hooked-consumer case in verify-by-execution would likely have caught it before P5.
- **The P1 critic loop cost the most review time.** It ran nine passes, exhausted the approach budget, and waited for the human on exception 6. A file-ownership check before the critic loop would likely have shortened it.
- **Cheaper-tier routing is the largest cost lever in the log.** Five of 45 calls used it. The P4 coverage table, the P6 docs agents, and the P7 inline writing are candidates. Per-call tier records would make this auditable.
- **Two classes of gap reached review without tests.** P3 left link and failed-delete branches untested. P1 left the blocked-edit outcome undefined. Both surfaced late, at P4 and P5.
- **The Hard Limit 8 breaches need follow-up.** Backlog 0000225, 0000304, and 0000113 track the `git stash` breach. Backlog 0000366 tracks the `git rm` route. The P7 route for the `product.yml` edit should be recorded.
- **Stream data is missing.** The header's `Parallel streams` row stayed `pending`. No stream comparison or time-saved figure is possible for this run.
