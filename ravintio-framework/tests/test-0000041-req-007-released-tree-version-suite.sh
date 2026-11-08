#!/usr/bin/env bash
# Verified by: integration
# Verified by: execution
#
# Tests for feature 0000041-pack-source-under-src, req-007: the version suite
# test-0000039-req-010-version-bump.sh runs its equality checks on a released
# tree only, and it finds the pack and the repo through pack-root.sh
# (backlog 0000368, ADR-009).
#
# Sections:
#   AC1 (integration)  open run: plan/current/design.md present, component.yml
#                      ahead of product.yml and docs/about.md. Exit 0, three
#                      SKIP (open run) lines, the other checks still run.
#   AC2 (integration)  released tree: design.md absent. A mismatch fails the
#                      three checks, equal versions pass with no SKIP line.
#   AC3 (execution)    the suite sources pack-root.sh, the static scan of
#                      req-008 no longer flags it, and the AC2 scan reads the
#                      pack source and skips the root release copy.
#
# Each case copies the real version suite and its helpers into a scratch git
# repo, so pack-root.sh resolves there. The real repo is never changed.
#
# Every regex is POSIX extended, as Bash 3.2 [[ =~ ]] and grep -E read it.
# Every loop reads lines with `done <<< "$(...)"`, never `done < <(...)`.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

SUITE_PACK="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_SUITE="$SUITE_PACK/tests/test-0000039-req-010-version-bump.sh"

WORK="$(mktemp -d -t ravintio_0000041_req007_XXXXXX)" || { echo "  FAIL: req-007: mktemp -d failed"; exit 1; }
trap 'rm -rf "$WORK"' EXIT

PACK_REL="src/ravintio-framework"

# mk_repo <name> <component version> <product version> <about version> [open]
# Build a committed scratch repo. The fourth argument "open" adds
# plan/current/design.md. Prints the repo path.
mk_repo() {
  local name="$1" cv="$2" pv="$3" av="$4" mode="${5:-released}"
  local r="$WORK/$name" p="$WORK/$name/$PACK_REL"
  mkdir -p "$p/tests/helpers" "$p/scripts" "$r/docs" "$r/plan"
  cp "$SUITE_PACK/tests/helpers/assert.sh" "$p/tests/helpers/assert.sh"
  cp "$SUITE_PACK/tests/helpers/pack-root.sh" "$p/tests/helpers/pack-root.sh"
  cp "$SUITE_PACK/scripts/project-kind.mjs" "$p/scripts/project-kind.mjs"
  cp "$SUITE_PACK/scripts/product-version.mjs" "$p/scripts/product-version.mjs"
  cp "$VERSION_SUITE" "$p/tests/test-0000039-req-010-version-bump.sh"
  printf 'id: "ravintio-framework"\nversion: "%s"\n' "$cv" > "$p/component.yml"
  printf 'id: "ravintio-framework"\nname: "RAVINTIO Framework"\nversion: "%s"\nversionPolicy: "max-component-version"\n\ncomponents:\n  - id: "ravintio-framework"\n    path: "%s/component.yml"\n' \
    "$pv" "$PACK_REL" > "$r/product.yml"
  printf -- '---\nversion: "%s"\nfeature: "x"\n---\n# About\n\n| Field | Value |\n|-------|-------|\n| Version | `%s` |\n' "$av" "$av" > "$r/docs/about.md"
  # AC2 needs at least one classified hit, so plant a removal-point line.
  printf 'Old names are removed at 1.0.0.\n' > "$r/docs/removal.md"
  if [ "$mode" = "open" ]; then
    mkdir -p "$r/plan/current"
    printf '# design\n' > "$r/plan/current/design.md"
  fi
  echo "$r"
}

# commit_repo <repo>: init and commit everything so git grep sees it.
commit_repo() {
  ( cd "$1" && git init -q . \
    && git add -A \
    && git -c user.name=t -c user.email=t@example.com commit -q -m scratch ) >/dev/null 2>&1
}

# run_suite <repo>: run the copied version suite. Sets OUT and CODE.
run_suite() {
  OUT="$(cd "$1" && bash "$1/$PACK_REL/tests/test-0000039-req-010-version-bump.sh" 2>&1)"
  CODE=$?
}

