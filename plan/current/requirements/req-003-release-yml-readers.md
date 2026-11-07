---
title: "Requirement: req-003 - release-yml-readers"
summary: "Step 1a, the update policy, and the migrator read ravintio-framework/release.yml first, with a component.yml fallback for an older pack. A read-only script detects a new release and each changed pack file. It warns about a leftover manifest and knows the source repo's own build."
status: "draft"
version: "0.1.0"
---
# Requirement: req-003 - release-yml-readers

**Skill:** [spec-agent](../../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Source:** US-002, backlog 0000181
**Priority:** must-have

## User Story

As a consumer repo owner, I install a pack that has `release.yml` and no `component.yml`, so that my runs never count the pack as my source and still detect each pack update.

## Functional Requirements

All paths below use the post-move layout from req-001. Sources live under `src/ravintio-framework/`. A consumer, and this repo's sessions, run them from `ravintio-framework/`.

### Where the recorded value lives

- Today the policy compares the installed version with "the version last read from `docs/about.md`, or from the most recent archived feature's `design.md`/`about.md`". No file records a source commit. In a consumer, `docs/about.md` holds the consumer's own product version, not the framework version.
- A new file, `plan/framework-release.yml`, records the release this repo last trusted. It holds two lines:

  ```yaml
  version: "0.39.0"
  source-commit: "0123456789abcdef0123456789abcdef01234567"
  ```

- Step 1a writes it with **Write**, under the rules in `### Step 1a`. The commit cadence rule (orchestrator Hard Limit 7) commits it. No other agent writes it.
- With no `plan/framework-release.yml`, the repo is on its first upgrade. The comparison then uses the version only, against today's fallback: the `version` in `docs/about.md`. With no `docs/about.md`, no value exists, and any release counts as a release update.

### The check script

- A new read-only script, `src/ravintio-framework/scripts/release-check.mjs`, does the comparison. Step 1a runs it as `node ravintio-framework/scripts/release-check.mjs`. It writes no file, so the Write-or-Edit rule (boot Hard Limit 8) needs no new sanction.
- It accepts `--root <dir>`, with the working directory as the default. It also accepts `--files-only`, under `### Files-only mode`. Any other argument exits 2.
- It reads `ravintio-framework/release.yml` in req-002's format. It refuses a file that breaks that format, including a `format` other than `1`, with exit 2. It never falls back to `component.yml` when `release.yml` exists but can't be read.
- It refuses to read through a link. `ravintio-framework/`, `release.yml`, and `plan/framework-release.yml` must be regular files or folders, and a link exits 2. A link inside `ravintio-framework/` counts as a changed file, and the script never follows it.
- It hashes each file with req-002's rule: SHA-256 of the content after each CRLF pair reads as LF, in lowercase hex.

### The two signals

The script prints one line for each finding, and step 1a acts on them.

1. **Release update.** The script compares `release.yml` with the recorded value.
   - With a recorded value, a different `version` or `source-commit` is a release update.
   - On a first upgrade, only a different `version` is a release update.
   - It prints `release: version "{v}" source-commit "{sha}"` and `recorded: version "{v}" source-commit "{sha}"`, or `recorded: none, fallback docs/about.md version "{v}"`, or `recorded: none`.
   - It prints `update: release` for a release update, and `update: none` otherwise.
2. **Changed file.** The script compares each pack file with its `release.yml` hash, whatever the version says. It prints one line per file:
   - `changed: ravintio-framework/{path}`, when the hash differs or the entry is a link
   - `missing: ravintio-framework/{path}`, when `release.yml` lists a file that doesn't exist
   - `unlisted: ravintio-framework/{path}`, when a file exists that `release.yml` doesn't list
   - The unlisted check skips `release.yml`, `component.yml`, `.DS_Store`, `Thumbs.db`, and `desktop.ini`.

- When `release.yml` exists and the recorded value differs from it, or is absent, the script prints `record: version "{v}" source-commit "{sha}"`. That line is the exact content step 1a writes.

### Fallback for a pack before 0.39.0

- With no `ravintio-framework/release.yml`, the script reads `version` from `ravintio-framework/component.yml`. It prints `release: none, fallback component.yml version "{v}"`.
- It compares that version with the recorded version, as on a first upgrade. It prints `files: not checked, no release.yml` and no `record:` line.
- With neither file, or an unreadable `component.yml`, it exits 2.

### Leftover manifest

- When `ravintio-framework/component.yml` sits beside `release.yml`, the script prints `warn: ravintio-framework/component.yml sits beside release.yml`. The warning doesn't change the exit code.
- Step 1a reports the warning at every session start while the file remains, even after req-006's migration records `skipped`.

### The source repo's own build

- In this repo, the release script (req-002) rebuilds the root copy at P7. The next session would see a new `version` and `source-commit`. Step 1a must not ask the maintainer to vouch for a build their own repo made.
- When `projectKind(root)` (req-005) returns `framework source`, the script also checks for an own build. An own build needs both of these:
  - No `changed:`, `missing:`, or `unlisted:` line.
  - Each `release.yml` entry matches the hash of the same path under `src/ravintio-framework/`. `git ls-files -- src/ravintio-framework` lists no file that `release.yml` lacks, except `component.yml`.
- An own build prints `update: own-build` in place of `update: release`. The proof is content, not commit ancestry, so it holds after a squash merge rewrites `source-commit`.
- Mid-run, `src/` moves ahead of the root copy. The recorded value already matches the root copy by then, so the script prints `update: none`.
- When the source repo's root copy isn't an own build, the normal rules apply, and step 1a asks for confirmation.

### Exit codes

- `0`: nothing to confirm. That covers `update: none` or `update: own-build`, with no file line.
- `1`: a candidate update. That covers `update: release`, or any `changed:`, `missing:`, or `unlisted:` line.
- `2`: the check couldn't run. Stderr names the reason.

### Files-only mode

- With `--files-only`, the script runs only the changed-file signal. It ignores the recorded value and prints no `record:` line.
- With no `release.yml`, it prints `skipped: no ravintio-framework/release.yml` and exits 0. Otherwise it exits 0 when every file matches, and 1 on any file line.
- req-008's CI integrity check may run this mode. If req-008 builds its own check, it must apply the same hash rule and the same skip list.

### Step 1a

Rewrite step 1a in `src/ravintio-framework/skills/ravintio-orchestrator/SKILL.md`. It keeps the `1a. **Detect a` opening and its link to `framework-update-policy.md`, which `test-0000027-req-003-005-007-008-governance-docs.sh` matches.

1. Run `node ravintio-framework/scripts/release-check.mjs`.
2. Report every `warn:` line, whatever the exit code.
3. On exit 0:
   - With `update: own-build`, report one line: the root copy is this repo's own release build, with its version and source commit.
   - If the output holds a `record:` line, write `plan/framework-release.yml` with that content.
   - Record the outcome in the build log, and go on.
4. On exit 1, surface the update as its own decision, under the confirmation gate that exists today.
   - Name the release update with its version and source commit.
   - Name each `changed:`, `missing:`, and `unlisted:` file, even when the version is unchanged.
   - On confirmation with provenance, write `plan/framework-release.yml` from the `record:` line, if there is one. On rejection, write nothing, and treat the pack as untrusted.
   - A changed file stays flagged at each session start until it matches its hash or a new release lists it.
5. On exit 2, report that detection couldn't run, with the reason. Step 1b then loads no source copy.
6. Step 1a commits `plan/framework-release.yml` only on a `feat/` branch. On any other branch, it leaves the file uncommitted and says so, and the next feature branch commits it. Only the human on the loop commits to `main`.
6. If `ravintio-framework/scripts/release-check.mjs` doesn't exist, the pack predates 0.39.0. Compare the `component.yml` version with `docs/about.md` by hand, as the policy states.

- Step 1b's list of states names `release-check.mjs` exit 2 as a detection that couldn't run, in place of "an unreadable `component.yml`". Step 1b's other sentences stay exactly as they are, because `test-0000036-req-002-skill-drift-check.sh` matches them.
- Under the new step 1a, a changed file always counts as an update. So step 1b never loads an unconfirmed source copy after a push that skipped the version bump. That closes backlog 0000181.

### The update policy

Rewrite `## Detection signal` in `src/ravintio-framework/standards/framework-update-policy.md` to state these rules:

- the two signals and the first-upgrade rule
- the recorded value in `plan/framework-release.yml`
- the `component.yml` fallback for a pack before 0.39.0
- the leftover manifest warning
- the hash rule
- the script that runs the check

The policy drops the paragraph that names a file-level check the step 1a summary lacked. `## Human confirmation gate` gains one exception. In the framework source repo, an own build needs no confirmation, and step 1a records it. Every other path still ends in explicit confirmation or rejection. The policy keeps the word "provenance", which the 0000027 suite matches.

### The migrator

In `src/ravintio-framework/skills/ravintio-migrator/SKILL.md`:

- The `framework-version` row in `## Run records` and the Step 5 record template read the `version` in `ravintio-framework/release.yml`. They fall back to `ravintio-framework/component.yml` when `release.yml` is absent. If `release.yml` exists but breaks the format, the migrator stops, reports the file, and records nothing (ADR-004).
- `### Order and old paths` gains one rule. When a migration's instructions read the framework version from `ravintio-framework/component.yml`, read it through the same rule. Released migrations stay byte-identical, as the old-path mapping already works. This covers `migrate-0.38.0-retire-fast-path-and-change-pipeline.md` step 1 and the older re-run-setup migrations, which name `planifest-framework/component.yml`.

### Suites that change

- New suite: `src/ravintio-framework/tests/test-0000041-req-003-release-yml-readers.sh`. It builds scratch repos in a `mktemp -d` folder and reads the pack through req-008's resolver. It builds each `release.yml` with req-002's script, or writes one in req-002's format.
- These suites read step 1a, step 1b, the policy, or the migrator and must stay green. Recheck them at P3:
  - `test-0000027-req-003-005-007-008-governance-docs.sh`
  - `test-0000036-req-002-skill-drift-check.sh`
  - `test-0000035-req-007-migration-run-state.sh`
  - `test-0000035-req-010-migration-records-for-this-repo.sh`
  - `test-0000036-req-001-rerun-setup-migration.sh`

- Split step: keep, at three criteria. The one concern is how a repo learns which pack it runs and whether that pack changed. Step 1a, the policy, and the migrator read one source, and none of them ships alone.

## Acceptance Criteria

- [ ] In scratch repos, `release-check.mjs` behaves as follows. Verified by: integration
  - A consumer with a recorded value and a new `source-commit` at the same version prints `update: release` and a `record:` line, and exits 1.
  - A first upgrade with no record compares the version only. A version that differs from `docs/about.md` exits 1, and an equal version with matching files exits 0 and prints a `record:` line.
  - At an unchanged version, the test edits one file, deletes one, and adds one. The script prints one `changed:`, `missing:`, and `unlisted:` line each, and exits 1.
  - A CRLF copy of a listed file, a `.DS_Store`, and `component.yml` print no file line.
  - A leftover `component.yml` beside `release.yml` prints the `warn:` line at exit 0.
  - A pack with no `release.yml` reads the `component.yml` version, prints `files: not checked, no release.yml`, and prints no `record:` line.
  - A malformed `release.yml`, a `format: 2`, and a linked `release.yml` exit 2.
  - `--files-only` exits 0 on a matching copy, 1 on a changed file, and 0 with the `skipped:` line when `release.yml` is absent.
- [ ] In a scratch source repo, the own-build rule behaves as follows. Verified by: integration
  - req-002's script builds the root copy from the current `src/ravintio-framework/`. The check prints `update: own-build` and exits 0. It does the same after a squash-style rewrite removes `source-commit` from the history.
  - After one more commit changes a source file, a check with the recorded value prints `update: none`.
  - A root copy whose `release.yml` hashes don't match `src/` prints `update: release` and exits 1.
- [ ] The skill and policy texts state the rules as follows. Verified by: integration
  - Step 1a runs `release-check.mjs` and states the handling for exits 0, 1, and 2. It names the `record:` write to `plan/framework-release.yml` and the own-build line. It names each flagged file, and the warning at every session start.
  - Step 1b names `release-check.mjs` exit 2 as a detection that couldn't run.
  - The policy states both signals, the first-upgrade rule, the recorded file, and the fallback. It also states the hash rule and the own-build exception.
  - The migrator reads `release.yml` first for `framework-version` and for a version a migration reads. It falls back to `component.yml`.
  - The migrator states that a `release.yml` which breaks the format stops the run, names the file, and records nothing.

## Dependencies

- req-002 (release-script) defines the `release.yml` format and the hash rule that the script reads.
- req-005 (applies-to-header) provides `projectKind(root)` in `scripts/project-kind.mjs`, which the own-build check imports. req-005 owns the migrator `SKILL.md`. This requirement's migrator edits land after the req-005 Step 1b rule is green (execution plan, build order step 6). Its script, orchestrator, and update policy edits land earlier, at step 5.
- req-006 (consumer-migration) offers to remove the leftover manifest that the `warn:` line names, and names this warning in its `skipped` record.
- req-008 (tests-and-ci-from-src) provides the resolver the new suite uses, and may run `--files-only` for its CI check.
- Backlog 0000181 closes with this requirement.
- Backlog 0000383 covers step 1, which runs migrations before step 1a confirms the pack.
