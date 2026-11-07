---
title: "ADR 004: release.yml contract and readers"
summary: "The released pack carries ravintio-framework/release.yml with a version, a source commit, a build date, and a SHA-256 per file, and no component.yml. Step 1a, the update policy, and the migrator read release.yml first and fall back to component.yml for a pack before 0.39.0. Update detection has a release signal and a changed-file signal, which closes backlog 0000181."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - release.yml contract and readers

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000041-pack-source-under-src
**Component:** ravintio-framework
**Date:** 2026-11-07

## Context

Consumers copy `ravintio-framework/` with its `component.yml`. Their runs then count the pack as their own source, bump it, and can tag from it. ADR-002 moves the pack source to `src/ravintio-framework/`. ADR-003 adds a release script that rebuilds the root copy without `component.yml`.

A pack without a manifest still needs a version record. Three readers use the pack version today:

- Orchestrator step 1a reads the `component.yml` version to detect an update.
- `standards/framework-update-policy.md` defines the detection signal on that version.
- The migrator records `framework-version` from `component.yml`.

Detection today has a gap (backlog 0000181). The policy says detection keys on changed files, but step 1a compares the version only. A push that skips the version bump then reads as no update. Step 1b can then load an unconfirmed source copy.

No file records a source commit today. In a consumer, `docs/about.md` holds the consumer's own product version, not the framework version.

Packs before 0.39.0 have no `release.yml`. A consumer upgrading from 0.38.0 runs step 1a against the old pack first.

## Decision

The released pack carries `ravintio-framework/release.yml` and no `component.yml`. This is a new file contract, and the 0.39.0 version bump records it.

### The contract

The release script (req-002, ADR-003) writes the file. Its keys come in a fixed order:

1. `format`, the whole number `1`. A reader refuses any other value.
2. `version`, from `src/ravintio-framework/component.yml`.
3. `source-commit`, the full 40-character hash of `HEAD`.
4. `built`, the UTC build date as `YYYY-MM-DD`.
5. `files`, one `"{path}": "{sha256}"` line per root-copy file, in byte order.

Each hash is the SHA-256 of the file after each CRLF pair reads as LF. The file lists neither itself nor `component.yml`. The flat line shape lets a line-based reader parse it, as ADR-001 requires.

### The readers

Step 1a, the update policy, and the migrator read `release.yml` first (req-003).

- If `release.yml` is absent, they fall back to the `component.yml` version. This fallback serves a pack before 0.39.0 only.
- If `release.yml` exists but breaks the format, detection exits 2. No reader falls back to `component.yml` in that case.
- The migrator reads `framework-version` through the same rule. A released migration that names `component.yml` reads through it too, so released migrations stay byte-identical.

A new read-only script, `scripts/release-check.mjs`, does the comparison for step 1a. It writes no file, so the Write-or-Edit rule (boot Hard Limit 8) needs no new sanction.

### Two signals

Update detection has two signals, and the policy states both.

1. **Release update.** A new `version` or `source-commit` against the last recorded value is a release update.
   - The recorded value lives in a new `plan/framework-release.yml`. Only step 1a writes it, with **Write**.
   - A first upgrade has no recorded value. It compares the version only, against the `docs/about.md` version.
2. **Changed file.** A pack file whose hash differs from `release.yml` is a changed file. It counts as an update even when the version is unchanged.
   - A missing listed file and an unlisted file also count.
   - Step 1a names each file.
   - A changed file stays flagged at each session start until it matches its hash or a new release lists it.

In the framework source repo, an own build needs no confirmation. The check proves an own build by content, not commit ancestry. Each `release.yml` hash must match the same path under `src/ravintio-framework/`.

### Leftover manifest

