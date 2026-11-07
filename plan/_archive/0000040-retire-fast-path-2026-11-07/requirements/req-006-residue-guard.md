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
- Approach 2 iteration 1 revision. These lines govern the history-line rule above where they differ:
  - `docs/decisions-index.md` and `docs/architecture-overview.md`: a line passes if it names a feature ID together with `ADR`, or holds `[Ss]upersed`.
  - `docs/about.md`: a line passes if it names a feature ID. A release row has no ADR.
  - `ravintio-framework/component.yml`: a comment line passes if it belongs to a history block. A history block starts at a `# Updated by` line and runs over the next `#` lines up to the next `# Updated by` line or the first line that is not a comment. This covers line 264, which continues the 0000033 comment.
- One entry covers every 0000040 suite for req-001 to req-005. Path regex: `^ravintio-framework/tests/(regression/)?test-0000040-req-00[1-5]-[a-z0-9-]+\.sh$`. Reason: each suite plants or checks for the retired words. The suites are named in their requirements.
- Approach 2 iteration 2 revision: each suite entry, including the req-002 rewrite table entries and the `test-0000040` path entry, uses the line regex `.*`. For these entries, the stale-entry check fails when no tracked path matches the path regex.
- Correction: `path-rules.mjs` holds no entry for `workflows/fast-path.md`.

### Guard algorithm (approach 3, governing)

This section governs every earlier line in this file about stripping, the history-line rule, and allowlist matching. Where an earlier line differs, this section wins. A scratchpad prototype ran this algorithm on the 13 fixture cases below, and every case gave its expected verdict.

1. List tracked files with `git ls-files`, and drop each path under an excluded prefix.
2. For each path, and for each line of each file, make a stripped copy. The strip removes `0000040-retire-fast-path` and `retire-fast-path-and-change-pipeline`.
3. If no pattern matches the stripped copy, the line passes.
4. If a pattern matches, test the original, unstripped line against the rules below. If any rule covers it, the line passes. Otherwise the guard fails with the file and line number.
   - An allowlist entry covers the line when its path regex matches the path and its line regex matches the unstripped line.
   - The history-line rule covers the line in these files only. A feature ID is seven digits with no digit on either side, so `0000040-retire-fast-path` holds one.
     - `docs/decisions-index.md` and `docs/architecture-overview.md`: the line holds a feature ID and `ADR`, or holds `[Ss]upersed`.
     - `docs/about.md`: the line holds a feature ID.
     - `ravintio-framework/component.yml`: the line sits in a history block. A block starts at a `# Updated by` line and runs over the following `#` lines, up to the next `# Updated by` line or the first line that isn't a comment.
5. Paths follow the same steps, with the path itself as the line. Only allowlist entries can cover a path.

Fixture cases for the suite. Each gives a path, a line, and the expected verdict:

| Path | Line | Verdict |
|------|------|---------|
| `docs/decisions-index.md` | `### Feature 0000040-retire-fast-path` | pass, no match after the strip |
| `docs/decisions-index.md` | `\| ADR 001 \| Fast Path retired (0000040-retire-fast-path) \| accepted \|` | pass, history-line rule |
| `docs/decisions-index.md` | `\| 0000033 ADR 009 \| Fast Path admits no-src \| superseded by 0000040 ADR 001 \|` | pass, history-line rule |
| `docs/decisions-index.md` | `Fast Path is the quick route.` | fail |
| `docs/architecture-overview.md` | `- **ADR 009 (0000033):** Fast Path admits a change. superseded by 0000040 ADR 001` | pass, history-line rule |
| `docs/architecture-overview.md` | `### Fast Path for changes with no src target` | fail |
| `docs/about.md` | `\| 0.38.0 \| 0000040-retire-fast-path \| Retired Fast Path and the Change Pipeline \|` | pass, history-line rule |
| `docs/about.md` | `Use Fast Path for small fixes.` | fail |
| `ravintio-framework/component.yml` | `# budget, Fast Path for no-src changes`, inside a history block | pass, history-line rule |
| `ravintio-framework/component.yml` | `# budget, Fast Path for no-src changes`, outside any history block | fail |
| `README.md` | `Feature 0000040-retire-fast-path removed both tracks.` | pass, no match after the strip |
| `README.md` | `Run the Change Pipeline for small changes.` | fail |
| `product.yml` | `feature: "0000040-retire-fast-path"` | pass, no match after the strip |

The suite runs these cases as planted lines in scratch copies of each file, alongside the planted cases above.

The correction before this section continues here: `path-rules.mjs` holds no entry for `workflows/fast-path.md`. Only the comment above `FAST_PATH_ENFORCEMENT_PATHS` cites it, and req-002 rewrites that comment. The brand guard's stale-entry risk concerns only its `workflows/fast-path.md` row.

### Line regexes for the remaining entries (approach 3 iteration 1)

Every allowlist entry names a line regex. These govern the entries listed earlier that gave none:

