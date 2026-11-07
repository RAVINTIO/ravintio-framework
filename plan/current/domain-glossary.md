---
title: "Domain Glossary - pack-source-under-src"
summary: "Definitions of the terms used in moving the pack source under src and releasing a root copy with no manifest."
status: "draft"
version: "0.1.0"
---
# Domain Glossary - pack-source-under-src

**Skill:** [spec-agent](../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000041-pack-source-under-src
**Version:** 0.39.0

> The ubiquitous language for this feature. If the glossary says "Order", the code says `Order` - not "Purchase" or "Transaction". Never invent new terms without adding them here.

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| pack | The `ravintio-framework` component, of type `component-pack`. It holds the standards, skills, hooks, scripts, and setup for the pipeline. | RAVINTIO Framework, component pack | ravintio-framework |
| framework source | The repo that builds the pack. After this feature, the source-repo signal identifies it. It is also a `**Applies to:**` value. | framework source repo, source repo | ravintio-framework |
| consumer repo | A repo that installs the pack by copying the root `ravintio-framework/` into its own root. It is the `downstream` value of the `**Applies to:**` header. | consumer, downstream project | ravintio-framework |
| pack source | `src/ravintio-framework/`, the folder the maintainer edits. It holds the pack's `component.yml`, and `product.yml` lists it. | | ravintio-framework, setup-hook-integration |
| root copy | The root `ravintio-framework/` in the framework source. It holds the last release, with `release.yml` and no `component.yml`. Only the git pass and the release script write it. From the git pass until this run's P7, it is the `v0.38.0` tree with its `component.yml`. | release copy | ravintio-framework |
| vendored pack | The copy of `ravintio-framework/` in a consumer repo. It counts as source only if that repo's `product.yml` lists it (0000040). | copied pack | ravintio-framework |
| consumer runtime path | `ravintio-framework/`, the path every pack file uses to name the installed pack. This feature keeps it. | | ravintio-framework |
| git pass | The one P3 commit that runs `git mv ravintio-framework src/ravintio-framework`, then `git checkout v0.38.0 -- ravintio-framework`. It is a recorded exception to the Write-or-Edit rule (boot Hard Limit 8). | the move | ravintio-framework |
| release script | `scripts/build-release.mjs` in the pack. It rebuilds the root copy from the pack source without `component.yml` and writes `release.yml`. The Write-or-Edit rule names it as a sanctioned script. | | ravintio-framework |
| sanctioned script | A script that the Write-or-Edit rule (boot Hard Limit 8) lets a skill step run to write files, with only the arguments that step shows. | | ravintio-framework |
| `release.yml` | The file contract at `ravintio-framework/release.yml`. It holds `version`, `source-commit`, `built`, and a SHA-256 for each file in the root copy. | | ravintio-framework |
| release update | The step 1a signal for a new `source-commit` or `version` in `release.yml`, against the value the repo last recorded. A first upgrade compares the version only. | | ravintio-framework |
| changed file | The step 1a signal for a pack file that differs from its `release.yml` hash. It counts as an update even when the version is unchanged. | | ravintio-framework |
| leftover manifest | A `ravintio-framework/component.yml` that sits beside a `release.yml` in a consumer repo. Step 1a warns about it at every session start, and the 0.39.0 migration offers to remove it. | | ravintio-framework |
| root copy integrity check | The CI check that fails when a root copy file differs from its `release.yml` hash. It reports itself skipped while no `release.yml` exists. | | ravintio-framework |
| source-repo signal | The test for the framework source. `product.yml` lists the component `ravintio-framework` at `src/ravintio-framework/component.yml`, and that file exists. | | ravintio-framework |
| project kind | Whether a repo is the framework source or a consumer repo. The source-repo signal decides it, and the migrator compares it with a migration's `**Applies to:**` line. | | ravintio-framework |
| `**Applies to:**` header | A migration line with the value `framework source`, `downstream`, or `all`. An absent line reads as `all`. If the project kind differs, the migrator records `not applicable` with the reason. | Applies to line, migration header | ravintio-framework |
| `**Applies when:**` line | The existing migration line that states the condition for a migration to run (0000039). It is separate from the `**Applies to:**` header. | | ravintio-framework |
| `not applicable` | The migration record outcome when a migration does not apply to the project. After this feature, it also covers a project kind that differs from the `**Applies to:**` header. | | ravintio-framework |
| released tree | A tree where `plan/current/design.md` is absent, as on `main` after a merge. The version equality checks from 0000039 req-010 run in full only here. | | ravintio-framework |
| open run | A tree where `plan/current/design.md` exists, from P0 until P7 archives it. The version equality suite reports its equality checks skipped with the reason. | | ravintio-framework |
| resolver | The one helper through which suites in the framework source read the pack from `src/ravintio-framework/`. It fails a suite that reads the root copy in the source repo. | | ravintio-framework |
| component path rule | The single rule for where a component manifest lives. A manifest lives at the path `product.yml` lists, and `src/{component-id}/` is the default. | manifest rule | ravintio-framework |
