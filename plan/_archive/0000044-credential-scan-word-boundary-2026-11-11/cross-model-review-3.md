# Cross-model review 3 - credential-scan-word-boundary

**Feature:** 0000044-credential-scan-word-boundary
**Phase:** end of P6, autonomous run, iteration 3 (last under the loop cap)
**Reviewer model:** claude-fable-5-1 (fresh context)
**Implementer models:** claude-sonnet-5-5 (TDD subagents), claude-opus-5-5 (orchestrator)
**Diff reviewed:** `git diff 4764d2d5..HEAD -- src/ docs/`
**Fix commit checked:** `d382088e docs(0000044): shorten one architecture sentence`
**Rubric:** REJECT-default. APPROVE only when every check holds.

## Verdict

**APPROVE.**

The iteration 2 finding is fixed. Every rubric check holds. The code matches ADR-002 and its Amendment. Both suite copies pass with 210 checks each. No changed file holds matching text. Every added doc sentence is under 25 words, in British English, with no em dash or semicolon. The one open item from iteration 1 is the archive link, which resolves once P7 archives today. Two informational notes follow. Neither blocks.

## Iteration 2 finding

| # | Severity | File | Status | Evidence |
|---|----------|------|--------|----------|
| 1 | low | `docs/architecture-overview.md:554` | fixed | The fourth sentence of the 0.39.3 paragraph is now 24 words. Commit `d382088e` dropped "directly". The paragraph's seven sentences count 9, 8, 18, 24, 14, 10, and 17 words. |

## Iteration 1 findings still open

| # | Severity | File | Status | Evidence |
|---|----------|------|--------|----------|
| 6 | informational | `docs/decisions-index.md:473` | open, as expected | The ADR link targets `plan/_archive/0000044-credential-scan-word-boundary-2026-11-11/adr/`. The folder does not exist yet. Features 0000041 to 0000043 use the same convention, and each link resolved after its P7. Today is 2026-11-11, so the link resolves once P7 archives today. |

Findings 1 to 5 from iteration 1 stayed fixed. I re-read each site in the current diff.

## Rubric results

| Check | Result | Evidence |
|-------|--------|----------|
| 1. Every criterion met or deferred to P7 | holds | Criteria 1, 2, 4, 5, 6, and 7 map to passing suite cases or a file read. Criterion 3 stays deferred to P7 in `coverage-table.md:13` and `verification-report.md:33`. The untracked `release.yml` still scans clean, and it still reads `version: "0.39.2"`, the stale build the report describes. |
| 2. Regex matches ADR-002 and its Amendment | holds | `credential-scan.mjs:59` reads `/(?:\b\|(?<=%[0-9A-Fa-f]{2}\|\\[nrt]\|\\u[0-9A-Fa-f]{4}))sk-[A-Za-z0-9_-]{20,}/`. That is the same text as the Amendment and as req-001. 41 run-time fixtures agreed with the scan and with the ADR pattern on every case. |
| 3. Both suite copies identical and passing | holds | `diff` of the two copies shows only the helper path (line 15) and the pack path (line 17). Each copy exits 0 with 210 passed and 0 failed. |
| 4. No changed file holds matching text | holds | `credential-scan.mjs --file` exits 0 on all 11 changed files and on the untracked `ravintio-framework/release.yml`. |
| 5. Docs accurate and within prose rules | holds | Every new sentence is under 25 words. No em dash, semicolon, banned word, or American spelling in the added text. `risk.md` and `test-coverage.md` write "colour". Every factual claim I checked holds, see below. |
| 6. No other rule or output change | holds | The script diff touches only the `api-secret-key` entry and three comment lines. `NAME_RULES`, the other eight content rules, `safePath`, and both report lines are unchanged. |

## New findings

| # | Severity | File | Line | Finding | Fix |
|---|----------|------|------|---------|-----|
| 1 | informational | `src/ravintio-framework/component.yml` | 247 | The P3 update comment is one 26-word sentence. It is a manifest change note, not a doc artifact, and iterations 1 and 2 scoped check 5 to doc files. It does not block. | Split at "and" if a later feature touches the comment. |
| 2 | informational | `src/ravintio-framework/docs/quirks.md` | 3 | Only the "Last updated" line changed. Re-review N-006, a Windows path segment such as `\tsk-` read as an escape, is not recorded here. No rule requires it. | None required. A later feature may add a quirk entry. |

