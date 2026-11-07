---
title: "Backlog Entry: 0000420 - release script link-swap races under a concurrent writer"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000420 - release script link-swap races under a concurrent writer

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-11-07

---

## Problem

`src/ravintio-framework/scripts/build-release.mjs` checks that each folder it writes to or deletes from is not a link, then acts. A concurrent writer running as the same user can swap a folder for a link between the check and the action. Findings RS-F02 and RS-F03 in `plan/_archive/0000041-pack-source-under-src-*/security-review-release-script.md` show writes and deletes landing outside the root copy in a scratch repo (186 writes and 2,886 deletes). The two findings are rated Medium. Node has no `openat`, so the script can't hold a folder handle across the check. The P5 gate accepted both under R-002 and narrowed the window with mode 0o700 work folders.

## Suggested Action

Check the device and inode of each parent folder before each write and each child delete. Or move the release step to a tool that offers `openat`, and keep the Node script as a wrapper. Record the chosen design in an ADR.

## Why Deferred

Risk R-002 in `plan/current/risk-register.md` records the acceptance. The fix needs its own design decision and a P5 review. The race needs a same-user writer running at the same time. See `recommendations.md` TD-002.
