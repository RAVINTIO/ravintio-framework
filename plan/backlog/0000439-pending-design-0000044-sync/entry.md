---
title: "Backlog Entry: 0000439 - pending design carries the 0000044 design sync"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000439 - pending design carries the 0000044 design sync

**Source feature:** 0000044-credential-scan-word-boundary
**Source phase:** P9
**Deferral source:** deliberate scope decision
**Date filed:** 2026-11-11

---

## Problem

The archived 0000044 design still names the plain word-boundary pattern. The shipped rule uses the escape-aware pattern from the P5 deviation. The human on the loop accepted that deviation and deferred the design edit to the next feature build.

## Suggested Action

At the next P0, move `plan/pending/design.md` to `plan/current/design.md` and keep its chore C-001 in scope. The chore lists the exact lines to change.

## Why Deferred

The human on the loop chose to fold this archive edit into the next build rather than edit the archive by hand.
