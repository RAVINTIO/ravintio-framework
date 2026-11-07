---
title: "Requirement: req-007 - released-tree-version-suite"
summary: "The 0000039 req-010 version equality checks run only on a released tree. On an open run the suite reports each of them skipped with a reason."
status: "draft"
version: "0.1.0"
---
# Requirement: req-007 - released-tree-version-suite

**Skill:** [spec-agent](../../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Source:** US-001 (backlog 0000368 folded in)
**Priority:** must-have

## User Story

As a framework maintainer, I change the pack under `src/ravintio-framework/` while this repo runs on the last release at the root, so that a broken change can't break the run that builds it.

This requirement serves US-001 through the version suite. From P3 to P7 the run changes the pack version, so the suite must not fail the run that builds the change. It still holds in full on a released tree.

## Functional Requirements

### Background (backlog 0000368)

- The suite is `src/ravintio-framework/tests/test-0000039-req-010-version-bump.sh` after the req-001 pass. No copy sits in `tests/regression/`.
- The codegen close-out bumps the pack `component.yml` at P3. The ship agent sets `product.yml` at P7 Step 5b and `docs/about.md` at P7 Step 6b. So three AC1 checks fail for the whole run from P3 to P7.

### The rule

- A released tree is one where `plan/current/design.md` is not a regular file at the repo root. The suite tests it with `[ -f "$RAVINTIO_REPO_ROOT/plan/current/design.md" ]`.
- On a released tree, every check runs as today.
- On an open run, the suite skips these three equality checks and only these:
  - `product.yml version reads $WANT`
  - `docs/about.md frontmatter version reads $WANT`
  - `docs/about.md table Version cell reads $WANT`
- For each skipped check, the suite prints one line in this form: `SKIP (open run): {check name}. plan/current/design.md exists, so P7 has not set product.yml and docs/about.md yet. The check runs on a released tree.` The form follows the `SKIP (windows): {reason}` convention in `tests/README.md`.
- These checks run on every tree, open or released:
  - the `component.yml` version is a 0.37 or later 0.x release
  - `component.yml` reads `$WANT`, which is its own value
  - `product-version.mjs` prints `$WANT`. It reads each component version live, so it agrees with the bumped `component.yml` from P3 on.
  - every AC2 check, the `1.0.0` scan
- The skip never counts as a pass or a fail in the `assert.sh` totals.

### Path changes after the move

This requirement owns every change to this suite, so req-008 leaves it alone.

- Source `src/ravintio-framework/tests/helpers/pack-root.sh` from req-008. `FRAMEWORK` becomes `$RAVINTIO_PACK_DIR` and `REPO` becomes `$RAVINTIO_REPO_ROOT`. The suite no longer climbs out of the pack with `$FRAMEWORK/..`.
- The AC2 scan reads the pack source, not the root copy:
  - In the source repo, add the pathspec `:!ravintio-framework`, so the scan skips the release copy. req-008's integrity check covers that copy.
  - Build every pack path in `EXEMPT` and in the `OTHER_RE_*` regexes from `$RAVINTIO_PACK_REL`. In the source repo that value is `src/ravintio-framework`. Escape its `/` and `.` for the regexes.
- The check labels name `$RAVINTIO_PACK_REL/component.yml` in place of `ravintio-framework/component.yml`.
- The header comment states the released-tree rule and cites backlog 0000368 and this requirement.
- Add `src/ravintio-framework/tests/test-0000041-req-007-released-tree-version-suite.sh`. It builds a scratch git repo with these files, all committed:
  - `product.yml` that lists `ravintio-framework` at `src/ravintio-framework/component.yml`
  - `docs/about.md`
  - `src/ravintio-framework/component.yml`
  - `src/ravintio-framework/scripts/product-version.mjs`
  - `src/ravintio-framework/tests/helpers/`
  - the version suite
- The new suite runs the copied version suite in the scratch repo with and without `plan/current/design.md`. It sets the versions to match or to differ for each case.
- Split step: keep. The skip rule and the move to the resolver change one suite's verdict on one tree, so neither ships alone without a red suite.

## Acceptance Criteria
- [ ] With `plan/current/design.md` present, `component.yml` at 0.39.0, and `product.yml` and `docs/about.md` at 0.38.0, the version suite exits 0. It prints three `SKIP (open run):` lines, one per equality check, each with the reason, and still runs the format, `product-version.mjs`, and AC2 checks. Verified by: integration
- [ ] With `plan/current/design.md` absent, the same mismatch makes the version suite exit non-zero with a FAIL line for each of the three checks. With all four versions equal, it exits 0 and prints no `SKIP (open run):` line. Verified by: integration
- [ ] On this repo during the run, `bash src/ravintio-framework/tests/test-0000039-req-010-version-bump.sh` exits 0. Run with the suite's pathspecs, `git grep -n -I '1\.0\.0'` returns no hit whose path starts with `ravintio-framework/`. Verified by: execution

## Dependencies
- req-001 (move-pack-to-src) moves the suite to `src/ravintio-framework/tests/`.
- req-008 (tests-and-ci-from-src) provides `tests/helpers/pack-root.sh` and its variables `RAVINTIO_PACK_DIR`, `RAVINTIO_REPO_ROOT`, `RAVINTIO_PACK_REL`, and `RAVINTIO_SOURCE_REPO`.
- req-008's static scan must pass on this suite once req-007 lands.
