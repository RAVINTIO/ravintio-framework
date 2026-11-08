# Scope - ravintio-framework

Last updated: 0000041-pack-source-under-src

The full in-scope list for earlier features lives in `component.yml`. This file records the 0000041 boundary and the standing ownership edges.

## In scope

- The pack source at `src/ravintio-framework/` and its `component.yml`.
- `scripts/build-release.mjs`, its sanction in the Write-or-Edit rule (boot Hard Limit 8), and the P7 Step 5c ship step.
- `ravintio-framework/release.yml` and its readers, with the `component.yml` fallback for a pack before 0.39.0.
- `scripts/release-check.mjs` and file-level update detection in step 1a.
- `scripts/project-kind.mjs` and the `**Applies to:**` migration header.
- The 0.39.0 migration `migrate-0.39.0-remove-pack-component-yml.md`.
- `tests/helpers/pack-root.sh` and the eight 0000041 suites.
- The CI `release-copy-integrity` job and CI paths that run `src/ravintio-framework/tests/run-tests.sh`.

## Out of scope

- History under `plan/_archive/` and `plan/changelog/`, and released migration files.
- The consumer runtime path `ravintio-framework/`, which stays in every pack file.
- Backlog 0000364, the consumer CI file that setup never refreshes.
- Where per-component docs for a pack live (backlog 0000384).

## Deferred

- A trust anchor outside the repo (backlog 0000416).
- A release build that reads committed bytes (backlog 0000417).
- A CI integrity failure for a deleted `release.yml` (backlog 0000418).
- A migration diff that maps the old layout to the new one (backlog 0000402).

## Boundary with setup-hook-integration

`setup-hook-integration` owns its manifest and docs at `src/setup-hook-integration/`. Its code paths point into `src/ravintio-framework/`. This component owns no setup behaviour that the other describes.
