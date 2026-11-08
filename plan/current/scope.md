---
title: "Scope - macos-test-job-timeout"
summary: "In, out, and deferred scope for 0000043."
---
# Scope - macos-test-job-timeout

## In Scope

- The `test-suite` matrix in `.github/workflows/ravintio.yml`: every entry under `include`, each with its own `cap`, and 2 macOS shards (req-001)
- The test step timeout from `matrix.cap`, and a fixed 25-minute job backstop (req-001)
- The start-time step and the `if: always()` elapsed step, with the two-thirds warning (req-002)
- Updates to `test-0000031-req-001-003-ci-jobs.sh` and `test-0000037-req-010-windows-git-bash-leg.sh`
- One new suite, `test-0000043-req-001-macos-shards.sh`
- `tests/README.md` rows, if the README describes the CI layout. P1 found that it doesn't, so P3 adds no row.
- The 0.39.2 patch version, and the P7 release copy rebuild

## Out of Scope

- Sharding Ubuntu, which takes 7 to 9 minutes
- The Windows shard count, the Windows cap, and the Windows shard balance (backlog 0000432)
- Making any suite faster
- `run-tests.sh`, whose output stays byte-identical
- `ravintio-framework/hooks/ravintio.yml`, the consumer copy, which has no `test-suite` job (0000031 ADR 002)
- The run-mode anchor defect (backlog 0000427) and the `release.yml` scan hold-back (backlog 0000425)

## Deferred

- Nothing deferred.