assert_has() { # assert_has <haystack> <needle> <message>: assert_contains takes the needle first
  assert_contains "$2" "$1" "$3"
}

count_lines() { # count_lines <regex>: matching lines in OUT
  local n
  n="$(printf '%s\n' "$OUT" | grep -Ec "$1" || true)"
  echo "$n"
}

REASON='plan/current/design.md exists, so P7 has not set product.yml and docs/about.md yet. The check runs on a released tree.'
CHECK_PRODUCT='product.yml version reads 0.39.0'
CHECK_FM='docs/about.md frontmatter version reads 0.39.0'
CHECK_TABLE='docs/about.md table Version cell reads 0.39.0'

# ============================================================================
# AC1 (integration): open run skips the three equality checks
# ============================================================================

R="$(mk_repo open-mismatch 0.39.0 0.38.0 0.38.0 open)"; commit_repo "$R"
run_suite "$R"
assert_equals "0" "$CODE" "req-007 AC1: open run with component.yml ahead of product.yml and about.md exits 0"
assert_has "$OUT" "SKIP (open run): $CHECK_PRODUCT. $REASON" "req-007 AC1: open run skips the product.yml check with the reason"
assert_has "$OUT" "SKIP (open run): $CHECK_FM. $REASON" "req-007 AC1: open run skips the about.md frontmatter check with the reason"
assert_has "$OUT" "SKIP (open run): $CHECK_TABLE. $REASON" "req-007 AC1: open run skips the about.md table check with the reason"
assert_equals "3" "$(count_lines '^SKIP \(open run\):')" "req-007 AC1: open run prints exactly three SKIP lines"
assert_equals "0" "$(count_lines 'FAIL:.*(product\.yml version reads|about\.md (frontmatter|table))')" "req-007 AC1: open run reports no equality failure"
assert_has "$OUT" "PASS: req-010 AC1: $PACK_REL/component.yml version is a 0.37 or later 0.x release" "req-007 AC1: open run still checks the component.yml format, labelled with the pack path"
assert_has "$OUT" "PASS: req-010 AC1: $PACK_REL/component.yml version reads 0.39.0" "req-007 AC1: open run still checks component.yml reads its own value"
assert_has "$OUT" "PASS: req-010 AC1: product-version.mjs prints 0.39.0" "req-007 AC1: open run still checks product-version.mjs"
assert_has "$OUT" "PASS: req-010 AC2: no hit names 1.0.0 as the current release" "req-007 AC1: open run still runs the AC2 scan"
OPEN_SUMMARY="$(printf '%s\n' "$OUT" | grep -E '^Results:' | sed -E 's/^Results: ([0-9]+) passed.*/\1/')"

# Open run with equal versions still skips, since the rule keys on design.md.
R="$(mk_repo open-equal 0.39.0 0.39.0 0.39.0 open)"; commit_repo "$R"
run_suite "$R"
assert_equals "3" "$(count_lines '^SKIP \(open run\):')" "req-007 AC1: open run with equal versions still prints three SKIP lines"
assert_equals "0" "$CODE" "req-007 AC1: open run with equal versions exits 0"

# ============================================================================
# AC2 (integration): released tree runs the equality checks
# ============================================================================

R="$(mk_repo released-mismatch 0.39.0 0.38.0 0.38.0 released)"; commit_repo "$R"
run_suite "$R"
if [ "$CODE" -ne 0 ]; then RC=nonzero; else RC=zero; fi
assert_equals "nonzero" "$RC" "req-007 AC2: released tree with a version mismatch exits non-zero"
assert_has "$OUT" "FAIL: req-010 AC1: $CHECK_PRODUCT" "req-007 AC2: released tree fails the product.yml check"
assert_has "$OUT" "FAIL: req-010 AC1: $CHECK_FM" "req-007 AC2: released tree fails the about.md frontmatter check"
assert_has "$OUT" "FAIL: req-010 AC1: $CHECK_TABLE" "req-007 AC2: released tree fails the about.md table check"
assert_equals "0" "$(count_lines 'SKIP \(open run\)')" "req-007 AC2: released tree with a mismatch prints no SKIP (open run) line"

