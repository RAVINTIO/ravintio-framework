# Design-Critic Verdict (iteration 2, P2 loop `design_critic-p2`)
**Mode:** on
**Mechanical check:** clean (`node ravintio-framework/scripts/consistency-check.mjs` printed `consistency-check: clean`, exit 0)
**Overall:** APPROVE

Scope: the combined P1 and P2 set. That covers `design.md`, `feature-brief.md`, `scope.md`, `risk-register.md`, `domain-glossary.md`, `execution-plan.md`, req-001 to req-007, and ADR-001 to ADR-007. The req-006 matching rules sit outside this review's judgement. The human on the loop handed them to the P3 TDD fixtures (req-006 "P3 fixtures settle the matching rules", `loop-state-design_critic.md` Resolution).

## Iteration 1 findings

Each iteration 1 finding is resolved. The revision commit is `73455ee4`.

| # | Iteration 1 finding | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | [major] Pre-push fails closed with no `origin/main` | resolved | req-003 "P2 revision, which governs the base commit" sets the CI and pre-push bases. With no `origin/main` ref, pre-push checks nothing and warns. It fails closed only on an unreadable merge base. ADR-003 "When the read fails" gains the matching row. R-012 and backlog 0000367 record the hard-coded ref. The claim that today's diff finds no files holds: `hooks/pre-push` line 11 runs `git diff` against a missing ref, so `CHANGED_FILES` is empty and line 59 exits 0. |
| 2 | [major] req-004 still names one array | resolved | req-004 gains "P2 revision, which governs". It maps every `RETIRED_TRACK_FILES` and `$RetiredTrackFiles` mention to the two arrays and applies the layout rule to each. The build log Decision line replaces the P1 one-array line. ADR-005 Decision matches. req-006 line 140 already uses the two-array pass fixture. |
| 3 | [major] req-005 and ADR-006 say the migrator deletes the scope record | resolved | req-005 criterion 2 gains a governing line: the migrator asks the human on the loop to run the delete and then finds the path gone. ADR-006 Context step 3 and Affected Components now match ADR-006 Risks. The P2 revision for step 3 governs the old step 3 text. |
| 4 | [minor] req-007 placeholders | resolved | req-007 "P2 revision, which governs every `{n}`" names ADR-002 and ADR-004 for all five entries and the name `ENFORCEMENT_PATHS`. |
| 5 | [minor] req-002 has no rename bullet | resolved | req-002 "P2 answer to Q-001 (ADR-004)" adds the rename, keeps `isEnforcementPath`, and adds `FAST_PATH_ENFORCEMENT_PATHS` to the second criterion's search. |
| 6 | [minor] ADR-003 overstates what the migration delivers | resolved | ADR-003 Negative now says a consumer with an existing CI file never gets the source folder rule, and cites backlog 0000364. |
| 7 | [minor] R-006 still says P2 decides | resolved | R-006 Mitigation cites ADR-004 and the kept `isEnforcementPath`. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each criterion states an observable outcome, such as an exit code, a printed line, a byte-identical file, or a source search. Examples are req-002 criterion 1, req-003 criterion 2, req-004 criterion 2, req-005 criterion 2 with its governing line, and req-007 criterion 2 (`git diff main -- plan/_archive/` prints nothing). Two new P2 behaviours sit only in the functional requirements (findings 1 and 2). |
| 2 Traceability | pass | `feature-brief.md` Features holds three stories, and `design.md` names them US-001 to US-003. Each `Source` field resolves. req-001, req-006, and req-007 trace to US-001. req-002 and req-003 trace to US-002. req-004 and req-005 trace to US-003. Every story has at least two requirements. The `execution-plan.md` Functional Requirements Directory matches. |
| 3 ADRs record real decisions | pass | Each ADR names at least two rejected alternatives with reasons. ADR-001 has 2, ADR-002 has 5 rows, ADR-003 has 6, ADR-004 has 5, ADR-005 has 6, ADR-006 has 5, and ADR-007 has 4. ADR-004's "Drop the list" row gives a concrete reason: `ravintio-framework/hooks/CLAUDE.md` would pass again, which breaks NFR-003. |
| 4 Consequences are honest | pass | Each ADR has a negative that costs something. ADR-002 says a typo fix runs P0 to P9. ADR-003 says a `master` repo gets no pre-push check. ADR-004 says most list entries go inert. ADR-005 says a consumer's edited `fast-path.md` is lost. ADR-006 says the migrator can now edit a consumer CI file. |
| 5 Scope boundaries matter | pass | `scope.md` Out of Scope excludes four things someone could plausibly build. Those are the hotfix path (0000359), the pre-commit checks (0000308), moving the pack under `src/` (0000361), and re-routing the 0000355 rows. |
| 6 Risks are specific and mitigated | pass | R-001 to R-012 each name a concrete failure and an action. R-012 names the `master` repo and first-push cases and the warning-only fallback, with a fixture and backlog 0000367. R-011 names `fetch-depth: 0` and a shallow-clone fixture. |
| 7 NFRs are measurable | pass | `execution-plan.md` NFR-001 to NFR-004 each give a count or a named suite. Those are 0 failures per shard, 0 unallowed matches, 0 newly passing cases, and the req-004 parity suite. |
| 8 Internal consistency | pass | No requirement contradicts an ADR. req-002, req-004, req-005, and req-007 now match ADR-004, ADR-005, ADR-006, and ADR-002 through governing lines. The CI base `origin/${{ github.base_ref }}` is safe, because both CI files trigger on `pull_request` only (`hooks/ravintio.yml` lines 3 to 5). Some older prose drifts from the governing lines (findings 3 and 4). |
| 9 Split step | pass | Every requirement keeps three criteria and a `Split step: keep` note. The build log holds a matching `Decision (P1): split step` line for each one. |

