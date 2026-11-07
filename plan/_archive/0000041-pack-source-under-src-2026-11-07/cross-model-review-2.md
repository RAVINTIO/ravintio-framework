---
title: "Cross-model review 2 - 0000041-pack-source-under-src"
summary: "Fresh-context re-review after the iteration 1 fixes. Every iteration 1 finding is fixed or accepted with a recorded reason. APPROVE with three minor findings, none of which misleads a consumer or breaks a criterion."
---
# Cross-model review 2

- Reviewer model: claude-fable-5-1
- Implementer models: claude-opus-5-5 and Sonnet
- Branch: `feat/0000041-pack-source-under-src`, head `047a8020`. The fix commit `047a8020` touched ten files: four pack docs and skill texts, one script (`release-check.mjs`, four lines), one test, one requirement, one living doc, and one backlog entry.
- Diff reviewed: `git diff a5055f44..HEAD` (125 files), with the iteration 1 rubric. The iteration 1 verdict is `cross-model-review-1.md`.
- Default verdict: REJECT. Approval needs cited evidence for every rubric row.

## Overall verdict: APPROVE

Both iteration 1 majors are fixed, and the three minors the P6 decision chose to fix are fixed. Minor 4 has a backlog entry and a tech-debt row. Minor 5 is accepted until the P7 rebuild (`build-log.md:358`). The root copy is still byte-identical to `v0.38.0`. The `release-check.mjs` change behaves as its new documentation says in scratch consumers. The three new findings below are minor text defects. None misleads a consumer of the pack or breaks an acceptance criterion.

## Iteration 1 finding status

| # | Grade | Finding | Status | Evidence |
|---|-------|---------|--------|----------|
| 1 | Major | `docs/architecture-overview.md` named seven sanctioned scripts | Fixed | `:302` reads "It names eight scripts:". `:305` adds `build-release.mjs (0000041 ADR-003), with no arguments`. `:625` appends "0000041 ADR-003 adds an eighth." The list matches the `standard-boot.md:14` sentence, which names eight scripts and the no-argument rule. |
| 2 | Major | Migration file credited the warning to "the migrator's step 1a" | Fixed | `migrate-0.39.0-remove-pack-component-yml.md:6` reads "The orchestrator's step 1a warns at every session start while the file stays." Orchestrator `SKILL.md:74` owns step 1a. `test-0000041-req-006-consumer-migration.sh` passes, 127 of 127. |
| 3 | Minor | `release-check.mjs` printed the fallback line with a trusted record | Fixed | `release-check.mjs:287-290` prints `release: none` when a record exists and `release.yml` is missing, and never reads `component.yml`. Scratch runs in `mktemp -d` consumers: with a record and a leftover `component.yml`, output is `release: none`, `recorded:`, `missing: ravintio-framework/release.yml`, `update: release`, exit 1. With a record and neither file, the same four lines and exit 1. With no record and `component.yml`, the fallback line and exit 1. With no record and neither file, exit 2. `req-003:64`, `interface-contract.md:55`, and the new test cases at `test-0000041-req-003-release-yml-readers.sh:289-299` all state this. The suite passes, 137 of 137. |
| 4 | Minor | Duplicated helpers across the two release scripts | Accepted, reason recorded | Backlog `plan/backlog/0000423-release-scripts-duplicate-helpers/entry.md` (next free id, template fields present). `src/ravintio-framework/docs/tech-debt.md:15` names the five helpers and the reason: a refactor would reopen the P5 security review. `build-log.md:358` records the decision. |
| 5 | Minor | `README.md:118` links `ravintio-framework/docs/`, absent until P7 | Accepted until P7, reason recorded | `build-log.md:358`: "accept minor 5 until the P7 rebuild puts docs/ in the root copy", with backlog 0000384 open for the shipped docs. `README.md:118` is unchanged, as intended. |
| 6 | Minor | Spec-agent Component Manifest row held two `../templates/` links | Fixed | `ravintio-spec-agent/SKILL.md:39` now links `../../templates/component.template.yml` and `../../templates/component-guide.md`. Both files exist under `src/ravintio-framework/templates/`. `skills/templates/` does not exist. |
| 7 | Minor | `tests/README.md:67` miscounted its skip cases | Fixed | `:67` reads "The symlink cases (...) and the unreadable-file case only (...). The other checks run." |

## Rubric

