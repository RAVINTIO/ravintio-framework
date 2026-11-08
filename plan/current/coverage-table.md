---
title: "Coverage Table - 0000042-fix-windows-shards-pr-77"
summary: "P4 semantic traceability: each acceptance criterion, its type, and the test that covers it."
---
# Coverage Table - 0000042-fix-windows-shards-pr-77

| REQ-ID | AC | Type | Covered by test | Pass/Fail |
|--------|----|------|-----------------|-----------|
| req-001 | AC1: both suites exit 0 on the Windows shards, and every PR #77 check passes | execution | PR #77 run 42464874771 for head `605839ca`. Windows shards 5 and 6 pass. `test-0000042-req-001-windows-guards.sh` assertions 1 and 4 cover the exit codes under a MINGW `uname`. | Pass for shards 5 and 6. Shard 4 failed on the backlog 0000265 timing flake and was rerun. |
| req-001 | AC2: Linux and macOS keep 67 and 127 passes with no SKIP line | execution | `test-0000042-req-001-windows-guards.sh` assertions 6 and 7 on macOS, plus direct macOS runs. The `ubuntu-latest` and `macos-latest` jobs pass. | Pass |
| req-001 | AC3: each skipped case prints one `SKIP (windows)` line, and `tests/README.md` lists one row per suite | execution | `test-0000042-req-001-windows-guards.sh` assertions 2, 3, 5, and 8. Windows shard 5 prints four req-005 skip lines, and shard 6 prints one req-006 skip line. | Pass |

Requirement-ID scan: 1 requirement, 0 unmapped. Every assertion label in the guard suite starts with `req-001:`.
