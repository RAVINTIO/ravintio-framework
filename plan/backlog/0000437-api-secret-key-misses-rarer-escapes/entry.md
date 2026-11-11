---
title: "Backlog Entry: 0000437 - api-secret-key misses rarer escapes"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000437 - api-secret-key misses rarer escapes

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000044-credential-scan-word-boundary
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-11

---

## Problem

The 0000044 `api-secret-key` rule in `src/ravintio-framework/scripts/credential-scan.mjs` matches `sk-` after a word boundary, a percent escape, `\n`, `\r`, `\t`, or a `\u` escape. The P5 re-review (`security-rereview.md`, N-001 to N-004) found contexts that still miss, and the rule before 0000044 caught all of them:

- a `\x` hex escape, such as the quote that nginx logs write as `\x22` (low)
- a key straight after an ANSI colour code, which ends in a letter (low)
- double percent-encoding, such as `%253D` (informational)
- the escapes `\b`, `\f`, `\v`, `\0`, and `\U` with 8 hex digits (informational)

## Suggested Action

Add `\\x[0-9A-Fa-f]{2}` and an ANSI colour code to the lookbehind, with suite cases. Judge the rest against how often they appear in committed files.

## Why Deferred

0000044 closed its medium finding, S-001. Each extra escape form is a low or informational gap, and each widens the pattern that readers must follow.
