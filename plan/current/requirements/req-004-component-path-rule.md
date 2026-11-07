---
title: "Requirement: req-004 - component-path-rule"
summary: "The codegen close-out and the ship fallback find each component manifest from the design and product.yml, never from ravintio-framework/component.yml, and one manifest-location rule has one owner."
status: "draft"
version: "0.1.0"
---
# Requirement: req-004 - component-path-rule

**Skill:** [spec-agent](../../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Source:** US-002, backlog 0000061 and 0000361
**Priority:** must-have

## User Story

As a consumer repo owner, I install a pack that has `release.yml` and no `component.yml`, so that my runs never count the pack as my source and still detect each pack update.

This requirement serves the first half of US-002. Today the codegen close-out bumps a copied `ravintio-framework/component.yml`, and the ship fallback tags from it. Both count the pack as the consumer's source. One manifest rule that reads component paths removes both. The brief's sixth acceptance criterion names this outcome.

## Functional Requirements

All paths below use the post-move layout. P3 edits the pack under `src/ravintio-framework/`.

### The manifest-location rule

- `src/ravintio-framework/templates/component-guide.md` owns the rule, in its `## File location` section. The rule reads as follows:
  - A component manifest lives at the path that the root `product.yml` lists for that component in `components[]`.
  - If `product.yml` doesn't exist, or doesn't list the component, the manifest lives at `src/{component-id}/component.yml`. That is the default.
  - The component's folder is the folder that holds its manifest.
- The section keeps the fenced `src/{{component-id}}/component.yml` line as the default, and adds the rule above it.
- `src/ravintio-framework/skills/ravintio-spec-agent/SKILL.md` states no rule of its own. Each of its three manifest lines (the `## What You Produce` sentence, the Component Manifest table row, and the first `**Component manifest:**` bullet) points to the rule in `component-guide.md` by link. The table row may keep `src/{component-id}/component.yml` only when it labels it as the default.
- `src/ravintio-framework/skills/ravintio-docs-agent/SKILL.md` states no rule of its own. Two lines change:
  - The `## Input` line on the implementation reads each component from its folder under the rule, with a link to `component-guide.md`.
  - The drift table's `Component boundaries` row checks the manifest paths that `product.yml` lists, with the default for a component it doesn't list.
- Per-component docs keep the `src/{component-id}/docs/` line in docs-agent. This requirement moves no docs path. Backlog 0000384 covers the pack's docs folder.

### The codegen close-out

- In `src/ravintio-framework/skills/ravintio-codegen-agent/SKILL.md`, the `**Framework component.yml close-out:**` block becomes a component manifest close-out. It names no file under `ravintio-framework/`.
- The close-out runs before the P3 commit. It finds the run's components as follows:
  1. Read the components from the design's `## Engineering Layer` Components list.
  2. Find each manifest under the manifest-location rule.
  3. A component changed when any file under its folder changed in this P3 run.
- For each changed component, the close-out increments the minor version in its manifest and sets `feature` to the current feature ID. It stages that manifest in the P3 commit.
- A changed file under a `## Component Paths` entry that holds no listed manifest bumps nothing. In the source repo, the root `ravintio-framework/` release copy is such a path.
- The close-out applies to every kind of change: docs-only, skill text, template, migration, and code.
- ADR-006 adds four rules, and the close-out states each one:
  - If two component folders hold a changed file, the deeper folder's component owns it.
  - If `product.yml` lists a manifest path with no file, the close-out stops and reports it. It never falls back or creates a manifest.
  - A changed file is one that differs from the `HEAD` at P3 start, so the TDD commits count.
  - If a manifest's `feature` already holds the current feature ID, the close-out doesn't bump it again.

### The ship fallback

- In `src/ravintio-framework/skills/ravintio-ship-agent/SKILL.md`, Step 9 case 2 (no `product.yml`, one component) reads the single component from the design. Step 6 has archived the design by P9, so the case reads `plan/_archive/{feature-folder}/design.md`. It then reads `version` from that component's manifest under the manifest-location rule.
- Case 2 names no repo and no `ravintio-framework/component.yml` example. If the design lists no component or more than one, case 2 stops and reports it. It never tags.
- Step 5b's exit 4 text keeps its meaning. If it names the single `component.yml`, it points to the same rule.

### Tests

- New suite: `src/ravintio-framework/tests/test-0000041-req-004-component-path-rule.sh`. It reads the four files above.
- These suites read the changed text and must stay green. Recheck them in P3:
  - `test-0000035-req-002-product-yml-in-p7.sh` and its copy in `tests/regression/`
  - `test-0000033-req-013-clean-close-out.sh`
  - `test-0000040-req-006-residue-guard.sh` and its copy in `tests/regression/`

Split step: keep, at three criteria. The one concern is that each skill finds a component manifest by one rule. The codegen and ship changes apply the rule, and they ship no value on their own without it.

## Acceptance Criteria

- [ ] `component-guide.md` `## File location` states the rule: the path `product.yml` lists, else `src/{component-id}/component.yml`. spec-agent and docs-agent each link to that section. Neither skill states a manifest location that contradicts it, and neither names `src/{component-id}/component.yml` without labelling it the default. The docs-agent drift row reads the manifest paths from `product.yml`. Verified by: integration
- [ ] The codegen close-out reads components from the design's Components list and their manifests under the rule. It bumps each changed component's manifest and stages it. It states that a changed path with no listed manifest bumps nothing. No line of the codegen `SKILL.md` names `ravintio-framework/component.yml`. Verified by: integration
  - The close-out text states the four ADR-006 rules: the deeper folder wins, a missing listed path stops, the P3-start `HEAD` baseline, and one bump per feature.
- [ ] Ship Step 9 case 2 reads the single component from the archived design and its manifest under the rule. It stops and reports when the design lists zero or two or more components. No line of the ship `SKILL.md` names `ravintio-framework/component.yml`. Verified by: integration
  - A path that ends in `ravintio-framework/component.yml`, such as one under `src/`, counts as a match.

## Dependencies

- req-001 (move-pack-to-src) moves the four files to `src/ravintio-framework/` and points `product.yml` at `src/ravintio-framework/component.yml`.
- req-003 (release-yml-readers) owns the other live texts that name `ravintio-framework/component.yml`: the orchestrator, the migrator, and `standards/framework-update-policy.md`. This requirement touches none of them.
- req-008 (tests-and-ci-from-src) provides the resolver the new suite uses to read the pack from `src/ravintio-framework/`.
- Existing pattern: 0000040 ADR 003 reads component folders from `product.yml`.
