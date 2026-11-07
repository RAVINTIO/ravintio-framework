# Design - 0000041-pack-source-under-src

## Feature
- Problem: consumers copy `ravintio-framework/` with its `component.yml`, so consumer runs count the pack as their own source, bump it, and can tag from it.
- Adoption mode: standard-iterative (signal: `plan/_archive/` holds 40 feature folders, and `docs/about.md` exists)
- Feature ID: 0000041-pack-source-under-src
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As a framework maintainer, I change the pack under `src/ravintio-framework/` while this repo runs on the last release at the root, so that a broken change can't break the run that builds it.
  - US-002: As a consumer repo owner, I install a pack that has `release.yml` and no `component.yml`, so that my runs never count the pack as my source and still detect each pack update.
  - US-003: As a framework maintainer, I see migrations declare which kind of project they apply to, so that the source repo skips consumer-only migrations and consumers skip source-only ones.
- Acceptance criteria confirmed: 5 (from `feature-brief.md`). P1 added two more for req-004 and req-006, so the brief holds 7 (P1 deviation). P1 expands them to about 3 per story.
- Constraints:
  - Released migration files never change.
  - `ravintio-framework/` stays the consumer runtime path in every pack file.
  - History under `plan/_archive/` and `plan/changelog/` stays as written.
  - `gate-write` and `shell-write-guard` stay in parity.
- Integrations: none outside the pack. Consumers receive the change through a pack copy, setup, and the new migration.

## Architecture Layer
- Latency target: not applicable (no service)
- Availability target: not applicable (no service)
- Scalability target: the release script builds the full pack, about 1,200 files, in under 30 seconds on a CI runner.
- Security: no auth. The release script writes and deletes files only inside the root `ravintio-framework/` and its two work folders, `.ravintio-framework-build/` and `.ravintio-framework-previous/`. It refuses any path outside those three, including through a link (P1 deviation, req-002). The consumer migration removes `ravintio-framework/component.yml` only after the human on the loop confirms. Data classification: public source code.
- Data privacy: no regulated data
- Observability: the release script prints each file it adds, changes, or removes, and a summary line. The migrator reports each `not applicable` record and its reason.
- Cost boundary: not constrained

## Engineering Layer
- Stack: unchanged. Bash and PowerShell setup, Node.js `.mjs` hooks and scripts, Bash suites under `run-tests.sh`, GitHub Actions CI. Build target: local.
- Components:
  - `ravintio-framework` (component-pack): moves to `src/ravintio-framework/`, with its `component.yml`.
  - `setup-hook-integration` (component-pack): its manifest and docs stay at `src/setup-hook-integration/`. Its code paths now point into `src/ravintio-framework/`.
- Data ownership:
  - `ravintio-framework` owns every file under `src/ravintio-framework/`.
  - The release script owns the root `ravintio-framework/` copy. No agent writes it with **Write** or **Edit**.
  - Consumers own their copy of `ravintio-framework/component.yml`, and the migration removes it only on confirmation.
- Deployment: P7 runs the release script, which rebuilds the root copy. Consumers copy the root folder as today.
- API versioning: not applicable. `release.yml` is a new file contract, and the version bump records it.
- Move (P3, one git pass, approved at P0): one commit runs `git mv ravintio-framework src/ravintio-framework`, then `git checkout v0.38.0 -- ravintio-framework`. The root copy then matches `v0.38.0`, and this run keeps using it. The pass is a recorded exception to the Write-or-Edit rule (boot Hard Limit 8), like 0000039 ADR 008. Every follow-up content edit uses **Edit**.
- Release script: a new `scripts/build-release.mjs` in the pack. It copies `src/ravintio-framework/` to the root `ravintio-framework/` without `component.yml`. It removes root files that `src/` no longer holds. It writes `release.yml` with `version`, `source-commit`, `built`, and a SHA-256 for each file. It builds into a temporary folder beside the root copy, then swaps the folders, so an interrupted build leaves the old copy whole. A rerun rebuilds the whole copy. The Write-or-Edit rule (boot Hard Limit 8) names it as a sanctioned script, with the arguments its ship step shows. It runs only in the source repo.
- Ship (P7): a new step after Step 5b runs the release script in the source repo. This run's ship agent is the 0.38.0 copy, which lacks the step. This run's P7 therefore runs the script from `src/` as a recorded decision.
- Readers: orchestrator step 1a, `standards/framework-update-policy.md`, and the migrator read `ravintio-framework/release.yml` first. They fall back to `ravintio-framework/component.yml` for a pack before 0.39.0.
- Update detection (0000181): step 1a has two signals, and the policy states both.
  - A new `source-commit` or `version` in `release.yml`, against the value the repo last recorded, is a release update. A first upgrade has no recorded value, so it compares the version only.
  - A pack file that differs from its `release.yml` hash is a changed file. It counts as an update even when the version is unchanged, and step 1a names each file.
