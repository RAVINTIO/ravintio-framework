---
title: "ADR 001: Stack unchanged"
summary: "Feature 0000042 keeps the declared stack. The fix edits two Bash suites and one README, and adds no tool or library."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Stack unchanged

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000042-fix-windows-shards-pr-77
**Component:** ravintio-framework
**Date:** 2026-11-08

## Context

The confirmed design declares the stack unchanged: Bash suites under `run-tests.sh`, Node.js `.mjs` scripts, and GitHub Actions CI. The Windows shards run the suites under Git Bash on `windows-latest`.

## Decision

The fix uses only tools the suites already use: Bash, `uname`, `pwd -W`, `cygpath`, `git`, and Node's built-in `node:url` module. It adds no dependency and no CI job.

The path conversion copies the pattern in `test-0000035-req-005-ratchet-check-shared-root.sh`:

- `WORK` takes the `pwd -W` form of the scratch folder, with a `pwd` fallback.
- A `native()` helper converts any other path with `cygpath -m` when `command -v cygpath` finds it, and passes the path through unchanged otherwise. The suite runs `$PK` through `native()`.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| `pwd -W` alone, also for the folder of `project-kind.mjs` | One method for both paths | Works only on a folder, so the suite rebuilds the file path by hand | Five 0000035 suites and `test-0000040-req-005-consumer-migration.sh` already use the `native()` helper for file paths |
| Add a PowerShell suite for the link cases | Could build real Windows links | A second test language for one feature | Out of scope, and the Linux and macOS jobs already cover the link cases |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Two suites and `tests/README.md` change. No runtime file changes. |

## Consequences

**Positive:**
- The fix needs no new tool on any CI runner.

**Negative:**
- The Windows-only path code runs only on a Windows shard. Each fault there costs a CI round trip of about 15 minutes, because no local runner can show it.

**Risks:**
- A runner without `cygpath` would pass `$PK` through in POSIX form, and the import cases would fail again. Git for Windows ships `cygpath`, and the 0000035 suites rely on it today.

## Related ADRs

- ADR-002 - related-to
- ADR-003 - related-to

## Supersedes

- None

## Superseded By

- None
