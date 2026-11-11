---
title: "Feature Brief - 0000044-credential-scan-word-boundary"
summary: "Stop the api-secret-key rule from matching sk- inside a word, such as a release.yml path under a risk- folder."
---
# Feature Brief - 0000044-credential-scan-word-boundary

Source: backlog 0000425 (filed 2026-11-07 at 0000041 P7).

## Business Goal

Every release build writes `release.yml` lines for the vendored risk requirements analysis skill. The `api-secret-key` rule in `credential-scan.mjs` matches the `sk-` inside the word `risk-` on those lines. So every autonomous P7 holds back `release.yml`, and the human on the loop must clear it by hand. The goal is a scan that ignores `sk-` inside a word but still catches a real `sk-` key.

## Features

1. Word boundary for the `api-secret-key` rule, with suite cases for both sides.

US-001: As a framework maintainer, I run the credential scan on a release build, so that `release.yml` commits without a false hold-back.

## Waves

One wave.

## Target Architecture

### Components

- `ravintio-framework` (component-pack): owns `scripts/credential-scan.mjs` and the 0000037 credential scan suite under `src/ravintio-framework/`.

### Data Ownership

- `ravintio-framework` owns every file under `src/ravintio-framework/`.
- The release script owns the root `ravintio-framework/` copy and `release.yml`.

### Integration Points

- Every caller of `credential-scan.mjs`: staged mode, `--file` mode, and `--safe-paths` mode.

## Stack

Unchanged. Node built-ins only (0000037 ADR-001). Bash suites under `run-tests.sh`. GitHub Actions CI. Build target: local.

## Scope Boundaries

### In Scope

- The `api-secret-key` pattern in `credential-scan.mjs`.
- New suite cases in the 0000037 credential scan suite and its regression copy.
- The P7 release rebuild, so `release.yml` commits on this branch.

### Out of Scope

- Any other content rule.
- An allowlist for `release.yml` or any other file.
- gitleaks rules.

### Deferred

Nothing deferred.

## Non-Functional Requirements

- The rule stays linear on one long line. No nested quantifiers.
- The scan output still never prints matched text.

## Constraints and Assumptions

### Constraints

- No agent edits a held-back file to hide a match (backlog 0000425).
- The release script, not **Write** or **Edit**, writes the root `ravintio-framework/` copy.

### Assumptions

- Real `sk-` keys start after a non-word character, such as `=`, a quote, a colon, or a space, or at the start of a line.

## Scenario Paths

Derived at P0 by the Scope Lock Challenge.

## Acceptance Criteria

1. `credential-scan.mjs --file` exits 0 on a line holding `external-skills/risk-requirements-analysis/SKILL.md` and a 64-character hash.
2. The rule still matches an `sk-` key at the start of a line, after `=`, after a quote, and after a space.
3. The rule doesn't match `sk-` preceded by a letter, a digit, or `_`.
4. At P7, the scan passes the rebuilt `ravintio-framework/release.yml`, and the P7 commit includes it.
