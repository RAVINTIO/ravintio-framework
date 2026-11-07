# Test coverage - ravintio-framework

Last updated: 0000041-pack-source-under-src

## Summary

| Type | Coverage | Notes |
|---|---|---|
| Unit | None | The pack has no unit-test harness. |
| Integration | Broad | Bash suites under `src/ravintio-framework/tests/`, run by `run-tests.sh`. |
| E2E | Partial | Scratch git repos exercise the release script, the readers, and the migration. |

The full run for 0000041 covers 176 suites.

## 0000041 suites

All eight sit in `src/ravintio-framework/tests/`.

| Suite | Requirement |
|---|---|
| `test-0000041-req-001-move-pack-to-src.sh` | The pack sits under `src/`, the root copy matches `v0.38.0`, and `product.yml` points at the new path. |
| `test-0000041-req-002-release-script.sh` | `build-release.mjs` output, exit codes, write boundary, recovery, and case-collision refusal. |
| `test-0000041-req-003-release-yml-readers.sh` | `release-check.mjs` lines, exit codes, the fallback, and file-level detection. |
| `test-0000041-req-004-component-path-rule.sh` | The manifest-location rule in codegen, ship, spec, and docs skills. |
| `test-0000041-req-005-applies-to-header.sh` | The header values, the migrator table, and `project-kind.mjs`. |
| `test-0000041-req-006-consumer-migration.sh` | The 0.39.0 migration on scratch consumers. |
| `test-0000041-req-007-released-tree-version-suite.sh` | The equality checks run on a released tree and skip on an open run. |
| `test-0000041-req-008-tests-and-ci-from-src.sh` | The resolver, CI paths, and the integrity job. |

Existing suites changed in 0000041 to read the pack through `tests/helpers/pack-root.sh`. The 0000039 brand guard and the 0000040 residue guard also run against the new layout.

## Known gaps

- The case-collision case (RS-F07) skips on a case-insensitive file system. Linux CI runs it.
- The same-user link race (RS-F02 to RS-F04) has no test, because the race cannot be made reliable.
- The real-repo case of the 0000037 req-008 suite skips (backlog 0000402).
- No test covers a deleted `release.yml` in the CI integrity job (backlog 0000418).
