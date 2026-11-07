# Migration: remove the leftover pack component.yml for 0.39.0

**Target:** every downstream project that copied a 0.39.0 or later pack over an older one.
**Applies to:** downstream
**Scope:** `ravintio-framework/component.yml`. The migration also reads `ravintio-framework/release.yml` and changes nothing there.
**Safe to skip:** Yes. The orchestrator's step 1a warns at every session start while the file stays.

---

## Background

From framework version 0.39.0 the pack ships `ravintio-framework/release.yml` and no `component.yml`. A copy of the new pack over an old one adds and replaces files, but it never removes them. So a project that upgraded by copy keeps the old `ravintio-framework/component.yml` beside `release.yml`.

While that file stays, the project's runs still count the pack as the project's own source. This migration offers to remove it.

The file belongs to your project, so the removal needs your confirmation. The migrator doesn't delete the file itself. You run the delete, and the migrator checks the result.

If your `product.yml` lists `ravintio-framework/component.yml` as a component `path:`, the migration offers no removal. Removing the file would break `product-version.mjs`.

In the framework source this migration is not applicable. Step 1b of the migrator records `not applicable` there.

---

## Migrator Instructions

Run these steps in order. Every step is safe to repeat. A removed file and an absent file each count as done. An interrupted run applies again cleanly, and a second full run changes no file.

1. Read `ravintio-framework/release.yml`. If it doesn't exist, or its `version` is older than `0.39.0`, stop. Ask the human on the loop to refresh `ravintio-framework/` first. Record nothing, so the migration stays pending. If `release.yml` exists but breaks the format, stop, report the file, and record nothing (ADR-004).
2. If `ravintio-framework/component.yml` doesn't exist as a file or a link, record `applied` with both counts at `0`.
3. If `ravintio-framework` itself is a link, don't show a delete command. Name `ravintio-framework/component.yml` for the human on the loop to check by hand. Count it in `corrections-skipped` and record `skipped` with the reason `refused`.
3a. If the project's `product.yml` lists `ravintio-framework/component.yml` as a component `path:`, don't offer the removal. `product-version.mjs` would then exit 2 with `component.yml not found` (risk R-013). Name the `product.yml` entry, and tell the human on the loop to remove it before the next run. `product.yml` sits outside the scope rule (migrator Hard Limit 1), so the migrator never edits it. Count it in `corrections-skipped` and record `skipped` with the reason `listed in product.yml`.
4. Show the path and the `version` it reports. Say that it is left from an older pack, and that the pack now ships `release.yml` in its place. Ask the human on the loop to confirm its removal. This edit needs its own confirmation, and a batch `all` answer doesn't cover it. In `autonomous` run mode the migrator still asks, because the file sits in the consumer's repo.
5. On confirmation, the migrator doesn't delete the file itself. **Write** and **Edit** can't delete a file, and the Write-or-Edit rule (boot Hard Limit 8) names no delete route (backlog 0000366). The migrator shows this command, to run from the project root:

   `rm -- ravintio-framework/component.yml`

   In Claude Code the human on the loop can type `! rm -- ravintio-framework/component.yml`. If the path is a link, `rm` removes the link and never its target.
6. When the human on the loop says it is done, check that the path is gone, as a file or as a link.
   - If it is gone, count one correction in `corrections-applied` and record `applied`.
   - If it still exists, count it in `corrections-skipped` and record `skipped` with the reason `not removed`.
7. If the human on the loop declines, change no file. Count it in `corrections-skipped` and record `skipped` with the reason `declined`.
8. For every `skipped` outcome, the record body names `ravintio-framework/component.yml` and the reason. The migrator tells the human on the loop that step 1a warns at each session start until the file goes (req-003).

The migration changes no other file. Every other pack file stays byte-identical.

---

## Present Findings

Report to the human on the loop:
- the version that `ravintio-framework/release.yml` reports
- whether `ravintio-framework/component.yml` existed, and the version it reports
- the result: removed, already absent, `declined`, `not removed`, `refused`, or `listed in product.yml`
- for `listed in product.yml`, the `product.yml` entry to remove by hand
- for `refused`, the path `ravintio-framework/component.yml` to check by hand
- for any `skipped` outcome, the reminder that step 1a warns at each session start until the file goes

---

## Record

Once the human on the loop confirms the findings, the migrator records the outcome at `plan/_migrations/migrate-0.39.0-remove-pack-component-yml.md`. The body states the result. It names `ravintio-framework/component.yml` and the reason for a `skipped` outcome. If step 1 stops the run, the migrator records nothing, so the migration stays pending. This file stays where it is.
