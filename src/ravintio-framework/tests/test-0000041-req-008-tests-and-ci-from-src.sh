#!/usr/bin/env bash
# Verified by: unit
# Verified by: integration
#
# Tests for feature 0000041-pack-source-under-src, req-008: suites and CI read
# the pack from src/ravintio-framework/ (ADR-009).
#
# Sections:
#   AC1 (unit)         the pack-root.sh resolver, run in scratch repos.
#   AC2 (integration)  the static scan of tests/*.sh and tests/regression/*.sh,
#                      then the workflow checks on .github/workflows/ravintio.yml.
#   AC3 (integration)  the release-copy-integrity step in scratch repos built
#                      with build-release.mjs. Build order step 5 adds it.
#
# Expected state after build order step 3: AC1 and the workflow checks are RED
# and the real scan is RED. The real scan stays red until build order step 7
# edits the suites it flags, and until req-007 fixes the version-bump suite.
#
# This suite finds the pack from its own folder because it tests the resolver.
# The planted lines are built in parts, so this file holds no match for the scan.
#
# Every regex is POSIX extended, as Bash 3.2 [[ =~ ]] and grep -E read it.
# Every loop reads lines with `done <<< "$(...)"`, never `done < <(...)`.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

SUITE_PACK="$(cd "$SCRIPT_DIR/.." && pwd)"
SUITE_TOP="$(cd "$SUITE_PACK/../.." && pwd)"
HELPER_SRC="$SUITE_PACK/tests/helpers/pack-root.sh"
PK_SRC="$SUITE_PACK/scripts/project-kind.mjs"

WORK="$(mktemp -d -t ravintio_0000041_req008_XXXXXX)" || { echo "  FAIL: req-008: mktemp -d failed"; exit 1; }
trap 'rm -rf "$WORK"' EXIT

PRODUCT_SRC='id: "ravintio-framework"
name: "RAVINTIO Framework"
version: "0.38.0"
versionPolicy: "max-component-version"

components:
  - id: "ravintio-framework"
    path: "src/ravintio-framework/component.yml"
'

MANIFEST='id: "ravintio-framework"
version: "0.38.0"
'

FAIL_LINE='FAIL: pack-root: this suite runs from the root release copy. Run it from src/ravintio-framework/tests/.'

# put_pack <dir>: lay down a pack copy (helper, project-kind.mjs, component.yml).
put_pack() {
  mkdir -p "$1/tests/helpers" "$1/scripts"
  if [ -f "$HELPER_SRC" ]; then
    cp "$HELPER_SRC" "$1/tests/helpers/pack-root.sh"
  fi
  cp "$PK_SRC" "$1/scripts/project-kind.mjs"
  printf '%s' "$MANIFEST" > "$1/component.yml"
}

# mk_source_repo <name>: product.yml, src/ravintio-framework/ and a root copy.
mk_source_repo() {
  local r="$WORK/$1"
  mkdir -p "$r"
  printf '%s' "$PRODUCT_SRC" > "$r/product.yml"
  put_pack "$r/src/ravintio-framework"
  put_pack "$r/ravintio-framework"
  echo "$r"
}

# mk_consumer_repo <name>: only the root pack, no product.yml source entry.
mk_consumer_repo() {
  local r="$WORK/$1"
  mkdir -p "$r"
  put_pack "$r/ravintio-framework"
  echo "$r"
}

# source_helper <helper path>: source it in a child shell. Sets RC and OUT.
source_helper() {
  OUT="$(bash -c 'source "$1" && printf "REL=%s\nTOP=%s\nPACK=%s\nSRC=%s\n" "$RAVINTIO_PACK_REL" "$RAVINTIO_REPO_ROOT" "$RAVINTIO_PACK_DIR" "$RAVINTIO_SOURCE_REPO"' _ "$1" 2>&1)"
  RC=$?
}

# ============================================================================
# AC1 (unit): the resolver
# ============================================================================

if [ -f "$HELPER_SRC" ]; then
  assert_equals "yes" "yes" "req-008: tests/helpers/pack-root.sh exists"
else
  assert_equals "yes" "no" "req-008: tests/helpers/pack-root.sh exists"
fi

# --- source repo, sourced from src/ravintio-framework/tests/ ----------------
R="$(mk_source_repo source)"
source_helper "$R/src/ravintio-framework/tests/helpers/pack-root.sh"
assert_equals "0" "$RC" "req-008: source repo from src pack exits 0"
assert_contains "REL=src/ravintio-framework" "$OUT" "req-008: source repo from src pack sets RAVINTIO_PACK_REL"
assert_contains "TOP=$R" "$OUT" "req-008: source repo from src pack sets RAVINTIO_REPO_ROOT to the repo"
assert_contains "PACK=$R/src/ravintio-framework" "$OUT" "req-008: source repo from src pack sets RAVINTIO_PACK_DIR"
assert_contains "SRC=yes" "$OUT" "req-008: source repo from src pack sets RAVINTIO_SOURCE_REPO to yes"

