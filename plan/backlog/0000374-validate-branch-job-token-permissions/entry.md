---
title: "Backlog Entry: 0000374 - validate-branch job token permissions"
summary: "The validate-branch CI job has no permissions block and keeps the checkout token in the repo config."
status: "open"
---
# Backlog Entry: 0000374 - validate-branch job token permissions

**Source feature:** 0000040-retire-fast-path
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-06

---

## Problem

The `validate-branch` job in `ravintio-framework/hooks/ravintio.yml` and `.github/workflows/ravintio.yml`, near lines 8 to 13, has no `permissions:` block. Its `actions/checkout` step keeps the default `persist-credentials: true`.

The job runs only git and awk, not PR code, so the exposure is small (Info). This predates 0000040.

## Suggested Action

Add `permissions: contents: read` to the job, and `persist-credentials: false` to its checkout step, in both files. Check that the `test-0000040-req-003` line-for-line check still passes, and that backlog 0000311's template token work agrees.

## Why Deferred

The gap predates 0000040 and is Info. Backlog 0000311 already covers the template's token permissions, so the two should land together.