| Entry | Path regex | Line regex |
|-------|-----------|------------|
| Released migrations | `^ravintio-framework/migrations/migrate-0\.3[47]\.0-` | `.*`. Released files never change, so the whole file is covered. |
| The new migration and its helpers | `^ravintio-framework/migrations/migrate-0\.38\.0-retire-fast-path-and-change-pipeline` | `.*`. The migration names both tracks throughout. |
| Suites that test released migrations | `^ravintio-framework/tests/(regression/)?test-0000036-req-001-` and `test-0000039-req-006-` | `.*` |
| The setup retired list | `^ravintio-framework/setup\.(sh\|ps1)$` | `^\s*['"][^'"]*(fast-path\|change-pipeline\|ravintio-change-agent)[^'"]*['"],?\s*$`. It matches a line that holds only one quoted retired name, as a list item does. |

In this table, `\|` is the Markdown escape for the regex alternation `|`. The orchestrator tested the setup line regex on both fixture lines below, and it gave the expected result.

Two more fixture cases cover the setup entry:

| Path | Line | Verdict |
|------|------|---------|
| `ravintio-framework/setup.sh` | `  "commands/fast-path.md"` | pass, setup entry |
| `ravintio-framework/setup.sh` | `echo "Use Fast Path for small fixes"` | fail |

### Path regex rule (approach 3 iteration 2, governing)

The brand guard parser takes the text before the first `|` as the path regex. So no path regex holds `|`. The line regex may hold `|`. This rule replaces two rows in the table above:

- The setup retired list becomes two entries. Their path regexes are `^ravintio-framework/setup\.sh$` and `^ravintio-framework/setup\.ps1$`. Both keep the line regex from the table.
- Suites that test released migrations become two entries. Their path regexes are `^ravintio-framework/tests/(regression/)?test-0000036-req-001-` and `^ravintio-framework/tests/(regression/)?test-0000039-req-006-`. Both use the line regex `.*`.
- Every other path regex in this file holds no `|`. The orchestrator checked each one.
- Add a parser fixture. For each allowlist entry, the suite checks that the text before the first `|` is the intended path regex, and fails on any entry whose path regex part is empty or holds `(` without a matching `)`.

### Regex dialect and retired list form (after escalation, not yet reviewed)

These lines answer critic verdict 9 and govern the earlier lines they name. No critic has reviewed them yet.

- Every regex in this file is POSIX extended regex, as Bash `[[ =~ ]]` reads it on Bash 3.2. No regex uses `\s`, `\d`, or `\b`.
- The setup line regex becomes `^[[:space:]]*['"][^'"]*(fast-path|change-pipeline|ravintio-change-agent)[^'"]*['"],?[[:space:]]*$`. The orchestrator ran it under `/bin/bash` 3.2.57. It matched `  "commands/fast-path.md"` and `  'skills/ravintio-change-agent',`, and it rejected `echo "Use Fast Path for small fixes"`. The `\s` form rejected all three.
- The retired list items follow req-004's two-array form. So the setup pass fixture becomes `  "fast-path.md"`.
- The first criterion counts three covers for a match: an excluded prefix, an allowlist entry, and the history-line rule from the guard algorithm.

### P3 fixtures settle the matching rules

The human on the loop chose this route on 2026-11-06, after the P1 critic budget ran out.

- The P3 TDD fixtures settle the guard's matching rules, and paper review does not. The fixtures run on the Linux, macOS Bash 3.2, and Windows CI shards.
- If a fixture shows a fault in a rule above, P3 fixes the rule under TDD. The fix logs `Deviation (P3, unclassified)` and updates this file to match.
- The four fixes in the section above stand as written until a fixture shows a fault.

### What P3 built (governing)

The P3 fixtures and the real tree settled these rules. They govern every earlier line they name. The 13 guard-algorithm fixtures and the setup line regex passed as written.

- The 0000040 suite entry's path regex is `test-0000040-req-00[1-57]-`. The req-007 suite plants history-line cases, so it names the retired words.
- A new entry covers one history comment in `test-0000038-req-004-phase-scoped-orchestrator.sh`, in both folders. Its line regex is `^# Feature 0000040 req-001 then dropped the Fast Path and Change Pipeline bump`. The comment records why req-001 re-pinned the hashes.
- The req-002 rewrite-table rule changes. Entries exist only for the suites that still name a track: `test-0000035-req-003` and `test-0000036-req-00[89]`. The retired suites get no entry, and neither do suites that name no track.
- The stale-entry rule changes. Every entry, `.*` included, goes stale when it covers no match. This replaces the approach 2 iteration 2 rule for `.*` entries.
- The guard adds its own path to the scan when git doesn't list it yet, so its own entry isn't stale before the first commit.
- The parser fixture requires each path regex to be non-empty, anchored with `^`, balanced in its parentheses, and valid. Each line regex must be valid, and each reason non-empty.

### Functional Requirements, continued

The lines below continue the main Functional Requirements list. They are not part of the line regex section above.
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
