---
title: "ADR 004: Read the Windows CI before the archive"
summary: "This run pushes after the P4 CI pass and reads the PR #77 Windows shards before P7 archives the design, so a fix can still pass gate-write."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - Read the Windows CI before the archive

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000042-fix-windows-shards-pr-77
**Component:** ravintio-framework
**Date:** 2026-11-08

## Context

Only the Windows shards can prove req-001's first criterion. In 0000041, P9 read the shards after P7 had archived `plan/current/design.md`. `gate-write` then blocked every fix under `src/` (backlog 0000426).

## Decision

After the P4 CI pass, the run pushes `feat/0000041-pack-source-under-src` and reads the PR #77 checks for that head. It moves to P5 only when both Windows shards pass. If a shard fails, the fix loop runs while the design is still in `plan/current/`. P9 still reads the checks again for the final head.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Read the checks at P9 only | Follows the ship sequence as written | A failure can't be fixed after the archive | The same block as 0000041 |
| Change the ship sequence or `gate-write` | Fixes the cause for every run | Needs its own design | Backlog 0000426 holds it, and it is out of scope |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | None in code. The order of this run's phases changes. |

## Consequences

**Positive:**
- A Windows failure can still be fixed inside this run.

**Negative:**
- P4 waits for a full CI run, about 15 minutes.

**Risks:**
- P7 rebuilds the release copy and changes the head again. P9 reads the checks for that head. A failure caused only by the rebuild would still meet the 0000426 block.

## Related ADRs

- ADR-002 - related-to
- ADR-003 - related-to

## Supersedes

- None

## Superseded By

- None
