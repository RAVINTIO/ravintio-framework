# Security re-review - 0000041 P5 fixes

A fresh-context reviewer checked each fix in commits `20387dae` and `c3f845df`. Five fixes hold. Two hold for the reported case but have a bypass:

- RS-F06: `GIT_CONFIG_GLOBAL` still injects config.
- RS-F07: a tracked folder named `release.yml` still exits 1.

The fix for the 0o700 mode also leaves the root copy folder at mode 0o700.

Every experiment ran in a `mktemp -d` scratch repo under `/tmp`. `mk.sh` made each one from `git archive HEAD` of this branch at `c3f845df`. No run touched this repo. The scripts and their full output are in the session scratchpad:

- `rr-build.sh` and `rr-build.out` cover build-release.
- `rr-check.sh` and `rr-check.out` cover release-check.

Git was 2.50.1 (Apple Git-155) on macOS APFS with umask `0022`.

## Verdicts

| Finding | Verdict | Evidence (command and observed output) |
|---|---|---|
| RS-F01 root follows cwd into `src/` | Fixed | The original plant, then `cd src && node ravintio-framework/scripts/build-release.mjs`, printed `build-release: the project root is not the git top level` and exited 2. The pack kept its 1,197 files. |
| RS-F01 bypass: symlinked cwd | Holds | A link to `$R/src` as cwd printed `the project root is not the git top level` and exited 2. |
| RS-F01 bypass: git worktree | Holds | `git worktree add W`, then a run from `W/src` with the plant exited 2 with the same line. A run from `W` itself exited 0, which is a legitimate build. |
| RS-F01 bypass: `GIT_CEILING_DIRECTORIES=$R` from `src/` | Holds, fails closed | It printed `build-release: git rev-parse failed: exit 128` and exited 1. The variable stays in the child environment, so the exit is 1 rather than 2. |
| RS-F01 bypass: root through a symlink or a different letter case | Holds | Both runs exited 0 with a normal `summary:` line. The three paths agreed, so neither was a false refusal. |
| RS-F06 git config from the environment | Partly fixed | `GIT_CONFIG_COUNT`, `GIT_CONFIG_PARAMETERS`, and a `.git/config` `core.fsmonitor` hook no longer ran: `fsmonitor ran: no` each time. The bypass is in NF-01. |
| RS-F07 tracked `release.yml` or case collision | Partly fixed | A tracked `release.yml` exited 2 with `clashes with the built release.yml`. `RELEASE.YML` also exited 2. `zcase/Readme.md` with `zcase/readme.md` exited 2 with `differ only in case`. The bypass is in NF-02. |
| RS-F08 `restored:` line lost on failure | Fixed | The copy sat at `.ravintio-framework-previous/` and the build then failed. `node build-release.mjs \| cat` printed `restored: ravintio-framework/ from an interrupted build` before the failure line, and exited 1. |
| Mode 0o700 on `.ravintio-framework-build/` | Fixed | A poll during the build saw `drwx------` on `.ravintio-framework-build`. NF-03 records a side effect. |
| RC-F02 fallback downgrade | Fixed | With a valid record, `release.yml` deleted, and `component.yml` at the recorded version, the run printed `missing: ravintio-framework/release.yml` and `update: release`, and exited 1. |
| RC-F02 bypass: record present but empty, BOM only, a folder, or a link | Holds | An empty or BOM-only record printed `has no valid version and source-commit` and exited 2. A folder printed `is not a regular file`, and a link printed `is a link`. Both exited 2. None fell back to `component.yml`. |
| RC-F02 control: no record | Holds | With no record and no `docs/about.md`, the run printed `release: none, fallback component.yml version "0.39.0"` and `update: release`, and exited 1. This is the intended pre-0.39.0 path. |
| RC-F08 `git ls-files` runs `core.fsmonitor` | Fixed | The own-build check printed `update: own-build` and exited 0. No hook ran from `.git/config`, `GIT_CONFIG_COUNT`, `GIT_CONFIG_GLOBAL`, or an `include.path` file. Each check printed `ran: no`. |

## New findings

### NF-01 Low: `GIT_CONFIG_GLOBAL` and `GIT_CONFIG_SYSTEM` still inject config (RS-F06 bypass)

`build-release.mjs` `git()` clears the `GIT_CONFIG_COUNT`, `GIT_CONFIG_KEY_*`, `GIT_CONFIG_VALUE_*`, and `GIT_CONFIG_PARAMETERS` variables. It leaves `GIT_CONFIG_GLOBAL` and `GIT_CONFIG_SYSTEM` alone. A global config can set `core.attributesFile` and a `filter.*.clean` command. `git status` runs that command on any file whose stat data changed.

Reproduction: `GIT_CONFIG_GLOBAL=$X/evil.cfg` held `attributesFile = $X/attrs` and `filter "e" clean = "touch $X/FILTER-RAN; cat"`. `$X/attrs` held `* filter=e`. The test touched `getting-started.md` and ran the build. The build exited 0, and `filter ran: yes`. A clean filter that prints the committed bytes could also hide an uncommitted edit from `checkClean`.

