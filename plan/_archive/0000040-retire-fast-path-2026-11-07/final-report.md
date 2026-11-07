# Final Report - 0000040-retire-fast-path

## 1. What shipped

Framework 0.38.0 retires Fast Path and the Change Pipeline. Every change now runs the Feature Pipeline.

- **req-001:** routing text in the orchestrator, skills, boot template, and docs names one track.
- **req-002:** the write gates no longer read `plan/.fast-path-scope`. The list survives as `ENFORCEMENT_PATHS`.
- **req-003:** pre-push and both CI files lose the `fix(fast-path):` exemption and gain the source folder rule.
- **req-004:** the track workflows and the change agent are gone, and setup removes installed copies.
- **req-005:** `migrate-0.38.0-retire-fast-path-and-change-pipeline.md` upgrades consumers. A blocked CI edit records `skipped` with the reason `blocked` (R-014).
- **req-006:** a residue guard keeps one track, and it joins the regression pack.
- **req-007:** the living docs and decisions index describe one track.

The changelog is `plan/changelog/0000040-retire-fast-path-2026-11-07.md`.

## 2. Decisions and deviations

The archived `build-log.md` holds 78 `Decision` lines and 25 `Deviation` lines. This part summarises them by phase. The build log holds each line in full.

- **P1 (44 decisions, 1 deviation):** split steps keep all seven requirements whole. The source folder rule reads `product.yml` at base and HEAD and fails closed. Migrations name extra paths on a `**May edit:**` line. The critic loop ran three approaches, and exception item 6 settled the guard rules. Deviation: req-007 also supersedes 0000035 ADR 003.
- **P2 (8 decisions, 1 deviation):** seven ADRs. `ENFORCEMENT_PATHS` survives. Pre-push warns on a missing `origin/main`. Deviation (additive, destructive): you run the scope record delete, and the migrator checks it. You confirmed this at P6.
- **P3 (7 decisions, 19 deviations):** three TDD batches. Subagents write and the orchestrator commits. The orchestrator removed `test-0000033-req-011` with `git rm`. All 19 deviations are additive suite and rule details, listed in `deviation-review.md`.
- **P4 (5 decisions, 2 deviations):** one fix cycle. The manifest prunes skip retired names. The 5.1 job keeps its 10-minute cap. Backlog 0000370 and 0000371.
- **P5 (5 decisions, 1 deviation):** three parallel security reviews. Defect report 001 was denied as altering. You chose option 3 for exception 001. Backlog 0000372 to 0000378.
- **P6 (1 decision, 1 deviation):** three docs agents in one batch. Deviation (additive, process): a docs agent ran `git stash`, which broke the Write-or-Edit rule. Every file came back.
- **P7 (3 decisions):** the residue guard joins the regression pack, and `test-0000040-req-001` stays out. The archive commit kept its scan lists in the session scratchpad after a safety check refused `rm -rf` on a variable.
- **P8 (1 decision):** two files from another session stay uncommitted (part 5).
- **P9 (1 decision):** Option [1], push and raise the PR.

The deviation review classed all 25 lines additive. Exception 001 is the only altering item, and you resolved it.

## 3. Version

`v0.38.0`, pushed. It names `2595f850`, the head that P9 read.

## 4. PR

https://github.com/RAVINTIO/ravintio-framework/pull/76, ready for review.

CI: all passed, 13 of 13 checks on the head that P9 read (`2595f850`). The Windows PowerShell 5.1 job took 2m27s against its 10-minute cap, so backlog 0000380 can close.

## 5. Clean tree

Two files are left over, and this run didn't write either one:

- `plan/backlog/.next-id`
- `plan/backlog/0000362-subagent-task-classifier/entry.md`

Another session wrote both on 2026-11-07. Commit them from that session, or tell me to add them to this PR.

## 6. Exceptions waiting

None. Three exceptions came up, and you resolved each one: P1 item 6, P5 exception 001, and P6 item 1.

Next: the human on the loop reviews and merges the PR.
