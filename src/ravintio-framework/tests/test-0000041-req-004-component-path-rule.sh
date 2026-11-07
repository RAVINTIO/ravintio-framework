#!/usr/bin/env bash
# Verified by: integration
#
# Tests for feature 0000041-pack-source-under-src, req-004: the component path
# rule (ADR-006). One rule finds each component manifest: the path that
# product.yml lists, else src/{component-id}/component.yml.
#
# Sections:
#   AC1  component-guide.md owns the rule. spec-agent and docs-agent link to it.
#   AC2  the codegen close-out reads components from the design and applies the
#        rule. It states the four ADR-006 rules.
#   AC3  ship Step 9 case 2 reads the single component from the archived design.
#
# Match rule for the "names no file" cases: a path that ends in
# ravintio-framework/component.yml counts as a match, so a path under src/
# is a match too.
#
# Expected state after build order step 3: every case is RED, because P3 has
# not yet edited the five files under test.
#
# Sections are cut out by literal line prefix with awk index(), so no regex
# passes through awk -v. Every regex is POSIX extended for grep -E.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
source "$SCRIPT_DIR/helpers/pack-root.sh"

GUIDE="$RAVINTIO_PACK_DIR/templates/component-guide.md"
SPEC="$RAVINTIO_PACK_DIR/skills/ravintio-spec-agent/SKILL.md"
DOCS="$RAVINTIO_PACK_DIR/skills/ravintio-docs-agent/SKILL.md"
CODEGEN="$RAVINTIO_PACK_DIR/skills/ravintio-codegen-agent/SKILL.md"
SHIP="$RAVINTIO_PACK_DIR/skills/ravintio-ship-agent/SKILL.md"

for f in "$GUIDE" "$SPEC" "$DOCS" "$CODEGEN" "$SHIP"; do
  [ -f "$f" ] || { echo "  FAIL: req-004: missing file under test: $RAVINTIO_PACK_REL/${f#$RAVINTIO_PACK_DIR/}"; exit 1; }
done

# Path text that a match rule must catch: any path ending in this file name.
RE_ROOT_MANIFEST='ravintio-framework/component[.]yml' # portable-ok: a regex that must match the consumer path text
RE_DEFAULT_PATH='src/[{][{]?component-id[}][}]?/component[.]yml'

# section_h2 <file> <heading line>: the lines under a "## " heading, up to the next one.
section_h2() {
  awk -v h="$2" 'f && index($0, "## ") == 1 { exit } f { print } index($0, h) == 1 { f = 1 }' "$1"
}

# block_from <file> <start prefix> <stop prefix>: lines from the start line up to,
# but not including, the next line that begins with the stop prefix.
block_from() {
  awk -v s="$2" -v e="$3" 'f && index($0, e) == 1 { exit } index($0, s) == 1 { f = 1 } f { print }' "$1"
}

# line_with <file> <prefix>: the first line that begins with the prefix.
line_with() {
  awk -v p="$2" 'index($0, p) == 1 { print; exit }' "$1"
}

# check <name> <text> <regex>: pass when the text matches the regex, ignoring case.
check() {
  if [ -n "$2" ] && grep -Eiq -- "$3" <<< "$2"; then
    assert_equals "match" "match" "$1"
  else
    assert_equals "match" "no match" "$1"
  fi
}

# check_absent <name> <file> <regex>: pass when no line of the file matches.
check_absent() {
  local hits
  hits="$(grep -nE -- "$3" "$2" | head -3)"
  assert_equals "" "$hits" "$1"
}

# ============================================================================
echo "=== req-004 AC1: component-guide.md owns the rule ==="

GUIDE_LOC="$(section_h2 "$GUIDE" '## File location')"

check "req-004 AC1: guide File location names product.yml" "$GUIDE_LOC" 'product[.]yml'
check "req-004 AC1: guide File location names components[]" "$GUIDE_LOC" 'components\[\]'
check "req-004 AC1: guide File location keeps the src default path" "$GUIDE_LOC" "$RE_DEFAULT_PATH"
check "req-004 AC1: guide File location labels the src path as the default" "$GUIDE_LOC" 'default'
check "req-004 AC1: guide File location says the folder holds the manifest" "$GUIDE_LOC" 'folder'

# spec-agent: three manifest lines, each linking to the rule.
SPEC_PRODUCE="$(line_with "$SPEC" 'Write each spec artifact to')"
SPEC_ROW="$(line_with "$SPEC" '| Component Manifest')"
SPEC_BULLET="$(awk 'f { print; exit } $0 == "**Component manifest:**" { f = 1 }' "$SPEC")"

check "req-004 AC1: spec-agent What You Produce sentence links component-guide.md" "$SPEC_PRODUCE" 'component-guide[.]md'
check "req-004 AC1: spec-agent Component Manifest row links component-guide.md" "$SPEC_ROW" 'component-guide[.]md'
check "req-004 AC1: spec-agent first Component manifest bullet links component-guide.md" "$SPEC_BULLET" 'component-guide[.]md'