R="$(mk_repo released-equal 0.39.0 0.39.0 0.39.0 released)"; commit_repo "$R"
run_suite "$R"
assert_equals "0" "$CODE" "req-007 AC2: released tree with equal versions exits 0"
assert_equals "0" "$(count_lines 'SKIP \(open run\)')" "req-007 AC2: released tree with equal versions prints no SKIP (open run) line"
REL_SUMMARY="$(printf '%s\n' "$OUT" | grep -E '^Results:' | sed -E 's/^Results: ([0-9]+) passed.*/\1/')"
if [ -n "$OPEN_SUMMARY" ] && [ -n "$REL_SUMMARY" ] && [ "$((REL_SUMMARY - OPEN_SUMMARY))" -eq 3 ]; then R3=ok; else R3="open=$OPEN_SUMMARY released=$REL_SUMMARY"; fi
assert_equals "ok" "$R3" "req-007 AC2: a skip counts as neither pass nor fail (released passes exceed open passes by exactly 3)"

# ============================================================================
# AC3 (execution): resolver, static scan, and the pack-source AC2 scan
# ============================================================================

assert_equals "1" "$(grep -Ec '^[[:space:]]*(source|\.)[[:space:]]+.*helpers/pack-root\.sh' "$VERSION_SUITE" || true)" "req-007 AC3: the version suite sources helpers/pack-root.sh"

# The req-008 patterns, copied here. Run them over the version suite alone.
RE_P1='(FRAMEWORK|FW|FW_DIR|FRAMEWORK_DIR|FRAMEWORK_SRC|RAVINTIO_PACK_DIR)\}?/\.\.'
RE_P2_TESTS='SCRIPT_DIR\}?/\.\./\.\.'
RE_P3='(ROOT|REPO|REPO_ROOT|PROJECT_ROOT|RAVINTIO_REPO_ROOT)\}?/ravintio-framework'
RE_P4="git .*(['\"]|:!|:\\(exclude\\))ravintio-framework/"
RE_MARK='# root-copy-ok: *[^ ]'
FLAGGED=""
n=0
while IFS= read -r line || [ -n "$line" ]; do
  n=$((n + 1))
  if [[ "$line" =~ $RE_MARK ]]; then continue; fi
  if [[ "$line" =~ $RE_P1 || "$line" =~ $RE_P2_TESTS || "$line" =~ $RE_P3 || "$line" =~ $RE_P4 ]]; then
    FLAGGED+="$n "
  fi
done < "$VERSION_SUITE"
assert_equals "" "$FLAGGED" "req-007 AC3: the req-008 static scan flags no line of the version suite"

HDR="$(sed -n '1,25p' "$VERSION_SUITE")"
assert_has "$HDR" "0000368" "req-007 AC3: the version suite header cites backlog 0000368"
assert_has "$HDR" "req-007" "req-007 AC3: the version suite header cites req-007"

# The AC2 scan reads the pack source and skips the root release copy.
R="$(mk_repo scan-root-copy 0.39.0 0.39.0 0.39.0 released)"
mkdir -p "$R/ravintio-framework/docs"
printf 'The current release is 1.0.0 today.\n' > "$R/ravintio-framework/docs/frozen.md"
commit_repo "$R"
run_suite "$R"
assert_equals "0" "$CODE" "req-007 AC3: a 1.0.0 line in the root release copy is not scanned"

R="$(mk_repo scan-pack-src 0.39.0 0.39.0 0.39.0 released)"
printf 'The current release is 1.0.0 today.\n' > "$R/$PACK_REL/docs-planted.md"
commit_repo "$R"
run_suite "$R"
if [ "$CODE" -ne 0 ]; then RC=nonzero; else RC=zero; fi
assert_equals "nonzero" "$RC" "req-007 AC3: a 1.0.0 line in the pack source fails the AC2 scan"
assert_has "$OUT" "$PACK_REL/docs-planted.md" "req-007 AC3: the AC2 failure names the pack source path"

print_summary
