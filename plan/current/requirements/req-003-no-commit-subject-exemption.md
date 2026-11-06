---
title: "Requirement: req-003 - no-commit-subject-exemption"
summary: "Pre-push and both CI files drop the fix(fast-path): exemption and apply one source folder rule read from product.yml at run time."
status: "draft"
version: "0.1.0"
---
# Requirement: req-003 - no-commit-subject-exemption

**Skill:** [spec-agent](../skills/ravintio-spec-agent/SKILL.md)
**Feature:** 0000040-retire-fast-path
**Source:** US-002
**Priority:** must-have

## User Story

As a human on the loop, I rely on pre-push and CI to admit nothing on a Fast Path basis, so that no commit subject can skip a control.

## Functional Requirements

- Remove the Fast Path exemption from `ravintio-framework/hooks/pre-push`. That is the comment and the `if` block at lines 16 to 32, which exit 0 when every commit subject starts `fix(fast-path):`. Remove the `COMMIT_MESSAGES` line at line 14 too, because no check reads it after the removal.
- Remove the same exemption from the `Validate Code/Doc Parity` step of the `validate-branch` job in `ravintio-framework/hooks/ravintio.yml`. That is the comment, the `FAST_PATH_COUNT` and `TOTAL_COUNT` lines, and the `if` block at lines 20 to 33. Remove the `COMMIT_MESSAGES` line at line 18 as well.
- Make the same change in this repo's `.github/workflows/ravintio.yml`, at the same lines. After the change, the `validate-branch` job in both CI files holds the same text. The other jobs in this repo's file stay as they are.
- Replace the `src/` check in pre-push and in both CI files with the source folder rule:
  - A source folder is `src/`, or the folder that holds a `component.yml` listed in `product.yml`.
  - The check reads the list from `product.yml` when it runs. It never scans the tree for `component.yml` files. An unlisted `component.yml` doesn't make its folder a source folder.
  - The check reads `product.yml` at the git top level, from both the base commit and `HEAD`, and takes the union. A branch that drops a component from `product.yml` still has that folder checked.
  - If the base commit can't be read, as in a shallow clone, the check fails closed. Its message names `fetch-depth: 0`. Both CI files already check out with `fetch-depth: 0`, and a test fixture covers the shallow case.
  - It reads each `path:` value under `components:` and takes its folder. It ignores an empty value, an absolute path, and a path with a `..` part, and prints a warning that names each one.
  - A root-level `path: "component.yml"` gives the folder `.`, the whole repo. Every path outside `plan/` and `docs/` is then source. The check stays strict: a diff with a record still passes, and a diff under only `plan/` or `docs/` has no source change.
  - If `product.yml` is absent from both commits, the check falls back to `src/` only. It treats an unreadable file the same way and prints a warning.
  - `src/` always counts as a source folder, whatever `product.yml` lists.
  - P2 revision, which governs the base commit:
    - In CI, the base commit is the merge base with `origin/${{ github.base_ref }}`, which every pull request has.
    - In pre-push, the base commit is the merge base with `origin/main`, the branch the hook already diffs against.
    - If pre-push finds no `origin/main` ref, the rule checks nothing and prints a warning that names the missing ref. Today's diff already finds no files in that case, so the verdict doesn't change. A `master` repo or a first push then relies on CI.
    - The rule fails closed only when the ref exists but its merge base can't be read, as in a shallow clone.
    - Add a fixture for a repo with no `origin/main`: pre-push exits 0 and prints the warning.
