---
title: "Backlog Entry: 0000425 - credential scan flags release.yml hash lines"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000425 - credential scan flags release.yml hash lines

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P7
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

`scripts/credential-scan.mjs` flags `ravintio-framework/release.yml` lines 634 and 635 under its `api-secret-key` rule. Each line holds a pack path in the vendored risk requirements analysis skill, under `external-skills/`, and that file's SHA-256 hash. The skill's folder name joins `risk` and the next word with a hyphen. The rule likely reads the `sk` and hyphen inside that name, with the long run that follows, as a key. Prose that names the folder trips the same rule, so this entry names it in words.

Every release build writes these lines, so every autonomous P7 holds back `release.yml`. The 0000041 P7 commit left it untracked, and the human on the loop must clear it.

## Suggested Action

Narrow the `api-secret-key` rule so it needs a word boundary before `sk-`. Or teach the scan that a `release.yml` hash line has a fixed, safe shape. Add a suite case for a `release.yml` line under a `risk-` path.

## Why Deferred

The scan is a standing rule, and changing its patterns needs its own review. The agent must not edit a held-back file to hide a match.
