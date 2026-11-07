---
title: "Security Review - 0000041 release script"
summary: "P5 fresh-context review of build-release.mjs and the parts of path-rules.mjs and project-kind.mjs it imports, against the req-002 write boundary and risk R-002."
status: "active"
---
# Security Review - 0000041 release script

**Feature:** 0000041-pack-source-under-src
**Phase:** P5
**Reviewer:** fresh-context security reviewer (release script scope)
**Scope:** `src/ravintio-framework/scripts/build-release.mjs`, `resolveRoot` and `markedRoot` in `src/ravintio-framework/hooks/enforcement/path-rules.mjs`, and `projectKind` in `src/ravintio-framework/scripts/project-kind.mjs`
**Method:** code read, then experiments in `mktemp -d` scratch repos under `/tmp`, each holding a `git archive HEAD` copy of `src/ravintio-framework/` and a minimal `product.yml`. No experiment ran against this repo. The scratch repos are deleted.

## Summary

Overall risk rating for this scope: **High**.

The script holds its write boundary against every static state the requirement lists. A link at any of the three folders or at `src/ravintio-framework/` exits 2. A link inside the old copy goes as a link. Arguments, `CLAUDE_PROJECT_DIR`, and `GIT_DIR` can't move the root. Each interrupted-swap state recovers on a rerun.

The boundary fails in two other ways:

- The root follows the working directory. Run from `src/` beside a planted `src/product.yml`, the script treats `src/` as the root and deletes the real pack source, untracked files included (F-01, High).
- A concurrent writer in the root can swap a folder for a link during the run. A scratch repo reproduced 186 writes and 2,886 deletes outside the root (F-02 and F-03, Medium).

The other findings are Low. They cover a source read race, a dirty check that git state can hide, git config from the environment, and two inputs that exit 1 where they should exit 2.

Top actions before production:

1. Refuse unless the working directory's real path equals `git rev-parse --show-toplevel` and the root that `resolveRoot` returns (F-01).
2. Read each source file from the git object store at `HEAD`, not from the working tree (F-04 and F-05).
3. Check that each parent folder still holds the device and inode the script made or listed before each write and each child delete (F-02 and F-03). Record the residual risk in the risk register.

## Threat model (STRIDE)

| ID | Threat | Category | Severity | Mitigation |
|---|---|---|---|---|
| F-01 | A cwd under `src/` and a tracked `src/product.yml` make `src/` the root. The build then replaces the real `src/ravintio-framework/` and deletes uncommitted work there. | Tampering | High | not mitigated |
| F-02 | A concurrent writer swaps a build subfolder for a link after `mkdir`. New files land outside the root, and the release copy holds the link. | Tampering | Medium | not mitigated |
| F-03 | A concurrent writer swaps a folder in `.ravintio-framework-previous/` for a link mid-delete. `removeTree` deletes files outside the root. | Tampering | Medium | not mitigated |
| F-04 | A concurrent writer swaps a source folder for a link after `assertRealDirs` caches it. Outside content enters the release copy and `release.yml` with exit 0. | Info Disclosure | Low | not mitigated |
| F-05 | `git update-index --assume-unchanged` hides an edit from `checkClean`. The copy ships bytes that the named `source-commit` doesn't hold. | Tampering | Low | not mitigated |
| F-06 | `GIT_CONFIG_COUNT` and similar variables reach git. A `core.fsmonitor` value runs a command during `git status`. | Elevation | Low | partly: `GIT_DIR`, `GIT_WORK_TREE`, and `GIT_INDEX_FILE` are cleared |
| F-07 | A tracked `release.yml` or a case-only name collision fails with exit 1. Ship Step 5c then says to fix and rerun, which never ends. | DoS | Low | fails closed, wrong exit code |
| F-08 | A `restored:` line is lost when the build fails after recovery. The log then never shows the restore. | Repudiation | Low | not mitigated |
| - | A link at `ravintio-framework/`, `.ravintio-framework-build/`, `.ravintio-framework-previous/`, or `src/ravintio-framework/` | Tampering | - | mitigated: `checkBoundary` exits 2 (reproduced) |
| - | A link inside the old copy, or a tracked link or submodule | Tampering | - | mitigated: unlinked as a link, or refused by mode |
| - | A `..`, `.`, empty, or non-ASCII path segment in a tracked name | Tampering | - | mitigated: `SEGMENT_RE` at `build-release.mjs:162` |
| - | An argument, `CLAUDE_PROJECT_DIR`, or `GIT_DIR` that moves the root | Spoofing | - | mitigated: exit 2, cleared, or deleted (reproduced) |
| - | A case-variant cwd on APFS | Tampering | - | mitigated: same files, no escape (reproduced) |
| - | An interrupted swap at each step | DoS | - | mitigated: `recover` restores or deletes (reproduced) |
| - | A partial build committed by mistake | Tampering | - | mitigated: `.gitignore` lines 32 and 33 |

