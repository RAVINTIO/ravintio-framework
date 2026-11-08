#!/usr/bin/env bash
# Tests for feature 0000039-ravintio-rebrand.
#
# req-010: the rename release carries a 0.37 version, and no live file names
#          1.0.0 as the current release (ADR-003).
#   AC1: product.yml, ravintio-framework/component.yml and docs/about.md
#        (frontmatter and table) read the same 0.37.x version, and
#        product-version.mjs prints it. A patch release keeps the 0.37 minor.
#   AC2: every `git grep` hit for 1.0.0 names it as the removal point for
#        old-name reads, or sits in a third-party or non-release version field.
#        The EXEMPT list names the paths the scan skips (backlog 0000361).
#
# Released-tree rule (backlog 0000368, 0000041 req-007): a released tree has no
# plan/current/design.md. On an open run the three equality checks for
# product.yml and docs/about.md print a SKIP line, because P7 sets them after
# the P3 bump of component.yml. Every other check runs on every tree.
# The AC2 scan reads the pack source and skips the root release copy.
#
# Verified by: integration
# Verified by: execution

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
source "$SCRIPT_DIR/helpers/pack-root.sh"

FRAMEWORK="$RAVINTIO_PACK_DIR"
REPO="$RAVINTIO_REPO_ROOT"
PACK_REL="$RAVINTIO_PACK_REL"
# The pack path as a regex: escape the dots.
PACK_RE="${PACK_REL//./\\.}"

if [ -f "$REPO/plan/current/design.md" ]; then OPEN_RUN=yes; else OPEN_RUN=no; fi
SKIP_REASON="plan/current/design.md exists, so P7 has not set product.yml and docs/about.md yet. The check runs on a released tree."

# assert_equals_released <expected> <actual> <message>
# Runs the equality check on a released tree. On an open run it prints a SKIP line.
assert_equals_released() {
  if [ "$OPEN_RUN" = "yes" ]; then
    echo "SKIP (open run): ${3#req-010 AC1: }. $SKIP_REASON"
  else
    assert_equals "$1" "$2" "$3"
  fi
}

# --- AC1 ---------------------------------------------------------------
PRODUCT_V="$(sed -n 's/^version: *"\{0,1\}\([0-9.]*\)"\{0,1\} *$/\1/p' "$REPO/product.yml" | head -n 1)"
COMP_V="$(sed -n 's/^version: *"\{0,1\}\([0-9.]*\)"\{0,1\} *$/\1/p' "$FRAMEWORK/component.yml" | head -n 1)"
# The component version sets the release. It must be 0.37 or a later 0.x
# release, since 0000040-retire-fast-path moved the pack to 0.38.0.
WANT="$COMP_V"
if [[ "$COMP_V" =~ ^0\.(3[7-9]|[4-9][0-9])\.[0-9]+$ ]]; then R=ok; else R="not a 0.37 or later 0.x version: $COMP_V"; fi
assert_equals "ok" "$R" "req-010 AC1: $PACK_REL/component.yml version is a 0.37 or later 0.x release"
ABOUT_FM_V="$(awk 'NR==1 && /^---$/ {fm=1; next} fm && /^---$/ {exit} fm && /^version:/ {gsub(/^version: *"?|"? *$/, ""); print; exit}' "$REPO/docs/about.md")"
ABOUT_TABLE_V="$(sed -n 's/^| Version | `\([0-9.]*\)` |.*$/\1/p' "$REPO/docs/about.md" | head -n 1)"

assert_equals_released "$WANT" "$PRODUCT_V" "req-010 AC1: product.yml version reads $WANT"
assert_equals "$WANT" "$COMP_V" "req-010 AC1: $PACK_REL/component.yml version reads $WANT"
assert_equals_released "$WANT" "$ABOUT_FM_V" "req-010 AC1: docs/about.md frontmatter version reads $WANT"
assert_equals_released "$WANT" "$ABOUT_TABLE_V" "req-010 AC1: docs/about.md table Version cell reads $WANT"

PV_OUT="$(cd "$REPO" && env -u CLAUDE_PROJECT_DIR node "$FRAMEWORK/scripts/product-version.mjs" 2>&1 || true)"
assert_equals "$WANT" "$PV_OUT" "req-010 AC1: product-version.mjs prints $WANT"

