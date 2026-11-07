---
title: "Cross-model review 1 - 0000041-pack-source-under-src"
summary: "Fresh-context end-of-P6 review of the feature diff against req-001 to req-008, the nine ADRs, and design.md. REJECT on two major text defects. Every script refusal and the root copy identity check pass."
---
# Cross-model review 1

- Reviewer model: claude-fable-5-1
- Implementer models: claude-opus-5-5 and Sonnet
- Branch: `feat/0000041-pack-source-under-src`. The review read head `f6f60596`. Three commits landed during the review (`6f2405c9`, `12ccea9d`, `d6678607`, the post-P6 revalidation cycle 1). They change four doc lines and the build log, and no script or skill text. Every citation below was rechecked at `d6678607`.
- Diff reviewed: `git diff a5055f44..HEAD` (123 files at `f6f60596`). The pass commit `a5055f44` moved 1,184 files with no content edit, checked by `git show --stat`.
- Default verdict: REJECT. Approval needs cited evidence for every rubric row.

## Overall verdict: REJECT

Two major findings block approval. Both are text defects with a fix of a few lines, and neither touches a script. A re-review after the two fixes can approve.

1. `docs/architecture-overview.md` still says Hard Limit 8 names seven scripts, and its list lacks `build-release.mjs`. req-002 line 136 names this P6 update, and boot Hard Limit 7 requires docs to match reality.
2. The 0.39.0 migration file credits the leftover-manifest warning to "the migrator's step 1a". That step belongs to the orchestrator. Released migration files never change, so the error freezes at P7.

The code itself holds. The root copy is byte-identical to `v0.38.0`. Each new script refuses every bad input the requirements name, in scratch repos outside this repo. The skill texts agree with each other and with the ADRs.

## Rubric

| # | Item | Result | Evidence |
|---|------|--------|----------|
| 1 | Every acceptance criterion is met by code or text that exists now | FAIL (one req-002 functional line) | See the per-requirement table below. req-002 line 136 ("P6 docs-agent updates it to eight") is unmet at `docs/architecture-overview.md:302` and `:624`. Every acceptance criterion proper has code or text behind it. |
| 2 | No code contradicts an accepted ADR | PASS | ADR-002: pass commit `a5055f44`, root copy identical to `v0.38.0`. ADR-003: `build-release.mjs:54-58` three-folder boundary, `:134-147` link checks, `:357-417` build and swap, `:359` no-argument refusal. ADR-004: `release-check.mjs:94-129` fixed-format parser, `:107` refuses `format` other than 1, `:302-306` no fallback with a trusted record. ADR-006: codegen `SKILL.md:179-191`, ship `SKILL.md:307`, `component-guide.md:23-31`. ADR-007: `project-kind.mjs:58-87`, migrator `SKILL.md:115-126`. ADR-008: migration file steps 1 to 8. ADR-009: `pack-root.sh:35-38` FAIL line, `ravintio.yml:311-339` integrity job, version suite `test-0000039-req-010-version-bump.sh:33-44`. |
| 3 | Root `ravintio-framework/` byte-identical to v0.38.0 | PASS | `git diff --quiet v0.38.0 HEAD -- ravintio-framework` exits 0 at `f6f60596`. |
| 4 | Each new script refuses its stated bad inputs | PASS | Scratch repos under `mktemp -d`. `build-release.mjs` exits 2 on: an argument (`:359`), a run from a subfolder (`:372`), a downstream kind (`:375`), a dirty pack (`:149-153`), a tracked `src/ravintio-framework/release.yml` (`:180`), a tracked link (`:165-167`), and a linked root copy (`:139`). `release-check.mjs` exits 2 on an unknown argument (`:249`), `format: 2` (`:107`), a linked `release.yml` (`:82`). `project-kind.mjs` exits 2 on `--bogus` and on `--root` with no value (`:89-96`). First build left the root copy at mode 0755 with no `component.yml`, and a same-commit rerun printed `added 0, changed 0, removed 0, unchanged 1208`. The own-build check printed `update: own-build` and exited 0. |
| 5 | Skill text changes are internally consistent | FAIL (one attribution) | Orchestrator step 1a (`SKILL.md:72-90`) and step 1b (`:101`), the policy (`framework-update-policy.md:21-49`), the migrator (`SKILL.md:99`, `:115-126`, `:182`), ship Step 5c and Step 7 (`SKILL.md:265-273`, `:288`), codegen close-out (`SKILL.md:179-191`), spec-agent (`:24`, `:39`, `:85`), docs-agent (`:83`, `:150`), and `component-guide.md:23-31` all state one rule each and agree on the script names, the fallback, and the manifest rule. The one conflict is the migration file's "The migrator's step 1a" (finding 2). |
| 6 | Prose follows the pack style | PASS | A scan of every added line under `src/ravintio-framework`, `docs/`, `README.md`, and `src/setup-hook-integration` found no em dash. The only semicolons sit in shell code (`ship-agent/SKILL.md:288`) and in a pre-existing sentence of the spec-agent table row. No American spelling in added prose. |
| 7 | Nothing dead, duplicated, or out of scope | PASS with minors | Four helpers and the git environment scrub are duplicated across `build-release.mjs` and `release-check.mjs` (finding 4). The pack gains a `docs/` folder that ships in the release copy (finding 5, backlog 0000384). No dead code found. Every changed file maps to a requirement or to the P6 docs step. |

