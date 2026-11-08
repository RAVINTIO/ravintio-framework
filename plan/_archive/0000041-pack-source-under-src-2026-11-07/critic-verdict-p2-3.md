# Design-Critic Verdict (P2 iteration 3)
**Mode:** on
**Mechanical check:** clean. `node ravintio-framework/scripts/consistency-check.mjs plan/current` exited 0. Its output, verbatim:

```
  ⚠ req-002-release-script.md: 4 acceptance criteria (aim for 3 — consider splitting the story)
consistency-check: clean
```

<!-- ravintio-em-dash-allow --> The quoted script output above keeps its own dash, verbatim. The recorded keep answer covers the warning (see item 9).

**Overall:** APPROVE

This pass reviews the combined P1 and P2 set: the design, the brief, scope, the execution plan, the risk register, the glossary, req-001 to req-008, and ADR-001 to ADR-009. All five iteration 2 findings are resolved. No critical or major finding remains. Five new minor findings follow. None of them blocks P3 or changes a decision, so the human on the loop can weigh them at the P2 gate.

## Iteration 2 findings

| # | Finding | Status | Evidence |
|---|---------|--------|----------|
| 1 | `product.yml` missing from `## Component Paths` | resolved | `design.md` `## Component Paths` now lists `./product.yml` and `./refresh-ravintio-framework-dir.ps1`. This critic ran `evaluateWrite` from the installed `path-rules.mjs` on each file in the execution plan's `## File ownership` table. `product.yml`, `.gitattributes`, `.gitignore`, `README.md`, `refresh-ravintio-framework-dir.ps1`, `docs/component-registry.md`, `.github/workflows/ravintio.yml`, `src/setup-hook-integration/component.yml`, `src/ravintio-framework/tests/regression/`, and `plan/_migrations/` each returned `allowed: true`. Build log line 204 records the deviation. |
| 2 | Malformed `product.yml` skips Step 5c silently | resolved | req-002 Step 5c item 1 now logs `P7: Step 5c skipped: project kind {output}` and a warning when `src/ravintio-framework/` exists. ADR-003 Negative records the skip. req-002 AC3 gains a sub-bullet for the skip line and the warning. |
| 3 | Recovery rule missing from req-001, Scope Lock not logged as deviated, both-commands state unnamed | resolved | req-001 `### The git pass` holds the three recovery states. ADR-002 names the both-commands state. Build log line 205 logs the deviation from the accepted Scope Lock answer. The brief's `## Scenario Paths` now lists the four accepted paths and marks the change. A new wording gap in the both-commands state follows as finding 1. |
| 4 | No AC check for the Step 7 gate or the malformed `release.yml` stop | resolved | req-002 AC3 gains "The Step 7 line gates on the `project-kind.mjs` output". req-003 AC3 gains the migrator stop on a `release.yml` that breaks the format. |
| 5 | ADR-008 step 1 omits the malformed case | resolved | ADR-008 Steps item 1 now reads "If `release.yml` is missing, breaks the format, or reports a version older than `0.39.0`". |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each AC names an observable outcome and a `Verified by:` mode. Examples: req-001 AC1 (three git checks with exit codes), req-002 AC2 (exit 2 and byte-identical targets per link case), req-003 AC1 (named output lines and exit codes per scratch case), req-005 AC1 (`downstream` with a reason for six named cases), req-007 AC1 (three `SKIP (open run):` lines at exit 0), req-008 AC3 (exit codes for a changed byte, a deleted file, and an added file). |
| 2 Traceability | pass | Each requirement carries a `Source:` of US-001, US-002, or US-003. `execution-plan.md` Functional Requirements Directory maps US-001 to req-001, req-007, and req-008, US-002 to req-002, req-003, req-004, and req-006, and US-003 to req-005. The `design.md` Skill Map lists the same eight files. Each of the brief's seven ACs maps to a requirement. |
| 3 ADRs record real decisions | pass | Every ADR names at least two alternatives with a rejection reason. ADR-001 has two (a Bash script, a YAML library). ADR-002 to ADR-009 have four to six each, for example ADR-003 (sync in place, `rsync` or `git archive`, a CI release job, **Write** and **Edit**, keep `component.yml`). None restates its own decision. |
| 4 Consequences are honest | pass | Every ADR lists a negative that hurts. Examples: ADR-003 (a sanctioned script that deletes a folder tree), ADR-004 (a first-upgrade prompt that means nothing), ADR-005 (the gates permit a root copy **Write** in this run), ADR-007 (a broken `product.yml` runs consumer-only migrations). Finding 4 names one understated count, which doesn't fail the item. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes plausible work: rewriting `plan/_archive/` and released migrations, renaming the consumer runtime path, **Write** or **Edit** to the root copy, unconfirmed removal, and backlog 0000364. |
| 6 Risks specific and mitigated | pass | `risk-register.md` R-001 to R-014 each name a file or mechanism. Each mitigation is an action tied to a requirement, a probe, or a backlog ID, for example R-006 (P1 probe, backlog 0000382), R-008 (req-001 `.gitattributes` lines, checked by AC2), and R-013 (req-006 step 3a). |
| 7 NFRs measurable | pass | `execution-plan.md` NFR-001 to NFR-004 each carry a number or a deterministic check and name the measuring test or CI job. |
| 8 Internal consistency | pass | This critic checked each ADR against the design, the requirements, and the other ADRs. The source-repo signal reads the same in `design.md`, req-005, ADR-007, req-008, and the glossary. The `release.yml` contract reads the same in req-002, ADR-003, and ADR-004. The build order reads the same in the execution plan, ADR-007 point 9, and ADR-009. The P2 deviations at build log lines 202, 204, and 205 match the artifacts they name. Findings 1 to 5 are wording gaps that P3 can resolve from the requirement text. None reverses a decision. |
| 9 Split step | pass | Only req-002 exceeds three criteria (four `- [ ]` lines). Its file holds `Split step: keep`, and `build-log.md` line 112 holds the matching Decision line. The other seven requirements hold three criteria each, with a keep note. |

