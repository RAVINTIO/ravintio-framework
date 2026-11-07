#!/usr/bin/env bash
# Tests for feature 0000040-retire-fast-path, req-006: the residue guard (ADR-007).
#
# REGRESSION-CANDIDATE: guards the standing rule that live tracked paths and lines keep one pipeline track, tagged by test-writer for human review at P7
#
# Verified by: integration
#
# This suite is the guard. It reads `git ls-files` and drops history paths. It
# then searches every other path and line for the two retired tracks.
#
# The guard runs one ordered algorithm on each path and each line:
# 1. Strip the feature ID and the new migration slug from a copy.
# 2. If no retired-track pattern matches the stripped copy, the line passes.
# 3. Otherwise test the unstripped line against the allowlist and the
#    history-line rule. If neither covers it, the guard flags it.
# Only allowlist entries can cover a path. A path is checked as its own line.
#
# Each allowlist entry is `path_regex|line_regex|reason`. Both regexes must
# match. The path regex holds no `|`. The line regex may hold `|`, because the
# parser takes the text before the first `|` as the path regex. It takes the
# text after the last `|` as the reason.
#
# Every regex is POSIX extended regex, as Bash 3.2 `[[ =~ ]]` reads it. No
# regex uses `\s`, `\d`, or `\b`. Case-free patterns spell out both cases.
#
# A stale entry that covers no match fails the suite.
#
# Every loop reads lines with `done <<< "$(...)"` and skips empty lines. The
# `done < <(...)` form drops lines on macOS Bash 3.2.
#
# This file's own path is allowlisted, so it may name the retired words.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$SCRIPT_DIR"
if [ "$(basename "$SCRIPT_DIR")" = "regression" ]; then
  TESTS_DIR="$(dirname "$SCRIPT_DIR")"
fi
source "$TESTS_DIR/helpers/assert.sh"

ROOT="$(cd "$TESTS_DIR/../.." && pwd)"

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

# History paths. A path that starts with one of these is a past record.
EXCLUDED_PREFIXES=(
  "plan/_archive/"      # archived features are history
  "plan/changelog/"     # release notes are history
  "plan/_migrations/"   # applied migration records are history
  "plan/current/"       # describes the retirement until ship archives it
  "plan/backlog/"       # backlog entries are dated records
  "plan/reports/"       # each report is a dated record
)

# Neutral identifiers stripped before the pattern check.
STRIP_FEATURE_ID="0000040-retire-fast-path"
STRIP_MIGRATION_SLUG="retire-fast-path-and-change-pipeline"

# Retired-track patterns. The first three ignore case, so they spell out both
# cases. The last two match case exactly.
PATTERNS=(
  '[Ff][Aa][Ss][Tt][ _-]?[Pp][Aa][Tt][Hh]'
  '[Cc][Hh][Aa][Nn][Gg][Ee][ -][Pp][Ii][Pp][Ee][Ll][Ii][Nn][Ee]'
  '[Cc][Hh][Aa][Nn][Gg][Ee]-[Aa][Gg][Ee][Nn][Tt]'
  'PC:'
  'fix\(fast-path\):'
)

# A grep prefilter that matches every line the patterns could match. A strip
# only removes text that holds `fast-path`, so the prefilter also catches a
# match made by joining text around a stripped identifier.
PREFILTER='fast[ _-]?path|change[ -]pipeline|change-agent|pc:'

# The setup retired list holds one quoted name per line.
SETUP_LIST_RE="^[[:space:]]*['\"][^'\"]*(fast-path|change-pipeline|ravintio-change-agent)[^'\"]*['\"],?[[:space:]]*\$"

