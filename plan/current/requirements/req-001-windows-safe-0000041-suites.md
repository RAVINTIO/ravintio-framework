---
title: "Requirement: req-001 - Windows-safe 0000041 suites"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: req-001 - Windows-safe 0000041 suites

**Skill:** [spec-agent](../skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000042-fix-windows-shards-pr-77
**Source:** US-001
**Priority:** must-have

## User Story

As a framework maintainer, I see both 0000041 suites pass on the Windows CI shards, so that I can merge PR #77.

## Functional Requirements

- `test-0000041-req-005-applies-to-header.sh` sets `IS_WIN=yes` when `uname -s` starts with `MINGW`, `MSYS`, or `CYGWIN`, as the 0000035 suites do.
- On Windows, the req-005 suite builds `WORK` from the `pwd -W` form of its scratch folder, with a `pwd` fallback. Git Bash converts command arguments but not text inside a `node -e` script, so Node then reads a Windows path.
- The req-005 suite adds the `native()` helper from the 0000035 suites, which runs `cygpath -m` when `command -v cygpath` finds it. The `node -e` scripts read `project-kind.mjs` through `native "$PK"`, because `pack-root.sh` builds `$FW` with `pwd` in POSIX form.
- The two `projectKind(root)` cases import `project-kind.mjs` with a dynamic `await import(pathToFileURL(...).href)` under `--input-type=module`, on every platform.
- The req-005 suite moves its four linked-path cases into one block behind one `IS_WIN` guard. On Windows, the guard prints one `SKIP (windows): {reason}` line for each of the four cases. Each reason names Git Bash `ln -s` making a copy.
- The released-migration check makes two blob id compares against `v0.38.0:ravintio-framework/migrations/retroactive-release-tags.md`:
  - the blob id of the pack copy at `HEAD`
  - the `git hash-object` id of the pack copy in the working tree, run inside the repository so `core.autocrlf` applies
- Both blob compares feed one assertion, so the suite's case count stays at 67. The assertion label names the blob id compare in place of "byte-identical".
- `test-0000041-req-006-consumer-migration.sh` moves Case 6, the linked `ravintio-framework/`, behind one `IS_WIN` guard. On Windows, the guard prints one `SKIP (windows): {reason}` line for the case.
- `src/ravintio-framework/tests/README.md` gains one Windows skip row for each new guard, so two rows, in the table's existing format.
- `project-kind.mjs`, the migrator, and every released migration stay unchanged.
- Split step: keep. The requirement holds one observable outcome and three criteria.

## Acceptance Criteria

- [ ] Both suites exit 0 on the Windows CI shards, and every PR #77 check passes on the pushed head.
  - Verified by: execution - `gh pr checks 77` on the head that P9 pushes
- [ ] On Linux and macOS, the req-005 suite still passes 67 cases and the req-006 suite still passes 127, with no SKIP line in either.
  - Verified by: execution - local macOS runs at P4, and the `ubuntu-latest` and `macos-latest` CI logs
- [ ] On Windows, each skipped case prints one `SKIP (windows)` line with its reason, and `tests/README.md` lists one row per suite.
  - Verified by: execution - the Windows shard 5 and 6 logs, and a search of `tests/README.md`

## Dependencies

- The `v0.38.0` tag in the CI checkout. The test job checks out with `fetch-depth: 0`.
- PR #77 and its GitHub Actions workflow, `.github/workflows/ravintio.yml`.
