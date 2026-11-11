# Test Report (0000044-credential-scan-word-boundary, 2026-11-11)

**Feature:** stop the `api-secret-key` rule from matching `sk-` inside a word
**Plan date:** 2026-11-11

## 1. Tests Run This Plan (P4 Results)

| Test file | Requirement ID(s) | Status |
|-----------|-------------------|--------|
| `test-0000037-req-003-credential-scan.sh` | req-001 | pass (210 checks) |
| `regression/test-0000037-req-003-credential-scan.sh` | req-001 | pass (210 checks) |

**Summary:** the local full run on the final code ran 179 suites: 179 passed, 0 failed, 0 skipped.

CI on PR #78 head `6817bc51` passed all 16 checks. An earlier head, `4b795b00`, failed one shell guard timing check on Windows shard 3, at 278 ms against 200 ms, and passed on a rerun (backlog 0000275).

## 2. Regression Pack State

**Total promoted tests:** 37
**Passed:** 37
**Failed:** 0

The local full run passed all 37 regression suites.

## 3. Newly Promoted Tests (This Feature)

None. The only tagged suite is the 0000037 credential scan suite. This feature added the same cases to its regression copy, so P7 promotes nothing.

## 4. Summary

**Overall test health:** ✅ Healthy.
