# Security re-review - 0000042-fix-windows-shards-pr-77

Both findings are fixed. The overall risk rating for the diff drops from High to Low.

Reviewer: fresh-context security re-reviewer, 2026-11-08.

Scope:

- `951bc651` (fix)
- `764b7110` (red test)
- S-1 and S-7 in `plan/current/security-report.md`

## Summary

| Finding | Original severity | Verdict |
|---|---|---|
| S-1 | High | Fixed |
| S-7 | Low | Fixed |
| R-1 (new) | Info | Open, accepted residual |
| R-2 (new) | Info | Open, test gap |

## S-1: failed `mktemp` deletes the caller's folder

Verdict: fixed.

Evidence, in `src/ravintio-framework/tests/test-0000041-req-005-applies-to-header.sh`:

- Line 27 assigns `mktemp` to `WORK_TMP` with its own `||` guard. A non-zero `mktemp` exit now stops the suite.
- Line 28 exits if `WORK_TMP` is empty or is not a directory. This catches an empty output with exit 0.
- Line 29 sets the trap only after both checks. The trap removes `WORK_TMP`, never the converted `WORK`.
- Line 30 runs the `pwd -W` conversion in its own command. A `cd` failure exits 1 with `cannot enter the scratch folder`.
- No trap exists before line 29. Neither `helpers/assert.sh` nor `helpers/pack-root.sh` sets a trap. Under `set -u`, no path can run the trap with `WORK_TMP` unset.

Break attempts. Each ran from a scratch caller folder holding a `keep.txt` sentinel, with a stand-in `mktemp` first on `PATH`:

| Stand-in `mktemp` behaviour | Suite exit | Caller folder kept | Message |
|---|---|---|---|
| `exit 1`, no output | 1 | yes | `mktemp -d failed` |
| exit 0, empty output | 1 | yes | `mktemp -d failed` |
| prints `/nonexistent/xyz`, exit 0 | 1 | yes | `mktemp -d failed` |
| prints a regular file, exit 0 | 1 | yes | `mktemp -d failed` |
| prints a folder with mode `000` (`cd` fails) | 1 | yes | `cannot enter the scratch folder` |
| prints `.`, exit 0 | 0 | yes, with scratch repos left in it | none (see R-1) |
| prints the caller's own path, exit 0 | 0 | no, deleted | none (see R-1) |

The first five rows cover every failure that a real `mktemp` can produce. The last two need a `mktemp` that reports success for a folder it didn't create. R-1 covers them.

Git Bash `pwd -W` form, reasoned and not run:

- Git Bash ships GNU `mktemp`. With `-t`, it creates the folder under `$TMPDIR` or `/tmp` and prints a POSIX path such as `/tmp/ravintio_0000041_req005_AbC123`.
- `[ -d ]` and `rm -rf` on that POSIX path both work under MSYS. The trap now removes the POSIX form where it used to remove the Windows form. MSYS `rm` accepts both, so cleanup behaves as before.
- `cd "$WORK_TMP" && pwd -W` still yields `C:/Users/.../Temp/ravintio_...`. That gives `WORK` the same value as before the fix, so every later use of `WORK` and `native()` is unchanged.
- The Windows `SKIP (windows)` branch starts at line 116, after the scratch setup. On Git Bash, a failed `mktemp` still exits 1 before any skip runs.

Suite runs on macOS, `/bin/bash` 3.2:

- `test-0000041-req-005-applies-to-header.sh`: 67 passed, 0 failed. It left no `ravintio_0000041_req005_*` folder in `$TMPDIR`.
- `test-0000042-req-001-windows-guards.sh`: 10 passed, 0 failed. That includes the new assertions 9 and 10 at lines 109 to 136.

## S-7: unpinned `rev-parse` lookup

Verdict: fixed.

Evidence, in `src/ravintio-framework/tests/test-0000041-req-005-applies-to-header.sh`:

- Line 254 resolves `refs/tags/v0.38.0:ravintio-framework/migrations/retroactive-release-tags.md` with `--verify --quiet`.
- Line 255 resolves `HEAD:$REL_PATH` with `--verify --quiet`.

Reasoning:

- Git's first lookup rule takes `refs/tags/v0.38.0` as the literal ref. A branch named `v0.38.0` no longer shadows the tag. A ref at `refs/refs/tags/v0.38.0` only matches the second rule, so the tag still wins.
- `--verify --quiet` prints nothing and exits non-zero on a miss. The empty `OLD_ID` then fails the check on line 256 with `v0.38.0=none`, as before.
- Locally, `v0.38.0` is an annotated tag. The pinned lookup peels it and returns blob `c26385d3`. The suite's blob check passes.
- Anyone who can rewrite the tag on the remote can still move it. The original report accepted that, and this diff doesn't change it.

## New findings

### R-1: trap trusts any folder that `mktemp` reports (Info)

The original report suggested a trap guard: `[ -n "$WORK" ] && [ "$WORK" != "$PWD" ]`. The fix omits it.

If a `mktemp` on `PATH` prints an existing folder with exit 0, line 28 accepts it. The trap on line 29 then deletes that folder. The reviewer reproduced this with a stand-in that prints the caller's path. The caller folder was deleted.

A real `mktemp -d` always creates a new folder, so this needs a hostile or broken `mktemp` first on `PATH`. A person who can do that can already run code as the user. The severity is Info. If you want defence in depth, add `[ "$WORK_TMP" != "$PWD" ]` to line 28.

### R-2: assertions 9 and 10 test only a non-zero `mktemp` exit (Info)

The stand-in at `test-0000042-req-001-windows-guards.sh` lines 115 to 118 only exits 1. No assertion covers the empty-output, exit-0 case that line 28 guards. This re-review covered that case by hand, and it passes. A future edit could drop line 28 and the suite would stay green.

The fix introduced no other issue.

## Updated overall risk rating

Overall risk rating: Low.

S-1 drove the High rating, and it is now fixed. S-7 is fixed. R-1 and R-2 are Info and don't block the gate.
