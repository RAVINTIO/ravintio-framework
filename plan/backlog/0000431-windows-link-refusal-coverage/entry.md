---
title: "Backlog Entry: 0000431 - Windows link refusal coverage"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000431 - Windows link refusal coverage

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000042-fix-windows-shards-pr-77
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-11-08

---

## Problem

No Windows run tests that `project-kind.mjs` and the 0.39.0 consumer migration refuse a linked path. The 0000041 req-005 and req-006 suites skip their five link cases on Windows, because Git Bash `ln -s` makes a copy. A junction from `mklink /J` needs no admin rights, so a Windows consumer can still hold one.

## Suggested Action

Build a real junction with `cmd //c mklink /J` in a Windows-only case, and run the five link cases against it.

## Why Deferred

See 0000042 ADR-002 and the `recommendations.md` Tech Debt row in `plan/_archive/0000042-fix-windows-shards-pr-77-2026-11-08/`. The security review rated the gap Medium (S-2), and R-001 accepts it.
