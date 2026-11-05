---
title: "Backlog Entry: 0000364 - consumer CI file never receives template changes"
summary: "Setup copies the CI template only when the consumer has no CI file, so later template changes never reach an installed consumer."
status: "open"
---
# Backlog Entry: 0000364 - consumer CI file never receives template changes

**Source feature:** 0000040-retire-fast-path
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-11-05

---

## Problem

`setup.sh` copies `ravintio-framework/hooks/ravintio.yml` to `.github/workflows/ravintio.yml` only when that file is absent (lines 763 to 771). `setup.ps1` follows the same rule. A consumer that installed an earlier pack keeps its old CI file after every later setup run.

Feature 0000040 req-003 changes the template's `validate-branch` check. It adds the source folder rule and stops a `component.yml` counting as a record. The 0.38.0 migration (req-005) removes only the Fast Path exemption block from a consumer's file. So an upgraded consumer keeps the old `src/`-only check, and that check still accepts a `component.yml` alone as a record. Only a fresh install gets the new check.

Each future template change meets the same gap. Backlog 0000311 changes the template's token permissions and meets it too.

## Suggested Action

Decide how a template change reaches an installed consumer. One option is a migration that compares the consumer's `validate-branch` job with the template and offers a confirmed replacement. Another is a check that warns when the installed job differs from the template.

## Why Deferred

The confirmed 0000040 design keeps the copy-if-absent rule and limits the migration to the exemption block. Replacing a consumer-owned CI job needs its own design decision about consumer edits.
