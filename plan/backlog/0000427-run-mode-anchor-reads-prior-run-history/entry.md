---
title: "Backlog Entry: 0000427 - Run-mode anchor reads prior runs' history"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000427 - Run-mode anchor reads prior runs' history

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000042-fix-windows-shards-pr-77
**Source phase:** P0
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-08

---

## Problem

`scripts/run-mode.mjs` walks the whole git history of `plan/current/build-log.md`. That history holds every earlier run's build log, not only the current one.

In 0000042, commit `e2c82a17` added the autonomous anchor and confirmed the design. The script still printed `interactive` with this reason:

```
run-mode: autonomous not anchored: a commit removed or edited the confirmation line
```

The removal it found is `ecdc151d` (`plan(p7): archive plan/current`), which archived the 0000041 build log and its anchor. Commit `f6b91afe` added that older anchor. So every autonomous run after the first one in a repo reads as `interactive`, and every skill that calls the script then falls back to interactive stops.

## Suggested Action

Limit the history walk to commits after the current run's start. One option is to stop at the newest commit that created `plan/current/build-log.md`. Another is to stop at the P7 archive commit of the run before. Add a suite with two autonomous runs in one fixture repo.

## Why Deferred

The 0000042 run fixes two test suites for PR #77. A change to the run-mode integrity check needs its own design and its own threat review.
