---
title: "ADR 001: Stack unchanged"
summary: "Feature 0000041-pack-source-under-src keeps the declared stack. The release script, the resolver, and the new checks use Node.js .mjs and Bash, which the pack already uses."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Stack unchanged

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Component:** ravintio-framework
**Date:** 2026-11-07

## Context

The confirmed design records the stack as unchanged. The pack uses these parts:

- Bash and PowerShell setup scripts
- Node.js `.mjs` hooks and scripts that use only built-in modules
- Bash test suites under `run-tests.sh`
- GitHub Actions CI

This feature moves the pack source to `src/ravintio-framework/`. Its new code is a release script, a `release.yml` file contract, a pack resolver for the suites, a root copy integrity check, and a migration.

## Decision

Keep the declared stack. Every new piece uses a language the pack already uses:

- `scripts/build-release.mjs` is Node.js `.mjs` with built-in modules only. It hashes files with `node:crypto` SHA-256.
- The `release.yml` readers in skill text and scripts parse its flat keys by line, as the pack reads `product.yml` today.
- The suite resolver and the integrity check are Bash, run under `run-tests.sh` and the CI workflow.
- The 0.39.0 migration is a Markdown migration file, run by the migrator skill.

The feature adds no dependency, package, or tool.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Write the release script in Bash | Matches `setup.sh` | Path confinement and link checks are harder to get right, and Windows needs a second copy | Node.js runs the same on every shard, and `fs.realpath` gives the link check |
| Parse `release.yml` with a YAML library | Handles any YAML layout | Adds the pack's first package dependency, which every consumer must install | The release script writes the file in one fixed, flat form |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | No new dependency. The release script and resolver use existing languages. |
| setup-hook-integration | No change of language. Its code paths move under `src/ravintio-framework/`. |

## Consequences

**Positive:**
- Consumers need no new tool to upgrade.
- The release script runs on every CI shard without a second implementation.

**Negative:**
- A line-based `release.yml` reader accepts only the form the release script writes. A hand-edited file in another layout reads as unreadable.

**Risks:**
- A reader that misreads `release.yml` falls back to `component.yml` silently. ADR-004 states when the fallback applies.

## Related ADRs

- ADR-003 - related-to: the release script is the main new Node.js code.
- ADR-004 - related-to: the `release.yml` form follows from the line-based reader.

## Supersedes

- None

## Superseded By

- None
