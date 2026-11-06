---
title: "ADR 002: One track: every change runs the Feature Pipeline"
summary: "Fast Path and the Change Pipeline both retire. Every request that meets no standalone skill trigger routes to the Feature Pipeline, with or without a src/ target. No scope record, commit subject, or track-keyed patch rule offers a lighter route."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - One track: every change runs the Feature Pipeline

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Component:** ravintio-framework
**Date:** 2026-11-06

## Context

The framework offers three tracks today. Each lighter track skips part of the full record:

- Fast Path skips the Feature Brief, the execution plan, and the ADRs.
- The Change Pipeline skips P0 coaching, the ADRs, and the security review.
- The Feature Pipeline runs every phase from P0 to P9.

Several controls exist only to serve the lighter tracks:

- 0000033 ADR 009 let Fast Path admit a change with no `src/` target.
- 0000035 ADR 002 let `gate-write` and `shell-write-guard` admit writes listed in `plan/.fast-path-scope` when no design exists. The agent that makes the change writes that record, so the record is self-authorisation.
- 0000035 ADR 003 bound the record's life to the branch and `HEAD`, read from `.git` files by `readGitState` in `path-rules.mjs`.
- `hooks/pre-push`, `hooks/ravintio.yml`, and this repo's `.github/workflows/ravintio.yml` exit 0 when every commit subject starts `fix(fast-path):`. A commit subject is self-declared, so this exemption is self-authorisation too.
- 0000014 ADR 004 keyed the version bump to the track. Fast Path and the Change Pipeline take a patch bump.

Framework serves regulated teams. Each change there needs a record and a control that fits its risk. A self-declared route past the gates or CI gives an auditor no evidence that the change fitted the track. The owner decided on 2026-11-01 that Framework keeps one track. Quick, uncontrolled changes belong in RAVINTIO Zero instead (`feature-brief.md`, Business Goal).

The confirmed design records the routing, the hook change, and the CI change. req-001, req-002, and req-003 state them in detail. req-007 lists the ADRs this decision supersedes.

## Decision

- **Retire both tracks:** Fast Path and the Change Pipeline both retire. req-004 deletes `workflows/fast-path.md`, `workflows/change-pipeline.md`, and `skills/ravintio-change-agent/`. ADR-005 covers how setup removes the installed copies.
- **Route on one track:** Every request routes to the Feature Pipeline, whether or not it has a `src/` target. A documentation, governance, or tooling change runs the Feature Pipeline too.
- **Keep triage for standalone skills only:** The Routing Directive in `skills/ravintio-orchestrator/SKILL.md` keeps its triage step. Triage has two outcomes:
  - A request that meets a standalone skill trigger invokes that skill. The standalone skills are `ravintio-optimise-agent`, `ravintio-refresh-setup`, and the retrofit workflow.
  - Every other request goes to the Feature Pipeline.
- **Remove the track text from the orchestrator:** The orchestrator loses these parts:
  - the `### Three-Track Decision Tree` table
  - the `### Fast Path Criteria and Execution` section
  - the `## Invoking the Change Pipeline` section
  - the `PC:` row in the response prefix table
  - the Change Pipeline clause in Hard Limit 10
- **Drop the scope record from the gates:** `gate-write`, `shell-write-guard`, and `ratchet-check` stop reading `plan/.fast-path-scope`. A file at that path changes no verdict, whatever its content. With no design, `gate-write` blocks every write outside `plan/`, `docs/`, and the always-permitted names. P3 removes these from `path-rules.mjs`:
  - `FAST_PATH_SCOPE_FILE`, `parseScopeRecord`, and `readGitState` with its helpers
  - `loadScope`, `readScope`, and `scopeVerdict`
  - the `notice` key in `evaluateWrite`, and the notice output in `gate-write.mjs` and `shell-write-guard.mjs`
