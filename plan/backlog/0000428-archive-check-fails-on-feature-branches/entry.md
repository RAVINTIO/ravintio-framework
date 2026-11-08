---
title: "Backlog Entry: 0000428 - Archive check fails on feature branches"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000428 - Archive check fails on feature branches

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000042-fix-windows-shards-pr-77
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-08

---

## Problem

`src/ravintio-framework/tests/test-0000040-req-007-docs-and-adr-supersede.sh` asserts "plan/_archive/ holds no change against main". It runs `git diff --name-only main -- plan/_archive/` against the working tree.

That diff is never empty on a feature branch whose run reached P7, because P7 adds `plan/_archive/{feature-id}-{date}/`. On `feat/0000041-pack-source-under-src`, the 0000041 archive makes the local full suite fail with 53 passed and 1 failed.

CI has no local `main` ref, so the suite skips the check there, and the PR checks stay green. The fault shows only in a local P4 run.

## Suggested Action

Pin the check to 0000040's own pass. One option is to compare `plan/_archive/` between the 0000040 pass commit and its parent. Another is to allow additions of new archive folders and fail only on a change to an existing one.

## Why Deferred

The 0000042 run fixes two 0000041 suites on Windows. This check belongs to 0000040, and its fix needs its own decision about what "no change" means after later runs.
