---
title: "Backlog Entry: 0000382 - gate root resolves to src in the source repo"
summary: "With the pack at src/ravintio-framework/, path-rules.mjs takes src/ as the repo root when the walk starts under src/ and CLAUDE_PROJECT_DIR is unset."
status: "open"
---
# Backlog Entry: 0000382 - gate root resolves to src in the source repo

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

`ravintio-framework/hooks/enforcement/path-rules.mjs` finds the root with `markedRoot()`. The nearest folder that holds a `ravintio-framework/` folder wins over one that holds only `.git`.

After the 0000041 move, `src/` holds `src/ravintio-framework/`. A walk that starts at or below `src/` stops at `src/` and takes it as the root. The walk starts there when `CLAUDE_PROJECT_DIR` is unset and the working folder is under `src/`.

A P1 probe in a scratch layout confirmed it:

- cwd `repo/src/ravintio-framework/skills` with no `CLAUDE_PROJECT_DIR`: `resolveRoot` returned `repo/src`.
- The same cwd with `CLAUDE_PROJECT_DIR=repo`: it returned `repo`.

With `src/` as the root, the gates look for `src/plan/current/design.md`. That file never exists, so `gate-write` and `shell-write-guard` block every write outside the always-permitted paths. Claude Code sets `CLAUDE_PROJECT_DIR`, so its sessions read the right root. Tools without that variable, such as Cursor, Windsurf, and Cline, can't edit the pack source from a working folder under `src/` in this repo. `run-tests.sh` unsets the variable, so a suite that runs a hook against the real repo from a folder under `src/` sees the same root.

Consumer repos hold no `src/ravintio-framework/`, so they aren't affected.

## Suggested Action

Make `markedRoot()` ignore a `ravintio-framework/` marker inside a `src/` folder of a higher marked folder, as it already ignores markers under `plan/` and `docs/`. Keep `gate-write` and `shell-write-guard` in parity, and add a fixture for the source-repo layout.

## Why Deferred

The 0000041 design doesn't list the gate root rule in scope, and a change to it needs its own design and P5 review. This run uses Claude Code, which sets `CLAUDE_PROJECT_DIR`, so it isn't blocked.
