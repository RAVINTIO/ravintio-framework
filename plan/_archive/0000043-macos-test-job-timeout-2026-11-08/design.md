# Design - 0000043-macos-test-job-timeout

## Feature
- Problem: the macOS test job runs the whole suite against a 15-minute cap and timed out in 3 of the last 4 PR #77 runs, so the maintainer can't merge PR #77.
- Adoption mode: standard-iterative (signal: `plan/_archive/` holds 42 feature folders, and `docs/about.md` exists)
- Feature ID: 0000043-macos-test-job-timeout
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As a framework maintainer, I see the macOS test suite finish well inside its cap, so that I can merge PR #77.
  - US-002: As a framework maintainer, I see each test job's elapsed time against its cap in the CI log, so that I can act before a job times out.
- Acceptance criteria confirmed: 4 (from `feature-brief.md`)
- Constraints:
  - CI runs on `pull_request` only (0000031 ADR 003).
  - `run-tests.sh` output without `--quiet` stays byte-identical (0000038 req-003).
  - The fix lands on `feat/0000041-pack-source-under-src`, so PR #77 picks it up.
- Integrations: GitHub Actions runs the suites through `src/ravintio-framework/tests/run-tests.sh`.

## Architecture Layer
- Latency target: not applicable (no service)
- Availability target: not applicable (no service)
- Scalability target: each macOS shard finishes in under 10 minutes, two-thirds of its 15-minute cap.
- Security: no auth. The job keeps `permissions: contents: read`. The elapsed-time step reads only the shell clock and matrix values.
- Data privacy: no regulated data
- Observability: each test job prints one elapsed-time line with its cap, even after a step timeout. A test step past two-thirds of its cap also prints a `::warning::` annotation.
- Cost boundary: macOS runner minutes stay about the same in total. The split adds one checkout per run.

## Engineering Layer
- Stack: unchanged. Bash suites under `run-tests.sh`, GitHub Actions CI. Build target: local.
- Components:
  - `ravintio-framework` (component-pack): owns the two CI layout suites and `tests/README.md` under `src/ravintio-framework/tests/`.
  - repository CI: `.github/workflows/ravintio.yml`, which isn't mirrored to consumers (0000031 ADR 002).
- Data ownership:
  - `ravintio-framework` owns every file under `src/ravintio-framework/`.
  - The release script owns the root `ravintio-framework/` copy. No agent writes it with **Write** or **Edit**.
  - The repository CI owns `.github/workflows/ravintio.yml`.
- Deployment: P7 runs the release script, which rebuilds the root copy from `src/`. The workflow change takes effect on the next PR #77 push.
- API versioning: not applicable
- Matrix layout:
  - Every entry moves to `include`, and each entry carries its own `cap`. This gives the cap one source.
  - `ubuntu-latest` stays one unsharded entry with `cap: 15`, and it has no `shard` or `shards` value.
  - `macos-latest` becomes 2 entries, shards 1 and 2, each with `shards: 2` and `cap: 15`. P4 raised it to 3 entries with `shards: 3`, under ADR-002's 10-minute rule (P4 deviation).
  - Each Windows entry gains `shards: 7` and `cap: 20`. The count and the cap don't change.
  - The test step's `timeout-minutes` reads `matrix.cap`. The job `timeout-minutes` is a fixed 25-minute backstop above every cap (P1 deviation: GitHub Actions expressions have no arithmetic).
  - `RAVINTIO_SHARD_COUNT` reads `matrix.shards`, in place of the fixed `7`. An entry with no `shards` still passes an empty value, so Ubuntu runs every suite.
  - The job name reads `shard {0} of {1}` from `matrix.shard` and `matrix.shards`.
- Elapsed time:
  - The test step's own `timeout-minutes` reads `matrix.cap`. A slow run then fails the step, and the job isn't cancelled.
  - A later step runs with `if: always()`. It prints `Elapsed: {m} min {s} s of a {cap} min cap` for the test step, so a timed-out run still shows its time.
  - Past two-thirds of the cap, that step also prints a `::warning::` line. Two-thirds of 15 is 10 minutes, which matches the margin NFR.
  - The job result still comes from the test step. `run-tests.sh` doesn't change.
