---
title: "Requirement: req-005 - applies-to-header"
summary: "A migration may declare Applies to: framework source, downstream, or all. A script decides the project kind from the source-repo signal, and the migrator records not applicable with the reason when the kinds differ."
status: "draft"
version: "0.1.0"
---
# Requirement: req-005 - applies-to-header

**Skill:** [spec-agent](../../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Source:** US-003, backlog 0000378 and 0000136
**Priority:** must-have. US-003 is should-have, but must-have req-002 and req-008 import `project-kind.mjs` from this requirement.

## User Story

As a framework maintainer, I see migrations declare which kind of project they apply to, so that the source repo skips consumer-only migrations and consumers skip source-only ones.

## Functional Requirements

All paths below use the post-move layout. A consumer runs the same files at `ravintio-framework/`.

### The source-repo signal

- A new script, `src/ravintio-framework/scripts/project-kind.mjs`, decides the project kind. The migrator runs it as `node ravintio-framework/scripts/project-kind.mjs`. It writes no file, so the Write-or-Edit rule (boot Hard Limit 8) needs no new sanction.
- The script prints `framework source` when all of these hold at the project root:
  - `product.yml` exists as a regular file, not a link.
  - Its `components[]` list holds an entry with `id` `ravintio-framework` and `path` `src/ravintio-framework/component.yml`.
  - `src/ravintio-framework/component.yml` exists as a regular file, and no part of that path is a link.
- In every other case it prints `downstream`. It prints the failed condition on stderr. A missing, unreadable, or malformed `product.yml` reads as `downstream`.
- The script exits 0 when it prints a kind. It exits 2 only for a bad argument. It accepts `--root <dir>`, with the current folder as the default.
- The script exports one function, `projectKind(root)`, that returns the kind and the reason. req-002's release script imports it, so the signal has one owner.
- It parses `product.yml` line by line, in the constrained shape that `product-version.mjs` already reads. It adds no YAML dependency.

### The header

- A migration may carry one `**Applies to:**` line near the top, beside `**Target:**`. Its value is `framework source`, `downstream`, or `all`.
- An absent line reads as `all`. Released migration files never change, so each one keeps its behaviour.
- Released migrations with no header can still need a project kind. The migrator `SKILL.md` holds a `Released migrations by project kind` table for them. Its one row maps `retroactive-release-tags.md` to `framework source` (backlog 0000136). For a file with no header, the migrator reads the table first, and a file in neither reads as `all`. The released file stays byte-identical.
- The migrator `SKILL.md` documents the line and its three values. The pack holds no migration template, so the migrator is the one owner of the allowed values. Other texts point to it.

### The migrator rule

- In `src/ravintio-framework/skills/ravintio-migrator/SKILL.md`, Step 1b becomes the project-kind check. It runs in this order:
  1. Run `project-kind.mjs` to find the project kind. If the script fails to run, stop, report the error, and record nothing, so the migration stays pending.
  2. Read the `**Applies to:**` line. If its value is not one of the three, stop, report the line, and record nothing.
  3. If the value is `framework source` and the kind is `downstream`, or the value is `downstream` and the kind is `framework source`, skip Steps 2 to 4. Record `not applicable` with both counts at `0`. The body names the project kind and the header value.
  4. If the value is `all` or matches the kind, read the `**Target:**` line as today.
- The `**Target:**` check keeps its released behaviour. It takes the project kind from the same script, in place of the `id: "ravintio-framework"` test. In this repo both tests agree, so its records don't change.
- The migrator reports each `not applicable` record and its reason to the human on the loop. That meets the design's observability line.
- The rule narrows 0000035 ADR 019 for migrations that carry the header. Existing records in `plan/_migrations/` stay as written. P2 records the narrowing, and P6 updates the 0000035 ADR 019 entry in `docs/decisions-index.md`.
- The migrator never deletes, rewrites, or seeds a record because of this rule.

### Tests

- New suite: `src/ravintio-framework/tests/test-0000041-req-005-applies-to-header.sh`. Its `project-kind.mjs` cases come first in P3, before the req-008 resolver exists, so they find the pack from the suite's own folder. The suite moves onto the resolver when req-005's migrator rule lands (execution plan, build order).
- These suites read the migrator text and must stay green. Recheck them in P3:
  - `test-0000039-req-009-migration-ordering-and-old-paths.sh` (the `Applies when` checks)
  - `test-0000035-req-007-migration-run-state.sh`
  - `test-0000035-req-010-migration-records-for-this-repo.sh`
  - `test-0000040-req-005-consumer-migration.sh`

Split step: keep, at three criteria. The one concern is the skip by project kind. The script and the header have no use without the migrator rule.

## Acceptance Criteria

- [ ] `project-kind.mjs` prints `framework source` for a scratch root that meets all three conditions. It prints `downstream` with a reason for each of these: no `product.yml`, no `ravintio-framework` entry, a different `path`, a missing manifest, a linked `product.yml`, and a linked `src/ravintio-framework`. It exits 0 in each case and 2 for an unknown argument. Verified by: unit
- [ ] The migrator `SKILL.md` documents `**Applies to:**` with its three values and the absent-reads-as-`all` rule. Step 1b runs `project-kind.mjs`, records `not applicable` with the kind and the header value in the body, and stops with no record for an unknown value. The `**Target:**` check reads the same script. Verified by: integration
- [ ] In a scratch framework-source repo and a scratch consumer repo, the Step 1b rule behaves as follows. A `downstream` migration records `not applicable` in the source repo. A `framework source` migration records `not applicable` in the consumer. A migration with no header or `all` passes Step 1b in both. `retroactive-release-tags.md` records `not applicable` in the consumer through the table, and passes Step 1b in the source repo. Every released migration file matches `v0.38.0` byte for byte, and every existing record in this repo's `plan/_migrations/` is unchanged. Verified by: execution

## Dependencies

- req-001 (move-pack-to-src) puts `src/ravintio-framework/component.yml` in place and points `product.yml` at it. Before the move, this repo reads as `downstream`.
- req-002 (release-script) imports `projectKind(root)` to refuse a run outside the source repo.
- req-003 (release-yml-readers) also edits the migrator `SKILL.md`, for the record's `framework-version` source. The two edits touch different sections.
- req-006 (consumer-migration) is the first migration that carries the header.
- 0000035 ADR 016 to ADR 019 define the records, the outcomes, and the pending rule this rule writes through.
