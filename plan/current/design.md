# Design - 0000042-fix-windows-shards-pr-77

## Feature
- Problem: two 0000041 test suites fail on the Windows CI shards of PR #77, so the maintainer can't merge release 0.39.0.
- Adoption mode: standard-iterative (signal: `plan/_archive/` holds 41 feature folders, and `docs/about.md` exists)
- Feature ID: 0000042-fix-windows-shards-pr-77
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As a framework maintainer, I see both 0000041 suites pass on the Windows CI shards, so that I can merge PR #77.
- Acceptance criteria confirmed: 3 (from `feature-brief.md`)
- Constraints:
  - Released migration files never change.
  - A Windows skip prints one `SKIP (windows): {reason}` line.
  - Linux and macOS keep every case they run today.
- Integrations: GitHub Actions runs the suites through `src/ravintio-framework/tests/run-tests.sh`.

## Architecture Layer
- Latency target: not applicable (no service)
- Availability target: not applicable (no service)
- Scalability target: not applicable (test-only change)
- Security: no auth. The change touches test code only. Scratch folders stay under `mktemp -d`, and the `EXIT` trap still removes them.
- Data privacy: no regulated data
- Observability: each skipped case prints `SKIP (windows): {reason}`.
- Cost boundary: not constrained

## Engineering Layer
- Stack: unchanged. Bash suites under `run-tests.sh`, Node.js `.mjs` scripts, GitHub Actions CI. Build target: local.
- Components:
  - `ravintio-framework` (component-pack): owns both suites and `tests/README.md` under `src/ravintio-framework/tests/`.
- Data ownership:
  - `ravintio-framework` owns every file under `src/ravintio-framework/`.
  - The release script owns the root `ravintio-framework/` copy. No agent writes it with **Write** or **Edit**.
- Deployment: P7 runs the release script, which rebuilds the root copy from `src/`.
- API versioning: not applicable
- req-005 suite fixes (backlog 0000426):
  - `IS_WIN` comes from `uname -s`, as in the 0000035 suites.
  - On Windows, `WORK` holds the `pwd -W` form of the scratch folder, so Node reads a Windows path inside `-e` scripts.
  - The four linked-path cases print one `SKIP (windows)` line on Windows, because Git Bash `ln -s` makes a copy.
  - The two `projectKind(root)` cases import `project-kind.mjs` through `pathToFileURL(...).href`.
  - The released-migration check compares git blob ids, not working-tree bytes. A CRLF checkout then can't fail it.
- req-006 suite fix: Case 6, the linked `ravintio-framework/`, prints one `SKIP (windows)` line on Windows.
- README: `tests/README.md` gains one Windows skip row per suite, in the table's existing format.
- Version: last known `0.39.0`, and `v0.39.0` is already on `origin`. Suggested `0.39.1`, a patch bump, because the change fixes tests and adds no feature. The `ravintio-framework` manifest under `src/` carries the bump.

## Component Paths
- `src/ravintio-framework/`
- `ravintio-framework/`
- `./product.yml`

## Scope
- In:
  - the req-005 suite fixes above
  - the req-006 Case 6 skip
  - two `tests/README.md` skip rows
  - the 0.39.1 version and the P7 release copy rebuild
- Out:
  - `project-kind.mjs` and the migrator, which have no Windows fault
  - the ship sequence and `gate-write` change in backlog 0000426
  - backlog 0000425, the credential-scan false positive on `release.yml`
- Deferred: nothing deferred. Backlog 0000426 stays open for its ship and gate change.
- Release size: `three-story rule`. One story, so it fits.
- Backlog: pull in 0000426 for its planned edits only, and leave the folder open. Leave the other 249 entries untouched.

## Assumptions
- Git Bash `ln -s` makes a copy - impact if wrong: the link cases could run on Windows, and the skip hides coverage that Windows could give.
- Checkout converts LF to CRLF on the Windows runner - impact if wrong: the blob compare still passes, but the byte compare failed for another reason that needs a look.
- Node reads `/tmp/...` inside an `-e` string as `C:\tmp\...` - impact if wrong: the `pwd -W` change does nothing, and the import cases still fail.

## Risks
- A skip hides a real Windows defect in `project-kind.mjs` link handling. Likelihood low, impact medium. Linux and macOS still run every link case.
- The P7 credential scan holds back the new `release.yml` again, as in 0000041. Likelihood high, impact low. The `release-copy-integrity` job passes with its skip notice.
- The P9 CI check finds a third failure after the archive, and `gate-write` blocks the fix again (backlog 0000426). Likelihood low, impact high. P4 runs the Windows-sensitive cases' logic on macOS only, so the PR checks are the final proof.

## Dependencies
- Upstream: PR #77 and run `42409694287` on GitHub Actions
- Downstream: the maintainer's merge of PR #77

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - windows-safe-0000041-suites | ravintio-codegen-agent | test-only edits through the TDD loop, where the red step is the Windows CI failure |

## Repo Instructions
Five files in `ravintio-overrides/instructions/`, read at P0.
- `custom-001-local-git-only.md`: fetch, pull, push, and `gh pr create` need no prompt. Work on a `feat/` branch. Committing to `main` and merging PRs stay human-only. Commit after every meaningful artifact write.
- `custom-002-prefer-subagent-decomposition.md`: split long or multi-unit work into parallel subagents, above the size floor.
- `custom-003-git-up-to-date-shorthand.md`: `GUTD` means check out `main`, pull, list untracked files, and report the last merged PR's checks.
- `custom-004-file-backlog-entries-immediately.md`: file out-of-scope problems as backlog entries at once, then commit and push them.
- `custom-005-p9-push-and-raise-pr.md`: at P9, push and raise the PR without asking. Never merge. PR #77 already exists, so P9 pushes the branch and the tag, and it updates PR #77 instead of raising a new one.

## Confirmation
Human confirmed this design before proceeding: no // Date and Time confirmed: pending