A consumer may copy the new pack over the old one and keep `component.yml`. While that file sits beside `release.yml`, step 1a warns at every session start. The warning holds even after the 0.39.0 migration (ADR-008) records `skipped`.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep `component.yml` in the release and teach consumers to ignore it | No new file. Readers keep one path. | Every consumer-side reader must learn the exception. A missed reader still counts the pack as source and can bump or tag it. | The manifest in the copy causes the defect. Removing it fixes the cause in one place, where an ignore rule must hold in every reader. |
| Record `version` and `source-commit` only, with no per-file hashes | Smaller file. No hash rule. No CRLF handling. | Can't detect a file changed without a version bump. Backlog 0000181 stays open. The root copy integrity check (req-008) has nothing to compare. | The P0 exchange chose per-file hashes so step 1a gets file-level detection. |
| Drop the `component.yml` fallback | One read path. Less text in step 1a and the policy. | A consumer upgrading from 0.38.0 runs step 1a on a pack with no `release.yml`. Detection then can't run, and step 1b loads no source copy. | The first upgrade from every older pack would fail detection. |
| Record the trusted release in `docs/about.md` | Uses an existing file. | In a consumer, that file holds the consumer's product version. It has no source commit field. | A framework value there would clash with the consumer's own version. |
| Prove an own build by commit ancestry of `source-commit` | Reads one git fact. | A squash merge rewrites the commit, and the proof then fails. | A content match holds after a squash merge. |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Gains `scripts/release-check.mjs` and the `release.yml` contract. Step 1a, step 1b's state list, `standards/framework-update-policy.md`, and the migrator read `release.yml` first. |

## Consequences

**Positive:**
- A consumer copy has no manifest, so consumer runs never count the pack as their source (US-002).
- A pack file changed without a version bump now reads as an update, and step 1a names it. That closes backlog 0000181.
- Step 1b never loads an unconfirmed source copy after a push that skipped the version bump.
- The root copy integrity check (req-008) and step 1a share one hash rule through `release-check.mjs --files-only`.
- A consumer upgrading from 0.38.0 still gets detection through the `component.yml` fallback.

**Negative:**
- Readers carry two paths until no consumer runs a pack before 0.39.0. Step 1a, the policy, and the migrator each state the fallback.
- A repo gains a new tracked file, `plan/framework-release.yml`, for step 1a to write and commit.
- A local edit to any pack file flags at every session start until it matches its hash. A consumer who patches the pack sees the flag each time.
- On a first upgrade, a consumer's `docs/about.md` holds its own product version. Step 1a then shows a version mismatch that means nothing. The human on the loop still confirms with provenance, so the cost is one extra prompt.
- If that product version matches the framework version by chance, and every file matches its hash, step 1a writes the trusted record without a prompt. The files match the release, so the record is still correct. The first upgrade accepts both effects, because no better comparator exists before `plan/framework-release.yml`.
- The line-based reader accepts only the form the release script writes. A hand-edited `release.yml` in another layout exits 2 (ADR-001).
- The leftover manifest warning repeats every session for a consumer who declines removal (R-004, R-013).

**Risks:**
- A Windows checkout with CRLF conversion could flag every file as changed. The CRLF-as-LF hash rule mitigates this (R-009).
- A consumer that keeps `component.yml` still counts the pack as source in its runs. The warning and the 0.39.0 migration mitigate this (R-004).
- A consumer script outside the pack may read `component.yml` for the version (A-001). Removing the file breaks that script.
- Step 1 runs migrations before step 1a confirms the pack (backlog 0000383). A migration can run from an unconfirmed pack.
- The own-build rule depends on `projectKind(root)` (req-005, ADR-007). A misread repo kind would skip confirmation (R-014).

## Related ADRs

- ADR-001 - depends-on: the flat line shape follows from the line-based reader.
- ADR-002 - depends-on: the release copy exists because the source moves under `src/`.
- ADR-003 - depends-on: the release script writes `release.yml`.
- ADR-005 - related-to: the release script owns the root copy that `release.yml` describes.
- ADR-007 - depends-on: the own-build rule uses the source-repo signal.
- ADR-008 - related-to: the 0.39.0 migration offers to remove the leftover manifest that step 1a warns about.
- ADR-009 - related-to: the root copy integrity check reads `release.yml` with the same hash rule.

## Supersedes

- None

## Superseded By

- None
