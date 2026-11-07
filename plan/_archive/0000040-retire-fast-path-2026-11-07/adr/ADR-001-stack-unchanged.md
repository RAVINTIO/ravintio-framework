---
title: "ADR 001: Stack unchanged"
summary: "Feature 0000040-retire-fast-path keeps the declared stack. It removes code and files and adds Bash, PowerShell, and Node.js code of the kinds the pack already uses."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Stack unchanged

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Component:** ravintio-framework
**Date:** 2026-11-06

## Context

The confirmed design records the stack as unchanged. The pack uses these parts:

- Bash and PowerShell setup scripts
- Node.js `.mjs` hooks and scripts that use only built-in modules
- Bash test suites under `run-tests.sh`
- GitHub Actions CI on Linux, macOS, and Windows shards

This feature retires two pipeline tracks. Most of its work removes files and code. Its new code is a retired list in setup, a source folder rule in pre-push and CI, a migration, and a residue guard suite.

## Decision

Keep the declared stack. Every new piece uses a language the pack already uses:

- The retired list goes in `setup.sh` and `setup.ps1`, in Bash and PowerShell.
- The source folder rule goes in `hooks/pre-push` in Bash, and in both CI files as workflow shell steps.
- The hook changes stay in Node.js `.mjs` with built-in modules only.
- The residue guard is a Bash suite that runs on Bash 3.2 and uses POSIX extended regex.

The feature adds no dependency, package, or tool.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Write the residue guard in Node.js | Full regex support, one code path on every shard | A second test runner style for one suite, and the brand guard it mirrors is Bash | The brand guard pattern already works on all three shards |
| Read `product.yml` in pre-push with a Node.js script | A real YAML parser | Pre-push would need Node.js, and the pack parses no YAML with a library today | The `components` list has a fixed, flat form that line matching reads |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | No new dependency. Setup, hooks, CI, and suites keep their languages. |

## Consequences

**Positive:**
- Consumers need no new tool to upgrade.
- The suites keep one style, so the CI shards need no change.

**Negative:**
- Bash 3.2 limits the guard's regex to POSIX extended regex, so patterns can't use `\s` or `\b`.

**Risks:**
- A line-based read of `product.yml` can miss a hand-edited list in an unusual layout. ADR-003 states how the rule fails in that case.

## Related ADRs

- ADR-003 - related-to: the source folder rule reads `product.yml` without a YAML library.
- ADR-007 - related-to: the residue guard's regex dialect follows from this stack.

## Supersedes

- None

## Superseded By

- None
