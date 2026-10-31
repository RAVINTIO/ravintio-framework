# Changelog: 0000361 release scan exemptions

## 2026-10-31 - Fast Path: the 1.0.0 release scan skips backlog entries and reports

- Change: `test-0000039-req-010-version-bump.sh` AC2 now reads its skipped paths from an `EXEMPT` list. The list adds `plan/backlog` and `plan/reports`. The scan also passes `-I`, so binary files never match.
- Component: ravintio-framework, version 0.37.1 to 0.37.2
- Reason: Backlog 0000361. PR #74 failed CI on two mentions of 1.0.0 that make no release claim. One was an example profile version in backlog entry 0000348. The other came from the internals of the regulated strategy report PDF.
- Backlog: this change closes 0000361 and removes its entry.
- Paths:
  - `ravintio-framework/tests/test-0000039-req-010-version-bump.sh`
  - `ravintio-framework/component.yml`
  - `product.yml`
  - `docs/about.md`
