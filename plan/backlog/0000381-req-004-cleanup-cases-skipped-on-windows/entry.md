---
title: "Backlog Entry: 0000381 - req-004 cleanup cases skipped on Windows"
summary: "The 0000040 req-004 suite skips its two link cases and its failed-delete case on Windows, so no Windows run covers those setup cleanup branches."
status: "open"
---
# Backlog Entry: 0000381 - req-004 cleanup cases skipped on Windows

**Source feature:** 0000040-retire-fast-path
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-11-07

---

## Problem

`ravintio-framework/tests/test-0000040-req-004-remove-track-files.sh` skips three cases on Windows:

- The linked skills folder, near line 269. Git Bash `ln -s` makes a copy.
- The retired path that is a link, near line 299, for the same reason.
- The undeletable retired folder, near line 333. `chmod 555` does not block deletes on NTFS.

The `ravintio-framework/tests/README.md` Windows skip table lists them. The P4 5.1 CI step runs this suite, but these three cases never run there. PowerShell 7 on macOS and Linux covers them for `setup.ps1`. No run covers the retired-track cleanup's link and failed-delete branches on a real Windows file system.

Backlog 0000210 covers the same `ln -s` limit for other suites, but doesn't list this one.

## Suggested Action

Build real links on the runner, as backlog 0000210 suggests, and remove the two link guards. For the failed delete, deny delete through an ACL with `icacls`. Then remove the skip table row.

## Why Deferred

The fixtures need runner setup outside 0000040's scope, and PowerShell 7 already covers the branches on other platforms. See the P4 deviation in the 0000040 build log and TD-008 in `plan/current/recommendations.md`.
