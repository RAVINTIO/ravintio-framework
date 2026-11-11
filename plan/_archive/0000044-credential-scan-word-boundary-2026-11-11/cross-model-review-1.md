# Cross-model review 1 - credential-scan-word-boundary

**Feature:** 0000044-credential-scan-word-boundary
**Phase:** end of P6, autonomous run
**Reviewer model:** claude-fable-5-1 (fresh context)
**Implementer models:** claude-sonnet-5-5 (TDD subagents), claude-opus-5-5 (orchestrator)
**Diff reviewed:** `git diff 4764d2d5..HEAD -- src/ docs/`
**Rubric:** REJECT-default. APPROVE only when every check holds.

## Verdict

**REJECT.**

The code, the tests, and the security trail are sound. Rubric checks 1, 2, 3, 4, and 6 hold. Check 5 fails. Three new doc sentences run past the 25-word limit, and one of them describes a skill as a path. Each fix is a sentence edit in a docs file. No code change is needed.

## Rubric results

| Check | Result | Evidence |
|-------|--------|----------|
| 1. Every criterion met or deferred to P7 | holds | Criteria 1, 2, 4, 5, 6, and 7 map to passing suite cases or a file read. Criterion 3 is deferred to P7 in `coverage-table.md` and `verification-report.md`, with a partial run now on the untracked `release.yml`. |
| 2. Regex matches ADR-002 and its Amendment | holds | `credential-scan.mjs:58` reads `/(?:\b\|(?<=%[0-9A-Fa-f]{2}\|\\[nrt]\|\\u[0-9A-Fa-f]{4}))sk-[A-Za-z0-9_-]{20,}/`, the same text as the Amendment. 28 run-time fixtures in the scratchpad agreed with the scan and with the ADR pattern on every case. |
| 3. Both suite copies identical and passing | holds | `diff` of the two copies shows only the helper path (line 15) and the pack path (line 17). Each copy exits 0 with 210 passed and 0 failed. |
| 4. No changed file holds matching text | holds | `credential-scan.mjs --file` exits 0 on all 11 changed files and on the untracked `ravintio-framework/release.yml`. |
| 5. Docs accurate and within prose rules | fails | Findings 1 to 3 below. No em dash, semicolon, or banned word in the added text. |
| 6. No other rule or output change | holds | The script diff touches only the `api-secret-key` entry and two comment lines. `NAME_RULES`, the other eight content rules, `safePath`, and both report lines are unchanged. |

## Findings

| # | Severity | File | Line | Finding | Fix |
|---|----------|------|------|---------|-----|
| 1 | low | `docs/architecture-overview.md` | 554 | Two sentences run past 25 words. "The old rule matched `sk-` inside a word, so ... at every autonomous P7." is 28 words. "So a key after an ASCII letter ... accepted that trade at P0." is 27 words. | Split each at "so" or "and". |
| 2 | low | `docs/component-registry.md` | 13 | The "Version 0.39.3 (0000044)" sentence is 37 words. It also says "a path such as the vendored risk requirements analysis skill". A skill is not a path. The path is the skill's folder under `external-skills/`. | Split into two sentences. Name the folder, not the skill, as the path. |
| 3 | low | `src/ravintio-framework/docs/test-coverage.md` | 53 | The "4 negative cases" bullet is 26 words and holds a verb, so the sentence limit applies. | Move "and keys after an ASCII letter, a digit, and `_`" to its own bullet. |
| 4 | informational | `src/ravintio-framework/scripts/credential-scan.mjs` | 56 | The comment says the rule matches after "a percent or backslash escape". The lookbehind accepts only `\n`, `\r`, `\t`, and `\uXXXX`. `\xHH` misses (re-review N-001). `docs/component-registry.md:13` repeats the broad wording. `docs/decisions-index.md` and `risk.md` state the exact set. | Name the four escapes in the comment, or write "some backslash escapes". |
| 5 | informational | `src/ravintio-framework/component.yml` | 246 | `updatedAt` reads `2026-11-10`. The P6 docs date the feature `11 Nov 2026`. The P5 rule amendment and the P6 docs landed after the P3 note. | Set `updatedAt` to `2026-11-11` and add a P5 or P6 line to the update comments. |
| 6 | informational | `docs/decisions-index.md` | 476 | The ADR link targets `plan/_archive/0000044-credential-scan-word-boundary-2026-11-11/adr/`, which does not exist until P7 archives the folder. This matches the convention of earlier features. | None now. P7 must archive on 2026-11-11, or the link breaks. |

## Checks run

1. `git diff 4764d2d5..HEAD -- src/ docs/`, read in full.
2. `node $X/probe.mjs` over 28 fixtures built at run time under the scratchpad `xmodel/fx/` folder. Each fixture ran through `credential-scan.mjs --file` and through the ADR-002 pattern in-process. Expected, scan, and ADR results agreed on every case. No output held the key or the fixture tail.
3. Negative fixtures: the real hash-line shape under the vendored risk requirements analysis skill folder, `a`, `7`, and `_` before the key, `\u` with 3 hex digits, `\x22`, `%3`, `%ZZ`, a 19-character key, and `task-` paths with and without `%20` or `\n` before them.
4. Positive fixtures: column 1, `=`, `"`, `:`, space, `/`, `-`, `é`, `%3D`, `%22`, `%20`, `%3A`, `%3d`, `\n`, `\r`, `\t`, and `"`.
5. Linearity: the ADR pattern on a 5 MB line of repeated `%3Dsk-` plus a 19-character run took 6 ms.
6. `bash` on both suite copies: exit 0, 210 passed each. `diff` between the copies: lines 15 and 17 only.
7. `credential-scan.mjs --file` on each of the 11 changed files and on the untracked `release.yml`: exit 0 each time.
8. Backlog entries 0000435, 0000437, and 0000438 exist. Entry 0000425 is gone, as the design said.
9. Prose scan of the added lines: no em dash, no semicolon, no banned word. A sentence-length script found the three new sentences in findings 1 to 3. The other long sentences it flagged are pre-existing text in rewritten lines.
10. `git status`: only the untracked `ravintio-framework/release.yml`, as before this review. No background process remains.

## Notes for the next pass

- The hash-line fixture in both suites matches line 634 of the real `release.yml`: two spaces, a quoted path, a colon, a space, and a quoted 64-character hash.
- Two `# Verified by:` header lines in one suite is an existing repo convention. 18 other suites carry two or three.
- Re-review N-005, the `RangeError` on a huge single line, predates this feature and has backlog 0000438. It is not a reason to reject.
