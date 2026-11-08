---
title: "Risk Register - macos-test-job-timeout"
summary: "Feature-specific risks for 0000043."
---
# Risk Register - macos-test-job-timeout

| ID | Risk | Category | Likelihood | Impact | Mitigation |
|----|------|----------|-----------|--------|-----------|
| R-001 | The slow macOS suites land in one shard, which stays near its 15-minute cap | technical | low | medium | If a macOS shard takes over 10 minutes in the P4 CI run, P4 raises `shards` to 3 and adds a third entry before P7. |
| R-002 | A step `timeout-minutes` with a `matrix` expression fails to parse, and every test job fails | technical | low | high | P4 reads the PR #77 run before P7 archives the design. |
| R-003 | Windows shards 3 and 4 print the margin warning on most runs | operational | high | low | The warning is true. Backlog 0000432 tracks the rebalance. |
| R-004 | The fixed 25-minute backstop lets a stuck checkout run 10 minutes longer than today | operational | low | low | Accepted. A stalled checkout costs at most 10 extra runner minutes, and the step cap still bounds the suite. |
| R-005 | The `GITHUB_ENV` write lets a later step read a value an earlier step set | security | low | low | The value is a number from `date +%s`. The elapsed step checks it is digits only before any arithmetic. |
| R-006 | The P7 credential scan holds back `release.yml` again | operational | high | low | The `release-copy-integrity` job passes with its skip notice (backlog 0000425). |
| R-007 | A CI failure appears after P7 archives the design, and `gate-write` blocks the fix | operational | medium | high | The run pushes after P4 and reads the PR #77 checks before P7 (backlog 0000426). |
