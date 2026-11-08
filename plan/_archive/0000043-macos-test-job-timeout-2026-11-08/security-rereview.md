# Security Re-review - 0000043-macos-test-job-timeout

A fresh-context reviewer checked fix commit `167cd519`. The reviewer did not write the fix.

## Method

1. Extracted the "Report the test step time" `run:` block from `.github/workflows/ravintio.yml` into a `mktemp -d` folder outside the repository.
2. Ran it under `/bin/bash` 3.2.57 with a fake `date` that prints `1800000000`.
3. Ran `bash src/ravintio-framework/tests/test-0000043-req-002-job-margin.sh`.

No local Bash 5 was available. The guard uses only `case` globs, which behave the same in both versions.

## Findings

| Finding | Verdict | Evidence |
|---|---|---|
| S-001 (leading zero reads as octal) | Resolved | The new `0*` arm rejects `08`, `09`, `0`, and `00` for both `RAVINTIO_TEST_START` and `CAP`. Each prints `Elapsed: unknown` and exits 0. No value with a leading zero reaches the arithmetic. |
| S-002 (over-long value overflows) | Resolved | The new `???????????*` arm rejects 11 or more characters. `12345678901` prints `Elapsed: unknown` and exits 0 for both inputs. The largest accepted value, `9999999999`, stays far inside 64-bit range. `CAP=9999999999` gives `cap * 40` of about 4e11 and exits 0. |

Other hostile values also print `Elapsed: unknown` and exit 0 for both inputs:

- a trailing newline
- an embedded space
- a negative number
- `15; echo hi`
- non-ASCII digits

A valid input still reports, and an over-margin input still warns. `start=1799998000 CAP=15` prints `33 min 20 s` and the `::warning` line.

## New findings

| ID | Severity | Location | Finding | Recommendation |
|---|---|---|---|---|
| S-006 | Info | `.github/workflows/ravintio.yml`, step "Report the test step time" | A 10-digit start time later than now passes the guard. `start=9999999999` prints `Elapsed: -136666666 min -39 s` and exits 0. Only a tampered `GITHUB_ENV` reaches it. That actor already runs code in the job (S-003), so the wrong text gains nothing. | None needed. Optionally treat a negative elapsed time as `Elapsed: unknown`. |

The fix adds no other problem. Rejecting `0` is correct for both inputs, because neither a zero cap nor a zero start time is valid.

## Suite result

`test-0000043-req-002-job-margin.sh`: 44 passed, 0 failed, exit 0. That includes the four new S-001 and S-002 checks.
