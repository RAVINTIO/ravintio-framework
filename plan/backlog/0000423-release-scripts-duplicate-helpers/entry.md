---
title: "Backlog Entry: 0000423 - release scripts duplicate five helpers"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000423 - release scripts duplicate five helpers

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-11-07

---

## Problem

`build-release.mjs` and `release-check.mjs` each define `clean`, `lstatOrNull`, `readNoFollow`, and `lfHash`. Each also scrubs the git environment, in two different shapes. A drift in one copy of `lfHash` would make the builder and the checker disagree on every file hash. Cross-model review 1, finding 4, raised this.

## Suggested Action

Add `scripts/release-common.mjs` and import the helpers from it in both scripts, as `path-rules.mjs` serves the hooks.

## Why Deferred

Refactoring the two release scripts at the end of P6 would reopen the P5 security review. The duplication is tracked in `src/ravintio-framework/docs/tech-debt.md`.
