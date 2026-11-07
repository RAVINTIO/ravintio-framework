---
title: "Backlog Entry: 0000376 - setup linked parent parity and message"
summary: "setup.ps1 refuses a retired path whose parent links inside the project and says it resolves outside. setup.sh removes the same path."
status: "open"
---
# Backlog Entry: 0000376 - setup linked parent parity and message

**Source feature:** 0000040-retire-fast-path
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-06

---

## Problem

The P5 review of 0000040 made a retired path whose parent folder is a link to another folder inside the project:

- `setup.sh` `cleanup_retired_tracks` removes the path.
- `setup.ps1` `Invoke-RetiredTrackCleanup` refuses it and prints "resolves outside the project".

Both scripts fail safe, but the message is wrong, and ADR-005 of 0000040 claims parity between the two scripts.

## Suggested Action

Make `setup.ps1` resolve the parent's real path and compare it with the project root, as `setup.sh` does with `cd -P`. Or keep the refusal and print a message that says the parent is a link. Add a parity fixture to `test-0000040-req-004-remove-track-files.sh`.

## Why Deferred

Both scripts fail safe, and no file is lost. The fix needs a parity fixture across both shells.
