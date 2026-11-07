---
title: "ADR 002: Pack source under src"
summary: "The pack source and its component.yml move to src/ravintio-framework/ in one approved git pass. The root ravintio-framework/ becomes a workflow-only copy of the last release, which P7 alone refreshes. Consumers keep the ravintio-framework/ runtime path."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Pack source under src

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Component:** ravintio-framework
**Date:** 2026-11-07

## Context

Today the pack source sits at the root `ravintio-framework/`, with its `component.yml`. Consumers copy that folder as it stands. Their runs then read the pack manifest as their own source. They bump it, and they can tag from it (backlog 0000361).

This repo has a second problem. It runs on the same folder it changes. A broken hook or skill edit can break the run that builds it (US-001).

The human on the loop decided this at P0 (0000361). This repo keeps `ravintio-framework/` as a workflow-only copy, and the pack source and its manifest live under `src/`. Three later P0 answers set the method:

- The root copy holds the last release and refreshes at P7 only. Tests and CI run against `src/`.
- One git pass moves the pack, approved as a recorded exception to the Write-or-Edit rule (boot Hard Limit 8).
- Follow-up content edits use **Edit**.

The pass moves 1,184 tracked files. A P1 check found the annotated tag `v0.38.0` at commit `2595f850`. The root pack matched that tag with no diff.

## Decision

Move the pack source to `src/ravintio-framework/`, with its `component.yml`. Keep the root `ravintio-framework/` as a workflow-only copy of the last release, which is `v0.38.0` now.

1. P3 confirms that `git tag -l v0.38.0` prints `v0.38.0`.
2. P3 runs one git pass, in this order:
   1. `git mv ravintio-framework src/ravintio-framework`
   2. `git checkout v0.38.0 -- ravintio-framework`
3. The result lands in one commit with no content edit (req-001). The root copy stays byte-identical to `v0.38.0`, `component.yml` included.
4. The build log records the two commands and the commit hash. P3 runs the req-001 AC1 git checks before any follow-up edit.
5. Every follow-up content change uses **Edit**, in later commits.

The pass is a recorded exception to the Write-or-Edit rule (boot Hard Limit 8), as 0000039 ADR 008 was. The human on the loop approved it at P0, so the run does not stop for approval again. The exception covers these two commands only.

The root copy refreshes only at P7. The release script rebuilds it from `src/ravintio-framework/` without `component.yml` (ADR-003). No pack change before P7 reaches the root copy. Until this run's P7, the root copy keeps its 0.38.0 `component.yml`.

`ravintio-framework/` stays the consumer runtime path in every pack file. Consumers copy the root folder and run setup from it, as today.

If the pass stops partway, P3 resets the working tree to the last commit and repeats the pass. This is the Scope Lock cross-session path.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Copy the pack to `src/` and leave the root in place | The root copy never changes during the pass | Git records about 1,184 new files, not renames, so `git log --follow` loses each file's history. A shell copy is also a Bash write that Hard Limit 8 bars. | `git mv` keeps history, and the human on the loop chose it at P0 |
| Rebuild the root copy after every pack change | The root copy always matches `src/` | A broken `src/` change reaches the live hooks and skills of the run that made it, which defeats US-001. Every rebuild also adds a large diff to review. | The human on the loop chose the P7-only refresh at P0 |
| Keep the source at the root and publish from a release branch | No path change in the repo, and no git pass | Consumers would copy from a second branch, and `main` would still carry `component.yml`. This repo would still run on the folder it changes, so US-001 fails. | It fixes neither 0000361 nor US-001 |
| Move the pack with a scratchpad script, as 0000039 ADR 008 did | One reviewed script runs the whole pass | Two git commands need no script, and a script widens the Hard Limit 8 exception | Two named commands give the smallest exception |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Its source and manifest move to `src/ravintio-framework/`. `product.yml` lists it at `src/ravintio-framework/component.yml` (req-001). The root copy becomes release output with no manifest after P7. |
| setup-hook-integration | Its manifest and docs stay at `src/setup-hook-integration/`. Its source paths point into `src/ravintio-framework/`, and its runtime paths stay `ravintio-framework/` (req-001). |

## Consequences

**Positive:**
- A broken pack change under `src/` can't break the run that builds it, because this run's hooks and skills come from the 0.38.0 root copy (US-001, R-010).
- After P7, consumers copy a folder with no `component.yml`, so their runs stop bumping or tagging the pack (0000361, US-002).
- `git mv` keeps each file's history, and git reports the pass as renames.
- The pass commit holds no content edit, so reviewers can check it with three git commands (req-001 AC1, R-005).

**Negative:**
- Every repo path that names the pack source needs an **Edit** after the pass. That covers `product.yml`, `.gitattributes`, `em-dash-guard.mjs`, and the setup-hook-integration docs (req-001, R-008, R-011).
- Suites and CI must read the pack from `src/` through one resolver. Six suites that set `REPO_ROOT` to the pack's parent need a fix (req-008, R-007, A-002).
- From P3 to P6, this run can't exercise its own hook and skill changes in live sessions. Only suites test them (R-010, R-012).
- This run's P7 uses the 0.38.0 ship agent, which lacks the release step. P7 runs the release script from `src/` as a recorded decision (R-003, ADR-003).

**Risks:**
- A suite still reads the root copy and passes against 0.38.0, which hides a broken `src/` change (R-001). ADR-009 makes the resolver fail such a suite.
- `markedRoot()` can resolve the repo root to `src/`, because `src/` now holds a `ravintio-framework/` folder (R-006). The fault fails closed, and backlog 0000382 tracks the fix.
- The pass diff is large enough to hide a real change (R-005). The no-content-edit rule and the AC1 checks contain it.

## Related ADRs

- ADR-001 - related-to: the move adds no language or tool.
- ADR-003 - depends-on: the release script rebuilds the root copy at P7.
- ADR-004 - related-to: readers fall back to `component.yml` while the root copy is still 0.38.0.
- ADR-005 - related-to: it assigns ownership of the `src/` source and the root copy.
- ADR-009 - depends-on: tests and CI read the moved source through one resolver.

## Supersedes

- None

## Superseded By

- None
