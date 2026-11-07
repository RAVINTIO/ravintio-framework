---
title: "Requirement: req-002 - release-script"
summary: "A sanctioned script rebuilds the root ravintio-framework/ release copy from src/ravintio-framework/ without component.yml. It writes release.yml with a hash for each file, and swaps the copy in only when the build is whole. A new ship step runs it at P7."
status: "draft"
version: "0.1.0"
---
# Requirement: req-002 - release-script

**Skill:** [spec-agent](../../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Source:** US-002
**Priority:** must-have

## User Story

As a consumer repo owner, I install a pack that has `release.yml` and no `component.yml`, so that my runs never count the pack as my source and still detect each pack update.

## Functional Requirements

All paths below use the post-move layout from req-001. The script lives at `src/ravintio-framework/scripts/build-release.mjs`. Each release then carries it at `ravintio-framework/scripts/build-release.mjs`.

### What the script builds

- The script copies each file under `src/ravintio-framework/` into the root `ravintio-framework/`, except `src/ravintio-framework/component.yml`.
- The source set is the list that `git ls-files -z -- src/ravintio-framework` prints. Untracked and ignored files, such as `.DS_Store`, never reach the copy.
- The copy keeps each file's bytes and its executable bit. The pack holds 33 files with mode `100755` today.
- The script rebuilds the whole copy on every run. A root file that `src/` no longer holds is gone after the build. A rerun on the same commit and the same day gives a byte-identical root copy.
- The script then writes `ravintio-framework/release.yml` in the format under `### The release.yml format`.

### Inputs and refusals

- The script takes no arguments. Any argument exits 2 and names the argument without echoing its value. The root is the working directory, and the script clears `CLAUDE_PROJECT_DIR` before it resolves the root, as `set-product-release.mjs` does.
- The script runs only in the framework source repo. It decides that through `projectKind(root)` from req-005's `scripts/project-kind.mjs`. That function returns `framework source` only when `product.yml` lists `ravintio-framework` at `src/ravintio-framework/component.yml` and that file exists. Any other kind exits 2 and writes nothing.
- It reads `version` from `src/ravintio-framework/component.yml`. A value that isn't `MAJOR.MINOR.PATCH` exits 2 and writes nothing.
- It reads `source-commit` from `git rev-parse HEAD`.
- It refuses to build when `git status --porcelain -- src/ravintio-framework` prints anything. The release then always matches the commit it names. It exits 2, names the first uncommitted path, and writes nothing.
- It refuses a source entry that isn't a regular file, such as a link (mode `120000`) or a submodule (mode `160000`). It also refuses a path segment outside `[A-Za-z0-9._-]+`, or one that is `.` or `..`. Each refusal exits 2, names the path, and writes nothing. Every tracked pack path matches that pattern today.

### Write boundary

- The script writes and deletes only in three folders at the project root:
  - `ravintio-framework/`, the root copy
  - `.ravintio-framework-build/`, where the new copy is built
  - `.ravintio-framework-previous/`, where the old copy waits during the swap
- Before any change, it checks each of the three paths and `src/ravintio-framework/` itself. Each one must be absent or a real folder, never a link, and each must resolve inside the real root. Any other state exits 2 and writes nothing.
- It removes a folder with a recursive delete that never follows a link. A link inside the old copy goes as a link, and its target stays unchanged.
- No write or delete lands outside the three folders, whatever a link inside them points at.
- `.gitignore` lists `.ravintio-framework-build/` and `.ravintio-framework-previous/`, so an interrupted build never reaches a commit (P2 decision, ADR-003).

### Build and swap

1. Recover a leftover state first.
   - If `.ravintio-framework-build/` exists, delete it. It holds a partial build from an interrupted run.
   - If `.ravintio-framework-previous/` exists and `ravintio-framework/` doesn't, rename the previous folder back to `ravintio-framework/`. Print `restored: ravintio-framework/ from an interrupted build`.
   - If both exist, the earlier swap finished. Delete `.ravintio-framework-previous/`.
2. Build the full new copy and its `release.yml` in `.ravintio-framework-build/`.
3. Rename `ravintio-framework/` to `.ravintio-framework-previous/`, if it exists.
4. Rename `.ravintio-framework-build/` to `ravintio-framework/`.
5. Delete `.ravintio-framework-previous/`.

Until step 3, the old copy stays whole at `ravintio-framework/`. Between steps 3 and 4, it stays whole at `.ravintio-framework-previous/`, and step 1 of the next run restores it. A failure in step 2 deletes the build folder and leaves the old copy byte-identical.

### Output

- The script compares the new copy with the old one. It prints one line for each file that differs, with the path in its root-copy form:
  - `added: ravintio-framework/{path}`
  - `changed: ravintio-framework/{path}`, when the bytes or the executable bit differ
  - `removed: ravintio-framework/{path}`
- The lines cover `release.yml` too. This run's first build prints `removed: ravintio-framework/component.yml`.
- The last line is the summary: `summary: version {version}, source-commit {sha}, added {n}, changed {n}, removed {n}, unchanged {n}`.
- Each printed path has its control characters replaced, as `archive-current.mjs` does.
- Exit codes:
  - `0`: the new copy is in place.
  - `2`: a refusal from `### Inputs and refusals` or `### Write boundary`. The script wrote nothing, and stderr names the reason.
  - Any other non-zero code: a file-system or git failure. The old copy stays whole, and stderr names the operation.

### The release.yml format

The script writes this file, and readers rely on it (req-003, req-006, req-008). It is YAML in a fixed line shape, so a Bash reader can parse it with `sed`.

```yaml
# Written by scripts/build-release.mjs. Do not edit.
format: 1
version: "0.39.0"
source-commit: "0123456789abcdef0123456789abcdef01234567"
built: "2026-11-07"
files:
  "getting-started.md": "{64 lowercase hex characters}"
  "hooks/commit-msg": "{64 lowercase hex characters}"
```

- The keys come in this order: `format`, `version`, `source-commit`, `built`, `files`. Each scalar is double-quoted, except `format`.
- `format` is the whole number `1`. A reader refuses any other value.
- `version` is the `version` in `src/ravintio-framework/component.yml`, as `MAJOR.MINOR.PATCH`.
- `source-commit` is the full 40-character lowercase hex from `git rev-parse HEAD`.
- `built` is the build date in UTC, as `YYYY-MM-DD`. A date with no time keeps a same-day rerun byte-identical.
- `files` holds one line per file in the root copy, indented two spaces: `  "{path}": "{sha256}"`.
  - `{path}` is relative to `ravintio-framework/`, with `/` separators and no leading `./`. Each segment matches `[A-Za-z0-9._-]+`.
  - The lines sort in ascending byte order of `{path}`.
  - `{sha256}` is the SHA-256 of the file content after each CRLF pair reads as LF, in lowercase hex. A checkout with `core.autocrlf` then never reads as a changed file. The pack holds no binary file today.
- `release.yml` doesn't list itself, because a file can't hold its own hash. `component.yml` never appears either. Every other root-copy file appears exactly once.
- The file ends with one LF, and each line ends with LF.

### Sanction and ship step

- The Write-or-Edit rule (boot Hard Limit 8) names `ravintio-framework/scripts/build-release.mjs` as a sanctioned script, with no arguments. Add it to the one `Sanctioned scripts:` sentence in `src/ravintio-framework/templates/standard-boot.md` and `src/ravintio-framework/templates/cursor-boot.md`. Both templates keep the same sentence, which then names eight scripts.
- This repo's `CLAUDE.md` gets no edit. Setup writes it, and `.gitignore` line 10 excludes it. An agent never edits its own instruction file to sanction a script. After P7 rebuilds the root copy, a setup refresh writes the new sentence into `CLAUDE.md`. The final report recommends that refresh to the human on the loop.
- `src/ravintio-framework/skills/ravintio-ship-agent/SKILL.md` gains `### Step 5c: Build the release copy`, between Step 5b and Step 6:
  1. Run `node ravintio-framework/scripts/project-kind.mjs`. If it prints anything other than `framework source`, skip this step and log `P7: Step 5c skipped: not the framework source`.
  2. Run `node ravintio-framework/scripts/build-release.mjs`. The step runs the root copy, the last release, so a broken change under `src/` can't break the build that ships it (US-001).
  3. On exit 0, log the `summary:` line in the P7 build-log block.
  4. On exit 2, stop and report the reason. Never copy the pack by hand, and never write the root copy through **Write** or **Edit**.
  5. On any other exit, fix the cause stderr names and rerun. A rerun recovers a leftover state on its own.
- Step 7 stages the root copy in the source repo. Add one line after the `git add` line: `if [ "$(node ravintio-framework/scripts/project-kind.mjs)" = "framework source" ]; then git add -A -- ravintio-framework/; fi`. It reuses the Step 5c signal, so `project-kind.mjs` stays its one owner (ADR-007, P2 critic finding 3). The existing `git add plan/current/ plan/_archive/ plan/changelog/ docs/about.md` line stays exactly as it is, because `test-0000032-req-001-marker-clear-before-tag.sh` and its regression copy match it.
- The ship skill's `## Prefix` line names Step 5c beside Step 5b.

### This run's P7

- This run's ship agent is the 0.38.0 root copy, which has no Step 5c and doesn't stage the root copy. This run's P7 therefore runs `node src/ravintio-framework/scripts/build-release.mjs` after Step 5b, and stages `ravintio-framework/` in the Step 7 commit.
- The ship agent records both in the P7 block of the build log. The line reads `Decision (P7): run build-release.mjs from src/ and stage the root copy / reason: the 0.38.0 ship agent lacks Step 5c`.
- This one run from `src/` is a recorded exception to the sanctioned path in Hard Limit 8, like the move pass in req-001.

### Suites that change

- New suite: `src/ravintio-framework/tests/test-0000041-req-002-release-script.sh`. It builds scratch source repos in a `mktemp -d` folder and reads the pack through req-008's resolver. Link cases skip under Git Bash on Windows, as `test-0000035-req-008-sanctioned-scripts.sh` does.
- `src/ravintio-framework/tests/test-0000035-req-008-sanctioned-scripts.sh` and its copy in `tests/regression/`: add `ravintio-framework/scripts/build-release.mjs` to `EXPECTED`, and change "seven" to "eight" in the assertion labels and the header comment.
- `src/ravintio-framework/tests/test-0000039-req-008-emitted-names.sh`: add `scripts/build-release.mjs` to the sanctioned-script loop.
- These suites read the ship skill and must stay green. Recheck them at P3: `test-0000035-req-002-product-yml-in-p7.sh` and `test-0000032-req-001-marker-clear-before-tag.sh`, with their regression copies.
- `docs/architecture-overview.md` says Hard Limit 8 names seven scripts. P6 docs-agent updates it to eight.

- Split step: keep, at four criteria. The one concern is a release copy that a consumer can install and trust. The format, the safe swap, and the ship step that runs it can't ship apart. The fourth criterion checks this run's recorded P7 exception and the setup refresh it leads to, which have no outcome of their own.

## Acceptance Criteria

- [ ] Take a scratch source repo with a copy of `src/ravintio-framework/`, about 1,200 files. It also holds a committed `product.yml` and an older root copy. A run there behaves as follows. Verified by: integration
  - The run exits 0. The root copy holds every tracked source file except `component.yml`, with the same bytes and executable bits. A root file that the source lacks is gone.
  - `release.yml` matches the format exactly. The test checks the key order, the quoting, and the sort order. It checks each CRLF-as-LF SHA-256, and that no line names `release.yml` or `component.yml`.
  - The output holds one `added:`, `changed:`, or `removed:` line per differing file, and the `summary:` line with matching counts.
  - A second run on the same commit and day leaves every root file and `release.yml` byte-identical. Its summary shows `added 0, changed 0, removed 0`.
  - The full build finishes in under 30 seconds.
- [ ] The script refuses and keeps the old copy whole in each of these cases. Verified by: integration
  - It exits 2 and writes nothing in a downstream repo, or with an argument. It does the same with an uncommitted change under `src/`, or a tracked link.
  - It exits 2 and writes nothing when `ravintio-framework/`, `.ravintio-framework-build/`, or `.ravintio-framework-previous/` is a link. A file outside the root that a link points at stays byte-identical.
  - A link inside the old copy goes as a link, and its target outside the root stays byte-identical.
  - A source file that can't be read fails the build with a non-zero exit. The old root copy stays byte-identical, and no build folder remains.
  - With a leftover `.ravintio-framework-previous/` and no root copy, the next run restores the old copy, prints `restored:`, and then builds.
  - `.gitignore` holds a `.ravintio-framework-build/` line and a `.ravintio-framework-previous/` line.
- [ ] Both boot templates carry one identical `Sanctioned scripts:` sentence. It names eight scripts, `ravintio-framework/scripts/build-release.mjs` among them. The ship skill holds Step 5c between Step 5b and Step 6. Step 5c holds the `project-kind.mjs` check, the `build-release.mjs` call, and the exit handling. Step 7 holds the source-repo `git add -A -- ravintio-framework/` line and keeps its existing `git add` line. Verified by: integration
  - Verified by: integration - the new suite and the updated 0000035 req-008 and 0000039 req-008 suites
- [ ] The P7 build-log block holds the Decision line for the run from `src/`. The final report recommends a setup refresh, so that this repo's `CLAUDE.md` gains the eight-script sentence. Verified by: manual - git ignores `CLAUDE.md`, and no P7 log exists before P7

## Dependencies

- req-001 (move-pack-to-src) puts the pack at `src/ravintio-framework/` and restores the root copy from `v0.38.0`, so the first build has an old copy to compare.
- req-005 (applies-to-header) provides `projectKind(root)` in `scripts/project-kind.mjs`. The script imports it, so the source-repo signal has one owner.
- req-008 (tests-and-ci-from-src) provides the resolver the new suite uses. Its CI integrity check reads `release.yml` in the format above.
- req-003 (release-yml-readers) and req-006 (consumer-migration) read `release.yml` in the format above.
- Existing pattern: `set-product-release.mjs` for argument handling, the cleared `CLAUDE_PROJECT_DIR`, and exit 2. `archive-current.mjs` for link checks, recovery on rerun, and printed path cleaning.
- Backlog 0000384 covers pack docs that would ship in the release copy. This requirement copies every file except `component.yml`, as the design states.
