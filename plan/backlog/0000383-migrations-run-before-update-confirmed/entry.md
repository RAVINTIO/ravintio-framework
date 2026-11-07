---
title: "Backlog Entry: 0000383 - migrations run before step 1a confirms the pack"
summary: "Resume Detection step 1 runs migrations from the arriving pack before step 1a confirms that pack. The update policy says its check runs first."
status: "open"
---
# Backlog Entry: 0000383 - migrations run before step 1a confirms the pack

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

`ravintio-framework/skills/ravintio-orchestrator/SKILL.md` Resume Detection runs step 1 before step 1a. Step 1 invokes the migrator for each pending migration "before any other phase work" and says "Migrations take priority". Step 1a then detects a framework update and asks the human on the loop to confirm it and its provenance.

`ravintio-framework/standards/framework-update-policy.md` says the opposite order. Its `## Relationship to ravintio-migrator` section says the detection-and-confirmation step "happens first", and the migrator "may still run afterward".

So a session follows the instructions of migration files from a pack that the human on the loop hasn't confirmed yet. If they later reject the update, the migrations have already run.

0000041 req-003 rewrites step 1a and the policy's detection signal, but the confirmed design doesn't cover the step order.

## Suggested Action

Decide which order holds, then state it once in both texts. One option runs step 1a first and lets step 1 run only after a confirmed update or no update.

## Why Deferred

The 0000041 design confirms the detection signals, not the order of the Resume Detection steps. A new order changes when consumer migrations run, so it needs its own design decision.
