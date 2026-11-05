---
title: "Backlog Entry: 0000365 - regression pack has no retire path"
summary: "promote-to-regression.sh only adds tests, and the manifest forbids hand edits, so no sanctioned step retires a regression test."
status: "open"
---
# Backlog Entry: 0000365 - regression pack has no retire path

**Source feature:** 0000040-retire-fast-path
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-05

---

## Problem

`ravintio-framework/scripts/promote-to-regression.sh` takes three arguments and only adds a test to `tests/regression/`. It has no mode that removes one.

`tests/regression/regression-manifest.json` says "Managed by promote-to-regression.sh — do not edit manually." The Write-or-Edit rule (boot Hard Limit 8) sanctions the script only with the arguments its skill step shows.

0000040 retires `test-0000017-req-007-change-agent-archive.sh`, which has a regression copy and a manifest entry. It also rewrites the regression copies of `test-0000005`, `test-0000032-req-003`, `test-0000032-req-004`, and `test-0000039-req-007`. No sanctioned step covers the removal, so the run must hand-edit the manifest against its own notice.

## Suggested Action

Add a retire mode to `promote-to-regression.sh` that deletes the copy and its manifest entry, and name it in the ship skill. Or change the manifest notice to allow a recorded hand edit when a feature retires a test.

## Why Deferred

0000040 needs only one removal, which a recorded hand edit covers. A new script mode needs its own design and tests.
