---
title: "Backlog Entry: 0000371 - v0.37.2 release tag missing"
summary: "main carries framework 0.37.2, but the repository has no v0.37.2 tag. Tags stop at v0.37.1."
status: "open"
---
# Backlog Entry: 0000371 - v0.37.2 release tag missing

**Source feature:** 0000040-retire-fast-path
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-06

---

## Problem

`git tag` lists `v0.37.1` as the newest release tag. `main` carries `ravintio-framework/component.yml` version 0.37.2, so the 0.37.2 release has no tag.

P4 verify-by-execution needed a 0.37.2 consumer and had to build it from `git archive main` instead of the tag. Anyone who installs or compares by tag can't reach 0.37.2.

## Suggested Action

The human on the loop finds the commit that shipped 0.37.2 and tags it `v0.37.2`. Then check why the P9 tag step of that run didn't push a tag, for example a failed push or a skipped step.

## Why Deferred

Tagging a past release on `main` is a human-only action. The cause sits in an earlier run, outside 0000040.
