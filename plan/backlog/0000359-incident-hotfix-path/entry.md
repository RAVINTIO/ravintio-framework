---
title: "Backlog Entry: 0000359 - design a controlled hotfix path for incidents"
summary: "Design how an incident gets a fast, controlled fix. The path may defer some pipeline steps but never drops the record, the review, or the follow-up."
status: "open"
---
# Backlog Entry: 0000359 - design a controlled hotfix path for incidents

**Source feature:** none (human request)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline, after 0000358
**Related:** 0000286, 0000287, 0000289, 0000330, 0000334, 0000358

---

## Problem

0000358 retires Fast Path. An incident in production may still need a fix faster than a full pipeline run allows. Framework has no route for that today.

A regulated team can't ship an emergency change without control. GAMP 5 and ISO 27001 A.8.32 both expect an emergency change process. That process allows some steps to run after release, but it keeps the record and the approval.

## Suggested Action

Design a hotfix path that starts only from an incident record (0000334). Settle these points at P0:

- **Entry rule.** Only an incident with a set severity can open a hotfix. The Jira issue and incident ID go on the branch and every commit.
- **Steps it keeps.** A failing test that reproduces the incident, P4 Validate, P5 Security on the changed code, and an attributable human approval (0000286) before release.
- **Steps it may defer.** Full specification, ADRs, and full docs. Each deferred step becomes a tracked item with a due date.
- **Scope cap.** A hotfix changes the fewest files that fix the incident. It never touches enforcement paths, schema, or a new component.
- **Follow-up.** A follow-up Change Pipeline run closes the deferred steps. An overdue item blocks the next release.
- **Waiver record.** Each deferred step uses the waiver format from 0000287.
- **Audit trail.** The hotfix writes the same audit events as any run (0000289).
- **Postmortem.** A serious incident links the postmortem from 0000330.

## Wanted outcome

- A hotfix can't start without an incident record.
- A hotfix release carries a test, a security check, and a named human approval.
- Every deferred step has an owner, a due date, and a follow-up run that closes it.
- Tests check the entry rule, the scope cap, and the overdue-item block.

## Open questions

- Which severities may open a hotfix, and who sets them?
- How long may a deferred step stay open before it blocks release?
- Should a regulated profile (0000348) forbid deferring some steps?

## Why Deferred

The owner asked for it on 2026-10-31, during the Zero review. It needs a design, and it depends on 0000334 and 0000358.