## Findings

### F-01: the root follows the working directory into `src/` (High)

**Where:** `build-release.mjs:323-345` calls `resolveRoot(process.cwd())`. `path-rules.mjs:278-304` (`markedRoot`) returns the nearest folder that holds a `ravintio-framework/` folder. From any cwd under `src/`, that folder is `src/`.

**What happens:** `projectKind(src)` returns `framework source` once `src/product.yml` exists and `src/src/ravintio-framework/component.yml` is tracked. Every later path then shifts one level down:

- `checkClean` checks `src/src/ravintio-framework`, so uncommitted work in the real pack source passes.
- `sourceFiles` lists `src/src/ravintio-framework`.
- The swap renames the real `src/ravintio-framework/` to `src/.ravintio-framework-previous/` and deletes it.

An attacker who can land two small tracked files under `src/` gets this. The runner only needs a cwd under `src/`, which an agent shell keeps after a `cd`. R-006 records the `markedRoot` fault for the hooks, where it fails closed. Here it fails open.

**Reproduction (ran):**

```bash
# scratch repo R with the pack at src/ravintio-framework and a root product.yml
mkdir -p src/src/ravintio-framework
cp product.yml src/product.yml
printf 'id: x\nversion: 9.9.9\n' > src/src/ravintio-framework/component.yml
echo pwned > src/src/ravintio-framework/evil.md
git add -A; git commit -qm plant
echo local-untracked > src/ravintio-framework/MYNOTES.txt
(cd src && node ravintio-framework/scripts/build-release.mjs)
```

Result: exit 0 with `summary: version 9.9.9 ... added 2, removed 1198`. The real `src/ravintio-framework/` went from 1,198 files to 2, `evil.md` and `release.yml`. `git status` shows every pack file deleted. The untracked `MYNOTES.txt` is gone for good. Without the plant, the same cwd exits 2 with `project kind is downstream`.

**Suggested fix:** after `realpathSync(found)`, read `git rev-parse --show-toplevel` with the cleared environment and take its real path. Refuse with exit 2 unless the real cwd, the resolved root, and the git top level are one path. The ship step already runs from the root, so the check costs nothing there. As defence in depth, refuse when the root sits inside a `src/` folder.

### F-02: a build folder swapped for a link sends writes outside the root (Medium)

**Where:** `build-release.mjs:288-296`. `mkdirSync(join(out, d))` and `writeNew(join(out, rel))` resolve each path from the root by name. `O_NOFOLLOW` at line 245 guards the last segment only, so a link at a parent folder is followed.

**What happens:** a process that can write in the root swaps `.ravintio-framework-build/tests` for a link after the script makes it. Every later write into `tests/` lands at the link target. The swap then moves the link into the release copy, and ship Step 7 stages it with `git add -A`. The script exits 0. This breaks the req-002 line "No write or delete lands outside the three folders, whatever a link inside them points at".

**Reproduction (ran):** `racer.mjs` loops on `lstat` of `$R/.ravintio-framework-build/tests`. Once it sees a folder, it moves it aside and links the path to a scratch folder `OUT` outside the root. With the build running beside it, one of two runs ended `build exit 0`, and `OUT` held 186 files. The other run lost the race and exited 1 with `ENOENT`.

**Suggested fix:** Node has no `openat` or `mkdirat`, so a full fix in pure Node isn't possible. Narrow the window:

- Make `.ravintio-framework-build/` with mode `0o700`, so only the owner can swap a folder inside it.
- Record the `dev` and `ino` of each folder the script makes. Before each write, `lstat` the parent and refuse unless it is still that folder and not a link.
- Before the swap, walk the build folder and refuse if any entry is a link.