ALLOWLIST=(
  # --- This guard ---
  '^ravintio-framework/tests/(regression/)?test-0000040-req-006-residue-guard\.sh$|.*|The guard names the words to match them.'

  # --- Released migrations ---
  '^ravintio-framework/migrations/migrate-0\.3[47]\.0-|.*|Released migration files never change.'
  '^ravintio-framework/migrations/migrate-0\.38\.0-retire-fast-path-and-change-pipeline|.*|The migration deletes the scope record and the exemption by name.'

  # --- The 0000040 suites for req-001 to req-005 and req-007 ---
  # P3 deviation: req-007's suite plants the history-line cases and checks the
  # old names are gone, so the entry covers it too.
  '^ravintio-framework/tests/(regression/)?test-0000040-req-00[1-57]-[a-z0-9-]+\.sh$|.*|Each suite plants or checks for the retired words.'

  # --- The setup retired list ---
  "^ravintio-framework/setup\\.sh\$|${SETUP_LIST_RE}|Setup removes the installed copies by name."
  "^ravintio-framework/setup\\.ps1\$|${SETUP_LIST_RE}|Setup removes the installed copies by name."

  # --- Suites that test released migrations ---
  '^ravintio-framework/tests/(regression/)?test-0000036-req-001-|.*|They assert the text of released migrations.'
  '^ravintio-framework/tests/(regression/)?test-0000039-req-006-|.*|They assert the text of released migrations.'

  # --- The req-002 rewrite table ---
  # Only the rewritten suites that still name the scope record get an entry.
  # The rest were retired or name neither track, so an entry would be stale.
  '^ravintio-framework/tests/(regression/)?test-0000035-req-003-|.*|They prove the gates ignore the scope record, so they name it.'
  '^ravintio-framework/tests/(regression/)?test-0000036-req-00[89]-|.*|They prove the gates ignore the scope record, so they name it.'

  # --- The kept change-agent archive suite (backlog 0000365) ---
  '^ravintio-framework/tests/(regression/)?test-0000017-req-007-change-agent-archive\.sh$|.*|The suite keeps its name, because no sanctioned step removes a manifest entry.'
  '^ravintio-framework/tests/regression/regression-manifest\.json$|test-0000017-req-007-change-agent-archive\.sh|The manifest keeps the suite name.'
  '^ravintio-framework/tests/(regression/)?test-0000039-req-005-history-and-split-name-protection\.sh$|test-0000017-req-007-change-agent-archive\.sh|The suite lists the kept suite by name.'

  # --- Absence checks ---
  '^ravintio-framework/tests/(regression/)?test-0000032-req-00[34]-[a-z0-9-]+\.sh$|.*|An absence check names the words it checks for.'

  # --- A dated history comment in a hash-pinned suite ---
  # P3 deviation: the comment says why the pinned hashes changed in 0000040.
  '^ravintio-framework/tests/(regression/)?test-0000038-req-004-phase-scoped-orchestrator\.sh$|^# Feature 0000040 req-001 then dropped the Fast Path and Change Pipeline bump|The comment records why the pinned hashes changed.'

  # --- Vendored third-party text ---
  '^ravintio-framework/external-skills/plan-eng-review/SKILL\.md$|^\*\*Fast path:\*\* All paths covered|Vendored text, where the words carry another meaning.'
)

# Parse each entry once into three parallel arrays.
P_RE=()
L_RE=()
REASONS=()
HITS=()
parse_allowlist() {
  local i entry rest
  P_RE=(); L_RE=(); REASONS=(); HITS=()
  for i in "${!ALLOWLIST[@]}"; do
    entry="${ALLOWLIST[$i]}"
    P_RE[$i]="${entry%%|*}"
    rest="${entry#*|}"
    L_RE[$i]="${rest%|*}"
    REASONS[$i]="${entry##*|}"
    HITS[$i]=0
  done
}
parse_allowlist
COUNT_HITS=1

FEATURE_ID_RE='(^|[^0-9])[0-9]{7}([^0-9]|$)'

# strip <text>: prints the text without the two neutral identifiers.
strip() {
  local t="$1"
  t="${t//$STRIP_FEATURE_ID/}"
  t="${t//$STRIP_MIGRATION_SLUG/}"
  printf '%s' "$t"
}

# matches_pattern <text>: returns 0 when a retired-track pattern matches.
matches_pattern() {
  local t="$1" re
  for re in "${PATTERNS[@]}"; do
    [[ "$t" =~ $re ]] && return 0
  done
  return 1
}

# entry_covers <path> <text>: returns 0 when an entry covers the text.
# Counts every covering entry while COUNT_HITS is 1.
entry_covers() {
  local path="$1" text="$2" i found=1
  for i in "${!ALLOWLIST[@]}"; do
    if [[ "$path" =~ ${P_RE[$i]} ]] && [[ "$text" =~ ${L_RE[$i]} ]]; then
      found=0
      [ "$COUNT_HITS" -eq 1 ] && HITS[$i]=$(( ${HITS[$i]} + 1 ))
    fi
  done
  return "$found"
}

