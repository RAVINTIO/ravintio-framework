---
title: "Execution Plan - fix-windows-shards-pr-77"
summary: "Non-functional requirements, API and data summary for 0000042."
---
# Execution Plan - fix-windows-shards-pr-77

## Active Skills

| Skill | Scope | Purpose |
|-------|-------|---------|
| None | n/a | No capability skill applies to Bash test edits. |

## Functional Requirements Directory

| File | Requirement |
|------|------------|
| [req-001-windows-safe-0000041-suites.md](requirements/req-001-windows-safe-0000041-suites.md) | Both 0000041 suites pass on Windows, and every skip names its reason |

## Non-Functional Requirements

| ID | Category | Requirement | Target | Measurement |
|----|----------|------------|--------|-------------|
| NFR-001 | Reliability | Every PR #77 check passes | 14 of 14 | `gh pr checks 77` |
| NFR-002 | Coverage | Linux and macOS keep every case | req-005 at 67 passed, req-006 at 127 passed, 0 SKIP lines | suite `Results` lines |
| NFR-003 | Security | Scratch files stay in `mktemp -d` folders | 0 files written outside them | the `EXIT` trap, and `git status` after a run |

## API Summary

Not applicable. The change adds no endpoint.

## Data Model Summary

Not applicable. The change touches test code and one README.

## Component Interactions

- GitHub Actions runs `src/ravintio-framework/tests/run-tests.sh` in seven Windows shards and on `ubuntu-latest` and `macos-latest`.
- Each suite sources `helpers/assert.sh` and `helpers/pack-root.sh`, and reads the pack from `RAVINTIO_PACK_DIR`.
- At P7, the release script copies the changed suites to the root `ravintio-framework/` release copy.

## Assumptions

| ID | Assumption | Impact if Wrong |
|----|-----------|----------------|
| A-001 | Git Bash `ln -s` makes a copy on the Windows runner | The skip hides link coverage that Windows could give |
| A-002 | The Windows checkout converts LF to CRLF | The blob compare passes, but the byte compare failed for a reason still unknown |
| A-003 | Node reads `/tmp/...` inside a `node -e` string as `C:\tmp\...` | The `pwd -W` change does nothing, and the import cases still fail |

## Open Questions

None.
