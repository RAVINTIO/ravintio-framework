---
title: "Backlog Entry: 0000361 - Narrow the 1.0.0 release scan to release files"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000361 - Narrow the 1.0.0 release scan to release files

> Path: `plan/backlog/0000361-narrow-the-1-0-0-release-scan/entry.md`

**Source feature:** 0000279-regulated-environment-backlog (PR #74)
**Source phase:** P9
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-31

---

## Problem

`ravintio-framework/tests/test-0000039-req-010-version-bump.sh` AC2 runs `git grep '1\.0\.0'` over the whole repository. Every hit must match an allowlist of phrasings. Any other mention of `1.0.0` fails CI, even when it isn't a release claim.

Feature 0000039 needed a one-off check that no file called the rename release 1.0.0. The test now runs on every PR and blocks unrelated work. PR #74 failed on two hits that make no release claim:

- `plan/backlog/0000348-pluggable-compliance-profiles/entry.md:37` uses `version: 1.0.0` as an example profile version.
- `plan/reports/2026-10-31-regulated-strategy-review.pdf` matches as a binary file, from PDF internals.

Each new allowed case grows the regex list in the test. Authors learn to avoid a common semver string instead of writing what they mean.

## Suggested Action

Limit AC2 to the files that can state the current release:

- `product.yml`
- `ravintio-framework/component.yml`
- `docs/about.md`
- `README.md`

AC1 already checks the version values in the first three. Add `-I` to any remaining `git grep` so binary files never match. Then drop the allowlist regexes that the narrower scope no longer needs.

## Why Deferred

PR #74 files backlog entries and a report. A change to a regression test is out of its scope and needs its own review.
