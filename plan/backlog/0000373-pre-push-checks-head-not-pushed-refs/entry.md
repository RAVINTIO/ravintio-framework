---
title: "Backlog Entry: 0000373 - pre-push checks HEAD, not pushed refs"
summary: "pre-push checks the checked-out HEAD instead of the refs git passes on stdin, so pushing another branch skips the check."
status: "open"
---
# Backlog Entry: 0000373 - pre-push checks HEAD, not pushed refs

**Source feature:** 0000040-retire-fast-path
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-06

---

## Problem

`ravintio-framework/hooks/pre-push` diffs `HEAD` near lines 25 and 35. It doesn't read the local and remote refs that git passes on stdin.

In the P5 review, a clean branch was checked out. `git push origin feat:feat` then pushed a failing branch, and pre-push exited 0. CI still catches the change on the pull request. This predates 0000040.

## Suggested Action

Read each `<local ref> <local sha> <remote ref> <remote sha>` line from stdin, and check each pushed sha against its merge base. Skip delete pushes, where the local sha is all zeros. Add fixtures for pushing a branch that isn't checked out.

## Why Deferred

The gap predates 0000040, and CI covers it. A fix changes how pre-push picks its range, which needs its own design and tests.
