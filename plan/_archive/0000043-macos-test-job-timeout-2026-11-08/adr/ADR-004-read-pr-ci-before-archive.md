---
title: "ADR 004: Read the PR #77 CI before the archive"
summary: "This run pushes after the P4 local pass and reads the PR #77 checks before P7 archives the design, so a fix can still pass gate-write."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - Read the PR #77 CI before the archive

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000043-macos-test-job-timeout
**Component:** repository CI
**Date:** 2026-11-08

## Context

Only a real CI run can prove req-001's first two criteria and req-002's first. The workflow change has no local runner. After P7 archives `plan/current/design.md`, `gate-write` blocks every fix under `src/` (backlog 0000426). 0000042 ADR 004 met the same problem the same way.

## Decision

- After the P4 local suite pass, the run pushes `feat/0000041-pack-source-under-src` and reads the PR #77 checks for that head.
- It moves to P5 only when every check passes and each macOS job takes under 10 minutes.
- If a check fails or a macOS job takes 10 minutes or more, the P4 validate loop runs the fix while the design is still in `plan/current/`. ADR-002 names the fix for a slow shard.
- At P7, between `build-release.mjs` and `archive-current.mjs`, the run runs `node src/ravintio-framework/scripts/release-check.mjs --root . --files-only` and passes on exit 0.
- P9 still reads the checks again for the final head.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Read the checks at P9 only | Follows the ship sequence as written | A failure can't be fixed after the archive | The same block as 0000041 |
| Change the ship sequence or `gate-write` | Fixes the cause for every run | Needs its own design | Backlog 0000426 holds it |

## Affected Components

| Component | Impact |
|-----------|--------|
| repository CI | None in code. The order of this run's phases changes. |

## Consequences

**Positive:**
- A CI failure or a slow shard can still be fixed inside this run.

**Negative:**
- P4 waits for a full CI run, about 15 minutes.

**Risks:**
- P7 rebuilds the release copy and changes the head again. A CI failure caused only by the rebuild would still meet the 0000426 block.

## Related ADRs

- ADR-002 - depends-on
- 0000042 ADR 004 - follows

## Supersedes

- None

## Superseded By

- None
