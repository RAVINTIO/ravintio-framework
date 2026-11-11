# Cross-model review 2 - credential-scan-word-boundary

**Feature:** 0000044-credential-scan-word-boundary
**Phase:** end of P6, autonomous run, iteration 2
**Reviewer model:** claude-fable-5-1 (fresh context)
**Implementer models:** claude-sonnet-5-5 (TDD subagents), claude-opus-5-5 (orchestrator)
**Diff reviewed:** `git diff 4764d2d5..HEAD -- src/ docs/`
**Fix commit checked:** `372798db docs(0000044): fix cross-model review findings`
**Rubric:** REJECT-default. APPROVE only when every check holds.

## Verdict

**REJECT.**

Every iteration 1 finding is fixed. The code, the tests, and the security trail still hold. Rubric checks 1, 2, 3, 4, and 6 hold. Check 5 fails on one sentence. The iteration 1 fix to `docs/architecture-overview.md` grew one sentence from 22 words to 25 words. The prose rule needs every sentence under 25 words. The fix is a one-word edit. No code change is needed.

## Iteration 1 findings

| # | Severity | File | Status | Evidence |
|---|----------|------|--------|----------|
| 1 | low | `docs/architecture-overview.md:554` | fixed, with a side effect | The 28-word and 27-word sentences are split. Each piece is under 25 words. The sentence that names the escapes is now 25 words. See new finding 1. |
| 2 | low | `docs/component-registry.md:13` | fixed | The 37-word sentence is now two sentences of 23 and 17 words. The second names the folder under `external-skills/`, not the skill, as the path. |
| 3 | low | `src/ravintio-framework/docs/test-coverage.md:53` | fixed | The 26-word bullet is now two bullets. The hash-line case and the three word-character cases each have their own line. |
| 4 | informational | `src/ravintio-framework/scripts/credential-scan.mjs:56` | fixed | The comment names the exact escapes: `%XX`, `\n`, `\r`, `\t`, or `\uXXXX`. It no longer claims every backslash escape. |
| 5 | informational | `src/ravintio-framework/component.yml:246` | fixed | `updatedAt` reads `2026-11-11`. A P5 and P6 comment line records the escape amendment and the seven escape cases. |
| 6 | informational | `docs/decisions-index.md:476` | open, as expected | The ADR link still targets the P7 archive folder dated `2026-11-11`. Today is 2026-11-11, so the link resolves once P7 archives today. |

## Rubric results

| Check | Result | Evidence |
|-------|--------|----------|
| 1. Every criterion met or deferred to P7 | holds | Criteria 1, 2, 4, 5, 6, and 7 map to passing suite cases or a file read. Criterion 3 stays deferred to P7 in `coverage-table.md` and `verification-report.md`. The untracked `release.yml` still scans clean now. |
| 2. Regex matches ADR-002 and its Amendment | holds | `credential-scan.mjs:59` reads `/(?:\b\|(?<=%[0-9A-Fa-f]{2}\|\\[nrt]\|\\u[0-9A-Fa-f]{4}))sk-[A-Za-z0-9_-]{20,}/`, the same text as the Amendment and req-001. 36 run-time fixtures agreed with the scan and with the ADR pattern on every case. |
| 3. Both suite copies identical and passing | holds | `diff` of the two copies shows only the helper path (line 15) and the pack path (line 17). Each copy reports 210 passed and 0 failed. |
| 4. No changed file holds matching text | holds | `credential-scan.mjs --file` exits 0 on all 11 changed files and on the untracked `ravintio-framework/release.yml`. |
| 5. Docs accurate and within prose rules | fails | New finding 1 below. Every factual claim I checked holds. No em dash, semicolon, banned word, or American spelling in the added text. |
| 6. No other rule or output change | holds | The script diff touches only the `api-secret-key` entry and three comment lines. `NAME_RULES`, the other eight content rules, `safePath`, and both report lines are unchanged. |

## New findings

