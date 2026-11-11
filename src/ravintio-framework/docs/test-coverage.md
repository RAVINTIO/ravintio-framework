# Test coverage - ravintio-framework

Last updated: 0000044-credential-scan-word-boundary

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

## 0000042 suite

| Suite | Requirement |
|---|---|
| `test-0000042-req-001-windows-guards.sh` | Runs the 0000041 req-005 and req-006 suites under a `uname` stand-in that reports `MINGW64_NT`, and counts their `SKIP (windows)` lines. Checks both suites still pass 67 and 127 cases natively, checks the `tests/README.md` rows, and runs the req-005 suite under a failing `mktemp` stand-in. |

The 0000041 req-005 and req-006 suites changed in 0000042: one Windows guard each, Windows paths for Node, and a blob id compare. The full run for 0000042 covers 177 suites.

## 0000043 suites

| Suite | Requirement |
|---|---|
| `test-0000043-req-001-macos-shards.sh` | The `test-suite` matrix rows, `RAVINTIO_SHARD_COUNT` from `matrix.shards`, the job name, the step timeout from `matrix.cap`, and the 25-minute job timeout. |
| `test-0000043-req-002-job-margin.sh` | Both timing steps, `shell: bash`, and `if: always()`. It extracts the elapsed step's `run:` block and runs it under a fixed `date` stand-in, covering the two-thirds boundary, a timed-out step, and hostile start and cap values. |

The 0000031 req-001 and 0000037 req-010 suites changed in 0000043 to check the per-entry cap and the 3 macOS shards. The full run for 0000043 covers 179 suites.

## 0000044 changes

0000044 adds no suite. Both copies of `test-0000037-req-003-credential-scan.sh` gain a `0000044 req-001` block and a `# Verified by: unit` header line. Each copy passes 210 checks.

- 4 negative cases: a `release.yml` hash line under the vendored risk requirements analysis skill folder, and keys after an ASCII letter, a digit, and `_`.
- 11 positive cases: keys at column 1, after `=`, a double quote, and a colon, and after 7 escapes. The escapes are `%3D`, `%22`, `%20`, `%3A`, `\n`, `\t`, and `"`.

The full run for 0000044 covers 179 suites.

## Known gaps

- The case-collision case (RS-F07) skips on a case-insensitive file system. Linux CI runs it.
- The same-user link race (RS-F02 to RS-F04) has no test, because the race cannot be made reliable.
- The real-repo case of the 0000037 req-008 suite skips (backlog 0000402).
- No test covers a deleted `release.yml` in the CI integrity job (backlog 0000418).
- No Windows run tests that `project-kind.mjs` and the 0.39.0 migration refuse links. Linux and macOS run those cases (0000042 ADR-002, backlog 0000431).
- No test covers a `mktemp` that prints nothing and exits 0 in the req-005 suite. The suite checks for it (0000042 security re-review R-2).
- No test covers a key after a `\x` escape or an ANSI colour code, which the `api-secret-key` rule misses (backlog 0000437).
- No CI run has shown the elapsed step after a real step timeout. The req-002 suite runs the step's block with a start 16 minutes old (0000043 verification report).
