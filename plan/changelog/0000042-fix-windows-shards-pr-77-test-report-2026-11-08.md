# Test Report (0000042-fix-windows-shards-pr-77, 2026-11-08)

**Feature:** fix Windows shards on PR #77
**Plan date:** 2026-11-08

## 1. Tests Run This Plan (P4 Results)

| Test file | Requirement ID(s) | Status |
|-----------|-------------------|--------|
| `test-0000042-req-001-windows-guards.sh` | req-001 | pass: 10 of 10 on macOS, 6 of 6 plus one skip line on Windows |
| `test-0000041-req-005-applies-to-header.sh` | req-001 (changed suite) | pass: 67 of 67 on macOS, 55 of 55 with four skip lines on Windows |
| `test-0000041-req-006-consumer-migration.sh` | req-001 (changed suite) | pass: 127 of 127 on macOS, 124 of 124 with one skip line on Windows |

**Summary:** 3 suites run for req-001: 3 passed, 0 failed, 0 skipped. The full local run covered 177 suites. One failed, the 0000040 req-007 archive check, which fails on any feature branch after a P7 (backlog 0000428). PR #77 passes 14 of 14 checks on head `77626508`, after reruns of one Windows timing flake (backlog 0000265) and one macOS timeout (backlog 0000430).

## 2. Regression Pack State

**Total promoted tests:** 37
**Passed:** 37
**Failed:** 0

The local full run passed all 37 regression suites.

## 3. Newly Promoted Tests (This Feature)

None. No 0000042 suite carries a `# REGRESSION-CANDIDATE:` tag.

## 4. Summary

**Overall test health:** ⚠ Failures present; see sections above. The one local failure is the known 0000040 archive check (backlog 0000428), and CI passes.
