---
title: "Discovery - 0000041-pack-source-under-src"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000041-pack-source-under-src

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only. Decisions belong in `design.md`, and the Q&A audit trail in `build-log.md`.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds 40 feature folders, and `docs/about.md` exists |
| Git pre-flight | Branch `feat/0000041-pack-source-under-src`, cut from `main` at `3197b007` (PR #76 merged). `main` matched `origin/main`. No open PRs. |
| Skills inbox | empty |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`, `product.yml`): `0.38.0`. `product.yml` uses `versionPolicy: max-component-version` with two components:
  - `ravintio-framework` at `ravintio-framework/component.yml`, version 0.38.0
  - `setup-hook-integration` at `src/setup-hook-integration/component.yml`, version 0.7.0
- Prior features: 0000001 to 0000040. The last two:
  - 0000039-ravintio-rebrand (2026-10-25): renamed the pack to `ravintio-framework/`.
  - 0000040-retire-fast-path (2026-11-07): one track, and the source folder rule reads component folders from `product.yml`.
- Constraining ADRs (unless superseded):
  - 0000016 ADR-002 and 0000023 ADR-001: `product.yml` holds `{id, path}` pointers, and `product-version.mjs` reads each version live.
  - 0000035 ADR-010 and ADR-011: `set-product-release.mjs` sets `product.yml` at P7, and Hard Limit 8 names it.
  - 0000035 ADR-019: migration records come from scans, and this repo keeps `not applicable` records. 0000378 asks to revisit it.
  - 0000039 ADRs: `ravintio-framework/` is the consumer runtime path. Released migrations can't change.
  - 0000040 ADR-003: CI and pre-push read component folders from `product.yml` at the base and at HEAD.
- Component and data-ownership map (`docs/component-registry.md`):
  - `ravintio-framework` is a component pack. Its manifest sits at `ravintio-framework/component.yml`, outside `src/`, and it has no `src/` docs folder.
  - `setup-hook-integration` keeps only `component.yml` and `docs/` under `src/`. Its code lives in `ravintio-framework/` (`setup.sh`, `setup.ps1`, `setup/`, and `hooks/`).
  - The registry note says each ID maps to a folder under `src/`, which the pack breaks today.

### Layout findings

- `ravintio-framework/` holds 1,186 files, about 11 MB, with 139 entries under `tests/`.
- 20 live files name `ravintio-framework/component.yml`, outside the archive, backlog, and changelog:
  - 7 pack files: `product.yml`, `docs/component-registry.md`, the codegen, migrator, orchestrator, and ship skills, and `standards/framework-update-policy.md`
  - 13 test suites, three of them in `tests/regression/`
  - the released 0.38.0 migration, which can't change
- `.github/workflows/ravintio.yml` runs `ravintio-framework/tests/run-tests.sh`, `test_setup.ps1`, and `scripts/self-description-check.mjs` from the root copy.
- `.claude/` hooks and skills come from `ravintio-framework/setup.sh claude-code --include-full-skill-library`. The root script `refresh-ravintio-framework-dir.ps1` re-runs that setup and names an old Windows path.
- Consumers copy `ravintio-framework/` into their root. Two skills then treat the copied manifest as consumer source:
  - `ravintio-codegen-agent` bumps it after any P3 change under `ravintio-framework/`.
  - `ravintio-ship-agent` tags from it when no `product.yml` exists.

### Folded-in backlog entries

| Entry | Subject |
|-------|---------|
| 0000361 | Pack source under `src/`, and a release with no manifest |
| 0000061 | The skills disagree on where a component manifest lives |
| 0000378 | Skip migrations in the framework source repo |
| 0000136 | A framework-only migration shows as pending downstream |
| 0000368 | The version equality suite is red from P3 to P7 |
| 0000181 | Step 1a omits file-level update detection |

## Record Samples

None. The design reads no existing records.
