---
title: "ADR 006: Manifest location read from product.yml"
summary: "A component manifest lives at the path product.yml lists, with src/{component-id}/component.yml as the default. component-guide.md owns the rule, and spec-agent and docs-agent link to it. The codegen close-out and the ship fallback find each manifest under the rule and never name ravintio-framework/component.yml."
status: "accepted"
version: "0.1.0"
---
# ADR-006 - Manifest location read from product.yml

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Component:** ravintio-framework
**Date:** 2026-11-07

## Context

Four pack texts say where a component manifest lives. They don't agree:

- `templates/component-guide.md` `## File location` shows only `src/{{component-id}}/component.yml`.
- `skills/ravintio-spec-agent/SKILL.md` writes the manifest to `src/{component-id}/component.yml` in three lines.
- `skills/ravintio-docs-agent/SKILL.md` checks component boundaries against `src/` folders that hold a `component.yml`.
- `skills/ravintio-codegen-agent/SKILL.md` bumps `ravintio-framework/component.yml` whenever a file under `ravintio-framework/` changes.

The root `product.yml` already lists a manifest path for each component. In this repo, the pack manifest sits outside `src/`, so the `src/` texts are wrong for it (backlog 0000061).

The codegen close-out has a second fault. A consumer repo holds a copied `ravintio-framework/component.yml`. The close-out bumps that copy as if the pack were the consumer's source. Ship Step 9 case 2 then tags the consumer's repo from it (backlog 0000361).

ADR-002 moves the pack source to `src/ravintio-framework/`, and req-001 points `product.yml` at `src/ravintio-framework/component.yml`. The root `ravintio-framework/` copy then ships with `release.yml` and no manifest. A rule that names `ravintio-framework/component.yml` would find no file.

0000040 ADR 003 set the pattern this ADR follows. The source folder rule reads component folders from `product.yml` and never scans the tree. The requirement req-004 sets the outcome here.

## Decision

### The manifest-location rule

`src/ravintio-framework/templates/component-guide.md` owns one rule in its `## File location` section:

1. A component manifest lives at the path that the root `product.yml` lists for that component in `components[]`.
2. If `product.yml` doesn't exist, or doesn't list the component, the manifest lives at `src/{component-id}/component.yml`. That is the default.
3. The component's folder is the folder that holds its manifest.

The section keeps the fenced `src/{{component-id}}/component.yml` line and labels it the default.

spec-agent and docs-agent state no rule of their own. Each manifest line links to the `component-guide.md` section:

- spec-agent: the `## What You Produce` sentence, the Component Manifest table row, and the first `**Component manifest:**` bullet. The table row may keep `src/{component-id}/component.yml` only as the labelled default.
- docs-agent: the `## Input` line reads each component from its folder under the rule. The drift table's `Component boundaries` row checks the manifest paths that `product.yml` lists, with the default for an unlisted component.

Per-component docs keep `src/{component-id}/docs/`. This ADR moves no docs path. Backlog 0000384 covers the pack's docs folder.

### Reading product.yml

Skills read `product.yml` in the fixed layout that 0000040 ADR 003 reads. Each `id:` and `path:` pair sits inside the `components:` block. ADR-001 keeps the stack, so no YAML library applies.

A listed path takes priority over the default, even when a file also exists at the default. If `product.yml` lists a path and no file exists there, the reader stops and reports the path. It never falls back to the default and never creates a manifest at either place.

### The codegen close-out

The `**Framework component.yml close-out:**` block in `src/ravintio-framework/skills/ravintio-codegen-agent/SKILL.md` becomes a component manifest close-out. It runs before the P3 commit and names no file under `ravintio-framework/`. It takes three inputs:

| Input | Source |
|-------|--------|
| The run's components | The design's `## Engineering Layer` Components list |
| Each component's manifest | `product.yml`, under the manifest-location rule |
| The changed files | Files under the design's `## Component Paths` entries that changed in this P3 run |

A changed file belongs to the component whose folder holds it. If two component folders hold the file, the deeper folder wins. For each component with a changed file, the close-out takes these steps:

1. Increment the minor version in its manifest.
2. Set `feature` to the current feature ID.
3. Stage the manifest in the P3 commit.

A file changed in this P3 run when it differs between the commit `HEAD` held as P3 began and the working tree. P3's granular TDD commits therefore still count. If a manifest's `feature` already holds the current feature ID, a repeat P3 run leaves its version alone. A reversal that reruns P3 then bumps each manifest once per feature.

A changed file under a `## Component Paths` entry that holds no listed manifest bumps nothing. In the source repo, the root `ravintio-framework/` release copy, `.github/workflows/ravintio.yml`, and `./README.md` are such paths. The close-out applies to every kind of change: docs-only, skill text, template, migration, and code.

