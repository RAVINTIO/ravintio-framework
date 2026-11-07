---
title: "ADR 006: Migrations may name extra paths, each edit confirmed"
summary: "The migrator scope rule (migrator Hard Limit 1) widens. A migration may list extra paths on a May edit line, and the human on the loop confirms each edit to them. src/ stays closed. The 0.38.0 migration names only .github/workflows/ravintio.yml, so it can remove the Fast Path exemption block from a consumer CI file."
status: "accepted"
version: "0.1.0"
---
# ADR-006 - Migrations may name extra paths, each edit confirmed

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Component:** ravintio-framework
**Date:** 2026-11-06

## Context

The migrator scope rule (migrator Hard Limit 1) in `ravintio-framework/skills/ravintio-migrator/SKILL.md` reads today:

> Never modify files in `src/`: migrations apply to `plan/`, `docs/`, and `ravintio-framework/` only.

Feature 0000040 retires Fast Path and the Change Pipeline (ADR-002). Setup in 0.37.x shipped a Fast Path exemption block in the consumer CI file. That block lets a `fix(fast-path)` commit pass the `validate-branch` check with no feature record. Req-003 removes the block from the template at `ravintio-framework/hooks/ravintio.yml` and from this repo's CI file.

A consumer's `.github/workflows/ravintio.yml` keeps the block after an upgrade. Setup copies the CI template only when the file is absent (`setup.sh` lines 763 to 771). Setup keeps that copy-if-absent rule, so a setup re-run can't fix the file. Backlog 0000364 records the wider gap: no later template change reaches an installed consumer.

The CI file sits outside `plan/`, `docs/`, and `ravintio-framework/`. Under the present rule, no migration may edit it. The 0.37.0 rename migration met the same file. It avoided the rule because the human on the loop runs a helper script by hand, and the helper rewrites the workflow.

The new migration `migrate-0.38.0-retire-fast-path-and-change-pipeline.md` (req-005) runs these steps in order:

1. It confirms that the pack reports `0.38.0` or later.
2. It warns on an unfinished Change Pipeline or Fast Path run in `plan/current/`. The warning changes no file.
3. It asks the human on the loop to delete a leftover `plan/.fast-path-scope`, then checks that the path is gone.
4. It removes the exemption block from `.github/workflows/ravintio.yml` on confirmation.
5. It asks for a setup re-run for each tool the project uses.

Step 4 needs a wider scope rule. The decision has a security trade-off, because the CI file enforces the branch rules on a consumer repo.

## Decision

1. Widen the scope rule (migrator Hard Limit 1). A migration may name extra paths on a `**May edit:**` line near the top of the file. The migrator may then edit those paths as well as `plan/`, `docs/`, and `ravintio-framework/`.
2. Each edit to an extra path needs its own confirmation from the human on the loop. A batch `all` answer doesn't cover it. In `autonomous` run mode the migrator still asks, because the edit changes a file the consumer owns.
3. The migrator checks each extra path before it reads or edits it. It refuses these paths, reports each refusal, and edits nothing there:
   - an absolute path
   - a path with a `..` part
   - a path whose target or any parent is a symbolic link
   - a path under `src/`, even when a migration names it
4. `src/` stays closed to every migration.
5. Widen the `skipped` outcome in `## Run records`. It also covers an edit to a named path that the human on the loop declined or that the migrator couldn't match.
6. The 0.38.0 migration's `**May edit:**` line names `.github/workflows/ravintio.yml` and no other path. It quotes the 0.37.x exemption block verbatim and matches it after trimming trailing whitespace. It removes the block only when the block matches once.
7. If the block doesn't match once, or the human on the loop declines, the migration edits nothing in the CI file. The migrator then does these things:
   - It names the file and the line numbers to delete by hand.
   - It counts the edit in `corrections-skipped`.
   - It records `skipped`, and the body names the reason as `declined` or `no match`.
8. Every step in the 0.38.0 migration is safe to repeat. A deleted scope record, a removed block, and an absent CI file each count as done. A second full run changes no file.
9. Released migration files never change. The `**May edit:**` list of a released migration stays fixed, so no later release can widen what an earlier migration may edit.
10. Setup keeps its copy-if-absent rule for the CI file. This ADR doesn't decide how later template changes reach a consumer. Backlog 0000364 holds that question.

### What the widening allows, and what limits it

The widening lets a migration change a consumer-owned file outside the framework folder. A CI file is a strong target. An edit to it can weaken or remove a branch check on the consumer repo. A bad or tampered migration could use the route to do that.

These limits bound the route:

