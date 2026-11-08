---
title: "ADR 009: Tests and CI from src"
summary: "In the source repo, suites read the pack from src/ravintio-framework/ through one resolver, and the resolver fails a suite that reads the root copy. CI runs the src/ suites, and a new job checks the root copy against its release.yml hashes. The version equality checks run only on a released tree."
status: "accepted"
version: "0.1.0"
---
# ADR-009 - Tests and CI from src

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Component:** ravintio-framework
**Date:** 2026-11-07

## Context

ADR-002 moves the pack source to `src/ravintio-framework/`. The root `ravintio-framework/` stays as the last release, and this run keeps using it (US-001). The P1 survey in req-008 found these faults after the move:

- 38 suites climb out of the pack with `$FRAMEWORK/..` or `$SCRIPT_DIR/../..`. That climb now lands on `src/`, not the repo root.
- 12 suites name `ravintio-framework/component.yml`, which the root copy keeps only until P7.
- 17 suites scan the tree with `git ls-files` or `git grep`. They now see each pack file twice.
- CI runs `bash ravintio-framework/tests/run-tests.sh`, which tests the 0.38.0 release, not the change.

The main risk is R-001. A suite that still reads the root copy passes against the old release. That hides a broken change under `src/`. R-007 covers the six suites whose `REPO_ROOT` becomes `src/`.

Two more gaps follow from the move:

- The 0000039 req-010 version suite fails for the whole run from P3 to P7 (backlog 0000368). The codegen close-out bumps `component.yml` at P3, but P7 sets `product.yml` and `docs/about.md`.
- `em-dash-guard.mjs` scopes its check to the root prefixes only. Pack prose edits under `src/` then skip the guard (R-011).

## Decision

### One resolver for every suite

- Add `src/ravintio-framework/tests/helpers/pack-root.sh` (req-008). A suite sources it after `helpers/assert.sh`.
- The helper finds its own folder from `${BASH_SOURCE[0]}`. It sets `RAVINTIO_PACK_DIR`, `RAVINTIO_REPO_ROOT`, `RAVINTIO_PACK_REL`, and `RAVINTIO_SOURCE_REPO`. It exports nothing.
- It takes the source-repo signal from `scripts/project-kind.mjs` (ADR-007, req-005). It holds no second copy of that rule.
- If the signal holds and the helper sits in the root copy, it prints its `FAIL: pack-root:` line and exits 1. This is the control for R-001.
- In a consumer repo, the signal fails, so the helper sets the root copy values and never fails.
- Suites build their tree-scan pathspecs from `$RAVINTIO_PACK_REL`. In the source repo they add `:!ravintio-framework`, so a scan skips the release copy.
- A line that must keep a root path, such as `git show $BASE:ravintio-framework/...`, carries `# root-copy-ok: {reason}`.

### A static scan backs the run-time check

The run-time exit can't see a literal path in a suite that never sources the helper. So `test-0000041-req-008-tests-and-ci-from-src.sh` scans `tests/*.sh` and `tests/regression/*.sh`. It flags each line that matches one of four patterns and lacks the marker. Each flag names the file and line number.

### CI runs the source

- `.github/workflows/ravintio.yml` runs every pack command from `src/ravintio-framework/`. The test job runs `bash src/ravintio-framework/tests/run-tests.sh`.
- A new job, `release-copy-integrity`, runs `release-check.mjs --root . --files-only` (req-003, ADR-004). It fails when a root copy file differs from its `release.yml` hash, and it names each file.
- Until this run's P7 writes the first `release.yml`, the root copy is `v0.38.0` with its `component.yml`. The script then prints `skipped: no ravintio-framework/release.yml`. The job reports a `::notice` that names that reason and exits 0.
- The job is repo-only. The consumer copy `src/ravintio-framework/hooks/ravintio.yml` doesn't gain it.

### The version suite runs its equality checks on a released tree

- A released tree has no `plan/current/design.md` at the repo root (req-007, backlog 0000368).
- On an open run, the suite skips its three equality checks for `product.yml` and `docs/about.md`. It prints one `SKIP (open run): {check}. {reason}` line for each.
- Every other check runs on every tree. That covers the `component.yml` format, `product-version.mjs`, and the AC2 `1.0.0` scan.
- req-007 owns every change to that suite, including its move onto the resolver.

### The em dash guard covers the source

`em-dash-guard.mjs` gains the `src/ravintio-framework/` prefixes for `skills/`, `templates/`, and `standards/` (req-001, R-011). It keeps the root prefixes, because consumers edit their copy there. The build log records this as a P1 deviation.