- Suite updates:
  - `test-0000031-req-001-003-ci-jobs.sh` accepts the macOS shard entries.
  - `test-0000037-req-010-windows-git-bash-leg.sh` checks the per-entry shard count in place of `matrix.shard && 7`, and still checks 7 Windows shards.
  - A new suite, `test-0000043-req-001-macos-shards.sh`, checks the macOS shard entries and the shard count wiring.
  - A second new suite, `test-0000043-req-002-job-margin.sh`, checks the elapsed-time step (P1 decision).
- Version: last known `0.39.1`, and `v0.39.1` is already on `origin`. Suggested `0.39.2`, a patch bump, because the change fixes CI and adds no pack feature. The `ravintio-framework` manifest under `src/` carries the bump.

## Component Paths
- `src/ravintio-framework/`
- `ravintio-framework/`
- `./product.yml`
- `.github/workflows/ravintio.yml`

## Scope
- In:
  - the matrix layout above
  - the per-entry `cap`, the step timeout, the elapsed-time line, and the two-thirds warning
  - the two CI layout suite updates and two new 0000043 suites
  - `tests/README.md` rows, if the README describes the CI layout
  - the 0.39.2 version and the P7 release copy rebuild
- Out:
  - sharding Ubuntu, which takes 7 to 9 minutes
  - the Windows shard count and cap
  - making any suite faster
  - `ravintio-framework/hooks/ravintio.yml`, which has no `test-suite` job
- Deferred: nothing deferred.
- Release size: `three-story rule`. Two stories, so it fits.
- Backlog: pull in 0000430 and delete its folder in the design confirmation commit. Leave the other 254 entries untouched.

## Assumptions
- The macOS suite time splits roughly evenly across 2 shards by position - impact if wrong: one shard stays near the cap, and the run needs 3 shards.
- No ruleset requires a check by name - impact if wrong: the renamed macOS checks block the merge until the ruleset changes. The `main` ruleset was read at P0 and names none.
- A step `timeout-minutes` below the job backstop fails the step without cancelling the job, so an `if: always()` step still runs - impact if wrong: a timed-out run shows no elapsed line, and the maintainer reads the time from the job duration instead.
- A step's `timeout-minutes` accepts a `matrix` expression - impact if wrong: the workflow fails to parse, and every test job fails.

## Risks
- A macOS shard still runs near the cap because the slow suites land in one shard. Likelihood low, impact medium. The elapsed-time line shows it on the first run.
- The P7 credential scan holds back the new `release.yml` again, as in 0000041 and 0000042. Likelihood high, impact low. The `release-copy-integrity` job passes with its skip notice.
- The P9 CI check finds a failure after the archive, and `gate-write` blocks the fix (backlog 0000426). Likelihood medium, impact high. The run pushes after P4 and reads the PR #77 checks before P7 archives the design.

## Dependencies
- Upstream: PR #77 and the GitHub Actions runners
- Downstream: the maintainer's merge of PR #77

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - sharded-macos-test-job | ravintio-codegen-agent | workflow and suite edits through the TDD loop |
| REQ-002 - visible-job-margin | ravintio-codegen-agent | two workflow steps with their own suite through the TDD loop |

## Repo Instructions
Five files in `ravintio-overrides/instructions/`, read at P0.
- `custom-001-local-git-only.md`: fetch, pull, push, and `gh pr create` need no prompt. Work on a `feat/` branch. Committing to `main` and merging PRs stay human-only. Commit after every meaningful artifact write.
- `custom-002-prefer-subagent-decomposition.md`: split long or multi-unit work into parallel subagents, above the size floor.
- `custom-003-git-up-to-date-shorthand.md`: `GUTD` means check out `main`, pull, list untracked files, and report the last merged PR's checks.
- `custom-004-file-backlog-entries-immediately.md`: file out-of-scope problems as backlog entries at once, then commit and push them.
- `custom-005-p9-push-and-raise-pr.md`: at P9, push and raise the PR without asking. Never merge. PR #77 already exists, so P9 pushes the branch and the tag, and it updates PR #77 instead of raising a new one.

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 08 Nov 2026 @ 01:25 PM GMT
