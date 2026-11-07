---
title: "Iteration Log - 0000041-pack-source-under-src"
summary: "Execution log for the agent session."
status: "active"
version: "0.1.0"
---
# Iteration Log - 0000041-pack-source-under-src

> **Audience:** Build-assessment-agent (P8) and post-run technical review. This is NOT the PR changelog.

**Skill:** [docs-agent](../../ravintio-framework/skills/ravintio-docs-agent/SKILL.md)
**Date:** 2026-11-07
**Wave:** not waved

## Release summary

**Feature:** pack source under src
**Pipeline run:** P0 to P9 in `autonomous` mode. No phases skipped.
**Version:** 0.39.0
**PR:** [#77](https://github.com/RAVINTIO/ravintio-framework/pull/77), raised as a draft while exception items wait

### What was built

Version 0.39.0 moves the pack source to `src/ravintio-framework/` and ships the root `ravintio-framework/` as a release copy. The feature folds in backlog 0000361, 0000061, 0000378, 0000136, 0000368, and 0000181, with eight requirements under three user stories.

- **Pack move (req-001):** one recorded git pass moved 1,184 files (commit `a5055f44`). `product.yml` now points at `src/ravintio-framework/component.yml`.
- **Release script (req-002):** `build-release.mjs` builds the root copy from a clean `src/ravintio-framework/` tree, records `HEAD` as `source-commit`, swaps it in whole, and writes `release.yml` with a SHA-256 per file.
- **Release readers (req-003):** step 1a and `release-check.mjs` read `release.yml` first and fall back to `component.yml` only for a pack before 0.39.0.
- **Manifest rule (req-004):** `component-guide.md` owns the manifest location rule, which codegen and ship apply.
- **Applies to header (req-005):** `project-kind.mjs` tells the migrator whether a repo is the framework source or a downstream project.
- **Consumer migration (req-006):** `migrate-0.39.0-remove-pack-component-yml.md` offers to remove a leftover `ravintio-framework/component.yml`.
- **Released-tree version suite (req-007):** the version equality checks skip on an open run and run on a released tree.
- **Tests and CI from src (req-008):** `pack-root.sh` resolves the pack and the repo root, and the new `release-copy-integrity` CI job checks the root copy against its `release.yml`.

P5 rated the feature High. Two High reader findings stay open as accepted residual risk R-015, because a writer who can push to the pack can also rewrite the in-repo trust record.

## Iteration Steps Completed

| Phase | Status | Gate Result | Notes |
|-------|--------|-------------|-------|
| 0 - Assess & Coach | pass | Design confirmed: yes | 5 questions asked. Six backlog entries folded in. |
| 1 - Specification | pass | All artifacts produced: yes | 8 requirements. Design critic approved after 6 passes. 5 deviations. |
| 2 - ADRs | pass | 9 ADRs generated | Design critic approved at iteration 3. 3 deviations. |
| 3 - Code Generation | pass | Implementation complete: yes | 31 subagents. 1 rule breach. Full suite 176 passed. |
| 4 - Validation | pass | CI clean: yes | 0 cycles. Execution criteria verified. |
| 5 - Security | pass | Critical findings: 0 | Rated High. 2 High reader findings accepted under R-015. |
| 6 - Docs & Ship | pass | All docs synced: yes | P6 docs done. P7 to P9 follow. |

## Requirement Changes During Run

| Change | Phase Active | Classification | Action Taken |
|--------|-------------|----------------|-------------|
| Feature brief gains two acceptance criteria, one for req-004 and one for req-006 | P1 | additive | Design updated to 7 criteria. |
| req-001 adds the three `src/ravintio-framework/` prefixes to `em-dash-guard.mjs` scope | P1 | additive | Added to req-001 AC2. |
| `build-release.mjs` also writes two work folders beside the root copy | P1 | additive | `design.md` Security updated. |
| req-005 adds a migrator table that maps `retroactive-release-tags.md` to framework source | P1 | additive | `design.md` Dependencies updated. |
| req-006 adds step 3a for a leftover manifest listed in `product.yml` | P1 | additive | Records `skipped` with the reason `listed in product.yml`. |
| `design.md` gains a note that the human on the loop runs the delete | P2 | additive | Matches req-006, ADR-005, and ADR-008. |
| `design.md` Component Paths gains `./product.yml` and `./refresh-ravintio-framework-dir.ps1` | P2 | additive | `gate-write` had blocked both paths. |
| The accepted cross-session Scope Lock path no longer resets to the last commit | P2 | contradictory | ADR-002 and req-001 recover by state. `feature-brief.md` records the change. |
| req-002 gains the RS-F01, RS-F06, RS-F07, and RS-F08 rules and 0o700 work folders. req-003 gains RC-F02 and RC-F08. | P5 | additive | Security fixes, each re-reviewed in a fresh context. |
| req-002 gains the NF-02 folder refusal and the NF-03 0o755 root copy mode | P5 | additive | Fixed after re-review 1. Re-review 2 confirmed. |

The unclassified deviations wait for the pre-P7 deviation review.

## Self-Correct Log

- **P3, step 3:** the brand guard and residue guard allowlists named `^ravintio-framework/`. They now rewrite those entries to `^$RAVINTIO_PACK_REL/` at load time.
- **P3, step 4:** the req-001 fix broke three assertions in the 0000039 brand guard and req-005 suites. All three came from intended changes, and the orchestrator fixed them in the same commit.
- **P3, step 5:** the req-003 RED suite held three defects. A joined count read `000`, `awk -v` stripped regex escapes, and one `has_text` call searched the path string. The orchestrator fixed the suite, and no check weakened.
- **P3, step 5:** the first orchestrator `SKILL.md` draft reached 41,868 bytes against a 41,600-byte cap. One shorter sentence fixed it.
- **P3, full suite:** the first run failed 5 of 139 feature suites. One fixer resolved all five (`b14d0abc`). The second run passed 139 feature suites and 37 regression suites.
- **P4:** 0 cycles. Every check passed first time.
- **P5, full suite:** the portability lint flagged two GNU `stat -c` calls in the new req-002 cases. A Node mode reader replaced them.

## Quirks

- The root `ravintio-framework/` copy stays byte-identical to `v0.38.0` from P3 to P7. Hooks, skills, and `.claude/` in this run come from that copy, so changes under `src/ravintio-framework/` reach live sessions only after the P7 rebuild and a setup re-run (R-010, R-012).
- The installed 0.38.0 `em-dash-guard.mjs` skips `src/ravintio-framework/` prose for this whole run (R-011). P6 checks pack prose for em dashes by hand.
- Commit `b1c985dd` also holds the req-004 implementer's unfinished skill edits, because the orchestrator staged every changed path while that agent still ran. A later commit holds the rest.
- `plan/backlog/.next-id` holds `0000363` while entries reach `0000422`, and no pack file reads it (backlog 0000386).

## Rule breaches

Two subagents broke the Write-or-Edit rule (boot Hard Limit 8).

- **P3:** the req-008 AC3 test-writer ran `sed -i` once on `test-0000041-req-008-tests-and-ci-from-src.sh`.
- **P5:** the release-script test-writer changed `test-0000041-req-002-release-script.sh` with a Python one-liner. The change added 105 lines.

The orchestrator reviewed both diffs before commit and found content equal to what an Edit would produce. Backlog 0000238 covers the pattern.

## Backlog

| ID | Subject | Status |
|----|---------|--------|
| 0000382 | Gate root resolves to `src/` in the source repo | open |
| 0000383 | Migrations run before step 1a confirms the pack | open |
| 0000384 | Pack component docs ship in the release copy | open |
| 0000386 | Stale `plan/backlog/.next-id` file | open |
| 0000387 | `src/README.md` links a missing file | open |
| 0000391 | Gate permits writes to the release copy | open |
| 0000402 | Migration branch diff across the pack move | open |
| 0000403 | Brand guard and req-005 after the refresh script fix | closed in P3 |
| 0000415 | Migrations run before the release trust gate | open |
| 0000416 | Trust anchor outside the repo | open |
| 0000417 | Release build reads `HEAD` bytes | open |
| 0000418 | CI integrity skips a deleted `release.yml` | open |
| 0000419 | Release script runs a `GIT_CONFIG_GLOBAL` filter | open, filed in P6 |
| 0000420 | Release script link-swap races under a concurrent writer | open, filed in P6 |
| 0000421 | Step 1a unlisted file names reach the agent | open, filed in P6 |
| 0000422 | Skill drift check never compares `src/` skills | open, filed in P6 |

## Recommended Improvements

- Run `ravintio-framework/setup.sh` again after P7 so `.claude/` and `CLAUDE.md` match the 0.39.0 release. This run edits neither.
- Review R-015 before you share the framework more widely. Two High reader findings stay open under it.
- Add this run's two Write-or-Edit breaches to backlog 0000238, and consider a commit-time check as `recommendations.md` describes.
- Check the `release-copy-integrity` CI job after the first 0.39.0 release. Backlog 0000418 covers a deleted `release.yml`.
