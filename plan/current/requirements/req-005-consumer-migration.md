---
title: "Requirement: req-005 - consumer-migration"
summary: "A 0.38.0 migration removes a leftover Fast Path scope record and the CI exemption block from a consumer repo, and the migrator gains a confirmed route to edit a named path outside plan/, docs/, and the pack."
status: "draft"
version: "0.1.0"
---
# Requirement: req-005 - consumer-migration

**Skill:** [spec-agent](../skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Source:** US-003
**Priority:** must-have

## User Story

As a consumer repo owner, I upgrade and lose any leftover scope record and the CI exemption, with a notice, so that nothing stale offers a weaker route.

## Functional Requirements

### The migration

- Add `ravintio-framework/migrations/migrate-0.38.0-retire-fast-path-and-change-pipeline.md`. It follows the shape of `migrate-0.34.0-rerun-setup.md` and `migrate-0.37.0-ravintio-rename.md`:
  - a `**Target:**` line that names every project, the framework source included
  - a `**Scope:**` line that names `plan/.fast-path-scope` and `.github/workflows/ravintio.yml`
  - a `**May edit:**` line that names `.github/workflows/ravintio.yml` and no other path
  - a `**Safe to skip:**` line set to `No`, because a consumer's old CI file keeps the exemption until this migration runs
  - `Background`, `Migrator Instructions`, `Present Findings`, and `Record` sections
- The file has no `**Applies when:**` line. Every project runs it.
- The migrator instructions run these steps in order:
  1. Confirm that `ravintio-framework/component.yml` reports `0.38.0` or later. If it's older, stop and ask the human on the loop to refresh `ravintio-framework/` first.
  2. Check `plan/current/` for an unfinished run of a retired track. A Fast Path run leaves `plan/.fast-path-scope`. A Change Pipeline run leaves `plan/current/change-summary.md`. If either exists, warn that the track is gone. Tell the human on the loop to restart the work on the Feature Pipeline. The warning changes no file.
  3. If `plan/.fast-path-scope` exists, ask the human on the loop to confirm its deletion, then delete it. If it is a symbolic link, delete the link and never its target.
  4. Read `.github/workflows/ravintio.yml`. Look for the exemption block that setup shipped in 0.37.x. The migration file quotes that block verbatim, from the `# Fast Path exemption:` comment to the `fi` that closes the `FAST_PATH_COUNT` test. The match compares lines after trimming trailing whitespace.
  5. If the block matches once, show it and ask the human on the loop to confirm its removal. On confirmation, remove those lines and nothing else.
  6. Tell the human on the loop that Fast Path and the Change Pipeline are gone, and that every change now runs the Feature Pipeline. Ask for a setup re-run for each tool the project uses, so setup removes the installed copies (req-004).
- Every step is safe to repeat. A deleted scope record, a removed block, and an absent CI file each count as done. An interrupted run applies again cleanly, and a second full run changes no file.
- P2 revision for step 3, which governs it: the migrator doesn't delete the scope record itself, because boot Hard Limit 8 names no delete route (backlog 0000366). It shows the human on the loop the command `rm -- plan/.fast-path-scope` and asks them to run it. In Claude Code they can type `! rm -- plan/.fast-path-scope`. The migrator then checks that the path is gone. If the path still exists, the migrator names it in the record body, and the outcome doesn't change. The gates ignore the file under req-002, so a leftover record admits nothing.
- If the CI file holds `fix\(fast-path\)` or `FAST_PATH_COUNT` but the block doesn't match once, the migration edits nothing in that file. The same holds when the human on the loop declines. In both cases the migrator does these things:
  - It names the file and the line numbers to delete by hand.
  - It counts the edit in `corrections-skipped`.
  - It records the outcome `skipped`. The record body names the reason as `declined` or `no match`.
  - It never records `applied` with `corrections-skipped: 0` for this case.
- Setup keeps its copy-if-absent rule for the CI file (`setup.sh` lines 763 to 771). The migration removes only the exemption block. The consumer's CI file keeps its old `src/` check, without the source folder rule from req-003. The notice says so and names `ravintio-framework/hooks/ravintio.yml` as the template to compare against. Backlog 0000364 covers that gap.
- This repo runs the migration at the end-of-P6 setup run. By then req-003 has removed the block here, and no scope record exists. So the migration finds nothing and records `applied` with both counts at `0`. `test-0000035-req-010-migration-records-for-this-repo.sh` needs a record for every migration, so this record keeps it green.

### The migrator scope rule

- Widen the scope rule (migrator Hard Limit 1) in `ravintio-framework/skills/ravintio-migrator/SKILL.md`. A migration may name extra paths on its `**May edit:**` line. The migrator may then edit those paths as well as `plan/`, `docs/`, and `ravintio-framework/`.
- Each edit to an extra path needs its own confirmation from the human on the loop. A batch `all` answer doesn't cover it. In `autonomous` run mode the migrator still asks, because the edit changes a file the consumer owns.
- An extra path must be relative to the project root, with no `..` part. The migrator refuses an absolute path, a `..` part, and a path whose target or parent is a symbolic link. It reports each refusal and edits nothing there.
- `src/` stays closed. The migrator refuses an extra path under `src/`, even when a migration names it.
- Widen the `skipped` outcome in `## Run records` to cover an edit to a named path that the human on the loop declined or the migrator couldn't match.
- These suites read the migrator text and must stay green. Recheck them in P3: `test-0000005-framework-governance.sh`, `test-0000035-req-007-migration-run-state.sh`, `test-0000036-req-005-hard-limits-cited-by-name.sh`, and `test-0000039-req-009-migration-ordering-and-old-paths.sh`.
- Split step: keep, at three criteria. The one concern is the consumer's upgrade through this migration. The scope rule widening exists only so this migration can edit the CI file. Without it, step 5 breaks the scope rule (migrator Hard Limit 1). No other migration names an extra path.

- Approach 2 iteration 1 revision: the new suite is `ravintio-framework/tests/test-0000040-req-005-consumer-migration.sh`. It holds the migration text checks, the scratch consumer run, and the migrator rule checks.

## Acceptance Criteria

- [ ] The migration file holds the `**Target:**`, `**Scope:**`, `**May edit:**`, and `**Safe to skip:**` lines and the four sections. It quotes the exemption block verbatim. That block matches a fixture copy of the 0.37.2 `hooks/ravintio.yml` once, and removing it leaves no `fix\(fast-path\)` or `FAST_PATH_COUNT` text. The instructions name the unfinished-run warning, the setup re-run, and the `skipped` record for a declined or unmatched edit. Verified by: integration
- [ ] In a scratch consumer repo on 0.37.2, with `plan/.fast-path-scope` and `plan/current/change-summary.md`, a migrator run behaves as follows. Verified by: execution
  - With every confirmation given, it warns about the unfinished run and deletes the scope record. It removes the block and leaves the rest of the CI file byte-identical. It asks for a setup re-run, and records `applied`.
  - A second run changes no file and leaves the record unchanged.
  - A run where the human on the loop declines the CI edit leaves the CI file byte-identical. It names the file and the lines, and records `skipped` with the reason `declined`.
  - A run on an edited block does the same with the reason `no match`.
- [ ] The migrator `SKILL.md` states the scope rule (migrator Hard Limit 1) with the `**May edit:**` line. It also states the per-edit confirmation, the refusal of `src/`, absolute, `..`, and linked paths, and the widened `skipped` outcome. Verified by: integration

## Dependencies

- req-003 (no-commit-subject-exemption) removes the block from the template and from this repo's CI file. The block this migration quotes is the text req-003 removes.
- req-002 (gates-ignore-scope-record) makes a leftover `plan/.fast-path-scope` admit nothing. This migration then deletes the file.
- req-004 (remove-track-files) adds the retired list to setup. The setup re-run this migration asks for removes the installed track copies.
- req-007 (docs-and-adr-supersede) bumps the version to `0.38.0`, which step 1 checks.
- Existing pattern: `migrate-0.34.0-rerun-setup.md` for the setup re-run and the version check, and `migrate-0.37.0-ravintio-rename.md` for an edit to `.github/workflows/ravintio.yml`.
- Backlog 0000364 covers a consumer CI file that never receives template changes after its first install.
