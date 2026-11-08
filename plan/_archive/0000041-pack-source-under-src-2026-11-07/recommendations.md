# Recommendations - pack source under src

**Skill:** [docs-agent](../../ravintio-framework/skills/ravintio-docs-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Version:** 0.39.0

> These are not blockers. They are opportunities for future work.

## Recommendations

| ID | Category | Priority | Component | Recommendation | Rationale | Effort |
|----|----------|----------|-----------|---------------|-----------|--------|
| REC-001 | security | high | ravintio-framework | Move the step 1a trust anchor outside the repo. Backlog 0000416 holds the work. | R-015 stays open. A push that can write the pack can also rewrite `release.yml` and `plan/framework-release.yml`. | large |
| REC-002 | security | high | ravintio-framework | Run migrations only after step 1a confirms the pack. Backlog 0000415 holds the work. | `ravintio-orchestrator/SKILL.md` Resume Detection runs step 1 before step 1a. The migrator then reads and acts on text from an unconfirmed pack. | medium |
| REC-003 | security | medium | ravintio-framework | Make `release-check.mjs --files-only` fail when a trusted release record exists and `release.yml` is gone. Backlog 0000418 holds the work. | The `release-copy-integrity` job in `.github/workflows/ravintio.yml` treats the `skipped:` line as a pass. | small |
| REC-004 | maintainability | high | all | Add a commit-time check that scans each commit diff for changes that skipped Write and Edit. Backlog 0000238 holds the work. See the next section. | P3 and P5 each recorded a Hard Limit 8 breach by a subagent, even though every dispatch prompt repeated the rule. | medium |
| REC-005 | maintainability | medium | ravintio-framework | Run the next ship from the 0.39.0 ship agent, then run setup again. | This run's P7 used the 0.38.0 ship agent and ran `build-release.mjs` as a recorded decision (R-003). The install and `CLAUDE.md` still hold 0.38.0 text (R-010, R-012). | small |
| REC-006 | maintainability | medium | ravintio-framework | Fix `consistency-check.mjs` so it ignores another feature's ADR reference. Backlog 0000252 holds the work. | P1 and P2 wrote `ADR NNN` without the hyphen to avoid false findings. | small |
| REC-007 | testing | low | ravintio-framework | Run the `release-copy-integrity` job on Windows once `release-check.mjs` has a CRLF case there. | The job runs on ubuntu only (ADR-009). R-009 relies on the CRLF-as-LF hash rule, which only unit cases cover on Windows. | small |
| REC-008 | maintainability | low | ravintio-framework | Give Write and Edit a delete route, or name `git rm` in Hard Limit 8. Backlog 0000366 holds the work. | P0 removed six backlog folders with `git rm`, and ship Step 6 deletes files the same way. | small |

### Why a dispatch prompt rule is not enough

Two subagents broke the Write-or-Edit rule (boot Hard Limit 8) in this run.

- **P3:** the req-008 AC3 test-writer ran `sed -i` on `test-0000041-req-008-tests-and-ci-from-src.sh`.
- **P5:** the release-script test-writer changed `test-0000041-req-002-release-script.sh` with a Python one-liner. The change added 105 lines and removed none.

The orchestrator caught both in a diff review before commit. Both breaches also match earlier ones in backlog 0000238, which covers 0000038 and 0000039. Four features now show the same pattern, so the dispatch prompt rule has failed as a control.

`shell-write-guard` cannot stop these writes. It passes `plan/` and anything it can't parse. It also can't see an interpreter one-liner. Three steps would close the gap:

1. Add a commit-time check that fails when a commit diff touches a file that no Write or Edit call recorded. A `PostToolUse` hook on Write and Edit could keep that record.
2. Run `ratchet-check` over the staged diff at commit, so a Bash edit can't skip it.
3. Give test-writer and implementer subagents a tool list with no Bash access to files. They need Bash only to run a suite, so a narrow `node` and `bash` run allowlist would do.

Backlog 0000238 holds step 1 and step 2. Step 3 is new evidence for the same entry and files no new item. Add this run's two breaches to 0000238 at the next P0 that picks it up.

## Deferred Items

The scope for this feature defers nothing (`plan/current/scope.md`). These rows come from items the run found and chose to leave.

| Scope Item | Recommendation | When to Address |
|-----------|---------------|-----------------|
| Skill drift notice for `src/ravintio-framework/skills/` against the install (R-012). Backlog 0000422. | Add a source-repo mode to `skill-drift-check.mjs` that prints a notice, not a failure. | When a maintainer misses a stale install after a skill change. |
| Migration branch diff across the pack move. Backlog 0000402. | Make the 0000037 req-008 diff read the pack at `src/ravintio-framework/` against the right tag path. | Before the next unreleased re-run-setup migration. |
| Migrations run before step 1a confirms the pack. Backlog 0000415. | Reorder Resume Detection so step 1a runs first. | At the next change to `ravintio-orchestrator/SKILL.md`. |
| Trust anchor outside the repo (R-015). Backlog 0000416. | Design a signed or externally held release record. | Before the framework is distributed to more than one trusted team. |
| `release-copy-integrity` passes when `release.yml` is deleted. Backlog 0000418. | Fail `--files-only` when a release record exists and `release.yml` is gone. | After this repo's first 0.39.0 release. |

## Tech Debt

| ID | Component | Description | Impact if Ignored | Suggested Fix |
|----|-----------|-------------|-------------------|--------------|
| TD-001 | ravintio-framework | `build-release.mjs` clears `GIT_CONFIG_COUNT` and `GIT_CONFIG_PARAMETERS` but not `GIT_CONFIG_GLOBAL` or `GIT_CONFIG_SYSTEM` (NF-01). Backlog 0000419. | A clean filter in the user's global git config runs during the build. | Point both variables at the null device for every git call, and add the cases to the req-002 suite. |
| TD-002 | ravintio-framework | `build-release.mjs` checks then acts on folders, so a same-user writer can swap a folder for a link between the two (RS-F02, RS-F03). Backlog 0000420. | Writes and deletes land outside the root copy under a concurrent writer. | Compare device and inode before each write and delete, or use a tool with `openat`. |
| TD-003 | ravintio-framework | `release-check.mjs` prints pack file names in `unlisted:` lines, and `clean()` does not strip instruction-shaped words (RC-F06). Backlog 0000421. | A crafted file name reaches the agent as text. | Print the names inside a data block, or show only a count and an allowlisted sample. |
| TD-004 | ravintio-framework | `build-release.mjs` reads source bytes from the working tree (RS-F04, RS-F05). Backlog 0000417. | `git update-index --assume-unchanged` hides an edit, and the copy ships bytes that the named `source-commit` doesn't hold. | Read each file from `HEAD` through `git cat-file --batch`. |
| TD-005 | ravintio-framework | The step 1a record, checker, and source-repo signal all sit in the repo they protect (RC-F01, RC-F03 to RC-F05, RC-F07). Backlog 0000416. | Step 1a reports no update after a deliberate push that rewrites the record. | Hold the trust anchor outside the repo. |