### Acceptance criteria by requirement

| Requirement | Criterion | Evidence |
|-------------|-----------|----------|
| req-001 AC1 | Pass commit touches only `src/ravintio-framework/`, tree equals `v0.38.0`, root copy identical | `git show --stat a5055f44` lists 1,184 files, all under `src/ravintio-framework/`. `git diff --quiet v0.38.0 HEAD -- ravintio-framework` exits 0. Build log lines 234, 235, and 265 record the P3 checks. |
| req-001 AC2 | `product.yml` path, `.gitattributes`, em dash guard scope | `product.yml:22`, `.gitattributes:8-9`, `em-dash-guard.mjs:60-62`. |
| req-001 AC3 | setup-hook-integration docs, registry link, `$PSScriptRoot`, README | `src/setup-hook-integration/docs/dependencies.md:7-14`, `purpose.md:5`, `docs/component-registry.md:20`, `refresh-ravintio-framework-dir.ps1:1`, `README.md:41-43` and `:62`. `self-description-check.mjs .` exits 0. |
| req-002 AC1 | Build output, `release.yml` format, rerun identical, under 30 s | Scratch build: 1,208 files, header keys in order (`build-release.mjs:399-405`), rerun summary all zeros. The build of 1,208 files took under 5 s on this machine. |
| req-002 AC2 | Refusals and boundary | Rubric row 4. `.gitignore:32-33` lists both work folders. |
| req-002 AC3 | Eight-script sentence, Step 5c, Step 7 line | `standard-boot.md:14` and `cursor-boot.md:20` carry one identical sentence naming eight scripts. Ship `SKILL.md:265-273` and `:288`. |
| req-002 AC4 | P7 Decision line and setup refresh recommendation | Manual by design. `recommendations.md:17` (REC-005) names the setup rerun. The Decision line waits for P7. |
| req-003 AC1 | `release-check.mjs` consumer cases | `release-check.mjs:265-331`. Scratch runs: `warn:` at `:327-328`, `missing:` with a record at `:302-306`, `--files-only` at `:267-275`. |
| req-003 AC2 | Own-build rule | `release-check.mjs:205-240`, scratch run printed `update: own-build`, exit 0. |
| req-003 AC3 | Step 1a, step 1b, policy, migrator texts | Orchestrator `SKILL.md:72-90`, `:101`. `framework-update-policy.md:21-49`. Migrator `SKILL.md:38`, `:99`, `:182`. |
| req-004 AC1 | `component-guide.md` rule, spec-agent and docs-agent links | `component-guide.md:23-31`, spec-agent `:24`, `:39`, `:85`, docs-agent `:83`, `:150`. |
| req-004 AC2 | Codegen close-out, four ADR-006 rules, no root manifest name | Codegen `SKILL.md:179-191`. `grep ravintio-framework/component.yml` returns nothing in the codegen or ship skill. |
| req-004 AC3 | Ship Step 9 case 2 reads the archived design | Ship `SKILL.md:307`. |
| req-005 AC1 | `project-kind.mjs` cases | `project-kind.mjs:58-87`, scratch runs above. |
| req-005 AC2 | Migrator header, table, Step 1b | Migrator `SKILL.md:103-126`. |
| req-005 AC3 | Scratch repo behaviour, released files unchanged | `test-0000041-req-005-applies-to-header.sh:231` reads `v0.38.0:ravintio-framework/migrations/retroactive-release-tags.md` from history. Root copy identity covers the released files. |
| req-006 AC1 | Migration file header and steps | `migrate-0.39.0-remove-pack-component-yml.md:3-6`, `:28-42`. |
| req-006 AC2 | Scratch consumer runs | `verification-report.md:50-52` records the three confirmed, declined, and listed outcomes. |
| req-006 AC3 | This repo's `not applicable` record | `plan/_migrations/migrate-0.39.0-remove-pack-component-yml.md:1-9`, `framework-version: "0.38.0"` matches the root copy. |
| req-007 AC1 to AC3 | Released-tree rule and resolver move | `test-0000039-req-010-version-bump.sh:26-44`, `:57-61`, `:77-86`. `verification-report.md:94-105` records the open and released runs. |
| req-008 AC1 | Resolver variables and FAIL line | `pack-root.sh:14-38`. |
| req-008 AC2 | Static scan, CI from `src/`, suite exit | `ravintio.yml:162`, `:211`, `:233`, `:263`, `:270`, `:294`, `:309`. Full suite result below. |
| req-008 AC3 | Integrity job | `ravintio.yml:311-339`. `verification-report.md:10-12` records the skip notice on this repo. |

### Full suite run

