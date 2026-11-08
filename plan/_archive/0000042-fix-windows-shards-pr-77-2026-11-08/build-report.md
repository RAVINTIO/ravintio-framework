# Build Report (0000042-fix-windows-shards-pr-77, 08 Nov 2026)

## Summary

- The most serious finding is S-1, a High defect from the 0000042 diff. P3 and P4 did not catch it. P5 did.
- The log records four P6 exception items and one P7 exception item. It records no human decision on the four P6 items before P7 archived the run.
- The `run-mode.mjs` check prints `interactive` and reports the anchor as broken. The `Run mode` row still reads `autonomous`.
- The human touchpoint count is 0 in the log. The log uses other labels for human waits, so this count does not prove that no waits occurred.

## Model Usage

| Model tier | Concrete model | Phases used | Agent call count |
|------------|---------------|-------------|-----------------|
| Primary    | claude-opus-5-5 | P0 (orchestrator), P1, P2, P3 (orchestration), P4, P5, P6, P7 | 6 recorded at phase level (P1, P2, P6). P5 tier is not captured per call. |
| Cheaper    | claude-sonnet-5-5 | P0, P3, P4, P5 | 10 recorded (P0 4, P3 3, P4 1, P5 2) |
| Not in header | claude-haiku-5-5 | P8 (this run) | 1 |

The log's P8 row names the cheaper tier. This run used `claude-haiku-5-5`, which the header does not list.

## Skills Invoked

| Phase | Skill | Load pattern |
|-------|-------|-------------|
| P0    | ravintio-orchestrator | Not captured |
| P0    | ravintio-scope-lock-agent (4 subagents) | Not captured |
| P1    | ravintio-spec-agent | Not captured |
| P1    | ravintio-design-critic (2 iterations) | Not captured |
| P2    | ravintio-adr-agent | Not captured |
| P2    | ravintio-design-critic (2 iterations) | Not captured |
| P3    | ravintio-codegen-agent | Not captured |
| P3    | ravintio-test-writer | Not captured |
| P3    | ravintio-implementer | Not captured |
| P3    | ravintio-refactor | Not captured |
| P4    | ravintio-validate-agent | Not captured |
| P4    | ravintio-verify-by-execution | Not captured |
| P5    | ravintio-security-agent (2 reviews) | Not captured |
| P5    | ravintio-test-writer | Not captured |
| P5    | ravintio-implementer | Not captured |
| P6    | ravintio-docs-agent | Not captured |
| P6    | ravintio-reversal-assessor | Not captured |
| P6    | Cross-model reviewer (skill not named in log) | Not captured |
| P7    | ravintio-ship-agent (installed copy stale, source copy used for Step 5c) | Not captured |
| P8    | ravintio-build-assessment-agent | Not captured |

## Subagent Dispatch

| Phase | Agent type | Count | Purpose |
|-------|-----------|-------|---------|
| P0    | ravintio-scope-lock-agent | 4 | One Scope Lock draft per item |
| P1    | ravintio-design-critic | 2 | Spec critique: iteration 1 REJECT, iteration 2 APPROVE |
| P2    | ravintio-design-critic | 2 | ADR critique: iteration 1 REJECT, iteration 2 APPROVE |
| P3    | test-writer, implementer, refactor (TDD) | 3 | RED, GREEN, and refactor for req-001 |
| P4    | ravintio-verify-by-execution | 1 | Verify AC1 to AC3 by execution |
| P5    | ravintio-security-agent and fresh-context re-review | 2 | Security review, then re-review after the fix |
| P5    | test-writer, implementer (TDD) | 2 | RED and GREEN for S-1 and S-7 |
| P6    | ravintio-reversal-assessor | 1 | Purpose not recorded in log |
| P6    | Cross-model reviewer (claude-opus-5-5) | 1 | Doc review: APPROVE on iteration 1 |
| P8    | ravintio-build-assessment-agent | 1 | This report |

**Total agents spawned:** 19 (P0 to P8, including this run)

