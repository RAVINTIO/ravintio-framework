---
title: "ADR 008: Consumer migration removes the leftover manifest"
summary: "A new 0.39.0 downstream migration offers to remove a leftover ravintio-framework/component.yml beside release.yml. The human on the loop confirms and runs the delete, and the migrator checks the result. A decline, a product.yml entry, or a linked folder records skipped with the file named."
status: "accepted"
version: "0.1.0"
---
# ADR-008 - Consumer migration removes the leftover manifest

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Component:** ravintio-framework
**Date:** 2026-11-07

## Context

From 0.39.0 the pack ships `release.yml` and no `component.yml` (ADR-002, ADR-004). A consumer who copies the new pack over an old one keeps the old `ravintio-framework/component.yml`. A copy adds and replaces files, but it never removes them. While that file stays, the consumer's runs still count the pack as source. Risk R-004 rates this likelihood high and impact medium.

The leftover file belongs to the consumer, not to the pack (ADR-005). Removing it is a destructive change to consumer-owned data.

Three constraints shape the removal:

- The Write-or-Edit rule (boot Hard Limit 8) names no delete route. **Write** and **Edit** can't delete a file (backlog 0000366).
- A consumer's `product.yml` may list `ravintio-framework/component.yml` as a component `path:`. The 0000040 vendored pack rule allows this. If the file goes, `product-version.mjs` exits 2 with `component.yml not found` (risk R-013).
- The migrator never edits `product.yml`, because it sits outside the scope rule (migrator Hard Limit 1).

The 0.38.0 migration already faced the same missing delete route for `plan/.fast-path-scope`. In its step 3 the human on the loop runs the delete, and the migrator checks the path afterwards.

## Decision

Add `src/ravintio-framework/migrations/migrate-0.39.0-remove-pack-component-yml.md`, as req-006 specifies. Consumers read it at `ravintio-framework/migrations/`.

**Header.** The migration carries `**Applies to:** downstream` (ADR-007, req-005). It has no `**May edit:**` line, because its one target sits under `ravintio-framework/`. Its `**Safe to skip:**` line is `Yes`, and it says that step 1a keeps warning.

**Steps.** The migrator runs the steps of req-006 in order. Each step is safe to repeat.

1. If `release.yml` is missing, breaks the format, or reports a version older than `0.39.0`, stop and record nothing.
2. If the leftover file doesn't exist, record `applied` with both counts at `0`.
3. If `ravintio-framework` itself is a link, show no command. Record `skipped` with the reason `refused`.
4. If `product.yml` lists the leftover file, offer no removal. Name the entry and ask the human on the loop to remove it. Record `skipped` with the reason `listed in product.yml` (step 3a, a P1 deviation for R-013).
5. Show the path and its `version`, and ask for one confirmation of the removal.

**Human gate.** The removal needs its own confirmation. A batch `all` answer doesn't cover it. In `autonomous` run mode the migrator still asks and waits, because the file belongs to the consumer. This matches the migrator rule for named-path edits.

**Delete route.** The migrator never deletes the file itself. On confirmation it shows `rm -- ravintio-framework/component.yml` to run from the project root. In Claude Code the human on the loop can type `! rm -- ravintio-framework/component.yml`. If the path is a link, `rm` removes the link and never its target. When the human on the loop says it's done, the migrator checks that the path is gone, as a file or as a link.

**Outcomes.** The migrator records each result as follows:

| Result | Outcome | Count | Reason in the body |
|--------|---------|-------|--------------------|
| No leftover file | `applied` | both `0` | none |
| Path gone after the human-run delete | `applied` | `corrections-applied: 1` | none |
| Path still present after the human-run delete | `skipped` | `corrections-skipped: 1` | `not removed` |
| Human on the loop declines | `skipped` | `corrections-skipped: 1` | `declined` |
| `ravintio-framework` is a link | `skipped` | `corrections-skipped: 1` | `refused` |
| `product.yml` lists the file | `skipped` | `corrections-skipped: 1` | `listed in product.yml` |

Every `skipped` body names `ravintio-framework/component.yml` and the reason. The migrator then says that step 1a warns at each session start until the file goes (ADR-004, req-003). The migration changes no other file.

