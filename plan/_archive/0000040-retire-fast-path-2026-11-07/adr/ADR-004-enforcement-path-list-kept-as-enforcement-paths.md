---
title: "ADR 004: Enforcement path list kept as ENFORCEMENT_PATHS"
summary: "path-rules.mjs keeps its enforcement path list, renamed from FAST_PATH_ENFORCEMENT_PATHS to ENFORCEMENT_PATHS. isEnforcementPath keeps its name. The list's scope record role goes, and its permitted-name role stays, so no gate weakens."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - Enforcement path list kept as ENFORCEMENT_PATHS

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Component:** ravintio-framework
**Date:** 2026-11-06

## Context

This ADR answers open question Q-001 in the execution plan. The question asks whether `FAST_PATH_ENFORCEMENT_PATHS` survives the retirement of Fast Path, and under what name.

0000035 ADR 004 created the list in `ravintio-framework/hooks/enforcement/path-rules.mjs` (line 498). `isEnforcementPath` (line 543) matches a path against it. It folds case and NFKC lookalikes, and it reads `**/` entries at any depth. The function has two callers today:

- `scopeVerdict` (line 728) blocks a scope record from admitting an enforcement path. ADR-002 removes the scope record, and req-002 removes `scopeVerdict` with it.
- `isAlwaysPermitted` (line 442) denies the permitted-name shortcut inside an enforcement path (0000036 ADR 003). A name such as `CLAUDE.md` below `ravintio-framework/hooks/` then takes the normal route. With no design, it blocks. With a design, the component-path check judges it.

The second caller does not depend on Fast Path. If the list goes, `isAlwaysPermitted` admits `ravintio-framework/hooks/CLAUDE.md` again in every design state. That write blocks today, so dropping the list breaks NFR-003. It also fails the req-002 criterion that expects a block for that path.

The current name carries the retired track. The req-006 residue guard matches `fast[ _-]?path` without regard to case, so it flags `FAST_PATH_ENFORCEMENT_PATHS` in every live reader. Keeping the old name would need an allowlist entry for each one.

Assumption A-001 says no consumer depends on the constant outside the pack. Setup copies `path-rules.mjs` into a consumer's `.claude/hooks/enforcement/`, so the export exists there. No hook or script in the pack imports the constant from outside `path-rules.mjs`. The other importers take `shown`, `resolveRoot`, `evaluateWrite`, `judgeWrite`, and the path helpers only. Two shipped docs name the constant in prose, `pipeline-reference.md` and `interface-contract.md`. Neither offers it as an interface a consumer may import. The search found no breach of A-001.

## Decision

- **Name:** `path-rules.mjs` renames `FAST_PATH_ENFORCEMENT_PATHS` to `ENFORCEMENT_PATHS`. It stays exported and frozen with `Object.freeze`.
- **Entries:** Every entry stays as it is, old-name reads included. No path leaves the list.
- **Function:** `isEnforcementPath` keeps its name, signature, and matching. After P3 its one caller is `isAlwaysPermitted`. `foldWide` stays because `isEnforcementPath` uses it.
- **Scope record role:** The block that stops a record admitting an enforcement path goes with `scopeVerdict` (ADR-002, req-002). The non-ASCII rule (`NON_ASCII_RE`) guarded record admits only, so it goes too.
- **Permitted-name role:** `isAlwaysPermitted` keeps its `!isEnforcementPath(relPath)` condition unchanged. A permitted file name inside a listed path takes the normal route in every design state.
- **Comment above the list (lines 492 to 497):** P3 rewrites it. The new comment states that a permitted file name inside a listed path gets no shortcut (0000036 ADR 003). It keeps the sentences on entry syntax. It drops the scope record, 0000033 ADR 009, `workflows/fast-path.md`, and the claim that a suite checks the list against that file.
- **CI workflow entry comment (line 524):** P3 rewrites it. `.github/workflows/ravintio.yml` stays on the list because it now carries the source folder rule (ADR-003). The comment names that rule and drops the `fix(fast-path)` commit rule. A suggested form: `// The CI workflow setup installs, which enforces the source folder rule (0000040 ADR 003)`.
- **Other comments:** P3 updates the header export lines (46 and 47) and the doc comment above `isEnforcementPath` (line 539) to the new name. The `evaluateWrite` step 2 comment (line 854) goes with req-002's rewrite of that step.

### Readers that P3 changes

The search covered the repository, less `plan/_archive/` and `plan/changelog/`.

