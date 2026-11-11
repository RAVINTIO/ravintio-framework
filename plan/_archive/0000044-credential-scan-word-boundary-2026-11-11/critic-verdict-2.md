# Design-Critic Verdict (iteration 2)
<!-- ravintio-em-dash-allow -->
**Mode:** on
**Mechanical check:** clean, exit 0, with one warning (verbatim output below)

```
  ⚠ req-001-api-secret-key-word-boundary.md: 6 acceptance criteria (aim for 3 — consider splitting the story)
consistency-check: clean
```

**Overall:** APPROVE

## Iteration 1 findings

| # | Status | Evidence |
|---|--------|----------|
| 1 | resolved | `req-001` Dependencies and `execution-plan.md` NFR-003 read "0000037 ADR 001". The mechanical check exits 0. |
| 2 | resolved | `design.md` Constraints now read "0000037 ADR 001" and "0000041 ADR 004". Build log line 92 records the edit as a cosmetic Requirement Change. |
| 3 | resolved | `req-001` adds a column-1 case written without the `rule_case` prefix. AC 2 "Verified by" now names the column-1 case and the `rule_case` space case. Build log line 93 logs the `design.md` suite-list error as `Deviation (P1, unclassified)`, so the pre-P7 assessor and orchestrator own the `design.md` update. |
| 4 | resolved | `req-001` AC 5 and the functional requirements add a colon case. |
| 5 | resolved | `req-001` AC 4 and the functional requirements make each negative case check that the output lacks `api-secret-key`. |
| 6 | resolved | `req-001` functional requirements pin the fixture to two leading spaces, a quoted path, a colon, a space, and a quoted hash. That matches `ravintio-framework/release.yml` line 634. |
| 7 | resolved | `execution-plan.md` Component names the root copy, its `release.yml`, and `./product.yml`, and says no agent writes the root copy. |
| 8 | resolved | `req-001` AC 6 requires `component.yml` to read `0.39.3`. Under `max-component-version`, `product-version.mjs` prints the highest component version. `setup-hook-integration` sits at `0.8.0`, so the check reads the `ravintio-framework` bump. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each `req-001` criterion names an exit code, an output line, a file shape, a `git ls-files` result, or a printed version. AC 1 and AC 4 together pin the negative side. AC 2 and AC 5 together pin the positive side. |
| 2 Traceability | pass | `req-001` **Source:** US-001, the only story in `feature-brief.md` and `design.md`. Brief AC 1 maps to `req-001` AC 1 and AC 4. Brief AC 2 maps to AC 2 and AC 5. Brief AC 3 maps to AC 1. Brief AC 4 maps to AC 3. AC 6 traces to the version in `design.md` Scope. |
| 3 ADRs record real decisions | n/a | P1 review only. This feature has no ADRs. |
| 4 Consequences are honest | n/a | P1 review only. |
| 5 Scope boundaries matter | pass | `scope.md` Out of Scope excludes a `release.yml` allowlist and hand edits to the untracked `release.yml`. Both are shortcuts someone might take to clear the hold-back. |
| 6 Risks are specific and mitigated | pass | `risk-register.md` R-001 to R-004 each name a concrete failure. Each mitigation is an action, such as run-time fixture keys (R-003) and both suite copies in one commit (R-004). |
| 7 NFRs are measurable | pass | `execution-plan.md` NFR-001 to NFR-003 each have a deterministic check: pattern inspection, a `lacks` assertion, and no new import. |
| 8 Internal consistency | pass | The mechanical check is clean. `req-001` matches the `design.md` Rule change for `=`, `"`, `:`, a space, and the line start. The stale `design.md` suite-list phrase carries a logged unclassified deviation, which the protocol routes to the pre-P7 assessor. |
| 9 Split step | pass | `req-001` records "Split step: keep" for six criteria. Build log line 95 holds the matching `Decision (P1)` line and names the reason. Line 90 names the one concern: a scan that skips `sk-` inside a word. Line 94 explains why criteria 1 and 2 stay as written under the ratchet. |

## Findings (severity-ordered)

1. [minor] `req-001`: the functional requirements list a space among the new positive cases. The next bullet says the existing `rule_case` fixture already covers a space. AC 2 "Verified by" cites the existing case. State whether P3 adds a new space case or relies on the existing one, so the test-writer doesn't guess.
2. [minor] `req-001`: the column-1 case skips `rule_case`, so it doesn't inherit the `lacks "$text"` check. `execution-plan.md` NFR-002 says every new case checks that the output lacks the fixture text. Add a functional requirement that the column-1 case runs that check too.
3. [minor] `req-001`: AC 6 verifies the version through `product-version.mjs`, which prints the highest component version. The check holds only while every other component stays below `0.39.3`. A direct read of `src/ravintio-framework/component.yml` would test the criterion as written. This doesn't block, because `setup-hook-integration` sits at `0.8.0`.
