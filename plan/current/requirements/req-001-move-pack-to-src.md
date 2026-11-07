---
title: "Requirement: req-001 - move-pack-to-src"
summary: "One approved git pass moves the pack source to src/ravintio-framework/ and restores the root copy from v0.38.0. Follow-up Edit changes point the repo's own files at the new source path."
status: "draft"
version: "0.1.0"
---
# Requirement: req-001 - move-pack-to-src

**Skill:** [spec-agent](../../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Source:** US-001
**Priority:** must-have

## User Story

As a framework maintainer, I change the pack under `src/ravintio-framework/` while this repo runs on the last release at the root, so that a broken change can't break the run that builds it.

## Functional Requirements

### The git pass (one commit, approved at P0)

- Before the pass, confirm that `git tag -l v0.38.0` prints `v0.38.0`. The P1 check found the annotated tag at commit `2595f850`. `git diff --stat v0.38.0 HEAD -- ravintio-framework` printed nothing, so the root pack matches the tag today.
- Run these two commands in this order, then commit the result as one commit:
  1. `git mv ravintio-framework src/ravintio-framework`
  2. `git checkout v0.38.0 -- ravintio-framework`
- The pass commit holds no content edit. It adds the files under `src/ravintio-framework/` and leaves the root `ravintio-framework/` byte-identical to `v0.38.0`, `component.yml` included.
- The pass is the recorded exception to the Write-or-Edit rule (boot Hard Limit 8), as 0000039 ADR 008 was. The build log records the two commands and the commit hash.
- The commit subject follows `ravintio-framework/standards/commit-standards.md`. It stays under 72 characters.
- P3 runs the AC1 checks right after the commit, before any follow-up edit, and logs their output in the build log.

### Follow-up path fixes (Edit only, after the pass commit)

Each fix below is its own Edit. The rule for every file: a path that says where the pack source lives in this repo moves to `src/ravintio-framework/`. A path that says what setup or a hook reads in an installed repo stays `ravintio-framework/`, because that is the consumer runtime path.

- `product.yml`: the `ravintio-framework` component entry changes its `path:` to `src/ravintio-framework/component.yml`. The header comment that names `node ravintio-framework/scripts/product-version.mjs` stays, because the root copy holds that script.
- `.gitattributes`: add `src/ravintio-framework/hooks/pre-commit text eol=lf` and `src/ravintio-framework/hooks/pre-push text eol=lf`. Keep both root lines, because the root copy ships the hooks that `core.hooksPath` runs.
- `src/ravintio-framework/hooks/enforcement/em-dash-guard.mjs`: the scope list gains `src/ravintio-framework/skills/`, `src/ravintio-framework/templates/`, and `src/ravintio-framework/standards/`. The three root prefixes stay, because consumers edit their copy at that path. The header comment names both sets. Without the change, pack prose edits after the move skip the guard (risk R-011).
- `src/setup-hook-integration/component.yml`:
  - `scope.inScope` names the setup code by its source path: `src/ravintio-framework/setup.sh and setup.ps1 hook installation and settings.json merge`, and `src/ravintio-framework/setup/claude-code.sh and setup/claude-code.ps1 hook path declarations`.
  - `systemContext` gains one sentence: the code lives in `src/ravintio-framework/`, and consumers run it from the `ravintio-framework/` release copy.
  - Every other line stays. Lines that describe runtime behaviour, such as `.claude/hooks/enforcement/`, already name no pack path.
- `src/setup-hook-integration/docs/`:

| File | Line today | Change |
|------|-----------|--------|
| `dependencies.md` | rows 7 and 9 to 14, Source column `Framework source` | each path becomes `src/ravintio-framework/...` |
| `scope.md` | lines 5 to 10, the In Scope list | `setup.sh`, `setup.ps1`, and `setup/` gain the `src/ravintio-framework/` prefix, and the four `ravintio-framework/` items move to `src/ravintio-framework/` |
| `purpose.md` | line 5, "framework source (in `ravintio-framework/`)" | names `src/ravintio-framework/` as the source and `ravintio-framework/` as the copy setup runs from |
| `purpose.md` | lines 10 and 12 | stay, runtime paths |
| `tech-debt.md` | each `**File:**` line that names `ravintio-framework/` | becomes `src/ravintio-framework/...` |
| `test-coverage.md` | lines 8 and 18, `ravintio-framework/tests/` | becomes `src/ravintio-framework/tests/` |
| `quirks.md` | line 23, the skip table in `ravintio-framework/tests/README.md` | becomes `src/ravintio-framework/tests/README.md` |
| `quirks.md` | lines 27 and 37 | stay, they name an install command and installed hooks |
| `interface-contract.md` | lines 22, 24, and 25 | stay, runtime outputs |
| `interface-contract.md` | line 69 | stays, it quotes the `ENFORCEMENT_PATHS` constant in `path-rules.mjs` |
| `interface-contract.md` | line 84 | stays, the 0.37.0 history note |
| `data-contract.md` | line 9 skill link | stays, the root copy holds the linked skill |

- `docs/component-registry.md` line 13: the manifest link becomes `[component.yml](../src/ravintio-framework/component.yml)`. The "Last updated" history text stays.
- `refresh-ravintio-framework-dir.ps1`:
  - `$repoDir` becomes `$PSScriptRoot`, in place of the hard-coded `C:\d\planifest\framework\` path.
  - The comment "Refresh Framework - not required as this IS the framework" becomes a comment that names the root `ravintio-framework/` as the release copy. P7 rebuilds it from `src/ravintio-framework/`.
  - The setup call stays `.\ravintio-framework\setup.ps1 claude-code --include-full-skill-library`, so `.claude/` installs from the release.
- `README.md`, `## Repository structure` block:
  - The `ravintio-framework/` line says it is the release copy, built from `src/ravintio-framework/` at P7, and that nobody edits it by hand.
  - Under `src/`, add the nested line `│   └── ravintio-framework/ ← Pack source (this repo only)`. `self-description-check.mjs` then checks that `src/ravintio-framework/` exists.
  - The framework table and the setup commands keep their `ravintio-framework/` links, because consumers copy and run the root folder.
- `.claude/` and `CLAUDE.md` get no edit. Both are setup output that `.gitignore` excludes. `.claude/` keeps its install from the root release copy, which US-001 needs.
- Out of this requirement:
  - req-002 owns the release script and the Hard Limit 8 text in `src/ravintio-framework/templates/standard-boot.md`.
  - req-004 owns the codegen, ship, spec, and docs skill text and `component-guide.md`.
  - req-008 owns `.github/workflows/ravintio.yml`, every suite, `tests/README.md`, and `self-description-check.mjs`.
- Add `src/ravintio-framework/tests/test-0000041-req-001-move-pack-to-src.sh` for AC2 and AC3. It reads the repo through the req-008 resolver.
- Split step: keep. The pass and its path fixes form one outcome, the pack source at its new path, and neither ships alone without a broken tree.

## Acceptance Criteria
- [ ] The pass commit touches only paths under `src/ravintio-framework/`. `git rev-parse {pass}:src/ravintio-framework` equals `git rev-parse v0.38.0:ravintio-framework`. `git diff --quiet v0.38.0 HEAD -- ravintio-framework` exits 0 at the pass and again at the end of P3. Verified by: execution
  - Verified by: execution - P3 runs the three git checks after the pass and at the P3 close-out, and logs the output. A squash merge drops the pass commit, so no durable suite can find it.
- [ ] `product.yml` lists `ravintio-framework` at `src/ravintio-framework/component.yml`, and that file exists. Run at the repo root, `node src/ravintio-framework/scripts/product-version.mjs` exits 0 and prints the higher of the two component versions. `.gitattributes` holds `eol=lf` lines for both `src/ravintio-framework/hooks/` scripts. The `src/` copy of `em-dash-guard.mjs` blocks a U+2014 write to `src/ravintio-framework/skills/` and still blocks one to `ravintio-framework/skills/`. Verified by: unit
- [ ] The setup-hook-integration manifest and docs name `src/ravintio-framework/` for each source path in the table above, and keep each runtime path. `docs/component-registry.md` links the `src/` manifest. `refresh-ravintio-framework-dir.ps1` uses `$PSScriptRoot` and runs the root setup. The README structure block names `src/ravintio-framework/`, and `self-description-check.mjs` exits 0. Verified by: unit

## Dependencies
- req-008 (tests-and-ci-from-src) provides the resolver `src/ravintio-framework/tests/helpers/pack-root.sh` that the new suite sources.
- req-008 changes `self-description-check.mjs` to read the pack from `src/` in the source repo. AC3 runs that version.
- P3 runs the pass first. Every other requirement edits files under `src/ravintio-framework/` and so waits for the pass commit.
