#!/usr/bin/env bash
# Tests for feature 0000043-macos-test-job-timeout, req-002: visible job margin.
#
# Verified by: execution
#
# req-002: a step before the run-tests.sh step appends RAVINTIO_TEST_START to GITHUB_ENV.
# req-002: a step after it, named "Report the test step time", runs with if: always().
# req-002: both new steps set shell: bash, and the elapsed step reads CAP from matrix.cap.
# req-002: the job references no secret.
# req-002: the suite extracts the elapsed step's run: block and runs it under Bash.
#
# Clock control: the block is run with a fake date on PATH. The fake prints a fixed epoch
# for "date +%s" and calls the real date for anything else. The elapsed seconds are then
# exact, with no drift, so the 600 and 601 second boundary cases can't flip.
#
# No YAML library is available, so the tests extract the job and step blocks with awk.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

source "$SCRIPT_DIR/helpers/pack-root.sh"

REPO_ROOT="$RAVINTIO_REPO_ROOT"
WORKFLOW="$REPO_ROOT/.github/workflows/ravintio.yml"
ELAPSED_STEP_NAME="Report the test step time"

# Scratch folder. Stop before writing anything if mktemp fails.
TMP_ROOT="$(mktemp -d 2>/dev/null)" || { echo "req-002: mktemp -d failed" >&2; exit 1; }
[ -n "$TMP_ROOT" ] && [ -d "$TMP_ROOT" ] || { echo "req-002: mktemp -d failed" >&2; exit 1; }
trap 'rm -rf -- "$TMP_ROOT"' EXIT

job_block() {
  awk -v id="  $1:" '
    $0 == id { on = 1; print; next }
    on && /^  [^ ]/ { exit }
    on { print }
  ' "$WORKFLOW"
}

has() { grep -Eq -- "$1" <<<"$2"; }
yes_no() { if has "$1" "$2"; then echo "yes"; else echo "no"; fi; }

# Prints the steps of a job, one block per step, separated by a line holding only "@@STEP@@".
steps_of() {
  awk '
    /^    steps:/ { on = 1; next }
    on && /^      - / { print "@@STEP@@" }
    on && /^  [^ ]/ { exit }
    on { print }
  ' <<<"$1"
}

# Prints the Nth step block (1-based) from the stream made by steps_of.
step_n() {
  awk -v n="$2" '
    /^@@STEP@@$/ { i++; next }
    i == n { print }
  ' <<<"$1"
}

# Prints the 1-based index of the first step whose block matches the regex, or empty.
step_index_matching() {
  # The pattern goes through ENVIRON, not -v. awk -v processes backslash
  # escapes, so \$\( would reach awk as $( and never match.
  STEP_RE="$2" awk '
    function flush() { if (!found && cur != "" && cur ~ ENVIRON["STEP_RE"]) { found = i } }
    /^@@STEP@@$/ { flush(); i++; cur = ""; next }
    { cur = cur $0 "\n" }
    END { flush(); if (found) print found }
  ' <<<"$1"
}

# Prints the run: block of the named step with the YAML block indent stripped.
run_block_of() {
  awk -v name="$1" '
    $0 ~ "^      - name: " name "[[:space:]]*$" { in_step = 1; next }
    in_step && /^      - / { exit }
    in_step && !in_run && /^        run:[[:space:]]*\|/ { in_run = 1; next }
    in_run {
      if ($0 ~ /^[[:space:]]*$/) { print ""; next }
      if ($0 ~ /^          /) { sub(/^          /, ""); print; next }
      exit
    }
  ' "$WORKFLOW"
}

SUITE="$(job_block test-suite)"
STEPS="$(steps_of "$SUITE")"
TEST_IDX="$(step_index_matching "$STEPS" 'run-tests\.sh')"
START_IDX="$(step_index_matching "$STEPS" 'RAVINTIO_TEST_START=\$\(date \+%s\)')"
ELAPSED_IDX="$(step_index_matching "$STEPS" "name: $ELAPSED_STEP_NAME")"
START_STEP="$([ -n "$START_IDX" ] && step_n "$STEPS" "$START_IDX")"
ELAPSED_STEP="$([ -n "$ELAPSED_IDX" ] && step_n "$STEPS" "$ELAPSED_IDX")"

