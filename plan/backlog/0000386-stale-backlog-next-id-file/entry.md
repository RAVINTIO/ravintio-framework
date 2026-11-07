---
title: "Backlog Entry: 0000386 - Stale backlog next-id file"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000386 - Stale backlog next-id file

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

`plan/backlog/.next-id` holds `0000363`, but `plan/backlog/` already holds entries up to `0000381`. No pack skill, standard, or script reads the file. The backlog ID rule is "highest ever allocated + 1", stated in `ravintio-framework/templates/backlog-entry.template.md`.

Another session wrote the file in `be64f10c` when it filed `0000362`. That ID sits below the high-water mark of `0000381`. A session that trusts the file can reuse a retired ID, because P0 deletes picked-up entries.

## Suggested Action

Remove `plan/backlog/.next-id`, or make one script own it and compute it from git history. Either way, the template rule stays the single source of the next ID.

## Why Deferred

It's out of scope for 0000041, which moves the pack source under `src/`. No current entry collides, so it doesn't block the run.