### Build order

The P1 decisions fix these dependencies in the execution plan build order:

1. Step 1 lands req-001's `product.yml` edit in its own commit, so the source-repo signal holds from step 2 on.
2. Step 2 writes `project-kind.mjs` before the resolver, because the resolver runs it. Until step 6, the req-005 suite finds the pack from its own folder.
3. Step 3 adds the resolver and closes req-008 AC1.
4. Step 5 closes req-008 AC3, once `build-release.mjs` and `release-check.mjs` exist.
5. Step 7 closes req-008 AC2. The static-scan case stays red from step 3 to step 7, because it flags the version suite until req-007 moves it.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Rewrite each suite's paths by hand, with no resolver | No new helper file. Each suite stays self-contained. | The 37 suites on the P1 list each carry their own copy of the repo-root and pack-path logic. Nothing fails a suite that still reads the root copy, so R-001 stays open. | One resolver gives one rule and one place to fail. A-002 says one resolver can reach every suite. |
| Run the suites against a rebuilt root copy | Suites keep their current paths. The tests read the same tree consumers get. | The run would rebuild the root copy before P7, which this run uses for its hooks and skills (US-001, R-010). A broken change could then break the run that builds it. | It defeats the purpose of US-001. The release script runs only at P7 (ADR-003). |
| Drop the version equality suite | Removes the red suite from P3 to P7. | Loses the only check that `product.yml`, `docs/about.md`, and `component.yml` agree on a release. That was the 0000039 req-010 intent. | A skip on an open run keeps the check where it matters, on the released tree. |
| Fail the integrity job when `release.yml` is absent | Stricter from the first commit. | This run's PR stays red from P3 to P7, because the first `release.yml` arrives only at P7. | The skip notice names its reason, and the job runs in full on the PR from P7 on. |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Gains `tests/helpers/pack-root.sh` and the req-008 suite. The 37 suites on the P1 list and six regression copies change their paths. The version suite gains the released-tree rule. `em-dash-guard.mjs` gains three prefixes. `self-description-check.mjs` reads the pack folder list from `src/` when the source manifest exists. |
| setup-hook-integration | No direct change. Its code paths point into `src/ravintio-framework/` (ADR-002), so its suites run under the same resolver. |

## Consequences

**Positive:**
- A suite that reads the root copy in the source repo fails at once, which closes R-001 for every suite that sources the resolver.
- One resolver fixes the climb-out fault of R-007 in one place.
- CI checks the root copy against its hashes, so a hand edit to the release copy can't reach `main` unseen. That backs ADR-005, which bars **Write** and **Edit** on that copy.
- The version suite stops failing every run from P3 to P7, which closes backlog 0000368. It still fails a released tree whose versions disagree (req-007 AC2).

**Negative:**
- P3 edits 37 listed suites and six regression copies in one requirement, and the static scan may add more.
- The static-scan case stays red from build order step 3 to step 7. P3 must log that red case as expected rather than fix it early.
- The integrity job proves nothing on this run's PR until P7 writes `release.yml`. Before that, it only reports its skip.
- The resolver runs `node` once per suite to read the signal, which adds a little time to each suite.

**Risks:**
- This run's root copy is `v0.38.0` and holds no `pack-root.sh`. A suite run from the root copy during this run therefore reads the old release with no FAIL line. The resolver's guard starts only after the P7 rebuild. CI and P4 run from `src/`, which covers this gap for the run.
- A suite that never sources the resolver and uses a pattern outside the four scan patterns slips past both checks. A-002 covers this.
- A wrong `# root-copy-ok:` marker hides a real root-copy read. P6 review should check each marker's reason.
- The released-tree rule reads only `plan/current/design.md`. A repo that leaves that file in place after a release keeps skipping the equality checks.
- Until P7, the installed 0.38.0 `em-dash-guard.mjs` still skips `src/` prose (R-011). P6 checks pack prose for em dashes.

## Related ADRs

- ADR-002 - depends-on: the move to `src/` creates the two trees the resolver tells apart.
- ADR-003 - depends-on: `build-release.mjs` builds the scratch root copies the req-008 suite checks.
- ADR-004 - depends-on: the integrity job runs the `release.yml` reader `release-check.mjs --files-only`.
- ADR-005 - related-to: the integrity job enforces the rule that only the release script writes the root copy.
- ADR-007 - depends-on: the resolver takes the source-repo signal from `project-kind.mjs`.

## Supersedes

- None

## Superseded By

- None
