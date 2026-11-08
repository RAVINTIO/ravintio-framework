---
title: "ADR 003: Blob id compare for the released migration"
summary: "The req-005 suite checks that retroactive-release-tags.md is unchanged by git blob id at HEAD and in the working tree, not by working-tree bytes."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Blob id compare for the released migration

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000042-fix-windows-shards-pr-77
**Component:** ravintio-framework
**Date:** 2026-11-08

## Context

Released migration files never change. The req-005 suite checks this for `retroactive-release-tags.md`. It writes the `v0.38.0` copy with `git show` and runs `cmp -s` against the pack copy in the working tree.

On the Windows runner, checkout converts LF to CRLF, so the working-tree bytes differ from the stored blob. The `git show` output keeps LF. The compare fails although the file is unchanged.

## Decision

The check takes the blob id of `v0.38.0:ravintio-framework/migrations/retroactive-release-tags.md`. It compares that id with two others, and both must match for the one assertion to pass:

- the blob id of the pack copy at `HEAD`
- the `git hash-object` id of the working-tree pack copy, run inside the repository so `core.autocrlf` applies

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Strip CR with `tr -d '\r'` before `cmp` | Small change | Hides a real CR added to the file | It weakens the check |
| Compare the `HEAD` blob only | No line-ending effect | Misses an uncommitted edit | Backlog 0000426 planned it, and the working-tree hash adds that cover |
| Set `core.autocrlf=false` in CI | Bytes then match | Changes every suite's checkout | Too broad for one check |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | One assertion in the req-005 suite changes its method and its label. |

## Consequences

**Positive:**
- The check gives the same result on Windows, Linux, and macOS.
- It still catches a committed or an uncommitted edit.

**Negative:**
- The check now depends on git reading the repository, not only on file bytes.

**Risks:**
- The suite must build the pack path relative to `RAVINTIO_REPO_ROOT`. R-004 in the risk register tracks it.

## Related ADRs

- ADR-001 - depends-on

## Supersedes

- None

## Superseded By

- None
