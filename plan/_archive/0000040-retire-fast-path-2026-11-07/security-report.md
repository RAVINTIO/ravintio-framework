# Security Report - retire Fast Path and the Change Pipeline

**Skill:** [security-agent](../../ravintio-framework/skills/ravintio-security-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Version:** 0.38.0

> It is advisory - no code changes are made. All findings require human review before action.

## Summary

**Overall Risk Assessment:** low
**Components Reviewed:** ravintio-framework
**Review Scope:** code review, dependency audit, threat model

Three fresh-context reviewers ran in parallel on 2026-11-06. Each one ran real fixtures in scratch repos:

- **Enforcement hooks:** no finding. Every verdict that changed between `origin/main` and the branch went from allow to block.
- **Pre-push and both CI files:** no injection and no new bypass. The 7 findings are Low or Info, and 4 predate the feature.
- **Setup, the 0.38.0 migration, and the migrator:** setup cleanup held in every escape test. One Medium finding, S-1, and 7 Low findings.

The secrets scan passed on all 120 added or changed files. No dependency manifest changed, and the branch adds no new GitHub Action.

## Findings

| ID | Severity | Category | Component | Description | Recommendation | Status |
|----|----------|----------|-----------|-------------|----------------|--------|
| S-1 | medium | config | ravintio-framework | In a hooked consumer with no design, `gate-write` blocks the migration's **Edit** to `.github/workflows/ravintio.yml`. Step 7 then recorded `applied`, and the exemption stayed. | Record `skipped` with the reason `blocked`, and name the lines to delete by hand. | mitigated (`deaf863f`). The leftover block is accepted as R-014 (exception 001, option 3). |
| S-2 | low | config | ravintio-framework | The migrator says autonomous runs still ask before a named-path edit. `autonomous-run-standards.md` lets only its seven exception items wait. | Reconcile the two rules. | open (backlog 0000377) |
| S-3 | low | config | ravintio-framework | Named-path refusals miss case variants such as `SRC/`, and miss junctions and hard links. | Compare case-folded, normalised paths, and name reparse points. | open (backlog 0000377) |
| S-4 | low | config | ravintio-framework | A refused named path had no outcome, so step 7 recorded `applied` with counts of 0. | Record `skipped` with the reason `refused`. | mitigated (`deaf863f`) |
| S-5 | low | config | ravintio-framework | If `plan` is a link, `rm -- plan/.fast-path-scope` deletes the file in the link's target. | Check that `plan` is not a link before showing `rm`. | mitigated (`deaf863f`) |
| S-6 | low | config | ravintio-framework | A race window exists between `cd -P` and `rm -rf` in `setup.sh` cleanup. | None. The same pattern exists at line 732 and needs a local attacker. | accepted |
| S-7 | low | config | ravintio-framework | `setup.ps1` `Remove-Item -Recurse` may follow a nested junction under PowerShell 5.1. The manifest prune uses `-Path`, which expands wildcards. | Delete reparse points first, and use `-LiteralPath`. | open (backlog 0000375) |
| S-8 | low | config | ravintio-framework | `setup.ps1` refuses a retired path whose parent links inside the project and says it resolves outside. `setup.sh` removes it. | Resolve the parent's real path, or fix the message. | open (backlog 0000376) |
| C-1 | low | injection | ravintio-framework | A source file name with non-ASCII bytes, quotes, or control characters escapes the source folder rule, because git quotes it. Predates the feature. | Use `core.quotePath=false` and `-z`. | open (backlog 0000372) |
| C-2 | low | config | ravintio-framework | A rename out of a source folder escapes the rule. Predates the feature. | Add `--no-renames`. | open (backlog 0000372) |
| C-3 | low | config | ravintio-framework | A path such as `Src/evil.js` doesn't count as source, but lands in `src/` on a case-insensitive checkout. | Compare case-folded paths. | open (backlog 0000372) |
| C-4 | low | config | ravintio-framework | Pre-push checks `HEAD`, not the refs it reads on stdin. CI still catches the push. Predates the feature. | Check each pushed ref. | open (backlog 0000373) |
| C-5 | informational | config | ravintio-framework | CI is safe from an older-`main` branch only while checkout keeps the default merge ref. | Keep the default `actions/checkout` ref. | accepted |
| C-6 | low | config | ravintio-framework | A non-normalised `product.yml` path, such as `svc/./api/component.yml`, fails open with no warning. The base file sits on `main`. | Normalise paths before matching. | open (backlog 0000372, R-005) |
| C-7 | informational | config | ravintio-framework | The `validate-branch` job has no `permissions:` block and keeps the checkout token. It runs only git and awk. Predates the feature. | Add `contents: read` and `persist-credentials: false`. | open (backlog 0000374) |

## Dependency Audit

| Package | Current Version | Known CVEs | Severity | Action Required |
|---------|----------------|------------|----------|----------------|
| none changed | - | none | - | none |

## Threat Model

| Threat | Attack Vector | Affected Component | Likelihood | Impact | Existing Mitigation | Gap |
|--------|--------------|-------------------|------------|--------|--------------------|----|
| Removing the scope code opens `src/` without a design | A planted or stale `plan/.fast-path-scope` | ravintio-framework | low | high | No hook reads the record. Missing, non-regular, and oversize designs block. Six-state comparison with `origin/main` shows only tightening (R-002). | none |
| A commit subject skips a control | A `fix(fast-path):` subject | ravintio-framework | low | high | Pre-push and both CI files lose the exemption. | A hooked consumer keeps it in CI until a human deletes it (S-1, R-014). |
| A branch drops its component to escape the source folder rule | Remove the entry from `product.yml` at HEAD | ravintio-framework | low | medium | The rule reads the union of base and HEAD. Emptying or deleting `product.yml` gave exit 1. | Path-matching gaps C-1 to C-3 and C-6 |
| Setup cleanup deletes outside the project | A linked tool folder or retired name | ravintio-framework | low | high | Cleanup refuses outside parents and removes links, not targets. The manifest prune skips retired names. | S-6, S-7 |
| A migration edits a path it shouldn't | A wide `**May edit:**` line | ravintio-framework | low | medium | Each edit needs confirmation, and `src/` stays closed. `gate-write` still gates the edit (R-010). | S-2, S-3 |

## Recommendations

Ordered by priority (critical first):

1. Accept R-014. A hooked consumer deletes the CI exemption block by hand. The migration names the 14 lines.
2. Fix C-1, C-2, and C-3 together through backlog 0000372, because they share one diff read.
3. Reconcile the migrator's autonomous confirmation with the run standard (S-2, backlog 0000377).
4. Harden `setup.ps1` removal under PowerShell 5.1 (S-7, backlog 0000375).
5. Fix C-4 and C-7 through backlogs 0000373 and 0000374.
