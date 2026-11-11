# Risk - ravintio-framework

Last updated: 0000044-credential-scan-word-boundary

Component-scoped risks. The full register for each feature sits in the feature's `risk-register.md`. The component manifest lists earlier risks from features 0000021 to 0000040.

## Risks added by 0000044

| ID | Risk | Likelihood | Impact | Status |
|---|---|---|---|---|
| R-001 | A real `sk-` key glued to an ASCII letter, a digit, or `_` goes undetected by the `api-secret-key` rule. | low | medium | Open, accepted at the 0000044 P0 Scope Lock. gitleaks still runs where it is installed, and no CI job runs it (backlog 0000435). |
| N-001 | A key after a `\x` escape or an ANSI colour code goes undetected. The rule before 0000044 caught both. | low | low | Open (backlog 0000437). |

## Risks added by 0000041

| ID | Risk | Likelihood | Impact | Status |
|---|---|---|---|---|
| R-001 | A suite reads the root copy and passes against the old release, which hides a broken `src/` change. | high | high | Mitigated. `pack-root.sh` fails a suite that reads the root copy in the source repo, and P4 runs the full suite. |
| R-002 | The release script writes or deletes a file outside the root copy, for example through a link. | low | high | Open, accepted residual risk. See below. |
| R-004 | A consumer copies the new folder over the old one and keeps `component.yml`. | high | medium | Mitigated. The 0.39.0 migration offers the removal, and step 1a warns each session. |
| R-015 | A push that can write the pack can also rewrite the trust inputs, so step 1a reports no update. | medium | high | Open, accepted residual risk. See below. |

## R-002 residual risk

P5 fixed the working-folder root escape (RS-F01). The script now refuses unless the working folder, the resolved root, and the git top level are one real path.

A same-user writer can still swap a checked folder for a link between the check and the write or delete (RS-F02 to RS-F04). Node has no `openat`. The build folder is mode 0o700 while it fills, then 0o755 before the swap.

A `GIT_CONFIG_GLOBAL` filter can still run during the build (RS-F06, NF-01). It needs a local actor who controls the user's git config. The script clears `GIT_CONFIG_COUNT`, `GIT_CONFIG_PARAMETERS`, and `core.fsmonitor`.

`git update-index --assume-unchanged` hides an edit from the dirty check (RS-F05). Backlog 0000417 reads bytes from `HEAD`.

## R-015 residual risk

Step 1a decides from files in the same repo as the pack. These are `release.yml`, `plan/framework-release.yml`, `scripts/release-check.mjs`, and the `product.yml` source-repo signal. A writer of the pack can rewrite all of them (RC-F01, RC-F03 to RC-F05, RC-F07).

- Before this feature, step 1a compared the version only. The feature narrows the gap and does not open it.
- P5 removed the fallback downgrade for a deleted `release.yml` (RC-F02).
- A trust anchor outside the repo is backlog 0000416. It closes RC-F01, RC-F04, and RC-F05.
- The CI integrity job skips a deleted `release.yml` after the first 0.39.0 release. Backlog 0000418 covers it.

The security report rates the feature High overall because of R-015. No other finding is open above Medium.
