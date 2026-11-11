# Build Report (0000044-credential-scan-word-boundary, 11 Nov 2026)

## Headline findings

- The run reached P7 in `autonomous` mode. Each gate in the log has a recorded basis.
- The cheaper tier carried 11 of 22 agent calls. Validation and archive work ran on the primary tier.
- Model tier is recorded per phase, not per agent call. The cross-model reviewer model is missing from the Header.
- P1 (spec) and P2 (ADRs) ran multiple units inline with zero parallel batches. The log gives only the size-floor reason.
- The orchestrator made an altering deviation from the confirmed design in P5. The log records no human confirmation before the change. Human acceptance is still open before PR #78 merges.
- One self-correction occurred, a Windows CI timing flake fixed by a rerun. Review loops revised 21 findings across P1, P2, P5, and P6.
- The build log has gaps. The `Wall-clock` unit is not labelled, an 18-minute gap between P6 and P7 is unexplained, and the P8 progress line is not yet written.

## Model Usage

| Model tier | Concrete model | Phases used | Agent call count |
|------------|---------------|-------------|-----------------|
| Primary | claude-opus-5-5 | P0 to P7 (orchestrator), review subagents in P1, P2, P4, P5, and P6 | 8 |
| Cheaper | claude-sonnet-5-5 | P0 (Scope Lock drafts), P3 and P5 (TDD subagents), P8 | 11 |
| Cross-model reviewer (not in Header) | claude-fable-5-1 | P6 | 3 |

Orchestrator work done inline is not counted as an agent call.

## Skills Invoked

| Phase | Skill | Load pattern |
|-------|-------|-------------|
| P0 | ravintio-orchestrator | Session start, source copy (installed copy stale) |
| P1 | ravintio-spec-agent | Phase start, source copy, step 1b, run inline |
| P1 | ravintio-design-critic | Two subagent passes |
| P2 | ravintio-adr-agent | Phase start, run inline |
| P2 | ravintio-design-critic | Two subagent passes |
| P3 | ravintio-codegen-agent | Phase start, source copy, step 1b |
| P3 | ravintio-test-writer, ravintio-implementer, ravintio-refactor | One subagent each, TDD cycle |
| P4 | ravintio-validate-agent | Phase start, run inline |
| P4 | ravintio-verify-by-execution | One subagent after CI passes |
| P5 | ravintio-security-agent | Two subagent passes |
| P5 | ravintio-test-writer, ravintio-implementer, ravintio-refactor | One subagent each, TDD cycle for criterion 7 |
| P6 | ravintio-docs-agent | Phase start, source copy, step 1b |
| P6 | ravintio-reversal-assessor | One subagent |
| P7 | ravintio-ship-agent | Phase start, source copy, step 1b |
| P8 | ravintio-build-assessment-agent | Phase start, one subagent |

## Subagent Dispatch

| Phase | Agent type | Count | Purpose |
|-------|-----------|-------|---------|
| P0 | ravintio-scope-lock-agent | 4 | Scope Lock drafts in one parallel batch, cheaper tier |
| P1 | ravintio-design-critic | 2 | Spec review: iteration 1 REJECT, iteration 2 APPROVE |
| P2 | ravintio-design-critic | 2 | ADR review: iteration 1 REJECT, iteration 2 APPROVE |
| P3 | ravintio-test-writer, ravintio-implementer, ravintio-refactor | 3 | TDD cycle for req-001, cheaper tier |
| P4 | ravintio-verify-by-execution | 1 | Verify acceptance criteria by execution |
| P5 | ravintio-security-agent | 2 | Security review and fresh-context re-review |
| P5 | ravintio-test-writer, ravintio-implementer, ravintio-refactor | 3 | TDD cycle for criterion 7, cheaper tier |
| P6 | ravintio-reversal-assessor | 1 | Deviation review |
| P6 | Cross-model reviewer (claude-fable-5-1) | 3 | Iterations 1 and 2 REJECT, iteration 3 APPROVE |
| P8 | ravintio-build-assessment-agent | 1 | This report |

**Total agents spawned:** 22

## Phase Timing