- Leftover manifest: while `ravintio-framework/component.yml` sits beside `release.yml`, step 1a warns at every session start, even after the migration records `skipped`.
- Codegen and ship (0000061, 0000361): the codegen close-out bumps the manifest of each component the run changed, read from `## Component Paths` and `product.yml`. It takes the component list from the Engineering Layer Components list, each manifest from `product.yml`, and the changed files from `## Component Paths` (P1 wording, req-004). It never names `ravintio-framework/component.yml`. The ship fallback with no `product.yml` reads the single component from the design.
- Manifest rule (0000061): a component manifest lives at the path `product.yml` lists, and `src/{component-id}/` is the default. `spec-agent`, `docs-agent`, and `component-guide.md` state one rule.
- Source-repo signal (0000378, 0000136): a repo is the framework source when `product.yml` lists the component `ravintio-framework` at `src/ravintio-framework/component.yml` and that file exists.
- Migration header (0000136, 0000378): a migration may carry `**Applies to:**` with `framework source`, `downstream`, or `all`. An absent line reads as `all`, so released migrations keep their behaviour. The migrator records `not applicable` with the reason when the project kind differs. This narrows 0000035 ADR 019 for future migrations. Existing records stay.
- Consumer migration: a new 0.39.0 migration with `**Applies to:** downstream`. If `ravintio-framework/component.yml` remains beside a `release.yml`, it offers to remove it, one confirmed edit. If the human on the loop declines, it records `skipped` and names the file.
- Version suite (0000368): the 0000039 req-010 equality checks run only on a released tree, where `plan/current/design.md` is absent. On an open run, the suite reports them skipped with the reason.
- Tests and CI: suites read the pack from `src/ravintio-framework/` in the source repo, through one resolver. CI runs `src/ravintio-framework/tests/run-tests.sh`. A new CI check fails when a root copy file differs from its `release.yml` hash. Until this run's P7 writes the first `release.yml`, the root copy is `v0.38.0` with its `component.yml`, and the check reports itself skipped with that reason.
- Version: last known `0.38.0`. Suggested `0.39.0`, a minor bump for a Feature Pipeline run.

## Component Paths
- `src/ravintio-framework/`
- `src/setup-hook-integration/`
- `ravintio-framework/`
- `.github/workflows/ravintio.yml`
- `./README.md`
- `./CLAUDE.md`
- `.claude/skills/`
- `refresh-ravintio-framework-dir.ps1`

## Scope
- In:
  - the git pass that moves the pack and restores the root copy
  - the release script, its sanction in Hard Limit 8, and the P7 ship step
  - `release.yml` readers with the `component.yml` fallback, and file-level update detection
  - the codegen close-out and ship fallback reading component paths
  - one manifest-location rule in `spec-agent`, `docs-agent`, and `component-guide.md`
  - the `**Applies to:**` header, the source-repo signal, and the migrator rule
  - the 0.39.0 consumer migration
  - the version equality suite on a released tree only
  - tests and CI reading from `src/`, with a root copy integrity check
  - live docs: the component registry, decisions index, README, and `product.yml` path
- Out:
  - history under `plan/_archive/`, `plan/changelog/`, and released migrations
  - the consumer runtime path `ravintio-framework/` in pack text
  - backlog 0000364, the consumer CI file that setup never refreshes
- Deferred: nothing deferred
- Release size: `three-story rule`. Three stories, so it fits.

## Assumptions
- No consumer reads `ravintio-framework/component.yml` outside the pack - impact if wrong: a consumer script loses its version source after it removes the file.
- Every suite that names `ravintio-framework/` can read the pack through one resolver - impact if wrong: P3 rewrites more suites by hand.
- Record samples: none. The design reads no existing records.

## Risks
- A suite still reads the root copy and passes against the old release, which hides a broken `src/` change. Likelihood high, impact high. The resolver fails a suite that reads the root copy in the source repo, and P4 runs the full suite.
- The release script deletes a file outside the root copy, for example through a link. Likelihood low, impact high. The script resolves every target and refuses paths outside the root copy. P5 reviews it.
- This run's P7 uses the 0.38.0 ship agent, which lacks the release step. Likelihood certain, impact medium. P7 runs the script from `src/` as a recorded decision.
- A consumer copies the new folder over the old one and keeps `component.yml`. Likelihood high, impact medium. The 0.39.0 migration offers to remove it.
- The git pass produces a very large diff that hides real changes. Likelihood high, impact medium. The pass is its own commit with no content edits.

## Dependencies
- Upstream: none
- Downstream: backlog 0000361, 0000061, 0000378, 0000136, 0000368, and 0000181 close. 0000364 stays open. 0000136 closes through a migrator table that maps the released `retroactive-release-tags.md` to `framework source`, because that file can't change (P1 deviation, req-005).

## Active Skills
None

## Skill Map
P1 owns the final requirement split. This draft maps the expected requirements.

| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - move-pack-to-src | ravintio-codegen-agent | One approved git pass, then path fixes under TDD |
| REQ-002 - release-script | ravintio-codegen-agent | New script with path safety, tested in scratch repos |
| REQ-003 - release-yml-readers | ravintio-codegen-agent | Step 1a, update policy, and migrator text with file-level detection |
| REQ-004 - component-path-rule | ravintio-codegen-agent | Codegen, ship, spec, and docs skill text, checked by suites |
| REQ-005 - applies-to-header | ravintio-codegen-agent | Migrator rule and the source-repo signal |
| REQ-006 - consumer-migration | ravintio-codegen-agent | The 0.39.0 migration and its test |
| REQ-007 - released-tree-version-suite | ravintio-test-writer | The 0000039 req-010 suite rule change |
| REQ-008 - tests-and-ci-from-src | ravintio-codegen-agent | Resolver, CI paths, and the root copy integrity check |

## Repo Instructions
Five files in `ravintio-overrides/instructions/`, read at P0.
- `custom-001-local-git-only.md`: fetch, pull, push, and `gh pr create` need no prompt. Work on a `feat/` branch. Committing to `main` and merging PRs stay human-only. Commit after every meaningful artifact write.
- `custom-002-prefer-subagent-decomposition.md`: split long or multi-unit work into parallel subagents, above the size floor.
- `custom-003-git-up-to-date-shorthand.md`: `GUTD` means check out `main`, pull, list untracked files, and report the last merged PR's checks.
- `custom-004-file-backlog-entries-immediately.md`: file out-of-scope problems as backlog entries at once, then commit and push them.
- `custom-005-p9-push-and-raise-pr.md`: at P9, push and raise the PR without asking. Never merge.

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 07 Nov 2026 @ 03:18 PM GMT
