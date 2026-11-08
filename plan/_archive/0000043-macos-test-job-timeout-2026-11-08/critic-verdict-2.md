# Design-Critic Verdict (iteration 2)
**Mode:** on
**Mechanical check:** clean

```
consistency-check: clean
exit=0
```

**Overall:** APPROVE

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | req-001 ACs name `gh pr checks 77`, `gh run view` durations, and `Suites run` totals against the Ubuntu total. req-002 FR line 22 names how the suite runs the extracted `run:` block with a faked start time, cap, and `GITHUB_ENV`. req-002 AC2 and AC3 give fixed inputs: 16 minutes against 15, and 9 and 11 minutes against 15. |
| 2 Traceability | pass | req-001 `Source: US-001`, req-002 `Source: US-002`. Brief ACs 1 to 3 map to req-001, and brief AC4 maps to req-002. No orphan story. |
| 3 ADRs record real decisions | n/a | P1 review. No ADR exists yet. |
| 4 Consequences are honest | n/a | P1 review. No ADR exists yet. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope: sharding Ubuntu, the Windows shard count and balance (backlog 0000432), and `run-tests.sh` are plausible builds. |
| 6 Risks specific and mitigated | pass | R-001 now states a P4 action with a 10-minute trigger. R-004 is an explicit acceptance with a bound. R-005 names the digits-only check that req-002 line 27 requires. |
| 7 NFRs measurable | pass | NFR-001 to NFR-004 each give a number or a command. |
| 8 Internal consistency | pass | design.md Matrix layout, req-001 Functional Requirements, and `scope.md` agree on entries, caps, and the 25-minute backstop. design.md line 45 records the P1 deviation. Ground truth confirms the suite updates in req-001 lines 28 to 33 cover every layout assertion: `test-0000031` line 48, and `test-0000037` lines 65, 82, and 83. `shards:` lines don't match the `shard:` count regex, so 9 is correct. `test-0000041` req-008 counts one `run: bash .../run-tests.sh` line, which the change keeps. |
| 9 Split step | pass | req-001 and req-002 each hold 3 criteria. |

## Iteration 1 findings

| # | Finding | Status |
|---|---------|--------|
| 1 | Bare `ADR-NNN` references | resolved. The mechanical check is clean. |
| 2 | req-002 local run method | resolved. req-002 line 22 names extraction of the `run:` block. |
| 3 | `shell: bash` on both new steps | resolved. req-002 line 21. |
| 4 | Breaking suite assertions | resolved. req-001 lines 29 to 33. |
| 5 | `SECONDS` assumption | resolved. design.md line 85 now matches execution-plan A-003. |
| 6 | One measure for "under 10 minutes" | resolved. req-002 line 23 states that the warning measures the step and req-001 measures the job. |
| 7 | `tests/README.md` rows | resolved. `scope.md` line 14 records that P3 adds no row. The README has no CI layout section. |
| 8 | R-001 and R-004 actions | resolved. |

## Findings (severity-ordered)
- [minor] `domain-glossary.md` Margin and Margin warning, design.md line 26, and req-002 AC3 say "a job" passes two-thirds of its cap. req-002 line 23 says the warning measures the test step only. Change "job" to "test step" in those three places.
- [minor] req-002 line 26: "past two-thirds" doesn't define the boundary. State whether exactly 600 s of a 15-minute cap warns, for example "elapsed seconds greater than cap times 40".
- [minor] req-002 line 31: the req-002 checks sit in `test-0000043-req-001-macos-shards.sh`. Either name the suite for both requirements or add a `test-0000043-req-002-...` suite, so the suite name traces to req-002.