Wall-clock values appear in minutes. The log does not label the unit, and each value matches the truncated whole minutes between the phase `Start` and `End` stamps.

| Phase | Subagents | Parallel batches | Streams | Wall-clock |
|-------|-----------|------------------|---------|------------|
| P0 | 4 | 1 | n/a | 1234 |
| P1 | 2 | 0 | n/a | 5 |
| P2 | 2 | 0 | n/a | 3 |
| P3 | 3 | 0 | n/a | 20 |
| P4 | 1 | 1 | n/a | 58 |
| P5 | 5 | 0 | n/a | 24 |
| P6 | 4 | 1 | n/a | 36 |
| P7 | 0 | 1 | n/a | 1 |
| P8 | 1 | 0 | n/a | pending |
| Total | 22 | 4 | n/a | 1381 (P0 to P7) |

P0 includes the human wait for the design and run-mode confirmations. That wait accounts for 1234 of the 1381 minutes.

## MCP Tool Usage

| Tool | Call count | Purpose |
|------|-----------|---------|
| None recorded | 0 | Every phase row records 0 MCP calls. CI checks ran through `gh`, which the log does not classify as MCP. |

## Parallel Task Bursts

| Phase | Batch count | Tasks parallelised |
|-------|------------|-------------------|
| P0 | 1 | Four Scope Lock drafts, one per item |
| P4 | 1 | Not described in the log |
| P6 | 1 | Documentation edits to seven files, as parallel calls |
| P7 | 1 | Not described in the log |

**Phases with no parallelism:** P1, P2, P3, P5, and P8. P3, P5, and P8 each handled one unit. P1 and P2 are the findings below.

## Self-Corrections

| Phase | Count | Summary |
|-------|-------|---------|
| P4 | 1 | Windows CI shard 3 failed one timing check at 278 ms against a 200 ms limit. The rerun passed with no code change. |

**Total self-corrections:** 1

Review-driven revisions are separate from self-corrections. They total 21 findings: 8 at P1, 5 at P2, 1 medium security finding at P5, and 7 across the P6 iterations.

## Artefact Counts

