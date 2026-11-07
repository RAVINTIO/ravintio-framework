# Design-Critic Verdict (P2 iteration 1)
**Mode:** on
**Mechanical check:** clean. `node ravintio-framework/scripts/consistency-check.mjs plan/current` exited 0. Its output, verbatim:

```
  ⚠ req-002-release-script.md: 4 acceptance criteria (aim for 3 — consider splitting the story)
consistency-check: clean
```

<!-- ravintio-em-dash-allow --> The quoted script output above keeps its own dash, verbatim. The recorded keep answer covers the warning (see item 9).

**Overall:** REJECT

Phase is the P2 gate, so this pass reviews the combined P1 and P2 set: the design, the brief, scope, the execution plan, the risk register, the glossary, req-001 to req-008, and ADR-001 to ADR-009. Item 8 fails on four major contradictions. Every other item passes with cited evidence.

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each AC names an observable outcome and a `Verified by:` mode. Examples: req-001 AC1 (three git checks with exit codes), req-002 AC2 (exit 2 and byte-identical targets per link case), req-003 AC1 (named output line and exit code per case), req-007 AC1 (three `SKIP (open run):` lines at exit 0). |
| 2 Traceability | pass | Each requirement carries a `Source:` of US-001, US-002, or US-003. `execution-plan.md` Functional Requirements Directory maps every story to at least one requirement. `design.md` Skill Map lists the same eight files. The brief's seven ACs each map to a requirement (AC6 to req-004, AC7 to req-006). |
| 3 ADRs record real decisions | pass | Every ADR names at least two alternatives with a rejection reason. ADR-001 has two (Bash script, YAML library). ADR-002 to ADR-009 have four to six each, for example ADR-003 (sync in place, `rsync` or `git archive`, a CI job on `main`, agent writes, keep `component.yml`) and ADR-006 (fixed path, tree scan, fallback on a missing listed path). None restates its own decision. |
| 4 Consequences are honest | pass | Every ADR lists a negative that hurts. Examples: ADR-003 (a sanctioned script that deletes a folder tree, and reviewers read most changes twice), ADR-005 (the gates permit a root copy **Write** in this run), ADR-007 (a broken `product.yml` makes the source repo run consumer-only migrations), ADR-009 (the static-scan case stays red from step 3 to step 7). Finding 10 names one missing consequence, which does not fail the item. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes plausible work: rewriting `plan/_archive/` and released migrations, renaming the consumer runtime path, **Write** or **Edit** to the root copy, unconfirmed removal, and backlog 0000364. |
| 6 Risks specific and mitigated | pass | `risk-register.md` R-001 to R-014 each name a file or mechanism. Each mitigation is an action tied to a requirement, a probe, or a backlog ID, for example R-008 (req-001 `.gitattributes` lines, checked by AC2) and R-013 (req-006 step 3a). |
| 7 NFRs measurable | pass | `execution-plan.md` NFR-001 to NFR-004 each carry a number or a deterministic check and name the measuring test or CI job. |
| 8 Internal consistency | fail | Four contradictions between ADRs and requirements or the plan. See findings 1 to 4. |
| 9 Split step | pass | Only req-002 exceeds three criteria (four `- [ ]` lines). Its file holds `Split step: keep` and `build-log.md` holds "Decision (P1): split step for req-002: keep / reason: one concern, a release copy a consumer can trust". The other seven requirements hold three criteria each, with a keep note and a matching Decision line. |

## Findings (severity-ordered)

