---
title: "Risk Register - 0000040-retire-fast-path"
summary: "Technical, operational, security, and compliance risks for retiring Fast Path and the Change Pipeline."
status: "active"
version: "0.1.0"
---
# Risk Register - 0000040-retire-fast-path

**Skill:** [spec-agent](../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Version:** 0.1.0
**Overall Risk Level:** medium

> Sources: `design.md` Risks and Assumptions, and the P0 Scope Lock flags.

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | A suite that tests the gates or routing still asserts Fast Path or Change Pipeline behaviour, and fails after removal. | high | medium | Each requirement names its suites. P3 rewrites each one test-first, and the residue guard catches the rest (req-006). | open |
| R-002 | security | Removing the scope code weakens a check it shares with the gates, such as link or root resolution. A write that the gate blocked before could then pass. | medium | high | P3 keeps the link and root suites green unchanged. P5 reviews the hook diff. `gate-write` and `shell-write-guard` keep a parity test (req-002). P5: a six-state comparison with `origin/main` showed only allow-to-block changes. | mitigated |
| R-003 | operational | The migration can't match a consumer's edited CI block, or the human on the loop declines the edit. That consumer keeps a commit subject bypass in CI. | medium | medium | The migration names the file and the lines to delete, and records the outcome with its reason, never as success (req-005). | open |
| R-004 | operational | A consumer skips the setup re-run after the upgrade. The old commands and the change agent skill stay installed until setup runs. | medium | low | The migration asks for the re-run. The setup retired list removes the copies on the next run, with or without a manifest (req-004, req-005). | open |
| R-005 | technical | The source folder rule misreads `product.yml`, for example a path with no folder part or a missing file. CI then checks too little or blocks every diff. | medium | medium | CI falls back to `src/` when `product.yml` is absent. Tests cover a listed component, a missing file, and a root-level `component.yml` (req-003). R-011 covers an unreadable base commit. A root-level `component.yml` makes every path outside `plan/` and `docs/` source, so a diff with a record still passes (req-003). | open |
| R-006 | operational | A consumer depends on `FAST_PATH_ENFORCEMENT_PATHS` outside the pack. A script of theirs breaks on upgrade. | medium | medium | ADR-004 keeps the list, renamed `ENFORCEMENT_PATHS`, and keeps `isEnforcementPath`. The changelog names the change. Documented assumption from `design.md`. | open |
| R-007 | operational | A consumer run is mid-way through the Change Pipeline or Fast Path when it upgrades. That run loses its skill. | medium | low | The migration warns and tells the human on the loop to restart on the Feature Pipeline (req-005). Documented assumption from `design.md`. | open |
| R-008 | operational | Removing the Change Pipeline makes small changes slower, because each one runs the full pipeline. | high | low | The owner accepts this as the cost of a full record. | accepted |
| R-009 | compliance | A live document or skill still describes a weaker route after the change. A reader could follow a track that no longer exists. | medium | medium | The residue guard fails on any live reference outside its allowlist (req-006). | open |
| R-011 | technical | The source folder rule reads `product.yml` from the base commit. A shallow clone has no base commit, so the read fails. | low | medium | Both CI files check out with `fetch-depth: 0`. If the base can't be read, the check fails closed and names `fetch-depth: 0`. A shallow-clone fixture tests it (req-003). P5: a `--depth 1` clone gave exit 1 in pre-push and CI. | mitigated |
| R-012 | technical | Pre-push fails closed when it can't read its base, and a consumer repo has no `origin/main`, as in a `master` repo or before the first push. Every push would then block. | medium | high | Pre-push checks nothing and warns when the `origin/main` ref is missing, which keeps today's verdict. It fails closed only on an unreadable merge base. CI runs the rule on every pull request. A fixture covers the missing ref (req-003, ADR-003). Backlog 0000367 covers the hard-coded ref. P5: a missing `origin/main` gave pre-push exit 0 with a warning. | mitigated |
| R-010 | technical | The migrator rule 1 widening lets a migration edit a path outside `plan/`, `docs/`, and `ravintio-framework/`. A later migration could name a wider path than it needs. | low | medium | Each migration names its paths, the human on the loop confirms each edit, and `src/` stays closed (req-005). | open |
| R-014 | security | `gate-write` blocks the 0.38.0 CI edit in a hooked consumer with no design. That consumer's CI then keeps the `fix(fast-path):` exemption. | high | low | The record reads `skipped` with the reason `blocked` and names the 14 lines to delete. The human on the loop accepted this at P5 (exception 001, option 3). | accepted |
| R-013 | operational | The `setup-powershell-51` CI job now runs three `.ps1` passes inside its 10-minute cap. Nobody has timed the req-004 pass on Windows, and the job could time out. | medium | low | The req-004 pass took about 77 seconds on macOS. The P9 check read of the PR shows the real time. Raising the cap needs a change to the 0000037 req-011 suite, which pins it. | open |
