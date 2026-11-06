---
title: "Backlog Entry: 0000370 - pre-push false empty path warning"
summary: "pre-push and the CI source folder step warn about an empty path: value when product.yml has no path: lines at all."
status: "open"
---
# Backlog Entry: 0000370 - pre-push false empty path warning

**Source feature:** 0000040-retire-fast-path
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-06

---

## Problem

`ravintio-framework/hooks/pre-push` prints "product.yml at {label} has an empty path: value. The rule ignores it." near line 100. The CI source folder step prints the same text.

Both print it when `product.yml` holds no `path:` line at all, for example `components: []`. No empty value exists, so the warning misleads the reader. The verdict is still correct.

P4 verify-by-execution found it in a scratch repo.

## Suggested Action

Warn only when a `path:` key is present with an empty value. Add a fixture with `components: []` that expects no warning. Change `pre-push`, `hooks/ravintio.yml`, and `.github/workflows/ravintio.yml` together, so the `test-0000040-req-003` line-for-line check still passes.

## Why Deferred

The warning doesn't change any verdict, and no req-003 criterion covers warning text for this case. A fix touches three files that must stay in step.