## Phase Timing

Wall-clock values are minutes. The values come from the log and match the Start and End timestamps.

| Phase | Subagents | Parallel batches | Streams | Wall-clock |
|-------|-----------|------------------|---------|------------|
| P0    | 4 | 1 | n/a | 410 |
| P1    | 2 | 0 | n/a | 6 |
| P2    | 2 | 0 | n/a | 6 |
| P3    | 3 | 0 | n/a | 4 |
| P4    | 1 | 1 | n/a | 30 |
| P5    | 4 | 0 | n/a | 39 |
| P6    | 2 | 1 | n/a | 26 |
| P7    | 0 | 1 | n/a | 1 |
| P8    | 1 | 0 | n/a | pending |
| Total | 19 | 4 | n/a | 522 (P0 to P7) |

## MCP Tool Usage

| Tool | Call count | Purpose |
|------|-----------|---------|
| None recorded | 0 | Every phase logs 0 MCP calls |

## Parallel Task Bursts

| Phase | Batch count | Tasks parallelised |
|-------|------------|-------------------|
| P0    | 1 | Four Scope Lock drafts, one per item |
| P4    | 1 | Local full suite alongside the PR #77 CI run |
| P6    | 1 | All doc edits in one batch |
| P7    | 1 | Cross-reference search alongside the regression-candidate scan |

**Phases with no parallelism:** P1, P2, P3, P5. Each phase runs dependent steps. P8 is one unit of work.

## Self-Corrections

| Phase | Count | Summary |
|-------|-------|---------|
| P4    | 0     | The log records zero validate self-correct cycles. |

**Total self-corrections:** 0 recorded. Section "Self-correction audit" lists the corrections that the log describes without counting them.

## Artefact Counts

| Category | Count |
|----------|-------|
| Requirements | 1 (req-001, 3 acceptance criteria, 2 functional requirements added at P5) |
| ADRs | 4 |
| Critic verdicts | 4 |
| Loop state files | 2 |
| Security reports | 2 (`security-report.md`, `security-rereview.md`) |
| Cross-model reviews | 1 |
| Test suites | 1 added, 2 changed, plus `tests/README.md` |
| Backlog entries cited or filed | 0000426 (pulled in), 0000427, 0000428, 0000429, 0000430, 0000431 |

The archive holds 1 requirement file and 4 ADR files, which match the log.

## Efficiency Observations

- The run used 522 minutes across P0 to P7. P0 used 410 minutes, which is 79 percent of that time. The log does not separate agent time from human wait time in P0.
- P4 and P5 spent 69 minutes, mostly on CI. The run needed two CI reruns: a Windows shard 4 timing flake (backlog 0000265) and a macOS 15-minute timeout (backlog 0000430).
- Both design critics rejected their first draft. Each rejection led to a design revision, and the revisions drove the P3 scope deviation.
- Scope grew after validation. P3 added a suite and a README row. P5 added two functional requirements. Each change needed re-review or revalidation, and P5 and P6 took 65 minutes together.
- Six installed skills are stale. The installed ship skill lacked Step 5c, so P7 read the source copy. The log already recommends a `ravintio-refresh-setup` run after PR #77 merges.
- P6 doc edits and P7 archive steps ran on the primary tier. Both are cheaper-eligible work.

## Critical Audit

**Model routing audit**
- The primary tier ran P0 orchestration, the P1 and P2 critics, P4 validation, the P5 security review, P6 docs and reviews, and P7 archive.
- Cheaper-eligible work ran on the primary tier. P6 doc edits and P7 archive steps are mechanical. The log gives no reason for the primary tier on those steps.
- The cheaper tier ran at least 10 agent calls. Usage is not near zero, so this audit raises no zero-usage flag.
- Tier decisions are recorded per phase, not per agent call. The tier of the P5 re-review is not recorded. Flagged as a sparse log.
- The header lists `claude-sonnet-5-5` as the cheaper model. This report ran on `claude-haiku-5-5`, and the log records no entry for it. Flagged.

