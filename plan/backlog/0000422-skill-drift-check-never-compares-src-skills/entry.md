---
title: "Backlog Entry: 0000422 - skill drift check never compares src skills with the install"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000422 - skill drift check never compares src skills with the install

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-11-07

---

## Problem

`skill-drift-check.mjs` compares the installed skills in `.claude/skills/` with the pack it finds from its own path. In this repo the orchestrator runs the root `ravintio-framework/` copy, so the check never compares the install with `src/ravintio-framework/skills/`. A skill change under `src/` reaches the install only after a P7 rebuild and a setup re-run. Until then, nothing reports that the source and the install differ. Risk R-012 in `plan/current/risk-register.md` records this.

## Suggested Action

Add an optional source-repo mode to `skill-drift-check.mjs`. When `project-kind.mjs` prints `framework source`, the check also lists skills where `src/ravintio-framework/skills/` differs from the install, as a notice and not a failure.

## Why Deferred

US-001 deliberately keeps the install on the last release, so the gap is the intent of 0000041 and R-012 is accepted. A notice mode is a new feature with its own design. See `recommendations.md` Deferred Items.
