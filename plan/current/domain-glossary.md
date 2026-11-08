---
title: "Domain Glossary - macos-test-job-timeout"
summary: "Terms used in 0000043."
---
# Domain Glossary - macos-test-job-timeout

| Term | Definition |
|------|-----------|
| Cap | The minutes a test step may run before GitHub Actions stops it. Each matrix entry holds its own cap in `matrix.cap`. |
| Backstop | The fixed job `timeout-minutes`. It sits above every cap, so a step timeout fails the step before the job is cancelled. |
| Shard | One of several jobs that each run part of the suite list. `run-tests.sh` picks the suites at positions where `(position - 1) % count` equals the shard index minus one. |
| Margin | The time left between a test step's elapsed time and its cap. |
| Elapsed line | The `Elapsed: {m} min {s} s of a {cap} min cap` line that each test job prints after its test step. |
| Margin warning | The `::warning` annotation that a job prints when its test step passes two-thirds of the cap. |
