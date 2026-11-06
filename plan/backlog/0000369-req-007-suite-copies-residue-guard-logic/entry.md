---
title: "Backlog Entry: 0000369 - req-007 suite copies residue guard logic"
summary: "test-0000040-req-007 holds its own awk copy of the residue patterns and the history-line rule, which can drift from the req-006 guard."
status: "open"
---
# Backlog Entry: 0000369 - req-007 suite copies residue guard logic

**Source feature:** 0000040-retire-fast-path
**Source phase:** P3
**Deferral source:** tech debt
**Date filed:** 2026-11-06

---

## Problem

`ravintio-framework/tests/test-0000040-req-007-docs-and-adr-supersede.sh` scans its 15 rewrite-list files with its own awk copy of the residue patterns and the history-line rule, near line 65. `ravintio-framework/tests/test-0000040-req-006-residue-guard.sh` holds the governing copy.

If one copy changes and the other doesn't, the two suites can disagree on the same line.

## Suggested Action

Point the req-007 scan at the req-006 guard, for example through a shared helper that both suites source. Or drop the req-007 scan, because the guard already covers those files.

## Why Deferred

Both copies agree today, and both suites pass. A shared helper changes two suites and needs its own tests.