# --- source repo, sourced from the root release copy ------------------------
source_helper "$R/ravintio-framework/tests/helpers/pack-root.sh"
assert_equals "1" "$RC" "req-008: source repo from the root copy exits 1"
assert_equals "$FAIL_LINE" "$OUT" "req-008: source repo from the root copy prints the exact FAIL line"

# --- consumer layout --------------------------------------------------------
C="$(mk_consumer_repo consumer)"
source_helper "$C/ravintio-framework/tests/helpers/pack-root.sh"
assert_equals "0" "$RC" "req-008: consumer layout exits 0"
assert_contains "REL=ravintio-framework" "$OUT" "req-008: consumer layout sets RAVINTIO_PACK_REL to ravintio-framework"
assert_contains "TOP=$C" "$OUT" "req-008: consumer layout sets RAVINTIO_REPO_ROOT to the repo"
assert_contains "SRC=no" "$OUT" "req-008: consumer layout sets RAVINTIO_SOURCE_REPO to no"

# --- the helper exports nothing ---------------------------------------------
if [ -f "$HELPER_SRC" ]; then
  EXPORTED="$(bash -c 'source "$1" && env | grep -c "^RAVINTIO_\(PACK_DIR\|REPO_ROOT\|PACK_REL\|SOURCE_REPO\)="' _ "$R/src/ravintio-framework/tests/helpers/pack-root.sh" 2>/dev/null || true)"
else
  EXPORTED="helper missing"
fi
assert_equals "0" "$EXPORTED" "req-008: the helper exports none of its four variables"

# ============================================================================
# AC2 (integration): the static scan
# ============================================================================

# scan_pack <pack dir>: print "<tests-relative path>:<line>: pattern <n>" for
# each flagged line in tests/*.sh and tests/regression/*.sh. A line passes when
# it carries `# root-copy-ok: {reason}` with a non-empty reason.
RE_P1='(FRAMEWORK|FW|FW_DIR|FRAMEWORK_DIR|FRAMEWORK_SRC|RAVINTIO_PACK_DIR)\}?/\.\.'
RE_P2_TESTS='SCRIPT_DIR\}?/\.\./\.\.'
RE_P2_REG='SCRIPT_DIR\}?/\.\./\.\./\.\.'
RE_P3='(ROOT|REPO|REPO_ROOT|PROJECT_ROOT|RAVINTIO_REPO_ROOT)\}?/ravintio-framework'
RE_P4="git .*(['\"]|:!|:\\(exclude\\))ravintio-framework/"
RE_MARK='# root-copy-ok: *[^ ]'

