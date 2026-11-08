---
title: "Final Report - 0000043-macos-test-job-timeout"
summary: "The autonomous run's single report to the human on the loop."
---
# Final Report - 0000043-macos-test-job-timeout

## 1. What shipped

This run picks up backlog 0000430 on the PR #77 branch. The single macOS test job had timed out at its 15-minute cap in 3 of 4 PR #77 runs.

- Every `test-suite` matrix entry in `.github/workflows/ravintio.yml` sits under `include` with its own `cap`: 15 for Ubuntu and macOS, and 20 for Windows.
- macOS runs in 3 shards. In the last P4 run, they took 323 s, 275 s, and 320 s, and ran 60, 60, and 59 suites, which sum to Ubuntu's 179.
- The test step times out at `matrix.cap`, under a fixed 25-minute job backstop.
- Each test job prints `Elapsed: {m} min {s} s of a {cap} min cap`. Past two-thirds of the cap, it adds a `Test job margin` warning. Windows shard 3 carried one, at 14 min 36 s of 20 (backlog 0000432).
- Two new suites check the layout and the elapsed step: `test-0000043-req-001-macos-shards.sh` and `test-0000043-req-002-job-margin.sh`.

## 2. Decisions and deviations

Decisions:
- P0: the elapsed step runs with `if: always()` after a step timeout. The P1 deviation below changed the timeout's bound.
- P0: the warning fires past two-thirds of the cap, not 75%, to match the 10-minute target.
- P0: each matrix entry carries its own `cap`.
- P0: this session kept `autonomous`, though `run-mode.mjs` reads `interactive` because of backlog 0000427.
- P1: the elapsed step reads a start time that an earlier step writes to `GITHUB_ENV`.
- P1: the req-002 suite tests the step by extracting its real `run:` block from the workflow.
- P1: req-001's under-10-minutes criterion measures the whole job.
- P1: `tests/README.md` stays in scope as a conditional item that adds no row.
- P1: the three minor critic findings from iteration 2 were applied after the loop closed.
- P3: the TDD subagents ran on `claude-sonnet-5-5`, the declared cheaper model, not haiku.
- P3: the warning prints `{m} min {s} s`, the same form as the elapsed line.
- P3: the elapsed step is named `Report the test step time`, and it reads the clock with `date +%s`.
- P3: the suite's step matcher reads its pattern from `ENVIRON`, which fixed a test defect.
- P3: a patch bump to 0.39.2, as the design confirmed.
- P9: PR #77 keeps its 0000041 title, and its body gains a 0000043 section.
- P7: no regression candidates, because no suite carries a `# REGRESSION-CANDIDATE:` tag.

Deviations, classed by a fresh-context `ravintio-reversal-assessor`:
- P1, altering: the job `timeout-minutes` is a fixed 25-minute backstop, and the test step reads `matrix.cap`. GitHub Actions expressions have no arithmetic, so the confirmed "cap minus one" step bound couldn't be written.
- P5, additive: the elapsed step rejects a leading zero and values over 10 digits, for security findings S-001 and S-002.
- P4, altering: macOS runs 3 shards in place of the confirmed 2. With 2 shards, shard 1 took 668 s and 612 s in two of four runs, against the 600 s target.

## 3. Version

`v0.39.2`, on commit `ab1009f8`, pushed to `origin`.

## 4. PR

[PR #77](https://github.com/RAVINTIO/ravintio-framework/pull/77), updated in place and still a draft. CI: all passed, 16 of 16 checks, on the head that P9 read, `580e6cd5`, in run `42499047016`.

## 5. Clean tree

Clean. Step 10b committed the archived build log as `580e6cd5`. `ravintio-framework/release.yml` stays untracked, under exception item 7 below.

## 6. Exceptions waiting

- **Item 2 (P6):** accept the fixed 25-minute job `timeout-minutes` in `.github/workflows/ravintio.yml`, or ask for another bound. The suites still stop at the confirmed 15 or 20 minutes. See row 1 of `deviation-review.md`.
- **Item 2 (P4):** accept 3 macOS shards, or ask for 2 shards with a higher cap. See row 3 of `deviation-review.md`.
- **Item 7 (P7):** the credential scan held back `ravintio-framework/release.yml` at lines 634 and 635. Each line is a pack file path with its SHA-256 hash, which is the backlog 0000425 false positive. Decide whether to commit the file. CI's `release-copy-integrity` job reports a skip while it is absent.

Backlog filed in this run: 0000432, 0000433, and 0000434.

Next: the human on the loop reviews and merges the PR.
