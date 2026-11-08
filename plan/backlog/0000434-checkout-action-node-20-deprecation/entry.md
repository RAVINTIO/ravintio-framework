---
title: "Backlog Entry: 0000434 - Checkout action runs on deprecated Node.js 20"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000434 - Checkout action runs on deprecated Node.js 20

> Path: `plan/backlog/{id}-{slug}/entry.md`: one folder per entry, `{id}` zero-padded sequence, `{slug}` kebab-case.

**Source feature:** 0000043-macos-test-job-timeout
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-08

---

## Problem

Every job in `.github/workflows/ravintio.yml` uses `actions/checkout@v4`. PR #77 run `42490766491` annotates each job with this warning:

> Node.js 20 is deprecated. The following actions target Node.js 20 but are being forced to run on Node.js 24: actions/checkout@v4.

The jobs pass today. The consumer copy, `ravintio-framework/hooks/ravintio.yml`, may use the same action.

## Suggested Action

Move to a checkout release that targets Node.js 24, in the repository workflow and the consumer copy. Pin it the way backlog 0000218 suggests for the other actions.

## Why Deferred

0000043 changes the `test-suite` matrix and timing steps only. An action upgrade touches every job and the consumer copy, so it needs its own run.
