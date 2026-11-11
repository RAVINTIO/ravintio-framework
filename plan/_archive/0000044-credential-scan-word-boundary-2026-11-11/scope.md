---
title: "Scope - credential-scan-word-boundary"
summary: "In, out, and deferred scope for 0000044."
---
# Scope - credential-scan-word-boundary

## In Scope

- The `api-secret-key` pattern in `src/ravintio-framework/scripts/credential-scan.mjs` (req-001)
- The new cases in `test-0000037-req-003-credential-scan.sh` and its regression copy (req-001)
- The 0.39.3 patch version, and the P7 release copy rebuild with `release.yml` committed

## Out of Scope

- Every other content rule and every refused file name
- An allowlist for `release.yml` or any other file
- gitleaks rules and gitleaks configuration
- Hand edits to the untracked `release.yml` on disk

## Deferred

- Nothing deferred.
