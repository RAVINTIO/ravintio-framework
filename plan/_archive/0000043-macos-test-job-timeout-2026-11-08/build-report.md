# Build report (0000043-macos-test-job-timeout, 08 Nov 2026)

## Summary

The run completed P0 to P7 with 18 subagents and one recorded self-correction. It recorded no human touchpoints outside the exception list. Three exception items waited for the human on the loop, and all three sit on that list.

Findings to act on:

- The run-mode script prints `interactive`. The header and the P0 confirmation both record `autonomous`. The log cites backlog 0000427.
- The phase blocks leave a 21-minute gap, from 15:18:57Z to 15:40:25Z, with no phase record.
- The P0 block records 2 questions. The log holds 3 question and answer exchanges.
- The run used four models. The header declares two. The P8 tier names `haiku`, which the header does not declare.

## Run mode

Script output: `run-mode: autonomous not anchored: a commit removed or edited the confirmation line`, followed by `interactive`. The header row and the P0 confirmation line both record `autonomous`. The log attributes the mismatch to earlier archive commits on this branch and cites backlog 0000427.

This report treats `autonomous` as the recorded mode. The touchpoint audit runs because the user asked for it. The skill skips that audit when the script prints `interactive`.

## Model usage

| Model tier | Concrete model | Phases used | Agent call count |
|------------|----------------|-------------|------------------|
| Primary | `claude-opus-5-5` | P0 to P7, reopened P4 | 6 |
| Cheaper | `claude-sonnet-5-5` | P0, P3 | 10 |
| Other (not declared in the header) | `claude-fable-5-1` | P6 (cross-model review) | 1 |
| Other (not declared in the header) | `claude-haiku-5-5` | P8 (this report) | 1 |

The P8 tier comes from the ship skill at `ravintio-framework/skills/ravintio-ship-agent/SKILL.md`, line 197, which hard-codes `haiku`. The header declares `claude-sonnet-5-5` as the cheaper model.

## Skills invoked

| Phase | Skill | Load pattern |
|-------|-------|--------------|
| P0 | ravintio-orchestrator | Session start, source copy |
| P0 | ravintio-scope-lock-agent | 4 parallel subagents |
| P1 | ravintio-spec-agent | Source copy |
| P1 | ravintio-design-critic | 2 subagents |
| P1 | ravintio-loop-runner | Loaded |
| P2 | ravintio-adr-agent | Installed copy, no subagent recorded |
| P2 | ravintio-design-critic | 1 subagent |
| P3 | ravintio-codegen-agent | Source copy |
| P3 | ravintio-test-writer, ravintio-implementer, ravintio-refactor | Per requirement, TDD loop |
| P4 | ravintio-validate-agent, ravintio-verify-by-execution | Installed copy |
| P4 (reopened) | ravintio-validate-agent, ravintio-loop-runner | Loaded |
| P5 | ravintio-security-agent | Installed copy, 2 subagents |
| P6 | ravintio-docs-agent | Source copy |
| P6 | ravintio-reversal-assessor | 1 subagent |
| P7 | ravintio-ship-agent | Source copy |
| P8 | ravintio-build-assessment-agent | 1 subagent (this report) |

## Subagent dispatch

| Phase | Agent type | Count | Purpose |
|-------|-----------|-------|---------|
| P0 | ravintio-scope-lock-agent (cheaper) | 4 | Scope Lock drafts |
| P1 | ravintio-design-critic (primary) | 2 | REJECT on iteration 1, APPROVE on iteration 2 |
| P2 | ravintio-design-critic (primary) | 1 | ADR review, APPROVE |
| P3 | Test-writer, implementer, refactor (cheaper) | 6 | TDD for 2 requirements |
| P5 | Security and re-review (primary) | 2 | Security review, then re-review of fixes |
| P6 | Reversal assessor (primary) and cross-model reviewer (`claude-fable-5-1`) | 2 | Deviation review and cross-model review |
| P8 | Build assessment (haiku) | 1 | This report |

**Total agents spawned:** 18

## Phase timing

| Phase | Subagents | Parallel batches | Streams | Wall-clock |
|-------|-----------|------------------|---------|------------|
| P0 | 4 | 1 | n/a | 17 min |
| P1 | 2 | 0 | n/a | 8 min |
| P2 | 1 | 0 | n/a | 3 min |
| P3 | 6 | 0 | n/a | 58 min |
| P4 | 0 | 1 | n/a | 16 min |
| P5 | 2 | 0 | n/a | 4 min |
| P6 | 2 | 1 | n/a | 19 min |
| P4 (reopened) | 0 | 1 | n/a | 22 min |
| P7 | 0 | 1 | n/a | 4 min |
| P8 | 1 | 0 | n/a | pending |
| Total | 18 | 5 | n/a | 151 min |

