# Coverage Table - 0000043-macos-test-job-timeout

P4 semantic correctness check. Every criterion declares `Verified by: execution`.

| REQ-ID | AC | Type | Covered by test | Pass/Fail |
|--------|----|------|-----------------|-----------|
| req-001 | Every PR #77 check passes, including both macOS shards | execution | `test-0000043-req-001-macos-shards.sh` (layout), run `42490766491` | Pass |
| req-001 | Each macOS shard finishes in under 10 minutes | execution | run `42490766491` job times | Pass |
| req-001 | The macOS shards run every suite once, and the rows match | execution | `test-0000043-req-001-macos-shards.sh`, `test-0000031-req-001-003-ci-jobs.sh`, `test-0000037-req-010-windows-git-bash-leg.sh` | Pass |
| req-002 | Every test job log shows one `Elapsed:` line with its cap | execution | `test-0000043-req-002-job-margin.sh` (static checks), run `42490766491` logs | Pass |
| req-002 | The elapsed step prints after a failed or timed-out test step | execution | `test-0000043-req-002-job-margin.sh` (960 s case, `if: always()` check) | Pass |
| req-002 | A test step past two-thirds of its cap warns, and one at or under doesn't | execution | `test-0000043-req-002-job-margin.sh` (600 s, 601 s, 540 s, 660 s cases), run `42490766491` annotations | Pass |
