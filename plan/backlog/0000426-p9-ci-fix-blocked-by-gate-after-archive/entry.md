---
title: "Backlog Entry: 0000426 - P9 CI fix blocked by the gate after archive"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000426 - P9 CI fix blocked by the gate after archive

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P9
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

Ship Step 10c tells an `autonomous` run to fix a red CI check on the feature branch. By then P7 Step 6 has archived `plan/current/`, so `plan/current/design.md` is gone. `gate-write` then refuses every write under `src/` with "No confirmed design". No fix attempt can land, and the Step 10c fix loop can never succeed for a `src/` cause.

In 0000041, two Windows shards failed on test-suite cases, and the fixer was blocked on its first edit.

## Suggested Action

Two options:

- Run the CI check before P7 archives, for example by raising the draft PR at the P6 gate and reading its checks before Step 6.
- Let `gate-write` read the design from the archive folder that `plan/.orchestrator-active` names while a P9 fix runs.

### The 0000041 fix that waits

The P9 fixer confirmed the causes and planned these edits. Both suites sit under `src/ravintio-framework/tests/`.

1. `test-0000041-req-005-applies-to-header.sh`:
   - Build `WORK` with `pwd -W` on Git Bash, so Node reads a Windows path.
   - Add the `IS_WIN` block, and guard the four link cases with one `SKIP (windows)` line.
   - Import `project-kind.mjs` through `pathToFileURL(...).href`.
   - Compare the released migration by git blob id at `HEAD` and at `v0.38.0`, not by working-tree bytes. Both ids already match.
2. `test-0000041-req-006-consumer-migration.sh`: guard Case 6, the linked `ravintio-framework/`, with an `IS_WIN` skip.
3. `tests/README.md`: add one Windows skip table row for each suite, dated in the existing format.

`project-kind.mjs` itself has no Windows fault.

## Why Deferred

The fix changes the ship sequence or the write gate, and each needs its own design. Weakening the gate mid-run is not an option.
