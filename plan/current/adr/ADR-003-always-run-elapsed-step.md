---
title: "ADR 003: Always-run elapsed step"
summary: "A start-time step and an if: always() elapsed step print each test step's time against its cap, and a dedicated suite tests the step by extracting its run block."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Always-run elapsed step

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000043-macos-test-job-timeout
**Component:** repository CI, ravintio-framework
**Date:** 2026-11-08

## Context

US-002 asks for each test job's elapsed time against its cap. A timed-out job is the case that matters most. A job timeout cancels the job, and this run has no source that says a later step still runs after it. A step timeout only fails the step, so later `if: always()` steps run. The P4 CI run checks this (execution plan A-002). `run-tests.sh` output must stay byte-identical (0000038 req-003), so the runner can't print the time. A step can't read another step's duration.

## Decision

- A `shell: bash` step before the test step appends `RAVINTIO_TEST_START=$(date +%s)` to `GITHUB_ENV`.
- A `shell: bash` step after the test step runs with `if: always()`. Its `env` passes `CAP` from `matrix.cap` (ADR-002).
- It prints `Elapsed: {m} min {s} s of a {cap} min cap`.
- When the elapsed seconds exceed `CAP * 40`, it also prints `::warning title=Test job margin::{elapsed} of a {cap} min cap`.
- It checks that the start time and `CAP` are digits only before any arithmetic. Otherwise it prints `Elapsed: unknown`.
- It always exits 0. The job result comes from the test step.
- The logic stays inline in the step's `run:` block. `test-0000043-req-002-job-margin.sh` extracts that block from the workflow and runs it under Bash with faked values.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Print the time from `run-tests.sh` | One place for timing | Breaks byte-identical output, and a cancelled job prints nothing | 0000038 req-003 |
| A separate script file for the step | Easy to test directly | One more file in the release copy for a repository-only job | Extraction tests the real text |
| Read job duration from the API after the run | Exact durations | Needs a token and a second workflow | Adds a secret path for a log line |

## Affected Components

| Component | Impact |
|-----------|--------|
| repository CI | Two new steps in the `test-suite` job |
| ravintio-framework | One new suite, `test-0000043-req-002-job-margin.sh` |

## Consequences

**Positive:**
- A timed-out test step still shows its time in the log.
- The suite tests the exact text that CI runs.

**Negative:**
- The suite depends on the step's layout in YAML. A reformat of the step can break the extraction.

**Risks:**
- A later step can read `RAVINTIO_TEST_START` from `GITHUB_ENV`. The value is a number, and the digits check stops any other value. The risk register holds this as R-005.

## Related ADRs

- ADR-002 - depends-on

## Supersedes

- None

## Superseded By

- None
