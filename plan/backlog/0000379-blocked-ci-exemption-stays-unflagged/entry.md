---
title: "Backlog Entry: 0000379 - blocked CI exemption stays unflagged"
summary: "In a hooked consumer with no design, the 0.38.0 migration records the CI edit as skipped, and nothing later reminds the consumer that the fix(fast-path): exemption is still in place."
status: "open"
---
# Backlog Entry: 0000379 - blocked CI exemption stays unflagged

**Source feature:** 0000040-retire-fast-path
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-11-07

---

## Problem

In a consumer with the RAVINTIO hooks installed and no confirmed design, `gate-write` blocks the 0.38.0 migration's **Edit** to `.github/workflows/ravintio.yml`. Migrations run in Resume Detection, before P0, so this is the normal case in a hooked consumer.

The migration then records `skipped` with the reason `blocked`. It names the file and the 14 lines to delete by hand. A record makes the migration never pending again. So after that one notice, nothing tells the consumer that its CI still holds the `fix(fast-path):` exemption.

- Migration: `ravintio-framework/migrations/migrate-0.38.0-retire-fast-path-and-change-pipeline.md`, steps 5 and 7
- Risk: R-014 in the 0000040 risk register, accepted at P5

Any later migration with a `**May edit:**` path outside `plan/` and `docs/` meets the same block.

## Suggested Action

Add a check that keeps the leftover visible. For example, Resume Detection or `check-design` could warn while the consumer CI file still holds the exemption markers. A wider option is a route for a confirmed named-path edit that an agent can't forge. ADR-006 rejected a hook exception and a helper script for that reason, so any route needs its own design.

## Why Deferred

The human on the loop chose option 3 for exception 001 at P5. A blocked edit records `skipped`, and the block stays. See `plan/current/design.md` (Migration line and Risks), ADR-006 (Resolution), reversal verdict `plan/current/defect-reports/001-verdict.md`, and the Deferred Items row in `plan/current/recommendations.md`.