**This repo.** The source-repo signal reads this repo as the framework source (ADR-007). Step 1b records `not applicable` with both counts at `0`, at P3.

Decision: a verified human-run delete counts in `corrections-applied` and records `applied`, as req-006 step 6 states. The 0.38.0 migration left its scope record delete out of every count. That delete didn't affect its outcome. Here the delete is the migration's only correction, so the count follows the path check the migrator ran.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| `setup.sh` and `setup.ps1` delete the file silently on copy | No migration and no prompt. Every consumer is clean after one setup run. | It deletes consumer-owned data with no confirmation (ADR-005). A consumer who copies the folder by hand without setup keeps the file. It also breaks `product-version.mjs` for a consumer whose `product.yml` lists the file (R-013). | Silent deletion of consumer data breaks the human gate the design requires. It also misses copy-only upgrades. |
| Leave the file and only warn at step 1a | No delete route needed, so backlog 0000366 doesn't arise. No risk to `product.yml`. | The consumer must find and remove the file with no guided step. R-004 is high likelihood, so many runs keep counting the pack as source. | The brief's seventh acceptance criterion asks for a migration that offers the removal. The warning stays as the backstop, not the fix. |
| The migrator deletes the file through `git rm` or `rm` in Bash | One step, with no hand-off to the human on the loop | Hard Limit 8 bans shell writes and names no delete route (backlog 0000366). The file may be untracked, so `git rm` can fail. | It would set a delete policy inside one migration. Backlog 0000366 needs its own design. |
| The migrator empties the file with **Write** | Uses a sanctioned tool | An empty `component.yml` still sits beside `release.yml`. Step 1a and the project-kind readers would still see a file. | It doesn't remove the file, so the runs still misread the pack. |
| The migrator also removes the `product.yml` entry | Clears R-013 in the same run | `product.yml` sits outside the migrator scope rule (migrator Hard Limit 1). The entry is the consumer's own data. | The migrator names the entry and records `skipped`. The human on the loop removes it and re-runs. |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Gains the 0.39.0 migration file and the suite `test-0000041-req-006-consumer-migration.sh`. This repo gains a `not applicable` record at P3. |
| setup-hook-integration | No change. Setup keeps copying files without deleting any. |

## Consequences

**Positive:**
- A consumer who upgrades by copy gets one guided, confirmed step to remove the leftover manifest. This mitigates R-004 and meets req-006.
- The delete follows the 0.38.0 precedent, so the migration sets no new delete policy before backlog 0000366 closes.
- The `product.yml` check stops the migration from breaking `product-version.mjs` (R-013).
- The `refused` path and `rm --` keep the delete inside the consumer's repo even when a link is present.

**Negative:**
- The delete needs a hand-off. The human on the loop runs a shell command, and an `autonomous` run pauses to ask.
- A consumer whose `product.yml` lists the file must edit `product.yml` and run the migration again. The first run records `skipped`.
- After a `skipped` outcome the migration is no longer pending. Only the step 1a warning reminds the consumer, at every session start (ADR-004).

**Risks:**
- The human on the loop runs `rm` from the wrong folder. The path check after the delete then records `skipped` with `not removed`, so the record stays accurate.
- A consumer lists the file in `product.yml` under a path spelling that the check doesn't match. The removal then proceeds and R-013 recurs. req-006 tests cover the plain `ravintio-framework/component.yml` spelling only.
- Backlog 0000366 later sets a delete route. This migration then still asks for a human-run delete. Released migration files never change, so the text stays as written.

## Related ADRs

- ADR-002 - depends-on: moving the pack source to `src/` is why the release copy drops `component.yml`.
- ADR-004 - depends-on: the step 1a warning for a leftover manifest is the backstop after a `skipped` outcome.
- ADR-005 - depends-on: consumers own their `component.yml`, so the removal is human-gated.
- ADR-006 - related-to: `product.yml` decides where the manifest lives, which is why step 3a reads it.
- ADR-007 - depends-on: the `**Applies to:** downstream` header and the source-repo signal give this repo its `not applicable` record.
- ADR-009 - related-to: the new suite reads the pack under `src/` through the shared resolver.

## Supersedes

- None

## Superseded By

- None
