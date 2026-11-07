# Test Report (0000040-retire-fast-path, 2026-11-07)

**Feature:** retire Fast Path and the Change Pipeline
**Plan date:** 2026-11-07

## 1. Tests Run This Plan (P4 Results)

| Test file | Requirement ID(s) | Status |
|-----------|-------------------|--------|
| `test-0000040-req-001-one-track-routing.sh` | req-001 | pass (43 checks) |
| `test-0000040-req-002-gates-ignore-scope-record.sh` | req-002 | pass (487 checks) |
| `test-0000040-req-003-no-commit-subject-exemption.sh` | req-003 | pass (108 checks) |
| `test-0000040-req-004-remove-track-files.sh` | req-004 | pass (171 checks) |
| `test-0000040-req-005-consumer-migration.sh` | req-005 | pass (106 checks) |
| `test-0000040-req-006-residue-guard.sh` | req-006 | pass (29 checks) |
| `test-0000040-req-007-docs-and-adr-supersede.sh` | req-007 | pass (54 checks) |

**Summary:** the post-P6 revalidation ran 167 suites: 166 passed, 1 failed, 0 skipped. The failing suite was `test-0000039-req-010-version-bump.sh`, on 3 checks that expect `product.yml` and `docs/about.md` to read 0.38.0 (backlog 0000368). P7 Step 5b set `product.yml`, and Step 6b writes `docs/about.md`, which clears the last 2 checks.

At P7 every 0000040 suite passed again on the committed tree. The P4 verify-by-execution report holds 18 verified rows, 0 failed, and 4 not verifiable here. The req-004 suite skips its link and failed-delete cases on Windows (backlog 0000381).

## 2. Regression Pack State

**Total promoted tests:** 37
**Passed:** 37
**Failed:** 0

The P6 revalidation passed all 36 earlier suites. The new copy passes 29 of 29. The pack under `ravintio-framework/tests/regression/` gains one suite from this feature, and every other entry is unchanged.

## 3. Newly Promoted Tests (This Feature)

| Test file | Promoted by | Decision rationale |
|-----------|-------------|-------------------|
| `test-0000040-req-006-residue-guard.sh` | agent | It guards a standing rule: live tracked paths and lines keep one pipeline track. The P1 decision named it for the pack. |

Not promoted:

- `test-0000040-req-001-one-track-routing.sh`: it reads this feature's doc wording, and the residue guard already keeps one track. The pack has no retire step (backlog 0000365).

## 4. Summary

**Overall test health:** ✅ Healthy
