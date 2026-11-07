---
title: "Requirement: req-008 - tests-and-ci-from-src"
summary: "Suites and CI read the pack from src/ravintio-framework/ in the source repo through one resolver, and a CI check fails when the root release copy differs from its release.yml hashes."
status: "draft"
version: "0.1.0"
---
# Requirement: req-008 - tests-and-ci-from-src

**Skill:** [spec-agent](../../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Source:** US-001
**Priority:** must-have

## User Story

As a framework maintainer, I change the pack under `src/ravintio-framework/` while this repo runs on the last release at the root, so that a broken change can't break the run that builds it.

This requirement serves US-001 through the suites and CI. They test the change under `src/ravintio-framework/`, not the release at the root. CI also checks the root copy against its `release.yml`, so a broken change can't pass against the old release.

## Functional Requirements

### How suites find the pack today (P1 survey)

- `tests/` holds 139 entries. 39 sit in `tests/regression/`, which holds 37 suites plus the manifest and `test-gate-write-windows.mjs`.
- Most suites find the pack from their own folder: `FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"`, or `$SCRIPT_DIR/../..` in `tests/regression/`. After the req-001 pass, those suites read `src/ravintio-framework/` with no change.
- 38 suites find the repo root by climbing out of the pack: `$FRAMEWORK/..`, `$FW/..`, or `$SCRIPT_DIR/../..` in `tests/`. After the pass, that climb lands on `src/`, not the repo root, so those suites break or read the wrong tree.
- 12 suites name `ravintio-framework/component.yml`, three of them in `tests/regression/`. Discovery counted 13. The P1 `git grep` found 12, and the total of 20 live files holds with 12.
- 17 suites scan the whole tree with `git ls-files` or `git grep`. After the pass, those scans see each pack file twice, once under `src/ravintio-framework/` and once under the root copy.

### The resolver

- Add `src/ravintio-framework/tests/helpers/pack-root.sh`. A suite sources it after `helpers/assert.sh`: `source "$SCRIPT_DIR/helpers/pack-root.sh"` in `tests/`, or `source "$SCRIPT_DIR/../helpers/pack-root.sh"` in `tests/regression/`.
- The helper finds its own folder from `${BASH_SOURCE[0]}`, so the caller's folder doesn't matter. It uses `cd ... && pwd`, as the suites do today. It sets four shell variables:

| Variable | Value |
|----------|-------|
| `RAVINTIO_PACK_DIR` | the absolute path of the pack that holds the helper, `helpers/../..` |
| `RAVINTIO_REPO_ROOT` | the parent of `src/` when the pack folder sits in a folder named `src`, otherwise the pack's parent |
| `RAVINTIO_PACK_REL` | `src/ravintio-framework` or `ravintio-framework`, the pack path relative to `RAVINTIO_REPO_ROOT` |
| `RAVINTIO_SOURCE_REPO` | `yes` when the source-repo signal holds at `RAVINTIO_REPO_ROOT`, otherwise `no` |

- The source-repo signal is the design's rule: `product.yml` lists the component `ravintio-framework` at `src/ravintio-framework/component.yml`, and that file exists. req-005's `scripts/project-kind.mjs` owns that rule. The helper runs `node "$RAVINTIO_PACK_DIR/scripts/project-kind.mjs" --root "$RAVINTIO_REPO_ROOT"`. It sets `yes` only when the script prints `framework source`.
- If `RAVINTIO_SOURCE_REPO` is `yes` and `RAVINTIO_PACK_REL` is `ravintio-framework`, the helper prints `FAIL: pack-root: this suite runs from the root release copy. Run it from src/ravintio-framework/tests/.` It then exits 1. This is the design's risk control: a suite that reads the root copy in the source repo fails.
- In a consumer repo, the signal doesn't hold, so the helper sets the root copy values and never fails.
- The helper exports nothing and changes no environment variable.

### Suites that change

- Every suite that climbs out of the pack, or names a repo-root pack path, sources the helper. It uses `$RAVINTIO_REPO_ROOT` for the repo root and `$RAVINTIO_PACK_DIR` for the pack.
- A suite that scans the tree with `git ls-files` or `git grep` builds its pack pathspecs and path regexes from `$RAVINTIO_PACK_REL`. In the source repo, it also adds `:!ravintio-framework` so the scan skips the release copy. The integrity check below covers that copy.
- The guards change their allowlists the same way:
  - `test-0000039-req-007-brand-guard.sh` and `test-0000040-req-006-residue-guard.sh` anchor each pack path regex on `^src/ravintio-framework/` in the source repo.
  - The residue guard's history-line rule names `src/ravintio-framework/component.yml`.
  - The brand guard's `HISTORY_MIGRATIONS_DIR` becomes `$RAVINTIO_PACK_REL/migrations/`.
- A suite that reads a path from an old commit, such as `git show $BASE:ravintio-framework/...`, keeps that path, because history stores it there. The line carries `# root-copy-ok: {reason}`.
- Suites that assert the CI command text change with the workflow: `test-0000031-req-001-003-ci-jobs.sh`, `test-0000037-req-010-windows-git-bash-leg.sh`, `test-0000037-req-011-windows-powershell-coverage.sh`, and `test-0000039-req-003-environment-variables.sh`.
- The P1 list of suites to change in `src/ravintio-framework/tests/`. The static scan below is the final word, and P3 adds any suite it flags:
  - `test-0000005-framework-governance.sh`, `test-0000017-req-003-phase-wave-sweep.sh`, `test-0000019-req-005-self-description-check.sh`, `test-0000027-req-003-005-007-008-governance-docs.sh`
  - `test-0000028-req-004-install-refresh-registration.sh`, `test-0000029-req-001-003-boot-file-regeneration.sh`
  - `test-0000030-req-001-002-removed-files-and-residue.sh`, `test-0000030-req-003-telemetry-pipeline-text-removal.sh`, `test-0000030-req-005-refresh-setup-migration-and-self-hosting.sh`
  - `test-0000031-req-001-003-ci-jobs.sh`, `test-0000033-req-003-gates-as-loops.sh`
  - `test-0000035-req-002-product-yml-in-p7.sh`, `test-0000035-req-007-migration-run-state.sh`, `test-0000035-req-008-sanctioned-scripts.sh`, `test-0000035-req-010-migration-records-for-this-repo.sh`
  - `test-0000036-req-001-rerun-setup-migration.sh`, `test-0000036-req-005-hard-limits-cited-by-name.sh`
  - `test-0000037-req-002-gutd-ci-check.sh`, `test-0000037-req-008-migration-branch-diff.sh`, `test-0000037-req-010-windows-git-bash-leg.sh`, `test-0000037-req-011-windows-powershell-coverage.sh`
  - `test-0000038-req-006-decomposition-size-floor.sh`
  - `test-0000039-req-001`, and `req-003` to `req-009`. The P1 survey found no change needed in `req-002`.
  - `test-0000040-req-001` to `req-007`, all seven
- The regression copies that change, each with the same Edit as its twin in `tests/`:
  - `regression/test-0000005-framework-governance.sh`
  - `regression/test-0000033-req-003-gates-as-loops.sh`
  - `regression/test-0000035-req-002-product-yml-in-p7.sh`
  - `regression/test-0000035-req-008-sanctioned-scripts.sh`
  - `regression/test-0000039-req-007-brand-guard.sh`
  - `regression/test-0000040-req-006-residue-guard.sh`
- Regression pack rule: P3 edits a regression copy with **Edit**, in the same change as its twin, as 0000040 did. `promote-to-regression.sh` only adds a suite, and no rule bars an Edit to a copy. `regression-manifest.json` stays unchanged, because its `filePath` values are relative to the pack.
- req-007 owns `test-0000039-req-010-version-bump.sh`, so this requirement leaves it alone.
- `tests/README.md` and the `run-tests.sh` usage comment name `src/ravintio-framework/tests/` for runs in the source repo.

### Static scan

- Add `src/ravintio-framework/tests/test-0000041-req-008-tests-and-ci-from-src.sh`. It scans `tests/*.sh` and `tests/regression/*.sh` line by line. It flags each line that matches one of these and has no `# root-copy-ok: {reason}` marker with a non-empty reason:
  1. a climb out of the pack: `(FRAMEWORK|FW|FW_DIR|FRAMEWORK_DIR|FRAMEWORK_SRC|RAVINTIO_PACK_DIR)\}?/\.\.`
  2. `SCRIPT_DIR/\.\./\.\.` in `tests/`, or `SCRIPT_DIR/\.\./\.\./\.\.` in `tests/regression/`
  3. a repo-root read of the root copy: `(ROOT|REPO|REPO_ROOT|PROJECT_ROOT|RAVINTIO_REPO_ROOT)\}?/ravintio-framework`
  4. a `git` command line with a literal pathspec: `git .*(['"]|:!|:\(exclude\))ravintio-framework/`
- Each flag prints the file and line number. Planted lines in scratch copies prove each pattern flags, and a marked line passes.
- The new suite builds its planted lines in parts, as the brand guard builds the old brand words, so its own source holds no match.
- A fixture that builds `$FX/ravintio-framework/` doesn't match pattern 3, because `FX` isn't in the list. A fixture variable that is in the list carries the marker.
- Every regex is POSIX extended, as Bash 3.2 `[[ =~ ]]` and `grep -E` read it. Read lines with `done <<< "$(...)"`, never `done < <(...)`.

### CI

- `.github/workflows/ravintio.yml` runs every pack path from `src/ravintio-framework/`:
  - `self-description-check`: `node src/ravintio-framework/scripts/self-description-check.mjs .`
  - `test-suite`: `bash src/ravintio-framework/tests/run-tests.sh`
  - `setup-powershell` and `setup-powershell-51`: `./src/ravintio-framework/tests/test_setup.ps1`
  - `setup-powershell-51`: the helper parse path `src\ravintio-framework\migrations\migrate-0.37.0-ravintio-rename.ps1`, and both `bash src/ravintio-framework/tests/...` suite runs
- `validate-branch` keeps its logic. It reads the source folders from `product.yml`, so it picks up `src/ravintio-framework/` with no change.
- The job comments that name the consumer copy `ravintio-framework/hooks/ravintio.yml` stay. That copy is the one setup ships, and it stays unchanged.
- `self-description-check.mjs` check 2 reads the pack folder list from `src/ravintio-framework/` when `src/ravintio-framework/component.yml` exists, otherwise from `ravintio-framework/`. Its README table links keep `ravintio-framework/`.

### Root copy integrity check

- The check reuses req-003's read-only `src/ravintio-framework/scripts/release-check.mjs` in its `--files-only` mode. req-003 owns the hash rule, the skip list, and the `changed:`, `missing:`, and `unlisted:` lines. This requirement adds no second hash reader.
- A new CI job, `release-copy-integrity`, runs on `ubuntu-latest` with `permissions: contents: read`. Its one step runs `node src/ravintio-framework/scripts/release-check.mjs --root . --files-only`.
  - On exit 1, the step fails, and the script's lines name each file.
  - On exit 2, the step fails with the script's reason.
  - When the script prints `skipped: no ravintio-framework/release.yml`, the step prints `::notice title=Release copy integrity::Skipped. The root copy has no release.yml, so it is a release from before 0.39.0.` It then exits 0.
- Like the test jobs, the job is repo-only and isn't mirrored into the consumer copy `src/ravintio-framework/hooks/ravintio.yml`. A job comment says so.
- Until this run's P7 writes the first `release.yml`, the job reports the skip. From P7 on, it runs in full on the PR.
- The new suite reads the step's `run:` block from `ravintio.yml` and runs it with Bash in scratch source repos. It builds each root copy with req-002's `build-release.mjs`, so a change to either script's contract fails this suite too.

- Split step: keep. The integrity check guards the same risk as the resolver: CI passing against a root copy that doesn't match what the run built.

## Acceptance Criteria
- [ ] Sourced from `src/ravintio-framework/tests/` in a scratch source repo, `pack-root.sh` sets `RAVINTIO_PACK_REL` to `src/ravintio-framework`, `RAVINTIO_REPO_ROOT` to the repo, and `RAVINTIO_SOURCE_REPO` to `yes`. Sourced from the root copy in that repo, it prints its FAIL line and exits 1. In a consumer layout, it sets `ravintio-framework` and `no` and doesn't fail. Verified by: unit
- [ ] The static scan flags no line in `tests/` or `tests/regression/`, and it flags each planted pattern with its file and line number. `ravintio.yml` runs every pack command from `src/ravintio-framework/` and holds the `release-copy-integrity` job. `bash src/ravintio-framework/tests/run-tests.sh` exits 0 on this repo. Verified by: integration
  - Verified by: integration - the new suite runs the scan and the workflow checks. The P4 full run gives the `run-tests.sh` exit.
- [ ] In a scratch source repo built with `build-release.mjs`, the `release-copy-integrity` step exits 0 on an untouched copy. It exits non-zero and names the file for a changed byte, a deleted file, and an added file. With `release.yml` removed, it prints its skip notice and exits 0. On this repo before P7, it prints the skip notice. Verified by: integration

## Dependencies
- req-001 (move-pack-to-src) runs the pass that puts the suites under `src/ravintio-framework/tests/`.
- req-002 (release-script) defines `release.yml` and provides `build-release.mjs`. The new suite runs that script to build each scratch root copy.
- req-003 (release-yml-readers) provides `release-check.mjs --files-only`, which the CI job runs.
- req-005 (applies-to-header) provides `scripts/project-kind.mjs`, which the resolver runs for the source-repo signal.
- req-007 (released-tree-version-suite) owns the version suite and sources this resolver.
- Every new 0000041 suite sources this resolver and must pass the static scan.
