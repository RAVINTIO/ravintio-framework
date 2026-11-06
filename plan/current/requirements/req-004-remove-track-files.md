---
title: "Requirement: req-004 - remove-track-files"
summary: "The pack drops the Fast Path and Change Pipeline workflows, the change agent, and the change summary template, and setup removes their installed copies from every tool folder through a named retired list."
status: "draft"
version: "0.1.0"
---
# Requirement: req-004 - remove-track-files

**Skill:** [spec-agent](../skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Source:** US-003
**Priority:** must-have

## User Story

As a consumer repo owner, I upgrade and lose every Fast Path and Change Pipeline file and any leftover scope record, with a notice, so that nothing stale offers a weaker route.

## Functional Requirements
- Delete these pack files with `git rm`:
  - `ravintio-framework/workflows/fast-path.md`
  - `ravintio-framework/workflows/change-pipeline.md`
  - `ravintio-framework/skills/ravintio-change-agent/`, which holds `SKILL.md` and a `.gitkeep` in each of `assets/`, `references/`, and `scripts/`
  - `ravintio-framework/templates/change-summary.template.md`
- Change summary template finding: only `skills/ravintio-change-agent/SKILL.md` reads the template. Its `bundle_templates` line names it, and its body writes `plan/current/change-summary.md`. No other skill, script, hook, or setup step reads it. Backlog entry 0000346 names it as context. History under `plan/_archive/` and `plan/changelog/` also names it, and stays as written. So the template goes with the change agent.
- Why setup needs a retired list: `copy_workflow` in `setup.sh` (line 350) and `Copy-RavintioWorkflow` in `setup.ps1` (line 356) only copy. Setup copies every `workflows/*.md`, so a deleted workflow stops arriving but its old copy stays. The skill manifest prune in `setup_tool` (`setup.sh` lines 1064 to 1075) and `Invoke-RavintioSetup` (`setup.ps1` lines 1317 to 1328) removes only listed folders. A repo with no manifest, or one whose manifest lists stale absolute paths, keeps `ravintio-change-agent/`. This repo's own `.claude/skills/.ravintio-manifest` lists paths from the old `planifest/framework` checkout, so its prune finds nothing to remove.
- `setup.sh` gains a named retired list and a function that acts on it:
  - The list is one array, `RETIRED_TRACK_FILES`, of paths relative to a tool folder: the `fast-path.md` and `change-pipeline.md` workflow copies, and the `ravintio-change-agent` skill folder. A comment names 0000040 and this requirement.
  - Layout: each list item sits on its own line, as one quoted path with an optional trailing comma. This holds for `RETIRED_TRACK_FILES` in `setup.sh` and `$RetiredTrackFiles` in `setup.ps1`. The req-006 setup entry matches only that layout.
  - A new function, `cleanup_retired_tracks`, takes the tool's skills folder and workflow folder. `setup_tool` calls it after the manifest prune and before `copy_skills`. It runs whether or not a manifest exists.
  - It removes each listed entry that exists, and prints `  - {path} (retired, removed)` for each one. It prints nothing when nothing is found.
  - It follows the delete rules of `cleanup_retired_integrations` (`setup.sh` line 621). It resolves the parent folder physically and refuses a parent outside the project root. It removes a link as a link and never follows it. A failed delete warns and setup carries on.
- `setup.ps1` gains the same list, `$RetiredTrackFiles`, and a function `Invoke-RetiredTrackCleanup`. `Invoke-RavintioSetup` calls it at the same point. It gives the same output lines and the same link and parent rules, on Windows PowerShell 5.1 and PowerShell 7.
- Installed paths the list covers, per tool, from `setup/{tool}.sh` and `setup/{tool}.ps1`:

  | Tool | Workflow copies removed | Skill folder removed |
  |------|------------------------|----------------------|
  | `claude-code` | `.claude/commands/fast-path.md`, `.claude/commands/change-pipeline.md` | `.claude/skills/ravintio-change-agent/` |
  | `antigravity` | `.agent/workflows/fast-path.md`, `.agent/workflows/change-pipeline.md` | `.gemini/skills/ravintio-change-agent/` |
  | `copilot` | `.github/copilot-workflows/fast-path.md`, `.github/copilot-workflows/change-pipeline.md` | `.github/skills/ravintio-change-agent/` |
  | `codex` | `.agents/workflows/fast-path.md`, `.agents/workflows/change-pipeline.md` | `.agents/skills/ravintio-change-agent/` |
  | `cursor` | none, no workflow folder | `.cursor/skills/ravintio-change-agent/` |
  | `windsurf` | none, no workflow folder | `.windsurf/skills/ravintio-change-agent/` |
  | `cline` | none, no workflow folder | `.clinerules/skills/ravintio-change-agent/` |

- `opencode` installs no skills or workflows, and `roo-code` exits before it installs anything. Neither needs the list.
- Each setup run cleans the folders of the tool it sets up. A consumer who uses two tools re-runs setup for each, as the migration in req-005 asks.
- The list removes these paths whatever their content, because setup owns those names. A consumer file with any other name in those folders stays.
- Docs that list installed files drop the deleted entries:
  - `README.md` line 112: the `workflows/` row lists `feature-pipeline` and `retrofit`.
  - `ravintio-framework/tool-setup-reference.md` line 40 lists only `feature-pipeline` and `retrofit`. Drop the `ravintio-change-agent` and `change-pipeline.md` lines in the trees at lines 71, 78, 139, 172, and 203. Add one sentence on the retired list.
  - `src/setup-hook-integration/docs/interface-contract.md`: add the retired list to the setup outputs.
- Suites that read the deleted files, to rewrite test-first:
  - `ravintio-framework/tests/test-0000017-req-007-change-agent-archive.sh` and its copy in `tests/regression/`: drop the change-agent sections and the Change Pipeline assertion on Hard Limit 10. Keep the ship-agent cross-reference and Hard Limit 10 checks. Keep the file name, because `regression-manifest.json` and the 0000039 req-005 suite list it.
  - `ravintio-framework/tests/test-0000005-framework-governance.sh` and its copy in `tests/regression/`: drop the change-agent spelling check.
  - `ravintio-framework/tests/test-0000007-agent-optimisation.sh`: drop `ravintio-change-agent` from both skill loops.
  - `ravintio-framework/tests/test-0000030-req-003-telemetry-pipeline-text-removal.sh`: drop `change-agent` from the skill brace list.
  - `ravintio-framework/tests/test-0000039-req-001-pack-paths-and-identifiers.sh`: drop `change-agent` from `SKILLS`.
  - `ravintio-framework/tests/test-0000039-req-005-history-and-split-name-protection.sh`: drop `change-agent` from the brace check and the skill loop.
  - `ravintio-framework/tests/test-0000039-req-007-brand-guard.sh` and its copy in `tests/regression/`: drop the `workflows/fast-path.md` allowlist row. Its stale-entry check fails once the file goes.
- `test-0000035-req-001-fast-path-scope-record.sh` and `test-0000035-req-009-fast-path-enforcement-paths.sh` read `workflows/fast-path.md`. req-002 removes or rewrites them, so P3 lands req-002 and this requirement in one green step.
- `test-0000036-req-001-rerun-setup-migration.sh` names `workflows/fast-path.md` only as text in a released migration. It needs no change.
- Add `ravintio-framework/tests/test-0000040-req-004-remove-track-files.sh`. It follows `test-0000030-req-004-install-clean-up-and-retired-flags.sh`, and runs the `.ps1` cases when `pwsh` is present.
- Split step: keep. The one concern is that no Fast Path or Change Pipeline file survives in the pack or in a tool folder. Deleting the pack files without the retired list would leave every installed copy in place, so neither part ships alone. PowerShell parity ships with the Bash list as one pair.

- P1 critic revision: the execution plan's file ownership table governs who edits each file. This requirement states the installed-file listings for `README.md` and `tool-setup-reference.md`, and req-007 writes them.

## Acceptance Criteria
- [ ] The pack holds no `workflows/fast-path.md`, `workflows/change-pipeline.md`, `skills/ravintio-change-agent/`, or `templates/change-summary.template.md`. A fresh `setup.sh claude-code` in a scratch repo installs `feature-pipeline.md` and `retrofit.md` in `.claude/commands/`, and no `ravintio-change-agent` skill. The rewritten suites listed above pass in `tests/` and `tests/regression/`. Verified by: integration
- [ ] In a scratch repo seeded with every path in the per-tool table, `setup.sh` for each listed tool removes that tool's paths and prints one `(retired, removed)` line each. It does so with no manifest, and with a manifest that lists stale paths. A rerun prints no retired line. A linked skills folder whose target sits outside the project stays untouched, and setup exits 0. Verified by: integration
- [ ] `setup.ps1` gives the same removals, output lines, and exit codes as `setup.sh` for the same fixtures, on Windows PowerShell 5.1 and PowerShell 7. Verified by: integration

## Dependencies
- req-001 (one-track-routing) stops every skill, template, and doc from pointing at the deleted files.
- req-002 (gates-ignore-scope-record) removes or rewrites the 0000035 req-001 and req-009 suites and drops `workflows/fast-path.md` from the enforcement path list in `path-rules.mjs`.
  - Correction: the list holds no such entry. Only the comment above the list cites `workflows/fast-path.md`, and req-002 rewrites that comment.
- req-005 (consumer-migration) tells the human on the loop to re-run setup, which runs this list.
- req-006 (residue-guard) checks that no live reference to the deleted files remains.
- Existing pattern: `cleanup_retired_integrations` in `setup.sh` and `Invoke-RetiredIntegrationCleanup` in `setup.ps1` (0000030 ADR 004).
- Backlog 0000255 covers the manifest prune that trusts listed paths. This requirement doesn't fix that prune. Its list works without the manifest.
