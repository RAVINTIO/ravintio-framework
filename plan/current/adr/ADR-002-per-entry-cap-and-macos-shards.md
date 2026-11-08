---
title: "ADR 002: Per-entry cap and two macOS shards"
summary: "Every test-suite matrix entry carries its own cap and shard count, macOS runs as two shards, and a fixed job backstop sits above every step cap."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Per-entry cap and two macOS shards

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000043-macos-test-job-timeout
**Component:** repository CI
**Date:** 2026-11-08

## Context

The macOS job runs every suite against a 15-minute job cap and timed out in 3 of the last 4 PR #77 runs. The cap comes from one job-level expression, `matrix.os == 'windows-latest' && 20 || 15`. The shard count is a fixed `7` in two places. GitHub Actions expressions have no arithmetic, so a step can't derive "cap minus one" from a matrix value. This amends 0000037 ADR 014, which set the Windows shards and the job-level cap.

## Decision

- Every `test-suite` entry moves to `include` and carries `cap`. Sharded entries also carry `shard` and `shards`.
  - Ubuntu: one entry, `cap: 15`, with no `shard` or `shards`.
  - macOS: shards 1 and 2, with `shards: 2` and `cap: 15`.
  - Windows: shards 1 to 7, with `shards: 7` and `cap: 20`.
- `RAVINTIO_SHARD_COUNT` reads `matrix.shards`, and the job name reads `matrix.shards`.
- The test step's `timeout-minutes` reads `matrix.cap`.
- The job `timeout-minutes` is a fixed `25`, above every cap. A slow suite then fails the step, and the job runs its later steps (ADR-003).
- If a macOS shard takes over 10 minutes in the P4 CI run, P4 raises macOS to 3 shards before P7. This is risk R-001's action. The move amends req-001, this ADR, and both layout suites, whose `shard:` count rises to 10. The run logs it as a deviation.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Raise the macOS cap | One-line change | Each new suite eats the margin again | The human chose shards at P0 |
| Keep the job-level cap expression | Fewer lines change | The cap keeps two copies once a step needs it | The elapsed step needs the cap, so one source is safer |
| Step cap one minute below the job cap | Keeps the job cap at its old value | Needs arithmetic that Actions expressions lack | It can't be written |

## Affected Components

| Component | Impact |
|-----------|--------|
| repository CI | The matrix, the job name, both timeouts, and the shard count |
| ravintio-framework | `test-0000031-req-001-003-ci-jobs.sh` and `test-0000037-req-010-windows-git-bash-leg.sh` follow the new layout |

## Consequences

**Positive:**
- Each macOS shard should take about half its current time, and new suites spread across both shards.
- A change to a cap or a shard count touches one entry.

**Negative:**
- The matrix grows from 9 to 10 jobs, and each extra job pays for one checkout.
- The macOS check names change from `Test suite (macos-latest)` to two shard names.

**Risks:**
- A stalled checkout can now run up to 25 minutes. The risk register accepts this as R-004.

## Related ADRs

- ADR-001 - related-to
- ADR-003 - related-to
- 0000037 ADR 014 - amends

## Supersedes

- None

## Superseded By

- None
