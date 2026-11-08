# Quirks - ravintio-framework

Last updated: 0000043-macos-test-job-timeout

## Two copies of the pack

This repo holds the pack twice. Maintainers edit `src/ravintio-framework/`. The root `ravintio-framework/` is the release copy and is read-only to agents. Consumers copy the root folder.

## The root copy is frozen at v0.38.0 until P7

The pass commit left the root copy at `v0.38.0`, with its `component.yml` and no `release.yml`. It stays so during 0000041, and the run uses the 0.38.0 skills and hooks from it.

- The 0.38.0 ship agent has no Step 5c. This run's P7 runs `node src/ravintio-framework/scripts/build-release.mjs` from `src/` as a recorded decision.
- The CI `release-copy-integrity` job reports itself skipped while the root copy has no `release.yml`.
- After P7 the root copy is 0.39.0 and the next run uses it.

## The root copy is not a place to fix a bug

A hand edit to the root copy ships to every consumer without passing the suites that run against `src/`. The next release build also overwrites it. Fix the source and rebuild.

## Pack docs ship in the release copy

These docs sit in `src/ravintio-framework/docs/`, so the release script copies them into every consumer's `ravintio-framework/docs/`. This is backlog 0000384. It is a known gap and not a fix target in 0000041.

## Suites find the pack through one resolver

Suites source `tests/helpers/pack-root.sh`. In the source repo, a suite run from the root copy prints a FAIL line and exits 1. Run the suites from `src/ravintio-framework/tests/`.

## Release script details

- The script builds from tracked files, so an untracked file never ships. A dirty pack source also stops the build.
- A rerun rebuilds the whole copy. An interrupted run leaves the old copy whole, and the next run prints `restored:`.
- The case-collision test skips on a case-insensitive file system. Run it on Linux CI to cover RS-F07.

## Leftover component.yml in a consumer

Copying a new pack over an old one never removes `component.yml`. Step 1a warns at every session start while the file sits beside `release.yml`, even after the migration records `skipped`.

## Version suite

The 0000039 req-010 equality checks run only on a released tree, where `plan/current/design.md` is absent. On an open run they print `SKIP (open run):` with the reason.

## Paths inside node -e scripts on Windows

Git Bash converts command arguments to Windows paths, but not text inside a `node -e` script. A suite that writes a path into such a script converts it first. It uses `pwd -W` for its scratch folder and the `native()` helper, which runs `cygpath -m`, for any other path. Node otherwise reads `/d/a/...` as `D:\d\a\...` (0000042 ADR-001).

## Link cases skip on Windows

Git Bash `ln -s` makes a copy, so no link case can run on a Windows shard. The 0000041 req-005 and req-006 suites each put their link cases behind one `IS_WIN` guard, and `tests/README.md` lists each guard. `test-0000042-req-001-windows-guards.sh` checks the guards from Linux and macOS through a `uname` stand-in (0000042 ADR-002).

## Line endings and released files

A Windows checkout converts LF to CRLF, so a byte compare against a `git show` copy fails although the file is unchanged. Compare git blob ids instead, with `git hash-object` run inside the repo for the working-tree copy (0000042 ADR-003).

## Testing a workflow step's script

`test-0000043-req-002-job-margin.sh` finds the `Report the test step time` step by its name and strips a 10-space block indent from its `run:` block. A rename or a reformat of that step breaks the extraction, so change the suite with the step (0000043 ADR-003).

Pass an awk pattern through `ENVIRON`, not `awk -v`. `awk -v` processes backslash escapes, so `\$\(` reaches awk as `$(` and never matches.

## Leading zeros in Bash arithmetic

Bash reads a number with a leading zero as octal, so `$((08))` fails. The elapsed step rejects a start time or cap with a leading zero for this reason (0000043 security finding S-001).
