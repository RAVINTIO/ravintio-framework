---
title: "Backlog Entry: 0000377 - migrator named path rule gaps"
summary: "The migrator's named-path refusals miss case variants, junctions, and hard links. Its autonomous confirmation rule and its code-line exclusion conflict with other rules."
status: "open"
---
# Backlog Entry: 0000377 - migrator named path rule gaps

**Source feature:** 0000040-retire-fast-path
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-06

---

## Problem

The P5 review of 0000040 found three gaps in `ravintio-framework/skills/ravintio-migrator/SKILL.md`, `### Named paths`:

1. **Refusals miss some forms.** On a case-insensitive volume, `SRC/app.js`, `Src/app.js`, and `./src/app.js` reach `src/`, but a literal `src/` prefix test misses them. The rule names only symbolic links, not Windows junctions, reparse points, or hard links. Severity Low, because released migrations are reviewed and each edit needs confirmation.
2. **The autonomous confirmation conflicts with a higher rule.** The skill says "In `autonomous` run mode you still ask and wait". `ravintio-framework/standards/autonomous-run-standards.md` lists seven exception items, and any other question becomes a decision. The skill's rule isn't on that list. Severity Low.
3. **The code-line exclusion conflicts.** `## Exclusions` says never to correct "Lines that are clearly code", near line 186. The 0.38.0 migration's CI edit removes shell code, and nothing reconciles the two rules.

## Suggested Action

- Compare named paths case-folded and normalised, and name junctions, reparse points, and hard links in the refusals.
- Add a named-path edit to the autonomous exception list, or state in the standard that the migrator's per-edit confirmation ranks above it.
- Say in `## Exclusions` that a `**May edit:**` edit is exempt from the code-line rule.

## Why Deferred

Items 2 and 3 change a standard and a shared skill rule, outside 0000040's confirmed scope. Item 1 is Low and needs fixtures on a case-insensitive volume and on Windows.