# history_line <path> <text> <in_block>: returns 0 when the history-line rule
# covers the line. <in_block> is 1 when a component.yml line sits in a block.
history_line() {
  local path="$1" text="$2" in_block="$3"
  case "$path" in
    docs/decisions-index.md|docs/architecture-overview.md)
      [[ "$text" =~ [Ss]upersed ]] && return 0
      [[ "$text" =~ $FEATURE_ID_RE ]] && [[ "$text" =~ ADR ]] && return 0
      ;;
    docs/about.md)
      [[ "$text" =~ $FEATURE_ID_RE ]] && return 0
      ;;
    ravintio-framework/component.yml)
      [ "$in_block" -eq 1 ] && return 0
      ;;
  esac
  return 1
}

# history_blocks <file>: prints the number of each line in a history block. A
# block starts at a `# Updated by` line and runs over the following comment
# lines. It ends at the next `# Updated by` line or the first other line.
history_blocks() {
  local file="$1" line n=0 in_block=0
  while IFS= read -r line || [ -n "$line" ]; do
    n=$(( n + 1 ))
    if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*Updated[[:space:]]by ]]; then
      in_block=1
    elif [[ "$line" =~ ^[[:space:]]*# ]]; then
      :
    else
      in_block=0
    fi
    [ "$in_block" -eq 1 ] && printf '%s\n' "$n"
  done < "$file"
}

# check_file <root> <path>: appends "path:line: text" to LINE_FAILS for each
# matching line that no rule covers.
LINE_FAILS=""
HISTORY_HITS=0
check_file() {
  local root="$1" path="$2" hit num text blocks="" in_block
  [ -f "$root/$path" ] || return 0
  [ "$path" = "ravintio-framework/component.yml" ] && blocks=" $(history_blocks "$root/$path" | tr '\n' ' ')"
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    num="${hit%%:*}"
    text="${hit#*:}"
    matches_pattern "$(strip "$text")" || continue
    entry_covers "$path" "$text" && continue
    in_block=0
    case "$blocks" in *" $num "*) in_block=1 ;; esac
    if history_line "$path" "$text" "$in_block"; then
      [ "$COUNT_HITS" -eq 1 ] && HISTORY_HITS=$(( HISTORY_HITS + 1 ))
      continue
    fi
    LINE_FAILS="${LINE_FAILS}${path}:${num}: ${text}"$'\n'
  done <<< "$(grep -inIE -- "$PREFILTER" "$root/$path" 2>/dev/null)"
}

# check_path <path>: appends the path to PATH_FAILS when it names a retired
# track and no entry covers it.
PATH_FAILS=""
check_path() {
  local path="$1"
  matches_pattern "$(strip "$path")" || return 0
  entry_covers "$path" "$path" || PATH_FAILS="${PATH_FAILS}${path}:0: path names a retired track"$'\n'
}

in_scope() {
  local path="$1" prefix
  for prefix in "${EXCLUDED_PREFIXES[@]}"; do
    case "$path" in "$prefix"*) return 1 ;; esac
  done
  return 0
}

SCOPE=""
while IFS= read -r path; do
  [ -n "$path" ] || continue
  in_scope "$path" && SCOPE="${SCOPE}${path}"$'\n'
done <<< "$(git -C "$ROOT" ls-files)"

# The guard always scans itself, even before its first commit.
SELF="${SCRIPT_DIR#"$ROOT"/}/$(basename "$0")"
case "$SCOPE" in
  "$SELF"$'\n'*|*$'\n'"$SELF"$'\n'*) ;;
  *) SCOPE="${SCOPE}${SELF}"$'\n' ;;
esac

# One scan: paths first, then lines. Hits count toward the stale check.
while IFS= read -r path; do
  [ -n "$path" ] || continue
  check_path "$path"
  check_file "$ROOT" "$path"
done <<< "$SCOPE"
COUNT_HITS=0

# stale_entries: prints each entry that covered no path and no line.
stale_entries() {
  local i out=""
  for i in "${!ALLOWLIST[@]}"; do
    [ "${HITS[$i]}" -eq 0 ] && out="${out}stale entry $i: ${P_RE[$i]} | ${L_RE[$i]}"$'\n'
  done
  printf '%s' "$out"
}

