---
title: "Backlog Entry: 0000424 - em dashes in the setup-hook-integration scope doc"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000424 - em dashes in the setup-hook-integration scope doc

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P6
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

`src/setup-hook-integration/docs/scope.md` lines 5 to 10 hold six spaced em dashes. The pack prose style bans them. The em-dash guard doesn't scope `src/setup-hook-integration/`, so no write check caught them. 0000041 re-pathed those lines but didn't add the dashes. Cross-model review 2 found them (finding N1).

## Suggested Action

Replace each dash with a colon or a full stop. Then consider adding `src/setup-hook-integration/docs/` to the em-dash guard scope.

## Why Deferred

The dashes predate this feature, and the fix would widen 0000041's diff into an unrelated cleanup.
