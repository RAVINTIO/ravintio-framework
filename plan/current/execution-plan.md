---
title: "Execution Plan - credential-scan-word-boundary"
summary: "Non-functional requirements and change summary for 0000044."
---
# Execution Plan - credential-scan-word-boundary

## Summary

The `api-secret-key` rule gains a word boundary before `sk-`. The 0000037 credential scan suite gains negative and positive cases in both its copies. P7 rebuilds the release copy, and `release.yml` commits without a hold-back.

## Functional requirements

- [req-001 - api-secret-key word boundary](requirements/req-001-api-secret-key-word-boundary.md)

## Non-functional requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-001 | The rule stays linear on one long line | The pattern adds only the zero-width `\b`. It holds no nested quantifier. |
| NFR-002 | The scan prints no matched text | Every new suite case checks that the output lacks the fixture text. |
| NFR-003 | Node built-ins only (0000037 ADR-001) | No new import in `credential-scan.mjs`. |

## API and data summary

- API: none.
- Data: none. The change reads files and writes no record.

## Component

- `ravintio-framework`: `scripts/credential-scan.mjs`, `tests/test-0000037-req-003-credential-scan.sh`, `tests/regression/test-0000037-req-003-credential-scan.sh`, and `component.yml` for the 0.39.3 version.
