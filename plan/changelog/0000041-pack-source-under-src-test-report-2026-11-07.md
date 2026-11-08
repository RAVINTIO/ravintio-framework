# Test Report (0000041-pack-source-under-src, 2026-11-07)

**Feature:** pack source under src
**Plan date:** 2026-11-07

## 1. Tests Run This Plan (P4 Results)

| Test file | Requirement ID(s) | Status |
|-----------|-------------------|--------|
| `test-0000041-req-001-move-pack-to-src.sh` | req-001 | pass (26 checks) |
| `test-0000041-req-002-release-script.sh` | req-002 | pass (126 checks, 1 skip on a case-insensitive file system) |
| `test-0000041-req-003-release-yml-readers.sh` | req-003 | pass (137 checks) |
| `test-0000041-req-004-component-path-rule.sh` | req-004 | pass (41 checks) |
| `test-0000041-req-005-applies-to-header.sh` | req-005 | pass (67 checks) |
| `test-0000041-req-006-consumer-migration.sh` | req-006 | pass (127 checks) |
| `test-0000041-req-007-released-tree-version-suite.sh` | req-007 | pass (27 checks) |
| `test-0000041-req-008-tests-and-ci-from-src.sh` | req-008 | pass (49 checks) |

**Summary:** the P4 run passed 176 suites, 0 failed, on the first attempt. P5 and P6 changed code and docs, so the full suite ran again after each. The last run, at `047a8020`, passed 139 feature suites and 37 regression suites, 0 failed.

The check counts above are from the last run of each suite. They exceed the P4 counts where P5 security fixes or the P6 cross-model fixes added cases.

The P4 verify-by-execution report verified req-005 AC3, req-006 AC2, and req-007 AC3, plus `release-check.mjs` and the `release-copy-integrity` run block on this repo. req-001 AC1 passed its git checks at P3. req-002 AC4 is manual and closes at P7 with the build-log Decision line and the final report.

## 2. Regression Pack State

**Total promoted tests:** 37
**Passed:** 37
**Failed:** 0

This feature edited six regression copies with the same edit as their twins, so they read the pack through `tests/helpers/pack-root.sh`. `regression-manifest.json` is unchanged, because its paths are relative to the pack.

## 3. Newly Promoted Tests (This Feature)

None. No 0000041 suite carries a `# REGRESSION-CANDIDATE:` tag.

Not promoted:

- `test-0000041-req-008-tests-and-ci-from-src.sh`: its static scan guards a standing rule, that no suite reads the root copy. The sanctioned `promote-to-regression.sh` accepts only a suite under `ravintio-framework/tests/`, which is now the release copy, and the scan already runs in every full suite.

## 4. Summary

**Overall test health:** Healthy. Every suite passes. The req-002 case-only collision case skips on this macOS file system and runs on the Linux CI shard.
