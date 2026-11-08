---
title: "ADR 001: Stack unchanged"
summary: "0000043 keeps the declared stack and gives the workflow file to the repository CI."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Stack unchanged

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000043-macos-test-job-timeout
**Component:** ravintio-framework, repository CI
**Date:** 2026-11-08

## Context

The design declares Bash suites under `run-tests.sh`, YAML, and GitHub Actions CI, with a local build target. The change edits `.github/workflows/ravintio.yml` and adds two Bash suites. The workflow file sits outside the `ravintio-framework` component, so the design names its owner.

## Decision

- The stack stays as declared. No new language, tool, or Action enters the repository.
- The elapsed step uses only Bash and `date +%s`, which every runner image already has.
- The repository CI owns `.github/workflows/ravintio.yml`. The `ravintio-framework` component owns the suites under `src/ravintio-framework/tests/`.
- The consumer copy, `ravintio-framework/hooks/ravintio.yml`, stays unchanged (0000031 ADR 002).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| A timing Action from the Marketplace | Ready-made duration reports | A third-party Action in a repository job, and a new supply-chain input | The shell clock does the job with no new input |
| Move the workflow into the component | One owner for every changed file | The workflow tests this repository only, and consumers never get it | 0000031 ADR 002 keeps it repository-only |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Two new suites and two updated suites under `tests/` |
| repository CI | The `test-suite` job in `.github/workflows/ravintio.yml` |

## Consequences

**Positive:**
- No new dependency reaches CI or the release copy.

**Negative:**
- The elapsed logic lives inline in YAML, so the suite must extract it to test it (ADR-003).

**Risks:**
- None beyond the risk register.

## Related ADRs

- ADR-002 - related-to
- ADR-003 - related-to

## Supersedes

- None

## Superseded By

- None
