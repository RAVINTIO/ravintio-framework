---
title: "Requirement: req-002 - Visible job margin"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: req-002 - Visible job margin

**Skill:** [spec-agent](../skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000043-macos-test-job-timeout
**Source:** US-002
**Priority:** must-have

## User Story

As a framework maintainer, I see each test job's elapsed time against its cap in the CI log, so that I can act before a job times out.

## Functional Requirements

- A step before the test step writes the start time, in whole seconds since the epoch, to `GITHUB_ENV`.
- Both new steps set `shell: bash`. Windows runners default to `pwsh`, where `date +%s` and the `GITHUB_ENV` append don't work.
- The elapsed step's `run:` block holds all of its logic, and no separate script file exists. The 0000043 suite extracts that block from the workflow and runs it under Bash with a faked start time, cap, and `GITHUB_ENV`.
- The margin warning measures the test step only, because the step cap is what stops a slow run. req-001's under-10-minutes criterion measures the whole job, which is the stricter measure.
- A step after the test step runs with `if: always()`. It runs after a pass, a failure, and a step timeout.
- That step prints one line: `Elapsed: {m} min {s} s of a {cap} min cap`. It reads `{cap}` from `matrix.cap` through an `env` value.
- When the elapsed seconds exceed the cap in minutes times 40, which is two-thirds of the cap, the step also prints `::warning title=Test job margin::{elapsed} of a {cap} min cap`. For a cap of 15, 600 s prints no warning and 601 s prints one. For a cap of 20, the line sits at 800 s.
- If the start time is missing or isn't a number, the step prints `Elapsed: unknown` and exits 0.
- The elapsed step always exits 0. The job result comes from the test step.
- The steps reference no secret, and the job keeps `permissions: contents: read`.
- `run-tests.sh` stays unchanged, so its output without `--quiet` stays byte-identical (0000038 req-003).
- A new suite, `test-0000043-req-002-job-margin.sh`, checks both new steps, `shell: bash`, the `if: always()` condition, and the warning text. It also runs the extracted `run:` block.
- Split step: keep. The requirement holds one observable outcome, the margin line, in three criteria.

## Acceptance Criteria

- [ ] Every test job log on PR #77 shows one `Elapsed:` line with its cap.
  - Verified by: execution - the job logs from `gh run view --log` for the pushed head
- [ ] The elapsed step prints its line after the test step fails or times out.
  - Verified by: execution - the 0000043 suite runs the extracted `run:` block with a start time 16 minutes old and a cap of 15, and checks the `if: always()` condition
- [ ] A test step past two-thirds of its cap prints one `::warning` line, and a test step at or under it prints none.
  - Verified by: execution - the 0000043 suite runs the extracted `run:` block at 9 and 11 minutes against a cap of 15

## Dependencies

- req-001, which adds `matrix.cap`.
