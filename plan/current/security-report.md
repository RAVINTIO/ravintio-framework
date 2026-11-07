---
title: "Security Report - 0000041-pack-source-under-src"
summary: "P5 security assessment of the pack move, the release script, the release.yml readers, CI, and the 0.39.0 migration."
---
# Security Report - 0000041-pack-source-under-src

Overall risk rating: **High**. P5 fixed every boundary break in the release script. Two High reader findings stay open as accepted residual risk R-015. A writer who can push to the pack can also rewrite the in-repo trust record, so step 1a can't detect that push.

Sources:

- `security-review-release-script.md`, the release script review (RS findings)
- `security-review-readers-and-ci.md`, the readers, CI, and migration review (RC findings)
- `security-rereview.md`, two fresh-context re-reviews of each fix

## Threat Model (STRIDE)

| Threat | Category | Severity | Mitigation |
|---|---|---|---|
| RS-F01: a run from `src/` with planted tracked files resolves `src/` as the root and replaces the real pack source | Tampering | High | Fixed. The script refuses unless the working folder, the resolved root, and the git top level are one real path. Re-review 1 and 2 confirm it. |
| RS-F02 to RS-F04: a concurrent same-user writer swaps a checked folder for a link between the check and the write or delete | Tampering | Medium | Accepted under R-002. Node has no `openat`. The build folder is mode 0o700 while it fills. |
| RS-F05: `git update-index --assume-unchanged` hides an edit from the dirty check | Tampering | Low | Accepted. Backlog 0000417 reads bytes from `HEAD`. |
| RS-F06 and NF-01: git config from the environment runs a command during the build | Elevation | Low | Partly fixed. `GIT_CONFIG_COUNT`, `GIT_CONFIG_PARAMETERS`, and `core.fsmonitor` are cleared. A `GIT_CONFIG_GLOBAL` filter still runs, which needs a local actor who controls the user's git config. Accepted under R-002. |
| RS-F07 and NF-02: a tracked `release.yml` file or folder, or a case-only collision, exits 1 and loops the ship rerun | Denial of service | Low | Fixed. Each exits 2 before any change. |
| RS-F08: the `restored:` line is lost when a build fails after recovery | Repudiation | Low | Fixed. The line prints at once. |
| NF-03: the 0o700 build folder leaves the root copy unreadable to other accounts | Denial of service | Low | Fixed. The folder goes to 0o755 before the swap. |
| RC-F01: a pack edit with rewritten `release.yml` hashes at the same version passes step 1a | Tampering | High | Not mitigated. Accepted as R-015, backlog 0000416. Step 1a compared the version only before this feature. |
| RC-F02: a deleted `release.yml` downgrades the check to version only | Tampering | High | Fixed. The fallback applies only with no trusted release record. |
| RC-F03: a push that adds the source-repo signal earns `update: own-build` | Spoofing | Medium | Not mitigated. Accepted as R-015. |
| RC-F04: step 1a runs the checker from the pack it checks | Tampering | High | Not mitigated. Accepted as R-015, backlog 0000416. |
| RC-F05: the trust record sits in the same repo as the pack | Tampering | Medium | Not mitigated. Accepted as R-015. It predates this feature. |
| RC-F06: instruction-shaped file names reach the agent in `unlisted:` lines | Spoofing | Low | Accepted. `clean()` strips control characters, and step 1a only names the files. |
| RC-F07: the CI integrity job checks the copy only against its own `release.yml` | Tampering | Medium | Not mitigated. Accepted as R-015. Backlog 0000418 covers the deleted `release.yml` skip. |
| RC-F08: `core.fsmonitor` from `.git/config` runs in the own-build check | Elevation | Low | Fixed. Every git call forces `core.fsmonitor=false` and clears the config variables. |

## Dependency Audit

No dependency added. `build-release.mjs`, `release-check.mjs`, and `project-kind.mjs` use Node.js built-in modules only (ADR-001). The one existing `package.json`, under `hooks/adapters/opencode/`, is unchanged.

## Secrets Management

The review grepped the diff since the pass commit `a5055f44`, renames included. It found no credential, token, or key. Every `autonomous` commit in this run ran `credential-scan.mjs` first, in regex-only mode, because `gitleaks` is not on PATH. No file was held back.

## Authentication & Authorisation Review

Not applicable. The feature adds no API and no auth. The human confirmation gate in step 1a stays the authorisation point for a pack update, with the limits that R-015 records.

## Input Validation Review

- `build-release.mjs` refuses arguments, links at each boundary folder, `..` and non-ASCII segments, a dirty pack source, tracked links, a reserved `release.yml` name, and case-only collisions. Each refusal exits 2 before any change.
- `release-check.mjs` reads `release.yml` and `plan/framework-release.yml` line by line, refuses links, and exits 2 on any format break, with no fallback.
- The 0.39.0 migration shows the `rm` command and never runs it. The human on the loop confirms it in every run mode.

## Network Policy

Not applicable. No script opens a network connection. The `release-copy-integrity` CI job runs on `pull_request` with `permissions: contents: read` and interpolates no `${{ }}` input.

## Infrastructure as Code Review

Not applicable. The feature has no IaC. The CI workflow review sits under Network Policy.

## Risk Register cross-reference

| Risk | Status after P5 |
|------|-----------------|
| R-002 | Open. P5 fixed the root escape and narrowed the race. The same-user race and NF-01 are accepted. |
| R-004, R-009, R-011, R-013 | Mitigated. |
| R-006 | Accepted, unchanged. RS-F01's fix removes the release script's dependency on backlog 0000382. |
| R-014 | Open. RC-F03 moves the deliberate case into R-015. |
| R-015 | New, open, accepted residual risk. |

## Summary

Overall risk rating: High.

Top actions before production:

1. Decide on backlog 0000416, a trust anchor outside the repo, which closes RC-F01, RC-F04, and RC-F05.
2. Run the req-002 suite on a case-sensitive file system, such as the Linux CI shard, so the RS-F07 case-collision case runs and doesn't skip.
3. Take up backlog 0000417, so the build reads committed bytes and closes RS-F04 and RS-F05.
