# Design-Critic Verdict (iteration p2-1)
**Mode:** on
**Mechanical check:** clean (`consistency-check: clean`, exit 0)
**Overall:** APPROVE

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | req-001 ACs name `gh pr checks 77`, `gh run view` durations, and `Suites run` totals. req-002 ACs name fixed inputs (16 min with cap 15, 9 and 11 min with cap 15). See finding 1 for the AC1 log match. |
| 2 Traceability | pass | req-001 Source US-001, req-002 Source US-002. The brief holds US-001 and US-002 only. |
| 3 Real decisions | pass | ADR-001: Marketplace Action, move the workflow. ADR-002: raise the cap, keep the job expression, cap minus one. ADR-003: runner timing, script file, API. ADR-004: P9 only, change `gate-write`. Each has a rejection reason. |
| 4 Honest consequences | pass | ADR-001 inline logic needs extraction. ADR-002 adds a job and renames checks. ADR-003 depends on YAML layout. ADR-004 adds a 15-minute wait. |
| 5 Scope boundaries | pass | scope.md excludes Ubuntu sharding, the Windows count and balance, `run-tests.sh`, and the consumer copy. Each is a plausible build. |
| 6 Risks | pass | R-001 names a 10-minute trigger and a 3-shard action. R-002 and R-007 name the P4 push. R-005 names the digits check. |
| 7 NFRs | pass | execution-plan.md NFR-001 to NFR-004 each give a number or a command. |
| 8 Consistency | pass | ADR-002 matches req-001 and design.md "Matrix layout". ADR-003 matches req-002. Ground truth: `ravintio.yml` lines 169 to 212 hold 9 jobs, the `&& 7` count, and the job-level expression the ADRs replace. Step `timeout-minutes` accepts the `matrix` context. A step timeout ends the step as failed rather than cancelling the job, so an `if: always()` step runs. See finding 2. |
| 9 Split step | pass | req-001 and req-002 hold 3 criteria each, with a `Split step: keep` note. |

## Findings (severity-ordered)
1. [minor] req-002 AC1: the Actions log prints the `run:` script before the output, so a grep for `Elapsed:` matches the `echo` source text too. Fix: verify with a pattern such as `^Elapsed: [0-9]+ min [0-9]+ s of a (15|20) min cap$` on the output lines, once per job.
2. [minor] design.md, Scope "In": the line reads "one new 0000043 suite". The Engineering layer, scope.md, and ADR-001 name two. Fix: change the line to "two new 0000043 suites" (Hard Limit 7).
3. [minor] ADR-002 Decision, last bullet, and R-001: a move to 3 macOS shards also changes req-001 (2 entries, a count of 9 `shard:` lines) and both layout suites. Fix: say that the move amends req-001, ADR-002, and those suites.
4. [minor] ADR-003 Context: "a job timeout cancels every later step" is stated without a source. `if: always()` steps can run after a cancel. Fix: write "may skip later steps", or cite a source. The decision itself stands.
