---
title: "Backlog Entry: 0000418 - CI integrity job skips a deleted release.yml"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000418 - CI integrity job skips a deleted release.yml

**Source feature:** 0000041
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

The P5 fix for RC-F02 stops the step 1a fallback downgrade in a consumer. The `--files-only` mode of `src/ravintio-framework/scripts/release-check.mjs` still prints `skipped: no ravintio-framework/release.yml` and exits 0 when `release.yml` is absent. The `release-copy-integrity` job in `.github/workflows/ravintio.yml` treats that skip as a pass. After this repo's first 0.39.0 release, a PR that deletes `ravintio-framework/release.yml` and hand-edits the root copy passes the job with a notice.

The security re-review reproduced the skip in a scratch folder. A record was present and `release.yml` was deleted. `--files-only` printed the `skipped:` line and exited 0.

## Suggested Action

Fail the job when the root copy lacks `release.yml` but the root copy holds no `component.yml`. Or fail it once any tag at 0.39.0 or later exists.

## Why Deferred

The skip follows req-003 and ADR-009 as written. R-015 and RC-F07 already accept that a push can rewrite the copy. Changing the CI contract needs its own design decision.