- A record is a file under the top-level `plan/` or `docs/` folder. A record never counts as source, even when a listed folder holds it.
- If the diff touches a source folder, the same diff must touch a record. Otherwise the check fails with exit 1.
- A `component.yml` counts as source, not as a record. A diff that touches a source folder and a `component.yml`, and no record, fails. Today pre-push line 41 and CI line 40 accept any `component.yml` as a record. This rule closes that route.
- The failure message names each source folder the diff touched. It keeps the existing note that this is a presence check, not a correspondence guarantee.
- Pre-push and CI read the list with Bash, git, and standard text tools. Neither needs Node.
- Pre-push and CI give the same verdict on the same diff and the same `product.yml`.
- In this repo, `product.yml` lists `ravintio-framework/component.yml` and `src/setup-hook-integration/component.yml`. So `ravintio-framework/` and `src/setup-hook-integration/` both become source folders here. A diff to the pack then needs a record, as each Feature Pipeline run already writes one.
- In a consumer repo, a copied `ravintio-framework/` is a dependency, not source. It counts as a source folder only when that repo's `product.yml` lists it. Backlog 0000361 owns moving the pack source under `src/`. This requirement doesn't.
- Setup needs no folder list. Pre-push and CI read the repo when they run.
- Rewrite these existing suites test-first in P3, because they assert behaviour this requirement changes:
  - `ravintio-framework/tests/test-0000019-req-002-component-yml-matcher.sh` and its copy `tests/regression/test-0000019-req-002-component-yml-matcher.sh`. The PASS case expects pre-push to accept a `src/` change with only a `component.yml`. Under this rule, that case fails. The `component.json` checks and the pre-commit checks stay.
- These suites read the CI files and stay green with no change. Recheck them in P3:
  - `test-0000031-req-001-003-ci-jobs.sh`, `test-0000037-req-010-windows-git-bash-leg.sh`, and `test-0000037-req-011-windows-powershell-coverage.sh`. Each asserts that the consumer template lacks this repo's test jobs.
  - `test-0000039-req-006-consumer-migration.sh`. Its Fast Path message lines sit in a synthetic 0.36.0 workflow fixture for the released 0.37.0 helper. Released migrations never change, so the fixture stays.
- No suite runs pre-push or either CI file against a `fix(fast-path):` branch today. The new suite adds that case.
- The advisory `hooks/pre-commit` is out of scope (backlog 0000308).
- Split step: keep, at three criteria. The one concern is the verdict that pre-push and CI give on a branch diff. The exemption and the `src/` check sit in the same step, so removing one without the other leaves a half-changed check.

- Approach 2 iteration 1 revision: the new suite is `ravintio-framework/tests/test-0000040-req-003-no-commit-subject-exemption.sh`. It holds the scratch-repo fixtures, including the shallow-clone case.

## Acceptance Criteria

- [ ] `hooks/pre-push`, `hooks/ravintio.yml`, and `.github/workflows/ravintio.yml` hold no `fast-path` or `FAST_PATH` text. In a scratch repo, a branch whose every commit subject starts `fix(fast-path):` gets the same verdict as one with other subjects. A `src/` change with only a `component.yml` or only a non-plan file fails in both cases. Verified by: integration
- [ ] In scratch repos, pre-push and the extracted CI step each give these verdicts. Verified by: integration
  - A change in a folder that `product.yml` lists, with no record, fails. The message names that folder.
  - The same change with a file under `plan/` or `docs/` passes.
  - The same change with only that folder's `component.yml` fails.
  - A folder with an unlisted `component.yml` isn't a source folder, so a change there passes with no record.
  - A branch that removes a component from `product.yml` still has that folder checked.
  - With no `product.yml`, only `src/` counts as source.
  - An absolute or `..` path value is ignored with a warning.
  - With a root-level `path: "component.yml"`, every path outside `plan/` and `docs/` is source. A code change with no record fails, and a change under `plan/` or `docs/` alone passes.
- [ ] The `validate-branch` job in `.github/workflows/ravintio.yml` matches the one in `hooks/ravintio.yml` line for line. Pre-push and the CI step give the same exit code on every fixture in the second criterion. Verified by: integration

## Dependencies

- req-002 (gates-ignore-scope-record) removes the scope record from the write gates. This requirement removes the matching route from pre-push and CI.
- req-005 (consumer-migration) removes the exemption block from a consumer's existing `.github/workflows/ravintio.yml`. Setup copies the template only when that file is absent (`setup.sh` lines 763 to 771). So a consumer gets this requirement's CI change only through a fresh install or req-005.
- req-007 (docs-and-adr-supersede) updates the docs that describe the `fix(fast-path):` prefix, such as `pipeline-reference.md` and `project-operations.md`.
- Backlog 0000308 narrows to the advisory pre-commit and the presence-only checks once this ships.
- Backlog 0000361 owns moving the pack source under `src/`.
