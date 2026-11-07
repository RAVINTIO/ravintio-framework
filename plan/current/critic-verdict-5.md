# Design-Critic Verdict (iteration 5)
**Mode:** on
**Mechanical check:** clean. `node ravintio-framework/scripts/consistency-check.mjs plan/current` printed one warning, `req-002-release-script.md: 4 acceptance criteria (aim for 3 — consider splitting the story)`, then `consistency-check: clean`, exit 0. The recorded keep answer covers the warning (see item 9). <!-- ravintio-em-dash-allow --> The dash sits in the quoted tool output.
**Overall:** REJECT

Phase is P1. No ADRs exist, so items 3 and 4 are not applicable and do not count against the verdict. This is approach 2, iteration 2. Both iteration 4 findings are resolved. The REJECT rests on one new minor finding in item 8. It has a direct fix.

## Iteration 4 findings

| # | Finding | Status | Evidence |
|---|---------|--------|----------|
| 1 | Build order step 5 closed req-008 AC2 too early, and step 3 said the scan closes AC1 | resolved | `execution-plan.md` Build order step 3 now says the resolver closes AC1 and AC2 closes at step 7. Step 5 closes AC3 only. Step 7 says req-007 moves `test-0000039-req-010-version-bump.sh` onto the resolver, so the scan comes up clean. req-007 Dependencies agree. The build log holds a Decision line that supersedes the earlier AC2 timing line. |
| 2 | req-004 read components from the Components list, while the design and scope said `## Component Paths` and `product.yml` | resolved | `design.md` Engineering Layer (Codegen and ship) now splits the sources the way req-004 does and marks it "P1 wording, req-004". `scope.md` gains the matching sub-bullet. req-004 Functional Requirements and AC2 read the same split. The build log records the Decision. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC names an observable outcome and a `Verified by:` mode. Examples: req-002 AC1 (key order, quoting, sort order, CRLF-as-LF hashes, byte-identical rerun, under 30 seconds), req-005 AC1 (one output per failed condition, exit 0 or 2), req-006 AC2 (six named fixture outcomes), req-008 AC3 (exit code and named file per tampering case). |
| 2 Traceability | pass | Each requirement carries a `Source:` of US-001, US-002, or US-003. `execution-plan.md` Functional Requirements Directory maps every story to a requirement. req-004 and req-006 each name the brief criterion they serve. |
| 3 ADRs record real decisions | not applicable | No ADRs exist at P1. |
| 4 Consequences are honest | not applicable | No ADRs exist at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes plausible work: rewriting `plan/_archive/` and released migrations, renaming the consumer runtime path, any Write or Edit to the root copy, unconfirmed removal of a consumer manifest, and backlog 0000364. Each carries a reason. The new sub-bullet bars edits to `./CLAUDE.md` and `.claude/skills/`. |
| 6 Risks specific and mitigated | pass | `risk-register.md` R-001 to R-014 name files and mechanisms. Each mitigation is an action tied to a requirement, a probe, or a backlog ID. I found no change since iteration 4 and no new generic risk. |
| 7 NFRs measurable | pass | `execution-plan.md` NFR-001 to NFR-004 carry a number or a deterministic check and name the measuring test. |
| 8 Internal consistency | fail | Paths, exit codes, the `release.yml` format, the migrator order, and the req-008 AC timing agree across the set. I checked the claims against the repo: 1,184 tracked pack files, 33 at mode `100755`, and every path segment matches `[A-Za-z0-9._-]+`. Finding 1 below remains. |
| 9 Split step | pass | Only req-002 exceeds three criteria (four). Its file holds `Split step: keep, at four criteria` and the build log holds "Decision (P1): split step for req-002: keep". req-001, 003, 004, 005, 006, 007, and 008 each hold three criteria, a keep note, and a matching Decision line. No later Decision line supersedes a split step answer. |

## Findings (severity-ordered)
- [minor] execution-plan.md Build order versus req-001, req-008, and req-005: the source-repo signal reads `product.yml`, and req-001 edits `product.yml` in its follow-up path fixes at step 4. Step 3 edits about 38 suites onto the resolver first. Until step 4, `RAVINTIO_SOURCE_REPO` reads `no` in this repo. Every suite that adds the `:!ravintio-framework` pathspec only when the signal is `yes` then scans the root copy as well as `src/`. The brand guard and the residue guard anchor their regexes the same way. Those suites can fail for a reason that step 4 removes. The new `test-0000041-req-008-tests-and-ci-from-src.sh` also stays red from step 3 to step 7, because the scan flags the version suite. The plan states the step 7 timing but not that red state. Move req-001's `product.yml` edit ahead of step 3, as a new first line of step 2 or as step 1b. It needs only the `src/ravintio-framework/component.yml` that the pass creates. Also add one sentence to step 3 saying the scan suite is red until step 7 and that P3 judges steps 3 to 6 by the other suites.

No critical or major findings. The existing backlog entries (0000382, 0000383, 0000384, 0000386, 0000387) cover the out-of-scope problems I met, so I filed no new entry.
