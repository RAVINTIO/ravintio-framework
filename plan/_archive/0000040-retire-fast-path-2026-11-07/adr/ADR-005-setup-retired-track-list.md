---
title: "ADR 005: Setup removes retired track files through a named list"
summary: "Setup carries two named lists of retired workflow and skill names. Every run removes those names from the tool it sets up, with or without a skill manifest, under the delete rules of the retired integration clean-up."
status: "accepted"
version: "0.1.0"
---
# ADR-005 - Setup removes retired track files through a named list

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Component:** ravintio-framework
**Date:** 2026-11-06

## Context

ADR-002 retires the Fast Path and the Change Pipeline, so the pack deletes these files:

- `workflows/fast-path.md`
- `workflows/change-pipeline.md`
- `skills/ravintio-change-agent/`

Deleting them from the pack doesn't remove the copies that setup installed earlier. Setup has two install paths, and neither one removes a retired name:

- `copy_workflow` in `setup.sh` (line 350) and `Copy-RavintioWorkflow` in `setup.ps1` (line 356) only copy. A deleted workflow stops arriving, but its old copy stays.
- The skill manifest prune in `setup_tool` (`setup.sh` lines 1064 to 1075) and `Invoke-RavintioSetup` (`setup.ps1` lines 1317 to 1328) removes only the folders the manifest lists. A repo with no manifest keeps `ravintio-change-agent/`.

The prune also trusts the paths it reads (backlog 0000255). This repo's own `.claude/skills/.ravintio-manifest` lists absolute paths from the old `planifest/framework` checkout. Its prune finds nothing to remove.

Feature 0000030 met the same problem for Context Mode and Telemetry. Its answer was `cleanup_retired_integrations`, recorded as 0000030 ADR 004. That pass is always on, matches exact paths, and fails open.

## Decision

Setup removes the retired track files through a named list that it owns. The list doesn't depend on the manifest.

1. The list is two arrays, because each tool has its own workflow folder and skills folder:
   - `RETIRED_TRACK_WORKFLOWS` holds `fast-path.md` and `change-pipeline.md`, relative to the tool's workflow folder.
   - `RETIRED_TRACK_SKILLS` holds `ravintio-change-agent`, relative to the tool's skills folder.
   - In `setup.ps1` the arrays are `$RetiredTrackWorkflows` and `$RetiredTrackSkills`.
   - A comment names feature 0000040 and req-004.
2. Each array item sits on its own line as one quoted path, with an optional trailing comma. ADR-007 depends on this layout.
3. `cleanup_retired_tracks` in `setup.sh` takes the skills folder and the workflow folder. `setup_tool` calls it after the manifest prune and before `copy_skills`.
4. `Invoke-RetiredTrackCleanup` in `setup.ps1` does the same. `Invoke-RavintioSetup` calls it after the manifest prune and before `Copy-RavintioSkills`.
5. Both functions run whether or not a manifest exists. A tool with no workflow folder skips the workflow array.
6. Each function removes every listed entry that exists, whatever its content, because setup owns those names. A consumer file with any other name stays.
7. Each removal prints `  - {path} (retired, removed)`. A run that finds nothing prints nothing.
8. Each setup run cleans only the tool it sets up. A consumer with two tools re-runs setup for each, as ADR-006 asks.

The functions follow the delete rules of `cleanup_retired_integrations` (`setup.sh` line 621):

- They resolve the parent folder physically and refuse a parent outside the project root.
- They remove a link as a link and never follow it. PowerShell uses `-LiteralPath`.
- A failed delete warns, and setup carries on and exits 0.

Unlike `cleanup_retired_integrations`, the new functions need no Node.js. That pass returns early when `node` is missing, so the track clean-up must not sit inside it.

This decision replaces the single-array wording in req-004. That wording named one array, `RETIRED_TRACK_FILES` (`$RetiredTrackFiles` in `setup.ps1`), of paths relative to a tool folder. The two-array form governs, as the req-004 section marked "After escalation, not yet reviewed" records.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| One array, `RETIRED_TRACK_FILES`, relative to a tool folder | One list to read and guard | Workflow and skills folders differ per tool, and some sit under different roots, such as `.agent/` and `.gemini/` for `antigravity` | One base path can't reach both folders for every tool |
| Rely on the manifest prune | No new code | Misses repos with no manifest or a stale one, including this repo | It fails in the case that most needs it (backlog 0000255) |
| Fix the manifest prune first | Fixes the root cause | Larger change with its own risks, outside this feature | Backlog 0000255 owns it, and the list works without it |
| Remove every workflow copy that has no pack source | Covers future retirements with no list | Deletes consumer files that share the folder | Destroys work a person wrote |
| Leave removal to the migration, done by hand | No setup code | Every consumer deletes files by hand per tool | Error-prone, and 0000030 ADR 004 already chose automatic clean-up |
| Add the names to `cleanup_retired_integrations` | One clean-up function | That pass skips everything when Node.js is missing, and its paths are hook-relative | A missing `node` would leave the retired tracks in place |

## Affected Components

| Component | Impact |
|-----------|--------|
| `setup-hook-integration` | New arrays and clean-up functions in `setup.sh` and `setup.ps1`. The interface contract lists the retired list as a setup output. |
| `ravintio-framework` | The pack drops the two workflows and the change agent. The new suite `test-0000040-req-004-remove-track-files.sh` covers the list. |

## Consequences

**Positive:**
- One setup re-run removes the retired copies, with no manifest or a stale one.
- The list shows reviewers exactly which names setup will delete.
- The per-removal output lets a consumer see each deletion.

**Negative:**
- Setup carries the retired names for as long as the list exists.
- A consumer who edited an installed `fast-path.md` loses that edit on the next run.
- The arrays must keep the one-per-line quoted layout, or the residue guard flags them.

**Risks:**
- A consumer with several tools re-runs setup for only one, and the others keep their copies. The migration in ADR-006 names a re-run per tool.
- Bash and PowerShell drift apart. The suite runs the `.ps1` cases when `pwsh` is present.
  - P4 addition: the `setup-powershell-51` CI job also runs the req-004 `.ps1` cases under Windows PowerShell 5.1.

## What P4 changed (governing)

- The manifest prune in `setup.sh` and `setup.ps1` skips every name on the retired skills list. Only `cleanup_retired_tracks` and `Invoke-RetiredTrackCleanup` remove those names, under their link and outside-project rules.
- Reason: P4 verify-by-execution found that a second setup run deleted a refused retired folder through a linked skills folder. The manifest listed the folder, and the prune removed it.
- An installed retired skill now prints a `(retired, removed)` line on a re-run, not a `- removed:` line.

## Related ADRs

- ADR-002 - depends-on: one track remains, so the other track files retire.
- ADR-006 - related-to: the migration asks for a setup re-run, which runs this list.
- ADR-007 - related-to: the residue guard's setup allowlist entry matches only the quoted one-per-line layout.
- 0000030 ADR 004 - extends: the same always-on, path-matched, fail-open delete rules.

## Supersedes

- None

## Superseded By

- None
