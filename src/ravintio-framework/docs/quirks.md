# Quirks - ravintio-framework

Last updated: 0000041-pack-source-under-src

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
