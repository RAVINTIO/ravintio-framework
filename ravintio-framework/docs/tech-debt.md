# Tech debt - ravintio-framework

Last updated: 0000041-pack-source-under-src

Debt that 0000041 accepted or found. Each item has a backlog entry under `plan/backlog/`.

## Open

| Backlog | Item | Why it stays |
|---|---|---|
| 0000402 | The 0000037 migration branch diff compares the pack against the highest `v*` tag. A tag before the move holds the pack at `ravintio-framework/`, so the next unreleased re-run-setup migration would show every pack file as added. | The real-repo case skips today because no such migration exists. |
| 0000416 | Step 1a decides from files in the same repo as the pack. A trust anchor outside the repo would close RC-F01, RC-F04, and RC-F05. | Deliberate scope decision. It is accepted residual risk R-015. |
| 0000417 | `build-release.mjs` reads source bytes from the working tree. It should read committed bytes from `HEAD` (RS-F04, RS-F05). | Accepted under R-002. |
| 0000418 | The CI integrity job treats `skipped: no ravintio-framework/release.yml` as a pass. A PR that deletes `release.yml` and edits the root copy passes with a notice. | Found at P5 re-review. |
| 0000423 | `build-release.mjs` and `release-check.mjs` duplicate `clean`, `lstatOrNull`, `readNoFollow`, `lfHash`, and the git environment scrub. A shared `scripts/release-common.mjs` would hold one copy. | A refactor would reopen the P5 security review. A drift in `lfHash` would make the two scripts disagree on every hash. |
| 0000384 | Pack component docs ship in the release copy as `ravintio-framework/docs/`. | Needs a decision on where a pack's docs live. |

## Resolved by 0000041

- 0000361, 0000061: the codegen close-out reads manifests from `## Component Paths` and `product.yml`.
- 0000378, 0000136: the `**Applies to:**` header and the source-repo signal.
- 0000368: the version suite runs its equality checks on a released tree only.
- 0000181: step 1a detects a changed pack file at an unchanged version.
