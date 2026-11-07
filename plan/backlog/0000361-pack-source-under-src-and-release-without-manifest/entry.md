---
title: "Backlog Entry: 0000361 - Pack source under src and release without manifest"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000361 - Pack source under src and release without manifest

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000040-retire-fast-path
**Source phase:** P0
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-01

---

## Problem

Consumers copy `ravintio-framework/` into their repo root, and the copy carries `ravintio-framework/component.yml`. That manifest makes the pack look like the consumer's own source. Two pack skills already treat it that way in a consumer repo:

- `ravintio-framework/skills/ravintio-codegen-agent/SKILL.md:180`: if P3 changed any file under `ravintio-framework/`, the codegen agent bumps the pack manifest's minor version and sets its `feature` field.
- `ravintio-framework/skills/ravintio-ship-agent/SKILL.md:296`: with no `product.yml` and one component, P9 tags from `ravintio-framework/component.yml`.

The owner reports that consumer runs have counted the pack as source in the past.

## Suggested Action

Move the pack source under `src/` with its `component.yml`, and publish releases of `ravintio-framework/` without the component manifest. The design must settle these points:

- How consumers learn the pack version without a manifest. Resume Detection step 1a, `standards/framework-update-policy.md`, and migrator records read `ravintio-framework/component.yml` today.
- How this repo runs its own hooks: from a built root copy, from a release, or from `src/` directly.
- Which tool builds the release folder. Hard Limit 8 sanctions only named scripts, so a build script needs sanctioning, or CI builds the release.
- Every pack path that names `ravintio-framework/` stays the consumer runtime path. About 134 pack files name it, and released migrations can't change.
- The codegen close-out and the ship fallback stop naming the pack manifest.

## Why Deferred

It needs its own design and ADRs for release packaging and the repo layout. 0000040 already holds three stories. The 0000040 source folder rule reads `product.yml`, so it stays valid after the move with `product.yml` pointing at the new path.
