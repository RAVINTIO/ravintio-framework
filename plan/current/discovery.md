---
title: "Discovery - 0000040-retire-fast-path"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000040-retire-fast-path

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds feature folders (latest `0000039-ravintio-rebrand-2026-10-25`), and `docs/about.md` exists |
| Git pre-flight | Started on `main`, clean, level with `origin/main`. No open PRs. The human confirmed, and `feat/0000040-retire-fast-path` was created. |
| Skills inbox | `ravintio-framework/skills-inbox/` is absent, so nothing to process |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`, `product.yml`, `ravintio-framework/component.yml`): `0.37.2`. `product.yml` sets `versionPolicy: max-component-version` and `id: ravintio-framework`.
- Prior features (`plan/_archive/`): 0000035 write-gate scope and path hardening (2026-10-22), 0000036 pipeline friction and gate fixes (2026-10-23), 0000037 green CI before ship (2026-10-24), 0000038 token efficiency and Windows shard (2026-10-24), 0000039 RAVINTIO rebrand (2026-10-25).
- Constraining ADRs (from `docs/decisions-index.md`):
  - 0000033 ADR-009: Fast Path admits changes with no `src/` target. This feature supersedes it.
  - 0000035 ADR-002: the Fast Path scope record as self-authorisation. This feature supersedes it.
  - 0000035 ADR-004: the Fast Path enforcement path list in code. Its list may survive under a new name if other rules read it.
  - ADR-004 (version bump rules by track) names Fast Path as a patch track. Its Fast Path row needs a supersede or amend note.
- Component / data-ownership map (`docs/component-registry.md`): one live component, `ravintio-framework` (component-pack), owns every file this feature touches. `src/setup-hook-integration/` holds docs that mention Fast Path.

### Fast Path footprint

A search for "fast path" or "fast-path", outside history folders, finds these live files:

- Track: `ravintio-framework/workflows/fast-path.md`. Setup copies each workflow to the tool folder, for example `.claude/commands/fast-path.md`.
- Routing: `skills/ravintio-orchestrator/SKILL.md`, `references/phase-0-assess-and-coach.md` (version bump table row), `skills/ravintio-ship-agent/SKILL.md`, and `external-skills/plan-eng-review/SKILL.md`.
- Enforcement hooks: `path-rules.mjs`, `gate-write.mjs`, `shell-write-guard.mjs`, `ratchet-check.mjs`, and `auto-trigger-orchestrator.mjs`.
- Git and CI: `hooks/pre-push`, `hooks/ravintio.yml` (consumer CI template), and `.github/workflows/ravintio.yml` (this repo's copy).
- Ignore rule: `.gitignore` lists `plan/.fast-path-scope`.
- Docs: `README.md`, `getting-started.md`, `pipeline-reference.md`, `project-operations.md`, `templates/standard-boot.md`, `component.yml`, four `docs/` files, and two `src/setup-hook-integration/docs/` files.
- Migrations that mention Fast Path: `migrate-0.34.0-rerun-setup.md` and the three `migrate-0.37.0-ravintio-rename.*` files. Migration files never move or change after release.
- Tests: 14 suites under `ravintio-framework/tests/` and 3 under `tests/regression/`.

Setup finding: `setup.sh` copies the CI template to `.github/workflows/ravintio.yml` only when that file is absent (lines 763 to 771). A consumer repo that upgrades keeps its old CI file, with the `fix(fast-path):` exemption, unless something else replaces it.

## Record Samples

None. The design reads no existing records.