- **Drop the commit-subject exemption:** `hooks/pre-push`, `hooks/ravintio.yml`, and `.github/workflows/ravintio.yml` lose the `fix(fast-path):` block and its `COMMIT_MESSAGES` line. ADR-003 states the source folder rule that replaces the old `src/` check.
- **Trim the version bump table:** The table in `references/phase-0-assess-and-coach.md` loses its Fast Path and Change Pipeline patch rows. The Feature Pipeline row (minor) and the Breaking change row (major) stay. The Greenfield start and the External Anchor rule from 0000014 ADR 004 stay unchanged. This run takes 0.38.0, a minor bump from 0.37.2.
- **Keep the enforcement path list:** The list survives for the permitted-name rule in `isAlwaysPermitted`. ADR-004 records its new name.
- **Migrate consumers:** A consumer upgrade deletes a leftover `plan/.fast-path-scope` and removes the CI exemption block once the human on the loop confirms. ADR-006 covers the migrator paths for the CI edit.
- **Leave history alone:** Archived ADRs, `plan/changelog/`, and released migrations stay as written. `docs/decisions-index.md` and this ADR record the supersession.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep all three tracks | No work, and small changes stay fast | Fast Path and the commit subject stay self-authorised routes past the gates and CI | Regulated users need a full pipeline record for every change |
| Retire Fast Path only, and keep the Change Pipeline | Small changes to existing components stay faster than a full run | The Change Pipeline still skips P0, the ADRs, and the security review. The `PC:` prefix, the change agent, and a patch row stay. | The owner widened the scope on 2026-11-01 to retire both tracks |
| Keep Fast Path, but require a human to sign the scope record | A real separation of duties for the record | Fast Path still skips the brief, the plan, and the ADRs. An `autonomous` run can't use a signed record. | 0000035 rejected the same option, and it leaves the record gap open |
| Keep the scope record in the gates as a dead branch with no writer | Smaller hook diff | A file an agent writes would still admit writes. The parser and git reader stay as attack surface. | Code with no sanctioned writer only widens what the gate accepts |
| One track (chosen) | One route, one record shape, and no self-declared bypass | Small changes cost a full run | The owner accepts slower small changes as the cost of a full record |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | The orchestrator, both phase 0 references, the ship, adr, and optimise skills, and `templates/standard-boot.md` describe one track. `path-rules.mjs`, `gate-write.mjs`, `shell-write-guard.mjs`, and `ratchet-check.mjs` lose the scope record. `hooks/pre-push` and `hooks/ravintio.yml` lose the exemption. Both track workflows and `ravintio-change-agent` go. |
| this repo (`.github/workflows/ravintio.yml`, `docs/`) | This repo's CI file loses the exemption and matches the template. The docs and the decisions index describe one track. |

## Consequences

**Positive:**
- Every change leaves a full pipeline record, from the Feature Brief to the PR. An auditor reads one record shape.
- No agent can admit a write or pass CI through a file or a commit subject it wrote itself.
- The gates lose `parseScopeRecord`, `readGitState`, and `scopeVerdict`. Less hook code reads untrusted input.
- Routing has two outcomes, so an agent can't pick the wrong track.

**Negative:**
- A one-line fix or a typo correction now runs every phase from P0 to P9. The owner accepts this cost.
- Consumer scripts or habits that rely on `fix(fast-path):` subjects stop working after the upgrade.

**Risks:**
- People take small changes outside the framework to avoid the cost, so those changes leave no record. The feature brief points such work to RAVINTIO Zero.
- A suite or doc still asserts Fast Path behaviour after the change. req-006 adds a residue guard that searches for it.
- A consumer upgrades mid-way through a Change Pipeline run and loses its skill. The migration warns and tells the human on the loop to restart on the Feature Pipeline.
- The incident hotfix path (backlog 0000359) stays out of scope. Until it ships, an urgent fix also runs the full pipeline.

## Related ADRs

- ADR-001 - related-to: the stack stays unchanged for this decision.
- ADR-003 - depends-on: the source folder rule replaces the commit-subject exemption as the CI and pre-push control.
- ADR-004 - related-to: the enforcement path list survives as `ENFORCEMENT_PATHS` after the scope record goes. It partly supersedes 0000035 ADR 004.
- ADR-005 - depends-on: the setup retired list removes the installed track copies.
- ADR-006 - depends-on: the migrator's named paths let the migration edit a consumer's CI file.

## Supersedes

- 0000033 ADR 009 (Fast Path admits no-src changes) - superseded. Fast Path no longer exists, and a no-`src/` change runs the Feature Pipeline.
- 0000035 ADR 002 (Fast Path scope record as self-authorisation with a visible trail) - superseded. No gate reads `plan/.fast-path-scope`.
- 0000035 ADR 003 (Scope record staleness from branch and HEAD read from git files) - superseded. The scope record was its only subject, so `readGitState` goes with it.
- 0000014 ADR 004 (Version Bump Rules by Pipeline Track) - partly superseded. The Fast Path and Change Pipeline patch rule goes. The minor, major, Greenfield, and External Anchor rules stay.

## Superseded By

- None
