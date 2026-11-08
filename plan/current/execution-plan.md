---
title: "Execution Plan - macos-test-job-timeout"
summary: "Non-functional requirements, API and data summary for 0000043."
---
# Execution Plan - macos-test-job-timeout

## Active Skills

| Skill | Scope | Purpose |
|-------|-------|---------|
| None | n/a | No capability skill applies to a workflow and Bash suite change. |

## Functional Requirements Directory

| File | Requirement |
|------|------------|
| [req-001-sharded-macos-test-job.md](requirements/req-001-sharded-macos-test-job.md) | macOS runs as 2 shards, and each matrix entry carries its own cap |
| [req-002-visible-job-margin.md](requirements/req-002-visible-job-margin.md) | Each test job prints its elapsed time against its cap, with a warning past two-thirds |

## Non-Functional Requirements

| ID | Category | Requirement | Target | Measurement |
|----|----------|------------|--------|-------------|
| NFR-001 | Reliability | Every PR #77 check passes | every check `pass` | `gh pr checks 77` |
| NFR-002 | Performance | Each macOS shard finishes well inside its cap | under 10 minutes per shard | job durations in `gh run view` |
| NFR-003 | Coverage | The macOS shards run every suite once | shard `Suites run` totals sum to the Ubuntu total | the summary line of each job log |
| NFR-004 | Security | The test job keeps its posture | no `secrets.` reference, `contents: read` only | the 0000031 and 0000043 suites |

## API Summary

Not applicable. The change adds no endpoint.

## Data Model Summary

Not applicable. The change touches one workflow file and test code.

## Component Interactions

- GitHub Actions runs `src/ravintio-framework/tests/run-tests.sh` once on Ubuntu, in 2 macOS shards, and in 7 Windows shards.
- `run-tests.sh` reads `RAVINTIO_SHARD_INDEX` and `RAVINTIO_SHARD_COUNT` from the step `env`.
- The elapsed step reads the start time from `GITHUB_ENV` and the cap from `matrix.cap`.
- At P7, the release script copies the changed suites to the root `ravintio-framework/` release copy.

## Assumptions

| ID | Assumption | Impact if Wrong |
|----|-----------|----------------|
| A-001 | The macOS suite time splits about evenly across 2 shards by position | One shard stays near its cap, and the run needs 3 shards |
| A-002 | A step timeout fails the step without cancelling the job, so an `if: always()` step still runs | A timed-out run shows no elapsed line |
| A-003 | A step's `timeout-minutes` accepts a `matrix` expression | The workflow fails to parse, and every test job fails |
| A-004 | No ruleset requires a check by name | The renamed macOS checks block the merge |

## Open Questions

None.
