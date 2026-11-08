# Design-Critic Verdict (iteration 1)
**Mode:** on
**Mechanical check:** 4 findings, exit 1

```
consistency-check: 4 finding(s)
  ✖ requirements/req-001-sharded-macos-test-job.md: references ADR-014 but no such file exists in adr/
  ✖ design.md: references ADR-003 but no such file exists in adr/
  ✖ design.md: references ADR-002 but no such file exists in adr/
  ✖ scope.md: references ADR-002 but no such file exists in adr/
```

**Overall:** REJECT

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | fail | req-001 ACs cite `gh pr checks 77`, `gh run view`, and `Suites run` totals. req-002 AC2 and AC3 cite "the step script", but no requirement creates a script file. The step is inline YAML, so the check can't run as written. |
| 2 Traceability | pass | req-001 `Source: US-001`, req-002 `Source: US-002`. Brief ACs 1 to 3 map to req-001, and brief AC4 maps to req-002. No orphan story. |
| 3 ADRs record real decisions | n/a | P1 review. No ADR exists yet. |
| 4 Consequences are honest | n/a | P1 review. No ADR exists yet. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope: sharding Ubuntu, the Windows shard count, and `run-tests.sh` are plausible builds. |
| 6 Risks specific and mitigated | fail | R-001 mitigation "A third shard is a one-line change" states a capability, not an action. R-004 mitigation "Checkout takes under a minute today" is an observation. |
| 7 NFRs measurable | pass | NFR-001 to NFR-004 each give a number or a command. |
| 8 Internal consistency | fail | See findings 3 to 6. |
| 9 Split step | pass | req-001 and req-002 each hold 3 criteria. |

## Findings (severity-ordered)
- [critical] `design.md` lines 15 and 33, `scope.md` line 22, `req-001` line 45: bare `ADR-NNN` cross-feature references fail the mechanical check. Write them as `0000031 ADR 003`, `0000031 ADR 002`, and `0000037 ADR 014`, as the GUTD text does.
- [major] `req-002` AC2 and AC3: name how the local runs execute the step. Either the 0000043 suite extracts the `run:` block from the workflow and runs it with a faked start time and cap, or a named script file holds the logic and lands in scope.
- [major] `req-002` Functional Requirements: both new steps need `shell: bash`. The Windows default shell is `pwsh`, so `date +%s` and `GITHUB_ENV` writes break there.
- [major] `req-001` suite updates: list every assertion that breaks. `test-0000037` counts `shard:` lines as 7, and the 2 macOS shards make 9. `test-0000037` and `test-0000031` both assert the job-level `timeout-minutes` expression. Each needs the new rule: Windows step cap `matrix.cap` 20, and job backstop 25.
- [minor] `design.md` Assumptions: the `SECONDS` assumption contradicts req-002, which uses an epoch start time in `GITHUB_ENV`. Replace it with execution-plan A-003, which design.md omits.
- [minor] `req-001` AC2 and brief NFR "macOS margin": job duration includes setup and the full-history checkout, but the warning measures the test step only. Pick one measure for "under 10 minutes".
- [minor] `scope.md` In Scope omits the `tests/README.md` rows that `design.md` and the brief list. The README doesn't describe the CI layout, so drop the row from all three or add it to `scope.md`.
- [minor] `risk-register.md` R-001 and R-004: state actions. For example, "if a shard exceeds 10 minutes at P4, raise `shards` to 3 before P7" and "set a checkout step `timeout-minutes`" or accept the risk outright.