# --- AC2 ---------------------------------------------------------------
# Paths the scan skips. History, backlog entries, and reports may name 1.0.0
# as an example or a plan without claiming it as the current release.
# -I skips binary files, such as PDF reports.
EXEMPT=(
  ':!plan/_archive'
  ':!plan/changelog'
  ':!plan/_migrations'
  ':!plan/current'
  ':!plan/backlog'
  ':!plan/reports'
  ":!$PACK_REL/tests/test-0000039-req-010-version-bump.sh"
  ":!$PACK_REL/tests/regression/test-0000039-req-010-version-bump.sh"
  # These suites build scratch repos with 1.0.0 fixture versions.
  ":!$PACK_REL/tests/test-0000041-req-002-release-script.sh"
  ":!$PACK_REL/tests/test-0000041-req-007-released-tree-version-suite.sh"
)
# In the source repo the root ravintio-framework is a frozen release copy.
# The integrity check of req-008 covers it, so this scan skips it.
if [ "$PACK_REL" != "ravintio-framework" ]; then EXEMPT+=(':!ravintio-framework'); fi
HITS="$(cd "$REPO" && git grep -n -I '1\.0\.0' -- . "${EXEMPT[@]}" 2>/dev/null || true)"

# A removal-point line pairs 1.0.0 with a form of "remove" or "go", in either order,
# such as "removed at 1.0.0", "1.0.0 removes them", or "upgrades straight to 1.0.0"
# in a note about the removal.
REMOVAL_RE='((removed?|removes|removal|remove at|go at|goes at|gone at|until|through 0\.x).*1\.0\.0|1\.0\.0.*(remov|go(es)? |release notes)|skips the 0\.x window)'
THIRD_PARTY_RE='^(package(-lock)?\.json|[^:]*/package(-lock)?\.json|[^:]*/external-skills/)'
# Non-release uses: a document or template version field, and semver examples
# or rejection fixtures that never name the framework release.
OTHER_RE_PATH='^[^:]*/(standards|templates)/[^:]*:[0-9]+:[[:space:]]*(version|templateVersion): *"?1\.0\.0"?'
OTHER_RE_COMP="^$PACK_RE/component\\.yml:[0-9]+:[[:space:]]*templateVersion: *\"1\\.0\\.0\""
OTHER_RE_SCHEMA='(schemaVersion|templateVersion): *"1\.0\.0"|Schema Version:\*\* 1\.0\.0|schema version stays 1\.0\.0'
OTHER_RE_TEST="^$PACK_RE/tests/(regression/)?test-0000035-req-008-sanctioned-scripts\\.sh:"
OTHER_RE_EXAMPLE="^$PACK_RE/skills/ravintio-orchestrator/references/phase-0-assess-and-coach\\.md:[0-9]+:.*Breaking change"

BAD=""
TOTAL=0
while IFS= read -r hit; do
  [ -z "$hit" ] && continue
  TOTAL=$((TOTAL + 1))
  if grep -Eq "$REMOVAL_RE" <<< "$hit"; then continue; fi
  if grep -Eq "$THIRD_PARTY_RE" <<< "$hit"; then continue; fi
  if grep -Eq "$OTHER_RE_PATH" <<< "$hit"; then continue; fi
  if grep -Eq "$OTHER_RE_COMP" <<< "$hit"; then continue; fi
  if grep -Eq "$OTHER_RE_SCHEMA" <<< "$hit"; then continue; fi
  if grep -Eq "$OTHER_RE_TEST" <<< "$hit"; then continue; fi
  if grep -Eq "$OTHER_RE_EXAMPLE" <<< "$hit"; then continue; fi
  BAD+="$hit"$'\n'
  echo "FAIL hit names 1.0.0 outside the allowed cases: $hit"
done <<< "$HITS"

if [ "$TOTAL" -gt 0 ]; then R=ok; else R="no hits found"; fi
assert_equals "ok" "$R" "req-010 AC2: git grep for 1.0.0 returned hits to classify"
assert_equals "" "$BAD" "req-010 AC2: no hit names 1.0.0 as the current release"

# A live file must also not claim 1.0.0 as the release in the three manifests.
assert_equals "0" "$(grep -c '1\.0\.0' <<< "$PRODUCT_V$COMP_V$ABOUT_FM_V$ABOUT_TABLE_V" || true)" \
  "req-010 AC2: no manifest or about page reads 1.0.0 as the version"

print_summary