# parser_faults: prints each entry whose parts are malformed. A path regex
# must be non-empty, start with `^`, hold balanced parentheses, and compile.
# A line regex must compile, and a reason must be non-empty.
parser_faults() {
  local i p bare opens closes out=""
  for i in "${!ALLOWLIST[@]}"; do
    p="${P_RE[$i]}"
    bare="${p//\\(/}"
    bare="${bare//\\)/}"
    opens="${bare//[^(]/}"
    closes="${bare//[^)]/}"
    if [ -z "$p" ] || [ "${p:0:1}" != "^" ] || [ "${#opens}" -ne "${#closes}" ]; then
      out="${out}entry $i: bad path regex '${p}'"$'\n'
      continue
    fi
    [[ "" =~ $p ]]
    [ "$?" -eq 2 ] && out="${out}entry $i: path regex does not compile '${p}'"$'\n'
    [[ "" =~ ${L_RE[$i]} ]]
    [ "$?" -eq 2 ] && out="${out}entry $i: line regex does not compile '${L_RE[$i]}'"$'\n'
    [ -n "${REASONS[$i]}" ] || out="${out}entry $i: no reason"$'\n'
  done
  printf '%s' "$out"
}

print_lines() {
  local l
  while IFS= read -r l; do
    [ -n "$l" ] || continue
    printf '    %s\n' "$l"
  done <<< "$1"
}

count_lines() {
  local l n=0
  while IFS= read -r l; do
    [ -n "$l" ] && n=$(( n + 1 ))
  done <<< "$1"
  echo "$n"
}

LINE_TOTAL="$(count_lines "$LINE_FAILS")"
PATH_TOTAL="$(count_lines "$PATH_FAILS")"
STALE="$(stale_entries)"
STALE_TOTAL="$(count_lines "$STALE")"
REAL_LINE_FAILS="$LINE_FAILS"
REAL_PATH_FAILS="$PATH_FAILS"

echo ""
echo "=== req-006: covered matches in the real tree ==="
for _i in "${!ALLOWLIST[@]}"; do
  printf '    entry %s: %s covered: %s\n' "$_i" "${HITS[$_i]}" "${REASONS[$_i]}"
done
printf '    history-line rule: %s covered\n' "$HISTORY_HITS"

echo ""
echo "=== req-006 AC1: no tracked line outside the rules names a retired track ==="
[ -n "$REAL_LINE_FAILS" ] && print_lines "$REAL_LINE_FAILS"
assert_equals "" "$REAL_LINE_FAILS" "req-006 AC1: every matching tracked line falls under an allowlist entry or the history-line rule"

echo ""
echo "=== req-006 AC1: no tracked path outside the allowlist names a retired track ==="
[ -n "$REAL_PATH_FAILS" ] && print_lines "$REAL_PATH_FAILS"
assert_equals "" "$REAL_PATH_FAILS" "req-006 AC1: every matching tracked path has an allowlist entry"

echo ""
echo "=== req-006 AC1: the .gitignore block for the scope record is gone ==="
GI="$(grep -n 'fast-path-scope' "$ROOT/.gitignore" 2>/dev/null)"
assert_equals "" "$GI" "req-006 AC1: .gitignore names no scope record"

echo ""
echo "=== req-006 AC3: every allowlist entry covers a path or a line ==="
[ -n "$STALE" ] && print_lines "$STALE"
assert_equals "" "$STALE" "req-006 AC3: no allowlist entry is stale"

echo ""
echo "=== req-006 AC3: every allowlist entry parses into its intended parts ==="
FAULTS="$(parser_faults)"
[ -n "$FAULTS" ] && print_lines "$FAULTS"
assert_equals "" "$FAULTS" "req-006 AC3: every path regex is anchored, balanced, and compiles"

# plant <path> <line> [<prefix line>]: copies the real file to the scratch
# tree, appends the optional prefix line and then the planted line. It sets
# PLANT_NUM to the planted line number and fills LINE_FAILS for that file.
PLANT_NUM=0
plant() {
  local path="$1" line="$2" prefix="${3:-}"
  rm -rf "$SCRATCH/tree"
  mkdir -p "$SCRATCH/tree/$(dirname "$path")"
  if [ -f "$ROOT/$path" ]; then
    cp "$ROOT/$path" "$SCRATCH/tree/$path"
  else
    : > "$SCRATCH/tree/$path"
  fi
  [ -n "$prefix" ] && printf '%s\n' "$prefix" >> "$SCRATCH/tree/$path"
  printf '%s\n' "$line" >> "$SCRATCH/tree/$path"
  PLANT_NUM="$(wc -l < "$SCRATCH/tree/$path" | tr -d ' ')"
  LINE_FAILS=""
  check_file "$SCRATCH/tree" "$path"
}