echo "== req-002: static checks on the test-suite job =="
assert_equals "yes" "$([ -n "$SUITE" ] && echo yes || echo no)" "req-002: workflow has a test-suite job"
assert_equals "yes" "$([ -n "$TEST_IDX" ] && echo yes || echo no)" "req-002: the job has a run-tests.sh step"

assert_equals "yes" "$([ -n "$START_IDX" ] && echo yes || echo no)" "req-002: a step writes RAVINTIO_TEST_START=\$(date +%s)"
assert_equals "yes" "$([ -n "$START_IDX" ] && [ -n "$TEST_IDX" ] && [ "$START_IDX" -lt "$TEST_IDX" ] && echo yes || echo no)" "req-002: the start-time step comes before the run-tests.sh step"
assert_equals "yes" "$(yes_no '^        shell:[[:space:]]*bash[[:space:]]*$' "$START_STEP")" "req-002: the start-time step sets shell: bash"
assert_equals "yes" "$(yes_no 'RAVINTIO_TEST_START=\$\(date \+%s\)"?[[:space:]]*>>[[:space:]]*"?\$GITHUB_ENV"?' "$START_STEP")" "req-002: the start-time step appends to \$GITHUB_ENV"

assert_equals "yes" "$([ -n "$ELAPSED_IDX" ] && echo yes || echo no)" "req-002: a step is named '$ELAPSED_STEP_NAME'"
assert_equals "yes" "$([ -n "$ELAPSED_IDX" ] && [ -n "$TEST_IDX" ] && [ "$ELAPSED_IDX" -gt "$TEST_IDX" ] && echo yes || echo no)" "req-002: the elapsed step comes after the run-tests.sh step"
assert_equals "yes" "$(yes_no '^        if:[[:space:]]*always\(\)[[:space:]]*$' "$ELAPSED_STEP")" "req-002: the elapsed step runs with if: always()"
assert_equals "yes" "$(yes_no '^        shell:[[:space:]]*bash[[:space:]]*$' "$ELAPSED_STEP")" "req-002: the elapsed step sets shell: bash"
assert_equals "yes" "$(yes_no '^          CAP:[[:space:]]*\$\{\{[[:space:]]*matrix\.cap[[:space:]]*\}\}[[:space:]]*$' "$ELAPSED_STEP")" "req-002: the elapsed step env sets CAP from matrix.cap"
assert_equals "yes" "$(yes_no '::warning title=Test job margin::' "$ELAPSED_STEP")" "req-002: the elapsed step holds the warning text ::warning title=Test job margin::"
assert_equals "no" "$(yes_no 'secrets\.' "$SUITE")" "req-002: the test-suite job references no secrets."

echo "== req-002: elapsed step behaviour =="
BLOCK="$(run_block_of "$ELAPSED_STEP_NAME")"
assert_equals "yes" "$([ -n "$BLOCK" ] && echo yes || echo no)" "req-002: the elapsed step has a run: block to extract"

# Fake date: "date +%s" prints FAKE_NOW. Anything else goes to the real date.
REAL_DATE="$(command -v date)"
mkdir -p "$TMP_ROOT/bin"
cat >"$TMP_ROOT/bin/date" <<EOF
#!/usr/bin/env bash
if [ "\${1:-}" = "+%s" ]; then echo "\$FAKE_NOW"; else exec "$REAL_DATE" "\$@"; fi
EOF
chmod +x "$TMP_ROOT/bin/date"
printf '%s\n' "$BLOCK" >"$TMP_ROOT/elapsed.sh"

FAKE_NOW=1800000000

