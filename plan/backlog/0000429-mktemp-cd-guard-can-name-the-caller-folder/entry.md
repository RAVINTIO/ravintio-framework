---
title: "Backlog Entry: 0000429 - mktemp cd guard can name the caller's folder"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000429 - mktemp cd guard can name the caller's folder

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000042-fix-windows-shards-pr-77
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-08

---

## Problem

Several suites build their scratch folder with this form:

```bash
WORK="$(cd "$(mktemp -d -t ...)" && { pwd -W 2>/dev/null || pwd; })"
```

If `mktemp` fails, the inner substitution is empty. Bash runs `cd ""`, which succeeds and stays in the current folder. `WORK` then names the caller's folder, and no guard fires. A suite whose `EXIT` trap runs `rm -rf "$WORK"` would then delete that folder. `run-tests.sh` and CI start suites from the repository root.

The 0000042 P5 security review found the form in nine suites under `src/ravintio-framework/tests/`:

- `test-0000032-req-007-stderr-block-reasons.sh` line 30
- `test-0000035-req-005-ratchet-check-shared-root.sh` line 23
- `test-0000035-req-008-sanctioned-scripts.sh` line 28
- `test-0000036-req-008-non-regular-design-md.sh` line 30
- `test-0000039-req-008` line 36
- `test-0000040-req-002` line 36
- `test-0000040-req-003` line 33
- `test-0000041-req-002-release-script.sh` line 46
- `test-0000041-req-003` line 53

The review didn't check each suite's trap, so the delete risk per suite is unknown. 0000042 fixed the same form in `test-0000041-req-005-applies-to-header.sh`, where it had introduced it.

## Suggested Action

Give `mktemp` its own assignment and `|| exit 1`, then convert the folder in a second step. Add a shared helper in `tests/helpers/` so every suite builds its scratch folder the same way. Add a check that runs each suite under a failing `mktemp` stand-in.

## Why Deferred

The 0000042 run fixes two 0000041 suites for PR #77. These nine suites belong to other features, and a shared helper needs its own design.