# Neither skill names the default path without labelling it the default.
unlabelled_default() {
  grep -E -- "$RE_DEFAULT_PATH" "$1" | grep -viE 'default' | head -3
}
assert_equals "" "$(unlabelled_default "$SPEC")" "req-004 AC1: spec-agent names no src component.yml path without the word default"
assert_equals "" "$(unlabelled_default "$DOCS")" "req-004 AC1: docs-agent names no src component.yml path without the word default"

# docs-agent: the Input line and the drift row.
DOCS_INPUT="$(line_with "$DOCS" '- The implementation at')"
DOCS_DRIFT="$(line_with "$DOCS" '| Component boundaries')"

check "req-004 AC1: docs-agent Input line links component-guide.md" "$DOCS_INPUT" 'component-guide[.]md'
check "req-004 AC1: docs-agent drift row reads the manifest paths from product.yml" "$DOCS_DRIFT" 'product[.]yml'
check "req-004 AC1: docs-agent drift row gives the default for an unlisted component" "$DOCS_DRIFT" 'default'

# ============================================================================
echo ""
echo "=== req-004 AC2: codegen close-out applies the rule ==="

# The close-out block is the one whose heading line holds "close-out".
CLOSE="$(awk 'index($0, "**") == 1 && /close-out/ { f = 1; print; next } f && index($0, "**") == 1 { exit } f { print }' "$CODEGEN")"

check "req-004 AC2: codegen has a component manifest close-out block" "$CLOSE" 'close-out'
check_absent "req-004 AC2: no line of the codegen SKILL.md names ravintio-framework/component.yml" "$CODEGEN" "$RE_ROOT_MANIFEST"
check "req-004 AC2: close-out reads the design Engineering Layer" "$CLOSE" 'Engineering Layer'
check "req-004 AC2: close-out reads the Components list" "$CLOSE" 'Components list'
check "req-004 AC2: close-out finds each manifest under the rule in component-guide.md" "$CLOSE" 'component-guide[.]md'
check "req-004 AC2: close-out runs before the P3 commit" "$CLOSE" 'before.*P3 commit'
check "req-004 AC2: close-out increments the minor version" "$CLOSE" 'increment.*minor'
check "req-004 AC2: close-out sets the feature field" "$CLOSE" 'feature'
check "req-004 AC2: close-out stages the manifest in the P3 commit" "$CLOSE" 'stage'
check "req-004 AC2: close-out says a path with no listed manifest bumps nothing" "$CLOSE" 'no listed manifest.*nothing|nothing.*no listed manifest|bumps nothing'
check "req-004 AC2: close-out applies to every kind of change" "$CLOSE" 'docs-only'
check "req-004 AC2 ADR-006: the deeper folder owns a file that two folders hold" "$CLOSE" 'deeper'
check "req-004 AC2 ADR-006: a listed path with no file stops and reports" "$CLOSE" 'stop.*report|report.*stop'
check "req-004 AC2 ADR-006: the close-out never creates a manifest or falls back" "$CLOSE" 'never.*(fall|creat)'
check "req-004 AC2 ADR-006: a changed file differs from the HEAD at P3 start" "$CLOSE" 'HEAD'
check "req-004 AC2 ADR-006: TDD commits count toward a change" "$CLOSE" 'TDD'
check "req-004 AC2 ADR-006: a manifest that holds the feature ID is not bumped again" "$CLOSE" 'already'

# ============================================================================
echo ""
echo "=== req-004 AC3: ship Step 9 case 2 ==="

CASE2="$(block_from "$SHIP" '2. **No `product.yml` and the project has exactly one component**' '3. **No `product.yml`')"
EXIT4="$(line_with "$SHIP" '   - Exit 4:')"

check "req-004 AC3: ship has a Step 9 case 2" "$CASE2" 'exactly one component'
check "req-004 AC3: case 2 reads plan/_archive design.md" "$CASE2" 'plan/_archive/.*design[.]md'
check "req-004 AC3: case 2 reads the manifest under the rule in component-guide.md" "$CASE2" 'component-guide[.]md'
check "req-004 AC3: case 2 reads the version field" "$CASE2" 'version'
check "req-004 AC3: case 2 stops and reports for zero or two or more components" "$CASE2" 'stop.*report|report.*stop'
check "req-004 AC3: case 2 states zero components" "$CASE2" 'no component|zero|none'
check "req-004 AC3: case 2 states two or more components" "$CASE2" 'more than one|two or more|2[+]'
check "req-004 AC3: case 2 never tags on a stop" "$CASE2" 'never tag|do not tag|don.t tag'
check_absent "req-004 AC3: no line of the ship SKILL.md names ravintio-framework/component.yml" "$SHIP" "$RE_ROOT_MANIFEST"
check "req-004 AC3: Step 5b exit 4 points to the rule when it names component.yml" "$EXIT4" 'component-guide[.]md'

# Match rule control: the pattern catches a root path and a path under src/.
assert_equals "2" "$(printf '%s\n' 'ravintio-framework/component.yml' 'src/ravintio-framework/component.yml' | grep -cE -- "$RE_ROOT_MANIFEST")" "req-004 AC3: the match rule counts a root path and a path under src/"

print_summary