## Findings (severity-ordered)

- [minor] req-001 and ADR-002: the recovery state "After both commands with no commit" tells P3 to run the AC1 checks on the working tree, then commit. The AC1 checks read commits, not the working tree. `git rev-parse {pass}:src/ravintio-framework` needs the pass commit, and `git diff --quiet v0.38.0 HEAD -- ravintio-framework` reads `HEAD`, which still holds the pre-pass tree. Change the state to "P3 commits, then runs the AC1 checks", as the normal path does. A failed check then reaches the human on the loop under the boot Escalation rule.
- [minor] req-004 and ADR-006 versus build log line 132: this run's P3 uses the installed 0.38.0 codegen agent. Its close-out bumps `ravintio-framework/component.yml`, the root copy that req-001 AC1 and ADR-005 keep byte-identical to `v0.38.0`. Only build log line 132 and one execution plan ownership row say that this run's close-out bumps the `src/` manifests by **Edit** instead. ADR-003 has a `### This run's P7` section for the same kind of gap. Add a matching "This run's P3" note to req-004 or ADR-006. It should say that the installed close-out text doesn't apply in this run, and that the root manifest stays at `0.38.0`.
- [minor] ADR-005 `### How the gates and Hard Limit 8 relate to the root copy`: the ADR says the design lists `ravintio-framework/` "so that P3 can commit the git pass and P7 can stage the rebuilt copy". `gate-write` judges **Write** and **Edit** only. `shell-write-guard` passes git commands (boot Hook Enforcement), and the release script writes through `node`. Neither the pass nor the P7 `git add` needs the entry. The entry's only effect is that the gates permit a root copy **Write**, which ADR-005 records as a negative. Correct the stated reason. Or record why the entry stays, given that dropping it would let `gate-write` enforce the ADR-005 rule in this run.
- [minor] ADR-002 Negative and risk-register R-007 versus req-008 and ADR-009: ADR-002 says "Six suites that set `REPO_ROOT` to the pack's parent need a fix". req-008 counts 38 suites that climb out of the pack. ADR-009 lists 37 suites and six regression copies for P3 to edit. The ADR-002 line understates the edit cost of its own decision. Cite the req-008 count in the ADR-002 negative, and keep R-007 for the `REPO_ROOT` subset.
- [minor] req-003 `### Where the recorded value lives` and ADR-004 Negative: step 1a writes `plan/framework-release.yml`, and orchestrator Hard Limit 7 commits it. In this repo, the first session after the merge runs step 1a on `main`. It finds an own build with a `record:` line and writes the file. A commit there would land on `main`, which only the human on the loop may commit to. Neither text says where that commit lands. State that step 1a commits the record only on a feature branch, or that it waits for the branch the run creates.

No out-of-scope problem turned up, so this pass filed no backlog entry. The existing entries 0000382, 0000383, 0000384, 0000386, 0000387, and 0000391 cover the problems already known.
