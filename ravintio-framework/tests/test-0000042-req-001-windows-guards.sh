#!/usr/bin/env bash
# Tests for feature 0000042-fix-windows-shards-pr-77, req-001: Windows-safe
# 0000041 suites (ADR-002 and ADR-003).
#
# Scope: the IS_WIN guards in the req-005 and req-006 suites of feature
# 0000041, and the Windows skip rows in tests/README.md.
#
# Mechanism: a stand-in uname script reports MINGW64_NT-10.0-20348 for
# `uname -s`, so each target suite takes its Windows path on any host. Without
# the stand-in, each suite runs as on Linux or macOS and prints no SKIP line.
# The suite resolves the target suites and README from its own folder, so it
# works in src/ravintio-framework/tests and in the root release copy.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
source "$SCRIPT_DIR/helpers/pack-root.sh"

# IS_WIN comes from the real uname. The stand-in below only reaches the suites it runs.
IS_WIN=no
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) IS_WIN=yes ;; esac

WORK="$(mktemp -d -t ravintio_0000042_req001_XXXXXX)" || { echo "  FAIL: req-001: mktemp -d failed"; exit 1; }
trap 'rm -rf "$WORK"' EXIT

SUITE_005="$SCRIPT_DIR/test-0000041-req-005-applies-to-header.sh"
SUITE_006="$SCRIPT_DIR/test-0000041-req-006-consumer-migration.sh"
README="$SCRIPT_DIR/README.md"

# Stand-in uname: reports a Git Bash kernel name for `uname -s`, real uname otherwise.
STUB="$WORK/stub-bin"
mkdir -p "$STUB"
cat > "$STUB/uname" <<'STUB_EOF'
#!/bin/sh
if [ "$#" -eq 1 ] && [ "$1" = "-s" ]; then
  echo "MINGW64_NT-10.0-20348"
else
  exec /usr/bin/uname "$@"
fi
STUB_EOF
chmod +x "$STUB/uname"

strip_ansi() { sed $'s/\x1b\\[[0-9;]*m//g'; }

# Run a suite under the stand-in. Output goes to a file, exit code to a variable.
run_win() {  # run_win <suite> <out-file>
  PATH="$STUB:$PATH" bash "$1" 2>&1 | strip_ansi > "$2"
  return "${PIPESTATUS[0]}"
}
run_native() {  # run_native <suite> <out-file>
  bash "$1" 2>&1 | strip_ansi > "$2"
  return "${PIPESTATUS[0]}"
}

echo "=== req-001: Windows guards in the 0000041 suites ==="

W5="$WORK/win-005.out"
W6="$WORK/win-006.out"
N5="$WORK/nat-005.out"
N6="$WORK/nat-006.out"

run_win "$SUITE_005" "$W5"; W5_EXIT=$?
run_win "$SUITE_006" "$W6"; W6_EXIT=$?
run_native "$SUITE_005" "$N5"; N5_EXIT=$?
run_native "$SUITE_006" "$N6"; N6_EXIT=$?

# 1. req-005 exits 0 under the stand-in.
assert_equals "0" "$W5_EXIT" "req-001: req-005 suite exits 0 under a MINGW uname"

# 2. req-005 prints exactly 4 SKIP lines.
W5_SKIPS="$(grep -c '^  SKIP (windows): ' "$W5" || true)"
assert_equals "4" "$W5_SKIPS" "req-001: req-005 suite prints 4 SKIP (windows) lines under a MINGW uname"

# 3. Each of those lines names ln -s.
W5_LN="$(grep '^  SKIP (windows): ' "$W5" | grep -c 'ln -s' || true)"
assert_equals "4" "$W5_LN" "req-001: each req-005 SKIP (windows) line names ln -s"

# 4. req-006 exits 0 under the stand-in.
assert_equals "0" "$W6_EXIT" "req-001: req-006 suite exits 0 under a MINGW uname"

