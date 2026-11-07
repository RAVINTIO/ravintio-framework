---
title: "Backlog Entry: 0000375 - setup.ps1 Remove-Item junction and wildcard"
summary: "setup.ps1 removes folders with Remove-Item -Recurse, which may follow a nested junction under Windows PowerShell 5.1. The manifest prune also uses -Path, which expands wildcards."
status: "open"
---
# Backlog Entry: 0000375 - setup.ps1 Remove-Item junction and wildcard

**Source feature:** 0000040-retire-fast-path
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-06

---

## Problem

`ravintio-framework/setup.ps1` removes folders in three places:

- `Remove-Item -LiteralPath $full -Recurse -Force`, near lines 808 and 878
- the manifest prune's `Remove-Item -Path $_ -Recurse -Force`, near line 1394

Under Windows PowerShell 5.1, `-Recurse` may follow a junction or directory link nested inside the folder and delete the target's contents. PowerShell 7 removes the link only. The P5 review of 0000040 couldn't run 5.1, so it has no execution evidence. No test puts a junction inside a retired folder.

Line 1394 also uses `-Path`, so a manifest entry holding `[` or `*` expands as a wildcard. That prune predates 0000040, and backlog 0000255 covers its path trust.

## Suggested Action

- Before a recursive remove, delete each reparse point inside the folder as a link first, for example with `[System.IO.Directory]::Delete($link)` or `cmd /c rmdir`.
- Change line 1394 to `-LiteralPath`.
- Add a 5.1 CI fixture with a junction inside a retired folder.

## Why Deferred

There's no execution evidence yet, and the prune code predates 0000040. The fix needs a 5.1 fixture in the `setup-powershell-51` job.
