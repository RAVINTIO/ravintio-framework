---
title: "ADR 003: Source folder rule read from product.yml"
summary: "Pre-push and both CI files drop the fix(fast-path): exemption and apply one source folder rule. The rule reads product.yml at run time from the base commit and HEAD, and a change to a source folder needs a record under plan/ or docs/ in the same diff."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Source folder rule read from product.yml

**Skill:** [adr-agent](../../../ravintio-framework/skills/ravintio-adr-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Component:** ravintio-framework
**Date:** 2026-11-06

## Context

Three files give the branch verdict today:

- `ravintio-framework/hooks/pre-push`
- the `validate-branch` job in `ravintio-framework/hooks/ravintio.yml`, the consumer CI template
- the `validate-branch` job in this repo's `.github/workflows/ravintio.yml`

Each one has two checks. The first exits 0 when every commit subject starts `fix(fast-path):`. It then asks only for a `component.yml` or a `plan/changelog/` file. ADR-002 retires the Fast Path track, so this exemption has no track left to serve.

The second check looks only at `src/`. If the diff touches `src/`, it needs a file under `plan/` or `docs/`, or any `component.yml`. That check has two gaps:

- It misses source that lives outside `src/`. In this repo, the pack source sits in `ravintio-framework/`, which carries its own `component.yml`.
- It accepts a `component.yml` as a record. A diff can change code and bump a manifest with no plan or doc.

The requirement req-003 sets the rule that closes both gaps. Risk R-005 covers a misread of `product.yml`. Risk R-011 covers a shallow clone with no base commit. ADR-001 keeps the stack, so the read uses Bash, git, and line matching, with no YAML library and no Node.js.

## Decision

Remove the `fix(fast-path):` exemption from all three files. Remove the `COMMIT_MESSAGES` line too, because no check reads it afterwards. Replace the `src/` check with one source folder rule. The `validate-branch` job holds the same text in both CI files.

### Source folders

A source folder is one of these:

- `src/`, which always counts, whatever `product.yml` lists
- the folder that holds a `component.yml` that `product.yml` lists

The rule reads the list when it runs. It never scans the tree for `component.yml` files. An unlisted `component.yml` doesn't make its folder a source folder. Setup writes no folder list, because pre-push and CI read the repo each time.

### Reading product.yml

The rule reads `product.yml` at the git top level from two commits:

1. The base commit. Pre-push uses the merge base of `origin/main` and `HEAD`. CI uses the merge base of `origin/${{ github.base_ref }}` and `HEAD`.
2. `HEAD`.

It takes the union of both lists. A branch that drops a component from `product.yml` still has that folder checked.

The read uses `git show` and line matching, in the fixed layout that `product.yml` and its template use:

```yaml
components:
  - id: "ravintio-framework"
    path: "ravintio-framework/component.yml"
```

The rule reads each `path:` value inside the `components:` block. The block ends at the next line that starts in column 1. The rule strips quotes and takes the folder part of each value. It skips these values and prints a warning that names each one:

- an empty value
- an absolute path
- a path with a `..` part

A root-level `path: "component.yml"` gives the folder `.`, the whole repo. Every path outside `plan/` and `docs/` is then source.

### Records and the verdict

A record is a file under the top-level `plan/` or `docs/` folder. A record never counts as source, even inside a listed folder. A `component.yml` counts as source, not as a record.

If the diff touches a source folder, the same diff must touch a record. Otherwise the check exits 1. The message names each source folder the diff touched. It keeps the note that this is a presence check, not a correspondence guarantee. Pre-push and CI give the same verdict on the same diff and the same `product.yml`.

### When the read fails

| Case | Behaviour |
|------|-----------|
| The base commit can't be resolved, as in a shallow clone (R-011) | Fail closed with exit 1. The message names `fetch-depth: 0`. |
| Pre-push finds no `origin/main` ref, as in a `master` repo or before the first push (R-012) | Check nothing and print a warning that names the missing ref. Today's diff finds no files in this case, so the verdict stays the same. CI still runs the rule on the pull request. |
| `product.yml` is absent from both commits | Check `src/` only. No warning, because a repo with one component needs no `product.yml`. |
| `product.yml` exists but git can't read it | Check `src/` only, and print a warning that names the file. |
| `product.yml` exists but yields no valid `path:` value, for example a flow-style list or no `components:` key | Check `src/` only, and print a warning that names the file and says the rule found no components. |

The first row follows req-003 and R-011. The second row follows req-003 and R-012. The third and fourth rows follow req-003. The last row is a decision this ADR adds, because req-003 doesn't name a layout the line match can't read. It treats that case like an unreadable file. The rule never checks less than `src/`, so the fallback is never weaker than the check it replaces. The warning tells the human on the loop that the listed folders went unchecked.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep the `src/` check and only remove the exemption | Smallest change | Pack changes in this repo need no record, and a `component.yml` still counts as one | It leaves both gaps open |
| Scan the tree for every `component.yml` | No list to keep | A consumer's copied `ravintio-framework/component.yml` would make the pack their source, and any stray manifest widens the rule | req-003 forbids a scan, and backlog 0000361 shows the copied manifest already misleads skills |
| Write a folder list into the hooks at setup | No read at run time | The list goes stale when a component appears, and setup would need a new step | `product.yml` already holds the list, so a second copy can drift |
| Read `product.yml` at `HEAD` only | One read, works in a shallow clone | A branch can drop a component from the list and skip its check | The union closes that route |
| Fail closed when the layout yields no valid path | No listed folder ever goes unchecked | A repo with a hand-edited or flow-style list can't push until someone rewrites the file | req-003 already treats an unreadable file as `src/` only with a warning, and this case matches it |
| Parse `product.yml` with a YAML library | Reads any valid layout | Pre-push and CI would need Node.js or another tool | ADR-001 keeps the stack and req-003 requires Bash, git, and text tools |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | `hooks/pre-push` and `hooks/ravintio.yml` lose the exemption and gain the source folder rule. In this repo, `ravintio-framework/` becomes a source folder, because `product.yml` lists its manifest. The matcher suite `test-0000019-req-002-component-yml-matcher.sh` and its regression copy change test-first in P3. The new suite `test-0000040-req-003-no-commit-subject-exemption.sh` holds the scratch-repo fixtures. |
| setup-hook-integration | `src/setup-hook-integration/` stays a source folder. The rule now reads it from `product.yml`, and a manifest bump alone no longer passes. |
| `.github/workflows/ravintio.yml` (repo CI) | Its `validate-branch` job matches the template line for line. Its other jobs stay as they are. |

## Consequences

**Positive:**
- No commit subject can skip the branch check.
- A `component.yml` bump no longer stands in for a plan or doc record.
- Pack changes in this repo need a record, as every Feature Pipeline run already writes one.
- A consumer adds a component to `product.yml` and the check covers it, with no setup re-run.

**Negative:**
- The CI step and pre-push grow longer, and both must stay in step by hand.
- A repo that lists a root-level `component.yml` needs a record for every code change, including small ones.
- A consumer with an existing CI file never gets the source folder rule in CI. Setup copies the CI template only when the file is absent, and the migration in ADR-006 removes only the exemption block. Backlog 0000364 covers the CI file that setup never refreshes.
- Pre-push hard-codes `origin/main`, so a `master` repo gets no pre-push check. Backlog 0000367 covers it.

**Risks:**
- A hand-edited `product.yml` in an unusual layout leaves only `src/` checked. The warning names the file, but a busy reader can miss a warning in a passing run (R-005).
- A shallow clone blocks the push until the base commit is present (R-011). A failed `git fetch` that leaves no `origin/main` ref skips the check with a warning instead (R-012).
- In a consumer repo, a copied `ravintio-framework/` counts as source only if that repo's `product.yml` lists it. Backlog 0000361 moves the pack source under `src/` and releases the pack without its manifest. This rule stays valid after that move, once `product.yml` points at the new path.

## Related ADRs

- ADR-001 - depends-on: the stack decision requires line matching in Bash, with no YAML library.
- ADR-002 - depends-on: the one-track decision removes the commit-subject exemption that this ADR deletes.
- ADR-006 - related-to: the migration removes the exemption block from a consumer's existing `.github/workflows/ravintio.yml`.

## Supersedes

- None

## Superseded By

- None
