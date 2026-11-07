---
title: "Feature Brief - Pack source under src"
summary: "The business case, scope, and product requirements for the feature."
status: "draft"
version: "0.1.0"
---
# Feature Brief - Pack source under src

**Feature ID:** 0000041-pack-source-under-src

> The orchestrator drafted this brief from backlog 0000361 and the human on the loop's P0 answers. Folded-in entries: 0000061, 0000378, 0000136, 0000368, and 0000181.

## Business Goal

Consumers copy `ravintio-framework/` into their repo root, and the copy carries the pack's `component.yml`. Consumer runs then count the pack as their own source, bump its version, and can tag from it. Move the pack source and its manifest under `src/`, and keep a root copy that holds only the last release, with no manifest. A copied pack then never shows up as product source in any repo that uses it.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Pack source under `src/` | US-001: As a framework maintainer, I change the pack under `src/ravintio-framework/` while this repo runs on the last release at the root, so that a broken change can't break the run that builds it. | must-have | 1 |
| Release with no manifest | US-002: As a consumer repo owner, I install a pack that has `release.yml` and no `component.yml`, so that my runs never count the pack as my source and still detect each pack update. | must-have | 1 |
| Migrations by project kind | US-003: As a framework maintainer, I see migrations declare which kind of project they apply to, so that the source repo skips consumer-only migrations and consumers skip source-only ones. | should-have | 1 |

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| `ravintio-framework` | component-pack | existing, moves to `src/ravintio-framework/` | Standards, skills, hooks, scripts, and setup for the pipeline |
| `setup-hook-integration` | component-pack | existing | Setup scripts and hook wiring. Its manifest stays at `src/setup-hook-integration/`, and its code paths move into `src/ravintio-framework/`. |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| `src/ravintio-framework/` | `ravintio-framework` | none |
| Root `ravintio-framework/` release copy and its `release.yml` | the release script, run at P7 | every session in this repo, read only |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| Release script | root `ravintio-framework/` | file copy at P7 | `src/ravintio-framework/` minus `component.yml`, plus `release.yml` |
| Orchestrator step 1a, migrator, update policy | `ravintio-framework/release.yml` | file read | `version`, `source-commit`, `built`, `files` |

## Stack

Unchanged: Bash and PowerShell setup, Node.js `.mjs` hooks and scripts, Bash suites under `run-tests.sh`, GitHub Actions CI. Build target: local.

## Scope Boundaries

### In Scope
- one approved git pass that moves the pack to `src/ravintio-framework/` and restores the root copy from `v0.38.0`
- a sanctioned release script that rebuilds the root copy and writes `release.yml`
- skills and standards that read `release.yml`, with a `component.yml` fallback
- a consumer migration that offers to remove a leftover `ravintio-framework/component.yml`
- the `**Applies to:**` migration header and the source-repo signal
- the version equality suite holding only on a released tree
- one manifest-location rule across the skills

### Out of Scope
- history under `plan/_archive/`, `plan/changelog/`, and released migrations
- the consumer runtime path `ravintio-framework/`, which stays as it is

### Deferred
- nothing deferred

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| Release build time | under 30 seconds for the full pack on a CI runner | the release script's timed test |
| Root copy integrity | 100% of root files match `release.yml` hashes on every PR | a CI check |

## Constraints and Assumptions

### Constraints
- Released migration files never change.
- About 134 pack files name `ravintio-framework/` as the consumer runtime path, and that path stays.
- The move runs as one recorded exception to the Write-or-Edit rule (boot Hard Limit 8), approved at P0.

### Assumptions
- No consumer reads `ravintio-framework/component.yml` outside the pack.

## Scenario Paths

Empty. The Scope Lock Challenge drafts the four paths at P0.

## Acceptance Criteria

- [ ] The pack source and its `component.yml` live under `src/ravintio-framework/`, and `product.yml` points there.
- [ ] The root `ravintio-framework/` holds a release with `release.yml` and no `component.yml`, and CI checks it against `release.yml`.
- [ ] Step 1a, the migrator, and the update policy read `release.yml`, and step 1a flags any changed pack file.
- [ ] A migration declares `**Applies to:**`, and the migrator records `not applicable` when the project kind differs.
- [ ] The version equality suite passes from P3 to P7.
