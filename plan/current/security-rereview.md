# Security Re-review - credential-scan-word-boundary

**Skill:** [security-agent](../../ravintio-framework/skills/ravintio-security-agent/SKILL.md)
**Feature:** 0000044-credential-scan-word-boundary
**Scope:** finding S-001 and the fix in `git diff 971a43d2..HEAD -- src/`
**Reviewer:** fresh-context subagent with no memory of the fix

> It is advisory. The re-review changes no code. All findings require human review before action.

## Verdict

**S-001 status:** closed

**Overall risk after the fix:** low

The fix matches a key after every context that S-001 lists. It brings back no false match on `release.yml` or on prose and paths. The pattern stays linear. The scan still prints no matched text. The new findings below are all low or informational. None blocks the P5 gate.

## S-001 contexts

Each probe wrote a one-line fixture in the scratchpad and ran `credential-scan.mjs --file` on it. The probe built the key at run time.

| Context from S-001 | Result |
|--------------------|--------|
| `%3D` before the key | match |
| `%22` before the key | match |
| `%20` before the key | match |
| `%3A` before the key | match |
| `\n` before the key | match |
| `\t` before the key | match |
| `\u0022` before the key | match |

Criterion 7 of req-001 holds. Both suite copies carry the seven cases at lines 207 to 213, and each copy reports 210 passed and 0 failed.

## Other escape contexts

| Context | Result | Old rule (no boundary) |
|---------|--------|------------------------|
| Lowercase hex percent escape (`%3d`, `%3a`, `%2c`) | match | match |
| Double-escaped backslash (`\\n`, `\\"`) | match | match |
| `\r` | match | match |
| `\u{22}` | match | match |
| HTML entity (`&#34;`, `&quot;`, `&#x22;`) | match | match |
| `+` as a form-encoded space | match | match |
| `\x22`, `\x3D` | miss (N-001) | match |
| ANSI colour code, a real ESC byte then `[0m` | miss (N-002) | match |
| Double percent-encoding (`%253D`, `%2522`) | miss (N-003) | match |
| `\b`, `\f`, `\v`, `\0`, `\U00000022`, a literal `\e[0m` | miss (N-004) | match |
| Base64 run glued to the key | miss (S-003, accepted) | match |

## False matches

- `node src/ravintio-framework/scripts/credential-scan.mjs --file ravintio-framework/release.yml` exits 0. Its eight `sk-` sites follow `d-task-`, `n-risk-`, and `s/risk-`.
- These prose and path probes each exit 0:
  - `task-`
  - `desk-`
  - `ask-`
  - `disk-`
  - `kiosk-`
  - `whisk-`
  - `risk-`
  - `src/my-task-…/x`
  - `%20task-`
  - `\ntask-`
- Words ending in `sk` keep a letter before `sk-`, so no escape lookbehind applies to them.

## New findings

