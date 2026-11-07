---
title: "Requirement: req-006 - consumer-migration"
summary: "A 0.39.0 migration for downstream projects offers to remove a leftover ravintio-framework/component.yml beside release.yml, with one confirmation, and records skipped with the file named when the human on the loop declines."
status: "draft"
version: "0.1.0"
---
# Requirement: req-006 - consumer-migration

**Skill:** [spec-agent](../skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Source:** US-002
**Priority:** must-have

## User Story

As a consumer repo owner, I install a pack that has `release.yml` and no `component.yml`, so that my runs never count the pack as my source and still detect each pack update.

This requirement serves US-002 for a consumer who copies the new pack over an old one. The copy leaves the old `component.yml` beside `release.yml`, so the runs would still count the pack as source. The migration offers to remove that file. The brief's seventh acceptance criterion names this outcome.

## Functional Requirements

### The migration file

- Add `src/ravintio-framework/migrations/migrate-0.39.0-remove-pack-component-yml.md`. A consumer reads it at `ravintio-framework/migrations/`. The name follows `migrate-{version}-{slug}.md`, as `migrate-0.38.0-retire-fast-path-and-change-pipeline.md` does.
- The file follows the shape of the 0.38.0 migration. Its header lines are:
  - `**Target:**` names every downstream project that copied a 0.39.0 or later pack over an older one.
  - `**Applies to:** downstream`, under req-005.
  - `**Scope:**` names `ravintio-framework/component.yml`. It says the migration also reads `ravintio-framework/release.yml` and changes nothing there.
  - `**Safe to skip:**` is `Yes`. It says that step 1a warns at every session start while the file stays.
- The file has no `**May edit:**` line. The one path it touches sits under `ravintio-framework/`, inside the scope rule (migrator Hard Limit 1). It has no `**Applies when:**` line.
- It holds `Background`, `Migrator Instructions`, `Present Findings`, and `Record` sections.

### The migrator instructions

The instructions run these steps in order. Every step is safe to repeat. A second full run changes no file.

1. Read `ravintio-framework/release.yml`. If it doesn't exist, or its `version` is older than `0.39.0`, stop. Ask the human on the loop to refresh `ravintio-framework/` first. Record nothing, so the migration stays pending.
2. If `ravintio-framework/component.yml` doesn't exist as a file or a link, record `applied` with both counts at `0`.
3. If `ravintio-framework` itself is a link, don't show a delete command. Name `ravintio-framework/component.yml` for the human on the loop to check by hand. Count it in `corrections-skipped` and record `skipped` with the reason `refused`.
3a. If the project's `product.yml` lists `ravintio-framework/component.yml` as a component `path:`, don't offer the removal. `product-version.mjs` would then exit 2 with `component.yml not found` (risk R-013). Name the `product.yml` entry, and tell the human on the loop to remove it before the next run. `product.yml` sits outside the migrator scope rule (migrator Hard Limit 1), so the migrator never edits it. Count it in `corrections-skipped` and record `skipped` with the reason `listed in product.yml`.
4. Show the path and the `version` it reports. Say that it is left from an older pack, and that the pack now ships `release.yml` in its place. Ask the human on the loop to confirm its removal. This edit needs its own confirmation, and a batch `all` answer doesn't cover it. In `autonomous` run mode the migrator still asks, because the file sits in the consumer's repo.
5. On confirmation, the migrator doesn't delete the file itself. **Write** and **Edit** can't delete a file, and the Write-or-Edit rule (boot Hard Limit 8) names no delete route (backlog 0000366). The migrator shows this command, to run from the project root:

   `rm -- ravintio-framework/component.yml`

   In Claude Code the human on the loop can type `! rm -- ravintio-framework/component.yml`. If the path is a link, `rm` removes the link and never its target.
6. When the human on the loop says it's done, check that the path is gone, as a file or as a link.
   - If it is gone, count one correction in `corrections-applied` and record `applied`.
   - If it still exists, count it in `corrections-skipped` and record `skipped` with the reason `not removed`.
7. If the human on the loop declines, change no file. Count it in `corrections-skipped` and record `skipped` with the reason `declined`.
8. For every `skipped` outcome, the record body names `ravintio-framework/component.yml` and the reason. The migrator tells the human on the loop that step 1a warns at each session start until the file goes (req-003).

- The migration changes no other file. Every other pack file stays byte-identical.

### This source repo

- In this repo, `project-kind.mjs` prints `framework source` after req-001 moves the manifest. Step 1b then records `not applicable` with both counts at `0`, and the body says this project is the framework source.
- The migrator writes that record at P3, at `plan/_migrations/migrate-0.39.0-remove-pack-component-yml.md`. It follows the migrator text under `src/ravintio-framework/`, because this run's installed migrator is the 0.38.0 copy. P4 then finds a record for every migration, so `test-0000035-req-010-migration-records-for-this-repo.sh` stays green.
- The root release copy holds no `component.yml` after this run's P7, so the migration would also find nothing here.

### Tests

- New suite: `src/ravintio-framework/tests/test-0000041-req-006-consumer-migration.sh`. It holds the migration text checks, the scratch consumer runs, and the record check for this repo.
- These suites read every migration file and must stay green. Recheck them in P3:
  - `test-0000035-req-007-migration-run-state.sh`
  - `test-0000035-req-010-migration-records-for-this-repo.sh`
  - `test-0000039-req-009-migration-ordering-and-old-paths.sh`

Split step: keep, at three criteria. The one concern is the consumer's removal of the leftover manifest. The record in this repo exists only so the new file keeps the records suite green.

## Acceptance Criteria

- [ ] The migration file holds the `**Target:**`, `**Applies to:** downstream`, `**Scope:**`, and `**Safe to skip:**` lines and the four sections, with no `**May edit:**` line. The instructions name the `release.yml` version check and the `rm -- ravintio-framework/component.yml` command. They state that the migrator never deletes the file itself, and they name the `skipped` reasons `declined`, `not removed`, `refused`, and `listed in product.yml`. Verified by: integration
- [ ] In a scratch consumer repo with a 0.39.0 `release.yml` and a leftover `ravintio-framework/component.yml`, a migration run behaves as follows. Verified by: execution
  - With the removal confirmed and the fixture running the `rm`, the file is gone and the record is `applied` with `corrections-applied: 1`. Every other file stays byte-identical.
  - With the removal declined, the file stays byte-identical. The record is `skipped`, and its body names the file and the reason `declined`.
  - With `product.yml` listing `ravintio-framework/component.yml`, the run shows no `rm` command. The file and `product.yml` stay byte-identical, and the record is `skipped` with the reason `listed in product.yml`.
  - With no leftover file, the record is `applied` with both counts at `0`.
  - With no `release.yml`, the run writes no record.
  - A second run changes no file and leaves the record unchanged.
- [ ] This repo holds `plan/_migrations/migrate-0.39.0-remove-pack-component-yml.md` with `outcome: "not applicable"`, both counts at `0`, and a body that names the framework source. `test-0000035-req-010-migration-records-for-this-repo.sh` passes. Verified by: integration

## Dependencies

- req-005 (applies-to-header) adds the header, `project-kind.mjs`, and the Step 1b rule that gives this repo its `not applicable` record.
- req-002 (release-script) writes `release.yml`, which step 1 reads.
- req-003 (release-yml-readers) adds the step 1a warning for a leftover manifest, which step 8 names. It also moves the record's `framework-version` source to `release.yml`.
- req-001 (move-pack-to-src) moves the manifest to `src/ravintio-framework/component.yml`, so this repo reads as the framework source.
- The version bump to `0.39.0` belongs to the requirement that owns the release version.
- Backlog 0000366 covers the missing delete route. The migration routes the delete to the human on the loop, as the 0.38.0 migration does.
- Existing pattern: `migrate-0.38.0-retire-fast-path-and-change-pipeline.md` step 3 for the human-run delete and the path check afterwards.