| Category | Count |
|----------|-------|
| Requirements | 1 (req-001, 7 criteria) |
| ADRs | 2 (ADR-001 and ADR-002, with an amendment to ADR-002) |
| Spec and design artefacts | 8 (design, execution plan, scope, risk register, domain glossary, feature brief, discovery, recommendations) |
| Critic verdicts | 4 |
| Cross-model reviews | 3 |
| Loop state files | 3 |
| Security artefacts | 2 (security report and re-review) |
| Verification artefacts | 2 (verification report and coverage table) |
| Deviation reviews | 1 |
| Pull requests | 1 (#78) |
| Suites passed | 142 feature suites and 37 regression suites |
| New test cases | 15 per suite copy, in 2 copies (8 from P3, 7 from P5) |
| Component files changed | 7 (P7 product summary) |
| Documentation files updated | 7 |
| Backlog entries filed | 4 (0000435 to 0000438) |
| Backlog entries pulled in | 1 (0000425) |
| Changelog files | 2 |
| Archive items moved | 26 |

## Efficiency Observations

### Model routing audit

- **Finding: cheaper-eligible work ran on the primary tier.** P4 validation (lint, test run, and CI checks) ran on the primary tier. The P7 archive moves and the commit ran on the primary tier. The P6 consistency checks and revalidation also ran on the primary tier.
- **Cheaper tier was used.** It carried 11 of 22 agent calls, which is not near zero. Its use covered P0, P3, P5, and P8.
- **Finding: tier is recorded per phase, not per agent call.** The P6 row mixes three models in one entry. The log does not say which model made each fix after each review. Accountability for individual calls is sparse.
- **Finding: the cross-model reviewer is missing from the Header.** The Header lists a primary and a cheaper model only. The P6 reviewer ran on claude-fable-5-1.
- **Finding: the spec-agent skill was loaded but no spec subagent ran.** The P1 spec artefacts were written inline by the orchestrator. The log gives no reason beyond the size floor.

### Parallelism audit

- **Finding: P1 (spec) recorded zero batches and zero spec subagents.** The phase produced eight artefacts inline. The log justifies this under the size floor. It does not show that the spec units were judged not always-parallel.
- **Finding: P2 (ADRs) recorded zero batches and zero ADR subagents.** Two ADRs were written inline. The two decisions were independent, as the log's own notes show. The size-floor reason is thin for a phase that has a dedicated ADR skill.
- **P3 and P5 were sequential by design.** Each TDD cycle depends on the previous red state, so each phase is correctly sequential.
- **Streams were off with one requirement.** The 10-requirement threshold did not apply. Time saved from streams is not captured.
- **P4 and P7 each record one batch with no description.** The log does not name the tasks in these batches.

### Phase gate audit

- **Run mode was `autonomous`, confirmed by the human at P0.** The P0 confirmation records the mode as pre-authorised. `continuous_run` does not apply.
- **P0 gate honoured.** The human confirmed the design and all four Scope Lock drafts.
- **Finding: the orchestrator made an altering deviation in P5 without recorded human confirmation.** The escape-aware pattern replaces the pattern the human confirmed. The P6 deviation review classed it as altering. Human acceptance is still open before PR #78 merges.
- **Finding: P7 proceeded while the P6 exception was open.** The log states that the exception blocks the merge, not the archive. Human action is still required before merge.
- **Minor: edits applied after critic approval were not re-reviewed.** The P1 and P2 loops closed on approval. The orchestrator then applied three P1 and two P2 wording fixes. The log records each fix with a reason.

### P0 question audit

- **P0 questions asked:** 3. `Brief complete` reads `no`, so the count is reported with no flag.
- All three P0 lines are present: `P0 questions asked`, `Brief complete`, and `Stack unchanged`.

### Self-correction audit

- **P4 CI flake (1).** The failure was environmental, from a Windows runner under load. It was not avoidable by the agent. Backlog 0000275 tracks the same timing flake.
- **Spec gaps surfaced at P1 (8 findings).** The first draft named the vendored folder in a form the rule matched before commit. The design's line-start case tested a space, not column 1. ADR cross-references read as local ADRs. These point to spec clarity gaps.
- **P5 medium finding S-001 (avoidable in principle).** The design's pattern did not cover keys after percent or backslash escapes. A threat review at P1 that covered escape sequences would have caught it earlier.
- **P6 prose findings (7 across two rejected iterations).** Several sentences exceeded 25 words in the docs output. A word-limit check before the cross-model review would have removed one review loop.

### Build log integrity

- **All phases P0 to P7 are present.** Each has `Start`, `End`, `Wall-clock`, `Streams`, `Model tier`, `Agents spawned`, `MCP calls`, and `Parallel task batches`.
- **P8 is in progress.** Its `End` and `Wall-clock` read `pending`, as expected at this point.
- **P9 has no entry.** It runs after this report.
- **Finding: the P8 progress line is absent.** The orchestrator must add it when P8 closes.
- **Finding: the P6 to P7 gap is unexplained.** P6 ended at 00:57:36Z and P7 started at 01:15:54Z, an 18-minute gap.
- **Finding: the `Wall-clock` unit is not labelled.** The values match whole minutes from the phase stamps.
- **Minor: test counts are ambiguous.** P3 shows 189 passed for the suite, and P5 shows 196 passed with 14 failed. The log does not say whether these counts are per copy or per assertion.
- **Run mode is `autonomous`.** The touchpoint audit applies. The log contains 0 `Human touchpoint` lines, so no touchpoint finding applies.

### Other efficiency observations

- **Human wait dominated the run.** P0 took 1234 of 1381 minutes. Agent-paced phases P1 to P7 took 147 minutes.
- **One CI rerun cost about 19.5 minutes of CI time.** The Windows shard 3 rerun ran from 23:36:44Z to 23:56:13Z. Backlog 0000432 tracks the slow Windows shards.
- **Stale installed skill copies were detected at P0.** Six installed skills were older than their source copies. The log recommends a `ravintio-refresh-setup` run. The log does not record that run as done.
- **Two review loops closed at approval with wording fixes after.** Re-review of those wording-only changes would have cost one short pass each.
