#!/usr/bin/env bash
# Verified by: integration
# test-0000040-req-007-docs-and-adr-supersede.sh
# Feature 0000040-retire-fast-path, req-007-docs-and-adr-supersede (ADR-002,
# ADR-004). The P3 parts of the criteria:
#   - No file in the rewrite list offers a retired track. The scan follows the
#     req-006 guard algorithm: strip the feature ID and the migration slug,
#     match the five patterns, then apply the history-line rule in the
#     decisions index, the architecture overview, and component.yml.
#   - Each rewritten passage routes every change to the Feature Pipeline, and
#     the docs name the enforcement path list ENFORCEMENT_PATHS.
#   - The five decisions-index entries carry their new Status cell and a
#     **Superseded:** note that names a 0000040 ADR.
#   - ravintio-framework/component.yml reads version 0.38.0 and the feature ID.
#   - plan/_archive/ holds no change against main.
# Run from any directory: bash ravintio-framework/tests/test-0000040-req-007-docs-and-adr-supersede.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$SCRIPT_DIR"
if [ "$(basename "$SCRIPT_DIR")" = "regression" ]; then
  TESTS_DIR="$(dirname "$SCRIPT_DIR")"
fi
source "$TESTS_DIR/helpers/assert.sh"

FW="$(cd "$TESTS_DIR/.." && pwd)"
ROOT="$(cd "$FW/.." && pwd)"
PIPEREF="$FW/pipeline-reference.md"
ARCH="$ROOT/docs/architecture-overview.md"
INDEX="$ROOT/docs/decisions-index.md"
COMP="$FW/component.yml"
CONTRACT="$ROOT/src/setup-hook-integration/docs/interface-contract.md"

