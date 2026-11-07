---
title: "Framework Update Policy"
version: "1.0.0"
---
# Framework Update Policy

Canonical definition of how a `ravintio-framework/` dependency update is detected, confirmed, and trusted. This is the document backlog entries `0000040`/`0000041` (and any future entry) mean when they reference "the Framework Update Policy": until this file existed, that reference resolved to nothing.

---

## What this covers

Distinguishes "the `ravintio-framework/` folder is being updated to a newer version" from "unrecognised code is being pushed from an unknown source." The two look identical at the file-diff level, both touch files under `ravintio-framework/`, but only the first is a trusted, provenance-tracked update, and only the first should be treated as such without question.

This policy is unrelated in scope to `ravintio-migrator`: that skill owns the narrower "read one pending migration file, present findings, apply confirmed changes, archive it" flow, and continues to be invoked from the same P0 area when a migration file happens to exist. This policy's detection-and-confirmation step runs first and independently, whether or not any migration accompanies the update.

## Where this runs

At the orchestrator's Resume Detection step (`ravintio-orchestrator/SKILL.md`), positioned alongside the existing migration-scan step, before any other Phase 0 work, including ordinary feature-brief coaching Q&A. It is surfaced as its own distinct decision: never silently applied, and never conflated with that coaching flow.

## Detection signal

The read-only script `ravintio-framework/scripts/release-check.mjs` runs the check. Step 1a runs it at every session start. It reads `ravintio-framework/release.yml`, which the release script writes. A candidate `ravintio-framework/` dependency update has two signals.

1. **Release update.** The script compares the `version` and `source-commit` in `release.yml` with the recorded value.
   - The recorded value lives in `plan/framework-release.yml`. It holds one `version` line and one `source-commit` line. Only step 1a writes it, with **Write**.
   - With a recorded value, a different `version` or `source-commit` is a release update.
   - With no `plan/framework-release.yml`, the repo is on its first upgrade. A first upgrade compares the version only, against the `version` in `docs/about.md`. With no `docs/about.md`, any release counts as a release update.
2. **Changed file.** The script compares each pack file with its hash in `release.yml`, whatever the version says. Each of these counts as an update, even at an unchanged version:
   - a changed file, whose hash differs or which is a link
   - a missing file, which `release.yml` lists and the pack lacks
   - an unlisted file, which the pack holds and `release.yml` doesn't list

   The unlisted check skips `release.yml`, `component.yml`, `.DS_Store`, `Thumbs.db`, and `desktop.ini`. A changed file stays flagged at each session start until it matches its hash or a new release lists it.

**Hash rule.** Each hash is the SHA-256 of the file content after each CRLF pair reads as LF, in lowercase hex. A checkout with `core.autocrlf` then never reads as a changed file.

**Fallback for a pack before 0.39.0.** A pack before 0.39.0 has no `release.yml`. The fallback applies only when no trusted release record exists. A `plan/framework-release.yml` proves that a `release.yml` was trusted once. If that record exists and `release.yml` is missing, the script prints a `missing:` line for `ravintio-framework/release.yml` and `update: release`, and exits 1. With no record, the script reads the `version` in `ravintio-framework/component.yml`. It compares that version with the recorded version, as on a first upgrade. It checks no file and prints no record. When `release.yml` exists but breaks its format, the check exits 2 and never falls back to `component.yml`. If the pack has no `release-check.mjs`, compare the `component.yml` version with `docs/about.md` by hand.

**Leftover manifest.** When `ravintio-framework/component.yml` sits beside `release.yml`, the script prints a `warn:` line. Step 1a reports the warning at every session start while the file remains.

## Human confirmation gate

Detecting a candidate update is not sufficient to treat it as trusted. Every path through this policy terminates in one of two explicit outcomes; there is no implicit pass-through:

- **Explicit confirmation**, or
- **Explicit rejection.**

One exception applies. In the framework source repo, an own build needs no confirmation. The release script rebuilds the root copy from `src/ravintio-framework/`. The check proves an own build by content, not commit ancestry. Each `release.yml` hash must match the same path under `src/ravintio-framework/`, and no file line may appear. Step 1a records an own build and goes on. Every other path still ends in explicit confirmation or rejection.

Confirmation requires the human to affirm both of the following, as two separate facts; a blanket "yes, update it" satisfies neither:

1. **That this is in fact a `ravintio-framework/` update**: as opposed to an arbitrary, unrelated code push that happens to touch the same paths.
2. **Its provenance**: the specific source release, commit, or migration identifier that produced the arriving files. The human must confirm a specific, named origin, not simply agree that an update is happening.

Record the outcome, confirmed with its stated provenance, or rejected, in `plan/current/build-log.md` before Phase 0 proceeds. If rejected, the arriving `ravintio-framework/` files are treated as untrusted: do not act on them silently, and ask the human how to proceed.

## Relationship to `ravintio-migrator`

Unchanged by this policy. `ravintio-migrator` continues to own reading a single pending migration file, presenting its findings, applying confirmed changes, and archiving it. This policy's detection-and-confirmation step happens first, independent of whether a migration file exists; `ravintio-migrator` may still run afterward for any migration that accompanies the confirmed update.

## Setup-delivered files

A setup-delivered file is a framework file that `setup.sh` or `setup.ps1` copies into a tool folder. It also covers a file that setup writes into a boot file or a settings file. These files count:

- each skill's `SKILL.md`, with the `scripts/`, `assets/`, and `references/` folders that setup copies beside it
- every file in `templates/` and `schemas/`, and every top-level file in `standards/`
- each file below `standards/` that a `bundle_standards` entry names by sub-path, such as `standards/library-standards/_version-policy.md`
- each enforcement hook in `hooks/enforcement/`, each hook adapter in `hooks/adapters/`, and each workflow file in `workflows/`
- the hook wiring that setup writes into a tool's settings file

Files in `standards/reference/` don't count. Git hooks in `hooks/` don't count either. Git runs them in place through `core.hooksPath`, so they need no setup run.

The definition follows what setup does, not what the skill manifests name. If a skill's `bundle_templates` key is absent or empty, setup copies every file in `templates/` into that skill. The same fallback applies to `bundle_standards` and the top-level standards. So a release can't treat a template or standard as safe because no manifest names it.

A release that changes a setup-delivered file ships a re-run-setup migration.

To build the migration's file list, filter the release's `git diff --name-only` by this definition. Never filter it by the `bundle_templates` or `bundle_standards` lists. One migration may cover several releases when an earlier release shipped none. `migrations/migrate-0.34.0-rerun-setup.md` covers 0.33.0 and 0.34.0 this way.

A re-run-setup migration's `**Target:**` line names every project with an installed RAVINTIO Framework setup, the framework source included. The framework source also carries an install, so its sessions need the refreshed files too.

## Related

- `plan/current/adr/ADR-002-framework-update-policy-p0-step.md`: the decision this policy documents (mechanism choice: new P0 step, not a `ravintio-migrator` extension or a new standalone skill).
- `ravintio-orchestrator/SKILL.md` Resume Detection: the P0 step invoking this policy.
