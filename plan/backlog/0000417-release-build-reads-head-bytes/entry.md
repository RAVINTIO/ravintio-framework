---
title: "Backlog Entry: 0000417 - release build reads committed bytes"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000417 - release build reads committed bytes

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P5
**Deferral source:** tech debt
**Date filed:** 2026-11-07

---

## Problem

`src/ravintio-framework/scripts/build-release.mjs` reads source bytes from the working tree. Two gaps follow:

- `git update-index --assume-unchanged` hides an edit from the dirty check, so the copy ships bytes that the named `source-commit` doesn't hold (P5 finding RS-F05).
- A same-user writer can swap a checked folder for a link between the check and the read (RS-F04).

## Suggested Action

Read each source file from `HEAD` through `git cat-file --batch`, so the copy holds exactly the committed bytes. The dirty check then matters only as a guard against a confusing release.

## Why Deferred

The change reworks the build's read path, and P5 rated both findings Low. Each needs a local actor who can already edit the source.
