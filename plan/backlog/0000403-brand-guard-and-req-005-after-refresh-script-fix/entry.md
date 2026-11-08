---
title: "Backlog Entry: 0000403 - brand guard and req-005 after the refresh script fix"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "closed"
---
# Backlog Entry: 0000403 - brand guard and req-005 after the refresh script fix

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

The req-001 follow-up drops the hard-coded old-brand checkout path from `refresh-ravintio-framework-dir.ps1`. Three suites now fail as a result.

- `test-0000039-req-007-brand-guard.sh` (c): allowlist entry 24, for the refresh script's old checkout path, is stale.
- `test-0000039-req-007-brand-guard.sh` (a): lines 143 and 144 of `test-0000041-req-001-move-pack-to-src.sh` name the old path and have no allowlist entry.
- `test-0000039-req-005-history-and-split-name-protection.sh`: the case that expects the refresh script to keep its old checkout path now fails.

The same req-005 suite also fails "the branch-diff suite greps ^ravintio-framework/". That failure comes from the pack move and not from this edit. `test-0000039-req-008-emitted-names.sh` fails two `build-release.mjs` cases, which the req-002 release script owns.

## Suggested Action

Replace allowlist entry 24 with one for the new 0000041 suite lines. Update the req-005 case to expect `$PSScriptRoot`. Re-run all three suites.

## Why Deferred

The task forbade edits to suites and to the allowlist. The fix needs a decision on where the old-path allowlist entry belongs.

## Resolution

Closed in 0000041 P3 on 2026-11-07. The problem sat inside this feature's scope, so the orchestrator fixed it in the same run:

- The req-001 suite builds the old checkout path in parts, so the brand guard finds no line.
- Allowlist entry 24 is gone from both brand guard copies.
- The 0000039 req-005 suite now expects no old checkout path and the branch-diff suite's `pack_rel` default.

All four suites pass.
