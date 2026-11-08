---
title: "Backlog Entry: 0000387 - src README broken structure link"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000387 - src README broken structure link

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

`src/README.md` line 5 links to `../ravintio/spec/feature-structure.md`. That file doesn't exist in this repo. The README also says each component under `src/` is a subfolder with a `component.yml`, which `src/setup-hook-integration/` meets but the text doesn't explain.

## Suggested Action

Point the link at `plan/feature-structure.md` or `docs/component-registry.md`, whichever holds the canonical layout. Add the link to the self-description check if that check reads `src/README.md`.

## Why Deferred

The 0000041 design doesn't list `src/README.md` in scope. The broken link doesn't block the move or the release script.
