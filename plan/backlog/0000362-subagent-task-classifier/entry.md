---
title: "Backlog Entry: 0000362 - subagent task classifier skill"
summary: "A human-requested change, filed for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000362 - subagent task classifier skill

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-11-07

---

## Problem

The dispatch rules in `ravintio-framework/standards/agent-dispatch-standards.md` assign each skill a model tier by judgement. Nothing looks at the unit of work itself before dispatch, and nothing sets the effort level.

The `ravintio-docs` repo, which runs Zero, hit this gap in run 0000024-explainer-six-tools. All three TDD tracks ran on `opus` instead of `haiku`. Two units were prose rewrites under strict style rules. The third was mostly code and could have run on `haiku`. No rule told the orchestrator to pick a tier for each unit. The source is `plan/_archive/0000024-explainer-six-tools-2026-11-06/build-log.md` in the `ravintio-docs` repo, at lines 91 and 92.

Zero holds the same request as its entry 0000366.

## Suggested Action

Add a classifier skill that the dispatching phase runs before each subagent dispatch.

- It classifies the unit by task class, such as code change, prose rewrite, test writing, review, or mechanical edit.
- It scores signals such as files touched, rules that constrain the output, and the risk of rework.
- It returns the model tier and the effort level for that unit, from a table in the dispatch standards.
- It records the class, tier, and effort for the unit in the build log.
- The build assessment reports rework by class and tier, so later runs can tune the table from evidence.

Entry 0000351 records model identity and AI contribution. Pickup checks whether the classifier's record can feed it.

## Why Deferred

The human asked for it from the `ravintio-docs` repo, where a pack change is out of scope. It needs its own design decision about the class list, the tier table, and how effort maps to each host tool.
