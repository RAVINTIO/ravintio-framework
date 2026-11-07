---
title: "Defect Report: 001 - gate blocks the migration CI edit"
summary: "A P3–P6 agent is blocked by an upstream P0–P2 artifact and petitions for a governed reversal."
status: "filed"
---
# Defect Report: 001 - gate blocks the migration CI edit

**Filed by:** P5 orchestrator, from the ravintio-security-agent review of setup and the migrator
**Date:** 2026-11-06T17:40:00Z
**Reversal budget remaining before this petition:** 2 of 2

---

## What Is Blocked

The P5 fix for security finding S-1 can't proceed within req-005 and ADR-006 as written.

In a consumer that has the RAVINTIO hooks installed, `gate-write` blocks the migrator's **Edit** to `.github/workflows/ravintio.yml`. req-005 and ADR-006 define no outcome for a blocked edit. Migration step 7 therefore records `applied`, and the exemption block stays in the consumer's CI file. A record makes the migration never pending again, so the consumer never learns the block is still there.

- Requirement: `plan/current/requirements/req-005-consumer-migration.md`
- Built file: `ravintio-framework/migrations/migrate-0.38.0-retire-fast-path-and-change-pipeline.md`, steps 5 and 7

## Binding Upstream Artifact

- `plan/current/requirements/req-005-consumer-migration.md`, `## Acceptance Criteria`, criterion 2. Its sub-cases name only `declined` and `no match` as reasons for `skipped`, and criterion 1 names the same two.
- `plan/current/adr/ADR-006-migrator-named-paths-with-confirmation.md`, decisions 3, 5, and 7. Decision 7 names only those two reasons. Decision 3 says the migrator "reports each refusal and edits nothing there", but gives a refused path no outcome.

## Attempts Made

1. **Read the gate's always-permitted names.** `.github/workflows/ravintio.yml` isn't on the list in `ravintio-framework/hooks/enforcement/path-rules.mjs` near line 511, and it is not under `plan/` or `docs/`. The gate blocks it with no design, and it also blocks it with a design that doesn't cover it. Migrations run in Resume Detection, before P0, so the no-design case is the normal one.
2. **Read the sanctioned routes.** Boot Hard Limit 8 names no script that may edit a CI file. A shell edit would break that limit.
3. **Read the outcome rules.** The two named reasons don't fit a gate block. The human on the loop didn't decline, and the block did match. Step 7's "applied in every other case" then applies, which states a false result.

No route inside the current design both makes the edit and records the true result.

## Evidence

Fixture scripts from the P5 review are in the session scratchpad `p5-setup/` folder, files `t5-gate.sh` and `t6-gate037.sh`. Both scripts feed real Edit JSON to `gate-write.mjs` in a scratch consumer git repo:

- With the current hooks and no design: exit 2, "No confirmed design at plan/current/design.md".
- With a design covering only `src/app/`: exit 2, "Path '.github/workflows/ravintio.yml' is not covered by the confirmed design".
- The 0.37.1 hooks give the same exit 2 on both.

P4 verify-by-execution missed this because its consumer fixture sat outside a git repo, and `gate-write` never gates paths outside the repo.

Two related findings from the same review share the root, a migration step with no defined outcome:

- **S-4:** a named path the migrator refuses, such as a linked `.github`, has no outcome. Step 7 records `applied` with counts of 0.
- **S-5:** if `plan` itself is a link, `rm -- plan/.fast-path-scope` deletes the file in the link's target. Step 3 says only that a linked leaf is safe.

## Proposed Correction Scope

The correction adds cases. It removes no criterion line and changes no confirmed decision.

1. **req-005 criterion 1 and 2, ADR-006 decisions 3, 5, and 7.** Add the reasons `blocked` and `refused`:
   - **`blocked`:** a hook blocks the Edit.
   - **`refused`:** the named path fails a path check.

   Each one gets the same handling as `declined` and `no match`:
   - The migrator edits nothing in the CI file.
   - It names the file and the lines to delete by hand.
   - It counts the edit in `corrections-skipped`.
   - It records `skipped` with the reason in the body.
2. **Migration step 3.** Add a check before the migrator shows the command: if `plan` is a link, it doesn't show `rm` and names the path for the human on the loop to check by hand.
3. **Migrator `SKILL.md`, `### Named paths`.** Add that a hook block or a refusal records `skipped` with its reason.

Downstream artifacts this changes:

- `ravintio-framework/migrations/migrate-0.38.0-retire-fast-path-and-change-pipeline.md`
- `ravintio-framework/skills/ravintio-migrator/SKILL.md`
- `ravintio-framework/tests/test-0000040-req-005-consumer-migration.sh`, which gains RED-then-GREEN cases
- `plan/current/verification-report.md`, which gets a row for a gate-blocked run

The cascade is 6 artifacts: req-005, ADR-006, and the 4 above.
