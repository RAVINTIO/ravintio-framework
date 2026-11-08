---
title: "Discovery - 0000042-fix-windows-shards-pr-77"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000042-fix-windows-shards-pr-77

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only. Decisions belong in `design.md`, and the Q&A audit trail in `build-log.md`.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds 41 feature folders, and `docs/about.md` exists |
| Git pre-flight | Branch `feat/0000041-pack-source-under-src`, level with its remote. PR #77 is open and unmerged by design: this run fixes it. `origin/main` sits at `3197b007`. One untracked file: `ravintio-framework/release.yml`. |
| Skills inbox | empty |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`): `0.39.0`. The tag `v0.39.0` sits on `origin` at `04c329e0`.
- Prior features: 0000001 to 0000041. The last one, 0000041-pack-source-under-src (2026-11-07), moved the pack source to `src/ravintio-framework/` and shipped as draft PR #77.
- Constraining ADRs (unless superseded):
  - 0000041 ADRs: the pack source lives under `src/ravintio-framework/`, and the root `ravintio-framework/` is the release copy that P7 rebuilds.
  - Released migration files never change. The req-005 suite checks this for `retroactive-release-tags.md`.
- Component and data-ownership map: unchanged from 0000041. The `ravintio-framework` component owns `src/ravintio-framework/`, including its tests.

### PR #77 CI findings

- Run `42409694287` has 14 checks. 12 pass and 2 fail.
- `Test suite (windows-latest, shard 5 of 7)`: `test-0000041-req-005-applies-to-header.sh` reports 60 passed and 7 failed.
  - 4 linked-path cases: linked `product.yml`, `component.yml`, `src/ravintio-framework`, and `src`.
  - 2 `projectKind(root)` import cases.
  - 1 byte compare of `retroactive-release-tags.md` against `v0.38.0`.
- `Test suite (windows-latest, shard 6 of 7)`: `test-0000041-req-006-consumer-migration.sh` reports 125 passed and 2 failed. Both cases come from Case 6, the linked `ravintio-framework/`.
- Other suites already print `SKIP (windows)` lines because `ln -s` makes a copy under Git Bash.
- Backlog 0000426 names the fix for each case. It also names the cause: `gate-write` blocked the P9 fixer because P7 had archived the design.

### Release copy findings

- `ravintio-framework/release.yml` stays untracked. The P7 credential scan held it back over two path and SHA-256 lines (backlog 0000425).
- The `release-copy-integrity` job passes and prints its skip notice while `release.yml` is absent.
- A change under `src/ravintio-framework/tests/` reaches the root copy only when P7 runs the release script.

## Record Samples

None