## Findings (severity-ordered)

- [minor] req-003 Acceptance Criteria: the missing-ref case has no criterion. The governing base-commit bullet adds a fixture: with no `origin/main`, pre-push exits 0 and prints the warning. R-012 cites that fixture as the mitigation of a high-impact risk. No criterion names it, so P4 has nothing to verify it against. The shallow-clone fail-closed case from R-011 has the same gap. Fix: add a governing line under criterion 1 for both pre-push cases. Keep them out of criterion 2, because criterion 3 compares pre-push and CI on every criterion 2 fixture, and CI has no missing-ref case.
- [minor] req-005 criterion 2: no case covers a human on the loop who doesn't run the delete. The P2 revision for step 3 states the outcome: the record body names the leftover path, and the outcome doesn't change. No fixture checks it. Fix: add a governing sub-bullet where the fixture leaves `plan/.fast-path-scope` in place. The run then names the path in the record body and records the same outcome.
- [minor] ADR-003 Consequences, Risks, second bullet: it says a failed `git fetch` in pre-push blocks the push. The governing table says otherwise. A failed fetch with a stale `origin/main` still yields a merge base, so nothing blocks. A failed fetch with no `origin/main` takes the new warning row. Only an unreadable merge base blocks. The sentence after the table also still reads "The second and third rows follow req-003", which now points at the wrong rows after the R-012 insert. Fix: limit the risk bullet to an unreadable merge base, and renumber the row references.
- [minor] `domain-glossary.md` "scope record", and `design.md` Security and Migration: each still says the migration deletes the scope record. ADR-002 Decision "Migrate consumers" reads "A consumer upgrade deletes", which a reader can take either way. req-005 now has the human on the loop run the delete. The build log logs this as `Deviation (P2, unclassified)`, but Hard Limit 7 asks that affected artifacts match what gets built. Fix: reword the glossary entry and the ADR-002 bullet to say the human on the loop deletes the file when the migration asks. Classify the deviation so the confirmed-design gate shows the `design.md` change.

No credential appeared in any reviewed file.
