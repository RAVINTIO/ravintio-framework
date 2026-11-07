---
title: "Backlog Entry: 0000419 - release script runs a GIT_CONFIG_GLOBAL filter"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000419 - release script runs a GIT_CONFIG_GLOBAL filter

**Source feature:** 0000041-pack-source-under-src
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-11-07

---

## Problem

The P5 fix for RS-F06 clears `GIT_CONFIG_COUNT` and `GIT_CONFIG_PARAMETERS` and forces `core.fsmonitor=false` in `src/ravintio-framework/scripts/build-release.mjs`. It does not clear `GIT_CONFIG_GLOBAL` or `GIT_CONFIG_SYSTEM`. A clean filter in the file those variables name still runs during the build's `git status`. The P5 re-review reproduced it as finding NF-01 (`filter ran: yes`) and rated it Low. See `plan/_archive/0000041-pack-source-under-src-*/security-rereview.md`.

## Suggested Action

Set `GIT_CONFIG_GLOBAL` and `GIT_CONFIG_SYSTEM` to the null device for every git call in `build-release.mjs`, and add the same cases to `src/ravintio-framework/tests/test-0000041-req-002-release-script.sh`. Check whether `release-check.mjs` needs the same change.

## Why Deferred

The 0000041 P5 gate accepted NF-01 as Low residual risk under R-002. It needs a local actor who already controls the user's global git config. See the Decision (P5) lines in the build log and `recommendations.md` TD-001.
