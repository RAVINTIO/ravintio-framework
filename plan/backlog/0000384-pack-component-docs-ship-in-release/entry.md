---
title: "Backlog Entry: 0000384 - pack component docs would ship in the release copy"
summary: "After the move, docs-agent's src/{component-id}/docs/ rule puts the pack's per-component docs inside src/ravintio-framework/, so the release script copies them into every consumer's ravintio-framework/."
status: "open"
---
# Backlog Entry: 0000384 - pack component docs would ship in the release copy

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

`ravintio-framework/skills/ravintio-docs-agent/SKILL.md` line 90 writes per-component docs to `src/{component-id}/docs/`. Today the pack component has no such folder, and `docs/component-registry.md` records that.

After 0000041 moves the pack to `src/ravintio-framework/`, that rule points at `src/ravintio-framework/docs/`. The release script copies all of `src/ravintio-framework/` except `component.yml` into the root copy. So any per-component docs that docs-agent writes for the pack would ship to every consumer as `ravintio-framework/docs/`.

The confirmed 0000041 design states the manifest rule only. It says nothing about where a component's docs live when its folder is also its shipped payload. 0000041 req-004 leaves the docs path unchanged.

## Suggested Action

Decide where a component-pack's per-component docs live, for example a `docs/` folder the release script excludes, or a path outside the pack folder. Then state it in docs-agent and `component-guide.md`, and teach the release script to exclude it if needed.

## Why Deferred

The 0000041 design confirms the manifest rule, not a docs-path rule. A docs-path rule changes docs-agent output and the release script's file set, so it needs its own design decision.
