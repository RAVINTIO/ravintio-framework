---
title: "Risk Register - 0000041-pack-source-under-src"
summary: "Technical, operational, security, and compliance risks for moving the pack source under src and releasing a root copy with no manifest."
status: "active"
version: "0.1.0"
---
# Risk Register - 0000041-pack-source-under-src

**Skill:** [spec-agent](../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md) (updated by any agent that identifies a new risk)
**Feature:** 0000041-pack-source-under-src
**Version:** 0.39.0
**Overall Risk Level:** high

> Every entry must be specific to this feature. Do not produce generic risks.
> Sources: R-001 to R-005 come from `design.md` Risks. R-006 to R-014 come from a P1 read of the pack code. The design rates R-003 as certain. This register records it as high, the top of its scale.

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | A suite still reads the root copy and passes against the 0.38.0 release. That hides a broken change under `src/ravintio-framework/`. | high | high | The resolver fails a suite that reads the root copy in the source repo, and P4 runs the full suite (req-008). | open |
| R-002 | security | The release script deletes or writes a file outside the root `ravintio-framework/`, for example through a link. | low | high | The script resolves every target and refuses any path outside the root copy and its two work folders (req-002, ADR-003). P5 reviews it. | open |
| R-003 | operational | This run's P7 uses the 0.38.0 ship agent, which lacks the release step. The first `release.yml` then never gets written. | high | medium | P7 runs `src/ravintio-framework/scripts/build-release.mjs` as a recorded decision (req-002). | open |
| R-004 | operational | A consumer copies the new folder over the old one and keeps `ravintio-framework/component.yml`. Its runs still count the pack as source. | high | medium | The 0.39.0 migration offers to remove the file (req-006). Step 1a warns at every session start while the file sits beside `release.yml` (req-003). | open |
| R-005 | operational | The git pass moves 1,184 tracked files. The diff is large enough to hide a real change. | high | medium | The pass is its own commit with no content edits (req-001). Every follow-up edit uses **Edit** in a later commit. | open |
| R-006 | security | `markedRoot` in `hooks/enforcement/path-rules.mjs` takes the nearest folder that holds `ravintio-framework/`. After the move, `src/` holds one. A hook with its `cwd` under `src/` and no `CLAUDE_PROJECT_DIR` then resolves the root to `src/`. `gate-write` and `shell-write-guard` then judge paths against the wrong root. | medium | high | A P1 probe confirmed that the wrong root makes both gates block, so the fault fails closed and widens no write. Claude Code sets `CLAUDE_PROJECT_DIR`, so this run reads the right root. Backlog 0000382 tracks the `markedRoot()` fix, which needs its own design and P5 review. | accepted |
| R-007 | technical | Six suites set `REPO_ROOT` to the parent of the pack folder. After the move, that parent is `src/`. Suites that read `plan/`, `product.yml`, or `.github/` through it then read the wrong folder. | high | medium | The single resolver gives every suite the repo root and the pack source (req-008). A-002 covers suites the resolver can't reach. | open |
| R-008 | technical | `.gitattributes` sets `eol=lf` on `ravintio-framework/hooks/pre-commit` and `ravintio-framework/hooks/pre-push` only. The source copies under `src/ravintio-framework/hooks/` lose that rule. A Windows checkout then writes CRLF and breaks their shebang lines. | medium | medium | req-001 adds `eol=lf` lines for both `src/ravintio-framework/hooks/` scripts and keeps the root lines. Its AC2 checks them. | open |
| R-009 | technical | `release.yml` holds a SHA-256 of each file's bytes. A Windows checkout with CRLF conversion changes those bytes. The root copy integrity check and step 1a's changed-file signal then flag files that did not change. | medium | medium | req-002 hashes each file after CRLF reads as LF, and req-003 and req-008 apply the same rule through `release-check.mjs`. req-002 AC1 checks the CRLF-as-LF hashes. | open |
| R-010 | operational | From P3 to P6, this run's hooks, skills, and `.claude/` install come from the 0.38.0 root copy. Hook and skill changes under `src/ravintio-framework/` reach this run only through suites, never through live sessions. | high | medium | This is the intent of US-001. P4 runs the full suite against `src/ravintio-framework/`. After P7, the release script rebuilds the root copy, and a setup re-run refreshes `.claude/`. | accepted |
| R-011 | technical | `em-dash-guard.mjs` scopes its check to `ravintio-framework/skills/`, `ravintio-framework/templates/`, and `ravintio-framework/standards/` from the root. Edits to `src/ravintio-framework/` prose skip the check. | high | low | req-001 adds the three `src/ravintio-framework/` prefixes to the guard's scope, and its AC2 tests them. The installed 0.38.0 guard still skips these paths for this whole run, so P6 checks pack prose for em dashes. | open |
| R-012 | operational | `skill-drift-check.mjs` compares installed skills with the pack it finds from its own path. In the source repo, the orchestrator runs the root copy, so the check never compares the install with `src/ravintio-framework/skills/`. | high | low | The install comes from the root copy by design (US-001). After each P7 rebuild, the setup re-run brings the install level with the release. | accepted |
| R-013 | operational | A consumer's `product.yml` lists `ravintio-framework/component.yml`, which the 0000040 vendored pack rule allows. After the migration removes the file, `product-version.mjs` exits 2 with `component.yml not found`. | low | medium | req-006 step 3a checks the consumer's `product.yml` before the offer. If it lists the file, the migration records `skipped` with the reason `listed in product.yml`. A-001 covers the same file read outside the pack. | open |
| R-014 | technical | The source-repo signal misreads a repo. A consumer with a `src/ravintio-framework/component.yml` listed in its `product.yml` would read as the framework source and skip downstream migrations. | low | medium | The signal needs both the `product.yml` entry and the file (req-005). Tests cover a consumer, the source repo, and a repo with only one of the two. | open |

## Assumptions Logged as Risks

Documented assumptions from the specification are logged here with likelihood: medium.

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | No consumer reads `ravintio-framework/component.yml` outside the pack. | A consumer script loses its version source after the migration removes the file. | open |
| A-002 | Every suite that names `ravintio-framework/` can read the pack through one resolver. | P3 rewrites more suites by hand, which grows req-008. | open |