Record the remaining same-user race against R-002 as accepted, because a same-user writer can already change the root.

### F-03: `removeTree` follows a folder swapped mid-delete (Medium)

**Where:** `build-release.mjs:177-194`. The function calls `lstat` on a path, then `readdirSync` on it, then recurses on child paths built by name. `recover` (lines 203 and 209) and step 5 (line 374) both use it.

**What happens:** after `readdirSync` lists a folder, the recursion rebuilds each child path from the root. A writer who swaps that folder for a link while the children are being deleted redirects each later child path to the link target. `lstat` on the child then sees a real folder outside the root, and the script deletes its contents.

**Reproduction (ran):** the old copy gained `zz/d1` to `zz/d3000`, each holding one file. A victim folder outside the root held the same names. `racer3.py` waited until `.ravintio-framework-previous/zz` held fewer than 2,900 entries. It then swapped the folder for a link to the victim with `renamex_np(RENAME_SWAP)`, so no gap opened. One of two runs deleted 2,886 of the victim's 3,000 files and exited 1 with `ENOTDIR`. The other run exited 1 with `ENOTEMPTY` and deleted nothing. A non-atomic swap (rename, then link) lost every round with `ENOENT`.

**Suggested fix:**

- Before `readdirSync`, and again before each child, `lstat` the folder and refuse unless its `dev` and `ino` match the first `lstat`.
- Make `.ravintio-framework-previous/` reachable only by the owner, by renaming into a `0o700` folder.
- Consider `fs.rmSync` with `recursive: true` only after checking how the installed Node version handles a link swap. Don't adopt it without a test.

Record the residual same-user race against R-002, as for F-02.

### F-04: a source folder swapped after its check feeds outside content into the copy (Low)

**Where:** `build-release.mjs:257-269`. `assertRealDirs` checks each source folder once and caches it in `seen` (line 262). `readNoFollow` at line 104 then opens later files by name, and `O_NOFOLLOW` guards only the last segment.

**What happens:** a writer swaps `src/ravintio-framework/tests` for a link after its first file has been read. The other files in that folder then come from outside the root. The run exits 0. `release.yml` hashes the outside content, so the integrity check that req-008 runs in CI passes against it. The effect is a read, not a write, but the content reaches a commit.

**Reproduction (ran):** `racer4.py` waited for `.ravintio-framework-build/tests` to exist. It then swapped `src/ravintio-framework/tests` for a link to a folder outside the root, using `renamex_np(RENAME_SWAP)`. In that folder, every `*.sh` file held `SECRET-OUTSIDE-ROOT`. The run exited 0, and 141 files in `ravintio-framework/tests/` held the marker. A swap before the first read exited 1 with `not a real folder`, so the check works when it runs.

**Suggested fix:** read the bytes from git, not the working tree. `git cat-file --batch` fed with `HEAD:src/ravintio-framework/{rel}` returns the committed blob. The file system then holds no source path to swap. This also closes F-05 and makes `source-commit` true by construction. Take the executable bit from the `ls-files -s` mode, as the script does now.

### F-05: `assume-unchanged` hides an edit from the dirty check (Low)

**Where:** `build-release.mjs:141-145` (`checkClean`) trusts `git status`. Line 286 reads the working tree.

**Reproduction (ran):**

```bash
echo UNCOMMITTED >> src/ravintio-framework/getting-started.md
git update-index --assume-unchanged src/ravintio-framework/getting-started.md
node src/ravintio-framework/scripts/build-release.mjs
```

Result: exit 0. `ravintio-framework/getting-started.md` holds the `UNCOMMITTED` line, and `release.yml` names a `source-commit` that doesn't hold it. `skip-worktree` and an `fsmonitor` that reports no change act the same way.

**Suggested fix:** the F-04 fix, reading blobs from `HEAD`, removes the gap. As a smaller fix, refuse when `git ls-files -v -- src/ravintio-framework` prints a lowercase tag or an `S` tag.

### F-06: git config from the environment reaches every git call (Low)

**Where:** `build-release.mjs:86-98`. `git()` deletes `GIT_DIR`, `GIT_WORK_TREE`, and `GIT_INDEX_FILE` only.

