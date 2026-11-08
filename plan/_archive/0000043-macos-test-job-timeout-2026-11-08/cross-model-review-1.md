# Cross-model review 1 - 0000043-macos-test-job-timeout

**Verdict:** APPROVE

**Reviewer model:** claude-fable-5-1
**Implementer models:** claude-sonnet-5-5 (TDD subagents), claude-opus-5-5 (orchestrator fixes)

**Scope read:** `git diff 589ddf01..HEAD -- .github/ src/ docs/`, req-001, req-002, `design.md`, ADR-001 to ADR-004, `verification-report.md`, `deviation-review.md`, `risk-register.md`, and `execution-plan.md`. The P1 backstop deviation is an open exception for the human and is not re-judged here.

## Evidence

- All four suites pass locally: req-001 (18), req-002 (44), 0000031 req-001-003 (26), 0000037 req-010 (52). No failures.
- req-001 criteria: run `42490766491` concluded `success` with both macOS shards green. Shards took 392 s and 281 s, both under 10 minutes. Shard totals 90 + 89 match Ubuntu's 179. The matrix rows match the requirement line for line.
- req-002 criteria: each of the 10 test jobs printed one anchored `Elapsed:` line. The real `run:` block prints at 960 s past a cap of 15 and exits 0. The 600 s and 601 s boundary cases behave as specified. Windows shard 3 carried the one live `Test job margin` annotation.
- GitHub Actions semantics: the include-only matrix is valid. `matrix.shards || ''` gives an empty value on the Ubuntu entry, and `matrix.shard && format(...) || ''` keeps the plain Ubuntu name. A step-level `timeout-minutes: ${{ matrix.cap }}` parsed and ran. `if: always()` runs after a step failure or step timeout. The `GITHUB_ENV` append worked on all three runners, including Git Bash.
- No vacuous pass. The req-002 suite fails when extraction yields an empty block, because every behaviour check expects one output line. The req-001 suite compares exact `os|shard|shards|cap` rows.
- Docs match the code. `architecture-overview.md`, `decisions-index.md`, `component-registry.md`, `dependency-graph.md`, `quirks.md` (10-space indent, `ENVIRON` pattern, octal note), and `test-coverage.md` (179 suites) describe what the workflow and suites do. R-004 and R-005 exist in the risk register as the ADRs state. `run-tests.sh` and `hooks/ravintio.yml` are unchanged.

## Findings

1. **Minor.** `src/ravintio-framework/tests/test-0000043-req-002-job-margin.sh`, line 142 (`bash "$TMP_ROOT/elapsed.sh"`). The suite runs the block under plain `bash`, but GitHub runs `shell: bash` as `bash --noprofile --norc -eo pipefail`. The block has no command that `-e` would change today, so the result is the same. Fix: invoke `bash -eo pipefail "$TMP_ROOT/elapsed.sh"` so a future edit to the block is tested under the CI shell options.

No blocking or major finding.
