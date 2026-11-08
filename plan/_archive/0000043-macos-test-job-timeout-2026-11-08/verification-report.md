# Verify-by-Execution Report

**Toggle:** on (absent key, read as `on` in `autonomous`)
**Software exercised:** PR #77 GitHub Actions run `42490766491` on head `1ed6e2b2`, read with `gh run view` (job times, job logs) and the check-run annotations API. The req-002 `run:` block also ran locally under Bash, through `test-0000043-req-002-job-margin.sh`.

| Requirement | Criterion | Method | Outcome | Observation evidence |
|-------------|-----------|--------|---------|---------------------|
| REQ-001 | Every PR #77 check passes, including both macOS shards | Side effects: CI run | verified | Run `42490766491` concluded `success`. All 15 jobs show `success`, including `Test suite (macos-latest, shard 1 of 2)` and `shard 2 of 2`. |
| REQ-001 | Each macOS shard finishes in under 10 minutes | Side effects: job times | verified (reopened at P4) | With 2 shards, run `42490766491` gave 392 s and 281 s, but later runs gave 668 s and 612 s for shard 1, so the criterion failed. With 3 shards, run `42496182854` on head `1b44f04e` gives 323 s, 275 s, and 320 s. Before the change, the single macOS job took 810 s to over 900 s. |
| REQ-001 | The macOS shards together run every suite once, and the rows match | Side effects: job logs, plus a local suite run | verified | In run `42496182854`, the 3 shard logs print `Suites run: 60`, `60`, and `59`, which sum to Ubuntu's `Suites run: 179`. `test-0000043-req-001-macos-shards.sh` passes locally and in CI. |
| REQ-002 | Every test job log shows one `Elapsed:` line with its cap | Side effects: job logs, anchored pattern | verified | Each of the 10 test jobs prints one line matching `Elapsed: [0-9]+ min [0-9]+ s of a (15\|20) min cap$`, for example `Elapsed: 6 min 26 s of a 15 min cap` on macOS shard 1. |
| REQ-002 | The elapsed step prints its line after the test step fails or times out | CLI: the extracted `run:` block | verified, with one part not observed | The real `run:` block, run with a start 960 s old and a cap of 15, prints `Elapsed: 16 min 0 s of a 15 min cap` and one warning, and exits 0. The step carries `if: always()`. No live CI step timeout was observed. Execution plan A-002 stays an assumption until a real test step times out. |
| REQ-002 | A test step past two-thirds of its cap warns, and one at or under it doesn't | Side effects: annotations, plus the extracted block | verified | Windows shard 3, at 14 min 36 s of 20, carries the one `Test job margin` annotation: `14 min 36 s of a 20 min cap`. The other 9 test jobs, all under their threshold, carry none. Locally, 600 s prints no warning and 601 s prints one. |

## Not-verifiable parts

- **A live step timeout:** this run had no test step hit its cap. Forcing one would need a deliberately failing CI run on PR #77. The extracted block's run proves the step's output, and `if: always()` is in place.
