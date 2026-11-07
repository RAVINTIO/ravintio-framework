---
title: "ADR 007: Applies to header and source-repo signal"
summary: "A repo is the framework source when product.yml lists ravintio-framework at src/ravintio-framework/component.yml and that file exists. project-kind.mjs owns that signal. A migration may carry Applies to: framework source, downstream, or all, and an absent line reads as all. The migrator records not applicable with the reason when the kinds differ. A migrator table maps the released retroactive-release-tags.md to framework source. The rule narrows 0000035 ADR 019 for future migrations and leaves existing records as written."
status: "accepted"
version: "0.1.0"
---
# ADR-007 - Applies to header and source-repo signal

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Component:** ravintio-framework
**Date:** 2026-11-07

## Context

Every migration runs in every project today. Some migrations fit only one kind of project:

- `retroactive-release-tags.md` tags this repo's history. A consumer has no such history (backlog 0000136).
- The 0.39.0 consumer migration removes a consumer's leftover `ravintio-framework/component.yml` (req-006, ADR-008). The source repo must never run it.

The migrator has one kind test today. Step 1b reads the `**Target:**` line, and it treats the repo as the framework source when the root `product.yml` has `id: "ravintio-framework"`. A consumer can copy that id, and the `**Target:**` line is free text. The migrator can't read it as a fixed value (backlog 0000378).

0000035 ADR 019 says that each downstream scan decides a migration's outcome. Its only skip without a scan is the target check for downstream-only migrations in this repo.

Released migration files never change (design constraint). `retroactive-release-tags.md` has no header, so a new header alone can't mark it.

After ADR-002, the pack source lives at `src/ravintio-framework/` with its `component.yml`. The root copy holds no `component.yml` once the release script runs (ADR-003). That gives a signal a consumer meets only by building the same layout on purpose.

## Decision

1. A repo is the framework source when all of these hold at the project root:
   - `product.yml` exists as a regular file, not a link.
   - Its `components[]` list holds an entry with `id` `ravintio-framework` and `path` `src/ravintio-framework/component.yml`.
   - `src/ravintio-framework/component.yml` exists as a regular file, and no part of that path is a link.

   Every other repo is `downstream`. A missing, unreadable, or malformed `product.yml` reads as `downstream` (req-005).
2. A new read-only script, `src/ravintio-framework/scripts/project-kind.mjs`, owns the signal. It prints the kind and gives the failed condition on stderr. It exports `projectKind(root)`, which the release script imports to refuse a run outside the source repo (req-002, ADR-003). It writes no file, so the Write-or-Edit rule (boot Hard Limit 8) needs no new sanction.
3. A migration may carry one `**Applies to:**` line beside `**Target:**`. Its value is `framework source`, `downstream`, or `all`. An absent line reads as `all`, so every released migration keeps its behaviour. The migrator `SKILL.md` owns the three values.
4. The migrator `SKILL.md` holds a `Released migrations by project kind` table for released files with no header. Its one row maps `retroactive-release-tags.md` to `framework source`. The migrator reads the header first, then the table. A file in neither reads as `all`. The released file stays byte-identical (P1 deviation, req-005).
5. Step 1b becomes the project-kind check, in this order:
   1. Run `project-kind.mjs`. If it fails to run, stop and record nothing, so the migration stays pending.
   2. Read the header value. If the value is not one of the three, stop and record nothing.
   3. If the value names the other kind, skip Steps 2 to 4. Record `not applicable` with both counts at `0`. The body names the project kind and the header value.
   4. If the value is `all` or matches the kind, run the `**Target:**` check as today.
