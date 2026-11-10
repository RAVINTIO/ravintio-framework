---
title: "ADR 001: Stack unchanged"
summary: "0000044 keeps the declared stack and the scan's Node built-ins rule."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Stack unchanged

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000044-credential-scan-word-boundary
**Component:** ravintio-framework
**Date:** 2026-11-10

## Context

The design declares Node built-ins, Bash suites under `run-tests.sh`, and GitHub Actions CI, with a local build target. The change edits one regular expression in `credential-scan.mjs` and adds cases to one Bash suite and its regression copy. The scan uses Node built-ins only, under 0000037 ADR 001.

## Decision

- The stack stays as declared. No new language, package, or tool enters the repository.
- `credential-scan.mjs` keeps its Node built-ins only rule. The new pattern uses the JavaScript `\b` assertion, which every supported Node version has.
- The `ravintio-framework` component owns every changed file under `src/ravintio-framework/`. The P7 release script owns the rebuilt root copy and its `release.yml` (0000041 ADR 004).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Require gitleaks for every scan | A maintained rule set with entropy checks | A new required binary on every machine and CI runner | 0000037 ADR 001 keeps the scan to Node built-ins, and gitleaks already runs where it is installed |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | One rule in `scripts/credential-scan.mjs`, and new cases in both copies of the 0000037 credential scan suite |

## Consequences

**Positive:**
- No new dependency reaches CI or the release copy.

**Negative:**
- The regex rules stay the only check on machines without gitleaks, so their accuracy matters more (ADR-002).

**Risks:**
- None beyond the risk register.

## Related ADRs

- ADR-002 - related-to

## Supersedes

- None

## Superseded By