### The ship fallback

Ship Step 9 case 2 covers a repo with no `product.yml` and one component. By P9, Step 6 has archived the design, so case 2 reads the single component from `plan/_archive/{feature-folder}/design.md`. It then reads `version` from that component's manifest under the rule. With no `product.yml`, the rule gives the default path.

If the design lists no component, or two or more, case 2 stops and reports it. It never tags. Case 2 names no repo and drops the `ravintio-framework/component.yml` example. Step 5b's exit 4 text keeps its meaning and points to the same rule.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Always use `src/{component-id}/component.yml`, with no `product.yml` lookup | One fixed path, and no file to read | It contradicts `product.yml` for any component listed elsewhere, such as the 0000040 vendored pack layout. A second rule would then disagree with the version script, which reads the listed paths. | `product.yml` already holds the paths, and two sources of truth drift |
| Scan the repo for `component.yml` files | No list to keep | A consumer's copied `ravintio-framework/component.yml` reads as a component, which is the 0000361 fault. A stray or test-fixture manifest widens the set. | 0000040 ADR 003 rejected a scan for the same reason |
| Keep the close-out keyed on a changed `ravintio-framework/` file, and point it at `src/ravintio-framework/component.yml` | Smallest edit to codegen | It still hard-codes one repo's layout, and a consumer's run still has no rule for its own components | It fixes this repo only and leaves 0000361 open in consumers |
| Let each skill state the rule in full | Each skill reads on its own | Three copies of one rule drift, which is the 0000061 fault | req-004 gives the rule one owner, `component-guide.md` |
| Fall back to the default when a listed path has no file | The run carries on | A typo in `product.yml` bumps or creates a manifest that the version script never reads | A loud stop surfaces the typo before P9 tags a wrong version |
| Map changed files to components through `## Component Paths` entries alone | Uses the design's own list | `## Component Paths` is a flat list with no component per entry, so it can't attribute a file | The manifest folder gives one owner for each file, and `## Component Paths` bounds which files count |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | `component-guide.md` gains the rule. spec-agent, docs-agent, codegen-agent, and ship-agent text changes under `src/ravintio-framework/`. The new suite `tests/test-0000041-req-004-component-path-rule.sh` reads the four files through the ADR-009 resolver. The suites req-004 names stay green. |
| setup-hook-integration | Its manifest stays at `src/setup-hook-integration/component.yml`, which `product.yml` lists. Its code lives under `src/ravintio-framework/`, so a change to that code bumps the `ravintio-framework` manifest, not its own. This matches today's close-out. |

## Consequences

**Positive:**
- One rule in `component-guide.md` answers where a manifest lives, and three texts link to it (req-004 AC1, backlog 0000061).
- A consumer run never bumps the copied pack manifest. Its tags come from its own components (backlog 0000361).
- The close-out works in any repo layout that `product.yml` describes, with no repo name in skill text (req-004 AC2).
- The ship fallback stops rather than tags when the design names zero or several components (req-004 AC3).
- The rule reads the same list as the version script and the 0000040 ADR 003 source folder rule, so the three can't disagree.

**Negative:**
- Each skill that finds a manifest now reads `product.yml` first, which adds a step to the close-out and to ship.
- A listed path with no file stops the run, where the old close-out would carry on. A human on the loop must fix `product.yml` first.
- `setup-hook-integration` code changes bump the pack manifest, not its own, because its folder holds only its manifest and docs. Its version tracks its docs, not its code.
- The line-based read accepts only the fixed `product.yml` layout. A flow-style list reads as no entry, and the default applies.

**Risks:**
- A consumer's `product.yml` may list `ravintio-framework/component.yml`. After the 0.39.0 migration removes that file, the close-out stops on the missing path. R-013 and the req-006 `listed in product.yml` skip cover the same file.
- A consumer that keeps the copied manifest and lists it would still bump the pack copy. R-004 covers the leftover file, and ADR-008 offers its removal.
- The close-out finds the changed files from git history. A wrong base would bump too much or too little. P4 and the req-004 suite check the result.

## Related ADRs

- 0000040 ADR 003 - extends: the same `product.yml` read, applied to manifest paths instead of source folders.
- ADR-001 - depends-on: the stack decision rules out a YAML library, so the read is line-based.
- ADR-002 - depends-on: the move puts the pack manifest at `src/ravintio-framework/component.yml` and leaves the root copy without one.
- ADR-007 - related-to: the source-repo signal also reads `product.yml` for the `ravintio-framework` entry.
- ADR-008 - related-to: the consumer migration removes the copied manifest that this rule no longer reads.
- ADR-009 - related-to: the new suite reads the four texts through the single resolver.

## Supersedes

- None

## Superseded By

- None
