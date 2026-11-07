---
title: "ADR 005: Pack copy data ownership"
summary: "The ravintio-framework component owns every file under src/ravintio-framework/. The release script owns the root ravintio-framework/ copy and its two work folders, and no agent writes the root copy with Write or Edit. Consumers own their copy of ravintio-framework/component.yml. setup-hook-integration owns no pack file."
status: "accepted"
version: "0.1.0"
---
# ADR-005 - Pack copy data ownership

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Component:** ravintio-framework
**Date:** 2026-11-07

## Context

After this feature, the source repo holds the pack twice:

- `src/ravintio-framework/`, the pack source with its `component.yml` (ADR-002, req-001)
- `ravintio-framework/`, the release copy that consumers install, with `release.yml` and no `component.yml` (ADR-003, req-002)

The release script also uses two work folders at the project root, `.ravintio-framework-build/` and `.ravintio-framework-previous/` (req-002, Write boundary). A consumer repo holds one more file of interest. A pack copied over an older one leaves `ravintio-framework/component.yml` beside the new `release.yml` (req-006, risk R-004).

The boot rules say one component owns each piece of data, and no other component writes it. Two copies of one pack make that rule ambiguous. A hand edit to the root copy would ship to every consumer without passing the suites that run against `src/` (US-001, risk R-001).

The design lists `ravintio-framework/` under `## Component Paths`. `gate-write` therefore permits a **Write** or **Edit** to the root copy in this run, and `shell-write-guard` follows it. The gates can't express "listed, but no agent writes it".

## Decision

Assign each copy one owner:

| Data | Owner | Who writes it |
|------|-------|---------------|
| Every file under `src/ravintio-framework/`, `component.yml` included | `ravintio-framework` component | Agents, through **Write** or **Edit** only (boot Hard Limit 8) |
| The root `ravintio-framework/` copy, `release.yml` included | `build-release.mjs` | The release script only, at P7 Step 5c (req-002) |
| `.ravintio-framework-build/` and `.ravintio-framework-previous/` | `build-release.mjs` | The release script only, during a build or a recovery |
| A consumer's `ravintio-framework/component.yml` | The consumer | The human on the loop. The 0.39.0 migration only offers the removal (req-006). |
| `src/setup-hook-integration/component.yml` and `docs/` | `setup-hook-integration` component | Agents, through **Write** or **Edit** |

The rules that follow from the table:

- No agent writes the root copy with **Write** or **Edit**. A fix to a pack file lands in `src/ravintio-framework/`, and the next P7 build carries it to the root.
- The git pass in req-001 writes the root copy once, from `v0.38.0`. It is a recorded exception to Hard Limit 8, approved at P0. After that commit, only the release script writes the root copy.
- This run's P7 runs `node src/ravintio-framework/scripts/build-release.mjs` from `src/`. It is the second recorded exception, because the 0.38.0 ship agent lacks Step 5c (req-002, risk R-003). The script still owns the output.
- `setup-hook-integration` owns no pack file. Its manifest and docs stay at `src/setup-hook-integration/`. Its code paths name `src/ravintio-framework/setup.sh`, `setup.ps1`, and `setup/` (req-001). Those files belong to `ravintio-framework`, and a change to them bumps that manifest. `setup-hook-integration` bumps its own manifest only when its manifest or docs change.
- The 0.39.0 migration never deletes the consumer's file. It shows `rm -- ravintio-framework/component.yml` and records the outcome only after the human on the loop confirms (req-006, steps 4 to 7). It records `skipped` with the reason `declined`, `not removed`, `refused`, or `listed in product.yml`.

### How the gates and Hard Limit 8 relate to the root copy

