---
title: "Backlog Entry: 0000415 - migrations run before the release trust gate"
summary: "Orchestrator Resume Detection runs pending migrations from an unconfirmed ravintio-framework/ pack in step 1, before step 1a asks the human on the loop to confirm the update."
status: "open"
---
# Backlog Entry: 0000415 - migrations run before the release trust gate

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

`ravintio-orchestrator/SKILL.md` Resume Detection runs step 1 before step 1a. Step 1 lists `ravintio-framework/migrations/*.md` and invokes the migrator for each pending file. Step 1a then runs `release-check.mjs` and asks the human on the loop to confirm the update with its provenance.

So a pack that arrives in an unrelated push gets its migration instructions followed before anyone confirms it. From 0000041, the migrator's Step 1b also runs `ravintio-framework/scripts/project-kind.mjs` from that same unconfirmed pack.

Migrations still ask the human on the loop before each edit, so a migration can't change a file silently. The agent still reads and acts on text from a pack nobody has trusted yet. That text can shape what it shows the human on the loop.

The order predates 0000041. The 0000041 P5 review of the readers and CI (`plan/current/security-review-readers-and-ci.md`) found it.

## Suggested Action

Run step 1a before step 1, or make step 1 stop when step 1a reports an unconfirmed update. Run no migration and no pack script until the human on the loop confirms the update with its provenance.

## Why Deferred

The order is pre-existing and isn't in the 0000041 scope. Changing the Resume Detection order touches every migration run, so it needs its own design and P5 review.