# expect <verdict> <path> <line> [<prefix line>]: plants the line and checks
# the guard gives the verdict, `pass` or `fail`.
expect() {
  local verdict="$1" path="$2" line="$3" prefix="${4:-}" got
  plant "$path" "$line" "$prefix"
  case "$LINE_FAILS" in
    *"${path}:${PLANT_NUM}: "*) got="fail" ;;
    *) got="pass" ;;
  esac
  assert_equals "$verdict" "$got" "req-006 fixture: $path '$line' gives $verdict"
}

echo ""
echo "=== req-006 fixtures: the guard algorithm cases ==="
expect pass "docs/decisions-index.md" '### Feature 0000040-retire-fast-path'
expect pass "docs/decisions-index.md" '| ADR 001 | Fast Path retired (0000040-retire-fast-path) | accepted |'
expect pass "docs/decisions-index.md" '| 0000033 ADR 009 | Fast Path admits no-src | superseded by 0000040 ADR 001 |'
expect fail "docs/decisions-index.md" 'Fast Path is the quick route.'
expect pass "docs/architecture-overview.md" '- **ADR 009 (0000033):** Fast Path admits a change. superseded by 0000040 ADR 001'
expect fail "docs/architecture-overview.md" '### Fast Path for changes with no src target'
expect pass "docs/about.md" '| 0.38.0 | 0000040-retire-fast-path | Retired Fast Path and the Change Pipeline |'
expect fail "docs/about.md" 'Use Fast Path for small fixes.'
expect pass "ravintio-framework/component.yml" '# budget, Fast Path for no-src changes' '  # Updated by 0000099 (fixture): a history block starts here.'
expect fail "ravintio-framework/component.yml" '# budget, Fast Path for no-src changes'
expect pass "README.md" 'Feature 0000040-retire-fast-path removed both tracks.'
expect fail "README.md" 'Run the Change Pipeline for small changes.'
expect pass "product.yml" 'feature: "0000040-retire-fast-path"'

echo ""
echo "=== req-006 fixtures: the setup retired list ==="
expect pass "ravintio-framework/setup.sh" '  "fast-path.md"'
expect pass "ravintio-framework/setup.ps1" "    'ravintio-change-agent',"
expect fail "ravintio-framework/setup.sh" 'echo "Use Fast Path for small fixes"'

echo ""
echo "=== req-006 AC2: each planted line in a scratch README.md fails with its file and line number ==="
for planted in 'Fast Path is back.' 'Change Pipeline is back.' 'PC: a quick change' 'fix(fast-path): a quick fix'; do
  plant "README.md" "$planted"
  assert_contains "README.md:$PLANT_NUM: $planted" "$LINE_FAILS" \
    "req-006 AC2: the check flags '$planted' with its file and line number"
done

echo ""
echo "=== req-006 AC2: a path that names a retired track fails the path check ==="
PATH_FAILS=""
check_path "ravintio-framework/workflows/fast-path.md"
assert_contains "ravintio-framework/workflows/fast-path.md:0:" "$PATH_FAILS" \
  "req-006 AC2: the path check flags the retired workflow path"

echo ""
echo "=== req-006 AC3: a stale allowlist entry is reported ==="
ALLOWLIST+=('^no/such/path$|no such line|Probe entry that matches nothing.')
SAVED_HITS=("${HITS[@]}")
parse_allowlist
HITS=("${SAVED_HITS[@]}" 0)
PROBE_STALE="$(stale_entries)"
assert_contains "^no/such/path\$" "$PROBE_STALE" \
  "req-006 AC3: the stale check reports an entry that covers nothing"

echo ""
echo "=== req-006 AC3: the parser check flags a path regex that holds a pipe ==="
ALLOWLIST+=('^ravintio-framework/setup\.(sh|ps1)$|.*|Probe entry with a pipe in its path regex.')
ALLOWLIST+=('|.*|Probe entry with an empty path regex.')
parse_allowlist
PROBE_FAULTS="$(parser_faults)"
assert_contains "bad path regex '^ravintio-framework/setup\\.(sh'" "$PROBE_FAULTS" \
  "req-006 AC3: the parser check flags an unbalanced path regex"
assert_contains "bad path regex ''" "$PROBE_FAULTS" \
  "req-006 AC3: the parser check flags an empty path regex"

echo ""
echo "Total offences: $(( LINE_TOTAL + PATH_TOTAL + STALE_TOTAL )) (lines $LINE_TOTAL, paths $PATH_TOTAL, stale entries $STALE_TOTAL)"
print_summary