**Reproduction (ran):** `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.fsmonitor GIT_CONFIG_VALUE_0="touch $R/FSMONITOR-RAN; false"` before the script. The command ran during `git status`, and the build went on to exit 0. `GIT_DIR=/nonexistent` had no effect, as intended.

Whoever sets the environment can already run code, so the risk is low. The script still trusts git config, though, and an `fsmonitor` value can also hide changes from F-05's check.

**Suggested fix:** build the git environment from an allowlist, such as `PATH`, `HOME`, `LANG`, and `SYSTEMROOT` on Windows. Pass `-c core.fsmonitor=false -c core.hooksPath=/dev/null` on each call. Also set `GIT_CONFIG_NOSYSTEM=1`. Leave `GIT_CONFIG_GLOBAL` at its default, because the run needs no user config.

### F-07: two tracked-name inputs exit 1 instead of 2 (Low)

**Where:** `build-release.mjs:167` skips only `component.yml`. Line 301 writes `release.yml` with `O_EXCL`. Lines 290-296 track folder names case-sensitively.

**Reproduction (ran):**

- A tracked `src/ravintio-framework/release.yml` exits 1 with `write .../release.yml: EEXIST`.
- Tracked `zcase/Readme.md` and `zcase/readme.md` on APFS exit 1 with `write .../zcase/readme.md: EEXIST`.

Both fail closed, and the old copy stays whole. The exit code is wrong, though. Ship Step 5c treats exit 1 as "fix the cause stderr names and rerun", and a rerun fails the same way. req-002 says a bad source entry exits 2.

**Suggested fix:** in `sourceFiles`, refuse `rel === "release.yml"` with exit 2. Also refuse two paths whose lowercase forms match, at any segment.

### F-08: the `restored:` line is lost when a later step fails (Low)

**Where:** `build-release.mjs:202-212` pushes `restored:` into `lines`. Line 377 prints `lines` only after a full success.

**What happens:** a run that restores the old copy and then fails in the build prints only the failure. The operator and the P7 log never learn that a restore ran. A test in `expMisc.sh` reached the success path, which printed the line. The failure path follows from the code.

**Suggested fix:** write the `restored:` line to stdout at once, or to stderr on the failure path.

## Risk register cross-reference

| Risk | Status in the code | Note |
|---|---|---|
| R-002 | partly mitigated | Static link states refuse with exit 2. F-01 breaks the boundary through root choice. F-02 and F-03 break it through races. Keep R-002 `open` until F-01 is fixed and the residual race is recorded. |
| R-006 | widened | The hooks fail closed on the wrong root. `build-release.mjs` fails open (F-01). Backlog 0000382 tracks the `markedRoot` fix. F-01's top-level check removes the dependency on it. |
| R-009 | mitigated | `lfHash` at line 215 reads CRLF as LF. |

## Dependency audit

The script imports only Node built-ins and two pack modules. It adds no dependency.

## Secrets management

The script reads no secret and writes none. `clean()` at line 68 strips control characters from printed paths, and `argName` at line 80 never echoes an argument value.

## Authentication and authorisation, input validation, network, and IaC

The script has no API, no network access, and no IaC. Its inputs are the cwd, the environment, the git index, and the working tree, which the findings above cover.

## Windows

This review didn't run on Windows. Two points need a Windows check before the boundary claim holds there:

- `O_NOFOLLOW` is `0` on Windows (line 62). Every `O_NOFOLLOW` guard is then absent, and only the `lstat` checks remain.
- Node reports a junction as a link through `lstat`, so `checkBoundary` and `removeTree` should treat it as one. The req-002 suite skips link cases under Git Bash on Windows, so no test covers this.

## Reproduction scripts

The scratch scripts sit in the session scratchpad at `/private/tmp/claude-501/-Users-martinmayer-d-ravintio-framework/3cb17e30-2be7-449d-8645-9ad5e43c57ae/scratchpad/`. They are `mk.sh`, `expB.sh` (F-01), `expRace.sh` with `racer.mjs` (F-02), `expDel.sh` with `racer3.py` (F-03), `expRead.sh` with `racer4.py` (F-04), and `expMisc.sh` (F-05 to F-08 and the mitigated cases). The racers run on macOS only, because they call `renamex_np`.
