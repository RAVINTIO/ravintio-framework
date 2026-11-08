---
title: "Backlog Entry: 0000433 - Triage-message timing check flakes on Windows"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000433 - Triage-message timing check flakes on Windows

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000043-macos-test-job-timeout
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-08

---

## Problem

`src/ravintio-framework/tests/test-0000032-req-003-no-run-triage-message.sh` asserts that each hook call takes under 200 ms. On `windows-latest`, CI run `42488827931` failed `req-003: malformed JSON call completes under 200 ms (took 269 ms)` in shard 4 of 7. The same check passed in earlier PR #77 runs. 0000043 doesn't change that hook, so the failure comes from runner load.

The regression copy, `tests/regression/test-0000032-req-003-no-run-triage-message.sh`, holds the same four checks.

## Suggested Action

Treat this check like the ones in backlogs 0000265 and 0000275. Take the median of several calls, or raise the Windows limit with a stated reason. Pick all three up together.

## Why Deferred

0000043 changes the CI layout only. A fix to timing checks in other suites needs its own design across all three entries.
