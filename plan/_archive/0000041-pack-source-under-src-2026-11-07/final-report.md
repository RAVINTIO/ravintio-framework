---
title: "Final Report - 0000041-pack-source-under-src"
summary: "The autonomous run's report to the human on the loop: what shipped, decisions, version, PR, clean tree, and waiting exceptions."
---
# Final report: 0000041-pack-source-under-src

The run shipped version 0.39.0 as draft PR #77. Two Windows CI shards are red, and no fix could land after the archive. Ten exception items wait for you, plus one credential item and one CI item.

## 1. What shipped

The pack source moves to `src/ravintio-framework/`, and the root `ravintio-framework/` becomes a release copy. This repo now runs on that copy. The run delivers eight requirements under three user stories:

- **req-001:** one git pass moved 1,184 files, and the follow-up fixes repoint `product.yml`, `.gitattributes`, the em-dash guard, setup-hook-integration, the README, and the refresh script.
- **req-002:** `scripts/build-release.mjs` rebuilds the root copy with `release.yml` and no `component.yml`. Ship Step 5c runs it, and boot Hard Limit 8 names it as the eighth sanctioned script.
- **req-003:** `scripts/release-check.mjs`, orchestrator step 1a, the update policy, and the migrator read `release.yml` first and detect each changed pack file.
- **req-004:** one manifest-location rule from `product.yml`, used by the codegen close-out, ship Step 9, the spec agent, and the docs agent.
- **req-005:** the `**Applies to:**` migration header and `scripts/project-kind.mjs`, which owns the source-repo signal.
- **req-006:** a 0.39.0 migration that offers to remove a consumer's leftover `component.yml`, with this repo's `not applicable` record.
- **req-007:** the 0000039 version suite runs its equality checks on a released tree only.
- **req-008:** suites read the pack through `tests/helpers/pack-root.sh`, CI runs from `src/`, and a `release-copy-integrity` job checks the root copy.

## 2. Decisions and deviations

The archived build log holds all 97 `Decision` lines and 10 `Deviation` lines verbatim, at `plan/_archive/0000041-pack-source-under-src-2026-11-07/build-log.md`. This report lists every deviation and the decisions you are most likely to want to check. It doesn't repeat all 97 decisions.

**Deviations, with the assessor's class:**

- P1, additive: req-001 adds the `src/ravintio-framework/` prefixes to the em-dash guard scope.
- P1, altering, destructive: the release script writes three folders, not the root copy only.
- P1, altering: req-005 adds a migrator table for the released `retroactive-release-tags.md`.
- P1, altering: req-006 adds step 3a, which skips the removal when `product.yml` lists the file.
- P1, additive: the feature brief gains two acceptance criteria.
- P2, altering, destructive: the human on the loop runs the consumer `rm`, and the migrator checks it.
- P2, additive: `## Component Paths` gains `./product.yml` and `./refresh-ravintio-framework-dir.ps1`.
- P2, altering: the Scope Lock cross-session path recovers by state and never resets.
- P5, additive: req-002 and req-003 gain the P5 security rules.
- P5, additive: req-002 gains the NF-02 refusal and the NF-03 0o755 root copy mode.

**Key decisions:**

- P2: nine ADRs, written by eight parallel subagents and approved by the design critic at iteration 3.
- P3: the CI path edits landed at step 3, and the integrity job at step 5 with `release-check.mjs`.
- P3: `test-0000040-req-007` and `test-0000038-req-007` changed what they pin, because this feature changes the version and the boot sentence on purpose.
- P5: fix RS-F01, RS-F06, RS-F07, RS-F08, NF-02, NF-03, RC-F02, and RC-F08. Accept RS-F02 to RS-F05, NF-01, and the R-015 reader findings.
- P6: fix cross-model findings 1, 2, 3, 6, and 7, and accept 4 and 5.
- P7: promote no suite to the regression pack, because none is tagged and the sanctioned promote script reads only the release copy.
- P7: run `build-release.mjs` from `src/` and stage the root copy, because the 0.38.0 ship agent lacks Step 5c. This closes req-002 AC4.
- P9: raise the PR as a draft, because exception items wait.

**Rule breaches:** subagents broke the Write-or-Edit rule (boot Hard Limit 8) three times. The orchestrator ran a P0 `git rm`. A P3 test-writer ran `sed -i`. A P5 test-writer used a Python one-liner. The orchestrator reviewed each diff before commit. Backlog 0000238 tracks the gap.

## 3. Version

0.39.0, from tag `v0.39.0`, pushed to origin.

## 4. PR

[#77](https://github.com/RAVINTIO/ravintio-framework/pull/77), a draft. CI on the head that P9 read: 12 passed and 2 failed.

- red: [Test suite (windows-latest, shard 5 of 7)](https://github.com/RAVINTIO/ravintio-framework/actions/runs/42409694287/job/128514941416)
- red: [Test suite (windows-latest, shard 6 of 7)](https://github.com/RAVINTIO/ravintio-framework/actions/runs/42409694287/job/128514941456)

Both failures sit in two new suites, `test-0000041-req-005-applies-to-header.sh` and `test-0000041-req-006-consumer-migration.sh`. Their link, import-path, and byte-compare cases don't hold under Git Bash. The scripts pass on Linux and macOS.

## 5. Clean tree

The scoped check over `plan/`, `docs/`, and `src/**/docs/` reads clean. One file outside that scope stays untracked: `ravintio-framework/release.yml`, which the credential scan held back.

## 6. Exceptions waiting

- **P6, item 3:** approve the P0 `git rm` of six picked-up backlog folders. It was a shell delete outside the one approved git pass (review row 1).
- **P6, item 1:** approve the release script's three-folder write and delete boundary (review row 3).
- **P6, item 2:** approve the migrator table for the released `retroactive-release-tags.md` (review row 4).
- **P6, item 1:** approve that you run `rm -- ravintio-framework/component.yml` and the migrator checks it (review rows 5 and 10).
- **P6, item 2:** approve req-006 step 3a (review row 6).
- **P6, item 2:** approve the Scope Lock change to recover by state (review rows 9 and 12).
- **P6, item 1:** accept the release script race RS-F02 to RS-F04 under R-002 (review row 14).
- **P6, item 2:** accept R-015, with RC-F01 and RC-F03 to RC-F07 open against US-002 (review row 16).
- **P7, item 7:** review `ravintio-framework/release.yml` lines 634 and 635, which the credential scan flagged. Both lines are path and SHA-256 pairs in the vendored risk requirements analysis skill. If you confirm a false positive, commit the file. Until then, the `release-copy-integrity` job prints its skip notice. Backlog 0000425.
- **P9, item 6:** fix the two red Windows shards in a new run. P7 archived the design, so `gate-write` blocked every fix attempt. Backlog 0000426 holds the planned edits.

After merge, run a setup refresh, so this repo's `CLAUDE.md` names the eighth sanctioned script.

Next: the human on the loop reviews and merges the PR.
