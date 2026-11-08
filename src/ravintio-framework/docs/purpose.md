# Purpose - ravintio-framework

Last updated: 0000041-pack-source-under-src

## What this component exists to do

`ravintio-framework` is the RAVINTIO pack. It holds the standards, skills, hooks, scripts, templates, migrations, and setup code that enforce the confirmed-design pipeline in an AI-assisted project.

The component has two forms:

- **Source.** The folder `src/ravintio-framework/` holds the pack source and its `component.yml`. Maintainers change it here.
- **Release copy.** The root folder `ravintio-framework/` holds the copy that consumers install. It carries `release.yml` and no `component.yml`.

## Who uses it

- Maintainers change the source and ship a release copy at P7.
- Consumer repos copy the root folder, run `setup.sh` or `setup.ps1`, and receive updates through step 1a and the migrator.
- Agents read the skills, standards, and templates at run time.

## What 0000041 added

Before 0.39.0 the pack source sat at the root, and consumers copied its `component.yml`. Their runs counted the pack as their own source, bumped it, and could tag from it. Version 0.39.0 fixes this.

- The source moved to `src/ravintio-framework/`. This repo runs on the last release at the root, so a broken change can't break the run that builds it.
- `scripts/build-release.mjs` builds the root copy and writes `release.yml`.
- `scripts/release-check.mjs` detects a release update and each changed pack file.
- `scripts/project-kind.mjs` decides whether a repo is the framework source or a consumer.
- A migration may carry an `**Applies to:**` header, and the migrator skips it for the wrong project kind.
- The 0.39.0 migration offers to remove a leftover `ravintio-framework/component.yml` in a consumer.
- `tests/helpers/pack-root.sh` is the one resolver that suites use to find the pack.

## Where the rest is documented

- Interfaces: `interface-contract.md`
- File formats and ownership: `data-contract.md`
- Decisions: ADR-001 to ADR-009 of feature 0000041, indexed in `docs/decisions-index.md`
