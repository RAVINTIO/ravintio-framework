---
title: "Discovery - 0000043-macos-test-job-timeout"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000043-macos-test-job-timeout

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only. Decisions belong in `design.md`, and the Q&A audit trail in `build-log.md`.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds 42 feature folders, and `docs/about.md` exists |
| Git pre-flight | Branch `feat/0000041-pack-source-under-src`, level with its remote. PR #77 is open and unmerged. One untracked file: `ravintio-framework/release.yml`. |
| Skills inbox | empty |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md` and `product.yml`): `0.39.1`.
- Prior features: 0000001 to 0000042. The last one, 0000042-fix-windows-shards-pr-77 (2026-11-08), fixed two Windows shards on PR #77.
- Constraining ADRs (unless superseded):
  - 0000031 ADR-002: the `test-suite` job tests this repository only and isn't mirrored into `ravintio-framework/hooks/ravintio.yml`.
  - 0000031 ADR-003: CI runs on `pull_request` only.
  - 0000037 ADR-014: Windows runs seven shards with a 20-minute cap per shard.
- Component and data-ownership map: unchanged from 0000042. The `ravintio-framework` component owns `src/ravintio-framework/`, including its tests.

### CI layout findings

- `.github/workflows/ravintio.yml` line 177 sets `timeout-minutes: ${{ matrix.os == 'windows-latest' && 20 || 15 }}`.
- `macos-latest` and `ubuntu-latest` each run the whole suite in one job, with no shard.
- `run-tests.sh` already supports `RAVINTIO_SHARD_INDEX` and `RAVINTIO_SHARD_COUNT`.
- `run-tests.sh` prints no elapsed time for a suite or for the run.
- Two suites pin the current layout:
  - `test-0000031-req-001-003-ci-jobs.sh` line 48 accepts a cap of `10` or the exact Windows expression.
  - `test-0000037-req-010-windows-git-bash-leg.sh` lines 82 and 83 expect seven `shard:` entries and the text `matrix.shard && 7`.

### PR #77 CI findings

| Run | macOS | Ubuntu |
|-----|-------|--------|
| 42471780093 | cancelled at 15 min 17 s | success, 8 min 25 s |
| 42472135426 | success, 13 min 30 s | success, 8 min 23 s |
| 42472194424 | cancelled at 15 min 17 s | success, 8 min 39 s |
| 42476595066 | cancelled at 15 min 20 s | success, 6 min 48 s |

- Run `42476595066` is the latest. Every PR #77 check passes except `Test suite (macos-latest)`, which reads `cancel`.
- The macOS timeout now blocks PR #77, not only threatens it.

## Record Samples

None
