# Deviation Review

**Feature:** 0000044-credential-scan-word-boundary
**Stage:** pre-P7 deviation review, autonomous run
**Reviewer:** fresh-context reversal assessor, not the agent that made these deviations

| # | Build-log line | Class | Flags | Exception-list item | Evidence |
|---|----------------|-------|-------|---------------------|----------|
| 1 | `Deviation (P1, unclassified): the design's suite list named an existing line-start case. The `rule_case` helper puts each key after `x` and a space, so that case covers a space, not column 1. req-001 adds a column-1 case and a colon case.` (build-log line 93) | additive | none | no | Confirmed: the design lists positive cases for `=`, a quote, and a space "beside the existing line-start case". Its Security line says the rule must still match at the line start and after any non-word character. It also names `:sk-` as a shape that still matches. Changed: the line-start case the design assumed doesn't exist. req-001 adds a column-1 case and a colon case to both suite copies. These two cases test behaviour the design already promised. The problem, the user, the in-scope list, and the out-of-scope list stay the same. |
| 2 | `Deviation (P5, unclassified): the `api-secret-key` rule becomes `/(?:\b\|(?<=%[0-9A-Fa-f]{2}\|\\[nrt]\|\\u[0-9A-Fa-f]{4}))sk-[A-Za-z0-9_-]{20,}/`, not the design's `/\bsk-[A-Za-z0-9_-]{20,}/`. It also matches after a percent escape, `\n`, `\r`, `\t`, or a `\u` escape. req-001 adds criterion 7, and ADR-002 gains an amendment.` (build-log line 229) | altering | none | yes | Confirmed: the design's Rule change bullet fixes the pattern as `/\bsk-[A-Za-z0-9_-]{20,}/`. Its Scalability line describes the new pattern as one zero-width word boundary. Changed: `credential-scan.mjs:58` ships a different pattern with three lookbehind alternatives. The match set grows past the confirmed one. It now holds back a file for shapes such as `C:\tsk-...` and `%41sk-...` (re-review N-006). `design.md` still records the old pattern. The change keeps the problem, the user, and the in-scope item "the `api-secret-key` pattern". It touches no other content rule. It replaces a pattern the human confirmed verbatim, so it is altering by the skill's rule. Mitigating facts: the new match set is a superset of the confirmed one, so it only strengthens detection. `release.yml` still passes. The pattern stays linear (re-review, Linearity). S-001 is closed. |

## Decisions touching data, a schema, or a destructive operation

None. I read every `Decision` line in `plan/current/build-log.md` (lines 87 to 236). None changes a schema or writes to data that another component owns. None drops, deletes, or renames data. The only deletion in this run is the backlog 0000425 folder. The confirmed design approves that deletion, and no Decision line records it.

## Exception list

1. Deviation 2: the human on the loop confirms the escape-aware `api-secret-key` pattern in place of the confirmed `\bsk-` pattern. If they accept it, `design.md` needs its Rule change and Scalability lines updated to match the shipped pattern (Hard Limit 7).
