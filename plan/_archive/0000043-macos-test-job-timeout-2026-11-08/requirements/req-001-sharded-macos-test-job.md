---
title: "Requirement: req-001 - Sharded macOS test job"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: req-001 - Sharded macOS test job

**Skill:** [spec-agent](../skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000043-macos-test-job-timeout
**Source:** US-001
**Priority:** must-have

## User Story

As a framework maintainer, I see the macOS test suite finish well inside its cap, so that I can merge PR #77.

## Functional Requirements

- The `test-suite` job in `.github/workflows/ravintio.yml` lists every matrix entry under `include`. No entry stays in a plain `os` list.
- Each entry carries a `cap` value in minutes:
  - `ubuntu-latest`: one entry with `cap: 15`, and no `shard` or `shards` value
  - `macos-latest`: three entries, `shard: 1` to `shard: 3`, each with `shards: 3` and `cap: 15`. P1 set two entries with `shards: 2`. P4 raised it to three under ADR-002's 10-minute rule (P4 deviation).
  - `windows-latest`: seven entries, `shard: 1` to `shard: 7`, each with `shards: 7` and `cap: 20`
- The test step sets `RAVINTIO_SHARD_COUNT` from `matrix.shards`, in place of the fixed `7`. The Ubuntu entry passes an empty value, so `run-tests.sh` runs every suite there.
- The job name reads `Test suite ({os}, shard {n} of {count})` from `matrix.shard` and `matrix.shards`. The Ubuntu job keeps the name `Test suite (ubuntu-latest)`.
- The test step's `timeout-minutes` reads `matrix.cap`. The job `timeout-minutes` is a fixed backstop of 25, above every cap (P1 deviation).
- `test-0000031-req-001-003-ci-jobs.sh` accepts the new layout. It checks that the job holds `ubuntu-latest` and `macos-latest` entries.
  - Its old check of the job-level `matrix.os == 'windows-latest' && 20 || 15` expression becomes two checks: the test step's `timeout-minutes` reads `matrix.cap`, and the job's `timeout-minutes` is `25`.
- `test-0000037-req-010-windows-git-bash-leg.sh` accepts the new layout. It still checks seven `windows-latest` entries.
  - Its count of `shard:` lines expects 10, which is 3 macOS and 7 Windows (P4 deviation: 9 with two macOS shards). A second count checks 7 `shards: 7` lines.
  - Its check of `matrix.shard && 7` becomes a check that `RAVINTIO_SHARD_COUNT` reads `matrix.shards`.
  - Its old check of the job-level Windows cap expression becomes two checks: 7 `cap: 20` lines, and the job's `timeout-minutes` of `25`.
- A new suite, `test-0000043-req-001-macos-shards.sh`, checks the matrix rows above, the `RAVINTIO_SHARD_COUNT` wiring, and both timeouts.
- `run-tests.sh` and `ravintio-framework/hooks/ravintio.yml` stay unchanged.
- Split step: keep. The requirement holds one observable outcome, the macOS margin, in three criteria.

## Acceptance Criteria

- [ ] Every PR #77 check passes on the pushed head, including both macOS shards.
  - Verified by: execution - `gh pr checks 77` on the head that the run pushes
- [ ] Each macOS shard finishes in under 10 minutes on PR #77.
  - Verified by: execution - the job durations from `gh run view` for the pushed head
- [ ] The two macOS shards together run every suite exactly once, and the matrix rows match this requirement.
  - P4 note: with 3 shards, the criterion applies to all 3 macOS shards together.
  - Verified by: execution - the `Suites run` totals of both macOS shards sum to the Ubuntu total, and `test-0000043-req-001-macos-shards.sh` passes locally

## Dependencies

- `run-tests.sh` shard selection, `(position - 1) % count`, from 0000037 ADR 014.
- PR #77 and its GitHub Actions workflow.
