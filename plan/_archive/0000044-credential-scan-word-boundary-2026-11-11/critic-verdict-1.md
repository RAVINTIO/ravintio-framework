# Design-Critic Verdict (iteration 1)
**Mode:** on
**Mechanical check:** 4 findings, exit 1

```
consistency-check: 4 finding(s)
  ✖ requirements/req-001-api-secret-key-word-boundary.md: references ADR-001 but no such file exists in adr/
  ✖ design.md: references ADR-001 but no such file exists in adr/
  ✖ design.md: references ADR-004 but no such file exists in adr/
  ✖ execution-plan.md: references ADR-001 but no such file exists in adr/
```

**Overall:** REJECT

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | fail | `req-001` AC 2 cites "the existing line-start case". No such case exists. `rule_case` in `test-0000037-req-003-credential-scan.sh` writes `printf 'x %s\n'`, so the existing `api-secret-key` fixture sits after a space. AC 1 and AC 3 state observable outcomes (exit codes, the `--safe-paths` out-file, `git ls-files`). |
| 2 Traceability | pass | `req-001` **Source:** US-001. US-001 is the only story in `feature-brief.md` and `design.md`. Brief AC 1 to AC 3 map to `req-001` AC 1 and AC 2. Brief AC 4 maps to `req-001` AC 3. |
| 3 ADRs record real decisions | n/a | P1 review only. This feature has no ADRs. |
| 4 Consequences are honest | n/a | P1 review only. |
| 5 Scope boundaries matter | pass | `scope.md` Out of Scope names a `release.yml` allowlist and hand edits to the untracked `release.yml`. Both are plausible shortcuts that someone might build. |
| 6 Risks are specific and mitigated | pass | `risk-register.md` R-001 to R-004 each name a concrete failure. Each mitigation is an action, such as the run-time fixture build (R-003) and both copies in one commit (R-004). |
| 7 NFRs are measurable | pass | `execution-plan.md` NFR-001 to NFR-003 each have a deterministic check: pattern inspection, a `lacks` assertion, and no new import. |
| 8 Internal consistency | fail | The mechanical check fails on cross-feature ADR references. `design.md` and the brief list `:` as a common key prefix, but no artefact adds a colon case. |
| 9 Split step | pass | `req-001` holds three criteria and records "Split step: keep". `build-log.md` holds the matching `Decision (P1): split step for req-001: keep` line. |

## Findings (severity-ordered)

1. [major] `req-001`, `execution-plan.md`: the consistency check exits 1. It reads "0000037 ADR-001" and "0000041 ADR-004" as references to local ADR files. These ADRs belong to archived features, so the references are correct in meaning. Reword them so the checker's `ADR-\d{3}` pattern doesn't fire, such as "0000037 ADR 001". `CLAUDE.md` already uses that form for "0000031 ADR 003".
2. [major] `design.md`: the same check flags ADR-001 and ADR-004 here. The confirmed design is immutable, so the critic can't ask for an edit. This finding recurs on every iteration until a human acts. Escalate it to the human on the loop. They can amend the design wording or rule the finding a checker false positive. Consider filing a backlog entry for cross-feature ADR references in `consistency-check.mjs`.
3. [major] `req-001`: AC 2 and its "Verified by" line rely on a line-start case that doesn't exist. The `rule_case` helper prefixes every fixture with `x `. So the line start, where `\b` is most likely to differ, has no test. The planned "after a space" case also duplicates the existing fixture. Add a functional requirement for a new fixture with `sk-` in column 1. Drop the existing-case claim from "Verified by". The `design.md` suite list repeats the error ("beside the existing line-start case"). Record the deviation in the build log, per Hard Limit 7.
4. [minor] `req-001`: `design.md` (Rule change) lists `:sk-` as still matching. The brief and the design assumption both name a colon as a common prefix. No positive case covers it. Add a colon case beside `=`, the double quote, and the space.
5. [minor] `req-001`: the negative cases verify only exit 0. Also assert that the output lacks `api-secret-key`. Then a later rule that fires on the same fixture can't pass the case for the wrong reason.
6. [minor] `req-001`: the `release.yml` fixture isn't pinned to the real line shape. In the real file, each hash line is a quoted path, a colon, and a quoted hash, with leading spaces. State that the fixture copies that shape, so the test reproduces the observed false match.
7. [minor] `execution-plan.md`: the Component section omits the root `ravintio-framework/` copy, `release.yml`, and `./product.yml`. `design.md` Component Paths lists all three, and `req-001` AC 3 depends on the rebuilt `release.yml`. Name them as release-script outputs that no agent edits.
8. [minor] `req-001`: the 0.39.3 version bump is in scope (`scope.md`, `design.md`), but no criterion or functional requirement covers it. Add a functional requirement that `src/ravintio-framework/component.yml` reads `0.39.3`, or cite where P3 or P7 checks it.