- [major] ADR-003 and req-002: ADR-003 `## Consequences` Risks says "The two work folders are not in `.gitignore`." req-002 `### Write boundary` now says "`.gitignore` lists `.ravintio-framework-build/` and `.ravintio-framework-previous/` (P2 decision, ADR-003)", and the P2 build-log Decision line adds it. The ADR cites itself as the source of a rule its own text denies. Also, `execution-plan.md` `## File ownership` has no `.gitignore` row, and no req-002 AC checks the two lines. Rewrite the ADR-003 risk to match, add a `.gitignore` row owned by req-002, and add the check to req-002 AC2 or AC3.
- [major] ADR-005 and execution-plan.md: ADR-005 assigns the root copy, `release.yml` included, to `build-release.mjs`, and its Affected Components row says the `ravintio-framework` component "doesn't own the root copy that its release script builds". It also rejects "The `ravintio-framework` component owns both copies". `execution-plan.md` `## Data Model Summary` lists `ravintio-framework/release.yml` with Owner Component `ravintio-framework`. Change that row's owner to the release script, as ADR-005, `design.md` Data ownership, and the brief's Data Ownership table state.
- [major] req-002, req-004, and ADR-007: req-002 adds a ship Step 7 line, `if [ -f src/ravintio-framework/component.yml ]; then git add -A -- ravintio-framework/; fi`. That line has two faults. First, it tests the source repo by one fact, file presence. ADR-007 rejects that test ("Detect the source repo by the presence of `src/ravintio-framework/` alone"), and it says one script owns the signal. Step 5c item 1 already uses `project-kind.mjs`. Second, the line holds the text `ravintio-framework/component.yml`. req-004 AC3 says "No line of the ship `SKILL.md` names `ravintio-framework/component.yml`", and req-004's edit lands after req-002's in the same file. A plain `grep` in the req-004 suite then fails on req-002's line. Gate Step 7 on the `project-kind.mjs` result from Step 5c. Then state in req-004 AC3 whether a `src/` path counts as a match.
- [major] ADR-002 and req-001: ADR-002 says "The exception covers these two commands only". The next paragraph says "If the pass stops partway, P3 resets the working tree to the last commit and repeats the pass." That reset is a third git command that rewrites the working tree, and it discards uncommitted work. req-001 names only the two commands, and the build log's P2 Decision line repeats both claims. Either name the exact recovery command as part of the P0-approved exception, or make recovery stop and ask the human on the loop.
- [minor] ADR-006 and req-004: ADR-006 sets four close-out rules that req-004 and its AC2 lack. The four rules follow.
  - The deeper folder wins when two component folders hold a file.
  - A listed `product.yml` path with no file stops the run.
  - A changed file is one that differs from the `HEAD` that P3 began at.
  - A manifest whose `feature` already holds the current ID gets no second bump.
  The test-writer works from the requirement's ACs, so P3 may leave these rules untested. Add them to req-004 `### The codegen close-out` and to AC2 as sub-bullets.
- [minor] design.md, req-006, ADR-005, and ADR-008: the `design.md` Security line says "The consumer migration removes `ravintio-framework/component.yml` only after the human on the loop confirms". The Consumer migration line says "one confirmed edit". req-006 step 5, ADR-005, and ADR-008 say the migrator never deletes the file and the human on the loop runs `rm`. Hard Limit 7 asks for the design to match. Add a P1 deviation note that names req-006, as the design does for req-002 and req-005.
- [minor] req-003, req-006, and ADR-004: ADR-004 says "No reader falls back to `component.yml`" when `release.yml` exists but breaks the format. req-003 states that rule for `release-check.mjs` only. The migrator `framework-version` rule in req-003 covers only an absent `release.yml`. req-006 step 1 covers only an absent file or an older version. Neither says what happens with a malformed `release.yml`. State that both stop, report, and record nothing.
- [minor] ADR-001 and ADR-004: ADR-001 Risks says "A reader that misreads `release.yml` falls back to `component.yml` silently." ADR-004 and req-003 rule that out with exit 2 and no fallback. Restate the ADR-001 risk as a reader that rejects a valid file, or as a reader that drifts from the writer's format.
- [minor] req-008, execution-plan.md, and ADR-009: req-008 Dependencies says the rest of the req-005 suite moves onto the resolver "once req-008 lands". The build order step 6, req-005 `### Tests`, ADR-007 point 9, and ADR-009 Build order item 2 place that move at step 6. req-008 AC1 lands at step 3 and the requirement closes at step 7, so "once req-008 lands" names neither. Reword it to "at build order step 6".
- [minor] ADR-004: its Context says a consumer's `docs/about.md` "holds the consumer's own product version, not the framework version". It then keeps that file as the first-upgrade comparator. No consequence states the result. A consumer on its first upgrade sees a prompt for a version mismatch that means nothing. If the two versions match by chance and the files match, step 1a writes the trusted record without confirmation. Record both effects as negatives, or state why the first-upgrade case accepts them.

No out-of-scope problem turned up, so this pass filed no backlog entry. The existing entries 0000382, 0000383, 0000384, 0000386, 0000387, and 0000391 cover the problems already known.
