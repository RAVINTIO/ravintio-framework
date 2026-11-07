# Interface contract - ravintio-framework

Last updated: 0000041-pack-source-under-src

The pack exposes hooks, setup commands, and scripts. This file records the interfaces that feature 0000041 added or changed. Earlier interfaces live in `src/setup-hook-integration/docs/interface-contract.md` and in the component manifest.

## release.yml

The release script writes `ravintio-framework/release.yml`. Readers parse it line by line. Keys come in a fixed order.

| Key | Value |
|---|---|
| `format` | The whole number `1`. A reader refuses any other value. |
| `version` | The version from `src/ravintio-framework/component.yml`. |
| `source-commit` | The 40-character lowercase hash of `HEAD` at build time. |
| `built` | The UTC build date as `YYYY-MM-DD`. |
| `files` | One `"{path}": "{sha256}"` line per root-copy file, in byte order. |

Each hash is the SHA-256 of the file after each CRLF pair reads as LF, in lowercase hex. The list excludes `release.yml` and `component.yml`. The file must end with a line feed. A path segment must match `[A-Za-z0-9._-]+`.

## build-release.mjs

Run `node ravintio-framework/scripts/build-release.mjs` from the source repo root. The script takes no arguments. It runs only when `project-kind.mjs` reports `framework source`.

| Exit code | Meaning |
|---|---|
| 0 | The new copy is in place. |
| 1 | A file-system or git failure. The old copy stays whole, and stderr names the operation. |
| 2 | A refusal. Nothing is written, and stderr gives the reason. |

Output on stdout:

- `added:`, `changed:`, or `removed:` followed by `ravintio-framework/{path}`, one line per differing file.
- `restored: ravintio-framework/ from an interrupted build`, when recovery restores the old copy.
- `summary: version {v}, source-commit {sha}, added {n}, changed {n}, removed {n}, unchanged {n}`.

The script refuses arguments, a dirty pack source, tracked links, a tracked `release.yml`, case-only path collisions, and any boundary folder that is a link. It also refuses a run where the working folder, the root, and the git top level are not one real path.

## release-check.mjs

Run `node ravintio-framework/scripts/release-check.mjs [--root <dir>] [--files-only]`. The script is read-only. Step 1a writes `plan/framework-release.yml` with **Write**.

| Exit code | Meaning |
|---|---|
| 0 | Nothing to confirm. |
| 1 | A candidate update: `update: release`, or any file line. |
| 2 | The check could not run. stderr gives the reason, and no reader falls back. |

Output lines on stdout:

| Line | Meaning |
|---|---|
| `release: version "{v}" source-commit "{sha}"` | Read from `release.yml`. |
| `release: none, fallback component.yml version "{v}"` | No `release.yml` and no trusted record. |
| `release: none` | No `release.yml` and a trusted record. The script then prints `missing:` and `update: release`, and exits 1. |
| `recorded: ...` | The last trusted release, or `none`, or the `docs/about.md` fallback. |
| `update: release`, `update: own-build`, `update: none` | The decision. `own-build` applies only in the framework source. |
| `record: version "{v}" source-commit "{sha}"` | The value for step 1a to write after confirmation. |
| `changed:`, `missing:`, `unlisted:` | One line per pack file that differs from `release.yml`. |
| `files: not checked, no release.yml` | No hashes to compare. |
| `warn: ravintio-framework/component.yml sits beside release.yml` | A leftover manifest. |
| `skipped: no ravintio-framework/release.yml` | `--files-only` with no `release.yml`. |

The fallback to the `component.yml` version applies only when no trusted release record exists (P5 fix RC-F02).

## project-kind.mjs

Run `node ravintio-framework/scripts/project-kind.mjs [--root <dir>]`. It prints `framework source` or `downstream` on stdout and the reason on stderr. A repo is the framework source when `product.yml` is a regular file that lists the component `ravintio-framework` at `src/ravintio-framework/component.yml`, and that file exists with no link in its path. Every other case, including a malformed `product.yml`, prints `downstream`.

| Exit code | Meaning |
|---|---|
| 0 | A kind was printed. |
| 2 | Bad argument. |

## Applies to header

A migration may carry one `**Applies to:**` line beside `**Target:**`.

| Value | Meaning |
|---|---|
| `framework source` | The migrator applies it only in the framework source. |
| `downstream` | The migrator applies it only in a consumer repo. |
| `all` | Applies everywhere. An absent line reads as `all`. |

When the value and the project kind differ, the migrator records `not applicable` with the reason. A table in the migrator skill maps released headerless files. `retroactive-release-tags.md` maps to `framework source`. Released migration files never change.

## 0.39.0 migration

`migrations/migrate-0.39.0-remove-pack-component-yml.md` has `**Applies to:** downstream`. It offers to remove `ravintio-framework/component.yml` when it sits beside `release.yml`. The human on the loop runs the delete, and the migrator checks the result.

## Breaking change policy

A change to the `release.yml` format needs an ADR and a new `format` number. A change to a script's exit codes or output lines needs an ADR, because step 1a and the CI integrity job parse them.
