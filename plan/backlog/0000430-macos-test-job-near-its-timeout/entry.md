---
title: "Backlog Entry: 0000430 - macOS test job runs near its timeout"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000430 - macOS test job runs near its timeout

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000042-fix-windows-shards-pr-77
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-08

---

## Problem

`.github/workflows/ravintio.yml` line 177 gives the `Test suite` jobs `timeout-minutes: 15` outside Windows. The `macos-latest` job runs the whole suite in one job, with no shards.

Recent `macos-latest` durations on PR #77:

| Run | Duration | Result |
|-----|----------|--------|
| 42409694287 | 14 min 48 s | success |
| 42464874771 | 10 min 11 s | success |
| 42467601591 | over 15 min | cancelled at the timeout, during the 0000032 suites |

The margin on a slow runner is under one minute. Each new suite adds time. `test-0000042-req-001-windows-guards.sh` runs the req-005 suite three times and the req-006 suite twice.

## Suggested Action

Shard the macOS job the way the Windows job is sharded, or raise its timeout with a recorded reason. Track the job duration in CI so the margin shows before a run times out.

## Why Deferred

The 0000042 run fixes two test suites, and the workflow file sits outside its component paths. A CI layout change needs its own design.
