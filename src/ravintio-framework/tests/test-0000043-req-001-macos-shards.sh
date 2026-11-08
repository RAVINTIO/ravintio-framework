#!/usr/bin/env bash
# Static tests for feature 0000043-macos-test-job-timeout, req-001: sharded macOS test job.
#
# Verified by: execution
#
# req-001: every test-suite matrix entry sits under include and carries a cap (ADR-002).
# req-001: ubuntu-latest is one entry with cap 15. macos-latest is two shards with cap 15.
# req-001: windows-latest is seven shards with cap 20.
# req-001: RAVINTIO_SHARD_COUNT and the job name read matrix.shards.
# req-001: the test step timeout-minutes reads matrix.cap and the job timeout-minutes is 25.
#
# No YAML library is available, so the tests extract each job block with awk and grep it.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

source "$SCRIPT_DIR/helpers/pack-root.sh"

REPO_ROOT="$RAVINTIO_REPO_ROOT"
WORKFLOW="$REPO_ROOT/.github/workflows/ravintio.yml"

job_block() {
  awk -v id="  $1:" '
    $0 == id { on = 1; print; next }
    on && /^  [^ ]/ { exit }
    on { print }
  ' "$WORKFLOW"
}

has() { grep -Eq -- "$1" <<<"$2"; }
yes_no() { if has "$1" "$2"; then echo "yes"; else echo "no"; fi; }

# Prints one "os|shard|shards|cap" line per include entry. A missing key prints empty.
entries() {
  awk '
    function flush() { if (os != "") print os "|" shard "|" shards "|" cap }
    /^[[:space:]]+-[[:space:]]*os:/ {
      flush(); os = ""; shard = ""; shards = ""; cap = ""
      v = $0; sub(/^[[:space:]]+-[[:space:]]*os:[[:space:]]*/, "", v); sub(/[[:space:]]+$/, "", v); os = v; next
    }
    os != "" && /^[[:space:]]+shard:/ { v = $0; sub(/^[[:space:]]+shard:[[:space:]]*/, "", v); sub(/[[:space:]]+$/, "", v); shard = v; next }
    os != "" && /^[[:space:]]+shards:/ { v = $0; sub(/^[[:space:]]+shards:[[:space:]]*/, "", v); sub(/[[:space:]]+$/, "", v); shards = v; next }
    os != "" && /^[[:space:]]+cap:/ { v = $0; sub(/^[[:space:]]+cap:[[:space:]]*/, "", v); sub(/[[:space:]]+$/, "", v); cap = v; next }
    os != "" && /^    steps:/ { flush(); os = "" }
    END { flush() }
  ' <<<"$1"
}

SUITE="$(job_block test-suite)"
ROWS="$(entries "$SUITE")"
rows_for() { grep -E "^$1\|" <<<"$ROWS"; }

echo "== req-001: matrix rows =="
assert_equals "yes" "$([ -n "$SUITE" ] && echo yes || echo no)" "req-001: workflow has a test-suite job"
assert_equals "no" "$(yes_no 'os:[[:space:]]*\[' "$SUITE")" "req-001: no plain os list remains in the matrix"
assert_equals "10" "$(grep -c . <<<"$ROWS")" "req-001: the matrix holds ten include entries"

assert_equals "1" "$(rows_for ubuntu-latest | grep -c .)" "req-001: the matrix holds one ubuntu-latest entry"
assert_equals "ubuntu-latest|||15" "$(rows_for ubuntu-latest)" "req-001: the ubuntu-latest entry has cap 15 and no shard or shards"

assert_equals "2" "$(rows_for macos-latest | grep -c .)" "req-001: the matrix holds two macos-latest entries"
assert_equals "macos-latest|1|2|15
macos-latest|2|2|15" "$(rows_for macos-latest | sort)" "req-001: macos-latest has shards 1 and 2, each with shards 2 and cap 15"

WIN_WANT="$(for n in 1 2 3 4 5 6 7; do echo "windows-latest|$n|7|20"; done)"
assert_equals "7" "$(rows_for windows-latest | grep -c .)" "req-001: the matrix holds seven windows-latest entries"
assert_equals "$WIN_WANT" "$(rows_for windows-latest | sort)" "req-001: windows-latest has shards 1 to 7, each with shards 7 and cap 20"

echo "== req-001: shard count and job name =="
COUNT_LINE="$(grep -E 'RAVINTIO_SHARD_COUNT:' <<<"$SUITE")"
assert_equals "yes" "$(yes_no 'RAVINTIO_SHARD_COUNT:.*matrix\.shards' "$COUNT_LINE")" "req-001: RAVINTIO_SHARD_COUNT reads matrix.shards"
assert_equals "no" "$(yes_no 'RAVINTIO_SHARD_COUNT:.*&&[[:space:]]*7' "$COUNT_LINE")" "req-001: RAVINTIO_SHARD_COUNT no longer holds a fixed 7"
NAME_LINE="$(grep -E '^    name:' <<<"$SUITE" | head -1)"
assert_equals "yes" "$(yes_no 'matrix\.shards' "$NAME_LINE")" "req-001: the job name reads matrix.shards"
assert_equals "yes" "$(yes_no 'matrix\.shard[,)]' "$NAME_LINE")" "req-001: the job name reads matrix.shard"
assert_equals "yes" "$(yes_no 'Test suite \(' "$NAME_LINE")" "req-001: the job name starts Test suite ("
assert_equals "yes" "$(yes_no 'shard \{0\} of \{1\}' "$NAME_LINE")" "req-001: the job name reads shard {n} of {count}"

echo "== req-001: timeouts =="
assert_equals "yes" "$(yes_no '^        timeout-minutes:[[:space:]]*\$\{\{[[:space:]]*matrix\.cap[[:space:]]*\}\}[[:space:]]*$' "$SUITE")" "req-001: the test step timeout-minutes reads matrix.cap"
assert_equals "yes" "$(yes_no '^    timeout-minutes:[[:space:]]*25[[:space:]]*$' "$SUITE")" "req-001: the job timeout-minutes is a fixed 25"
assert_equals "no" "$(yes_no "matrix\.os == 'windows-latest' && 20" "$SUITE")" "req-001: the job-level windows cap expression is gone"

print_summary
