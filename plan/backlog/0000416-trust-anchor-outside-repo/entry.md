---
title: "Backlog Entry: 0000416 - pack trust anchor outside the repo"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000416 - pack trust anchor outside the repo

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Date filed:** 2026-11-07

---

## Problem

Step 1a decides whether a pack update needs human confirmation from files inside the same repo:

- `ravintio-framework/release.yml`
- `plan/framework-release.yml`
- `ravintio-framework/scripts/release-check.mjs`
- the `product.yml` source-repo signal

A push that can change the pack can change all four. The 0000041 P5 review shows five ways that push passes step 1a with no prompt. See findings F-01 and F-03 to F-07 in `plan/_archive/0000041-pack-source-under-src-*/security-review-readers-and-ci.md`. The risk is R-015.

## Suggested Action

Anchor trust outside the repo. One option is a signed `release.yml`, checked with a key the setup step installs. Another is to pin the expected `release.yml` digest and the checker's digest in a file setup writes outside the tracked tree. A simpler step is to store a digest of the whole `release.yml` in the record, which stops a push that leaves `plan/` alone.

## Why Deferred

Any in-repo record falls to a writer who can also edit that record. A real fix needs its own design for key or digest storage across consumer setups. The 0000041 change still narrows the gap, because step 1a compared the version only before it.
