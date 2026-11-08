# Security Report - 0000043-macos-test-job-timeout

Scope: `git diff 589ddf01..HEAD -- .github/ src/`. That covers the `test-suite` job in `.github/workflows/ravintio.yml`, two new suites, two edited suites, and the `component.yml` version bump.

Overall risk rating: **Low**. No Critical, High, or Medium findings. Two Low findings and three Informational notes follow.

## Findings

| ID | Severity | Location | Finding | Fix |
|---|---|---|---|---|
| S-001 | Low | `.github/workflows/ravintio.yml`, step "Report the test step time" | The digits-only guard accepts a value with a leading zero, such as `08`. Bash arithmetic reads it as octal and fails with "value too great for base". The step then exits 1 and fails the job, although the step is report-only. Only a tampered `GITHUB_ENV` or a future `cap` such as `08` reaches it. | Force base 10, for example `elapsed=$((now - 10#$start))` and `$((10#$cap * 40))`, or reject a leading `0` in the `case` guard. Add a suite case for `08`. |
| S-002 | Low | `.github/workflows/ravintio.yml`, step "Report the test step time" | The guard puts no limit on length. A digit string longer than 19 characters overflows 64-bit arithmetic and prints a wrong elapsed time. The step still exits 0 and runs no command. | Reject values longer than 10 digits in the `case` guard, or accept the wrong output as harmless. |
| S-003 | Info | `.github/workflows/ravintio.yml`, `test-suite` job | `run-tests.sh` runs PR code, and that code can append to `$GITHUB_ENV`. It can therefore change `RAVINTIO_TEST_START` or set variables such as `BASH_ENV` for the later step. This gains nothing, because the PR code already runs in the same job with the same `contents: read` token and no secrets. | None needed. Keep the job free of secrets and write scopes. |
| S-004 | Info | `src/ravintio-framework/tests/test-0000043-req-002-job-margin.sh`, fake `date` heredoc | The unquoted heredoc embeds `$REAL_DATE` inside double quotes. A `date` path that holds `"`, `$`, or a backtick would break the fake or run text. `command -v date` returns a system path such as `/bin/date`, so no attacker controls it. | Optional: pass the real path through an environment variable that the fake reads, instead of embedding it. |
| S-005 | Info | `src/ravintio-framework/tests/test-0000043-req-002-job-margin.sh`, `run_block_of` and `bash "$TMP_ROOT/elapsed.sh"` | The suite runs a `run:` block that it reads from the workflow file. The text comes from the same commit as the suite, so it crosses no trust boundary. The suite already runs repository code. The block runs with `GITHUB_ENV` pointed at the scratch folder and only `date` faked on `PATH`. | None needed. Reviewers should treat a change to that step as executable code in the local suite. |

## Threat Model (STRIDE)

| Threat | Category | Severity | Mitigation |
|---|---|---|---|
| Expression injection from matrix values into `run:` text | Tampering | Low | Mitigated. `matrix.cap` reaches the shell only through `env: CAP`, never through `${{ }}` inside `run:`. Matrix values are literals in the workflow file. |
| Shell injection through `CAP` or `RAVINTIO_TEST_START` | Elevation | Low | Mitigated. The `case` guards accept digits only before any arithmetic. The suite proves `CAP='15; echo hi'` prints `Elapsed: unknown` and runs nothing. See S-001 and S-002 for the gaps that remain. |
| PR code rewrites `GITHUB_ENV` for the report step (R-005) | Tampering | Low | Mitigated in effect. The guard rejects a non-numeric value. The step holds no extra privilege. See S-003. |
| Report step fails the job on a crafted value | DoS | Low | Not mitigated. See S-001. |
| Longer job backstop wastes runner minutes | DoS | Low | Mitigated. The step `timeout-minutes: ${{ matrix.cap }}` stops the test step at 15 or 20 minutes. The 25-minute job ceiling only bounds checkout and the report step. Two macOS shards add one macOS runner per PR, and macOS minutes cost more. |
| Secret exposure in logs or the warning annotation | Info Disclosure | Low | Mitigated. The job references no `secrets.`. The suites assert that. The annotation prints only computed integers. |
| Fake `date` or scratch folder hijacked | Tampering | Low | Mitigated. `mktemp -d` creates a private folder. The suite stops if `mktemp` fails and removes the folder on `EXIT` with `rm -rf --`. |

## Dependency Audit

The diff adds no dependency. The job keeps `actions/checkout@v4`, pinned to a major tag rather than a commit SHA. That is the existing posture across the workflow, so this feature adds no change.

## Secrets Management

The `test-suite` job references no secret. The `GITHUB_ENV` value is a Unix time from `date +%s`. No credential appears in the diff.

## Authentication & Authorisation Review

The workflow triggers on `pull_request` only. It never uses `pull_request_target`, and the suites assert both. The `test-suite` job keeps `permissions: contents: read`. A fork PR therefore gets a read-only token and no secrets.

Out of scope: the workflow has no top-level `permissions:` block. The `validate-branch` job sets no `permissions:` of its own, so it gets the repository default token scope on same-repository PRs. This feature didn't introduce that. It should go in a backlog entry with `permissions: {}` or `contents: read` at the top level.

## Input Validation Review

There is no API and no OpenAPI spec. The only inputs are `CAP` and `RAVINTIO_TEST_START` in the report step. Both pass a digits-only guard. S-001 and S-002 list its gaps.

## Network Policy

There is no change. The new steps make no network call.

## Infrastructure as Code Review

There is no IaC in the diff. The workflow review above covers the CI configuration.

## Risk Register cross-reference

| Risk | Status |
|---|---|
| R-005 (`GITHUB_ENV` value read by a later step) | Mitigated. The digits-only guard is in place and the suite tests it. A leading-zero value still fails the step (S-001). |

## Summary

Overall risk rating: Low

Top actions before production:
1. Force base-10 arithmetic in the report step, or reject a leading zero, and add a suite case (S-001).
2. Cap the digit length in the report step guard (S-002).
3. File a backlog entry for a top-level `permissions:` block in `.github/workflows/ravintio.yml`.
