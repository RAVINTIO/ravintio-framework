---
title: "Backlog Entry: 0000358 - retire Fast Path"
summary: "Remove the Fast Path track so every change runs the Change Pipeline or the Feature Pipeline. Uncontrolled quick changes belong in RAVINTIO Zero."
status: "open"
---
# Backlog Entry: 0000358 - retire Fast Path

**Source feature:** none (human request)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Priority:** next. The owner asked for this to run before any other entry from the Zero review.
**Suggested route:** Feature Pipeline. The change edits enforcement hooks, the CI template, and setup.
**Related:** 0000152, 0000200, 0000297, 0000308, 0000355, 0000359

---

## Problem

Fast Path lets a change skip the Feature Brief, the execution plan, and the ADRs. On 2026-10-31 the owner decided Framework needs no fast option. Framework serves regulated teams, and every change there needs a record and a control that fits its risk. The quick-change use case moves to RAVINTIO Zero.

Fast Path reaches these parts of the pack:

- the track itself: `ravintio-framework/workflows/fast-path.md` and the installed `fast-path` skill and command, such as `.claude/commands/fast-path.md`
- routing: the Three-Track Decision Tree and Fast Path criteria in `ravintio-framework/skills/ravintio-orchestrator/SKILL.md` and `references/phase-0-assess-and-coach.md`
- enforcement: the scope record `plan/.fast-path-scope` and `FAST_PATH_ENFORCEMENT_PATHS` in `ravintio-framework/hooks/enforcement/path-rules.mjs`, read by `gate-write.mjs`, `shell-write-guard.mjs`, and `ratchet-check.mjs`
- the `fix(fast-path):` commit exemption in `ravintio-framework/hooks/pre-push` and the consumer CI template `ravintio-framework/hooks/ravintio.yml`
- `auto-trigger-orchestrator.mjs`, which names the three tracks in its triage message
- `ravintio-ship-agent/SKILL.md`, `templates/standard-boot.md`, the generated `CLAUDE.md`, `pipeline-reference.md`, `project-operations.md`, and `getting-started.md`
- 14 test suites under `ravintio-framework/tests/` and 3 under `tests/regression/`

## Suggested Action

1. Route every request to the Change Pipeline or the Feature Pipeline. The decision tree keeps two tracks.
2. Send the cases Fast Path took to the Change Pipeline. That covers UI copy, an isolated pure-function bug, a dependency bump, and a change with no `src/` target.
3. Delete the workflow, the skill, and the command. Have setup remove the installed copies.
4. Remove the scope record from the hooks. With no design, `gate-write` blocks every `src/` write. Keep the enforcement path list, renamed, if other rules still read it.
5. Remove the `fix(fast-path):` exemption from pre-push and the CI template. This closes 0000308.
6. Add a migration that deletes a stale `plan/.fast-path-scope` and tells the human on the loop that Fast Path is gone. This closes 0000152.
7. Remove or rewrite the Fast Path tests. This closes 0000200.
8. Keep history under `plan/_archive/` and `plan/changelog/` as written.

Incidents that need a quick fix don't use this route. 0000359 designs a controlled hotfix path for them.

## Wanted outcome

- No skill, command, hook, or CI rule admits a change without a pipeline record.
- A request that Fast Path used to take routes to the Change Pipeline.
- A consumer repo that upgrades loses the Fast Path files, and a leftover scope record admits nothing.
- Tests check that `gate-write` ignores `plan/.fast-path-scope` and that CI no longer exempts `fix(fast-path):` branches.

## Open questions

- Should the Change Pipeline gain a lighter tier for changes with no `src/` target, such as documentation? Any tier must still keep a record.
- Does the consumer CI template still need a separate exemption for anything?

## Why Deferred

The owner asked for it on 2026-10-31, during the Zero review on a chore branch. It changes enforcement hooks, so it needs its own Feature Pipeline run.
