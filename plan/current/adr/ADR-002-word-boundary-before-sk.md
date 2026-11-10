---
title: "ADR 002: Word boundary before sk-"
summary: "The api-secret-key rule needs a word boundary before sk-, and accepts a false negative for a key glued to a word."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Word boundary before `sk-`

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000044-credential-scan-word-boundary
**Component:** ravintio-framework
**Date:** 2026-11-10

## Context

The `api-secret-key` rule reads `/sk-[A-Za-z0-9_-]{20,}/`. It matches `sk-` anywhere on a line, including inside a word. Every release build writes two `release.yml` hash lines for the vendored risk requirements analysis skill. The folder name holds `sk-` inside the word `risk`, followed by more than 20 path characters. So every autonomous P7 holds back `release.yml`, and the human on the loop clears it by hand (backlog 0000425). The fix must not edit a held-back file to hide a match.

## Decision

- The rule becomes `/\bsk-[A-Za-z0-9_-]{20,}/`.
- `\b` holds at the start of a line or between a word character and any other character. A word character is a letter, a digit, or `_`.
- The rule therefore skips `sk-` after a letter, a digit, or `_`. It still matches at column 1 and after every other character, such as `=`, a quote, a colon, a space, `-`, or `/`.
- The trade is a known false negative. A real key glued to a word character, such as `KEY_sk-...`, goes undetected by this rule. The human on the loop accepted this trade at the P0 Scope Lock (error path).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Allowlist `release.yml` | No change to any rule | A real key in `release.yml` would go unseen, and an allowlist invites more entries | Hides a whole file, which is broader than the false match |
| A rule that skips the `release.yml` hash-line shape | Exact fit for the known false match | Ties the scan to one file format, and any other word ending in `sk` still trips | Fixes one symptom, not the cause |
| A lookbehind that excludes only letters | Still catches `_sk-` and `1sk-` | A second, less common pattern for readers, and `_sk-` inside identifiers still trips | `\b` is the standard boundary and reads at a glance |
| Raise the length floor above 20 | No boundary logic | Real keys vary in length, and long path names still trip | Trades one false match for a missed real key |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | One pattern in `scripts/credential-scan.mjs`, and new cases in both copies of the 0000037 credential scan suite |

## Consequences

**Positive:**
- `release.yml` commits at P7 without a hold-back.
- Prose and paths that hold a word ending in `sk`, such as `task-` or `desk-`, no longer trip the rule.

**Negative:**
- A key glued to a letter, a digit, or `_` goes undetected by the regex rule (risk register R-001).

**Risks:**
- A future vendored folder whose name starts with `sk-` still trips the rule after `/`. The scan then holds the file back, as it does now.

## Related ADRs

- ADR-001 - related-to

## Supersedes

- None

## Superseded By
