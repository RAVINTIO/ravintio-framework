---
title: "Feature Brief - Retire Fast Path"
summary: "Remove the Fast Path track so every change runs the Change Pipeline or the Feature Pipeline."
status: "draft"
version: "0.1.0"
---
# Feature Brief - Retire Fast Path

**Feature ID:** 0000040-retire-fast-path

> The orchestrator drafted this brief from backlog entries 0000358, 0000152, and 0000200, and from F1 in 0000355. The human on the loop confirms it through the design.

## Business Goal

Framework serves regulated teams, and every change there needs a record and a control that fits its risk. Fast Path lets a change skip the Feature Brief, the execution plan, and the ADRs. On 2026-10-31 the owner decided Framework keeps no fast option. Quick, uncontrolled changes belong in RAVINTIO Zero.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Two-track routing | As a human on the loop, I see every request routed to the Change Pipeline or the Feature Pipeline, so that every change leaves a pipeline record. | must-have | 1 |
| No bypass in gates or CI | As a human on the loop, I rely on the write gates, pre-push, and CI to admit nothing on a Fast Path basis, so that neither a scope record nor a commit subject can skip a control. | must-have | 1 |
| Clean consumer upgrade | As a consumer repo owner, I upgrade and lose every Fast Path file and leftover scope record, with a notice, so that nothing stale admits a change. | must-have | 1 |

## Waves

One wave. The three stories ship together.

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| `ravintio-framework` | component-pack | existing | Skills, hooks, setup scripts, templates, migrations, and tests for the pipeline |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| Pack files under `ravintio-framework/` | `ravintio-framework` | consumer repos, read only after setup |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| `setup.sh`, `setup.ps1` | consumer tool folders | file copy | installed skills, commands, and hook wiring |
| `hooks/ravintio.yml` | consumer CI | file copy | GitHub Actions workflow |

## Stack

Unchanged from the pack: Bash and PowerShell setup, Node.js `.mjs` hooks and scripts, Bash test suites run by `run-tests.sh`, and GitHub Actions CI.

## Scope Boundaries

### In Scope
- Two-track routing in the orchestrator, phase 0 reference, boot template, and docs.
- Delete the Fast Path workflow and its installed skill and command. Setup removes installed copies.
- Remove the scope record from `gate-write`, `shell-write-guard`, and `ratchet-check`.
- Remove the `fix(fast-path):` exemption from pre-push and the CI template.
- A migration that deletes a stale `plan/.fast-path-scope` and tells the human on the loop.
- Remove or rewrite the Fast Path tests.

### Out of Scope
- History under `plan/_archive/`, `plan/changelog/`, and released migration files.
- The incident hotfix path (0000359).
- The advisory pre-commit and presence-only checks left in 0000308.

### Deferred
- Nothing deferred yet.

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| Test suite | 0 failures on Linux, macOS, and Windows shards | CI on the PR |
| Residue | 0 live references to Fast Path outside history and released migrations | brand-guard-style search suite |

## Constraints and Assumptions

### Constraints
- Released migration files never change.
- Every hook change keeps `gate-write` and `shell-write-guard` in parity.

### Assumptions
- No consumer depends on `FAST_PATH_ENFORCEMENT_PATHS` outside the pack.

## Acceptance Criteria

- [ ] No skill, command, hook, or CI rule admits a change without a pipeline record.
- [ ] A request that Fast Path used to take routes to the Change Pipeline.
- [ ] A consumer repo that upgrades loses the Fast Path files, and a leftover scope record admits nothing.
- [ ] Tests check that `gate-write` ignores `plan/.fast-path-scope` and that CI no longer exempts `fix(fast-path):` branches.
