# Verify-by-Execution Report
**Toggle:** on
**Software exercised:** `gh` queries against PR #77 and run 42464874771, the two 0000041 suites and the 0000042 req-001 suite run with `bash` on macOS (no `RAVINTIO_PASS_COMMIT`), and the Windows shard 5 and 6 job logs (ANSI stripped).

| Requirement | Criterion | Method | Outcome | Observation evidence |
|-------------|-----------|--------|---------|---------------------|
| REQ-001 | AC1: all 14 PR checks pass | CLI: `gh pr checks 77 --json name,bucket,link`, `gh pr view`, `gh run view` | verified | Head is `605839cabfef10e41174ff4d3c167b272fbb025b`. All 14 checks have bucket `pass`. `gh run view 42464874771 --json jobs` shows all 14 jobs `success`, run attempt 2. Windows shard 4 (job 128685660802) is `success`, so the rerun of the 0000265 timing case passed. |
| REQ-001 | AC2: req-005 and req-006 suites pass natively with no SKIP line | CLI: ran both suites on macOS | verified | req-005 exit 0, `Results: 67 passed, 0 failed`, no `SKIP` text in output. req-006 exit 0, `Results: 127 passed, 0 failed`, no `SKIP` text in output (case-sensitive grep found 0 lines). |
| REQ-001 | AC3: Windows skips are printed with reasons and listed in the README | Log inspection of jobs 128681942074 and 128681942147, plus README read | verified | Shard 5 under `--- test-0000041-req-005-applies-to-header.sh ---` (log line 859) shows 4 `SKIP (windows)` lines (878 to 881), each ending "ln -s makes a copy under Git Bash, so a link cannot be built" (linked product.yml, component.yml, src/ravintio-framework folder, src folder). Shard 5 has other `SKIP (windows)` lines from other suites, outside this criterion. Shard 6 under `--- test-0000041-req-006-consumer-migration.sh ---` (line 1073) shows 1 line (1196): "a linked ravintio-framework: ln -s makes a copy under Git Bash, so a link cannot be built". Other shard 6 SKIP lines at 605 to 960 precede that header and belong to other suites. `src/ravintio-framework/tests/README.md` has one row each at lines 77 (req-005), 78 (req-006) and 79 (`test-0000042-req-001-windows-guards.sh`). |
| REQ-001 | Extra: guard suite `test-0000042-req-001-windows-guards.sh` | CLI: ran locally | verified | `Results: 8 passed, 0 failed`. The last three PASS lines cover the req-005 (67) and req-006 (127) native runs and the README row check. Exit status was not captured because of a zsh quirk in my command, but the zero-failure result line printed. |

## Notes

- Run 42464874771 attempt 2 holds the all-green state. The attempt 1 failure (shard 4, backlog 0000265) is a timing case that passed on rerun. This does not show the case is fixed.
- I made no code changes, commits, pushes or reruns. I left `plan/.run-mode` alone.