# 5. req-006 prints exactly 1 SKIP line, naming ln -s.
W6_SKIPS="$(grep -c 'SKIP (windows)' "$W6" || true)"
W6_LN="$(grep 'SKIP (windows)' "$W6" | grep -c 'ln -s' || true)"
assert_equals "1:1" "$W6_SKIPS:$W6_LN" "req-001: req-006 suite prints 1 SKIP (windows) line naming ln -s under a MINGW uname"

if [ "$IS_WIN" = yes ]; then
  # 6 and 7. A native Windows run prints the skips these checks expect to be absent.
  echo "  SKIP (windows): native-run checks 6 and 7: a native Windows run prints the SKIP lines that these checks expect to be absent"
else
  # 6. req-005 without the stand-in: no SKIP lines, 67 cases.
  N5_SKIPS="$(grep -c 'SKIP (windows)' "$N5" || true)"
  N5_RESULT="$(grep -o 'Results: [0-9]* passed, [0-9]* failed' "$N5" | tail -n 1)"
  assert_equals "0|Results: 67 passed, 0 failed" "$N5_SKIPS|$N5_RESULT" "req-001: req-005 suite prints no SKIP line and passes 67 cases natively"

  # 7. req-006 without the stand-in: no SKIP lines, 127 cases.
  N6_SKIPS="$(grep -c 'SKIP (windows)' "$N6" || true)"
  N6_RESULT="$(grep -o 'Results: [0-9]* passed, [0-9]* failed' "$N6" | tail -n 1)"
  assert_equals "0|Results: 127 passed, 0 failed" "$N6_SKIPS|$N6_RESULT" "req-001: req-006 suite prints no SKIP line and passes 127 cases natively"
fi

# 8. README Windows skip table has one row per suite.
ROW_005="$(grep -c '^| `test-0000041-req-005-applies-to-header.sh` |' "$README" || true)"
ROW_006="$(grep -c '^| `test-0000041-req-006-consumer-migration.sh` |' "$README" || true)"
assert_equals "1:1" "$ROW_005:$ROW_006" "req-001: tests/README.md Windows skip table has one row each for the req-005 and req-006 suites"

# 9 and 10. If mktemp fails, the req-005 suite exits non-zero and deletes nothing.
# The stand-in mktemp goes on PATH for this one run only. The caller folder is a
# scratch folder inside WORK, so a bug harms nothing outside it.
MKSTUB="$WORK/mktemp-stub-bin"
CALLER="$WORK/caller"
mkdir -p "$MKSTUB" "$CALLER"
cat > "$MKSTUB/mktemp" <<'MKSTUB_EOF'
#!/bin/sh
exit 1
MKSTUB_EOF
chmod +x "$MKSTUB/mktemp"
echo "keep" > "$CALLER/keep.txt"

CALLER_BEFORE="$(ls -A "$CALLER" 2>/dev/null | LC_ALL=C sort)"
MK_OUT="$WORK/mktemp-fail-005.out"
(cd "$CALLER" && PATH="$MKSTUB:$PATH" bash "$SUITE_005") > "$MK_OUT" 2>&1
MK_EXIT=$?
CALLER_AFTER="$(ls -A "$CALLER" 2>/dev/null | LC_ALL=C sort)"

# 9. req-005 exits non-zero when mktemp fails.
MK_NONZERO=no
[ "$MK_EXIT" -ne 0 ] && MK_NONZERO=yes
assert_equals "yes" "$MK_NONZERO" "req-001: req-005 suite exits non-zero when mktemp fails"

# 10. The caller folder, its sentinel and its listing survive.
CALLER_KEPT=no
[ -d "$CALLER" ] && [ -f "$CALLER/keep.txt" ] && [ "$CALLER_BEFORE" = "$CALLER_AFTER" ] && CALLER_KEPT=yes
assert_equals "yes" "$CALLER_KEPT" "req-001: req-005 suite leaves the caller folder and its entries intact when mktemp fails"

print_summary