# run_elapsed AGE CAP  -> sets OUT and RC. AGE "unset" leaves the start unset. Other
# non-numeric AGE values are passed through as the start time.
run_elapsed() {
  local age="$1" cap="$2" start
  : >"$TMP_ROOT/github_env"
  case "$age" in
    unset) OUT="$(env -u RAVINTIO_TEST_START PATH="$TMP_ROOT/bin:$PATH" FAKE_NOW="$FAKE_NOW" CAP="$cap" GITHUB_ENV="$TMP_ROOT/github_env" bash "$TMP_ROOT/elapsed.sh" 2>&1)"; RC=$? ;;
    ''|*[!0-9]*) OUT="$(PATH="$TMP_ROOT/bin:$PATH" FAKE_NOW="$FAKE_NOW" RAVINTIO_TEST_START="$age" CAP="$cap" GITHUB_ENV="$TMP_ROOT/github_env" bash "$TMP_ROOT/elapsed.sh" 2>&1)"; RC=$? ;;
    *) start=$((FAKE_NOW - age))
       OUT="$(PATH="$TMP_ROOT/bin:$PATH" FAKE_NOW="$FAKE_NOW" RAVINTIO_TEST_START="$start" CAP="$cap" GITHUB_ENV="$TMP_ROOT/github_env" bash "$TMP_ROOT/elapsed.sh" 2>&1)"; RC=$? ;;
  esac
}
count_matching() { grep -Ec -- "$1" <<<"$OUT"; }

# CAP 15 at 540 s (9 min): exact Elapsed line, no warning, exit 0.
run_elapsed 540 15
assert_equals "1" "$(count_matching '^Elapsed: ')" "req-002: 540 s prints one Elapsed line"
assert_equals "1" "$(count_matching '^Elapsed: 9 min 0 s of a 15 min cap$')" "req-002: 540 s prints exactly 'Elapsed: 9 min 0 s of a 15 min cap'"
assert_equals "0" "$(count_matching '^::warning')" "req-002: 540 s prints no warning"
assert_equals "0" "$RC" "req-002: 540 s exits 0"

# CAP 15 at 660 s (11 min): one Elapsed line and one warning.
run_elapsed 660 15
assert_equals "1" "$(count_matching '^Elapsed: 11 min 0 s of a 15 min cap$')" "req-002: 660 s prints 'Elapsed: 11 min 0 s of a 15 min cap'"
assert_equals "1" "$(count_matching '^::warning')" "req-002: 660 s prints one warning line"
assert_equals "1" "$(count_matching '^::warning title=Test job margin::11 min 0 s of a 15 min cap$')" "req-002: 660 s warning reads '::warning title=Test job margin::11 min 0 s of a 15 min cap'"
assert_equals "0" "$RC" "req-002: 660 s exits 0"

# CAP 15 at 960 s (16 min, a step that hit its timeout): the line and warning still print.
run_elapsed 960 15
assert_equals "1" "$(count_matching '^Elapsed: 16 min 0 s of a 15 min cap$')" "req-002: 960 s prints 'Elapsed: 16 min 0 s of a 15 min cap'"
assert_equals "1" "$(count_matching '^::warning')" "req-002: 960 s prints one warning line"
assert_equals "0" "$RC" "req-002: 960 s exits 0"

# Boundary: the date fake fixes the clock, so 600 and 601 s are exact and can't drift.
run_elapsed 600 15
assert_equals "0" "$(count_matching '^::warning')" "req-002: boundary, cap 15 at 600 s prints no warning"
assert_equals "1" "$(count_matching '^Elapsed: 10 min 0 s of a 15 min cap$')" "req-002: boundary, cap 15 at 600 s prints the Elapsed line"
run_elapsed 601 15
assert_equals "1" "$(count_matching '^::warning')" "req-002: boundary, cap 15 at 601 s prints one warning"
assert_equals "1" "$(count_matching '^Elapsed: 10 min 1 s of a 15 min cap$')" "req-002: boundary, cap 15 at 601 s prints the Elapsed line"

# Missing or non-numeric start time.
run_elapsed unset 15
assert_equals "1" "$(count_matching '^Elapsed: unknown$')" "req-002: unset start time prints 'Elapsed: unknown'"
assert_equals "0" "$RC" "req-002: unset start time exits 0"
run_elapsed abc 15
assert_equals "1" "$(count_matching '^Elapsed: unknown$')" "req-002: start time 'abc' prints 'Elapsed: unknown'"
assert_equals "0" "$RC" "req-002: start time 'abc' exits 0"

# Non-numeric cap: no arithmetic, no command run.
run_elapsed 540 "15; echo hi"
assert_equals "1" "$(count_matching '^Elapsed: unknown$')" "req-002: CAP '15; echo hi' prints 'Elapsed: unknown'"
assert_equals "0" "$RC" "req-002: CAP '15; echo hi' exits 0"
assert_equals "0" "$(count_matching '^hi$')" "req-002: CAP '15; echo hi' runs no injected command"

print_summary