The phase blocks sum to 151 minutes. The run took 182 minutes from pipeline start (13:08:01Z) to P7 end (16:10:18Z). The 31-minute difference sits in the gaps between blocks. The largest gap is 21 minutes 28 seconds, between P6 and the reopened P4.

## MCP tool usage

| Tool | Call count | Purpose |
|------|-----------|---------|
| None recorded | 0 | Every phase block records `MCP calls: 0`. |

## Parallel task bursts

| Phase | Batch count | Tasks parallelised |
|-------|------------|--------------------|
| P0 | 1 | 4 Scope Lock drafts |
| P4 | 1 | Not named in the log |
| P4 (reopened) | 1 | Not named in the log |
| P6 | 1 | Four documentation edits as parallel calls |
| P7 | 1 | Not named in the log |

**Phases with no parallelism:** P1, P2, P3, P5, and P8.

## Self-corrections

| Phase | Count | Summary |
|-------|-------|---------|
| P4 | 0 | Original pass. The log records none. |
| P4 (reopened) | 1 | Check: req-001 AC2 (CI timing). MacOS shard 1 of 2 ran over 600 seconds in 2 of 4 runs. Fixed by moving to 3 shards. |

**Total self-corrections:** 1

Revision events the log does not label as self-corrections:

- P1: the critic returned REJECT on iteration 1 with 8 findings. All 8 were revised.
- P3: a test defect in the req-002 suite. `awk -v` altered the backslashes, and the orchestrator fixed it.
- P5: security findings S-001 and S-002, fixed and re-reviewed.
- P6: one cross-model finding, fixed after revalidation.

## Artefact counts

| Category | Count |
|----------|-------|
| Requirements | 2 |
| ADRs | 4 |
| Critic verdicts | 3 |
| Security reports | 2 |
| Verification and coverage reports | 2 |
| Deviation review | 1 |
| Cross-model review | 1 |
| Changelog files | 2 |
| New test suites | 2 |
| CI matrix entries | 10 before the reopen, 11 after |
| Components changed | 1 (`ravintio-framework`, 0.39.1 to 0.39.2) |
| Decisions recorded | 14 |
| Deviations recorded | 3 (2 altering, 1 additive) |
| Exception waits | 3 |
| Human touchpoints | 0 |
| Backlog entries filed | 3 (0000432, 0000433, 0000434) |
| Backlog entries pulled in | 1 (0000430) |
| CI runs cited | 5 |

## Efficiency observations

- P3 took 58 minutes, which is 38% of the phase-block time. Its six subagents ran in sequence. The log gives a dependency reason, because req-002 reads `matrix.cap` that req-001 adds. The serial order holds.
- The P4 reopen cost 22 minutes and one more CI run. The CI run on `68a500d5` passed, but its macOS shard missed the 600-second target. The 3-shard run on `1b44f04e` passed.
- One of the five cited CI runs failed on a Windows timing test under runner load. The log files this as backlog 0000433.
- A Claude Code safety check refused one compound shell command in P7, which ran `rm -rf` on a variable path inside `bash -c`. Nothing in the command ran. The refusal did not reach the human.

## Critical audit

### Model routing audit

- **Primary tier.** The primary tier ran P0 to P7 and the reopened P4. Judgement work, such as critic passes, security review, and the reversal assessment, suits this tier.
- **Flag: cheaper-eligible work at the primary tier.** P4 validation (lint, test runs, CI reads) and the P7 archive and scan steps ran at the primary tier with no subagents. The skill names validation and formatting as cheaper-eligible. The log records no decision to keep this work at primary.
- **Cheaper tier.** The cheaper tier handled 10 of 18 calls: 4 Scope Lock drafts in P0 and 6 TDD subagents in P3. Routing is not near zero.
- **Flag: sparse records.** The log records tiers per phase, not per agent call. It names model IDs only in P3 and P6. P0, P1, P2, and P5 give no model ID for their subagents.
- **Flag: undeclared models.** The run used four models. The header declares two. The P8 tier also conflicts with the header's cheaper model.

### Parallelism audit