# has <needle> <haystack> <label>: passes when the haystack holds the needle.
has() {
  assert_equals "present" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# residue_hits <mode> <file>: prints each line that names a retired track and
# that no history rule covers, as "line: text". Modes:
#   plain      no history rule applies
#   decisions  a line passes if it holds a feature ID and ADR, or [Ss]upersed
#   history    a comment line passes inside a "# Updated by" history block
residue_hits() {
  awk -v mode="$1" '
    function has_fid(s) {
      return s ~ /(^|[^0-9])[0-9][0-9][0-9][0-9][0-9][0-9][0-9]([^0-9]|$)/
    }
    {
      orig = $0
      if (mode == "history") {
        if (orig ~ /^[[:space:]]*# Updated by/) inblock = 1
        else if (orig !~ /^[[:space:]]*#/) inblock = 0
      }
      s = orig
      gsub(/0000040-retire-fast-path/, "", s)
      gsub(/retire-fast-path-and-change-pipeline/, "", s)
      l = tolower(s)
      hit = (l ~ /fast[ _-]?path/ || l ~ /change[ -]pipeline/ || l ~ /change-agent/ || s ~ /PC:/ || s ~ /fix\(fast-path\):/)
      if (!hit) next
      if (mode == "decisions" && ((has_fid(orig) && orig ~ /ADR/) || orig ~ /[Ss]upersed/)) next
      if (mode == "history" && inblock) next
      print NR ": " substr(orig, 1, 120)
    }
  ' "$2"
}

# no_residue <mode> <relative path>: passes when the file has no uncovered line.
no_residue() {
  local f="$ROOT/$2"
  if [ ! -f "$f" ]; then
    assert_equals "file present" "file missing" "req-007: $2 exists"
    return
  fi
  assert_equals "" "$(residue_hits "$1" "$f")" "req-007: $2 offers no retired track"
}

echo "=== req-007: the rewrite list offers no retired track ==="

for rel in \
  README.md \
  ravintio-framework/getting-started.md \
  ravintio-framework/pipeline-reference.md \
  ravintio-framework/project-operations.md \
  ravintio-framework/tool-setup-reference.md \
  docs/component-registry.md \
  docs/dependency-graph.md \
  src/setup-hook-integration/docs/interface-contract.md \
  src/setup-hook-integration/docs/scope.md \
  src/setup-hook-integration/docs/test-coverage.md \
  src/setup-hook-integration/docs/quirks.md \
  src/setup-hook-integration/docs/tech-debt.md
do
  no_residue plain "$rel"
done
no_residue decisions docs/decisions-index.md
no_residue decisions docs/architecture-overview.md
no_residue history ravintio-framework/component.yml

echo ""
echo "=== req-007: the history-line rule still fails an uncovered line ==="

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
printf '%s\n' \
  '### Feature 0000040-retire-fast-path' \
  '| 0000033 ADR 009 | Fast Path admits no-src | superseded by 0000040 ADR 001 |' \
  'Fast Path is the quick route.' > "$WORK/index.md"
assert_equals "3: Fast Path is the quick route." "$(residue_hits decisions "$WORK/index.md")" \
  "req-007: the decisions scan flags only the line with no feature ID or superseding note"
printf '%s\n' \
  '  # Updated by 0000033 (docs-agent) P6: version 0.32.0.' \
  '  # budget, Fast Path for no-src changes' \
  '  createdBy: "agent"' \
  '  # budget, Fast Path for no-src changes' > "$WORK/component.yml"
assert_equals "4:   # budget, Fast Path for no-src changes" "$(residue_hits history "$WORK/component.yml")" \
  "req-007: the component.yml scan flags only the line outside a history block"

echo ""
echo "=== req-007: rewritten passages route every change to the Feature Pipeline ==="

PIPE_TEXT="$(cat "$PIPEREF")"
ONE_TRACK=$(sed -n '/^## One track: the Feature Pipeline/,/^---/p' "$PIPEREF")
has "Every change runs the Feature Pipeline" "$ONE_TRACK" \
  "req-007: pipeline-reference.md one-track section routes every change to the Feature Pipeline"
has 'no `src/` target' "$ONE_TRACK" \
  "req-007: pipeline-reference.md one-track section covers a change with no src/ target"
has "pipeline-reference.md#one-track-the-feature-pipeline" "$(cat "$FW/getting-started.md")" \
  "req-007: getting-started.md links to the one-track section"
GUARD=$(sed -n '/^## Git Guardrails/,/^## Orchestrator Sentinel/p' "$PIPEREF")
has "source folder" "$GUARD" "req-007: pipeline-reference.md Git Guardrails names the source folder rule"
has "product.yml" "$GUARD" "req-007: pipeline-reference.md Git Guardrails reads product.yml"
has "source folder" "$(cat "$FW/project-operations.md")" \
  "req-007: project-operations.md names the source folder rule"
has "Feature Pipeline" "$(grep -E '^\| \[workflows/\]' "$ROOT/README.md")" \
  "req-007: README.md workflows row lists the Feature Pipeline"
has "RETIRED_TRACK_WORKFLOWS" "$(cat "$FW/tool-setup-reference.md")" \
  "req-007: tool-setup-reference.md names the setup retired list"
has "RETIRED_TRACK_SKILLS" "$(cat "$CONTRACT")" \
  "req-007: interface-contract.md lists the setup retired list"

echo ""
echo "=== req-007: the docs name the list ENFORCEMENT_PATHS ==="

for f in "$PIPEREF" "$CONTRACT" "$ARCH" \
  "$ROOT/src/setup-hook-integration/docs/quirks.md" \
  "$ROOT/src/setup-hook-integration/docs/tech-debt.md"; do
  lacks "FAST_PATH_ENFORCEMENT_PATHS" "$(cat "$f")" "req-007: ${f#$ROOT/} drops the old list name"
done
has '`ENFORCEMENT_PATHS`' "$PIPE_TEXT" "req-007: pipeline-reference.md names ENFORCEMENT_PATHS"
has '`ENFORCEMENT_PATHS`' "$(cat "$CONTRACT")" "req-007: interface-contract.md names ENFORCEMENT_PATHS"

echo ""
echo "=== req-007: architecture-overview.md (approach 2 revision) ==="

ARCH_TEXT="$(cat "$ARCH")"
lacks "### Fast Path for changes with no src target" "$ARCH_TEXT" \
  "req-007: architecture overview drops the no-src section"
lacks "### Fast Path scope record" "$ARCH_TEXT" \
  "req-007: architecture overview drops the scope record section"
assert_equals "" "$(grep -E '^- `plan/\.fast-path-scope`' "$ARCH" || true)" \
  "req-007: architecture overview data owner list drops the scope record row"
ENF=$(sed -n '/^### `ENFORCEMENT_PATHS`/,/^##/p' "$ARCH")
has "isAlwaysPermitted" "$ENF" "req-007: architecture overview has an ENFORCEMENT_PATHS section that names isAlwaysPermitted"
has "0000040 ADR-004" "$ENF" "req-007: the ENFORCEMENT_PATHS section cites 0000040 ADR-004"
# The decision list lines may start the note with a capital, so compare in lower case.
DL_009=$(grep -E '^- \*\*ADR-009 \(0000033\):\*\*' "$ARCH" | tr '[:upper:]' '[:lower:]' || true)
DL_002=$(grep -E '^- \*\*ADR-002 \(0000035\):\*\*' "$ARCH" | tr '[:upper:]' '[:lower:]' || true)
DL_004=$(grep -E '^- \*\*ADR-004 \(0000035\):\*\*' "$ARCH" | tr '[:upper:]' '[:lower:]' || true)
has "superseded by 0000040 adr-002" "$DL_009" "req-007: decision list 0000033 ADR-009 line names its superseding ADR"
has "superseded by 0000040 adr-002" "$DL_002" "req-007: decision list 0000035 ADR-002 line names its superseding ADR"
has "partly superseded by 0000040 adr-004" "$DL_004" "req-007: decision list 0000035 ADR-004 line names its superseding ADR"

echo ""
echo "=== req-007: decisions-index Status cells and notes ==="

# index_row <feature> <adr>: prints the ADR row from that feature's section.
index_row() {
  awk -v head="### Feature $1:" -v adr="| $2 |" '
    index($0, head) == 1 { on = 1; next }
    on && /^### / { exit }
    on && index($0, adr) == 1 { print; exit }
  ' "$INDEX"
}

# status_cell <row>: prints the third table cell, trimmed.
status_cell() {
  printf '%s\n' "$1" | awk -F'|' '{ s = $4; gsub(/^ +| +$/, "", s); print s }'
}

check_entry() {
  local feature="$1" adr="$2" want="$3" cite="$4" row
  row="$(index_row "$feature" "$adr")"
  assert_equals "$want" "$(status_cell "$row")" "req-007: $feature $adr Status cell reads '$want'"
  has "**Superseded:** $cite" "$row" "req-007: $feature $adr has a Superseded note that names $cite"
}

check_entry 0000014 ADR-004 "partly superseded by 0000040 ADR-002" "0000040 ADR-002"
check_entry 0000033 ADR-009 "superseded by 0000040 ADR-002" "0000040 ADR-002"
check_entry 0000035 ADR-002 "superseded by 0000040 ADR-002" "0000040 ADR-002"
check_entry 0000035 ADR-003 "superseded by 0000040 ADR-002" "0000040 ADR-002"
check_entry 0000035 ADR-004 "partly superseded by 0000040 ADR-004" "0000040 ADR-004"

echo ""
echo "=== req-007: component.yml version and archive ==="

COMP_V="$(sed -n 's/^version: *"\{0,1\}\([0-9.]*\)"\{0,1\} *$/\1/p' "$COMP" | head -n 1)"
COMP_F="$(sed -n 's/^feature: *"\{0,1\}\([^"]*\)"\{0,1\} *$/\1/p' "$COMP" | head -n 1)"
assert_equals "0.38.0" "$COMP_V" "req-007: ravintio-framework/component.yml version reads 0.38.0"
assert_equals "0000040-retire-fast-path" "$COMP_F" "req-007: ravintio-framework/component.yml feature reads 0000040-retire-fast-path"

if git -C "$ROOT" rev-parse --verify --quiet main^{commit} > /dev/null; then
  ARCHIVE_DIFF="$(git -C "$ROOT" diff --name-only main -- plan/_archive/ 2>&1)"
  assert_equals "" "$ARCHIVE_DIFF" "req-007: plan/_archive/ holds no change against main"
else
  echo "  SKIP: req-007: no local main ref, so the archive diff check skips"
fi

print_summary
