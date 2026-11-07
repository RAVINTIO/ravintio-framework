# Design-Critic Verdict (P2 iteration 2)
**Mode:** on
**Mechanical check:** clean. `node ravintio-framework/scripts/consistency-check.mjs plan/current` exited 0. Its output, verbatim:

```
  ⚠ req-002-release-script.md: 4 acceptance criteria (aim for 3 — consider splitting the story)
consistency-check: clean
```

<!-- ravintio-em-dash-allow --> The quoted script output above keeps its own dash, verbatim. The recorded keep answer covers the warning (see item 9).

**Overall:** REJECT

This pass reviews the combined P1 and P2 set: the design, the brief, scope, the execution plan, the risk register, the glossary, req-001 to req-008, and ADR-001 to ADR-009. All ten iteration 1 findings are resolved. Item 8 fails on one new major finding: the design's `## Component Paths` doesn't cover `product.yml`, so `gate-write` blocks the req-001 edit at build order step 1. Four new minor findings follow.

## Iteration 1 findings

| # | Finding | Status | Evidence |
|---|---------|--------|----------|
| 1 | ADR-003 said `.gitignore` lacks the work folders | resolved | ADR-003 Risks now says "req-002 therefore adds both work folders to `.gitignore`". `execution-plan.md` `## File ownership` holds a `.gitignore` row owned by req-002. req-002 AC2 gains the `.gitignore` sub-bullet. |
| 2 | Execution plan named the component as `release.yml` owner | resolved | `## Data Model Summary` now names "the release script `build-release.mjs`, which owns the root copy (ADR-005)". |
| 3 | Step 7 guard tested file presence and named `ravintio-framework/component.yml` | resolved | req-002 Step 7 now reads `if [ "$(node ravintio-framework/scripts/project-kind.mjs)" = "framework source" ]; ...`. req-004 AC3 gains the sub-bullet that a path ending in `ravintio-framework/component.yml` counts as a match. No AC checks the new guard (new finding 4). |
| 4 | ADR-002 allowed a reset outside the exception | resolved | ADR-002 now runs only the missing checkout, or stops and reports under the boot Escalation rule. It says "The exception never covers a reset". Build log line 199 supersedes line 187. req-001 and the P0 Scope Lock line still differ (new finding 3). |
| 5 | ADR-006 rules missing from req-004 | resolved | req-004 `### The codegen close-out` lists the four rules, and AC2 gains a sub-bullet that names them. |
| 6 | Design delete wording | resolved | The `design.md` Consumer migration line now says the human on the loop runs the delete, marked "P1 deviation, req-006, ADR-008". Build log line 202 records the deviation. |
| 7 | Malformed `release.yml` handling | resolved | req-003 `### The migrator` and req-006 step 1 each say to stop, report the file, and record nothing. |
| 8 | ADR-001 fallback risk | resolved | ADR-001 Risks now names a reader that drifts from the format and rejects a valid file with exit 2. |
| 9 | req-008 timing | resolved | req-008 Dependencies now says "at build order step 6", which matches the execution plan, req-005, ADR-007 point 9, and ADR-009. |
| 10 | ADR-004 first-upgrade effects | resolved | ADR-004 Negative gains both effects, with the reason the first upgrade accepts them. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each AC names an observable outcome and a `Verified by:` mode. Examples: req-001 AC1 (three git checks with exit codes), req-002 AC2 (exit 2 and byte-identical targets per link case, and the two `.gitignore` lines), req-003 AC1 (named output lines and exit codes), req-007 AC1 (three `SKIP (open run):` lines at exit 0). Finding 4 names two P2 fixes with no AC check. That gap doesn't fail the item. |
| 2 Traceability | pass | Each requirement carries a `Source:` of US-001, US-002, or US-003. `execution-plan.md` Functional Requirements Directory maps every story to at least one requirement. `design.md` Skill Map lists the same eight files. The brief's seven ACs each map to a requirement. |
| 3 ADRs record real decisions | pass | Every ADR names at least two alternatives with a rejection reason. ADR-001 has two (Bash script, YAML library). ADR-002 to ADR-009 have four to six each, for example ADR-005 (component owns both copies, setup owns the copy, gate enforcement, silent delete). None restates its own decision. |
| 4 Consequences are honest | pass | Every ADR lists a negative that hurts. Examples: ADR-003 (a sanctioned script that deletes a folder tree), ADR-004 (a meaningless first-upgrade prompt), ADR-005 (the gates permit a root copy **Write** in this run), ADR-007 (a broken `product.yml` runs consumer-only migrations). Finding 2 names one missing effect, which doesn't fail the item. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes plausible work: rewriting `plan/_archive/` and released migrations, renaming the consumer runtime path, **Write** or **Edit** to the root copy, unconfirmed removal, and backlog 0000364. |
| 6 Risks specific and mitigated | pass | `risk-register.md` R-001 to R-014 each name a file or mechanism. Each mitigation is an action tied to a requirement, a probe, or a backlog ID, for example R-008 (req-001 `.gitattributes` lines, checked by AC2) and R-013 (req-006 step 3a). |
| 7 NFRs measurable | pass | `execution-plan.md` NFR-001 to NFR-004 each carry a number or a deterministic check and name the measuring test or CI job. |
| 8 Internal consistency | fail | The design's Component Paths contradict req-001 and the execution plan on `product.yml`. See finding 1. |
| 9 Split step | pass | Only req-002 exceeds three criteria (four `- [ ]` lines). Its file holds `Split step: keep`, and `build-log.md` holds the matching Decision line. The other seven requirements hold three criteria each, with a keep note. |

