# Verify-by-Execution Report
**Toggle:** report-only
**Software exercised:** the pack scripts under `src/ravintio-framework/scripts/` (`project-kind.mjs`, `build-release.mjs`, `release-check.mjs`, `product-version.mjs`) and the version suite. Each ran on this repo read-only, or in scratch git repos made with `mktemp -d` under `/tmp`. `build-release.mjs` ran only in the scratch source repo `/tmp/vbe-src.DYMe`, never on this repo. The migrator Step 1b rule and the 0.39.0 migration steps were walked by hand against the real files, with each check run as a shell command.

| Requirement | Criterion | Method | Outcome | Observation evidence |
|-------------|-----------|--------|---------|---------------------|
| REQ-005 | AC3: the Step 1b rule records the right outcome for each migration in a source repo and a consumer repo. Released migrations match `v0.38.0` byte for byte. Existing records in `plan/_migrations/` are unchanged. | cli + side effects | verified | See the REQ-005 notes below. `project-kind.mjs` prints `framework source` here and in a scratch source layout, and `downstream` in scratch consumer layouts, each with exit 0. A bad argument exits 2. All 17 released migration files compare `same` with `v0.38.0`. `git diff --stat main -- plan/_migrations/` shows only the new 0.39.0 record. |
| REQ-006 | AC2: in scratch consumer repos built from a `build-release.mjs` copy, the 0.39.0 migration behaves as stated for each scenario. | cli + side effects | verified | See the REQ-006 notes below. Confirm ran the real `rm`, the file went, the record read `applied` 1/0, and only that file changed. Decline, listed, no leftover, no `release.yml`, older `release.yml`, and malformed `release.yml` each behaved as the criterion states. `release-check.mjs` printed `warn: ravintio-framework/component.yml sits beside release.yml` before removal and no warning after. |
| REQ-007 | AC3: the version suite exits 0 on this repo during the run, and the `1.0.0` scan has no hit under `ravintio-framework/`. | cli | verified | This repo: three `SKIP (open run):` lines, `Results: 6 passed, 0 failed`, exit 0. The `git grep` with the suite's pathspecs gave 0 hits under `ravintio-framework/`. Scratch released tree: a mismatch gave three FAIL lines and exit 1. Equal versions gave `9 passed, 0 failed`, no SKIP line, and exit 0. |
| End to end | `release-check.mjs --root . --files-only` on this repo | cli | verified | `skipped: no ravintio-framework/release.yml`, exit 0 |
| End to end | `release-check.mjs --root .` on this repo | cli | verified | See the output below. Exit 0. |
| End to end | the `release-copy-integrity` run block from `.github/workflows/ravintio.yml` on this repo | cli | verified | `::notice title=Release copy integrity::Skipped. The root copy has no release.yml, so it is a release from before 0.39.0.`, exit 0 |

## REQ-005 notes

### project-kind.mjs runs

| Root | stdout | stderr reason | Exit |
|------|--------|---------------|------|
| this repo | `framework source` | `product.yml and src/ravintio-framework/component.yml meet the source-repo signal` | 0 |
| scratch source layout | `framework source` | same as above | 0 |
| scratch consumer, `product.yml` with app only | `downstream` | `product.yml has no ravintio-framework entry with path src/ravintio-framework/component.yml` | 0 |
| scratch consumer, `product.yml` lists `ravintio-framework/component.yml` | `downstream` | same as above | 0 |
| scratch folder with no `product.yml` | `downstream` | `no product.yml at /tmp/vbe-pk.c4tF/empty` | 0 |
| `--bogus` | none | `project-kind: bad argument: --bogus` and the usage line | 2 |

### Step 1b walked by hand

The rule is at `src/ravintio-framework/skills/ravintio-migrator/SKILL.md`, Step 1b and the table above it.

| Migration | Header or table value | Source repo (kind `framework source`) | Consumer (kind `downstream`) |
|-----------|----------------------|---------------------------------------|------------------------------|
| `migrate-0.39.0-remove-pack-component-yml.md` | header `downstream` | Step 1b.3 gives `not applicable`, counts 0 | Step 1b passes. The Target line names a downstream project, and the kind agrees, so Step 1c follows. |
| `retroactive-release-tags.md` | no header, table `framework source` | Step 1b passes. The file has no Target line, so Step 2 follows. | Step 1b.3 gives `not applicable`, counts 0 |
| `0001-date-format.md` | no header, not in the table, reads as `all` | passes, no Target line | passes, no Target line |
| `migrate-0.38.0-retire-fast-path-and-change-pipeline.md` | no header, reads as `all` | passes. The Target names every project. | passes |

This repo's record `plan/_migrations/migrate-0.39.0-remove-pack-component-yml.md` holds `outcome: "not applicable"` with both counts at `0`. Its body reads: "This project is the framework source, so the migration for a downstream project's leftover pack manifest does not apply." That matches the source-repo row above. The existing record `plan/_migrations/retroactive-release-tags.md` is unchanged from `main`.

