#!/usr/bin/env bash
# Verified by: unit
# Verified by: integration
#
# Tests for feature 0000041-pack-source-under-src, req-005: applies-to header
# and the source-repo signal (ADR-007).
#
# Scope: AC1 (project-kind.mjs cases) and the text half of AC2 and AC3 (the
# migrator SKILL.md rule and the released retroactive-release-tags.md).
#
# The suite finds the pack through helpers/pack-root.sh (req-008 resolver).
# Each project-kind case builds a scratch repo in a temporary folder.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
source "$SCRIPT_DIR/helpers/pack-root.sh"

FW="$RAVINTIO_PACK_DIR"
PK="$FW/scripts/project-kind.mjs"
MANIFEST_PATH="src/ravintio-framework/component.yml"

# Git Bash gives /tmp/x, which node reads as C:\tmp\x inside a node -e script. pwd -W gives the Windows form.
WORK="$(cd "$(mktemp -d -t ravintio_0000041_req005_XXXXXX)" && { pwd -W 2>/dev/null || pwd; })" || { echo "  FAIL: req-005: mktemp -d failed"; exit 1; }
trap 'rm -rf "$WORK"' EXIT

native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

# IS_WIN: yes under Git Bash, MSYS, or Cygwin. There, ln -s copies the target.
IS_WIN=no
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) IS_WIN=yes ;; esac

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

R="$(mk_repo no-entry)"
printf 'id: "other"\ncomponents:\n  - id: "setup-hook-integration"\n    path: "src/setup-hook-integration/component.yml"\n' > "$R/product.yml"
expect_downstream "$R" "no ravintio-framework entry"

R="$(mk_repo wrong-path)"
printf 'id: "ravintio-framework"\ncomponents:\n  - id: "ravintio-framework"\n    path: "ravintio-framework/component.yml"\n' > "$R/product.yml"
expect_downstream "$R" "a different path"

R="$(mk_repo no-manifest)"; rm -f "$R/$MANIFEST_PATH"
expect_downstream "$R" "missing component.yml"

# The four linked-path cases. ln -s makes a copy under Git Bash, so Windows skips them.
if [ "$IS_WIN" = yes ]; then
  echo "  SKIP (windows): linked product.yml: ln -s makes a copy under Git Bash, so a link cannot be built"
  echo "  SKIP (windows): linked component.yml: ln -s makes a copy under Git Bash, so a link cannot be built"
  echo "  SKIP (windows): linked src/ravintio-framework folder: ln -s makes a copy under Git Bash, so a link cannot be built"
  echo "  SKIP (windows): linked src folder: ln -s makes a copy under Git Bash, so a link cannot be built"
else
  R="$(mk_repo linked-product)"
  mv "$R/product.yml" "$R/real-product.yml"; ln -s real-product.yml "$R/product.yml"
  expect_downstream "$R" "linked product.yml"

  R="$(mk_repo linked-manifest)"
  mv "$R/$MANIFEST_PATH" "$R/real-component.yml"; ln -s ../../real-component.yml "$R/$MANIFEST_PATH"
  expect_downstream "$R" "linked component.yml"

  R="$(mk_repo linked-dir)"
  mv "$R/src/ravintio-framework" "$R/real-pack"; ln -s ../real-pack "$R/src/ravintio-framework"
  expect_downstream "$R" "linked src/ravintio-framework folder"

  R="$(mk_repo linked-src)"
  mv "$R/src" "$R/real-src"; ln -s real-src "$R/src"
  expect_downstream "$R" "linked src folder"
fi

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
const { pathToFileURL } = await import('node:url');
const { projectKind } = await import(pathToFileURL('$(native "$PK")').href);
const r = projectKind('$R');
console.log(JSON.stringify({ kind: r.kind, reasonType: typeof r.reason }));
" 2>/dev/null)"
assert_equals '{"kind":"framework source","reasonType":"string"}' "$FN_OUT" "req-005: projectKind(root) returns kind framework source and a string reason"

R="$(mk_repo fn-down)"; rm -f "$R/product.yml"
FN_OUT="$(node --input-type=module -e "
const { pathToFileURL } = await import('node:url');
const { projectKind } = await import(pathToFileURL('$(native "$PK")').href);
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

# ============================================================================
# AC2: the migrator SKILL.md documents the header and the Step 1b rule
# ============================================================================
MIG="$FW/skills/ravintio-migrator/SKILL.md"
if [ -f "$MIG" ]; then MIG_TEXT="$(cat "$MIG")"; else MIG_TEXT=""; fi

# has <label> <extended regex> <text>: assert that a line of text matches.
has() {
  if printf '%s\n' "$3" | grep -Eiq -e "$2"; then
    assert_equals "yes" "yes" "req-005: $1"
  else
    assert_equals "yes" "no" "req-005: $1"
  fi
}

# Step 1b section: from its heading to the next heading of the same level.
STEP1B="$(awk '/^### Step 1b/ {on=1; print; next} on && /^### / {exit} on {print}' "$MIG" 2>/dev/null)"