| Reader | Location | Action at P3 |
|--------|----------|--------------|
| `path-rules.mjs` | header lines 46 and 47 | Rename. Line 47 cites the new reason and this ADR. |
| `path-rules.mjs` | comment and constant, lines 492 to 527 | Rename, and rewrite the comment and the line 524 entry comment as above. |
| `path-rules.mjs` | doc comment line 539, `some` call line 546 | Rename. |
| `path-rules.mjs` | `scopeVerdict` line 728, step 2 comment line 854 | Remove with req-002. |
| `test-0000035-req-009-fast-path-enforcement-paths.sh` | header line 4, import and assertions lines 188 to 202 | Rename, or retire under req-002. Most sections plant a scope record. The `fast-path.md` set-equality section goes with req-004. The long s folding check (lines 174 to 181) calls `isEnforcementPath` directly and should survive in some suite. |
| `ravintio-framework/pipeline-reference.md` | line 166 | Rename, under req-007's rewrite of that section. |
| `ravintio-framework/workflows/fast-path.md` | line 16 | None. req-004 deletes the file. |
| `src/setup-hook-integration/docs/interface-contract.md` | line 65 | Rename, and drop the scope record sentence (req-007). |
| `src/setup-hook-integration/docs/quirks.md` | line 71 | Rename (req-007). |
| `src/setup-hook-integration/docs/tech-debt.md` | TD-011, line 64 | Rename (req-007). |
| `docs/architecture-overview.md` | line 299 | None. req-007 deletes the scope record section. req-007 adds a short `ENFORCEMENT_PATHS` section in its place. |
| `docs/architecture-overview.md` | line 552 | Keep the old name. It is a decision record, and it gains `superseded by 0000040 ADR-004` on the same line (req-007). |
| `docs/decisions-index.md` | line 337, the 0000035 ADR 004 entry | Keep the old name. Its status becomes `partly superseded by 0000040 ADR-004` (req-007). |

These readers name `isEnforcementPath` only, so the kept name needs no change:

- `test-0000036-req-009-permitted-names-in-enforcement-paths.sh`, header line 5
- `test-0000039-req-008-emitted-names.sh`, lines 75 to 89. Line 78 asserts that `.github/workflows/ravintio.yml` is an enforcement path, and that stays true.
- `docs/architecture-overview.md` line 368 and `docs/decisions-index.md` line 359

These readers keep the old name as written. req-006 excludes their folders from the residue guard:

- backlog entries 0000130, 0000179, 0000288, 0000293, 0000297, 0000298, and 0000308
- `plan/current/` artifacts, which ship archives

No suite under `ravintio-framework/tests/regression/` names either identifier.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Drop the list and `isEnforcementPath` | Less code, and no retired-track name stays | `isAlwaysPermitted` admits `CLAUDE.md` and `AGENTS.md` inside hook folders again. A write that blocks today would pass. | Breaks NFR-003 and the req-002 first criterion |
| Keep the name `FAST_PATH_ENFORCEMENT_PATHS` | No rename, and no consumer could break | The name points at a retired track. The residue guard needs an allowlist entry for each live reader. | Misleads readers, and grows the allowlist that req-006 keeps closed |
| Rename both the list and the function, for example `PROTECTED_PATHS` and `isProtectedPath` | One new term for both | `isEnforcementPath` holds no retired-track word. Renaming it touches more suites and docs for no gain. | The function name is already correct |
| Keep a deprecated `FAST_PATH_ENFORCEMENT_PATHS` alias beside the new name | Protects any consumer script that imports the old name | Leaves a retired-track name in live code. The search found no such consumer (A-001). | Adds residue to guard against a consumer that the evidence says does not exist |
| Trim the list to entries that `isAlwaysPermitted` can still match | The list states exactly what it guards today | Entries for wiring files and the CI workflow would leave the list. Backlog 0000297 and 0000298 plan to widen the list's use. | Removes coverage that later features build on, and weakens the record of what the gate protects |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | `path-rules.mjs` renames one export and rewrites four comments. One suite renames its import, or req-002 retires it. `pipeline-reference.md` uses the new name. |
| setup-hook-integration | `interface-contract.md`, `quirks.md`, and `tech-debt.md` use the new name. Consumers receive the renamed export at the next setup run. |

## Consequences

**Positive:**
- A permitted file name inside a hook folder still blocks with no design, so the gates stay as strict as before (NFR-003).
- The live code and docs carry no retired-track name for the list, so the residue guard needs no entry for it.
- Backlog entries that build on the list, such as 0000130 and 0000297, still have a list to build on.

**Negative:**
- Most file entries become inert. Their base names are not on `ALWAYS_PERMITTED_FILES`, so `isAlwaysPermitted` never meets them. `.claude/settings.json`, `**/setup.sh`, and `.github/workflows/ravintio.yml` are examples. Only folder entries still change a verdict.
- The 0000035 suite tests the list almost wholly through the scope record. P3 must rebuild direct coverage of the list's matching, or lose it.

**Risks:**
- A consumer script outside the pack imports `FAST_PATH_ENFORCEMENT_PATHS` from the installed copy and fails on upgrade. The search found no such reader, and no shipped doc offers the constant as an interface (A-001).
- A reader sees the CI workflow on the list and assumes the gate guards it in every case. It does so only for a permitted file name, which that path never has.

## Related ADRs

- ADR-002 - depends-on: removing the scope record removes the list's first role.
- ADR-003 - related-to: the source folder rule is why `.github/workflows/ravintio.yml` stays on the list.
- ADR-007 - related-to: the residue guard's `fast[ _-]?path` pattern drives the rename.
- 0000036 ADR 003 (permitted names skip enforcement paths) - depends-on: this is the role the list keeps.
- 0000035 ADR 004 (Fast Path enforcement path list) - partly supersedes.

## Supersedes

- 0000035 ADR 004, partly superseded: the list stays under a new name, and its scope-record role goes.

## Superseded By

- None
