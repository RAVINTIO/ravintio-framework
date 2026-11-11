---
title: "Backlog Entry: 0000436 - no rule for underscore-style secret keys"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000436 - no rule for underscore-style secret keys

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000044-credential-scan-word-boundary
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-10

---

## Problem

`CONTENT_RULES` in `src/ravintio-framework/scripts/credential-scan.mjs` has no rule for secret keys that put an underscore after `sk`, such as payment-provider live and test keys. The `api-secret-key` rule needs a hyphen after `sk`, so these keys pass the regex scan. The gap predates 0000044.

## Suggested Action

Add a named content rule for the underscore-style prefixes, with a word boundary before `sk` and a length floor. Add `rule_case` fixtures that build the key at run time.

## Why Deferred

Out of scope for 0000044, which changes only the `api-secret-key` boundary. A new rule needs its own review, as each rule is a standing control.