scan_pack() {
  local pack="$1" f rel line n p2 hits
  for f in "$pack"/tests/*.sh "$pack"/tests/regression/*.sh; do
    [ -f "$f" ] || continue
    rel="${f#$pack/}"
    p2="$RE_P2_TESTS"
    case "$rel" in tests/regression/*) p2="$RE_P2_REG" ;; esac
    n=0
    while IFS= read -r line || [ -n "$line" ]; do
      n=$((n + 1))
      if [[ "$line" =~ $RE_MARK ]]; then continue; fi
      hits=""
      if [[ "$line" =~ $RE_P1 ]]; then hits="1"; fi
      if [[ "$line" =~ $p2 ]]; then hits="${hits:+$hits,}2"; fi
      if [[ "$line" =~ $RE_P3 ]]; then hits="${hits:+$hits,}3"; fi
      if [[ "$line" =~ $RE_P4 ]]; then hits="${hits:+$hits,}4"; fi
      if [ -n "$hits" ]; then echo "$rel:$n: pattern $hits"; fi
    done < "$f"
  done
}

# Planted lines, built in parts so this file holds no match.
V1='FW'
V2='SCRIPT_DIR'
V3='REPO_ROOT'
V4='ravintio'
PL1="cd \"\${${V1}}/..\""
PL2_TESTS="x=\"\$${V2}/../..\""
PL2_REG="x=\"\$${V2}/../../..\""
PL3="ls \"\$${V3}/${V4}-framework/x\""
PL4="git ls-files -- '${V4}-framework/x'"
MARK_OK='# root-copy-ok: history stores this path'
MARK_EMPTY='# root-copy-ok:'

# plant <name> <rel path> <line>: scratch pack with a clean line 1 and the
# planted line 2. Scans it and prints the result.
plant() {
  local d="$WORK/plant-$1" rel="$2" line="$3"
  mkdir -p "$d/tests/regression"
  printf '%s\n%s\n' 'echo clean' "$line" > "$d/$rel"
  scan_pack "$d"
}

assert_equals "tests/p1.sh:2: pattern 1" "$(plant p1 tests/p1.sh "$PL1")" "req-008: scan flags a climb out of the pack with file and line"
assert_equals "tests/p2.sh:2: pattern 2" "$(plant p2 tests/p2.sh "$PL2_TESTS")" "req-008: scan flags SCRIPT_DIR two levels up in tests/"
assert_equals "" "$(plant p2r tests/regression/p2r.sh "$PL2_TESTS")" "req-008: scan allows SCRIPT_DIR two levels up in tests/regression/"
assert_equals "tests/regression/p2r.sh:2: pattern 2" "$(plant p2r2 tests/regression/p2r.sh "$PL2_REG")" "req-008: scan flags SCRIPT_DIR three levels up in tests/regression/"
assert_equals "tests/p3.sh:2: pattern 3" "$(plant p3 tests/p3.sh "$PL3")" "req-008: scan flags a repo-root read of the root copy"
assert_equals "tests/p4.sh:2: pattern 4" "$(plant p4 tests/p4.sh "$PL4")" "req-008: scan flags a git line with a literal root pathspec"
assert_equals "" "$(plant m1 tests/m1.sh "$PL1  $MARK_OK")" "req-008: scan passes a pattern 1 line with a root-copy-ok marker"
assert_equals "" "$(plant m3 tests/m3.sh "$PL3  $MARK_OK")" "req-008: scan passes a pattern 3 line with a root-copy-ok marker"
assert_equals "" "$(plant m4 tests/m4.sh "$PL4  $MARK_OK")" "req-008: scan passes a pattern 4 line with a root-copy-ok marker"
assert_equals "tests/e1.sh:2: pattern 1" "$(plant e1 tests/e1.sh "$PL1  $MARK_EMPTY")" "req-008: scan flags a marker with an empty reason"
assert_equals "" "$(plant ok tests/ok.sh 'FX="$WORK/fixture"; mkdir -p "$FX/ravintio-framework"')" "req-008: scan ignores a fixture variable outside the list"

# The real scan over this pack. RED until build order step 7 edits the suites it
# flags and req-007 fixes test-0000039-req-010-version-bump.sh.
REAL_SCAN="$(scan_pack "$SUITE_PACK")"
if [ -n "$REAL_SCAN" ]; then
  echo "        flagged lines:"
  echo "$REAL_SCAN" | head -40 | sed 's/^/          /'
  echo "          ($(echo "$REAL_SCAN" | wc -l | tr -d ' ') flagged in total)"
fi
assert_equals "" "$REAL_SCAN" "req-008: the real scan flags no line in tests/ or tests/regression/"

# ============================================================================
# AC2 (integration): the workflow checks
# ============================================================================

WF="$SUITE_TOP/.github/workflows/ravintio.yml"
PACK_P='src/ravintio-framework'

# wf_count <fixed string>: print how many workflow lines hold the string.
wf_count() {
  grep -cF -- "$1" "$WF" 2>/dev/null || true
}

assert_equals "1" "$(wf_count "run: node $PACK_P/scripts/self-description-check.mjs .")" "req-008: self-description-check runs from the src pack"
assert_equals "1" "$(wf_count "run: bash $PACK_P/tests/run-tests.sh")" "req-008: test-suite runs run-tests.sh from the src pack"
assert_equals "2" "$(wf_count "run: ./$PACK_P/tests/test_setup.ps1")" "req-008: setup-powershell and setup-powershell-51 run test_setup.ps1 from the src pack"
assert_equals "1" "$(wf_count 'src\ravintio-framework\migrations\migrate-0.37.0-ravintio-rename.ps1')" "req-008: setup-powershell-51 parses the helper from the src pack"
assert_equals "1" "$(wf_count "bash $PACK_P/tests/test-0000039-req-006-consumer-migration.sh")" "req-008: setup-powershell-51 runs the req-006 suite from the src pack"
assert_equals "1" "$(wf_count "bash $PACK_P/tests/test-0000040-req-004-remove-track-files.sh")" "req-008: setup-powershell-51 runs the 0000040 req-004 suite from the src pack"

OLD_CMDS="$(grep -cE '(bash |node |\./)ravintio-framework/(scripts|tests)/' "$WF" 2>/dev/null || true)"
assert_equals "0" "$OLD_CMDS" "req-008: no workflow command runs a pack path from the root copy"

JOB_BLOCK="$(awk '/^  release-copy-integrity:/{f=1; print; next} f && /^  [A-Za-z0-9_-]+:/{exit} f{print}' "$WF" 2>/dev/null)"
if [ -n "$JOB_BLOCK" ]; then
  assert_equals "yes" "yes" "req-008: ravintio.yml holds a release-copy-integrity job"
else
  assert_equals "yes" "no" "req-008: ravintio.yml holds a release-copy-integrity job"
fi
if [[ "$JOB_BLOCK" =~ permissions:[[:space:]]*$'\n'[[:space:]]*contents:[[:space:]]*read ]]; then
  assert_equals "yes" "yes" "req-008: release-copy-integrity has permissions contents: read"
else
  assert_equals "yes" "no" "req-008: release-copy-integrity has permissions contents: read"
fi
assert_contains "node $PACK_P/scripts/release-check.mjs --root . --files-only" "$JOB_BLOCK" "req-008: release-copy-integrity runs release-check.mjs in files-only mode"

# ============================================================================
# AC3 (integration): the release-copy-integrity step in scratch repos
# Build order step 5 adds these cases here. They build each root copy with
# build-release.mjs and run the step's run: block from ravintio.yml.
# ============================================================================

print_summary