Whoever sets the environment can already run code, so the severity stays Low. The original suggestion still applies. Build the git environment from an allowlist, set `GIT_CONFIG_NOSYSTEM=1`, and point `GIT_CONFIG_GLOBAL` at an empty file or `/dev/null`. `release-check.mjs` `ownBuild` has the same gap. `git ls-files` runs no filter, so no exploit there was found.

### NF-02 Low: a tracked folder named `release.yml` still exits 1 (RS-F07 bypass)

`sourceFiles` refuses `rel.toLowerCase() === "release.yml"` only when that path is a file. A tracked `src/ravintio-framework/release.yml/x.md` passes, and the build makes a `release.yml/` folder. The final `writeNew` then fails.

Reproduction output: `build-release: write .../.ravintio-framework-build/release.yml: EEXIST`, exit 1. The old copy stayed whole, so the failure is closed. A rerun fails the same way, which is the exit-code fault RS-F07 named. The suggested fix is to refuse when the first segment of `rel`, lowercased, is `release.yml`.

### NF-03 Low: the root copy folder keeps mode 0o700 after a build

The build folder becomes the copy through a rename, so `ravintio-framework/` ends at `drwx------`. Its subfolders stay at `drwxr-xr-x`. Git records no folder mode, so consumers are not affected. In this repo, any other local account loses read access to the root copy after each P7 build. That includes a CI runner or a tool under a separate user. The suggested fix is to `chmod` the build folder to `0o755` just before the swap rename, or to accept and document the mode.

## Observation

The `--files-only` mode still prints `skipped: no ravintio-framework/release.yml` and exits 0 when a record exists and `release.yml` is gone. The `release-copy-integrity` CI job reads that as a pass. That mode follows req-003 as written, and R-015 covers the writer who can do it. The RC-F02 fix covers step 1a only. Backlog 0000418 records the CI side.

## Re-review 2

Scope: commit 8ce4d7c8. Every run used a `mktemp -d` scratch repo built from `git archive HEAD`. No run touched this repo.

| Finding | Verdict | Evidence |
|---|---|---|
| NF-02 tracked folder `release.yml/` | Fixed | `release.yml/x.md` exited 2 with `clashes with the built release.yml`, and no `ravintio-framework/` was created. `Release.YML/x.md` exited 2 the same way. The check now tests `segs[0]`, so a folder at the pack root is covered. |
| NF-02 bypass: nested `docs/release.yml/y.md` | Holds, no impact | The build exited 0 and wrote the folder. A nested folder cannot clash with the root `release.yml`, so refusing it is not needed. |
| NF-02 bypass: look-alike `releaſe.yml/` and `release.yml ` (trailing space) | Holds, no impact | Both exited 2 with `path segment outside [A-Za-z0-9._-]+`. The segment allowlist stops them before the clash check. |
| NF-02 bypass: `release.yml./y.md` | Holds, no impact | The build exited 0. The name differs from `release.yml` on APFS and on case-folding file systems, so no clash exists. |
| NF-03 root copy mode | Fixed | After a build, `stat` showed `755` on `ravintio-framework/`. A preload hook printed the build folder mode at the `chmod` call. The code shows `mkdirSync(out, { mode: 0o700 })`, so the folder stays 0700 while it fills. |
| NF-03 failed `chmod` leaves the old copy whole | Fixed | A preload made `chmodSync` throw `EPERM` on a second build. The build exited 1 with `chmod .ravintio-framework-build: EPERM`. A checksum of the old copy was unchanged and its mode stayed 755. The next normal build removed the stale build folder and exited 0. |
| RS-F01 root escape | Holds | A build from `src/` with a planted `src/src/ravintio-framework` exited 2 with `the project root is not the git top level`. Symlink, worktree, and letter-case variants behaved as before. |
| RS-F06 `GIT_CONFIG_COUNT`, `GIT_CONFIG_PARAMETERS`, `.git/config` fsmonitor | Holds | Each run printed `fsmonitor ran: no`. |
| RS-F07 tracked `release.yml`, `RELEASE.YML`, case collision | Fixed | The file cases and `zcase/Readme.md` against `zcase/readme.md` all exited 2 with the earlier messages. |
| RC-F02 fallback downgrade | Holds | With `release.yml` deleted and a valid record, `release-check.mjs` printed `missing: ravintio-framework/release.yml` and `update: release`, and exited 1. An empty, BOM-only, folder, or link record exited 2. |

### New findings

- NF-01 stays open. `GIT_CONFIG_GLOBAL` with a clean filter still ran the filter (`filter ran: yes`). Severity stays Low.
- No new finding from this commit.
- Minor: a failed `chmod` leaves `.ravintio-framework-build/` on disk. The next run removes it, so no action is needed.
