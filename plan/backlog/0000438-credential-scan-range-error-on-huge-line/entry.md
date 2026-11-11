---
title: "Backlog Entry: 0000438 - credential scan RangeError on a huge line"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000438 - credential scan RangeError on a huge line

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000044-credential-scan-word-boundary
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-11

---

## Problem

A single line that holds about 10 MB of key-class characters makes V8 throw a `RangeError` in `contentHits` in `src/ravintio-framework/scripts/credential-scan.mjs`. The scan then exits 2, so it fails closed and the commit stops. The rule before 0000044 throws on the same input. The P5 re-review recorded it as N-005 in `security-rereview.md`.

## Suggested Action

Cap the class run, for example at `{20,512}`, or catch the error per line and report the line as unscannable. Add a suite case with a generated long line.

## Why Deferred

Out of scope for 0000044. The fault predates it, and it fails safe.
