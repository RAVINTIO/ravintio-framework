# Reversal Verdict (001)
**Verdict:** DENY
**Classification:** altering
**Budget after this verdict:** 2/2 remaining

| Rubric item | Verdict | Evidence cited |
|-------------|---------|----------------|
| 1 Real blocker | fail | The gate block is real. The assessor reproduced it in a scratch consumer git repo with the current `gate-write.mjs`. With no design, the CI file Edit exits 2 with "No confirmed design". With a design covering only `src/app/`, it exits 2 with "not covered by the confirmed design". A `plan/_migrations/` write passes in the same repo. The petitioned defect is the false `applied` record, and that has a route inside the current design. The rule "applied in every other case" lives in migration step 7, a P3 artifact. req-005 and ADR-006 name what `declined` and `no match` record. Neither says every other case records `applied`. The confirmed Scope Lock error path already requires the outcome to carry its reason and "never as success". A P5 fix can add `blocked` and `refused` to step 7 and to `### Named paths` as a logged deviation. S-5 has the same kind of route. req-005 step 3 says the delete must never reach a target, so a check for a linked `plan` in migration step 3 strengthens it. The report gives no fixture for S-5. |
| 2 Shallowest phase | fail | The root defect sits in the P0 design, not in req-005 or ADR-006. `design.md` confirms that with no design, `gate-write` blocks every write outside `plan/`, `docs/`, and the permitted names. It also confirms that the migration removes the block once the human on the loop confirms. Migrations run in Resume Detection, before P0, with no design. Setup installs `gate-write` in every hooked consumer. So the two confirmed lines can't both hold there. The P0 exchange "(CI file)" and ADR-006 Alternatives row 1 show the human chose automated removal over a hand-delete notice. The petition leaves that contradiction in place and only relabels the result. |
| 3 Blast radius | pass | cascade: `plan/current/requirements/req-005-consumer-migration.md`, `plan/current/adr/ADR-006-migrator-named-paths-with-confirmation.md`, `ravintio-framework/migrations/migrate-0.38.0-retire-fast-path-and-change-pipeline.md`, `ravintio-framework/skills/ravintio-migrator/SKILL.md`, `ravintio-framework/tests/test-0000040-req-005-consumer-migration.sh`, `plan/current/verification-report.md` (6 artifacts. Over 3, so the human gate applies). The assessor's grep for the skipped reasons found the same 6 files. A correction at the right target would also touch `plan/current/design.md` and the `confirmed edit` arrow in `plan/current/execution-plan.md`, for 8. |
| 4 Budget | pass | `loop-state-reversal-001.md` reads 2 remaining, shared feature-wide. A DENY spends none. |
| 5 Classification | altering | The human on the loop confirmed at P0 that "the migration removes the block with confirmation". They rejected a manual route. The petition calls its change additive. In a hooked consumer, though, `blocked` becomes the normal outcome. The exemption then stays until someone deletes the lines by hand. That is ADR-006 Alternatives row 1, which the design rejected. The effect changes what the human confirmed, so it is altering. In `autonomous` it becomes an exception-list item. |

## What would change this verdict (DENY only)

1. Target `plan/current/design.md`, the Migration and Hooks lines and the Scope Lock happy path. State how the confirmed removal reaches a consumer that has `gate-write` installed and no design. Candidates include these:
   - a human-run edit, like the step 3 delete pattern
   - a sanctioned helper script, as in 0.37.0 (boot Hard Limit 8 would need it named)
   - a gate route for a confirmed named-path edit by the migrator
2. Classify that petition as altering, and route it to the human on the loop as an exception-list item.
3. Count the cascade from `design.md` down. That includes `execution-plan.md` as well as the 6 listed here.
4. Leave S-4 and S-5 out of the reversal unless a fixture shows that no change inside req-005 can fix them. Each one today has a fix in the migration file or the migrator `SKILL.md` that contradicts no confirmed line.

Evidence that hooked consumers are rare would also change item 2. The assessor found none. The defect report itself calls the no-design case "the normal one".

Fixture used: `/private/tmp/claude-501/-Users-martinmayer-d-ravintio-framework/121d9a6e-e20f-42b7-a97d-d3c9514c11b7/scratchpad/assessor/run.sh`.