- A migration must name each path in advance. The migrator never edits a path the migration file doesn't list.
- The human on the loop sees and confirms each edit. No batch answer and no run mode skips that prompt.
- The path checks refuse escapes from the project root and edits through links.
- `src/` stays closed, so no migration touches application code.
- A released migration's path list can't grow, because released migration files never change.
- Only the 0.38.0 migration names an extra path, and its one edit removes lines. It makes the consumer's check stricter.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep the rule and only tell the human on the loop which lines to delete | No change to the migrator scope | The exemption stays in every repo where the human misses or defers the notice. A retired track keeps a weaker route through CI. | The feature goal is that nothing stale offers a weaker route |
| A helper script that the human on the loop runs by hand, as in 0.37.0 | The migrator scope stays as it is | A new script to write, test, and keep on both shells for one block removal. Boot Hard Limit 8 would need a new sanctioned script. | The cost is high for removing about ten lines, and the human still confirms the same edit |
| Setup overwrites the consumer CI file with the template | Every template change reaches the consumer | Setup discards the consumer's own CI edits with no prompt | The design keeps copy-if-absent, and backlog 0000364 needs its own decision about consumer edits |
| Open every path outside `src/` to every migration | No `**May edit:**` line to maintain | Any migration could edit any consumer file, such as hooks or secrets config | The route has no bound, and the human on the loop can't see the reach before a run |
| Named paths, with a batch `all` answer allowed | Fewer prompts | One answer could approve a CI edit along with routine text fixes | A CI edit changes enforcement, so it needs its own prompt |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | The migrator `SKILL.md` gains the `**May edit:**` rule, the per-edit confirmation, the path refusals, and the wider `skipped` outcome. The pack gains the 0.38.0 migration and `tests/test-0000040-req-005-consumer-migration.sh`. These suites read the migrator text and must stay green: `test-0000005-framework-governance.sh`, `test-0000035-req-007-migration-run-state.sh`, `test-0000036-req-005-hard-limits-cited-by-name.sh`, and `test-0000039-req-009-migration-ordering-and-old-paths.sh`. |
| Consumer repos | The human on the loop deletes `plan/.fast-path-scope` when the migration asks. On confirmation, the migration removes the exemption block from `.github/workflows/ravintio.yml`. The rest of the CI file stays byte-identical. |

## Consequences

**Positive:**
- An upgraded consumer loses the Fast Path exemption in CI, so a `fix(fast-path)` commit no longer passes `validate-branch` without a record.
- The human on the loop sees each edit to a consumer-owned file before it lands.
- A later migration that needs a file outside the framework folder has a bounded route, with no new script.
- A declined or unmatched edit leaves a `skipped` record and a list of lines to delete. The gap stays visible.

**Negative:**
- The migrator can now change a consumer CI file, which it never could before. The scope rule is harder to reason about.
- In `autonomous` run mode the CI edit waits for a human answer, so the migration can't finish unattended.
- A consumer's CI file keeps its old `src/` check without the source folder rule from ADR-003. The migration removes only the exemption block.
- The migrator text grows, and four existing suites that read it need a recheck in P3.

**Risks:**
- A consumer who edited the block gets `no match`. The exemption then stays until they delete the lines by hand.
- A human on the loop may confirm a CI edit without reading it. The prompt shows the exact lines to limit that risk.
- A future migration may name a sensitive path. Per-edit confirmation is then the only control. The P2 design critic and the P5 security review should check each new `**May edit:**` line.
- Boot Hard Limit 8 allows file changes only through **Write** or **Edit**, and neither deletes a file. So the migrator doesn't delete `plan/.fast-path-scope` itself. It asks the human on the loop to run the delete, then checks that the path is gone (req-005, P2 revision). Backlog 0000366 covers the missing delete route.

## What P5 changed (governing)

- Decisions 3, 5, and 7 gain two reasons for `skipped`, with the same handling as `declined` and `no match`:
  - `blocked`: a hook blocks the named-path edit. For example, `gate-write` exits 2 in a consumer with no confirmed design. The migrator shows the hook's block reason.
  - `refused`: the named path fails a check from decision 3. The migrator edits nothing there.
- In each case the migrator names the file and the lines to delete by hand. It counts the edit in `corrections-skipped`, and the record body names the reason. The migrator never records `applied` for a named-path edit it didn't make.
- Migration step 3 checks whether `plan` itself is a symbolic link before it shows `rm -- plan/.fast-path-scope`. If it is, the migrator doesn't show the command. It names the path for the human on the loop to check by hand.
- Reason: the P5 security review found that a hooked consumer's `gate-write` blocks the CI edit, and step 7 then recorded `applied`. Defect verdict 001 placed this fix within the confirmed design. How the removal reaches a hooked consumer stays an open design question for the human on the loop.

## Related ADRs

- ADR-002 - depends-on: retiring Fast Path is why the exemption block and the scope record must go.
- ADR-003 - related-to: the source folder rule lands in the template and this repo's CI file. This migration doesn't add it to a consumer's file.
- ADR-005 - related-to: the setup re-run this migration asks for uses the retired list to remove installed track copies.
- 0000035 ADR 015 - related-to: migration files never move. This ADR adds that released migration files never change, so a path list stays fixed.
- 0000035 ADR 016 - extends: the `skipped` outcome now also covers a declined or unmatched edit to a named path.
- 0000035 ADR 017 - related-to: the migrator stays the only writer of `plan/_migrations/`.
- 0000035 ADR 018 - related-to: a re-run with the same outcome leaves the record unchanged, which keeps the migration safe to repeat.
- 0000035 ADR 019 - related-to: findings in an `autonomous` run wait for the human on the loop. This ADR applies the same rule to each named-path edit.

## Supersedes

- None

## Superseded By

- None
