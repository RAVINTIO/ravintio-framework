---
title: "Backlog Entry: 0000432 - Windows shards 3 and 4 run near their cap"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000432 - Windows shards 3 and 4 run near their cap

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000043-macos-test-job-timeout
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-08

---

## Problem

The Windows `Test suite` shards have a 20-minute cap. In PR #77 run `42476595066`, shards 3 and 4 each took about 15 minutes, and shards 2 and 5 took about 13. Shards 1, 6, and 7 took 5 to 6 minutes. The position split puts the slow suites into a few shards.

0000043 adds a warning past two-thirds of each job's cap, which is 13 min 20 s on Windows. Shards 3 and 4 will print that warning on most runs.

## Suggested Action

Balance the Windows shards by measured suite time, or add an eighth shard. Check the 0000043 elapsed-time lines to pick the split.

## Why Deferred

The 0000043 scope keeps the Windows shard count and cap unchanged. Rebalancing Windows needs its own measurements and design.
