# Security Report - 0000042-fix-windows-shards-pr-77

Scope: `git diff 9222025a HEAD -- src/`. The diff changes test suites, the tests `README.md`, and the `component.yml` version. No runtime script, hook, or released migration changes.

The reviewer ran `test-0000042-req-001-windows-guards.sh` on macOS. It passed 8 of 8 checks. It left no `ravintio_0000041_*` or `ravintio_0000042_*` folder in the temp folder, and it changed no tracked file.

The review ran in one context. The diff holds five small files with no separate components, so a subagent split would cost more than it saves.

## Threat Model (STRIDE)

| Threat | Category | Severity | Mitigation |
|---|---|---|---|
| S-1. `test-0000041-req-005-applies-to-header.sh` line 27 wraps `mktemp` in `cd "$(mktemp ...)"`. If `mktemp` fails, it prints nothing, and `cd ""` succeeds without moving. `WORK` then holds the caller's working folder, and the `\|\| { ... exit 1; }` guard never fires. `mk_repo` then writes scratch repos into that folder. The `trap 'rm -rf "$WORK"' EXIT` on line 28 deletes it on exit. CI and `run-tests.sh` start suites from the repo root, so the delete takes the whole working tree and `.git`. The reviewer reproduced the empty `cd` result under `/bin/bash` 3.2. The old line 26 (`WORK="$(mktemp ...)" \|\| ...`) caught the failure, so this diff introduces the regression. Likelihood is low: it needs a full disk or an unusable temp folder, which happens on CI runners. | Tampering / DoS | High | Not mitigated. Fix: assign `mktemp` to its own variable with its own `\|\|` guard, then convert with `cd "$D" && { pwd -W \|\| pwd; }`. Also guard the trap with `[ -n "$WORK" ] && [ "$WORK" != "$PWD" ]`. |
| S-2. The four linked-path cases in `test-0000041-req-005-applies-to-header.sh` lines 114 to 135 skip on Windows. So does Case 6 in `test-0000041-req-006-consumer-migration.sh` lines 373 to 382. These cases are the only proof that `project-kind.mjs` refuses linked `product.yml`, `component.yml`, and `src` paths. They also prove the migrator refuses a linked `ravintio-framework/` and keeps the target file. A link that passes these checks would let a downstream repo pass as framework source, or let a migration delete through a link. On Windows, no test now covers this. `project-kind.mjs` lines 62 to 84 use `lstatSync().isSymbolicLink()`, which Node also sets for junctions. The code path probably holds, but no Windows run shows it. A real user can make a junction with `mklink /J` without admin rights. | Elevation / Tampering | Medium | Partly mitigated. Linux and macOS still run all five cases, and each skip prints its reason (R-001, accepted). Not mitigated for Windows junctions or Developer Mode links. |
| S-3. `test-0000041-req-005-applies-to-header.sh` lines 159, 160, 168, and 169 paste `$(native "$PK")` and `$R` into single-quoted JavaScript string literals inside `node -e`. A checkout path or `TMPDIR` holding `'` or `\` breaks the string, and a crafted path runs as code in the test's Node process. Both values come from the user's own checkout and temp folder, so no other party controls them. `$R` and `'$PK'` were already pasted this way before the diff. | Tampering | Low | Not mitigated. Pass the paths as arguments (`node -e '...' -- "$path"`, then read `process.argv`) or through an environment variable. |
| S-4. `test-0000042-req-001-windows-guards.sh` line 50 prepends the stand-in folder to `PATH`. The prefix assignment reaches only the child `bash` and its descendants, not the guard suite itself (line 24 reads the real `uname`). The folder comes from `mktemp -d`, which makes it mode `0700`, so no other local user can plant a binary there. The stand-in holds only `uname`, written through a quoted heredoc (line 36), so no variable expands into it. It calls the real binary by the absolute path `/usr/bin/uname` (line 41), so it cannot recurse or pick up another `uname` from `PATH`. | Elevation | Low | Mitigated by scope and folder mode. One side effect: every descendant that reads `uname -s`, such as a hook under test, takes its Windows path. That stays inside the scratch repos. |
| S-5. `test-0000042-req-001-windows-guards.sh` lines 26 and 27 keep the safe form: `WORK="$(mktemp ...)" \|\| exit`, then the trap. `test-0000041-req-006-consumer-migration.sh` lines 37 and 38 keep the same form. Cleanup ran on the reviewer's macOS run. | DoS | Low | Mitigated. |
| S-6. `test-0000041-req-005-applies-to-header.sh` line 254 runs `git hash-object --path=...` without `-w`, so it writes no object. `--path` applies the repo's `.gitattributes` and clean filters. A configured `filter.*.clean` could make any working-tree content hash to the v0.38.0 blob id. The old byte compare (`cmp`) did not trust repo config. Changing the filter config needs write access to the repo, which already allows editing the file. Line 253 adds a `HEAD` blob check, which the old code lacked. | Tampering | Low | Accepted by ADR-003. The `HEAD` check covers committed content. |
| S-7. `test-0000041-req-005-applies-to-header.sh` lines 252 and 253 run `git rev-parse` without `--verify` on `v0.38.0:...` and `HEAD:...`. Git resolves `v0.38.0` through `refs/`, then `refs/tags/`, then `refs/heads/`. A local ref named `v0.38.0` could shadow the tag. Only someone with write access to `.git` can add one. The tag itself is mutable on the remote, as before the diff. | Spoofing | Low | Not mitigated. `refs/tags/v0.38.0:...` would pin the lookup to the tag. |

### Risk register cross-reference

| ID | Register status | Finding in the implementation |
|---|---|---|
| R-001 | accepted | The link skips match ADR-002. Each prints a reason that names `ln -s`, and the guard suite checks the count (lines 71 to 87). Linux and macOS still run all five link cases. The Windows coverage gap stays open (S-2). |
| R-002 | open | Out of the diff. It concerns CI reads before P5 and a P7 step. Nothing in `src/` mitigates it. |
| R-003 | accepted | Out of the diff. `release.yml` sits untracked at the repo root and outside `src/`. |
| R-004 | open | Mitigated in code. Line 251 builds `REL_PATH` from `RAVINTIO_PACK_REL`, so the source repo reads `src/ravintio-framework/...`. The reviewer's macOS run of the req-005 suite passed 67 cases in the source repo. |
| A-001 | open | Consistent with the guards. The diff does not test it. |
| A-002 | open | Line 254 addresses it through `hash-object --path`, which applies `core.autocrlf`. |
| A-003 | open | Line 27 (`pwd -W`) and the `native()` helper on lines 30 to 32 address it. Line 27 also carries S-1. |

## Dependency Audit

No dependency changes. The diff adds no package, no lockfile entry, and no new tool. The suites call `bash`, `node`, `git`, `sed`, `grep`, and `cygpath`, which earlier suites already use. Nothing needs immediate action.

## Secrets Management

No secrets in the diff. The reviewer searched the changed lines for tokens, keys, and credentials and found none. The suites read no environment secret. Line 16 of the guard suite unsets `CLAUDE_PROJECT_DIR`, so the child suites cannot reach the real project root through it.

## Authentication & Authorisation Review

Not applicable. The diff holds shell test suites and a manifest. It exposes no API and handles no identity or token. No OpenAPI spec exists for this feature.

## Input Validation Review

Not applicable as an API review, because no endpoint exists. The only untrusted-looking input is the path text pasted into `node -e` strings, which S-3 covers. All other paths stay quoted in shell (`"$WORK"`, `"$R"`, `"$REL_PATH"`).

## Network Policy

Not applicable. The diff opens no port and makes no network call. The git commands on lines 252 to 254 read only the local repository.

## Infrastructure as Code Review

Not applicable. The diff holds no Terraform, Pulumi, CDK, or CloudFormation file. It does not change `.github/workflows/ravintio.yml`.

## Summary

Overall risk rating: High

The rating rests on S-1 alone. It is a data-loss regression in test code that ships in the pack. If you fix S-1, the rating drops to Low.

Top actions before production:
1. Fix S-1 in `test-0000041-req-005-applies-to-header.sh` line 27. Split `mktemp` from the `pwd -W` conversion, and guard the line 28 trap against an empty or current-folder `WORK`.
2. Cover link refusal on Windows (S-2). Build a junction with `cmd //c mklink //J` in one case, or record the gap as a Windows-only backlog entry.
3. Pass paths to `node -e` through `process.argv` rather than string literals (S-3), at lines 159, 160, 168, and 169.