## Findings (severity-ordered)

- [major] design.md versus req-001 and execution-plan.md: req-001 edits `product.yml`, and the execution plan's build order step 1 lands that edit in its own commit. `product.yml` isn't in `design.md` `## Component Paths`, and it isn't an always-permitted name in `path-rules.mjs`. This critic ran `evaluateWrite(root, "product.yml")` from the installed `path-rules.mjs` against the current design. It returned `allowed: false` with "Path 'product.yml' is not covered by the confirmed design." P3 then blocks at step 1, and every later step waits on it. The 0000039 design listed `./product.yml` for the same reason. Add `./product.yml` to `## Component Paths`, record it as a P2 deviation, and show it to the human on the loop at the P2 gate. `.gitignore`, `.gitattributes`, and `docs/` files pass as always permitted, and `README.md` passes through `./README.md`.
- [minor] req-002: Step 5c item 1 and the new Step 7 line both treat any answer other than `framework source` as "not the source repo". `project-kind.mjs` prints `downstream` at exit 0 for a malformed `product.yml` or a wrong `path:` (req-005). In the source repo, P7 then logs "Step 5c skipped: not the framework source", builds no release copy, and stages nothing. The CI integrity job still passes against the old `release.yml`. ADR-007 records the migrator effect of a broken `product.yml`, but no ADR records this one. Add the effect to ADR-003 or ADR-007 Negative. Or make Step 5c log the `project-kind.mjs` stderr reason, so the human on the loop sees why the build was skipped.
- [minor] req-001, ADR-002, and build-log.md: the ADR-002 recovery rule lives only in the ADR and build log line 199. req-001 `### The git pass` doesn't state it, and P3 works from the requirement. Build log line 61 still holds the human-accepted P0 Scope Lock cross-session path: "an interrupted move resets to the last commit and repeats". ADR-002 now overrides a P0 answer that the human on the loop confirmed, and the log records the change as a Decision, not as a deviation from that answer. ADR-002 also doesn't say what happens when both commands ran and the commit didn't. That state reads as "any other partial state", so P3 stops although only the commit remains. Add the recovery rule to req-001, name the state with both commands done, and log a deviation against the Scope Lock answer. The brief's `## Scenario Paths` section also still says "Empty. The Scope Lock Challenge drafts the four paths at P0", although P0 has run.
- [minor] req-002 and req-003: two iteration 1 fixes have no AC check. req-002 AC3 checks that Step 7 "holds the source-repo `git add -A -- ravintio-framework/` line", but not that the line gates on `project-kind.mjs`. A return to the `-f` file test would still pass. The req-003 AC3 migrator bullet checks the `release.yml` read and the fallback, but not the new stop on a malformed `release.yml`. Add one sub-bullet to each AC.
- [minor] ADR-008: its Steps list summarises req-006, and step 1 still names only a missing or older `release.yml`. It omits the malformed-file stop that req-006 step 1 gained. Add the malformed case to step 1, or say that the list summarises req-006 and defers to it.

No out-of-scope problem turned up, so this pass filed no backlog entry. The existing entries 0000382, 0000383, 0000384, 0000386, 0000387, and 0000391 cover the problems already known.
