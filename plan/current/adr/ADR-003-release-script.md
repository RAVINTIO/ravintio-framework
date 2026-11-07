---
title: "ADR 003: Release script"
summary: "A new scripts/build-release.mjs rebuilds the root ravintio-framework/ release copy from src/ravintio-framework/ without component.yml and writes release.yml with a hash for each file. It builds in a work folder and swaps, writes only inside three folders, and runs only in the source repo. Boot Hard Limit 8 sanctions it, and a new ship Step 5c runs it at P7. This run's P7 runs it from src/ as a recorded decision."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Release script

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Component:** ravintio-framework (cross-component, see Affected Components)
**Date:** 2026-11-07

## Context

ADR-002 moves the pack source to `src/ravintio-framework/`. The root `ravintio-framework/` then becomes a release copy. This repo runs on it, and consumers copy it.

Something has to write that copy. These constraints shape the choice:

- Consumers must get a pack with no `component.yml`, so their runs never count the pack as their own source (US-002).
- Consumers must still detect each pack update. The copy needs a version, a source commit, and a hash per file (req-003, backlog 0000181).
- A broken change under `src/` must not break the run that ships it (US-001). The copy must stay whole if a build stops halfway.
- The Write-or-Edit rule (boot Hard Limit 8) bans file writes through a script unless the rule names that script. The release copy holds about 1,200 files, so **Write** and **Edit** can't build it.
- A script that deletes files is a security risk. R-002 rates a delete outside the root copy, for example through a link, as low likelihood and high impact.
- This run's P7 uses the 0.38.0 ship agent. That agent has no release step (R-003).

## Decision

Add `scripts/build-release.mjs` to the pack, at `src/ravintio-framework/scripts/build-release.mjs`. req-002 holds the full contract. The main points follow.

### What it builds

- It copies each file from `git ls-files -z -- src/ravintio-framework` into the root `ravintio-framework/`, except `component.yml`. It keeps each file's bytes and executable bit.
- It removes every root file that `src/` no longer holds, because it rebuilds the whole copy on every run.
- It writes `ravintio-framework/release.yml` with `format`, `version`, `source-commit`, `built`, and a SHA-256 for each file. ADR-004 owns that file contract and its readers.
- A rerun on the same commit and day gives a byte-identical copy.

### Inputs and refusals

- It takes no arguments. Any argument exits 2.
- It runs only in the framework source repo. It asks `projectKind(root)` from `scripts/project-kind.mjs`, the one owner of the source-repo signal (ADR-007, req-005).
- It reads `version` from `src/ravintio-framework/component.yml` and `source-commit` from `git rev-parse HEAD`.
- It refuses a dirty `src/ravintio-framework/`, so `source-commit` always matches the content.
- It refuses a tracked link, a submodule, and any path segment outside `[A-Za-z0-9._-]+`.
- Every refusal exits 2 and writes nothing.

### Write boundary

The script writes and deletes only inside three folders at the project root:

- `ravintio-framework/`, the root copy
- `.ravintio-framework-build/`, where it builds the new copy
- `.ravintio-framework-previous/`, where the old copy waits during the swap

Before any change, it checks each of the three folders and `src/ravintio-framework/`. Each must be absent or a real folder, never a link, and each must resolve inside the real root. Its recursive delete never follows a link. A link inside the old copy goes as a link, and its target stays as it was.

### Build and swap

1. Recover any leftover state from an interrupted run.
2. Build the full copy and `release.yml` in `.ravintio-framework-build/`.
3. Rename `ravintio-framework/` to `.ravintio-framework-previous/`.
4. Rename `.ravintio-framework-build/` to `ravintio-framework/`.
5. Delete `.ravintio-framework-previous/`.

At every point, one whole copy exists, either at `ravintio-framework/` or at `.ravintio-framework-previous/`. A rerun restores it and rebuilds the whole copy. The script prints an `added:`, `changed:`, or `removed:` line for each differing file, then one `summary:` line.

### Sanction and ship step

- Boot Hard Limit 8 names `ravintio-framework/scripts/build-release.mjs` as a sanctioned script with no arguments. Both boot templates carry the same eight-script sentence.
- The ship skill gains Step 5c after Step 5b. It checks `project-kind.mjs`, then runs the root copy of `build-release.mjs`. Running the last release, not `src/`, keeps a broken source change from breaking its own build.
- Step 7 stages `ravintio-framework/` with `git add -A` in the source repo only.

### This run's P7

The 0.38.0 ship agent lacks Step 5c, and the 0.38.0 root copy lacks the script. This run's P7 therefore runs `node src/ravintio-framework/scripts/build-release.mjs` after Step 5b and stages the root copy in the Step 7 commit. The P7 build-log block records this as a Decision line. It is a one-time recorded exception to the sanctioned path in Hard Limit 8, like the req-001 move pass. The final report recommends a setup refresh, so that this repo's `CLAUDE.md` gains the eight-script sentence (req-002 AC4).

### Security trade-off

