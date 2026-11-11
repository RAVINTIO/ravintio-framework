# Design-Critic Verdict (P2, iteration 2)
<!-- ravintio-em-dash-allow -->
**Mode:** on
**Mechanical check:** clean, exit 0, with one warning (verbatim output below)

```
  ⚠ req-001-api-secret-key-word-boundary.md: 6 acceptance criteria (aim for 3 — consider splitting the story)
consistency-check: clean
```

**Overall:** APPROVE

Every rubric item has cited evidence. All five iteration 1 findings are resolved. Three new findings are minor wording fixes, and none blocks the gate.

## Iteration 1 findings

| # | Severity | Status | Evidence |
|---|----------|--------|----------|
| 1 | major | resolved | `ADR-001` Alternatives Considered now has two rows: gitleaks for every scan, and an npm secret-scanning package. Each row has a rejection reason. No `package.json` exists under `src/ravintio-framework/`, `ravintio-framework/`, or the repo root, so the stated con holds. |
| 2 | minor | resolved | `ADR-001` Negative now reads that a key glued to an ASCII word character passes every check on a machine without gitleaks. It cites `ADR-002` and R-001. |
| 3 | minor | resolved | `domain-glossary.md` Word character and `ADR-002` Decision both say "ASCII letter" and name `é` as a non-word character. Three other places still say "a letter". See new finding 1. |
| 4 | minor | resolved | `ADR-002` Alternatives Considered adds the fixed-prefix-set row. Its rejection reason names the keys it would miss after `(`, `,`, `[`, and `-`. |
| 5 | minor | resolved | The `req-001` **Skill** link now reads `../../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md`. That path resolves from `plan/current/requirements/`. |

## Grounding checks run

- `src/ravintio-framework/scripts/credential-scan.mjs` line 56 reads `['api-secret-key', /sk-[A-Za-z0-9_-]{20,}/]`. This matches the `ADR-002` Context.
- The new pattern `/\bsk-[A-Za-z0-9_-]{20,}/` matches a 24-character key at column 1 and after `=`, `"`, `:`, a space, `-`, `/`, `(`, and `é`.
- The new pattern skips the key after `x`, `1`, and `_`.
- Both results match `ADR-002` Decision and the `design.md` Rule change.

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each `req-001` criterion names an exit code, a reported rule name, a fixture shape, a `--safe-paths` and `git ls-files` result, or a manifest line. |
| 2 Traceability | pass | `req-001` **Source:** US-001, the only story in `feature-brief.md` and `design.md`. Brief AC 1 to AC 4 map to `req-001` AC 1 to AC 5. AC 6 traces to `design.md` Version and build log line 60. |
| 3 ADRs record real decisions | pass | `ADR-001` names two alternatives with rejection reasons. `ADR-002` names five, each with a rejection reason. No row restates the decision. |
| 4 Consequences are honest | pass | `ADR-002` Negative: a key glued to a word character goes undetected (R-001). `ADR-001` Negative: without gitleaks that key passes every check. Both would let a real key reach a commit. |
| 5 Scope boundaries matter | pass | `scope.md` Out of Scope excludes a `release.yml` allowlist and hand edits to the untracked `release.yml`. Both are shortcuts someone might take. `ADR-002` rejects the allowlist with a reason. |
| 6 Risks are specific and mitigated | pass | `risk-register.md` R-001 to R-004 each name a concrete failure and an action. `ADR-002` Risks names the `sk-` folder case and its effect. |
| 7 NFRs are measurable | pass | `execution-plan.md` NFR-001 to NFR-003 each have a deterministic check: pattern inspection, a `lacks` assertion, and no new import. |
| 8 Internal consistency | pass | `ADR-002` Decision matches `design.md` Rule change and the `req-001` functional requirements. `ADR-001` keeps Node built-ins, as `design.md` Constraints require (0000037 ADR 001). The glossary defines "word character" as ASCII. The looser "a letter" wording in three places reads as that term, so it is imprecise rather than contradictory. See new finding 1. |
| 9 Split step | pass | `req-001` records "Split step: keep" for six criteria, with one concern named. Build log line 95 holds the matching `Decision (P1)` line with a reason. |

## Findings (severity-ordered)

1. [minor] `req-001` Functional Requirements, `ADR-002` Negative, and `risk-register.md` R-001: each still says "a letter, a digit, or `_`". The glossary and `ADR-002` Decision say "an ASCII letter". `req-001` is the file the P3 test-writer reads. If the test-writer reads "a letter" as any letter, it could add an `é` negative case that can never pass. Add a line to `req-001` that says "letter" means an ASCII letter, as the glossary defines it. An added line passes the ratchet. Use "ASCII letter" in `ADR-002` Negative and R-001.
2. [minor] `design.md` Rule change: "A word character is a letter, a digit, or `_`" has the same gap. The design is confirmed, so log it as a known wording gap at the P2 gate rather than editing it.
3. [minor] `ADR-001` Alternatives Considered: the shared gitleaks configuration that iteration 1 suggested isn't listed. Two alternatives meet the rubric, so this is optional. If you add it, a rejection reason could cite `scope.md` Out of Scope, which excludes gitleaks configuration.
