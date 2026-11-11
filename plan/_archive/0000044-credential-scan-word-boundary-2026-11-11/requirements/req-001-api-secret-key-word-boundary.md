---
title: "Requirement: req-001 - api-secret-key word boundary"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: req-001 - api-secret-key word boundary

**Skill:** [spec-agent](../../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000044-credential-scan-word-boundary
**Source:** US-001
**Priority:** must-have

## User Story

As a framework maintainer, I run the credential scan on a release build, so that `release.yml` commits without a false hold-back.

## Functional Requirements

- The `api-secret-key` entry in `CONTENT_RULES` in `src/ravintio-framework/scripts/credential-scan.mjs` reads `/\bsk-[A-Za-z0-9_-]{20,}/`.
- The rule matches `sk-` at the start of a line or after any character that isn't a letter, a digit, or `_`.
- The rule doesn't match `sk-` after a letter, a digit, or `_`.
- In this requirement, "letter" means an ASCII letter, `A` to `Z` or `a` to `z`. The pattern has no `u` flag, so `sk-` after a non-ASCII letter such as `é` still matches. P3 adds no negative case for a non-ASCII letter.
- P5 security finding S-001 adds an escape-aware boundary. The rule also matches `sk-` directly after a percent escape such as `%3D`, after `\n`, `\r`, or `\t`, or after a `\u` escape with 4 hex digits. The rule becomes `/(?:\b|(?<=%[0-9A-Fa-f]{2}|\\[nrt]|\\u[0-9A-Fa-f]{4}))sk-[A-Za-z0-9_-]{20,}/`.
- No other content rule, name rule, or output format changes. The scan still never prints matched text.
- `test-0000037-req-003-credential-scan.sh` and its copy under `tests/regression/` gain the same new cases:
  - A `release.yml` hash line under the vendored risk requirements analysis skill folder, with a 64-character hex hash, exits 0. The fixture builds the folder name at run time.
  - The hash-line fixture copies the real shape: two leading spaces, a quoted path, a colon, a space, and a quoted hash.
  - `sk-` keys after a letter, a digit, and `_` each exit 0.
  - Each negative case also checks that the output lacks `api-secret-key`.
  - `sk-` keys after `=`, a double quote, and a space each exit 1 and report `api-secret-key`. The space case is the existing `rule_case` fixture, so P3 adds no new space case.
  - `sk-` keys at column 1 and after a colon also each exit 1 and report `api-secret-key`. The column-1 case writes its fixture without the `rule_case` prefix. It still checks that the output lacks the fixture text.
  - The existing `rule_case` fixture puts its key after `x` and a space, so it already covers the space case.
- Each new fixture builds its key at run time, as the existing `rule_case` fixtures do, so the suite file holds no matching text.
- The `ravintio-framework` manifest under `src/` moves to version 0.39.3.
- Split step: keep. The requirement holds one observable outcome in six criteria. Criteria 4 and 5 sharpen criteria 1 and 2, which the ratchet keeps as written. Criterion 6, the version, ships only with the rule change and isn't a concern on its own.

## Acceptance Criteria

- [ ] `credential-scan.mjs --file` exits 0 on a `release.yml` line under an `external-skills/risk-` path with a 64-character hash, and on `sk-` keys after a letter, a digit, and `_`.
  - Verified by: unit - the new negative cases in both copies of the 0000037 suite
- [ ] `credential-scan.mjs --file` exits 1 and reports `api-secret-key` for an `sk-` key at a line start and after `=`, a double quote, and a space.
  - Verified by: unit - the new column-1 case, the existing `rule_case` space case, and the new positive cases in both copies of the 0000037 suite
- [ ] At P7, the scan passes the rebuilt `ravintio-framework/release.yml`, and the P7 commit includes it.
  - Verified by: execution - the P7 `credential-scan.mjs --safe-paths` run lists `ravintio-framework/release.yml` as safe, and `git ls-files` shows it after the P7 commit
- [ ] Each negative case output holds no `api-secret-key` line, and the `release.yml` fixture line copies the real hash-line shape.
  - Verified by: unit - the negative cases in both copies of the 0000037 suite
- [ ] `credential-scan.mjs --file` exits 1 and reports `api-secret-key` for an `sk-` key after a colon.
  - Verified by: unit - the new colon case in both copies of the 0000037 suite
- [ ] `credential-scan.mjs --file` exits 1 and reports `api-secret-key` for an `sk-` key after `%3D`, `%22`, `%20`, `%3A`, `\n`, `\t`, and a `"` escape.
  - Verified by: unit - the new escape cases in both copies of the 0000037 suite
- [ ] `src/ravintio-framework/component.yml` reads version `0.39.3`.
  - Verified by: execution - P4 reads the `version` line of `src/ravintio-framework/component.yml` and finds `"0.39.3"`

## Dependencies

- `credential-scan.mjs` from 0000037 ADR 001, Node built-ins only.
- The release script `scripts/build-release.mjs` from 0000041, which writes `release.yml`.
