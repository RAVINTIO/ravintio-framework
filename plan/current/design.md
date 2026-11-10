# Design - 0000044-credential-scan-word-boundary

## Feature
- Problem: the `api-secret-key` rule matches the `sk-` inside the word `risk-` on two `release.yml` lines, so every autonomous P7 holds back `release.yml`.
- Adoption mode: standard-iterative (signal: `plan/_archive/` holds prior feature folders up to 0000043, and `docs/about.md` exists)
- Feature ID: 0000044-credential-scan-word-boundary
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As a framework maintainer, I run the credential scan on a release build, so that `release.yml` commits without a false hold-back.
- Acceptance criteria confirmed: 4 (from `feature-brief.md`)
- Constraints:
  - Node built-ins only (0000037 ADR-001).
  - No agent edits a held-back file to hide a match.
  - The release script, not **Write** or **Edit**, writes the root `ravintio-framework/` copy (0000041 ADR-004).
- Integrations: every caller of `credential-scan.mjs`, in staged, `--file`, and `--safe-paths` modes.

## Architecture Layer
- Latency target: not applicable (no service)
- Availability target: not applicable (no service)
- Scalability target: the rule stays linear on one long line. The new pattern adds a zero-width word boundary and no nested quantifier.
- Security: no auth. The rule must still match a real `sk-` key at the start of a line or after any non-word character. The scan still never prints matched text.
- Data privacy: no regulated data
- Observability: unchanged. The scan prints `{path}:{line} {rule}` per hit.
- Cost boundary: not constrained

## Engineering Layer
- Stack: unchanged. Node built-ins, Bash suites under `run-tests.sh`, GitHub Actions CI. Build target: local.
- Components:
  - `ravintio-framework` (component-pack): owns `scripts/credential-scan.mjs` and the 0000037 credential scan suite under `src/ravintio-framework/`.
- Data ownership:
  - `ravintio-framework` owns every file under `src/ravintio-framework/`.
  - The release script owns the root `ravintio-framework/` copy and its `release.yml`. No agent writes them with **Write** or **Edit**.
- Rule change:
  - `api-secret-key` becomes `/\bsk-[A-Za-z0-9_-]{20,}/`. The `\b` needs a non-word character or the line start before `s`.
  - A word character is a letter, a digit, or `_`. So `risk-`, `task-`, and `my_sk-` no longer match.
  - `=sk-`, `"sk-`, `:sk-`, ` sk-`, and a line-start `sk-` still match.
  - Every other non-word character before `sk-` also still matches, such as `-`, `/`, `(`, and `,`. So a path segment that starts with `sk-` still holds a file back.
- Suite updates, in both the live and the regression copy of `test-0000037-req-003-credential-scan.sh`. The two copies differ only in their helper and pack paths, so both get the same cases:
  - a negative case: a `release.yml` line under an `external-skills/risk-` path with a 64-character hash exits 0
  - negative cases for `sk-` after a letter, a digit, and `_`
  - positive cases for `sk-` after `=`, a quote, and a space, beside the existing line-start case
- Deployment: P7 runs the release script, which rebuilds the root copy and `release.yml` from `src/`. The P7 scan then passes `release.yml`, and the P7 commit includes it.
- API versioning: not applicable
- Version: last known `0.39.2`, and `v0.39.2` already exists. Suggested `0.39.3`, a patch bump, because the change fixes a false match and adds no pack feature. The `ravintio-framework` manifest under `src/` carries the bump.

## Component Paths
- `src/ravintio-framework/`
- `ravintio-framework/`
- `./product.yml`

## Scope
- In:
  - the `api-secret-key` pattern
  - the suite cases above, in both suite copies
  - the 0.39.3 version and the P7 release copy rebuild, with `release.yml` committed
- Out:
  - any other content rule
  - an allowlist for `release.yml` or any other file
  - gitleaks rules
- Deferred: nothing deferred.
- Release size: `three-story rule`. One story, so it fits.
- Backlog: pull in 0000425 and delete its folder in the design confirmation commit. Leave the other 256 entries untouched.

## Assumptions
- Real `sk-` keys start after a non-word character or at the line start - impact if wrong: a key glued to a word, such as `token_sk-...`, goes undetected by the regex rule.
- The 0000041 hold-back line lives only in that run's archived build log - impact if wrong: a resumed run here refuses to stage `release.yml`. This run's build log holds no hold-back line.
- No other `release.yml` line trips another rule - impact if wrong: P7 still holds back `release.yml`. The P0 scan of the current `release.yml` showed only the two `api-secret-key` hits.

## Risks
- The boundary lets a real key through when it follows a word character. Likelihood low, impact medium. Provider keys appear after `=`, a quote, a colon, or a space in configs and environment files.
- A future vendored path holds `sk-` after a non-word character, such as a folder named `sk-...`. Likelihood low, impact low. The scan holds the file back, as it does now.

## Dependencies
- Upstream: none
- Downstream: every autonomous P7 and every commit that runs the credential scan

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - api-secret-key-word-boundary | ravintio-codegen-agent | one regex change and its suite cases through the TDD loop |

## Repo Instructions
Five files in `ravintio-overrides/instructions/`, read at P0.
- `custom-001-local-git-only.md`: fetch, pull, push, and `gh pr create` need no prompt. Work on a `feat/` branch. Committing to `main` and merging PRs stay human-only. Commit after every meaningful artifact write.
- `custom-002-prefer-subagent-decomposition.md`: split long or multi-unit work into parallel subagents, above the size floor.
- `custom-003-git-up-to-date-shorthand.md`: `GUTD` means check out `main`, pull, list untracked files, and report the last merged PR's checks.
- `custom-004-file-backlog-entries-immediately.md`: file out-of-scope problems as backlog entries at once, then commit and push them.
- `custom-005-p9-push-and-raise-pr.md`: at P9, push and raise the PR without asking. Never merge.

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 10 Nov 2026 @ 10:26 PM GMT
