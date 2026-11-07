---
title: "Backlog Entry: 0000372 - source folder rule path matching gaps"
summary: "pre-push and the CI source folder step miss quoted file names, renames out of a source folder, other-case paths, and non-normalised product.yml paths."
status: "open"
---
# Backlog Entry: 0000372 - source folder rule path matching gaps

**Source feature:** 0000040-retire-fast-path
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-06

---

## Problem

The P5 review of 0000040 ran the real `ravintio-framework/hooks/pre-push` and the CI step from `hooks/ravintio.yml` in scratch repos. Both gave exit 0, a pass, for these source changes with no record:

1. **Quoted file names.** `git diff --name-only` quotes a name with non-ASCII bytes, `"`, `\`, a tab, or a newline, as in `"src/\303\251.js"`, so `src/*` doesn't match. Lines: `pre-push` 35, and line 29 in both CI files. This predates 0000040.
2. **Renames out of a source folder.** Rename detection lists only the new path, so `git mv src/a.js lib/a.js` lists only `lib/a.js`. Lines: the same as item 1. This predates 0000040.
3. **Other-case paths.** `Src/evil.js` isn't source, but a case-insensitive checkout puts it in `src/`. Lines: `pre-push` 132, and line 126 in both CI files.
4. **Non-normalised base paths.** A base `product.yml` path such as `svc/./api/component.yml` or `svc//api/component.yml` makes no source folder, and no warning prints. Lines: `pre-push` 46 and 66, CI 40 and 60.

All four are Low. CI runs the same rule, so it misses them too. Only a maintainer error opens item 4, because the base file sits on `main`.

## Suggested Action

- Read the diff with `git -c core.quotePath=false diff --name-only --no-renames -z` and a NUL-delimited loop.
- Compare paths case-folded, and normalise `./` and `//` in `product.yml` paths.
- Change `pre-push`, `hooks/ravintio.yml`, and `.github/workflows/ravintio.yml` together, so the `test-0000040-req-003` line-for-line check still passes.
- Add a fixture for each case.

## Why Deferred

Items 1 and 2 predate 0000040, and every item is Low. The fix changes three files that must stay in step, and each case needs a fixture.
