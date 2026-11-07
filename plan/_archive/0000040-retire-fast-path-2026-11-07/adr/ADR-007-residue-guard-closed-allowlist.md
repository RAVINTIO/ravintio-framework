---
title: "ADR 007: Residue guard with a closed allowlist and a history-line rule"
summary: "A Bash suite fails on any live reference to either retired track outside the excluded history prefixes, a closed allowlist, and a history-line rule. A stale allowlist entry fails the suite. The P3 TDD fixtures on all three CI shards settle the matching rules."
status: "accepted"
version: "0.1.0"
---
# ADR-007 - Residue guard with a closed allowlist and a history-line rule

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Component:** ravintio-framework
**Date:** 2026-11-06

## Context

This feature retires two pipeline tracks. Without a guard, references to them return through copied text and old habits. Nothing would flag them, and the pack would drift back to more than one track.

Some references must stay. History records name the mechanism they retire. Released migrations never change. Setup must name installed copies to remove them. Some suites plant the retired words to prove the gates ignore them.

Feature 0000039 met the same problem for the old brand name. Its decision, 0000039 ADR 007, added a Bash suite with a `path_regex|line_regex|reason` allowlist and a stale-entry check. That suite is `ravintio-framework/tests/test-0000039-req-007-brand-guard.sh`. It runs on the Linux, macOS Bash 3.2, and Windows shards.

The P1 design critic ran nine passes over req-006, across three approaches. Each pass found a new interaction between the matching rules. The loop state at `plan/current/loop-state-design_critic.md` records the history:

1. Approach 1 added one enumerated allowlist line per finding. It could not cover decision and release lines that req-007 writes later.
2. Approach 2 added a history-line rule for those records. The critic then found that the order of the strip and the rule mattered.
3. Approach 3 wrote one ordered algorithm and tested it on fixture cases. The budget ran out with four fixes unreviewed.

On 2026-11-06 the human on the loop chose to let the P3 TDD fixtures settle the matching rules. Those fixtures run on all three CI shards, which a paper review can't do.

This decision governs req-006.

## Decision

Add the Bash suite `ravintio-framework/tests/test-0000040-req-006-residue-guard.sh`. It mirrors the brand guard from 0000039 ADR 007.

The suite reads tracked files from `git ls-files`. It drops each path under these history prefixes:

- `plan/_archive/`
- `plan/changelog/`
- `plan/_migrations/`
- `plan/current/`
- `plan/backlog/`
- `plan/reports/`

For each remaining path and each line, the guard runs one ordered algorithm:

1. Make a stripped copy that removes `0000040-retire-fast-path` and `retire-fast-path-and-change-pipeline`. These are the feature ID and the new migration slug.
2. Match the retired-track patterns on the stripped copy. If none match, the line passes.
3. On a match, test the unstripped line against the allowlist and the history-line rule. If either covers it, the line passes. Otherwise the suite fails with the file and line number.

Paths go through the same steps. Only allowlist entries can cover a path.

The allowlist is closed. Each entry has the form `path_regex|line_regex|reason`, and the brand guard parser reads it. That parser takes the text before the first `|` as the path regex, so no path regex holds `|`. An entry covers a line when both regexes match. If P3 needs an entry that req-006 doesn't name, P3 logs a deviation and adds the entry with a reason.

The history-line rule covers decision and release records in four files only:

- In `docs/decisions-index.md` and `docs/architecture-overview.md`, a line passes if it names a feature ID with `ADR`, or holds a superseding note.
- In `docs/about.md`, a line passes if it names a feature ID.
- In `ravintio-framework/component.yml`, a comment line passes if it sits in a dated `# Updated by` history block.

A stale entry fails the suite. An entry with the line regex `.*` goes stale when no tracked path matches its path regex.

Every regex is POSIX extended regex, as Bash `[[ =~ ]]` reads it on Bash 3.2. No regex uses `\s`, `\d`, or `\b`. The suite reads lines with `done <<< "$(...)"`, never `done < <(...)`.

The P3 TDD fixtures settle the matching rules on the Linux, macOS Bash 3.2, and Windows shards. If a fixture shows a fault in a rule, P3 fixes the rule under TDD. The fix logs `Deviation (P3, unclassified)` and updates req-006 to match.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| An enumerated allowlist only, with one entry per kept line (approach 1) | Every kept line is named and reviewed | Can't track the decision and release lines the feature writes later. Each new line needs a new entry. | Three critic passes found a missing entry each time |
| No guard | No suite to build or maintain | References return without a signal, and nobody sees the drift until a reader follows a retired route | The feature exists to leave one track. Without a guard, nothing keeps it that way. |
| A Node.js guard | Full regex dialect, one code path on every shard | A second runner style for one suite. The brand guard it mirrors is Bash. | ADR-001 keeps the stack and rejects this option |
| Settle the matching rules by more paper review | No P3 fixture work for the rules | Nine passes each found a new interaction. A review can't run Bash 3.2. | The human on the loop chose P3 fixtures on 2026-11-06 |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Gains the req-006 suite. Every later change to a live file must pass it. Setup, docs, and suites that keep a retired word need an allowlist entry or a history-line form. |

## Consequences

**Positive:**
- A live reference to either retired track fails CI with its file and line number.
- The history-line rule covers new decision and release lines without a new entry for each one.
- The stale-entry check keeps the allowlist as small as the tree needs.
- The suite reuses the brand guard parser and its Bash 3.2 line-reading pattern.

**Negative:**
- Bash 3.2 limits the regexes to POSIX extended regex, so patterns are longer and harder to read.
- New decision lines in the four history files must name a feature ID on the same line.
- The matching rules stay unreviewed by the design critic. P3 fixtures are the only check on them.

**Risks:**
- A P3 fixture can show a fault in a rule. The fix is then a logged deviation, and req-006 changes during P3.
- A broad line regex such as `.*` can hide a new residue line inside an allowed file.
- An entry the brand guard holds for a deleted file goes stale. The brand guard then fails until the deleting change removes that entry.

## Related ADRs

- ADR-001 - depends-on: the stack and the POSIX extended regex dialect.
- ADR-002 - related-to: the guard enforces the one-track decision.
- ADR-004 - related-to: the old constant name is renamed, so the guard needs no entry for it.
- ADR-005 - related-to: the guard's setup entries follow the retired list layout.
- 0000039 ADR 007 - extends: the brand guard allowlist form and parser.

## Supersedes

- None

## Superseded By

- None
