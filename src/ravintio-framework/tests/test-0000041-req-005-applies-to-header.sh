#!/usr/bin/env bash
# Verified by: unit
#
# Tests for feature 0000041-pack-source-under-src, req-005: applies-to header
# and the source-repo signal (ADR-007).
#
# Scope of this step: AC1 only, the project-kind.mjs cases. The header and
# migrator rule cases (AC2 and AC3) come at a later build step.
#
# The suite finds the pack from its own folder because the req-008 resolver
# does not exist yet. Each case builds a scratch repo in a temporary folder.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$(cd "$SCRIPT_DIR/.." && pwd)"
PK="$FW/scripts/project-kind.mjs"
MANIFEST_PATH="src/ravintio-framework/component.yml"

WORK="$(mktemp -d -t ravintio_0000041_req005_XXXXXX)" || { echo "  FAIL: req-005: mktemp -d failed"; exit 1; }
trap 'rm -rf "$WORK"' EXIT

PRODUCT_OK='id: "ravintio-framework"
name: "RAVINTIO Framework"
version: "0.38.0"
versionPolicy: "max-component-version"

components:
  - id: "ravintio-framework"
    path: "src/ravintio-framework/component.yml"
  - id: "setup-hook-integration"
    path: "src/setup-hook-integration/component.yml"
'

# mk_repo <name>: a scratch root that meets all three conditions.
mk_repo() {
  local r="$WORK/$1"
  mkdir -p "$r/src/ravintio-framework"
  printf '%s' "$PRODUCT_OK" > "$r/product.yml"
  printf 'id: "ravintio-framework"\nversion: "0.38.0"\n' > "$r/$MANIFEST_PATH"
  echo "$r"
}

# run_pk <args...>: run the script, keep stdout, stderr and the exit code.
run_pk() {
  node "$PK" "$@" >"$WORK/out" 2>"$WORK/err"
  RC=$?
  OUT="$(cat "$WORK/out")"
  ERR="$(cat "$WORK/err")"
}

# expect_downstream <root> <label>: exit 0, stdout downstream, reason on stderr.
expect_downstream() {
  run_pk --root "$1"
  assert_equals "0" "$RC" "req-005: $2 exits 0"
  assert_equals "downstream" "$OUT" "req-005: $2 prints downstream"
  if [ -n "$ERR" ]; then
    assert_equals "yes" "yes" "req-005: $2 gives a reason on stderr"
  else
    assert_equals "yes" "no" "req-005: $2 gives a reason on stderr"
  fi
}

# The script exists. Every later case needs it.
if [ -f "$PK" ]; then
  assert_equals "yes" "yes" "req-005: scripts/project-kind.mjs exists"
else
  assert_equals "yes" "no" "req-005: scripts/project-kind.mjs exists"
fi

# --- framework source -------------------------------------------------------
R="$(mk_repo source)"
run_pk --root "$R"
assert_equals "0" "$RC" "req-005: framework source root exits 0"
assert_equals "framework source" "$OUT" "req-005: all three conditions hold prints framework source"

# --root default is the current folder
(cd "$R" && node "$PK" >"$WORK/out" 2>"$WORK/err"); RC=$?
assert_equals "0" "$RC" "req-005: no --root uses the current folder and exits 0"
assert_equals "framework source" "$(cat "$WORK/out")" "req-005: no --root prints framework source in a source folder"

# --- downstream cases -------------------------------------------------------
R="$(mk_repo no-product)"; rm -f "$R/product.yml"
expect_downstream "$R" "no product.yml"
assert_contains "product.yml" "$ERR" "req-005: no product.yml reason names product.yml"

R="$(mk_repo linked-product)"
mv "$R/product.yml" "$R/real-product.yml"; ln -s real-product.yml "$R/product.yml"
expect_downstream "$R" "linked product.yml"

R="$(mk_repo no-entry)"
printf 'id: "other"\ncomponents:\n  - id: "setup-hook-integration"\n    path: "src/setup-hook-integration/component.yml"\n' > "$R/product.yml"
expect_downstream "$R" "no ravintio-framework entry"

R="$(mk_repo wrong-path)"
printf 'id: "ravintio-framework"\ncomponents:\n  - id: "ravintio-framework"\n    path: "ravintio-framework/component.yml"\n' > "$R/product.yml"
expect_downstream "$R" "a different path"

R="$(mk_repo no-manifest)"; rm -f "$R/$MANIFEST_PATH"
expect_downstream "$R" "missing component.yml"

R="$(mk_repo linked-manifest)"
mv "$R/$MANIFEST_PATH" "$R/real-component.yml"; ln -s ../../real-component.yml "$R/$MANIFEST_PATH"
expect_downstream "$R" "linked component.yml"

R="$(mk_repo linked-dir)"
mv "$R/src/ravintio-framework" "$R/real-pack"; ln -s ../real-pack "$R/src/ravintio-framework"
expect_downstream "$R" "linked src/ravintio-framework folder"

R="$(mk_repo linked-src)"
mv "$R/src" "$R/real-src"; ln -s real-src "$R/src"
expect_downstream "$R" "linked src folder"

R="$(mk_repo malformed)"
printf '\001\002 :: [ { not yaml\n  - - id\n"unterminated\n' > "$R/product.yml"
expect_downstream "$R" "malformed product.yml"

R="$(mk_repo empty-product)"; : > "$R/product.yml"
expect_downstream "$R" "empty product.yml"

R="$WORK/no-such-dir"
expect_downstream "$R" "a root that does not exist"

# --- bad argument -----------------------------------------------------------
run_pk --bogus
assert_equals "2" "$RC" "req-005: an unknown argument exits 2"

R="$(mk_repo arg-source)"
run_pk --root
assert_equals "2" "$RC" "req-005: --root with no value exits 2"

# --- exported function ------------------------------------------------------
R="$(mk_repo fn-source)"
FN_OUT="$(node --input-type=module -e "
import { projectKind } from '$PK';
const r = projectKind('$R');
console.log(JSON.stringify({ kind: r.kind, reasonType: typeof r.reason }));
" 2>/dev/null)"
assert_equals '{"kind":"framework source","reasonType":"string"}' "$FN_OUT" "req-005: projectKind(root) returns kind framework source and a string reason"

R="$(mk_repo fn-down)"; rm -f "$R/product.yml"
FN_OUT="$(node --input-type=module -e "
import { projectKind } from '$PK';
const r = projectKind('$R');
console.log(JSON.stringify({ kind: r.kind, hasReason: typeof r.reason === 'string' && r.reason.length > 0 }));
" 2>/dev/null)"
assert_equals '{"kind":"downstream","hasReason":true}' "$FN_OUT" "req-005: projectKind(root) returns kind downstream and a reason"

# --- no file written --------------------------------------------------------
R="$(mk_repo no-write)"
BEFORE="$(cd "$R" && find . | sort | tr '\n' ' ')"
run_pk --root "$R"
AFTER="$(cd "$R" && find . | sort | tr '\n' ' ')"
assert_equals "$BEFORE" "$AFTER" "req-005: project-kind.mjs writes no file"

print_summary
