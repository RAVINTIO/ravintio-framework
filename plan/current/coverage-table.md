---
title: "P4 Coverage Table - 0000041-pack-source-under-src"
summary: "Each acceptance criterion, its Verified by type, and the suite that covers it."
---
# P4 coverage table: 0000041-pack-source-under-src

Every criterion maps to a covering check. The suite results come from the P4 full run. The execution results come from `verification-report.md`.

| REQ-ID | AC | Type | Covered by test | Pass/Fail |
|--------|----|------|-----------------|-----------|
| req-001 | AC1 | execution | P3 git checks after the pass and at close-out, in the build log | pass |
| req-001 | AC2 | unit | `test-0000041-req-001-move-pack-to-src.sh` | see P4 run |
| req-001 | AC3 | unit | `test-0000041-req-001-move-pack-to-src.sh` | see P4 run |
| req-002 | AC1 | integration | `test-0000041-req-002-release-script.sh` | see P4 run |
| req-002 | AC2 | integration | `test-0000041-req-002-release-script.sh` | see P4 run |
| req-002 | AC3 | integration | `test-0000041-req-002-release-script.sh`, `test-0000035-req-008-sanctioned-scripts.sh`, `test-0000039-req-008-emitted-names.sh` | see P4 run |
| req-002 | AC4 | manual | P7 build-log Decision line and the final report | deferred to P7 |
| req-003 | AC1 | integration | `test-0000041-req-003-release-yml-readers.sh` | see P4 run |
| req-003 | AC2 | integration | `test-0000041-req-003-release-yml-readers.sh` | see P4 run |
| req-003 | AC3 | integration | `test-0000041-req-003-release-yml-readers.sh` | see P4 run |
| req-004 | AC1 | integration | `test-0000041-req-004-component-path-rule.sh` | see P4 run |
| req-004 | AC2 | integration | `test-0000041-req-004-component-path-rule.sh` | see P4 run |
| req-004 | AC3 | integration | `test-0000041-req-004-component-path-rule.sh` | see P4 run |
| req-005 | AC1 | unit | `test-0000041-req-005-applies-to-header.sh` | see P4 run |
| req-005 | AC2 | integration | `test-0000041-req-005-applies-to-header.sh` | see P4 run |
| req-005 | AC3 | execution | `verification-report.md` | see report |
| req-006 | AC1 | integration | `test-0000041-req-006-consumer-migration.sh` | see P4 run |
| req-006 | AC2 | execution | `verification-report.md`, with model cases in `test-0000041-req-006-consumer-migration.sh` | see report |
| req-006 | AC3 | integration | `test-0000041-req-006-consumer-migration.sh`, `test-0000035-req-010-migration-records-for-this-repo.sh` | see P4 run |
| req-007 | AC1 | integration | `test-0000041-req-007-released-tree-version-suite.sh` | see P4 run |
| req-007 | AC2 | integration | `test-0000041-req-007-released-tree-version-suite.sh` | see P4 run |
| req-007 | AC3 | execution | `verification-report.md` | see report |
| req-008 | AC1 | unit | `test-0000041-req-008-tests-and-ci-from-src.sh` | see P4 run |
| req-008 | AC2 | integration | `test-0000041-req-008-tests-and-ci-from-src.sh` and the full `run-tests.sh` exit | see P4 run |
| req-008 | AC3 | integration | `test-0000041-req-008-tests-and-ci-from-src.sh` | see P4 run |
