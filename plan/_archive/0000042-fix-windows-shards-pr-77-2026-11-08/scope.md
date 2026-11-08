---
title: "Scope - fix-windows-shards-pr-77"
summary: "In, out, and deferred scope for 0000042."
---
# Scope - fix-windows-shards-pr-77

## In Scope

- the req-005 suite: `IS_WIN`, the `pwd -W` work folder, four link-case skips, the `pathToFileURL` import, and the blob id compare
- the req-006 suite: the Case 6 skip on Windows
- two Windows skip rows in `src/ravintio-framework/tests/README.md`
- the 0.39.1 patch version and the P7 release copy rebuild

## Out of Scope

- `project-kind.mjs`, the migrator, and every released migration
- the ship sequence and `gate-write` change in backlog 0000426
- backlog 0000425, the credential-scan false positive on `release.yml`
- backlog 0000427, the run-mode anchor history walk

## Deferred

- Nothing deferred. Backlog 0000426 stays open for its ship and gate change, and nothing in this run waits on it.
