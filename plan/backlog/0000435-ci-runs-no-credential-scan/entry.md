---
title: "Backlog Entry: 0000435 - CI runs no credential scan"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000435 - CI runs no credential scan

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000044-credential-scan-word-boundary
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-10

---

## Problem

`.github/workflows/ravintio.yml` runs neither `credential-scan.mjs` nor gitleaks on a pull request. The scan runs only before autonomous commits, on the machine that makes them. gitleaks isn't installed on the maintainer's machine, so every scan there runs regex only. Risk R-001 in 0000044 names gitleaks as the fallback for a key the regex rule misses, but that fallback doesn't run anywhere by default.

## Suggested Action

Add a CI job that runs `credential-scan.mjs` over the PR diff, and runs gitleaks too. Keep it read-only, with `permissions: contents: read`.

## Why Deferred

Out of scope for 0000044, which changes one rule and adds no CI job. A new CI job needs its own design for runtime and permissions.
