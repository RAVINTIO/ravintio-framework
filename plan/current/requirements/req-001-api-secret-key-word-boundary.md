---
title: "Requirement: req-001 - api-secret-key word boundary"
summary: "Detailed requirements for this specific functional feature."
status: "active"
version: "0.1.0"
---
# Requirement: req-001 - api-secret-key word boundary

**Skill:** [spec-agent](../skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000044-credential-scan-word-boundary
**Source:** US-001
**Priority:** must-have

## User Story

As a framework maintainer, I run the credential scan on a release build, so that `release.yml` commits without a false hold-back.

## Functional Requirements

- The `api-secret-key` entry in `CONTENT_RULES` in `src/ravintio-framework/scripts/credential-scan.mjs` reads `/\bsk-[A-Za-z0-9_-]{20,}/`.
- The rule matches `sk-` at the start of a line or after any character that isn't a letter, a digit, or `_`.
- The rule doesn't match `sk-` after a letter, a digit, or `_`.
- No other content rule, name rule, or output format changes. The scan still never prints matched text.
- `test-0000037-req-003-credential-scan.sh` and its copy under `tests/regression/` gain the same new cases:
  - A `release.yml` hash line under the vendored risk requirements analysis skill folder, with a 64-character hex hash, exits 0. The fixture builds the folder name at run time.
  - `sk-` keys after a letter, a digit, and `_` each exit 0.
  - `sk-` keys after `=`, a double quote, and a space each exit 1 and report `api-secret-key`.
- Each new fixture builds its key at run time, as the existing `rule_case` fixtures do, so the suite file holds no matching text.
- Split step: keep. The requirement holds one observable outcome in three criteria.

## Acceptance Criteria

- [ ] `credential-scan.mjs --file` exits 0 on a `release.yml` line under an `external-skills/risk-` path with a 64-character hash, and on `sk-` keys after a letter, a digit, and `_`.
  - Verified by: unit - the new negative cases in both copies of the 0000037 suite
- [ ] `credential-scan.mjs --file` exits 1 and reports `api-secret-key` for an `sk-` key at a line start and after `=`, a double quote, and a space.
  - Verified by: unit - the existing line-start case and the new positive cases in both copies of the 0000037 suite
- [ ] At P7, the scan passes the rebuilt `ravintio-framework/release.yml`, and the P7 commit includes it.
  - Verified by: execution - the P7 `credential-scan.mjs --safe-paths` run lists `ravintio-framework/release.yml` as safe, and `git ls-files` shows it after the P7 commit

## Dependencies

- `credential-scan.mjs` from 0000037 ADR-001, Node built-ins only.
- The release script `scripts/build-release.mjs` from 0000041, which writes `release.yml`.