The decision adds a sanctioned script that deletes a whole folder tree. That widens what a sanctioned script can do. The narrow boundary, the link checks, the no-argument rule, and the source-repo check keep the reach to three named folders in one kind of repo. P5 reviews the script against R-002.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Sync in place: delete and overwrite files inside `ravintio-framework/` with no work folder or swap | One folder in the write boundary. Less code. | An interrupted run leaves a mixed copy of old and new files. This repo then runs on a pack that matches no release, which breaks US-001. `release.yml` could list hashes the files don't match. | A half-built copy is worse than an old one, and the swap costs only two renames |
| `rsync --delete` or `git archive` piped to `tar` | Mature tools with known delete and copy rules | Neither ships on Windows Git Bash by default. Neither writes `release.yml`, so a second step still needs a script. A pipe through `tar` is a shell writer that Hard Limit 8 can't sanction by script name. `rsync --delete` writes in place, with the same interruption gap as the row above. | A Node.js script runs on every CI shard, owns the link checks, and writes `release.yml` in the same pass (ADR-001) |
| A CI release job that builds the copy after merge to `main` | No agent runs a delete script. The build runs in a clean checkout. | CI runs on `pull_request` only (0000031 ADR 003), so a job on `main` needs a new trigger. A bot commit to `main` breaks the rule that every change lands through a feature branch. The PR the human reviews would not show the release copy it ships. | The human must review the root copy in the PR before merge, and only the human merges to `main` |
| Let the agent write the copy with **Write** and **Edit** | Needs no new sanction | About 1,200 files per release, with no executable bits and no atomic swap. Each write passes through `gate-write` one at a time. | Not workable at this size, and scope bans **Write** or **Edit** to the root copy |
| Keep `component.yml` in the copy and teach consumers to ignore it | No new script | Every consumer reader must learn the rule. The file still bumps and tags in a run that misses it. | Removes neither the problem in the brief nor the update detection gap (0000181) |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Gains `scripts/build-release.mjs`, Step 5c and a Step 7 line in the ship skill, and the eight-script sentence in both boot templates. The script owns the root copy (ADR-005). |
| setup-hook-integration | Hard Limit 8 text in the boot templates changes, so the next setup run writes the new sentence into each tool's boot file. `gate-write` and `shell-write-guard` need no change, because the script runs through `node`. |
| consumer repos | Receive a root copy with `release.yml` and no `component.yml`. The script ships in the copy but exits 2 outside the source repo. |
| CI (`.github/workflows/ravintio.yml`) | The integrity check reads the `release.yml` the script writes (ADR-009, req-008). |

## Consequences

**Positive:**
- Consumers get a pack with no `component.yml`, so their runs stop counting the pack as source (US-002, closes the cause behind backlog 0000361 and 0000061).
- `release.yml` gives step 1a a version, a source commit, and a hash per file, which file-level update detection needs (req-003, backlog 0000181).
- An interrupted build leaves one whole copy, and a rerun recovers it. This repo never runs on a half-built pack (US-001).
- The human on the loop sees every root copy change in the PR diff before merge, because P7 commits it on the feature branch.
- Untracked files such as `.DS_Store` never reach a release, because the source set is `git ls-files`.

**Negative:**
- Hard Limit 8 grows to eight sanctioned scripts, and this one deletes a folder tree. A defect in its boundary checks has high impact (R-002).
- Each release commit carries the full diff of the root copy beside the `src/` diff. Reviewers read most changes twice.
- This run's P7 runs the script from `src/`, outside the sanctioned path. It relies on a recorded Decision line, not on the rule text (R-003).
- This repo's `CLAUDE.md` names the new script only after a manual setup refresh after P7, because setup writes that file and git ignores it.
- The script ships in every consumer copy, where it can only refuse. Backlog 0000384 tracks the wider question of pack files that ship but serve only the source repo.

**Risks:**
- A link check misses a case on one platform, and a delete lands outside the three folders. The link cases skip under Git Bash on Windows, so Windows coverage is thinner. P5 reviews the script, and the req-002 suite tests each link case on Linux and macOS.
- After an interrupted run, a broad `git add -A` could stage `.ravintio-framework-build/`. req-002 therefore adds both work folders to `.gitignore`, and Step 7 scopes its `git add -A` to `ravintio-framework/`.
- A maintainer runs the script by hand on a dirty tree. The dirty-tree refusal covers `src/ravintio-framework/` only, so an uncommitted root copy edit is lost on rebuild. Scope already bans **Write** or **Edit** to the root copy.

## Related ADRs

- ADR-001 - depends-on: the script uses Node.js with built-in modules only.
- ADR-002 - depends-on: the script exists because the source moves under `src/`.
- ADR-004 - related-to: ADR-004 owns the `release.yml` contract this script writes and its readers.
- ADR-005 - related-to: ADR-005 records that the script owns the root copy.
- ADR-007 - depends-on: the script calls the source-repo signal from `project-kind.mjs`.
- ADR-009 - related-to: the CI integrity check reads the hashes this script writes.

## Supersedes

- None

## Superseded By

- None