6. The `**Target:**` check takes the project kind from the same script, in place of the `id: "ravintio-framework"` test. Both tests agree in this repo after req-001 points `product.yml` at `src/ravintio-framework/component.yml`, so its records don't change.
7. The migrator reports each `not applicable` record and its reason to the human on the loop. That meets the design's observability line.
8. This rule narrows 0000035 ADR 019 for migrations that carry the header or a table row. A header or a row can now skip a downstream scan. Every existing record in `plan/_migrations/` stays as written, and the migrator never deletes, rewrites, or seeds a record because of this rule. P6 updates the 0000035 ADR 019 entry in `docs/decisions-index.md`.
9. Build order: `project-kind.mjs` and its cases land in P3 before the suite resolver (ADR-009). The resolver imports the script, so the script comes first. Until the resolver exists, the req-005 suite finds the pack from its own folder. It moves onto the resolver when the Step 1b rule lands (P1 decisions in `build-log.md`).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Detect the source repo by the presence of `src/ravintio-framework/` alone | One check, no `product.yml` parse | A consumer that keeps a pack copy or a fork under `src/` reads as the source. It then skips every downstream migration and lets the release script run (R-014). | The signal needs two facts that only the source repo declares together. |
| Keep the `id: "ravintio-framework"` test in `product.yml` | No new script | A consumer can copy the id. The test says nothing about where the pack source lives (backlog 0000378). | It names the product, not the layout that makes a repo the source. |
| Edit released migrations to add the header | Every migration declares its kind in one place, with no table | Breaks the design constraint that released migrations never change. Consumers would see a changed file as a pack update, and checksums would no longer match the tag. | The constraint holds. The table covers the one released file that needs a kind. |
| A separate migrations folder per project kind | The folder states the kind, with no header to parse | Moves released files, which breaks the same constraint. It also needs a third folder for `all`, and every migration reader must learn the new layout. | The header leaves the folder and every released path unchanged. |
| Read the kind from the free-text `**Target:**` line | No new header | The line is prose, so the migrator must guess its meaning. A guess can skip a migration that applies. | A fixed set of three values gives one answer per file. |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Gains `scripts/project-kind.mjs`. The migrator `SKILL.md` gains the header rule, the table, and the new Step 1b. The `**Target:**` check reads the script. A new suite covers the script and the rule (req-005). |
| setup-hook-integration | No change. |

## Consequences

**Positive:**
- A consumer no longer runs `retroactive-release-tags.md` against its own history, which closes backlog 0000136.
- The 0.39.0 consumer migration can carry `**Applies to:** downstream`, so the source repo skips it with a stated reason (ADR-008, req-006).
- One script owns the source-repo signal. The migrator, the release script (req-002), and the resolver (ADR-009) read the same answer, which closes backlog 0000378.
- Every released migration file stays byte-identical, and every existing record stays as written.

**Negative:**
- The migrator `SKILL.md` now holds two ways to state a kind: the header and the table. A maintainer must check both to know how a released file behaves.
- A future released migration that ships with the wrong header can't change. Only a new table row can correct it, so the table can grow.
- The signal depends on `product.yml`. A source repo with a broken `product.yml` reads as `downstream` and runs consumer-only migrations until someone fixes the file.
- Until req-001's `product.yml` edit lands, this repo reads as `downstream`. The Step 1b rule must not run here before that edit.

**Risks:**
- A consumer that lists `src/ravintio-framework/component.yml` in its `product.yml` and holds that file reads as the source (R-014). The two-fact signal keeps the likelihood low. Tests cover a consumer, the source repo, and a repo with only one fact.
- A link at `product.yml` or under `src/ravintio-framework/` could fake the signal. The script refuses links on both paths, and req-005 AC1 tests both cases.
- A script failure could read as a kind and skip a migration. Step 1b stops with no record on failure, so the migration stays pending.

## Related ADRs

- ADR-002 - depends-on: the pack source at `src/ravintio-framework/` gives the signal its path.
- ADR-003 - related-to: the release script imports `projectKind(root)` to refuse a run outside the source repo.
- ADR-006 - related-to: both read component manifest paths from `product.yml`.
- ADR-008 - related-to: the 0.39.0 consumer migration is the first file that carries the header.
- ADR-009 - related-to: the resolver imports `project-kind.mjs`, so the script lands first.
- 0000035 ADR 019 - extends: narrows the scan-decides rule for migrations with a header or a table row.

## Supersedes

- None. This ADR narrows 0000035 ADR 019 and leaves its records in place.

## Superseded By

- None
