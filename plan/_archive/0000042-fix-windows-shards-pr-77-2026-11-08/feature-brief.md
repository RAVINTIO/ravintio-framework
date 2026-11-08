---
title: "Feature Brief - fix-windows-shards-pr-77"
summary: "The business case, scope, and product requirements for the feature."
status: "draft"
version: "0.1.0"
---
# Feature Brief - fix-windows-shards-pr-77

**Feature ID:** 0000042-fix-windows-shards-pr-77

> Drafted by the orchestrator from backlog 0000426 and the PR #77 CI logs, at the human's request: "You need to fix the PR so we can merge it."

## Business Goal

PR #77 carries release 0.39.0, and two of its 14 CI checks fail. Both failures sit in two 0000041 test suites that assume POSIX behaviour under Git Bash on Windows. The maintainer can't merge a red PR, so the release stays blocked until both shards pass.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Windows-safe 0000041 suites | US-001: As a framework maintainer, I see both 0000041 suites pass on the Windows CI shards, so that I can merge PR #77. | must-have | 1 |

## Waves

| Wave | Features Included | Ships When |
|------|-------------------|------------|
| 1 | Windows-safe 0000041 suites | every PR #77 check passes |

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| `ravintio-framework` | component-pack | existing | owns the two suites under `src/ravintio-framework/tests/` and `tests/README.md` |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| `src/ravintio-framework/tests/` | `ravintio-framework` | the root release copy, through the release script |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| GitHub Actions | `src/ravintio-framework/tests/run-tests.sh` | CI job | each suite prints PASS, FAIL, or SKIP lines and exits non-zero on a FAIL |

## Stack

| Concern | Decision |
|---------|----------|
| Language | Bash, Node.js `.mjs` |
| Runtime | Node.js, Git Bash on Windows |
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

- `test-0000041-req-005-applies-to-header.sh`: Windows paths for Node, a file URL import, a link-case skip on Windows, and a git blob id compare of the released migration at `HEAD` and `v0.38.0` in place of the working-tree byte compare
- `test-0000041-req-006-consumer-migration.sh`: a Windows skip for Case 6, the linked `ravintio-framework/`
- `tests/README.md`: one Windows skip row per suite
- the 0.39.1 patch version, and the P7 release copy rebuild

### Out of Scope

- `project-kind.mjs` and the migrator, which have no Windows fault
- the ship sequence and `gate-write` change in backlog 0000426's suggested action
- the credential-scan false positive on `release.yml` (backlog 0000425)

### Deferred

- Nothing deferred. Backlog 0000426 stays open for its ship and gate change.

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| CI result | all 14 PR #77 checks pass | `gh pr checks 77` |
| Coverage | Linux and macOS still run every case, with zero new skips | suite output on `ubuntu-latest` and `macos-latest` |

## Constraints and Assumptions

### Constraints

- Released migration files never change.
- A Windows skip prints one `SKIP (windows): {reason}` line, like the existing suites.
- The fix lands on `feat/0000041-pack-source-under-src`, so PR #77 picks it up.

### Assumptions

- Git Bash `ln -s` makes a copy, so a link case can't be built on Windows.
- The byte compare fails because checkout converts LF to CRLF on Windows.

## Scenario Paths

## Acceptance Criteria

- [ ] Both Windows shards pass on PR #77, and so do the other 12 checks.
- [ ] On Linux and macOS, both suites run every case they run today and print no new SKIP line.
- [ ] On Windows, each skipped case prints one `SKIP (windows)` line with its reason, and `tests/README.md` lists each skip.
