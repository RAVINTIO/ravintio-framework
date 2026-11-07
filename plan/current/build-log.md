---
title: "Build Log - 0000041-pack-source-under-src"
summary: "Working log file maintained by the orchestrator throughout the pipeline run."
---
# Build Log - 0000041-pack-source-under-src

> Created at P0. Appended by the orchestrator at each phase boundary. Survives session changes.

## Header

| Field | Value |
|-------|-------|
| Feature ID | `0000041-pack-source-under-src` |
| Pipeline start | `2026-11-07T12:37:04Z` |
| Tool | `claude-code` |
| Primary model | `claude-opus-5-5` |
| Cheaper model | `sonnet` |
| Run mode | pending |
| Parallel streams | pending |

---

## Phase Log

### P0: Assess & Coach

| Field | Value |
|-------|-------|
| Start | `2026-11-07T12:37:04Z` |
| End | pending |
| Wall-clock | pending |
| Streams | n/a |
| Model tier | primary |
| Skills loaded | ravintio-orchestrator |
| Agents spawned | 0 |
| MCP calls | 0 |
| Parallel task batches | 0 |
| P0 questions asked | pending |
| Brief complete | pending |
| Stack unchanged | pending |
| Notes | P0 runs in the session that shipped 0000040. The human on the loop asked for P0 here and a context reset before P1. |

P0 references loaded: ravintio-framework/skills/ravintio-orchestrator/references/phase-0-assess-and-coach.md, ravintio-framework/skills/ravintio-orchestrator/references/adoption-modes.md
Context reset (step -1): not run. The human on the loop asked to finish P0 in the 0000040 session and reset before P1.
Resume detection: no pending migrations. Step 1a found no framework update, since 0.38.0 is the release this repo shipped in 0000040. Skill drift check exit 0, 20 skills match. plan/current/ empty, no sentinel, no run-mode file.
P0 exchange (pre-flight): Q: PR #76 merged and main matches origin/main at 3197b007, with no open PRs. Create feat/0000041-pack-source-under-src? / A: The human on the loop said "run this now as the next feature". Branch created from main at 3197b007.
P0 exchange (backlog pickup): Q: Fold 0000061, 0000378, 0000136, 0000368, and 0000181 into 0000361, or take the smaller set? / A: "make the run large". All six entries pulled in. Every other entry is left untouched.
Release budget: none, three-story rule
Decision: committed the other session's plan/backlog/.next-id and the 0000362 entry on this branch in be64f10c, as the human on the loop asked.
Human decision (0000361): this repo keeps ravintio-framework/ as a workflow-only working copy with no component.yml. The pack source and its manifest live under src/.
P0 exchange (working copy version): Q: Should the root ravintio-framework/ copy hold the last release, rebuilt from src/ at P7 without component.yml, or rebuild after every pack change? / A: "yes. correct". The root copy holds the last release and refreshes at P7 only. Tests and CI run against src/.
Decision: wrote the session ID to plan/.orchestrator-ack, as the strict-mode banner asked.
P0 exchange (move method): Q: Move the pack with one approved git pass (git mv to src/ravintio-framework, then git checkout v0.38.0 -- ravintio-framework, in one commit), or copy it to src/? / A: "yes". One git pass, approved now as a recorded exception to the Write-or-Edit rule (boot Hard Limit 8), as 0000039 ADR-008 did. Follow-up content edits use Edit.
P0 exchange (pack version record): Q: Should the release script write ravintio-framework/release.yml with version, source commit, build date, and a SHA-256 per file, or version and source commit only? / A: "yes". release.yml carries the file list, and step 1a uses it for file-level detection (0000181). Readers fall back to component.yml for packs before 0.39.0. A new migration offers to remove a leftover ravintio-framework/component.yml in a consumer.
