# Data contract - ravintio-framework

Last updated: 0000041-pack-source-under-src

`component.yml` declares `ownsData: false`, because the pack has no database. This file records the file-level data that the pack owns, per 0000041 ADR-005.

## Ownership

| Data | Owner | Who writes it |
|---|---|---|
| Every file under `src/ravintio-framework/`, `component.yml` included | `ravintio-framework` | Agents, through **Write** or **Edit** only, under the Write-or-Edit rule (boot Hard Limit 8) |
| The root `ravintio-framework/` copy, `release.yml` included | `build-release.mjs` | The release script only, at P7 Step 5c |
| `.ravintio-framework-build/` and `.ravintio-framework-previous/` | `build-release.mjs` | The release script only, during a build or a recovery |
| A consumer's `ravintio-framework/component.yml` | The consumer | The human on the loop. The 0.39.0 migration only offers the removal. |
| `plan/framework-release.yml` in a repo | That repo | Step 1a, with **Write**, after the human on the loop confirms |
| `src/setup-hook-integration/` | `setup-hook-integration` | Agents, through **Write** or **Edit** |

No agent writes the root copy with **Write** or **Edit**. The design lists the root folder under `## Component Paths`, so `gate-write` would permit it. The rule rests on ADR-005 and on review, not on a gate.

## release.yml format

See `interface-contract.md` for the keys, hash rule, and ordering. The format number is `1`. Invariants:

- Every listed path exists in the root copy, and every root-copy file is listed, except `release.yml` and `component.yml`.
- Paths sort in byte order with no duplicates.
- `source-commit` is the `HEAD` hash at build time. The copy is built from tracked files only.

## plan/framework-release.yml format

A line-based file that holds the release a repo last trusted.

```yaml
version: "0.39.0"
source-commit: "{40 lowercase hex characters}"
```

`release-check.mjs` refuses the file when either value is missing or malformed. A missing file means the repo has no trusted record, and the check compares the version against `docs/about.md`.

## Migration

No schema exists, so no schema migration applies. Format changes ship as a new `format` number and a pack migration.