**Parallelism audit**
- Phases with zero batches: P1, P2, P3, P5. Each phase runs dependent steps. The critic iterations depend on the prior findings, and the TDD steps depend on the step before. The P5 fixes touched the same suite files, so they could not run in parallel. These phases are not flagged.
- P0 ran four Scope Lock drafts in one batch. This is evidenced.
- P6 recorded two subagents. The log does not say whether the cross-model reviewer and the reversal assessor went out in one message. Not evidenced. Flagged.
- Streams are `off` with one requirement. The 10-requirement scalability rule does not apply.

**Phase gate audit**
- The P0 combined confirmation recorded "Accept all and Autonomous". The human pre-authorised the autonomous mode at P0.
- The log calls the P6 and P7 mode "continuous run" and the header calls it `autonomous`. Flagged as a terminology gap in the log.
- Gates P1 to P6 are recorded as "Gate (Px)" lines. Under the P0 authorisation, these did not wait for a human.
- P6 recorded four exception items that "wait for the human on the loop". The log records no decision on them before P7 archived the run. Two of the four change an `rm -rf` guard and add a suite outside the confirmed in-scope list. Flagged as a process concern for the human on the loop.
- P7 recorded a credential exception on `ravintio-framework/release.yml`. The file stays held back, and the log records no decision on it.
- P1 armed the design critic loop after iteration 1, not before. The ratchet guard did not cover that iteration. Flagged as a process deviation.

**P0 question audit**
- The log records `P0 questions asked: 2`.
- The P0 block lists three exchanges: the branch choice, the happy-path Scope Lock draft, and the combined confirmation. The count and the exchanges disagree. Flagged as a build-log gap.
- `Brief complete` reads `no`, so the count does not trigger the NFR-002 flag.
- All three header lines are present.

**Self-correction audit**
- The log records 0 self-correct cycles in P4. It does not count the corrections below.
- **S-1 (High, P5): avoidable.** A failed `mktemp` made the `WORK` path the caller's folder, and the `EXIT` trap deleted it. The 0000042 diff introduced the defect. P3 GREEN and P4 validation both passed. The codegen assumed `mktemp` succeeds, and no test covered the failure path.
- **P4 environment variable: avoidable.** The orchestrator set `RAVINTIO_PASS_COMMIT` to this run's head, which failed 0000039. Rerunning without the variable passed.
- **P1 and P2 critic rejections: partly avoidable.** The spec did not name the path conversion method. The ADR set did not state the scope of ADR-004. Both gaps surfaced in iteration 1.
- **P3 deviation: avoidable.** The design did not foresee a guard for the new suite. The third README row followed from that gap.
- Pattern: the rework came from spec gaps and one codegen assumption about failure paths. The spec and codegen should state failure paths for shell `mktemp` and `cd` calls.

**Build log integrity**
- P0 to P7 each have a progress line. P8 has none yet, which is expected while P8 runs.
- P0 to P7 populate Start, End, Wall-clock, Streams, model tier, agent count, MCP calls, and parallel batches.
- The P8 row shows `pending` for End and Wall-clock. The P8 owner fills these fields when the phase closes. This agent does not edit the log.
- `run-mode.mjs` prints `interactive` with the message "not anchored: a commit removed or edited the confirmation line". The anchor is commit `e2c82a17`, and the removal is `ecdc151d`. Backlog 0000427 tracks this check. The `Run mode` row still reads `autonomous`. Flagged.

**Human touchpoint audit**
- `run-mode.mjs` prints `interactive`, so the skill's condition for this audit is not met on its own. This run applies the audit because the operator instructed it and the P0 block confirms autonomous mode.
- Lines labelled "Human touchpoint": 0. Lines outside the exception list: 0.
- The skill text does not list the exceptions. The log records human waits under other labels: three P0 exchange lines and five "Exception waiting" lines. The audit cannot check those against an exception list. Flagged as a log gap.