| # | Item | Result | Evidence |
|---|------|--------|----------|
| 1 | Every acceptance criterion is met by code or text that exists now | PASS | The one iteration 1 gap, req-002 line 136 ("P6 docs-agent updates it to eight"), is met at `docs/architecture-overview.md:302-308`. The per-requirement table in `cross-model-review-1.md` still holds: the fix commit changed no criterion's evidence except req-003 AC1, where the new `release: none` line matches `req-003:64-65`. Suites run at `047a8020`: req-002 126 passed, req-003 137 passed, req-006 127 passed, 0000036 req-005 hard-limits 12 passed. Full suite: 176 suites, 0 failed, exit 0 (see below). |
| 2 | No code contradicts an accepted ADR | PASS | The only script change is `release-check.mjs:287-290`. ADR-004 line 50 says the fallback "serves a pack before 0.39.0 only", and `framework-update-policy.md:38` says the fallback applies only with no trusted record. The change makes the script match both. Every other ADR citation in iteration 1 row 2 is unchanged, checked by `git show HEAD --stat`. |
| 3 | Root `ravintio-framework/` byte-identical to v0.38.0 | PASS | `git diff --quiet v0.38.0 HEAD -- ravintio-framework` exits 0 at `047a8020`. |
| 4 | Each new script refuses its stated bad inputs | PASS | `build-release.mjs` and `project-kind.mjs` are unchanged since iteration 1, so its row 4 evidence stands. `release-check.mjs` scratch runs above: exit 2 with no record and neither file (`:293`), exit 1 with a record and a missing `release.yml` (`:306-310`). The req-003 suite covers the unknown-argument, `format: 2`, and linked `release.yml` refusals and passes. |
| 5 | Skill text changes are internally consistent | PASS | The one iteration 1 conflict is gone: the migration file, orchestrator step 1a (`SKILL.md:74`), and `test-0000041-req-006-consumer-migration.sh:106`, `:220` now name the same step. The record rule reads the same in `req-003:61-65`, `framework-update-policy.md:38`, `interface-contract.md:54-55` and `:64`, and `release-check.mjs:303-310`. The migrator (`SKILL.md:38`, `:99`, `:182`) describes its own version read, which has no record and keeps the plain fallback. |
| 6 | Prose follows the pack style | PASS with one minor | The fix commit adds no em dash (`git show HEAD` grep, 0 lines). Its semicolons sit in JavaScript, shell, and the pre-existing spec-agent sentence. Finding N1 below: six em dashes in `src/setup-hook-integration/docs/scope.md:5-10` sit on lines the feature re-pathed. They predate the feature, and iteration 1 row 6 missed them. |
| 7 | Nothing dead, duplicated, or out of scope | PASS | The duplication of minor 4 now has backlog 0000423 and a tech-debt row. Backlog id 0000423 follows 0000422 with no gap or collision (`ls plan/backlog`). The new test cases at `test-0000041-req-003-release-yml-readers.sh:289-299` each assert a distinct line. No dead code found. |

### Full suite run

`bash src/ravintio-framework/tests/run-tests.sh` at `047a8020`: 176 suites run, 139 feature suites passed and 0 failed, 37 regression suites passed and 0 failed, exit 0. The iteration 1 failure (`test-0000036-req-005-hard-limits-cited-by-name.sh`) now passes in the full run.

## New findings

### Critical

None.

### Major

None.

### Minor

1. **N1. `src/setup-hook-integration/docs/scope.md:5-10` carry six em dashes (U+2014).** The feature changed these lines from `ravintio-framework/...` to `src/ravintio-framework/...` and kept the dashes. The em dash guard's scope (`em-dash-guard.mjs:53-62`) covers `docs/`, `plan/current/`, and the pack's skills, templates, and standards, so no hook or test flags a component doc. The text predates the feature. Fix: replace each spaced em dash with a colon, for example "`src/ravintio-framework/setup.sh` and `setup.ps1`: all flag processing and tool dispatch". A backlog entry is also acceptable, since the lines are outside the pack.

2. **N2. `plan/changelog/0000041-pack-source-under-src-2026-11-07.md:25` says the script builds the root copy "from `HEAD`".** The script copies working-tree bytes for the files `git ls-files` lists (`build-release.mjs:14`, `:191`) and reads only `source-commit` from `git rev-parse HEAD` (`:387`). The dirty-tree refusal ties the two together, but `tech-debt.md:13` (backlog 0000417) and `security-report.md:21` (RS-F05) record that an `assume-unchanged` edit can slip through, so the bytes are not guaranteed to be `HEAD`'s. Fix: "builds the root copy from a clean `src/ravintio-framework/` tree, records `HEAD` as `source-commit`, swaps it in whole, and writes `release.yml` with a SHA-256 per file."

3. **N3. `ravintio-spec-agent/SKILL.md:40` still holds two `../templates/` links in the Data Contract row.** The row is outside this feature's diff, so this is not a regression. The links resolve to `skills/templates/`, which does not exist. Fix: change both to `../../templates/`, as finding 6 did for the row above, or file a backlog entry.

## Not re-litigated

The accepted residual risks in `security-report.md` and the exception-list rows in `deviation-review.md` stay as recorded. The fix commit changed no boundary, refusal, or write path in `build-release.mjs`.
