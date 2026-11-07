# Cross-model verdict 1: 0000040-retire-fast-path

**Verdict: APPROVE**

- Reviewer model id: `claude-sonnet-5-5`
- Implementer model id: `claude-opus-5-5`
- Date: 2026-11-07
- Run mode: autonomous
- Branch: `feat/0000040-retire-fast-path`
- Rubric: REJECT by default. Approve only when evidence shows each requirement is met.

## Result

All seven requirements are met. The full suite passes except the three known `test-0000039-req-010-version-bump.sh` checks (P7 sets `product.yml` and `docs/about.md`, backlog 0000368). The four findings below are Low or Informational and block nothing.

## Test runs

| Run | Result |
|-----|--------|
| `run-tests.sh --quiet` at HEAD | 130 of 131 feature suites passed. 36 of 36 regression suites passed. 167 suites ran in 12 minutes 37 seconds. |
| The one failing suite | `test-0000039-req-010-version-bump.sh`, 3 checks. The failures are the known, accepted ones. No other check failed. |

## Requirement-by-requirement

| Req | Verdict | Evidence | Gap |
|-----|---------|----------|-----|
| req-001 one-track routing | Met | `test-0000040-req-001-one-track-routing.sh` passes. `grep -i` for the retired words finds none in the orchestrator, ship agent, boot template, or phase-0 reference. The verification report shows the `auto-trigger-orchestrator.mjs` run naming only the Feature Pipeline. | None. |
| req-002 gates ignore scope record | Met | `test-0000040-req-002-gates-ignore-scope-record.sh` passes. `path-rules.mjs` drops 300 lines of scope code. The report's 48-row matrix gives `gate=2 guard=2` on every no-design row, with and without a record. A control run on 0.37.2 admitted the write. | Linux and Windows parity is CI-only (X-004). |
| req-003 no commit-subject exemption | Met | `pre-push` and both CI files hold no `fast-path` text. I read the `pre-push` diff. It fails closed on a shallow clone, reads `product.yml` at base and HEAD, and treats `component.yml` as source. The suite passes. The report shows pre-push and CI agree on 18 shared fixtures, and the 133 run lines match. | None. |
| req-004 remove track files | Met | `test-0000040-req-004-remove-track-files.sh` passes. `workflows/` holds `feature-pipeline.md` and `retrofit.md` only. `setup.sh:742-799` and `:1133-1145` implement the retired list and the prune skip. The report shows one `(retired, removed)` line per path for all seven tools. | PowerShell 5.1 parity is not verified here (X-004). |
| req-005 consumer migration | Met | `test-0000040-req-005-consumer-migration.sh` passes. The migration carries the four header lines, with `**May edit:**` naming only the CI file. The report shows full, second, skipped, declined, and edited-block runs, and the `blocked` outcome through the real `gate-write`. | The leftover block in a hooked consumer is accepted (R-014). |
| req-006 residue guard | Met | `test-0000040-req-006-residue-guard.sh` passes with 0 offences on the real tree. The report shows planted lines, a planted path, and a stale entry all failing as required. My own `grep -i` over live files found hits only in the setup retired lists, migrations, `component.yml` history comments, and docs that name the retirement. All match the allowlist intent. | None. |
| req-007 docs and ADR supersede | Met | `test-0000040-req-007-docs-and-adr-supersede.sh` passes. `docs/architecture-overview.md:581,585` and the decisions index carry `Superseded by 0000040` notes. `git diff main...HEAD` shows no change under `plan/_archive/`. The pack `component.yml` reads 0.38.0. | `product.yml` and `docs/about.md` wait for P7, which is the known item. |

## Findings

| ID | Severity | File or criterion | Issue | Suggested fix |
|----|----------|-------------------|-------|---------------|
| X-001 | Low | `plan/current/verification-report.md`, "Out-of-scope findings" item 1 | The item says a second setup run deletes a retired skill folder outside the project through the manifest prune. Deviation row 22 and `setup.sh:1133-1135` show that P4 fixed this with the prune skip. The report still reads as an open defect. | Add a line to the report that the prune skip closed this case, and name the test that covers it. |
| X-002 | Low | `plan/current/verification-report.md`, REQ-007 criteria 1 and 2 | Both rows say "observed at P4, before P6" and ask P6 to rerun the guard. The suite now passes at HEAD, but the report was not updated after P6. | Append a re-verification note that the req-006 and req-007 suites pass at the P6 HEAD. |
| X-003 | Low | req-004 criterion 3, deviation row 23, backlog 0000381 | The PowerShell 5.1 CI run of the req-004 suite skips the link and failed-delete cases under Git Bash. PowerShell 7 covers them on macOS and Linux. Windows PowerShell 5.1 has no execution evidence for those two cases. | Backlog 0000381 tracks it. Close it before the next release that touches setup cleanup. |
| X-004 | Informational | req-002 criterion 3, req-004 criterion 3, req-006 criterion 3 | Linux, Windows, and 5.1 shards are `not-verifiable` in the report because only macOS ran. These rows pass or fail in CI on the pull request. | Check the pull request's CI result before the human on the loop merges. |

## Checks that found nothing

- Security report: the three reviewers found no hook regression. Every verdict that changed between `main` and the branch went from allow to block. The open Low items map to backlog entries.
- Deviation review: rows 1 to 25 are additive. Row 26 is altering and matches exception 001, resolved by the human on the loop with option 3.
- Docs against code: `docs/architecture-overview.md` lines 476 to 504 match the built hooks, CI, setup, and migration behaviour. `docs/component-registry.md` and `docs/dependency-graph.md` carry the 0.38.0 update.
- Attribution and credentials: I found no credential in the files I read.
