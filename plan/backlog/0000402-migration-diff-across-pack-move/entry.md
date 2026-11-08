---
title: "Backlog Entry: 0000402 - migration diff across the pack move"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000402 - migration diff across the pack move

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

The 0000037 req-008 migration branch diff compares the pack against the highest `v*` tag. In the source repo, the tag `v0.38.0` holds the pack at `ravintio-framework/`, and the live pack now sits at `src/ravintio-framework/`. A diff with a `src/ravintio-framework` pathspec against that tag shows every pack file as added.

Today the real-repo case in `src/ravintio-framework/tests/test-0000037-req-008-migration-branch-diff.sh` skips, because no unreleased re-run-setup migration exists. The next unreleased one would likely make the case fail, and the delivered-file list it models would be wrong.

## Suggested Action

Map the old layout to the new one when the base tag predates the move. One option is to diff `{tag}:ravintio-framework` against `HEAD:src/ravintio-framework` as trees. Another is to treat the first tag after 0.39.0 as the base.

## Why Deferred

The case passes today, and the fix needs its own decision on how a diff spans the layout change. After the first release from `src/`, the base tag holds the new layout and the problem goes away.
