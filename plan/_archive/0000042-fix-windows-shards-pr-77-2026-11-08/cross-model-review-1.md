---
title: "Cross-model review 1 - 0000042-fix-windows-shards-pr-77"
summary: "Fresh-context REJECT-default review of the full 0000042 diff by a second model."
---
# Cross-model review 1 - 0000042-fix-windows-shards-pr-77

- Reviewer model: `claude-opus-5-5`
- Implementer model: `claude-sonnet-5-5`
- Diff reviewed: `git diff 9222025a HEAD`, with HEAD at `85193a01` (plan-only commit after docs commit `21bb30bc`)
- Date: 2026-11-08

## Verdict

APPROVE

The diff meets every functional requirement and acceptance criterion in req-001 that can be checked before P9. It follows ADR-001 to ADR-004 and introduces no regression. No finding is above Low.

## Local runs

All three suites ran on macOS from the source repo without `RAVINTIO_PASS_COMMIT`.

| Suite | Exit | Result | SKIP lines |
|---|---|---|---|
| `test-0000042-req-001-windows-guards.sh` | 0 | 10 passed, 0 failed | none printed natively |
| `test-0000041-req-005-applies-to-header.sh` | 0 | 67 passed, 0 failed | none |
| `test-0000041-req-006-consumer-migration.sh` | 0 | 127 passed, 0 failed | none |

The guard suite took about 4 seconds, so it adds no real load to the macOS job (backlog 0000430). The runs left no tracked file changed.

## Requirement evidence (req-001)

All paths below are under `src/ravintio-framework/tests/`.

| Functional requirement | Evidence | Met |
|---|---|---|
| `IS_WIN` from `uname -s` (`MINGW`, `MSYS`, `CYGWIN`) | `test-0000041-req-005-applies-to-header.sh` lines 37 and 38 | yes |
| `WORK` from `pwd -W`, with a `pwd` fallback | req-005 line 30 | yes |
| `native()` helper with `cygpath -m`, used for `$PK` | req-005 lines 32 to 34, 161, and 170 | yes |
| Dynamic `import(pathToFileURL(...).href)` under `--input-type=module` | req-005 lines 159 to 172 | yes |
| Four link cases in one `IS_WIN` block, one SKIP line each, reason names `ln -s` | req-005 lines 115 to 137 | yes |
| Two blob compares (`HEAD` blob and `hash-object` inside the repo) in one assertion | req-005 lines 254 to 262 | yes |
| Case count stays 67, label names the blob id compare | req-005 line 258, local run 67 passed | yes |
| req-006 Case 6 behind one `IS_WIN` guard with one SKIP line | `test-0000041-req-006-consumer-migration.sh` lines 40 to 42 and 373 to 382 | yes |
| Three README rows in the existing format | `README.md` lines 77 to 79 | yes |
| Guard suite skips its native-run checks on a real Windows shard | `test-0000042-req-001-windows-guards.sh` lines 23, 24, and 89 to 102 | yes |
| Failed `mktemp` exits before any write or delete, trap removes only the `mktemp` path | req-005 lines 27 to 29 | yes |
| Old blob resolves through `refs/tags/v0.38.0` with `rev-parse --verify` | req-005 line 254 | yes |
| `project-kind.mjs`, the migrator, and released migrations unchanged | `git diff 9222025a HEAD --stat` lists no such file | yes |

| Acceptance criterion | Status |
|---|---|
| AC1: both suites exit 0 on the Windows shards, and every PR #77 check passes | Met for head `77626508` per the brief and `verification-report.md`. The final head is still to come (finding 5). |
| AC2: 67 and 127 passes on Linux and macOS with no SKIP line | Met. Local runs above, plus guard suite checks 6 and 7. |
| AC3: one SKIP line per skipped case with reason, one README row per suite | Met. Guard suite checks 2, 3, 5, and 8, and the shard 5 and 6 logs cited in `verification-report.md`. |

## ADR conformance

- ADR-001: no new tool or library. `pwd -W` serves the scratch folder and `native()` serves `$PK`, as decided.
- ADR-002: one guard per suite, one SKIP line per case, and one README row per guard.
- ADR-003: both blob compares feed one assertion. `hash-object --path` runs with `-C "$RAVINTIO_REPO_ROOT"` and a repo-relative `--path`, so `.gitattributes` and `core.autocrlf` apply.
- ADR-004: process only, with no code. The build log records the CI reads before P5, and the P7 `release-check.mjs` step is still to come.

