---
title: "Discovery - 0000044-credential-scan-word-boundary"
summary: "Raw P0 discovery-pass findings: what the orchestrator knew before coaching began."
---
# Discovery - 0000044-credential-scan-word-boundary

> Created at the start of P0, before the first coaching question, in every adoption mode.
> Raw findings only; decisions belong in `design.md`, the Q&A audit trail in `build-log.md`.
> Unreadable signal: say so; coaching proceeds.

## Header (all modes)

| Field | Value |
|-------|-------|
| Adoption mode detected | `standard-iterative` |
| Detection signal | `plan/_archive/` holds prior feature folders up to 0000043, and `docs/about.md` exists |
| Git pre-flight | Started on `main`, level with `origin/main` at `4764d2d5`. No open PR. PR #77 merged last. Created `feat/0000044-credential-scan-word-boundary`. |
| Skills inbox | empty |

## Mode Findings

### Standard Iterative

- Current version (`docs/about.md`): `0.39.2`. Tags `v0.39.0`, `v0.39.1`, and `v0.39.2` exist.
- Prior features (`plan/_archive/`):
  - 0000041-pack-source-under-src, 2026-11-07: moved the pack source under `src/` and ships a release copy with `release.yml`.
  - 0000042-fix-windows-shards-pr-77, 2026-11-08: fixed the Windows test shards for PR #77.
  - 0000043-macos-test-job-timeout, 2026-11-08: sharded the macOS test job.
- Constraining ADRs (unless superseded):
  - 0000037 ADR-001: `credential-scan.mjs` uses Node built-ins only.
  - 0000037 ADR-003: an autonomous commit holds back a file with a scan hit. A resumed run never stages it until the human clears it.
  - 0000041 ADR-004: the release script owns the root `ravintio-framework/` copy. No agent writes it with **Write** or **Edit**.
- Component / data-ownership map (`docs/`): `ravintio-framework` owns `src/ravintio-framework/`, which holds `scripts/credential-scan.mjs` and `tests/test-0000037-req-003-credential-scan.sh`. The root `ravintio-framework/` copy comes from the release build.

### Backlog 0000425 findings

- Rule: `src/ravintio-framework/scripts/credential-scan.mjs:56` holds `['api-secret-key', /sk-[A-Za-z0-9_-]{20,}/]`.
- Reproduction: `node src/ravintio-framework/scripts/credential-scan.mjs --file ravintio-framework/release.yml` exits 1. It reports lines 634 and 635 under `api-secret-key` and no other hit.
- Cause: each line holds the path of the vendored risk requirements analysis skill. The folder name puts `sk` and a hyphen inside the word `risk`, then a run of 20 or more path characters.
- Scan mode: regex only. `gitleaks` isn't installed on this machine.
- Suite: `test-0000037-req-003-credential-scan.sh` has one `api-secret-key` fixture, an `sk` key at the start of a word. A regression copy under `tests/regression/` differs from the live copy.
- State: `ravintio-framework/release.yml` sits untracked on `main` since the 0000041 P7 held it back.

## Record Samples

None
