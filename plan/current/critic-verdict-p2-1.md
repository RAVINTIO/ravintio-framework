# Design-Critic Verdict (P2, iteration 1)
<!-- ravintio-em-dash-allow -->
**Mode:** on
**Mechanical check:** clean, exit 0, with one warning (verbatim output below)

```
  ⚠ req-001-api-secret-key-word-boundary.md: 6 acceptance criteria (aim for 3 — consider splitting the story)
consistency-check: clean
```

**Overall:** REJECT

Rubric item 3 fails on `ADR-001`. That ADR names one alternative, and the rubric needs two or more.

## Grounding checks run

- `src/ravintio-framework/scripts/credential-scan.mjs` line 56 reads `['api-secret-key', /sk-[A-Za-z0-9_-]{20,}/]`. This matches the `ADR-002` Context.
- The old pattern matches `ravintio-framework/release.yml` lines 634 and 635. The new pattern `/\bsk-[A-Za-z0-9_-]{20,}/` matches neither line. No other line in that file matches either pattern.
- The new pattern skips `1sk-` and `_sk-` and matches `-sk-`, as `ADR-002` Decision states.
- The new pattern matches `sk-` after a non-ASCII letter such as `é`. JavaScript `\b` without the `u` flag treats only `[A-Za-z0-9_]` as word characters. See finding 3.

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each `req-001` criterion names an exit code, an output line, a fixture shape, a `--safe-paths` and `git ls-files` result, or a manifest line. |
| 2 Traceability | pass | `req-001` **Source:** US-001, the only story in `feature-brief.md` and `design.md`. Brief AC 1 to AC 4 map to `req-001` AC 1 to AC 5. AC 6 traces to the version in `design.md` Scope and build log line 60. |
| 3 ADRs record real decisions | fail | `ADR-002` names four genuine alternatives, each with a rejection reason. `ADR-001` Alternatives Considered holds one row only ("Require gitleaks for every scan"). See finding 1. |
| 4 Consequences are honest | pass | `ADR-002` Negative: a key glued to a letter, a digit, or `_` goes undetected (R-001). `ADR-001` Negative: the regex rules stay the only check without gitleaks. Finding 2 asks to sharpen the second. |
| 5 Scope boundaries matter | pass | `scope.md` Out of Scope excludes a `release.yml` allowlist and hand edits to the untracked `release.yml`. Both are shortcuts someone might take. `ADR-002` rejects the allowlist with a reason, so scope and ADR agree. |
| 6 Risks are specific and mitigated | pass | `risk-register.md` R-001 to R-004 each name a concrete failure and an action. `ADR-002` Risks adds the `sk-` folder case and states the scan holds the file back. |
| 7 NFRs are measurable | pass | `execution-plan.md` NFR-001 to NFR-003 each have a deterministic check: pattern inspection, a `lacks` assertion, and no new import. |
| 8 Internal consistency | pass | `ADR-002` Decision matches `design.md` Rule change and the `req-001` functional requirements. `ADR-001` keeps Node built-ins, which matches the `design.md` constraint (0000037 ADR 001). The stale `design.md` line-start phrase still carries the logged unclassified deviation (build log line 93). |
| 9 Split step | pass | `req-001` records "Split step: keep" for six criteria. Build log line 95 holds the matching `Decision (P1)` line with a reason. |

## Findings (severity-ordered)

1. [major] `ADR-001`: Alternatives Considered names one alternative, so rubric item 3 fails. Add at least one more genuine alternative with a rejection reason. Candidates:
   - Add an npm secret-scanning package as a dev dependency of the scan.
   - Move the content rules into a shared gitleaks configuration that both scanners read.
2. [minor] `ADR-001`: the negative consequence describes the status quo. Tie it to this feature. With no gitleaks, a key glued to a word character now passes every check (R-001).
3. [minor] `domain-glossary.md` (Word character) and `ADR-002` Decision: "a letter" reads as any letter. JavaScript `\b` without the `u` flag counts only ASCII letters, so `sk-` after `é` still matches. The error is on the safe side. State "an ASCII letter" so the P3 test-writer doesn't add a wrong negative case.
4. [minor] `ADR-002`: one plausible alternative is missing. That alternative allows a fixed set of characters before `sk-`, such as the line start, whitespace, `=`, `:`, and a quote. It would also clear the `sk-` folder risk in `ADR-002` Risks. Add it with its rejection reason. A reason could be that it misses keys after characters such as `(` or `,`.
5. [minor] `req-001`: the **Skill** link `../skills/ravintio-spec-agent/SKILL.md` resolves to `plan/current/skills/`, which doesn't exist. The ADRs use `../../../ravintio-framework/skills/...`, which resolves. Use the same form.
