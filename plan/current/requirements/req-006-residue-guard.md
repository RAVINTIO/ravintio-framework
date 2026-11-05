---
title: "Requirement: req-006 - residue-guard"
summary: "A guard suite fails when a live tracked path or line names Fast Path or the Change Pipeline outside a closed allowlist."
status: "draft"
version: "0.1.0"
---
# Requirement: req-006 - residue-guard

**Skill:** [spec-agent](../../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Source:** US-001
**Priority:** must-have

## User Story

As a human on the loop, I get a failing test when a live file brings back Fast Path or the Change Pipeline, so that every change keeps one track.

## Functional Requirements
- Add the suite `ravintio-framework/tests/test-0000040-req-006-residue-guard.sh`. Build it on the model of `test-0000039-req-007-brand-guard.sh`.
- `run-tests.sh` finds every `tests/test-*.sh` file by glob, so the suite needs no registration.
- Read the tracked files from `git ls-files`. Drop each path that starts with one of these prefixes before any check:
  - `plan/_archive/`, because archived features are history.
  - `plan/changelog/`, because release notes are history.
  - `plan/_migrations/`, because applied migration records are history.
  - `plan/current/`, because its files describe the retirement until ship archives them.
  - `plan/backlog/`, because backlog entries are dated records. Many name a track as their subject, such as 0000307 and 0000308, and a rewrite would change their meaning.
  - `plan/reports/`, because each report is a dated record.
- Match these patterns. The first three ignore case, and the last two match case exactly:
  - `fast[ _-]?path`, which also catches `FAST_PATH_ENFORCEMENT_PATHS` and `.fast-path-scope`
  - `change[ -]pipeline`
  - `change-agent`, which catches `ravintio-change-agent`
  - `PC:`
  - `fix\(fast-path\):`
- Before any check, strip two neutral identifiers from each path and line:
  - `0000040-retire-fast-path`, the feature ID, which `product.yml`, `docs/about.md`, and the decisions index carry
  - `retire-fast-path-and-change-pipeline`, the slug of the new migration file
- A stripped line still fails when it holds another match.
- Fail on any remaining path or line that no allowlist entry covers. Print the file and line number.
- Write each allowlist entry as a path regex, a line regex, and a reason. Both regexes must match. Use the `path_regex|line_regex|reason` form that the brand guard parses.
- Allow only these cases. Each entry names its reason:
  - This suite and its regression copy, in one entry. Path regex: `^ravintio-framework/tests/(regression/)?test-0000040-req-006-residue-guard\.sh$`. Reason: the guard names the words to match them.
  - Migrations released before 0.38.0: `migrate-0.34.0-rerun-setup.md` and the three `migrate-0.37.0-ravintio-rename.*` files. Reason: released migration files never change.
  - The new `migrate-0.38.0-retire-fast-path-and-change-pipeline.md`, its helpers if any, and the req-005 suites. Reason: the migration deletes the scope record and the exemption by name.
  - Setup lines in the named retired list in `setup.sh` and `setup.ps1`, and the req-004 suites that plant installed copies. Reason: setup removes those copies by name.
  - The req-002 suites that plant `plan/.fast-path-scope`, and the req-003 suites that push a `fix(fast-path):` subject. Reason: they prove the gates and CI ignore both.
  - Suites that test a released migration, namely `test-0000036-req-001-rerun-setup-migration.sh` and `test-0000039-req-006-consumer-migration.sh`. Reason: they assert the text of released migrations.
  - Lines in `docs/decisions-index.md` and `docs/architecture-overview.md` that hold `[Ss]upersed`. Reason: superseding notes name the decision they replace.
  - The `0000033` history comment in `ravintio-framework/component.yml`, line regex `Fast Path for no-src changes`. Reason: the dated `Updated by` comments are history.
  - The vendored line in `ravintio-framework/external-skills/plan-eng-review/SKILL.md`, line regex `^\*\*Fast path:\*\* All paths covered`. Reason: vendored third-party text, where the words carry another meaning.
- P1 critic revision adds these entries, each with its reason:
  - `test-0000017-req-007-change-agent-archive.sh` in `tests/` and `tests/regression/`, its line in `tests/regression/regression-manifest.json`, and the lines in `test-0000039-req-005-history-and-split-name-protection.sh` that name it. Reason: the suite keeps its name, because no sanctioned step removes a manifest entry (backlog 0000365).
  - Suites that assert the words are absent: `test-0000040-req-001-one-track-routing.sh`, `test-0000040-req-004-remove-track-files.sh`, and the rewritten `test-0000032-req-003` and `test-0000032-req-004` suites in both folders. Reason: an absence check names the words it checks for.
  - Every suite in req-002's rewrite table. Reason: those suites prove the gates ignore the scope record, so they name it.
  - If P2 or P3 retires a suite from that table, its entry goes in the same change, so no entry goes stale.
- Approach 2 revision, the history-line rule. It replaces the two `[Ss]upersed` entries and the one `component.yml` entry above. One entry covers every line that records a decision or a release, in these files only:
  - `docs/decisions-index.md`, `docs/architecture-overview.md`, and `docs/about.md`: a line that names a feature ID such as `0000033` or `0000040` together with `ADR`, or holds `[Ss]upersed`.
  - `ravintio-framework/component.yml`: a comment line that starts `# Updated by` or names a feature ID.
  - Reason: decision and release records name the mechanism they add or retire. A line in these files without a feature ID or a superseding note still fails.
- req-007 writes each new decision and release line so it names its feature ID on the same line, which brings it under this rule.
- No other file gets an entry. That rule covers these:
  - hooks
  - setup lines outside the retired list
  - both CI files
  - skills and templates
  - docs
- The `.gitignore` block for `plan/.fast-path-scope` goes, because the migration deletes the file and the gates ignore it.
  - req-002 owns that removal, per the execution plan's file ownership table. This suite only checks it.
- The guard runs last in P3, after req-007's live-doc rewrites land, per the execution plan's build order.
- Split step for the third criterion: keep. The three-shard pass is the run condition of the stale-entry check, not a second outcome.
- If P3 needs an entry this list does not name, log a deviation and add it with a reason. The list stays closed.
- Fail the suite when an allowlist entry matches no path and no line. A stale entry must not stay.
- Add planted cases on scratch copies of `README.md`. Plant `Fast Path`, `Change Pipeline`, `PC:`, and `fix(fast-path):` on separate lines. Expect a flag with the file and line number for each.
- Add a path case. Feed the path check `ravintio-framework/workflows/fast-path.md` and expect a flag.
- Read lines with `done <<< "$(...)"` and skip empty lines. Never use `done < <(...)`, because macOS Bash 3.2 drops lines from that form.
- Regression pack: tag the suite `# REGRESSION-CANDIDATE:`. The guard guards a standing rule, so it belongs in the long-term pack. At P7 the ship agent runs `promote-to-regression.sh`, which copies the suite to `tests/regression/` and adds its entry to `regression-manifest.json`. Nobody edits the manifest by hand.
- Interaction with the brand guard: `test-0000039-req-007-brand-guard.sh` and its regression copy hold an entry for `workflows/fast-path.md`. That entry goes stale when req-004 deletes the file, and the brand guard then fails. The change that deletes the file also removes the entry from both copies. The same holds for the `path-rules.mjs` entry if req-002 removes its line.
- Split step: keep. The pattern scan, the path check, and the stale-entry check share one allowlist and one pass over the tree, so they form one concern.

## Acceptance Criteria
- [ ] The suite passes on the finished tree, and every remaining match falls under an excluded prefix or an allowlist entry with a reason. Verified by: integration
- [ ] Each planted line in the scratch `README.md` fails the check with its file and line number. The `workflows/fast-path.md` path also fails. Verified by: integration
- [ ] A stale allowlist entry fails the suite. The suite passes on the Linux, macOS Bash 3.2, and Windows CI shards. Verified by: integration

## Dependencies
- req-001 to req-005 remove the live references before the suite can pass.
- req-002, req-003, req-004, and req-005 name the suites and setup lines that the allowlist covers.
- req-007 writes the superseding notes that the decisions-index entry covers.
- Existing pattern: `ravintio-framework/tests/test-0000039-req-007-brand-guard.sh`.
