---
title: "Requirement: req-001 - one-track-routing"
summary: "Every request that doesn't name a standalone skill routes to the Feature Pipeline, and no skill, template, hook message, or doc offers Fast Path or the Change Pipeline as a route."
status: "draft"
version: "0.1.0"
---
# Requirement: req-001 - one-track-routing

**Skill:** [spec-agent](../skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Source:** US-001
**Priority:** must-have

## User Story

As a human on the loop, I see every request routed to the Feature Pipeline, so that every change leaves a full pipeline record.

## Functional Requirements
- The orchestrator, `ravintio-framework/skills/ravintio-orchestrator/SKILL.md`, routes on one track:
  - The Routing Directive keeps its first rule: every request is triaged before any action, after P9 too, whether or not a run is active. Triage now has two outcomes. A request that meets a standalone skill trigger invokes that skill. Every other request goes to the Feature Pipeline.
  - "Route to exactly one of four tracks" becomes a sentence that names those two outcomes.
  - The Standalone Skills table lists `ravintio-optimise-agent`, `ravintio-refresh-setup`, and the retrofit workflow, each with its trigger. The three sub-agent rows stay.
  - The Feature Pipeline accepts a change with no `src/` target, such as documentation, governance, or tooling. The directive says so in one sentence.
  - Remove the `### Three-Track Decision Tree` table and the `### Fast Path Criteria and Execution` section.
  - Remove the `PC:` row from the phase prefix table.
  - Hard Limit 10 names only the Feature Pipeline archive at ship-agent P7. Drop the Change Pipeline clause.
  - Remove the `## Invoking the Change Pipeline` section.
- `references/phase-0-assess-and-coach.md`: the version bump table drops its Fast Path and Change Pipeline rows. It keeps the Feature Pipeline row (minor) and the Breaking change row (major).
- `references/adoption-modes.md` line 34: suggest a minor bump for a Feature Pipeline run. Drop "patch for Change Pipeline".
- `ravintio-framework/skills/ravintio-ship-agent/SKILL.md`:
  - Hard Limit 6 routes each P9 next step through the Feature Pipeline. "A code change always needs a track" becomes "A code change always needs a Feature Pipeline run". The no-P0 and `main` runbook bans stay.
  - Step 11 says each listed next step names the Feature Pipeline, or the standalone skill it needs.
- `ravintio-framework/skills/ravintio-adr-agent/SKILL.md` line 45: the supersede rule applies to any run. Drop "If this is a change pipeline run".
- `ravintio-framework/skills/ravintio-optimise-agent/SKILL.md` line 65: list the confirmed changes as Feature Pipeline input.
- `ravintio-framework/hooks/enforcement/auto-trigger-orchestrator.mjs`: the header comment and the no-run message tell the agent to load the orchestrator and route the request as the Routing Directive says. The message names the Feature Pipeline and no other track.
- `ravintio-framework/templates/standard-boot.md` lines 28 and 29: drop the Fast Path scope record sentences from the `gate-write` and `shell-write-guard` entries. req-002 owns the hook code. This requirement owns only the boot text, so the two stay in step.
- `ravintio-framework/templates/component-guide.md` lines 17, 89, and 146, and `templates/domain-glossary-guide.md` line 56: name the agent that changes a component in a Feature Pipeline run (`codegen-agent`), not `change-agent`.
- Docs that describe routing:
  - `README.md` line 138: the overhead note no longer offers a fast-path workflow as relief. req-004 owns line 112, so the residue check for `README.md` belongs to req-006.
  - `ravintio-framework/getting-started.md` lines 103 and 104: drop the Fast Path and Change Pipeline rows.
  - `ravintio-framework/pipeline-reference.md`: drop the `PC:` row (line 23), the Fast Path section that starts at line 119, and the `## Change Pipeline` section. req-003 owns the `### fast-path prefix` section, and req-002 owns the gate text.
  - `src/setup-hook-integration/docs/scope.md` line 38: drop "via change-agent".
- Out of this requirement:
  - req-002 owns the hook code and the gate text in `project-operations.md`, `pipeline-reference.md`, and the docs.
  - req-003 owns pre-push, both CI files, and their docs.
  - req-004 owns the deleted files and the installed-file listings in `README.md` line 112 and `tool-setup-reference.md`.
  - req-007 owns the ADR supersede notes, `docs/decisions-index.md`, `docs/architecture-overview.md`, `component.yml`, and the version bump.
- `ravintio-framework/external-skills/plan-eng-review/SKILL.md` line 1148 uses "Fast path" to mean "every code path is covered". It names no RAVINTIO track. Leave the vendored file unchanged. req-006 lists it on the residue allowlist.
- Rewrite these suites test-first, so each asserts one-track routing:
  - `ravintio-framework/tests/test-0000032-req-003-no-run-triage-message.sh` and its copy in `tests/regression/`. The message names the Feature Pipeline and no other track.
  - `ravintio-framework/tests/test-0000032-req-004-handover-note-routing.sh` and its copy in `tests/regression/`. The rule names the Feature Pipeline, not Fast Path or Change Pipeline.
- Remove `ravintio-framework/tests/test-0000033-req-011-lightweight-track-for-no-src.sh`. Its subject, the Fast Path no-src prerequisite and the track table, no longer exists. The new req-001 suite covers the no-src route.
- `test-0000032-req-005-blocking-context-clear.sh` and `test-0000038-req-001-stable-windows-timing.sh` need no change. The triage rule and the suite names they read both stay.
- Add `ravintio-framework/tests/test-0000040-req-001-one-track-routing.sh` for the first two criteria.
- Split step: keep. The one concern is the route a request takes, as every skill, template, hook message, and doc states it. Each file only restates that route, so none could ship alone without leaving two routes on offer.

## Acceptance Criteria
- [ ] In `skills/ravintio-orchestrator/SKILL.md`, the Routing Directive sends a request with or without a `src/` target to the Feature Pipeline, unless it meets a standalone skill trigger. The Standalone Skills table names `ravintio-optimise-agent`, `ravintio-refresh-setup`, and retrofit. The file holds no `Three-Track Decision Tree`, no `Fast Path Criteria`, no `PC:` row, no `Invoking the Change Pipeline` section, and no Change Pipeline clause in Hard Limit 10. Verified by: unit
- [ ] None of these files contains "Fast Path", "fast-path", "Change Pipeline", "change-pipeline", or "change-agent": both phase 0 references, `standard-boot.md`, the ship, adr, and optimise skills, both template guides, `getting-started.md`, and `src/setup-hook-integration/docs/scope.md`. `pipeline-reference.md` holds no `PC:` row, Fast Path section, or `## Change Pipeline` section. The version bump table holds only the Feature Pipeline and Breaking change rows. Ship Hard Limit 6 and Step 11 name the Feature Pipeline. Verified by: unit
- [ ] Run with no `plan/.orchestrator-active`, `auto-trigger-orchestrator.mjs` prints a message that loads `ravintio-orchestrator` and names the Feature Pipeline. The message names neither Fast Path nor the Change Pipeline. The rewritten 0000032 req-003 and req-004 suites pass in `tests/` and `tests/regression/`. Verified by: integration

## Dependencies
- req-002 (gates-ignore-scope-record) removes the scope record from the hook code that the boot text describes.
- req-003 (no-commit-subject-exemption) owns the `fix(fast-path):` text in `pipeline-reference.md` and `project-operations.md`.
- req-004 (remove-track-files) deletes `workflows/fast-path.md`, `workflows/change-pipeline.md`, and `skills/ravintio-change-agent/`, which this requirement stops pointing to.
- req-006 (residue-guard) checks the whole repo for residue and allowlists the `plan-eng-review` line.
- req-007 (docs-and-adr-supersede) adds the supersede notes on 0000033 ADR-009 and the bump-rules ADR-004.
- P3 changes each `tests/regression/` copy together with its source suite in `tests/`.
