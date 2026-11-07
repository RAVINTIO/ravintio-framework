---
title: "Scope - 0000040-retire-fast-path"
summary: "Defines explicit boundaries of what is in scope and out of scope."
status: "active"
version: "0.1.0"
---
# Scope - 0000040-retire-fast-path

**Skill:** [spec-agent](../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Wave:** not waved
**Version:** 0.38.0

## In Scope

- One-track routing. The orchestrator, both phase 0 references, the boot template, other skills, and docs send every request to the Feature Pipeline. Triage stays only for the standalone skills. Maps to req-001-one-track-routing (US-001).
- Removal of both tracks. Delete `workflows/fast-path.md`, `workflows/change-pipeline.md`, `skills/ravintio-change-agent/`, and the `PC:` prefix. Setup removes the installed copies through a named retired list in `setup.sh` and `setup.ps1`. Maps to req-004-remove-track-files (US-003).
- The scope record leaves the gates. `gate-write`, `shell-write-guard`, and `ratchet-check` stop reading `plan/.fast-path-scope`, and the two write gates stay in parity. Maps to req-002-gates-ignore-scope-record (US-002).
- No commit subject exemption. Pre-push, the CI template, and this repo's CI file lose the `fix(fast-path):` exemption. Both gain the source folder rule read from `product.yml`. Maps to req-003-no-commit-subject-exemption (US-002).
- The consumer migration `migrate-0.38.0-retire-fast-path-and-change-pipeline.md`, and the migrator rule 1 widening it needs. Maps to req-005-consumer-migration (US-003).
- A residue guard suite with an allowlist for history. Maps to req-006-residue-guard (US-001).
- Docs, superseding notes on four ADRs, and the 0.38.0 version bump. Maps to req-007-docs-and-adr-supersede (US-001).
- Fast Path and Change Pipeline tests removed or rewritten test-first. Each requirement names its own suites.
- P1 clarification for the docs line: the superseding notes cover five ADRs. req-007 adds 0000035 ADR 003, which reads only the scope record.

## Out of Scope

- History under `plan/_archive/`, `plan/changelog/`, and `plan/_migrations/`, and the bodies of released migrations. These stay as written.
- The incident hotfix path. Backlog 0000359 owns it.
- The advisory pre-commit and presence-only checks left in backlog 0000308. P7 narrows that entry.
- Moving the pack source under `src/` and releasing the folder without its manifest. Backlog 0000361 owns it.
- Re-routing the 0000355 feature rows marked Change. P7 updates that table.

## Deferred

- Nothing deferred.
