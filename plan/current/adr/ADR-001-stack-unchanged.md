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

The fix uses only tools the suites already use: Bash, `uname`, `pwd -W`, `git`, and Node's built-in `node:url` module. It adds no dependency and no CI job.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Use `cygpath -m` for path conversion | Converts any path, not only a folder | Not every MSYS install ships it, and the 0000035 suites don't use it | `pwd -W` is built into Git Bash and converts the two folders the fix needs |
| Add a PowerShell suite for the link cases | Could build real Windows links | A second test language for one feature | Out of scope, and the Linux and macOS jobs already cover the link cases |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Two suites and `tests/README.md` change. No runtime file changes. |

## Consequences

**Positive:**
- The fix needs no new tool on any CI runner.

**Negative:**
- `pwd -W` works only on a folder, so the suite converts the folder of `project-kind.mjs` and appends the file name.

**Risks:**
- A future Git Bash release could change `pwd -W` output. The suites print the path they use, so a failure would show it.

## Related ADRs

- ADR-002 - related-to
- ADR-003 - related-to

## Supersedes

- None

## Superseded By

- None
