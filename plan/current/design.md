# Design - 0000040-retire-fast-path

## Feature
- Problem: Fast Path and the Change Pipeline let a change skip parts of the full record, and Framework's regulated users need every change to run the Feature Pipeline.
- Adoption mode: standard-iterative (signal: `plan/_archive/` holds feature folders, and `docs/about.md` exists)
- Feature ID: 0000040-retire-fast-path
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As a human on the loop, I see every request routed to the Feature Pipeline, so that every change leaves a full pipeline record.
  - US-002: As a human on the loop, I rely on the write gates, pre-push, and CI to admit nothing on a Fast Path basis, so that neither a scope record nor a commit subject can skip a control.
  - US-003: As a consumer repo owner, I upgrade and lose every Fast Path and Change Pipeline file and any leftover scope record, with a notice, so that nothing stale offers a weaker route.
- Acceptance criteria confirmed: 4 (from `feature-brief.md`). P1 expands them to about 3 per story.
- Constraints:
  - Released migration files never change.
  - `gate-write` and `shell-write-guard` stay in parity.
  - History under `plan/_archive/` and `plan/changelog/` stays as written.
- Integrations: none outside the pack. Consumer repos receive the change through setup and the new migration.

## Architecture Layer
- Latency target: not applicable (no service)
- Availability target: not applicable (no service)
- Scalability target: not applicable
- Security: no auth. The change removes an admission route from the write gates, so the gates get stricter. The migration deletes one marker file and edits one CI file in a consumer repo, each only after the human on the loop confirms. Data classification: public source code.
- Data privacy: no regulated data
- Observability: standard defaults. The migration reports each file it removed or left.
- Cost boundary: not constrained

## Engineering Layer
- Stack: unchanged. Bash and PowerShell setup, Node.js `.mjs` hooks and scripts, Bash suites under `run-tests.sh`, GitHub Actions CI. Build target: local.
- Components: `ravintio-framework` (component-pack), the only component touched.
- Data ownership: `ravintio-framework` owns every file under `ravintio-framework/`. Consumer repos own their CI file and `plan/` markers, and the migration changes them only on confirmation.
- Deployment: consumers pull the pack and re-run setup. The migrator applies the new migration.
- API versioning: not applicable. The hook contracts change, and the version bump records it.
- Routing: one track. The Routing Directive keeps triage for the standalone skills (optimise, refresh setup, retrofit), and sends every other request to the Feature Pipeline, whether or not it has a `src/` target.
- Removed: `workflows/fast-path.md`, `workflows/change-pipeline.md`, `skills/ravintio-change-agent/`, the `PC:` prefix, and `templates/change-summary.template.md` if nothing else reads it.
- Setup clean-up: `copy_workflow` only copies, and the skill manifest only removes listed skill folders. `setup.sh` and `setup.ps1` gain a named retired list. It removes the installed `fast-path` and `change-pipeline` commands or workflow copies, and the `ravintio-change-agent` skill, in every tool folder, with or without a manifest.
- Hooks: `gate-write`, `shell-write-guard`, and `ratchet-check` stop reading `plan/.fast-path-scope`. With no design, `gate-write` blocks every `src/` write. P2 decides whether `FAST_PATH_ENFORCEMENT_PATHS` survives under a new name.
- Git and CI: `hooks/pre-push` and `hooks/ravintio.yml` lose the `fix(fast-path):` exemption. This repo's `.github/workflows/ravintio.yml` matches.
- Migration: a new `migrate-0.38.0-retire-fast-path-and-change-pipeline.md` deletes a leftover `plan/.fast-path-scope`. It removes the exemption block from `.github/workflows/ravintio.yml` once the human on the loop confirms. It tells the human on the loop that both tracks are gone and asks for a setup re-run. Setup keeps its copy-if-absent rule for the CI file. Every step is safe to repeat, so an interrupted run applies again cleanly. If `plan/current/` holds an unfinished Change Pipeline or Fast Path run, the migration warns and tells the human on the loop to restart it on the Feature Pipeline. If the CI block can't be matched, or the human declines, the migration names the file and the lines to delete and records the outcome with that reason.
- Migrator scope: rule 1 in `skills/ravintio-migrator/SKILL.md` widens so a migration can name extra paths it may edit, outside `plan/`, `docs/`, and `ravintio-framework/`. The human on the loop confirms each edit. `src/` stays closed. This migration names only `.github/workflows/ravintio.yml`.
- Version: last known `0.37.2`. Suggested `0.38.0`, a minor bump for a Feature Pipeline run. The version bump table loses its Fast Path and Change Pipeline rows.