## Accuracy checks on the added docs

- `test-coverage.md`: "Each copy passes 210 checks" matches both runs. 1 plus 3 negative cases and 11 positive cases match the 15 `wb_` calls. "7 escapes" matches the seven escape prefixes. "179 suites" matches 142 `test-*.sh` feature suites plus 37 regression suites. `run-tests.sh` and `test_setup.sh` are not suites.
- `decisions-index.md`: "Adds 2 ADRs" matches the two files in `plan/current/adr/`. The ADR-002 summary names the same escape set as the pattern and records the P5 amendment.
- `architecture-overview.md`: two `release.yml` hash lines name the vendored risk requirements analysis skill, at lines 634 and 635 of the untracked copy.
- `component-registry.md`: the 0.39.3 sentences name the pattern's escape set and the folder under `external-skills/` as the path. Both match the code.
- `risk.md`: R-001 and N-001 match the security re-review and ADR-002. Backlog 0000435 and 0000437 exist. Entry 0000425 is gone, as the design said.
- `component.yml`: `feature`, `version: "0.39.3"`, and `updatedAt: "2026-11-11"` match the design and the P6 dates.
- `credential-scan.mjs`: the comment names the exact escapes and claims no more than the lookbehind accepts.

## Checks run

1. `git diff 4764d2d5..HEAD -- src/ docs/`, read in full, plus `git show d382088e` for the fix commit.
2. `node probe.mjs` over 41 fixtures built at run time under the scratchpad `xmodel3/fx/` folder. Each fixture ran through `credential-scan.mjs --file` and through the ADR-002 pattern in-process. Expected, scan, and ADR results agreed on every case. No output held the key, the hash, or the fixture tail.
3. Negative fixtures, 16 in all:
   - two hash-line shapes under the vendored risk requirements analysis skill folder
   - `a`, `Z`, `7`, and `_` before the key
   - `\u` with 3 hex digits, `\x22`, `%3`, `%ZZ`, and an ANSI colour code before the key
   - a 19-character key
   - `task-` paths with and without `%20` before them, and `desk-`
4. Positive fixtures, 25 in all:
   - column 1, and a key after prose
   - `=`, `"`, `:`, `/`, `-`, `(`, `,`, `[`, `é`, and `«`
   - `%3D`, `%22`, `%20`, `%3A`, `%3d`, and `a%3D`
   - `\n`, `\r`, `\t`, `"`, `x\n`, and a doubled backslash before `n`
   - an escaped JSON string and a URL-encoded body
5. Linearity: the ADR pattern on a 5.4 MB line of repeated `%3Dsk-` plus a 19-character run took 5 ms.
6. `bash` on both suite copies: exit 0, 210 passed, 0 failed each. `diff` between the copies: lines 15 and 17 only.
7. `credential-scan.mjs --file` on each of the 11 changed files and on the untracked `release.yml`: exit 0 each time.
8. Prose scan of the added lines with a sentence-length script, then a hand count of each sentence in the 0.39.3 architecture paragraph. The scan found no em dash, semicolon, banned word, or American spelling. Every long sentence it flagged is pre-existing text in a rewritten line, except the manifest comment in new finding 1.
9. `deviation-review.md` read in full. The P5 pattern deviation is the logged altering deviation with an exception for the human on the loop (`build-log.md:271`). It is not counted here.
10. Backlog entries 0000435, 0000436, 0000437, and 0000438 exist. Entry 0000425 is gone.
11. `git status`: only the untracked `ravintio-framework/release.yml`, as before this review. `pgrep` shows no scan or probe process left running.

## Notes for P7

- The exception for the P5 pattern deviation waits for the human on the loop. If they accept it, `design.md` lines 22 and 36 need the shipped pattern (Hard Limit 7).
- P7 must archive on 2026-11-11, or the `decisions-index.md` link breaks.
- P7 rebuilds `release.yml` from 0.39.3 sources, scans it, and commits it. That closes criterion 3.
- Re-review N-005, the `RangeError` on a huge single line, predates this feature and has backlog 0000438.
