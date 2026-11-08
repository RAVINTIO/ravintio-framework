# Test Report (0000043-macos-test-job-timeout, 2026-11-08)

**Feature:** shard the macOS test job and show each job's margin
**Plan date:** 2026-11-08

## 1. Tests Run This Plan (P4 Results)

| Test file | Requirement ID(s) | Status |
|-----------|-------------------|--------|
| `test-0000043-req-001-macos-shards.sh` | req-001 | pass (18 checks) |
| `test-0000043-req-002-job-margin.sh` | req-002 | pass (44 checks) |
| `test-0000031-req-001-003-ci-jobs.sh` | req-001 (layout updates) | pass (26 checks) |
| `test-0000037-req-010-windows-git-bash-leg.sh` | req-001 (layout updates) | pass (52 checks) |

**Summary:** the local full run on the final code ran 179 suites: 178 passed, 1 failed, 0 skipped. The failure is `test-0000040-req-007-docs-and-adr-supersede.sh`, whose local-`main` archive check fails on any branch that adds an archive. CI has no local `main` and skips that check (backlog 0000428).

CI run `42496182854` on head `1b44f04e` passed all 16 checks. The 3 macOS shards took 323 s, 275 s, and 320 s, and ran 60, 60, and 59 suites, which sum to Ubuntu's 179.

## 2. Regression Pack State

**Total promoted tests:** 37
**Passed:** 37
**Failed:** 0

The local full run passed all 37 regression suites.

## 3. Newly Promoted Tests (This Feature)

None. No suite from this run carries a `# REGRESSION-CANDIDATE:` tag.

## 4. Summary

**Overall test health:** ✅ Healthy. The one local failure is known, predates this run, and doesn't run in CI.