| # | Severity | File | Line | Finding | Fix |
|---|----------|------|------|---------|-----|
| 1 | low | `docs/architecture-overview.md` | 554 | The fourth sentence of the 0.39.3 paragraph is 25 words. It starts "The rule now needs a word boundary" and ends "(0000044 ADR-002)." The rule needs every sentence under 25 words. The iteration 1 version of this sentence was 22 words. The fix added the escape names and pushed it over. | Drop "directly", or move "(0000044 ADR-002)" to the end of the first sentence of the paragraph. |

## Accuracy checks on the added docs

- `test-coverage.md`: "Each copy passes 210 checks" matches both runs. 1 plus 3 negative cases and 11 positive cases match the 15 `wb_` calls. "7 escapes" matches the seven escape prefixes. "179 suites" matches 142 feature suites plus 37 regression suites under `src/ravintio-framework/tests/`.
- `decisions-index.md`: "Adds 2 ADRs" matches `plan/current/adr/`. The ADR-002 summary names the same escape set as the pattern.
- `architecture-overview.md`: two `release.yml` hash lines name the vendored skill, at lines 634 and 635 of the untracked copy.
- `risk.md`: R-001 and N-001 match the security re-review and ADR-002. Backlog 0000435 and 0000437 exist.
- `component.yml`: `feature`, `version: "0.39.3"`, and `updatedAt` match the design and the P6 dates.
- `quirks.md`: only the "Last updated" line changed. No other pack doc names the old pattern.

## Checks run

1. `git diff 4764d2d5..HEAD -- src/ docs/`, read in full, plus `git show 372798db` for the fix commit.
2. `node $X/probe.mjs` over 36 fixtures built at run time under the scratchpad `xmodel2/fx/` folder. Each fixture ran through `credential-scan.mjs --file` and through the ADR-002 pattern in-process. Expected, scan, and ADR results agreed on every case. No output held the key, the hash, or the fixture tail.
3. Negative fixtures, 15 in all:
   - two hash-line shapes under the vendored risk requirements analysis skill folder
   - `a`, `Z`, `7`, and `_` before the key
   - `\u` with 3 hex digits, `\x22`, `%3`, and `%ZZ` before the key
   - a 19-character key
   - `task-` paths with and without `%20` or `\n` before them, and `desk-`
4. Positive fixtures, 21 in all:
   - column 1, and a key after prose
   - `=`, `"`, `:`, space, `/`, `-`, `(`, `,`, and `é`
   - `%3D`, `%22`, `%20`, `%3A`, and `%3d`
   - `\n`, `\r`, `\t`, `"`, and `«`
5. Linearity: the ADR pattern on a 5.4 MB line of repeated `%3Dsk-` plus a 19-character run took 6 ms.
6. `bash` on both suite copies: 210 passed, 0 failed each. `diff` between the copies: lines 15 and 17 only.
7. `credential-scan.mjs --file` on each of the 11 changed files and on the untracked `release.yml`: exit 0 each time.
8. Prose scan of the added lines with a sentence-length script, then a hand count of each new sentence in the architecture paragraph. The scan found no em dash, semicolon, banned word, or American spelling. It flagged one new 25-word sentence. The other long sentences it flagged are pre-existing text in rewritten lines.
9. Backlog entries 0000435, 0000436, 0000437, and 0000438 exist. Entry 0000425 is gone, as the design said.
10. `git status`: only the untracked `ravintio-framework/release.yml`, as before this review. No background process remains.

## Notes for the next pass

- The pattern deviation from `design.md` is a logged altering deviation with an exception waiting for the human on the loop (`build-log.md:271`). It is not a finding here.
- The untracked `release.yml` still reads `version: "0.39.2"`. It is the stale build the verification report describes. P7 rebuilds it.
- Re-review N-005, the `RangeError` on a huge single line, predates this feature and has backlog 0000438. It is not a reason to reject.
- Re-review N-006, a Windows path segment such as `\tsk-` read as an escape, is accepted. `quirks.md` could record it, but no rule requires that.