| ID | Severity | Category | Component | Description | Recommendation | Status |
|----|----------|----------|-----------|-------------|----------------|--------|
| N-001 | low | data-exposure | ravintio-framework | `src/ravintio-framework/scripts/credential-scan.mjs:58`: the lookbehind covers `\n`, `\r`, `\t`, and `\uXXXX` but not `\xHH`. nginx access logs write a quote as `\x22`, and Python and shell traces use the same form. A key after `\x22` or `\x3D` now misses. The pre-feature rule matched it. | Add `\\x[0-9A-Fa-f]{2}` to the lookbehind, and add a suite case for `\x22`. A follow-up patch can carry it. | open |
| N-002 | low | data-exposure | ravintio-framework | `credential-scan.mjs:58`: an ANSI colour code ends in a letter, such as the `m` in ESC `[32m`. A key printed straight after a colour code in a captured terminal or CI log now misses. The pre-feature rule matched it. RAVINTIO commits build logs, so this shape can reach a commit. | Record it under R-001. Optionally add `(?<=\x1b\[[0-9;]*m)` to the lookbehind. Its quantifier sits inside a lookbehind, so time it on long lines first. | open |
| N-003 | informational | data-exposure | ravintio-framework | `credential-scan.mjs:58`: a double percent-encoded delimiter, such as `%253D`, misses. The lookbehind needs `%` three characters before `sk-`. Double encoding is rare outside nested redirect URLs. | Record it under R-001. No rule change. | open |
| N-004 | informational | data-exposure | ravintio-framework | `credential-scan.mjs:58`: the escapes `\b`, `\f`, `\v`, `\0`, `\U00000022`, and a literal `\e` miss. Keys rarely follow these escapes. | None beyond a note under R-001. | accepted |
| N-005 | informational | denial-of-service | ravintio-framework | `credential-scan.mjs:111-113`: one line with a run of key-class characters of about 10 MB makes V8 throw `RangeError: Maximum call stack size exceeded`. The scan then prints `scan could not run: unexpected error` and exits 2, so it fails closed. The pattern before 0000044 and the plain `\b` pattern throw on the same input, so the fix didn't cause this. The fix widens it only to escape contexts the original rule already reached. Runs of 3 MB still test without error. | File a backlog entry to cap the class run, for example `{20,512}`, or to catch the error per line and report the line as held. This re-review edits no other file, so the entry isn't filed here. | open |
| N-006 | informational | usability | ravintio-framework | `credential-scan.mjs:58`: a Windows path segment that starts with `n`, `r`, or `t` then `sk-` reads as an escape. `C:\tsk-` with 20 more key-class characters is one case. `%41sk-` is another. Each now holds the file back. Such names are rare. | None. A held-back file fails safe. | accepted |

## Linearity

`timing2.mjs` ran the new pattern, the plain `\b` pattern, and the pre-feature pattern on single 10 MB lines. The inputs repeated `sk-`, `%3Dsk-`, `\u0022sk-`, and `\nsk-`, and runs one character under the floor. They also included floods of `%`, `\u`, and `%AA`. Every input that didn't throw finished within 22 ms. Each lookbehind alternative has a fixed length, and the pattern holds no nested quantifier. Throws on long key-class runs affect all three patterns (N-005).

## Output

- `credential-scan.mjs:225` and `credential-scan.mjs:299` build each report line from `safePath(path)`, the line number, and the rule. The diff doesn't touch either line.
- The probe checked each output for the key and for the last 20 characters of the fixture line. None of the 44 runs printed either one.

## Evidence commands

The scratchpad folder below is `$D`: `/private/tmp/claude-501/-Users-martinmayer-d-ravintio-framework/bb5eec78-c41f-40d9-bc28-25e31ef01df6/scratchpad/rereview`.

1. `git diff 971a43d2..HEAD -- src/`
2. `node $D/probe.mjs $D $PWD/src/ravintio-framework/scripts/credential-scan.mjs` runs 44 fixtures and reports match, clean, and leak for each.
3. `node src/ravintio-framework/scripts/credential-scan.mjs --file ravintio-framework/release.yml` exits 0.
4. `node $D/timing2.mjs 10` times three patterns on 10 MB lines.
5. `node src/ravintio-framework/scripts/credential-scan.mjs --file $D/fx/long.txt` exits 2 with `scan could not run: unexpected error` (N-005).
6. `bash src/ravintio-framework/tests/test-0000037-req-003-credential-scan.sh` and the copy under `tests/regression/` each report 210 passed and 0 failed.
7. `credential-scan.mjs --file` exits 0 on the script, both suite copies, ADR-002, and req-001.

## Risk register cross-reference

| Risk | Status after the fix |
|------|----------------------|
| R-001 | Narrowed. The encoded and escaped delimiters from S-001 now match. N-001 to N-004 remain and are low or informational. S-002 still applies, because gitleaks is absent here and in CI. |
| R-002 | Mitigated. `release.yml` scans clean. |