- **Flag: P2.** Four ADRs ran inline with zero batches. The log says each ADR is one file from context already held. ADR-003 and ADR-004 cite ADR-002, but the log does not link ADR-001 to the others. Small independent units should run as parallel tool calls in one message. The log records no such batch.
- **Not flagged: P1.** The critic passes ran in sequence. Pass 2 checks the fixes from pass 1, so the order holds. The spec units ran inline under a size-floor reason.
- **Not flagged: P3.** The six subagents ran in sequence for a dependency reason. See the efficiency observations.
- **Not flagged: P5.** The security review ran before the re-review of its fixes. That order is a dependency.
- **Flag: P6, not evidenced.** Two agents ran in P6. The log does not say whether they dispatched in one message. The log also does not say whether their inputs depended on each other.
- **Flag: header wording.** The header reads `off (one unit of work)`, but the log records two requirements. The 10-or-more rule does not apply, so no flag follows from it.

### Phase gate audit

- **Pre-authorisation.** The human pre-authorised `autonomous` at P0. The human answered `3` and confirmed the design.
- **Gates P1 to P6.** `continuous_run` auto-accepted these gates. The P6 documentation gate also auto-accepted.
- **Exception items.** The run recorded 3 waits, all on the list (items 2, 2, and 7). The run continued after each one, as the standard requires.
- **Deviation review.** The reversal assessor classed the P1 and P5 deviations before P7. It classed the reopened P4 deviation before P7 too.
- **Skipped gates.** None found. The 21-minute gap is a logging gap, covered under build log integrity.

### P0 question audit

- The P0 block records 2 questions, `Brief complete: no`, and `Stack unchanged: yes`. The NFR-002 flag needs a count above 3 with both lines reading `yes`, so no flag applies.
- **Flag: undercount.** The log holds 3 P0 question and answer exchanges. They are the CI approach, the combined confirmation (answered `3`), and the follow-up (answered "accept all"). The record undercounts by one.

### Self-correction audit

- One self-correction was recorded, at the P4 reopen. It was partly avoidable. The design chose 2 macOS shards against a 10-minute criterion. The log cites risk R-001 (runner variance) for the fix, so the risk existed before the design gate. The variance showed only across four runs.
- **Flag: rationale.** The log says the 10-minute rule came from ADR-002 at P2, after the human gate. The P0 Scope Lock, which the human accepted, already states that each shard finishes in under 10 minutes. The rule was confirmed at P0. The P4 rationale needs a correction.
- Four revision events sit outside the self-correction count. That is not a high count for a feature with two requirements.

### Build log integrity

- **Phases represented.** P0 to P7 and the reopened P4 are present. P8 is open. P9 has not run. Neither has a progress line yet, which is expected.
- **Per-phase fields.** Every block from P0 to P7 records Start, End, Wall-clock, Streams, Model tier, Skills loaded, Agents spawned, MCP calls, and Parallel task batches. P8 shows `pending` for End and Wall-clock, as expected.
- **Flag: unlogged gap.** No phase block covers 15:18:57Z to 15:40:25Z, a span of 21 minutes 28 seconds. The log does not explain it. Mark it as not captured.
- **Flag: skill loaded, not used.** P2 lists `ravintio-adr-agent` as loaded, but records only the critic as a subagent. The ADRs ran inline. The entry suggests a use the log does not show.
- **Progress lines.** Nine are present, one each for P0 to P7 and the reopened P4.

### Human touchpoint audit

This audit runs on the user's instruction. The skill skips it when the script prints `interactive`.

- **Touchpoints after the P0 confirmation (2026-11-08T13:25:13Z).** Zero `Human touchpoint` lines.
- **Exception waits.** Three. Each is an exception item, so none counts as a touchpoint under the standard.
  - `Exception waiting (P4, 2)`: the 3-shard deviation, classed altering. Exception item 2.
  - `Exception waiting (P6, 2)`: the P1 job backstop of 25 minutes, classed altering. Exception item 2.
  - `Exception waiting (P7, 7)`: a credential sighting in `ravintio-framework/release.yml`, which the log records as a known false positive. Exception item 7.
- **Touchpoints outside the exception list.** Zero.
- **Flag: definition.** The standard defines a gross deviation as an altering change, then narrows it to changes to the problem, the users, or the in-scope list. The reversal assessor defines altering as a change to what the human confirmed. The two definitions differ. The assessor's reason for the 3-shard move also says the problem and the users do not change. The run took the more cautious class. The human should settle which definition holds.
