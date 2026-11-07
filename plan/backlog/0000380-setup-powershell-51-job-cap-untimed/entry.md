---
title: "Backlog Entry: 0000380 - setup-powershell-51 job cap untimed"
summary: "The setup-powershell-51 CI job runs three .ps1 passes inside a 10-minute cap that a 0000037 suite pins, and nobody has timed the 0000040 req-004 pass on Windows."
status: "open"
---
# Backlog Entry: 0000380 - setup-powershell-51 job cap untimed

**Source feature:** 0000040-retire-fast-path
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-11-07

---

## Problem

P4 cycle 1 of 0000040 added a req-004 pass to the `setup-powershell-51` job in `.github/workflows/ravintio.yml`. The job now runs three `.ps1` passes with `timeout-minutes: 10`.

The req-004 pass took about 77 seconds on macOS. Nobody has timed it on `windows-latest` under Windows PowerShell 5.1. `ravintio-framework/tests/test-0000037-req-011-windows-powershell-coverage.sh` line 51 pins the cap at 10, so raising it needs a change to that suite. If the job runs past 10 minutes, CI turns red with no code fault.

This is risk R-013 in the 0000040 risk register.

## Suggested Action

Read the job's real time from the 0000040 PR checks, and from the next few PRs. If it runs near the cap, raise `timeout-minutes` and the req-011 pin together, or split the job.

## Why Deferred

P4 kept the cap at 10 minutes because the 0000037 req-011 suite pins it, and only a CI run gives the real time. See the P4 decision in the 0000040 build log and TD-007 in `plan/current/recommendations.md`.
