---
title: "Backlog Entry: 0000378 - skip migrations in the framework source repo"
summary: "Resume Detection runs every migration in the framework source repo, which only adds not applicable records. A source-repo check could skip them."
status: "open"
---
# Backlog Entry: 0000378 - skip migrations in the framework source repo

**Source feature:** 0000040-retire-fast-path
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-07

---

## Problem

The framework source repo builds the framework with the framework. Resume Detection step 1 can't tell it from a consumer, so it treats every unrecorded migration as pending here too.

In the source repo, each feature's own change already does what its migration does for consumers. A migration here only adds a `not applicable` record. 0000035 ADR-019 chose to keep those records, and `test-0000035-req-010-migration-records-for-this-repo.sh` checks them. Each consumer-only migration therefore costs the source repo a record and a test update.

The human on the loop asked about this during 0000040 P5: "why do migrations need to run on the core repository?"

## Suggested Action

- Define a source-repo signal that an agent can't plant. For example, compare the `ravintio-framework/component.yml` path with the repo root layout, or read a field from `product.yml`.
- If the signal holds, Resume Detection skips the migration scan and reports that it skipped it.
- Revisit 0000035 ADR-019 and its req-010 suite, which require records in this repo.

## Why Deferred

It reverses a 0000035 decision and changes Resume Detection, outside 0000040's confirmed scope. It fits the "framework component lives in source" direction from 0000040 P0.
