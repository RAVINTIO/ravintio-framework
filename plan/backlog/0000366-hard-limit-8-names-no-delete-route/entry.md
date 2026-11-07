---
title: "Backlog Entry: 0000366 - Hard Limit 8 names no delete route"
summary: "Boot Hard Limit 8 allows file changes only through Write or Edit, and neither tool deletes a file, so agents delete through git rm or rm with no stated rule."
status: "open"
---
# Backlog Entry: 0000366 - Hard Limit 8 names no delete route

**Source feature:** 0000040-retire-fast-path
**Source phase:** P2
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-06

---

## Problem

Boot Hard Limit 8 says every change to code and project files goes through **Write** or **Edit**. It bans `rm` through Bash and sanctions no delete script. Neither **Write** nor **Edit** deletes a file.

Agents still delete files today:

- Feature runs remove pack files and backlog folders with `git rm`. 0000040 req-004 does the same for the retired track files.
- The migrator deletes its progress file in `ravintio-framework/migrations/migrate-adoption-mode-and-about-md.md` (line 117). The skill doesn't say how.

No rule says whether `git rm` counts as a change through git, which the rule names as a blind spot of the shell guard. So each run decides on its own.

## Suggested Action

State a delete route in Hard Limit 8. For example, allow `git rm -- {path}` for tracked files, and route untracked files to the human on the loop. Then align the migrator skill and the boot template with it.

## Why Deferred

The rule is a framework-wide policy change that needs its own design. 0000040 avoids it for the consumer scope record: the human on the loop runs that delete, and the migrator checks the result.