The root release copy is the frozen `v0.38.0` and has no `scripts/project-kind.mjs`. The design expects that until P7, and this run follows the migrator text under `src/ravintio-framework/`.

## REQ-006 notes

The scratch source repo `/tmp/vbe-src.DYMe` held `git archive HEAD src/ravintio-framework product.yml`. `node src/ravintio-framework/scripts/build-release.mjs` printed `summary: version 0.39.0, source-commit 8bfb1b535d683aa4e4695a36c20ad191b85632d6, added 1197, changed 0, removed 0, unchanged 0` and exited 0. The copy held `release.yml` (`format: 1`, `version: "0.39.0"`) and no `component.yml`.

Each consumer under `/tmp/vbe-cons.Znfk/` held that copy as `ravintio-framework/`. Each also held the `v0.38.0` `ravintio-framework/component.yml` as the leftover, a `product.yml`, and a `docs/about.md` at 0.38.0. A SHA-256 snapshot of every file outside `plan/_migrations/` ran before and after each walk. `project-kind.mjs` printed `downstream` in every consumer, so Step 1b passed with the header `**Applies to:** downstream`.

| Scenario | Steps taken | Files changed | Record |
|----------|-------------|---------------|--------|
| leftover, removal confirmed | 1 ok (0.39.0), 4 found version `"0.38.0"`, 5 ran `rm -- ravintio-framework/component.yml` (exit 0), 6 path gone | only `./ravintio-framework/component.yml` removed. `product.yml` byte-identical. | `applied`, `corrections-applied: 1`, `corrections-skipped: 0` |
| leftover, declined | 1 ok, 4 found, 7 declined | none | `skipped`, 0/1, body names `ravintio-framework/component.yml` and `declined` |
| `product.yml` lists the file | 1 ok, 3a, no `rm` shown | none. `product.yml` byte-identical. | `skipped`, 0/1, body names the file and `listed in product.yml` |
| no leftover | 1 ok, 2 | none | `applied`, 0/0 |
| no `release.yml` | 1 stop | none | none |
| `release.yml` at 0.38.0 | 1 stop, version older than 0.39.0 | none | none |
| malformed `release.yml` | 1 stop, format broken | none | none |

`release-check.mjs --root .` in each consumer:

- Before removal, with a leftover beside `release.yml`, it printed `warn: ravintio-framework/component.yml sits beside release.yml`.
- After the confirmed removal, it printed no `warn:` line.
- After decline and in the listed case, the warning stayed.
- On the malformed file it printed `release-check: ravintio-framework/release.yml breaks the format: expected format at line 1` and exited 2.

Each run with a record also printed `update: release` and exited 1. That exit is expected, because the scratch repos have no `plan/framework-release.yml`.

Second run: every scenario that wrote a record has `plan/_migrations/{stem}.md` in place. The pending rule (migrator `SKILL.md` line 48) then treats the migration as not pending, so nothing runs. A second snapshot showed no file change and an unchanged record. The scenarios with no record changed no file, and they stay pending.

## End-to-end output on this repo

```
$ node src/ravintio-framework/scripts/release-check.mjs --root . --files-only
skipped: no ravintio-framework/release.yml
exit=0
```

```
$ node src/ravintio-framework/scripts/release-check.mjs --root .
release: none, fallback component.yml version "0.38.0"
recorded: none, fallback docs/about.md version "0.38.0"
files: not checked, no release.yml
update: none
exit=0
```

```
$ (release-copy-integrity run block from .github/workflows/ravintio.yml)
::notice title=Release copy integrity::Skipped. The root copy has no release.yml, so it is a release from before 0.39.0.
exit=0
```

```
$ bash src/ravintio-framework/tests/test-0000039-req-010-version-bump.sh   (this repo)
SKIP (open run): product.yml version reads 0.39.0. plan/current/design.md exists, so P7 has not set product.yml and docs/about.md yet. The check runs on a released tree.
SKIP (open run): docs/about.md frontmatter version reads 0.39.0. ...
SKIP (open run): docs/about.md table Version cell reads 0.39.0. ...
Results: 6 passed, 0 failed
exit=0
```

The scratch released tree `/tmp/vbe-rel2.HyJn` held `git archive HEAD src product.yml docs/about.md` and no `plan/current/design.md`:

- Mismatch (component 0.39.0, the others 0.38.0): FAIL for `product.yml version`, `docs/about.md frontmatter version`, and `docs/about.md table Version cell`. `Results: 6 passed, 3 failed`, exit 1.
- All four at 0.39.0: `Results: 9 passed, 0 failed`, no SKIP line, exit 0.
- With `plan/current/design.md` added back and the mismatch restored: three SKIP lines, `Results: 6 passed, 0 failed`, exit 0.

A first scratch tree held only `src/ravintio-framework`. Its `product-version.mjs` exited 2 with `component setup-hook-integration: component.yml not found`, because `product.yml` lists a second component. That was a fixture gap in this check and not a defect, so the tree above includes all of `src/`.
