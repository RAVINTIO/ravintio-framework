---
title: "Backlog Entry: 0000308 - make pre-commit blocking and check record content, not presence"
summary: "The pre-commit hook only warns, and every pre-push and CI check tests whether a record file exists, not whether it matches the change. 0000040 removed the fix(fast-path): exemption."
status: "open"
---
# Backlog Entry: 0000308 - make pre-commit blocking and check record content, not presence

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline. It changes enforcement paths, and every change now runs the Feature Pipeline.
**Related:** 0000288, 0000298

---

## Context

A review of RAVINTIO Zero on 2026-10-31 compared how each pack checks a branch before merge. In Framework, a commit subject alone decided which check a branch got. Anyone who wrote the subject could choose the weaker check.

## Problem

Feature 0000040 removed the `fix(fast-path):` exemption from pre-push and both CI files on 2026-11-07. It also replaced the `src/` check with the source folder rule. Two problems remain:

- **Advisory pre-commit.** The pre-commit hook warns but always exits 0 (`hooks/pre-commit`).
- **Presence checks only.** The source folder rule tests whether the diff holds a file under `plan/` or `docs/`. It never tests whether that file's content matches the change.

## Suggested Action

- Decide whether pre-commit should block, and on what. If it stays advisory, say so in the boot file and the hook comment.
- Make the record check look at content. For example, require that the diff touches a requirement, ADR, or changelog file for the component it changes.

## Wanted outcome

A record file with no link to the change can't satisfy the check. Tests check these conditions:

- A diff that touches a source folder and only an unrelated `docs/` file fails CI.
- A diff that touches a source folder and a matching plan or changelog record passes.

## Update 2026-10-31

0000358 retires Fast Path and removes the `fix(fast-path):` exemption from pre-push and CI. That removes the weaker check this entry describes. The advisory pre-commit and the presence-only checks remain. When 0000358 ships, narrow this entry to those two problems.

## Update 2026-11-07

Feature 0000040 shipped the retirement and narrowed this entry to the two remaining problems. The original exemption problem and its suggested actions no longer apply.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. 0000040 scope.md defers the remaining two problems, and it changes enforcement paths outside that scope.
