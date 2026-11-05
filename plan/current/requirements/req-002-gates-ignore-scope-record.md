---
title: "Requirement: req-002 - gates-ignore-scope-record"
summary: "The write gates and the ratchet stop reading plan/.fast-path-scope, so with no design every write outside the permitted paths blocks."
status: "draft"
version: "0.1.0"
---
# Requirement: req-002 - gates-ignore-scope-record

**Skill:** [spec-agent](../../../ravintio-framework/skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Source:** US-002
**Priority:** must-have

## User Story

As a human on the loop, I rely on the write gates to admit nothing on a Fast Path basis, so that no scope record can skip a control.

## Functional Requirements

### Gate behaviour
- With no confirmed design, `gate-write` blocks with exit 2 every write outside `plan/`, `docs/`, and the always-permitted file names. The block reason is the no-design reason alone.
- A file at `plan/.fast-path-scope` changes no verdict, whether it is current, stale, invalid, oversize, a folder, or a link. Each gate gives the same exit code and the same output with the file present as with it absent.
- A missing `design.md`, a non-regular `design.md`, and an oversize `design.md` each take the no-design route. The non-regular and oversize blocks keep their extra line (0000036 ADR-002).
- An always-permitted file name inside an enforcement path still blocks with no design (0000036 ADR-003). Removing the scope record must not reopen that shortcut.
- No gate prints a `Fast Path: admitted` notice, and no block reason names the scope record, Fast Path, or the Change Pipeline.
- `shell-write-guard` judges every shell writer through `evaluateWrite`, as it does today, so its verdicts match `gate-write` for the same target (parity).
- `ratchet-check` reads no scope record today. Its verdicts and output stay the same with or without the file.

### Code that reads the scope record
These are the code paths in `ravintio-framework/hooks/enforcement/` that read or serve the scope record. P3 removes each one, or reduces it to the no-design route.

- `path-rules.mjs`, scope record block (0000035 ADR-002 and ADR-003):
  - `FAST_PATH_SCOPE_FILE`, `SCOPE_MAX_BYTES`, `SCOPE_MAX_PATHS`, and `SCOPE_PATH_RE`.
  - `validScopePath` and `parseScopeRecord`, the record grammar.
  - `readGitState` and its helpers, which check record freshness against the branch and HEAD: `readCapped`, `validBranch`, `BRANCH_RE`, `HEAD_RE`, `REF_RE`, `DETACHED`, `GIT_FILE_MAX_BYTES`, and `PACKED_REFS_MAX_BYTES`. The scope record is their only caller.
  - `scopeCache`, `loadScope`, and `readScope`.
  - `scopeVerdict`, which `evaluateWrite` calls for a missing, non-regular, or oversize `design.md`. It holds the enforcement-path block, the ignored-record block, the non-ASCII block (`NON_ASCII_RE`), the admit notice, and the not-listed block.
  - The `notice` key in `evaluateWrite` and the notice merge in `judgeWrite` (G-N2).
  - The header comment lines that name `plan/.fast-path-scope`, `parseScopeRecord`, and `readGitState`, and the step 2 comment on `evaluateWrite`.
- `gate-write.mjs`: the `result.notice` write to stderr and its comment.
- `shell-write-guard.mjs`: the `notices` array in `judgeCommand`, the `result.notice` push, and the `capped(notices, "admitted writes")` write.
- `ratchet-check.mjs`: one comment that cites "the Fast Path notice" for the `shown` cap. It reads no record. It imports `resolveRoot`, `resolveTargetBoth`, `hookCwd`, `norm`, `shown`, and `MAX_PATH_CHARS` from `path-rules.mjs`, and those exports must stay.

### What must not weaken
- `resolveRoot`, `resolveTarget`, `resolveTargetBoth`, `hookCwd`, `unjudgeable`, `shown`, and `norm` keep their behaviour. That covers the link walk, the text-collapsed `..` placement, the 40-hop limit, the planted-marker rule, the deleted-cwd walk, and the long-path cap.
- The sentinel step for `plan/current/` and the component-path step with a design keep their behaviour.

### The enforcement path list (finding for P2)
P2 decides whether `FAST_PATH_ENFORCEMENT_PATHS` survives under a new name. These are its readers today:

- `isEnforcementPath` in `path-rules.mjs`, read by two callers:
  - `scopeVerdict`, which this requirement removes.
  - `isAlwaysPermitted`, which denies the permitted-name shortcut inside an enforcement path (0000036 ADR-003). This reader survives the scope record's removal. If the list goes, a `CLAUDE.md` below `ravintio-framework/hooks/` becomes always permitted again.
- Suites: `test-0000035-req-009-fast-path-enforcement-paths.sh`, `test-0000036-req-009-permitted-names-in-enforcement-paths.sh`, and `test-0000039-req-008-emitted-names.sh`.
- Docs: `workflows/fast-path.md`, `docs/architecture-overview.md`, and `src/setup-hook-integration/docs/` (`interface-contract.md`, `quirks.md`, and `tech-debt.md` TD-011).
- Open backlog entries that build on the list: 0000130, 0000179, 0000288, 0000293, 0000297, 0000298, and 0000308.
- `hooks/pre-push`, `hooks/ravintio.yml`, and `.github/workflows/ravintio.yml` don't read it.

### Related text outside the hooks
- `.gitignore` lines 23 to 25 list `plan/.fast-path-scope` with a comment that cites `workflows/fast-path.md`. Remove the line and its comment, because nothing writes or reads the record any more. req-005 deletes a consumer's leftover file.
- `ravintio-framework/templates/standard-boot.md` "Hook Enforcement" describes the record in the `gate-write` and `shell-write-guard` bullets. Drop those sentences and state that, with no design, `gate-write` blocks every write outside `plan/`, `docs/`, and the permitted names. The root `CLAUDE.md` is generated from this template, and a setup re-run refreshes it. req-001 owns the routing text in the same template.
- `pipeline-reference.md`, `project-operations.md`, and the `docs/` pages that describe the record belong to req-007.

### Suites
Rewrite each suite test-first. Each rewrite fails against the current hooks before P3 changes them.

| Suite (under `ravintio-framework/tests/`) | Action |
|---|---|
| `test-0000035-req-001-fast-path-scope-record.sh` | Retire. Replace it with a req-002 suite for this feature that asserts a record of each kind admits nothing in both gates. `test-0000039-req-005-history-and-split-name-protection.sh` names this file three times, in `SUITES` and twice in `PREFIX_FILES`, and must drop those entries. |
| `test-0000035-req-009-fast-path-enforcement-paths.sh` | Rewrite or retire after the P2 list decision. Its section that matches `fast-path.md` goes with req-004. |
| `test-0000036-req-008-non-regular-design-md.sh` | Rewrite the two scope record sections to expect the no-design block. Keep every non-regular and oversize case. |
| `test-0000036-req-009-permitted-names-in-enforcement-paths.sh` | Rewrite the "current record" section to expect a block. Keep the no-record, design, and prefix sections. |
| `test-0000035-req-003-links-judged-by-real-target.sh` | Rewrite the "under a current scope record" block. It must still prove that the text-collapsed `..` placement blocks `.claude/settings.json`, with no record. |
| `test-0000035-req-005-ratchet-check-shared-root.sh` | Change the forged text `Fast Path: admitted` to a neutral forged line. Keep the forgery checks. |
| `test-0000039-req-008-emitted-names.sh` | Rename its `isEnforcementPath` calls if P2 renames the list. |
| `test-0000039-req-005-history-and-split-name-protection.sh` | Drop the retired suite names from its lists. |

These suites must stay green with no change to their assertions:
- `test-0000035-req-004-root-when-cwd-deleted.sh`
- `test-0000035-req-006-no-planted-root-marker.sh`
- `test-0000032-req-009-shell-guard-path-parity.sh` and its copy in `tests/regression/`
- `test-0000036-req-011-escaped-hook-output.sh`
- `test-gate-write-windows.sh` and `test-gate-write-windows.mjs`, with their copies in `tests/regression/`
- `test-0000017-req-002-ratchet-approve.sh` and its copy in `tests/regression/`

No suite under `ravintio-framework/tests/regression/` asserts scope record behaviour.

- Split step: keep, at three criteria. The one concern is that the gates admit nothing through a scope record. Parity and the unchanged link and root rules are conditions on that one change, not outcomes a reader could ship alone.

## Acceptance Criteria
- [ ] With no design, and with a current, stale, or invalid `plan/.fast-path-scope` in place, `gate-write` and `shell-write-guard` each block a write to `src/a.js`, `README.md`, `ravintio-framework/hooks/enforcement/gate-write.mjs`, and `ravintio-framework/hooks/CLAUDE.md` with exit 2. Each prints the no-design reason and no `Fast Path` text. Each verdict matches the same fixture with no record. The same holds for a non-regular and an oversize `design.md`, each with its extra line. Verified by: integration
- [ ] A source search of `path-rules.mjs`, `gate-write.mjs`, `shell-write-guard.mjs`, and `ratchet-check.mjs` finds no `fast-path-scope`, `FAST_PATH_SCOPE_FILE`, `parseScopeRecord`, `scopeVerdict`, `loadScope`, `readScope`, or `Fast Path: admitted`. `ratchet-check` gives the same exit code and output for a weakening write with and without a record.
  - Verified by: integration - a source search plus a `ratchet-check` fixture run with and without the record
- [ ] The link, `..`, root, permitted-name, and parity suites pass on Linux, macOS, and Windows. The rewritten suites in the table above keep every case that does not use a scope record. Verified by: integration

## Dependencies
- req-001 (one-track-routing) owns the routing text in `templates/standard-boot.md`. This requirement changes only the two hook bullets there.
- req-004 (remove-track-files) deletes `workflows/fast-path.md`, which `test-0000035-req-009` reads.
- req-005 (consumer-migration) deletes a consumer's leftover `plan/.fast-path-scope`.
- req-006 (residue-guard) searches for leftover scope record text.
- req-007 (docs-and-adr-supersede) updates the docs that describe the record, and supersedes 0000035 ADR-002 and ADR-004.
- P2 decides the fate and name of `FAST_PATH_ENFORCEMENT_PATHS`.