## Windows branch reasoning (Git Bash)

- `pwd -W` gives `C:/...` with forward slashes. MSYS bash accepts that form for `mkdir`, `mv`, `rm`, and redirects, so `mk_repo` and `run_pk` work. Node reads it unchanged inside the `-e` string.
- `pack-root.sh` builds `$FW` in POSIX form (`/d/a/...`). `cygpath -m` turns it into `D:/a/...`. `pathToFileURL` then gives `file:///D:/a/...`. Forward slashes mean no backslash escape can break the JavaScript string literal.
- On Linux and macOS, `pwd -W` fails and the fallback runs. `cygpath` is absent, so `native()` passes the path through. That holds under the guard suite's `uname` stand-in too.
- `git hash-object` receives `$REL` as a separate POSIX argument, which MSYS converts. `--path=src/...` is relative, so MSYS leaves it alone. The clean filter turns the CRLF working copy back to LF, so `WT_ID` matches the stored blob.
- `refs/tags/v0.38.0:path` peels the annotated tag to its tree. The path names the old root location (`ravintio-framework/...`) in both the source repo and a release copy, which is right because history stores it there. `HEAD:$REL_PATH` uses `RAVINTIO_PACK_REL`, so it reads `src/ravintio-framework/...` in the source repo and `ravintio-framework/...` in a release copy.
- `pack-root.sh` lines 35 to 38 stop any suite that runs from the root copy inside the source repo. So the `RAVINTIO_PACK_REL=ravintio-framework` branch runs only in a downstream checkout. There, a missing `v0.38.0` tag fails the check as it did before this diff, so this is no regression.

## Guard suite containment

- Both stand-ins (`uname` and `mktemp`) live under `$WORK` from `mktemp -d`. The `PATH` prefix reaches only the child `bash` and its descendants.
- The caller folder for the `mktemp` check is `$WORK/caller`, so a defect in the req-005 fail path can only delete inside `$WORK`.
- The `uname` stand-in calls `/usr/bin/uname` by absolute path, so it can't recurse.
- The suite's own trap removes `$WORK`, and its `mktemp` line keeps the safe form (line 26).
- The README rows follow one guard, one row. Each of the three suites has one guard and one row.

## Findings

| # | Severity | File | Line | Finding |
|---|---|---|---|---|
| 1 | Low | `src/ravintio-framework/component.yml` | 192 and 318 to 320 | The P6 docs pass adds no `# Updated by 0000042 (docs-agent) P6` comment and no `inScope` entry for the Windows guards or the new guard suite. Every earlier feature (0000039, 0000040, 0000041) added both. Version and `feature` are correct, so this is convention drift only. |
| 2 | Info | `docs/component-registry.md` | 13 | The `ravintio-framework` row has a doubled space before `[component.yml]` (`\|  [component.yml]`). The table still renders. |
| 3 | Info | `src/ravintio-framework/tests/test-0000042-req-001-windows-guards.sh` | 104 to 107 | Check 8 counts the req-005 and req-006 README rows but not the guard suite's own row at `README.md` line 79. A later edit could drop that row and the suite would stay green. |
| 4 | Info | `src/ravintio-framework/tests/test-0000042-req-001-windows-guards.sh` | 67 and 68 | On a real Windows shard, the suite still runs both target suites natively, although checks 6 and 7 skip there. The two runs cost time and give no result. Moving the `run_native` calls inside the `else` branch at line 93 would save that time. |
| 5 | Info | (process) | n/a | AC1 is proven for head `77626508`, not the final head. `origin` holds `e1b406fe`, and its checks were still pending at review time. `21bb30bc` and `85193a01` are not pushed yet, and P7 will rebuild the root copy. P9 must read `gh pr checks 77` on the head it pushes, as req-001 and ADR-004 require. |
| 6 | Info | `src/ravintio-framework/docs/quirks.md` | 49 | "Each suite puts its link cases behind one `IS_WIN` guard" reads as a rule for every suite. Older suites, such as `test-0000035-req-008-sanctioned-scripts.sh`, use several guards. Naming the 0000041 suites would remove the overreach. |

## Prose check

Added lines under `docs/` and `src/` hold no em dash and no semicolon outside code. A scan for common American spellings found none. The sentences use British spelling where it applies.
