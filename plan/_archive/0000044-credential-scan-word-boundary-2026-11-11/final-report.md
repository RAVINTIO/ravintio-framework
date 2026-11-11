---
title: "Final Report - 0000044-credential-scan-word-boundary"
summary: "The autonomous run's report to the human on the loop."
---
# Final Report - 0000044-credential-scan-word-boundary

## 1. What shipped

The `api-secret-key` credential scan rule no longer matches `sk-` inside a word (backlog 0000425). The rebuilt `ravintio-framework/release.yml` scanned clean and is committed in `508867b4`.

- The rule in `src/ravintio-framework/scripts/credential-scan.mjs` matches `sk-` after a word boundary, or after `%XX`, `\n`, `\r`, `\t`, or `\uXXXX`.
- Both copies of `test-0000037-req-003-credential-scan.sh` gain 4 negative and 11 positive cases, for 210 checks each.
- `ravintio-framework` moves to 0.39.3, and the root release copy is rebuilt.

## 2. Decisions and deviations

Each line below is in the archived `build-log.md`.

**Deviations:**

- P1, additive: req-001 adds a column-1 case and a colon case. The design named an existing line-start case, but that case covers a space.
- P5, altering: the rule uses the escape-aware pattern, not the design's plain word-boundary pattern, to close security finding S-001.

**Decisions:**

- P1: no OpenAPI spec, operational model, SLO definitions, or cost model.
- P1: the manifest stays as it is at P1, and P3 carries the version bump.
- P1: req-001 names the vendored folder in words, because the old rule matched its full name.
- P1: the split step keeps one requirement, at three and then six criteria.
- P1: req-001 keeps criteria 1 and 2 and adds criteria 4 to 6, because the ratchet blocks a rewrite.
- P1: apply three minor critic wording fixes after the loop closed.
- P2: apply two minor critic wording fixes after the loop closed.
- P2: leave the design's "a letter" wording as a known gap.
- P2: ADR-001 lists two alternatives, not three.
- P3: the TDD subagents run as `claude-sonnet-5-5`.
- P3: the 0000037 suite gains a `# Verified by: unit` header line.
- P3: the suite builds the vendored folder name from three string parts.
- P3: a patch bump to 0.39.3, as the design records.
- P3: criterion 6 moves from `unit` to `execution`.
- P4: raise PR #78 before P7, so CI reports before the archive.
- P5: fix S-001 in this run, through the TDD loop.
- P5: defer re-review findings N-001 to N-006 to backlog 0000437 and 0000438.
- P6: leave the two informational iteration 3 cross-model findings.
- P7: promote no regression candidate, because the 0000037 regression copy already holds the new cases.

## 3. Version

`v0.39.3`, tagged on `f001ec06` and pushed.

## 4. PR

[PR #78](https://github.com/RAVINTIO/ravintio-framework/pull/78), in draft because one exception waits.

CI: all passed, 16 of 16, on the head that P9 read, `86db7dc4`. The first P9 read had one red check, macOS shard 2 of 3, at 206 ms against a 200 ms timing limit in the ratchet-check suite (backlog 0000265). A rerun with no code change passed. P4 had one Windows timing flake that a rerun also cleared (backlog 0000275).

## 5. Clean tree

Step 10b committed one leftover, the archived build log, as `86db7dc4`. The scoped check is clean after the CI result commit.

## 6. Exceptions waiting

- **Exception waiting (P6, 2):** the P5 pattern deviation is altering. Accept the escape-aware pattern, or ask for the plain word-boundary pattern, before you merge PR #78.
  - **If you accept it:** the Rule change and Scalability lines in the archived `design.md` need the shipped pattern.
  - **If you refuse it:** the plain pattern reopens security finding S-001.

## Backlog filed this run

- 0000435: CI runs no credential scan or gitleaks.
- 0000436: no rule for underscore-style secret keys.
- 0000437: the rule still misses `\x` escapes, ANSI colour codes, and rarer escapes.
- 0000438: a 10 MB line makes the scan throw and exit 2.

Next: the human on the loop reviews and merges the PR.
