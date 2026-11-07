---
title: "Backlog Entry: 0000368 - version equality suite red from P3 to P7"
summary: "test-0000039-req-010-version-bump.sh needs product.yml and docs/about.md to match component.yml, but P3 bumps component.yml and only P7 bumps the other two."
status: "open"
---
# Backlog Entry: 0000368 - version equality suite red from P3 to P7

**Source feature:** 0000040-retire-fast-path
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-06

---

## Problem

`ravintio-framework/tests/test-0000039-req-010-version-bump.sh` checks that `product.yml`, the `docs/about.md` frontmatter, and the `docs/about.md` table all read the `ravintio-framework/component.yml` version.

The codegen agent bumps `component.yml` in P3, so the ship agent reads the right version for the tag. The ship agent sets `product.yml` at P7 Step 5b through `set-product-release.mjs`, and `docs/about.md` at P7 Step 6b. So the suite fails on three checks for the whole run from P3 to P7. That holds for every feature that changes the pack, and P4 sees a red full suite it must not fix.

## Suggested Action

Make the equality checks hold only on a released tree. For example, skip them while `plan/current/design.md` exists, or move them into a P7 check that runs after Step 6b.

## Why Deferred

The fix changes a 0000039 suite's rule and needs its own design. 0000040 accepts the three failures until P7 and records them for P4.