`bash src/ravintio-framework/tests/run-tests.sh` at `f6f60596`: 176 suites run, 138 feature suites passed and 1 failed, 37 regression suites passed, exit 1. The one failure was `test-0000036-req-005-hard-limits-cited-by-name.sh`, which flagged six bare `boot Hard Limit 8` citations in `src/ravintio-framework/docs/data-contract.md:11`, `docs/scope.md:10`, `docs/architecture-overview.md:522`, and `docs/decisions-index.md:444`. The orchestrator's revalidation cycle 1 fixed all six in `6f2405c9` and `12ccea9d` during this review. At `d6678607` the suite passes standalone with `12 passed, 0 failed`, and `git diff --quiet v0.38.0 HEAD -- ravintio-framework` still exits 0. No script, skill, template, standard, or migration file changed between the two heads.

## Findings

### Critical

None.

### Major

1. **`docs/architecture-overview.md:302-310` and `:624` still name seven sanctioned scripts.** Line 302 reads "It names seven scripts:" and the list below it lacks `build-release.mjs`. Line 624 repeats "seven". The new section at line 519 onwards says Boot Hard Limit 8 sanctions the script, so the document contradicts itself. req-002 line 136 states "P6 docs-agent updates it to eight", and boot Hard Limit 7 requires the docs to match what was built. Fix: at line 302 write "It names eight scripts:", add a bullet `- \`build-release.mjs\` (0000041 ADR-003), with no arguments` after `set-product-release.mjs`, and at line 624 append "0000041 ADR-003 adds an eighth."

2. **`src/ravintio-framework/migrations/migrate-0.39.0-remove-pack-component-yml.md:6` credits the warning to the wrong skill.** The line reads "The migrator's step 1a warns at every session start while the file stays." The migrator has Step 1, 1b, and 1c (`ravintio-migrator/SKILL.md:85`, `:115`, `:128`) and no step 1a. The warning comes from orchestrator step 1a (`ravintio-orchestrator/SKILL.md:74`), as req-006 line 29 and ADR-004 state. Released migration files never change (design constraint), so the error freezes at P7. Fix: change the line to "The orchestrator's step 1a warns at every session start while the file stays." `test-0000041-req-006-consumer-migration.sh:106-107` asserts only "step 1a" and "warns", so it stays green.

### Minor

3. **`release-check.mjs:288-292` prints the fallback line when the fallback doesn't apply.** With a trusted `plan/framework-release.yml`, no `release.yml`, and a leftover `component.yml`, a scratch run printed `release: none, fallback component.yml version "0.38.0"` before `missing: ravintio-framework/release.yml` and `update: release`. The P5 RC-F02 fix (`:302-306`) says the fallback never applies with a record, and `src/ravintio-framework/docs/interface-contract.md:49` documents the line as "No `release.yml` and no trusted record". With a record and neither file, line 289 exits 2, where req-003 line 65 says exit 1 with `missing:`. Fix: move the `recorded && !release` branch ahead of the `component.yml` read, print `release: none` there, and read `component.yml` only when no record exists. Update req-003 line 64 to say the exit 2 case applies only with no record.

4. **Duplicated helpers across the two release scripts.** `clean`, `lstatOrNull`, `readNoFollow`, and `lfHash` appear in `build-release.mjs:69-121` and `:236` and again in `release-check.mjs:51-89`. The git environment scrub appears twice with two shapes (`build-release.mjs:89-98`, `release-check.mjs:208-212`). A drift in one copy of `lfHash` would make the builder and the checker disagree on every hash. Fix: a shared `scripts/release-common.mjs` that both import, as `path-rules.mjs` serves the hooks. If the pack keeps standalone scripts on purpose, record the pair in `src/ravintio-framework/docs/tech-debt.md`.

5. **`README.md:118` links `ravintio-framework/docs/`, which the root copy doesn't hold until P7.** `v0.38.0` has no `docs/` folder, so the link is broken on the branch until the first release build. `self-description-check.mjs` passes only because it reads the folder list from `src/` (`:104-107`). The new pack `docs/` folder also ships in every consumer copy, which backlog 0000384 tracks and `component.yml` quirks record. Fix: accept until P7, and name the P7 rebuild as the step that makes the link live in the P6 build-log block.

6. **`skills/ravintio-spec-agent/SKILL.md:39` mixes a correct link with two broken ones in the row this feature edited.** The row now holds `../../templates/component-guide.md#file-location` beside the pre-existing `../templates/component.template.yml` and `../templates/component-guide.md`, which resolve to `skills/templates/`, a folder that doesn't exist. Fix: change both to `../../templates/`. This predates the feature, so a backlog entry is also acceptable.

7. **`tests/README.md:67` miscounts its skip cases.** "Two cases only: the symlink cases (...) and the unreadable-file case" names more than two cases. Fix: "The symlink cases and the unreadable-file case only: ...".

## Not re-litigated

The accepted residual risks in `security-report.md` (R-002, R-015, RS-F02 to RS-F05, NF-01, RC-F01, RC-F03 to RC-F05, RC-F07) and the exception-list rows in `deviation-review.md` stay as recorded. This review found no new boundary break in the release script.
