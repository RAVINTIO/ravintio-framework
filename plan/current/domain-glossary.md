---
title: "Domain Glossary - retire-fast-path"
summary: "Definitions of the terms used in retiring Fast Path and the Change Pipeline."
status: "draft"
version: "0.1.0"
---
# Domain Glossary - retire-fast-path

**Skill:** [spec-agent](../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000040-retire-fast-path
**Version:** 0.1.0

> The ubiquitous language for this feature. Never invent new terms without adding them here.

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Feature Pipeline | The P0 to P9 pipeline. After this feature, it is the only track for every change. | full pipeline | ravintio-framework |
| Fast Path | The retired track that applied a change without a Feature Brief, an execution plan, or ADRs. This feature removes it. | fast-path (retired) | ravintio-framework |
| Change Pipeline | The retired track for targeted changes to existing features, run by `ravintio-change-agent` with the `PC:` prefix. This feature removes it. | change-pipeline (retired) | ravintio-framework |
| scope record | The file `plan/.fast-path-scope`. It listed the paths a Fast Path change could write without a design. After this feature, no gate reads it, and the migration deletes it. | Fast Path scope record | ravintio-framework |
| commit subject exemption | The CI and pre-push rule that skipped the record check for a branch whose commits use the `fix(fast-path):` subject. This feature removes it. | Fast Path exemption | ravintio-framework |
| source folder | `src/`, or the folder of any `component.yml` that `product.yml` lists. A diff that touches one needs a file under `plan/` or `docs/` in the same diff. | | ravintio-framework |
| source folder rule | The CI and pre-push check for source folders. It reads `product.yml` at run time and never scans for manifests. If `product.yml` is absent, it covers `src/` only. | | ravintio-framework |
| vendored pack | The copy of `ravintio-framework/` in a consumer repo. It holds a `component.yml`, but it counts as source only if that repo's `product.yml` lists it. | copied pack | ravintio-framework |
| retired list | A named list in `setup.sh` and `setup.ps1` of installed files that setup removes on every run. It covers the old track commands and the change agent skill. | | ravintio-framework |
| standalone skill | A skill that runs outside the pipeline phases, such as optimise, refresh setup, and retrofit. Triage still routes to these. | | ravintio-framework |
| named path | A path outside `plan/`, `docs/`, and `ravintio-framework/` that a migration lists as one it may edit. The human on the loop confirms each edit, and `src/` is never a named path. | | ravintio-framework |