# --- the header and its three values ----------------------------------------
has "migrator documents the **Applies to:** line" '[*][*]Applies to:[*][*]' "$MIG_TEXT"
has "migrator documents the value framework source for Applies to" 'Applies to:[*][*].*`framework source`' "$MIG_TEXT"
has "migrator documents the value downstream for Applies to" 'Applies to:[*][*].*`downstream`' "$MIG_TEXT"
has "migrator documents the value all for Applies to" 'Applies to:[*][*].*`all`' "$MIG_TEXT"
has "migrator says an absent Applies to line reads as all" '(absent|no .*Applies to|no such line|no header).*reads? as `all`|reads? as `all`.*(absent|no header)' "$MIG_TEXT"

# --- the released-migrations table ------------------------------------------
TABLE="$(awk '/Released migrations by project kind/ {on=1; next} on && /^#/ {exit} on {print}' "$MIG" 2>/dev/null)"
has "migrator holds a Released migrations by project kind heading" 'Released migrations by project kind' "$MIG_TEXT"
has "table maps retroactive-release-tags.md to framework source" '^[|].*retroactive-release-tags[.]md.*framework source' "$TABLE"
ROWS="$(printf '%s\n' "$TABLE" | grep -c '[.]md')"
assert_equals "1" "$ROWS" "req-005: the Released migrations by project kind table has one row"
has "migrator reads the table before a file with no header" 'table' "$STEP1B"

# --- Step 1b order ----------------------------------------------------------
has "Step 1b is the project-kind check" 'project[- ]kind' "$(printf '%s\n' "$STEP1B" | head -1)"
has "Step 1b runs project-kind.mjs" 'project-kind[.]mjs' "$STEP1B"
has "Step 1b stops and records nothing when the script fails" '(fails?|error).*stop|stop.*(fails?|error)' "$STEP1B"
has "Step 1b stops for an Applies to value that is not one of the three" 'not one of|unknown value|invalid' "$STEP1B"
has "Step 1b records nothing for a stop" 'record(s)? nothing|no record' "$STEP1B"
has "Step 1b records not applicable on a kind mismatch" 'not applicable' "$STEP1B"
has "Step 1b mismatch records both counts at 0" 'both counts at `0`' "$STEP1B"
has "Step 1b mismatch body names the project kind and the header value" 'names? the project kind and the (header|Applies to)' "$STEP1B"
has "Step 1b reads Target when the value is all or matches the kind" '(`all`|matches).*Target|Target.*(`all`|matches)' "$STEP1B"

pos() { printf '%s\n' "$STEP1B" | grep -n -m1 -Ei -e "$1" | cut -d: -f1; }
P_RUN="$(pos 'project-kind[.]mjs')"
P_HDR="$(pos '[*][*]Applies to:[*][*]')"
P_NA="$(pos 'not applicable')"
P_TGT="$(pos '[*][*]Target:[*][*]')"
if [ -n "$P_RUN" ] && [ -n "$P_HDR" ] && [ -n "$P_NA" ] && [ -n "$P_TGT" ] \
   && [ "$P_RUN" -lt "$P_HDR" ] && [ "$P_HDR" -lt "$P_NA" ] && [ "$P_NA" -lt "$P_TGT" ]; then
  assert_equals "yes" "yes" "req-005: Step 1b order is script, header, mismatch record, Target"
else
  assert_equals "yes" "no" "req-005: Step 1b order is script, header, mismatch record, Target (lines: ${P_RUN:-none} ${P_HDR:-none} ${P_NA:-none} ${P_TGT:-none})"
fi

# --- the Target check and the reporting rule --------------------------------
has "Target check takes the kind from the same script" 'Target.*(same|that) script|(same|that) script.*Target' "$STEP1B"
if printf '%s\n' "$STEP1B" | grep -Fq 'has `id: "ravintio-framework"`'; then
  assert_equals "yes" "no" "req-005: Step 1b no longer tests the root product.yml id"
else
  assert_equals "yes" "yes" "req-005: Step 1b no longer tests the root product.yml id"
fi
has "migrator reports each not applicable record and its reason to the human" 'report.*not applicable.*reason|report.*reason.*not applicable' "$STEP1B"

# ============================================================================
# AC3: the released retroactive-release-tags.md keeps the v0.38.0 blob id
# ============================================================================
# Blob ids ignore line-ending conversion: hash-object runs inside the repo, so core.autocrlf applies.
REL="$FW/migrations/retroactive-release-tags.md"
REL_PATH="$RAVINTIO_PACK_REL/migrations/retroactive-release-tags.md"
OLD_ID="$(git -C "$RAVINTIO_REPO_ROOT" rev-parse v0.38.0:ravintio-framework/migrations/retroactive-release-tags.md 2>/dev/null)" # root-copy-ok: history stores the released file at the old path
HEAD_ID="$(git -C "$RAVINTIO_REPO_ROOT" rev-parse "HEAD:$REL_PATH" 2>/dev/null)"
WT_ID="$(git -C "$RAVINTIO_REPO_ROOT" hash-object --path="$REL_PATH" "$REL" 2>/dev/null)"
if [ -n "$OLD_ID" ] && [ "$OLD_ID" = "$HEAD_ID" ] && [ "$OLD_ID" = "$WT_ID" ]; then
  assert_equals "yes" "yes" "req-005: retroactive-release-tags.md blob id matches v0.38.0 at HEAD and in the working tree"
else
  assert_equals "yes" "no" "req-005: retroactive-release-tags.md blob id matches v0.38.0 at HEAD and in the working tree (v0.38.0=${OLD_ID:-none} HEAD=${HEAD_ID:-none} tree=${WT_ID:-none})"
fi

print_summary