## Scope
- In:
  - one-track routing in the orchestrator, both phase 0 references, the boot template, other skills, and docs
  - deletion of both tracks' workflows, the change agent, and their installed copies
  - the scope record removed from the three hooks
  - the `fix(fast-path):` exemption removed from pre-push and both CI files
  - the consumer migration, and the migrator rule 1 widening it needs
  - a named retired list in `setup.sh` and `setup.ps1`
  - Fast Path and Change Pipeline tests removed or rewritten, with a residue search suite
  - superseding notes on 0000033 ADR-009, 0000035 ADR-002, 0000035 ADR-004, and the bump-rules ADR-004
- Out:
  - history under `plan/_archive/`, `plan/changelog/`, and released migrations
  - the incident hotfix path (0000359)
  - the advisory pre-commit and presence-only checks left in 0000308
- Deferred: nothing deferred
- Release size: `three-story rule`. Three stories, so it fits.

## Assumptions
- No consumer depends on `FAST_PATH_ENFORCEMENT_PATHS` outside the pack - impact if wrong: a consumer script breaks on upgrade.
- No consumer run is mid-way through the Change Pipeline when it upgrades - impact if wrong: that run loses its skill and must restart on the Feature Pipeline.
- Record samples: none. The design reads no existing records.

## Risks
- A suite that tests the gates or routing still asserts Fast Path behaviour and fails after removal. Likelihood high, impact medium. P1 lists every suite, and P3 rewrites each one test-first.
- Removing the scope code weakens a gate check it shares, such as link or root resolution. Likelihood medium, impact high. P3 keeps the link and root suites green, and P5 reviews the hook diff.
- The migration can't match a consumer's edited CI block. Likelihood medium, impact low. The migrator shows the file and leaves it for the human on the loop.
- Removing the Change Pipeline makes small changes slower. Likelihood high, impact low. The owner accepts this as the cost of a full record.

## Dependencies
- Upstream: none
- Downstream: backlog 0000355 feature rows marked Change (F4, F9, F10, F23) become Feature runs. 0000308 narrows. 0000152 and 0000200 close.

## Active Skills
None

## Skill Map
P1 owns the final requirement split. This draft maps the expected requirements.

| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - one-track-routing | ravintio-codegen-agent | Orchestrator, references, boot template, and skill text, checked by suites |
| REQ-002 - gates-ignore-scope-record | ravintio-codegen-agent | Hook code under TDD, with gate parity |
| REQ-003 - no-commit-subject-exemption | ravintio-codegen-agent | Pre-push and both CI files under TDD |
| REQ-004 - remove-track-files | ravintio-codegen-agent | Delete workflows and the change agent, setup removes installed copies |
| REQ-005 - consumer-migration | ravintio-codegen-agent | The migration file, the migrator rule 1 widening, and their tests |
| REQ-006 - residue-guard | ravintio-test-writer | A search suite with an allowlist for history |
| REQ-007 - docs-and-adr-supersede | ravintio-docs-agent | Docs, decisions index, and the version bump |

## Repo Instructions
Five files in `ravintio-overrides/instructions/`, read at P0.
- `custom-001-local-git-only.md`: fetch, pull, push, and `gh pr create` need no prompt. Work on a `feat/` branch. Committing to `main` and merging PRs stay human-only. Commit after every meaningful artifact write.
- `custom-002-prefer-subagent-decomposition.md`: split long or multi-unit work into parallel subagents, above the size floor.
- `custom-003-git-up-to-date-shorthand.md`: `GUTD` means check out `main`, pull, list untracked files, and report the last merged PR's checks.
- `custom-004-file-backlog-entries-immediately.md`: file out-of-scope problems as backlog entries at once, then commit and push them.
- `custom-005-p9-push-and-raise-pr.md`: at P9, push and raise the PR without asking. Never merge.

## Confirmation
Human confirmed this design before proceeding: no // Date and Time confirmed: pending
