---
title: "Requirement: req-007 - docs-and-adr-supersede"
summary: "The docs describe one track, the decisions index marks the Fast Path and track ADRs as superseded, and the release carries version 0.38.0."
status: "draft"
version: "0.1.0"
---
# Requirement: req-007 - docs-and-adr-supersede

**Skill:** [spec-agent](../../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Source:** US-001
**Priority:** must-have

## User Story

As a human on the loop, I read docs and decisions that describe one track, so that no page offers Fast Path or the Change Pipeline as a route.

## Functional Requirements
- Rewrite each passage that offers Fast Path, the Change Pipeline, `ravintio-change-agent`, or the `PC:` prefix. The text routes every change to the Feature Pipeline instead. These files hold such passages today:
  - `README.md` (the workflows row and the overhead note)
  - `ravintio-framework/getting-started.md`
  - `ravintio-framework/pipeline-reference.md` (the prefix table and the track sections)
  - `ravintio-framework/project-operations.md`
  - `ravintio-framework/tool-setup-reference.md` (the installed commands and skills)
  - `docs/architecture-overview.md` (the no-src and scope record sections, the data owner list, and the decision list)
  - `docs/component-registry.md` (the `ravintio-framework` row)
  - `docs/dependency-graph.md` (the `path-rules.mjs` note)
  - `docs/decisions-index.md` (the entries below)
  - `src/setup-hook-integration/docs/interface-contract.md` (the enforcement list section)
  - `src/setup-hook-integration/docs/scope.md` (the change-agent note)
  - `src/setup-hook-integration/docs/test-coverage.md` (the 0000035 suite list)
  - `ravintio-framework/component.yml` (the capability line from 0000033)
- If `FAST_PATH_ENFORCEMENT_PATHS` survives under a new name, the docs use the name that P2 decides.
- Archived ADR files under `plan/_archive/` stay as written. The supersession lives in `docs/decisions-index.md` and in the new 0000040 ADRs, as in earlier features such as 0000033 ADR 010.
- In `docs/decisions-index.md`, change the Status cell and add a `**Superseded:**` note to each of these entries:

| Entry | Source ADR file | New status |
|-------|-----------------|------------|
| 0000014 ADR 004, version bump rules by track | `plan/_archive/0000014-improve-adoption-mode-selection-2026-05-19/adr/`, file `version-bump-rules-by-track` | `partly superseded by 0000040 ADR-{n}`. The Fast Path and Change Pipeline patch rule goes. The minor and major rules stay. |
| 0000033 ADR 009, Fast Path admits no-src changes | `plan/_archive/0000033-human-on-the-loop-run-mode-2026-10-19/adr/`, file `fast-path-admits-no-src-changes` | `superseded by 0000040 ADR-{n}` |
| 0000035 ADR 002, scope record as self-authorisation | `plan/_archive/0000035-write-gate-scope-and-path-hardening-2026-10-22/adr/`, file `fast-path-scope-record-self-authorisation` | `superseded by 0000040 ADR-{n}` |
| 0000035 ADR 003, scope record staleness from git files | file `scope-record-staleness-from-git-files` in the same folder | `superseded by 0000040 ADR-{n}` |
| 0000035 ADR 004, Fast Path enforcement path list | file `fast-path-enforcement-path-list` in the same folder | `superseded` if P2 drops the list, or `partly superseded` if the list survives under a new name |

- `{n}` is the 0000040 ADR that P2 writes for each decision.
- 0000035 ADR 003 reads only the scope record, so it falls with ADR 002 although the design does not name it.
- Add a Feature 0000040 section to the decisions index for the new ADRs, and update its `Last updated` line.
- The release is 0.38.0, a minor bump from 0.37.2, as the design suggests. Each file has one owner:

| File | Owner | Phase and step |
|------|-------|----------------|
| `ravintio-framework/component.yml` `version` | codegen agent | P3, in the P3 commit, so the ship agent reads the right version for the tag |
| `ravintio-framework/component.yml` history comment | docs agent | P6, an `Updated by 0000040 (docs-agent) P6` comment |
| `product.yml` `version` and `feature` | ship agent | P7 Step 5b, through `set-product-release.mjs` only |
| `docs/about.md` frontmatter and table | ship agent | P7 Step 6b |

- The codegen agent writes the live-doc rewrites in P3, before the req-006 guard runs, per the execution plan's build order. At P6 the docs agent checks them and writes the decisions-index notes.
- P1 critic revision: the rewrite list also covers `src/setup-hook-integration/docs/quirks.md` and `src/setup-hook-integration/docs/tech-debt.md` (TD-011). Both name `FAST_PATH_ENFORCEMENT_PATHS` or the scope record.
- P1 critic iteration 2 revision: the decisions-index Status cells, the `**Superseded:**` notes, and the superseding notes in `docs/architecture-overview.md` also land in P3, before the req-006 guard. P2 has numbered the 0000040 ADRs by then. At P6 the docs agent checks them and adds the Feature 0000040 section.
- Approach 2 revision for `docs/architecture-overview.md`:
  - Delete the sections "Fast Path for changes with no src target" (heading at line 253) and "Fast Path scope record" (heading at line 290), with their bodies. Both describe retired mechanisms.
  - Delete the `plan/.fast-path-scope` row in the data owner list (line 492).
  - Keep the decision list lines 547, 551, and 552. Each gains `superseded by 0000040 ADR-{n}` on the same line.
  - If P2 keeps the enforcement path list under a new name, add a short section under that name, with no retired-track words.
- Each new line in the decisions index, the architecture overview, `docs/about.md`, and the `component.yml` history comment names its feature ID on the same line, as req-006's history-line rule needs.
- Approach 2 iteration 2 revision: the new decisions-index section heading reads `### Feature 0000040-retire-fast-path`, with the hyphen. The req-006 strip step removes that exact ID, so the heading passes the guard. Every other new line that names the feature uses the same full ID.
- Approach 3 revision: req-006's guard algorithm governs how the guard reads these lines. Its history-line rule reads the unstripped line, so the full ID counts as a feature ID. Each new decisions-index and architecture-overview line that names a retired track also holds `ADR` or a superseding note.
- Criterion timing: the first and second criteria first run at the end of P3, after this requirement's P3 step. They run again after P6, as they state. The third criterion runs after P7.
- This requirement owns every file in the rewrite list, per the execution plan's file ownership table. It carries the routing, gate, CI, and installed-file text that req-001 to req-004 state.
- `src/setup-hook-integration/component.yml` keeps its own version. `product-version.mjs` takes the highest component version, which is 0.38.0.
- Split step: keep. The rewrite, the superseding notes, and the version bump form one outcome. A reader sees one track in every live record of the release. The count stays at three criteria.

## Acceptance Criteria
- [ ] After P6, the req-006 guard reports no unallowed match in any file this requirement lists. Each rewritten passage routes every change to the Feature Pipeline. Verified by: integration
- [ ] After P6, the five decisions-index entries carry the new status and a `**Superseded:**` note that names a 0000040 ADR. `git diff main -- plan/_archive/` prints nothing. Verified by: integration
- [ ] After P7, `ravintio-framework/component.yml`, `product.yml`, and `docs/about.md` each read 0.38.0, and `product-version.mjs` prints 0.38.0. Verified by: execution - the ship agent runs `product-version.mjs` at P9 Step 9 and compares it with the confirmed version

## Dependencies
- req-001 removes the track rows from the version bump table in the phase 0 reference. This requirement records the matching decision.
- req-002 and P2 decide whether the enforcement path list survives and under which name.
- req-004 deletes the files that the docs stop naming.
- req-006 supplies the guard that the first criterion runs.
