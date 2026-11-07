---
title: "Backlog Entry: 0000391 - gate permits writes to the release copy"
summary: "In the framework source repo, gate-write and shell-write-guard can't block an agent Write to the root ravintio-framework/ release copy once a design lists it under Component Paths."
status: "open"
---
# Backlog Entry: 0000391 - gate permits writes to the release copy

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P2
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

0000041 ADR-005 makes `build-release.mjs` the only writer of the root `ravintio-framework/` copy in the source repo. No agent may write it with **Write** or **Edit**.

The 0000041 design lists `ravintio-framework/` under `## Component Paths`, so P3 can commit the git pass and P7 can stage the rebuilt copy. `gate-write` in `hooks/enforcement/path-rules.mjs` then permits any **Write** or **Edit** to the root copy. `shell-write-guard` follows the same rule. Only rule text forbids the write: boot Hard Limit 8, the scope Out of Scope list, and ship Step 5c item 4.

The `release-copy-integrity` CI job (0000041 req-008) catches a hand edit only after the first `release.yml` exists. Any later design that lists the root copy reopens the same gap.

## Suggested Action

In the framework source repo, make `gate-write` block a **Write** or **Edit** to the root `ravintio-framework/` copy even when the design lists it. Detect the source repo with `projectKind(root)`. Keep `shell-write-guard` in parity, and add fixtures for both repo kinds.

## Why Deferred

The 0000041 design keeps the gate rules unchanged and lists the root copy in Component Paths. A gate change needs its own design and P5 review, as backlog 0000382 does.