- **This run.** `## Component Paths` lists `ravintio-framework/` so that P3 can commit the git pass and P7 can stage the rebuilt copy. The gates then permit a **Write** to it. Hard Limit 8, the scope file's Out of Scope list, and Step 5c item 4 forbid one. The rule text guards the root copy, not the gates.
- **Later runs.** A design lists `src/ravintio-framework/` and leaves out the root copy. `gate-write` then blocks a **Write** or **Edit** there, and `shell-write-guard` blocks the shell writers it can parse. The release script writes through Node.js, which no gate sees, and Hard Limit 8 sanctions it (req-002).
- **After the first release.** The `release-copy-integrity` CI job fails when a root copy file differs from its `release.yml` hash (req-008). That check catches a hand edit that slips past the rule text in any run.
- **Gate root.** Backlog 0000382 records that `markedRoot()` takes `src/` as the root when the walk starts under `src/` and `CLAUDE_PROJECT_DIR` is unset. The gates then block every write outside the always-permitted paths. The fault fails closed and widens no write, so this ADR accepts it as risk R-006.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| The `ravintio-framework` component owns both copies | One owner for all pack bytes. The manifest and the docs registry describe one thing. | Agents could then edit the root copy as their own data. A root edit would ship without passing the `src/` suites (R-001). The root copy has no `component.yml`, so no manifest records its changes. | It breaks US-001. The root copy must stay the last release, which only the script writes. |
| `setup-hook-integration` owns the root copy | Setup runs from the root copy, so ownership follows the runtime path. | It gives the component a second payload it doesn't build. Two writers, setup docs and the release script, would claim one folder. The codegen close-out would bump the wrong manifest for a pack change (req-004). | Setup reads the root copy and never writes it. Ownership follows the writer, not the reader. |
| The release script owns the root copy, and the gate blocks agent writes to it in the source repo | The gates would enforce the rule in this run as well. | It changes `path-rules.mjs` and the `gate-write` and `shell-write-guard` parity. That needs its own design and P5 review, like backlog 0000382. | Out of scope for this design. Backlog 0000391 tracks it. |
| The migration deletes the consumer's `component.yml` without asking | Fewer prompts. R-004 closes in one run. | It deletes a file in the consumer's repo without consent. It breaks `product-version.mjs` when `product.yml` lists the file (R-013). **Write** and **Edit** can't delete, and Hard Limit 8 names no delete route (backlog 0000366). | The design requires the human on the loop's confirmation, and the scope file lists unconfirmed removal as out of scope. |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Owns `src/ravintio-framework/`. Its manifest records every pack change, setup code included. It doesn't own the root copy that its release script builds. |
| setup-hook-integration | Owns its manifest and docs at `src/setup-hook-integration/` only. Its code paths point into `src/ravintio-framework/`, and it owns no pack file. |

## Consequences

**Positive:**
- A broken change under `src/ravintio-framework/` can't reach consumers or this run's live hooks until a P7 build ships it (US-001, risk R-010).
- Each pack byte has one writer, so the codegen close-out bumps one manifest per change (req-004, backlog 0000061 and 0000361).
- The `release-copy-integrity` check gives the root copy rule a check that runs in CI, not only in rule text (req-008).
- A consumer keeps control of a file in their own repo, and a decline leaves it byte-identical (req-006).

**Negative:**
- In this run the gates permit a **Write** to the root copy, because the design lists it. Only rule text forbids it until P7 writes the first `release.yml`.
- `setup-hook-integration` documents code that another component owns. A setup change bumps `ravintio-framework`, and a reader of the setup manifest has to follow its paths into `src/ravintio-framework/`.
- A consumer who declines the removal keeps the leftover manifest. Step 1a warns at every session start until the file goes (req-003, R-004).
- Two recorded exceptions to Hard Limit 8 write the root copy in this run: the git pass (req-001) and the P7 run from `src/` (req-002).

**Risks:**
- An agent edits the root copy during P3 to P6 and the gates allow it. The edit then survives until the P7 build overwrites it. P6 review and the P7 rebuild reduce the impact.
- R-006 (accepted): with `CLAUDE_PROJECT_DIR` unset and a working folder under `src/`, the gates take `src/` as the root and block every gated write. Tools other than Claude Code can't edit the pack source from there. Backlog 0000382 tracks the fix.
- An interrupted build leaves `.ravintio-framework-build/` or `.ravintio-framework-previous/` in the working tree. The next run recovers them (req-002), and Step 7 stages only `ravintio-framework/`, so neither gets committed.
- Backlog 0000384: per-component docs written to `src/ravintio-framework/docs/` would ship in the root copy. This ADR leaves that docs path to its own design.

## Related ADRs

- ADR-002 - depends-on: it places the pack source at `src/ravintio-framework/`, which this ADR assigns to the component.
- ADR-003 - depends-on: it defines the release script and its write boundary, which this ADR makes the root copy's owner.
- ADR-004 - related-to: `release.yml` sits in the root copy, so the release script owns it and readers only read it.
- ADR-006 - related-to: the codegen close-out reads manifests from `product.yml`, which follows the ownership in this ADR.
- ADR-008 - depends-on: the 0.39.0 migration applies the consumer ownership rule for `ravintio-framework/component.yml`.
- ADR-009 - related-to: the integrity check enforces the root copy rule in CI.

## Supersedes

- None

## Superseded By

- None
