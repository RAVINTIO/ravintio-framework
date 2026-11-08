---
title: "Feature Brief - macos-test-job-timeout"
summary: "The business case, scope, and product requirements for the feature."
status: "draft"
version: "0.1.0"
---
# Feature Brief - macos-test-job-timeout

**Feature ID:** 0000043-macos-test-job-timeout

> Drafted by the orchestrator from backlog 0000430 and the PR #77 CI runs, at the human's request: "Pick up backlog 0000430 on the PR #77 branch".

## Business Goal

The `Test suite (macos-latest)` job runs the whole suite in one job against a 15-minute cap. It hit the cap in 3 of the last 4 PR #77 runs, and it is the only PR #77 check that doesn't pass. The maintainer can't merge a red PR. Each new suite adds time, so the job needs margin that grows with the suite list.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Sharded macOS test job | US-001: As a framework maintainer, I see the macOS test suite finish well inside its cap, so that I can merge PR #77. | must-have | 1 |
| Visible job margin | US-002: As a framework maintainer, I see each test job's elapsed time against its cap in the CI log, so that I can act before a job times out. | must-have | 1 |

## Waves

| Wave | Features Included | Ships When |
|------|-------------------|------------|
| 1 | Sharded macOS test job, visible job margin | every PR #77 check passes |

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| `ravintio-framework` | component-pack | existing | owns the CI layout suites under `src/ravintio-framework/tests/` and `tests/README.md` |
| repository CI | workflow file | existing | `.github/workflows/ravintio.yml`, which runs this repository's own checks |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| `src/ravintio-framework/tests/` | `ravintio-framework` | the root release copy, through the release script |
| `.github/workflows/ravintio.yml` | repository CI | none |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| GitHub Actions | `src/ravintio-framework/tests/run-tests.sh` | CI job | `RAVINTIO_SHARD_INDEX` and `RAVINTIO_SHARD_COUNT` select the suites, and the runner exits non-zero on a FAIL |

## Stack

| Concern | Decision |
|---------|----------|
| Language | Bash, YAML |
| Runtime | GitHub Actions runners: Linux, macOS, and Windows with Git Bash |
| Framework | none |
| Frontend | none |
| Database | none |
| ORM | none |
| Testing | Bash suites under `run-tests.sh` |
| IaC | none |
| Cloud | none |
| Compute | none |
| CI | GitHub Actions |
| Build target | local |

## Scope Boundaries

### In Scope

- the `test-suite` matrix: 2 macOS shards with the 15-minute cap, and a per-entry shard count
- one elapsed-time line per test job, with a warning when a job passes 75% of its cap
- the two suites that pin the CI layout: `test-0000031-req-001-003-ci-jobs.sh` and `test-0000037-req-010-windows-git-bash-leg.sh`
- `tests/README.md` rows for the changed layout, if the README describes it
- the 0.39.2 patch version, and the P7 release copy rebuild

### Out of Scope

- sharding Ubuntu, which takes 7 to 9 minutes
- the Windows shard count and cap
- making any suite faster
- `ravintio-framework/hooks/ravintio.yml`, the consumer copy, which has no `test-suite` job (0000031 ADR-002)

### Deferred

- Nothing deferred.

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| CI result | every PR #77 check passes | `gh pr checks 77` |
| macOS margin | each macOS shard finishes in under 10 minutes, which is two-thirds of its cap | job duration in `gh run view` |
| Coverage | the 2 macOS shards together run every suite exactly once | the `Suites run` totals of both shards |

## Constraints and Assumptions

### Constraints

- CI runs on `pull_request` only (0000031 ADR-003).
- The fix lands on `feat/0000041-pack-source-under-src`, so PR #77 picks it up.
- `run-tests.sh` output without `--quiet` stays byte-identical (0000038 req-003).

### Assumptions

- The macOS suite time splits roughly evenly across 2 shards.
- No ruleset requires a check by name, so renamed macOS checks don't block the merge.

## Scenario Paths

## Acceptance Criteria

- [ ] Every PR #77 check passes, including both macOS shards.
- [ ] Each macOS shard finishes in under 10 minutes on PR #77.
- [ ] The 2 macOS shards together run every suite exactly once.
- [ ] Each test job's log shows its elapsed time and its cap, and a job past 75% of its cap shows a warning.
