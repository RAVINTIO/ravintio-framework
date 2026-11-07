---
title: "Scope - 0000041-pack-source-under-src"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "active"
version: "0.1.0"
---
# Scope - 0000041-pack-source-under-src

**Skill:** [spec-agent](../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Wave:** not waved
**Version:** 0.39.0

> All three sections must be present. If "Deferred" is empty, state "Nothing deferred."

## In Scope

- The git pass. One commit runs `git mv ravintio-framework src/ravintio-framework`, then `git checkout v0.38.0 -- ravintio-framework`. The commit holds no content edits. It is a recorded exception to the Write-or-Edit rule (boot Hard Limit 8), approved at P0. Maps to req-001-move-pack-to-src (US-001).
- Path fixes after the git pass, each made with **Edit**. `product.yml` lists `ravintio-framework` at `src/ravintio-framework/component.yml`. The `setup-hook-integration` manifest and docs stay at `src/setup-hook-integration/`, and its code paths point into `src/ravintio-framework/`. Maps to req-001-move-pack-to-src (US-001).
- The release script `src/ravintio-framework/scripts/build-release.mjs`. Maps to req-002-release-script (US-002).
  - It copies `src/ravintio-framework/` to the root `ravintio-framework/` without `component.yml`.
  - It removes root copy files that `src/ravintio-framework/` no longer holds.
  - It writes `ravintio-framework/release.yml` with `version`, `source-commit`, `built`, and a SHA-256 for each file.
  - It builds into a temporary folder beside the root copy, then swaps the folders. An interrupted build leaves the old copy whole.
  - It refuses any path outside the root copy, including through a link.
  - It prints each file it adds, changes, or removes, and a summary line.
  - It builds the full pack, about 1,200 files, in under 30 seconds on a CI runner.
  - It runs only in the framework source repo.
- The sanction for the release script in the Write-or-Edit rule (boot Hard Limit 8), with the arguments its ship step shows. Maps to req-002-release-script (US-002).
- A new P7 step after Step 5b in `src/ravintio-framework/skills/ravintio-ship-agent/SKILL.md` that runs the release script in the source repo. This run's P7 runs the script from `src/ravintio-framework/scripts/` as a recorded decision, because this run's ship agent is the 0.38.0 copy. Maps to req-002-release-script (US-002).
- `release.yml` readers. Orchestrator step 1a, `standards/framework-update-policy.md`, and the migrator read `ravintio-framework/release.yml` first. Each falls back to `ravintio-framework/component.yml` for a pack before 0.39.0. Maps to req-003-release-yml-readers (US-002).
- File-level update detection in step 1a, stated in the update policy (backlog 0000181). Maps to req-003-release-yml-readers (US-002).
  - A new `source-commit` or `version` against the value the repo last recorded is a release update. A first upgrade compares the version only.
  - A pack file that differs from its `release.yml` hash is a changed file. It counts as an update even when the version is unchanged, and step 1a names each file.
- The leftover manifest warning. Step 1a warns at every session start while `ravintio-framework/component.yml` sits beside `release.yml`, even after the migration records `skipped`. Maps to req-003-release-yml-readers (US-002).
- The component path rule (backlog 0000061, 0000361). Maps to req-004-component-path-rule (US-002).
  - The codegen close-out in `skills/ravintio-codegen-agent/SKILL.md` bumps the manifest of each component the run changed. It reads them from `## Component Paths` and `product.yml`, and never names `ravintio-framework/component.yml`.
  - The ship fallback with no `product.yml` reads the single component from the design.
  - `skills/ravintio-spec-agent/SKILL.md`, `skills/ravintio-docs-agent/SKILL.md`, and `templates/component-guide.md` state one manifest rule. A manifest lives at the path `product.yml` lists, and `src/{component-id}/` is the default.
- The `**Applies to:**` migration header and the source-repo signal (backlog 0000378, 0000136). Maps to req-005-applies-to-header (US-003).
  - The header takes `framework source`, `downstream`, or `all`. An absent line reads as `all`.
  - A repo is the framework source when `product.yml` lists `ravintio-framework` at `src/ravintio-framework/component.yml` and that file exists.
  - The migrator records `not applicable` with the reason when the project kind differs. This narrows 0000035 ADR-019 for future migrations only.
- A new 0.39.0 consumer migration under `src/ravintio-framework/migrations/` with `**Applies to:** downstream`. If `ravintio-framework/component.yml` remains beside a `release.yml`, it offers to remove it in one confirmed edit. If the human on the loop declines, it records `skipped` and names the file. Maps to req-006-consumer-migration (US-002).
- The version equality suite (backlog 0000368). The 0000039 req-010 equality checks run only on a released tree, where `plan/current/design.md` is absent. On an open run, the suite reports them skipped with the reason. Maps to req-007-released-tree-version-suite (US-001).
- Tests and CI from `src/`. Maps to req-008-tests-and-ci-from-src (US-001).
  - Suites in the source repo read the pack from `src/ravintio-framework/` through one resolver. The resolver fails a suite that reads the root copy in the source repo.
  - `.github/workflows/ravintio.yml` runs `src/ravintio-framework/tests/run-tests.sh` and the other pack tests and scripts it runs today from `src/ravintio-framework/`.
  - A new CI check fails when a root copy file differs from its `release.yml` hash. Until this run's P7 writes the first `release.yml`, the check reports itself skipped with that reason.
- Live docs: `docs/component-registry.md`, `docs/decisions-index.md`, and `./README.md` name the new pack source path and the release copy.
- P1 clarification: the design's Component Paths also list `./CLAUDE.md`, `.claude/skills/`, and `refresh-ravintio-framework-dir.ps1`. They cover the Hard Limit 8 text in this repo's boot file and the setup re-run from the new root copy. They add no new scope.

## Out of Scope

- History under `plan/_archive/` and `plan/changelog/`. It stays as written.
- Released migration files, including `migrate-0.38.0-retire-fast-path-and-change-pipeline.md`, which names `ravintio-framework/component.yml`. Released migrations never change.
- Existing `not applicable` records under `plan/_migrations/`. They stay as written.
- The consumer runtime path `ravintio-framework/` in pack text. About 134 pack files name it, and it stays the path in every pack file.
- Any **Write** or **Edit** to the root `ravintio-framework/` copy. Only the git pass and the release script write it.
- Removing a consumer's `ravintio-framework/component.yml` without the human on the loop's confirmation.
- Backlog 0000364, the consumer CI file that setup never refreshes. Setup copies the CI template only when the consumer has no CI file. That gap affects every template change, not only this feature, so its own entry owns it. This feature changes only this repo's `.github/workflows/ravintio.yml`.

## Deferred

- Nothing deferred.
