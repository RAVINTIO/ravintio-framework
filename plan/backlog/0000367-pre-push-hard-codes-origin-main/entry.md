---
title: "Backlog Entry: 0000367 - pre-push hard-codes origin/main"
summary: "The pack pre-push hook always diffs against origin/main, so a consumer repo whose default branch is master gets no pre-push check."
status: "open"
---
# Backlog Entry: 0000367 - pre-push hard-codes origin/main

**Source feature:** 0000040-retire-fast-path
**Source phase:** P2
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-06

---

## Problem

`ravintio-framework/hooks/pre-push` sets `TARGET_BRANCH="origin/main"` at line 5 and diffs `$TARGET_BRANCH...HEAD` at line 11. Setup points `core.hooksPath` at the pack hooks, so every consumer repo runs this hook.

In a repo whose default branch is `master`, or before the first push, the `origin/main` ref doesn't exist. The diff then finds no files, and the hook passes every push. The CI template accepts `master`, so such consumers exist.

## Suggested Action

Resolve the base from the remote's default branch through `origin/HEAD`, then fall back to `origin/main` and `origin/master`. Print a warning when none resolves.

## Why Deferred

0000040 keeps today's verdict for a missing ref and leaves the check to CI (ADR-003, R-012). Choosing the default branch is a separate pre-push change with its own tests.
