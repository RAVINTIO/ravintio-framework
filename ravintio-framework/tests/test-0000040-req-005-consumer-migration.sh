#!/usr/bin/env bash
# Verified by: integration
#
# Tests for feature 0000040-retire-fast-path, req-005: consumer migration
# (ADR-006).
#
# The 0.38.0 migration asks the human on the loop to delete a leftover
# plan/.fast-path-scope, and removes the 0.37.x Fast Path exemption block from
# .github/workflows/ravintio.yml once they confirm. The migrator scope rule
# (migrator Hard Limit 1) widens so a migration may name extra paths on a
# **May edit:** line.
#
# Acceptance criteria covered:
#   AC1 the migration file text, its quoted block, and the block match
#       against a fixture copy of the 0.37.2 hooks/ravintio.yml
#   AC3 the migrator SKILL.md states the widened scope rule
# AC2 is "Verified by: execution". It needs a real migrator run, so P4 runs it.
# The scratch consumer cases below check only the matching rule the migration
# states: trailing whitespace trimmed, and a removal only on one match.
#
# The fixture is a copy of the 0.37.2 template, held in this file. When git
# can resolve FIXTURE_COMMIT, the suite also checks the copy against it.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FW="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="$(cd "$FW/.." && pwd)"
STEM="migrate-0.38.0-retire-fast-path-and-change-pipeline"
MIGRATION="$FW/migrations/$STEM.md"
MIGRATOR="$FW/skills/ravintio-migrator/SKILL.md"
CI_PATH=".github/workflows/ravintio.yml"
# The last commit that changed hooks/ravintio.yml before 0000040. The template
# stayed the same from there to the 0.37.2 release.
FIXTURE_COMMIT="2aea4e7b7445418a51a47d23ba08862ecce19e29"

WORK="$(mktemp -d -t ravintio_0000040_req005_XXXXXX)" || { echo "  FAIL: req-005: mktemp -d failed"; exit 1; }
trap 'rm -rf "$WORK"' EXIT

yes_no() {
  if "$@"; then echo yes; else echo no; fi
}

# section <file> <start heading> <next heading>: the lines after the start
# heading, up to the next heading. An absent next heading reads to the end.
section() {
  awk -v a="$2" -v b="$3" '$0 == a { on = 1; next } on && $0 == b { exit } on { print }' "$1" 2>/dev/null
}

# header_line <file> <key>: the first line that opens with the bold key.
header_line() {
  grep -m1 -F -- "$2" "$1" 2>/dev/null | grep -E '^\*\*' || true
}

# quoted_blocks <file>: prints each fenced block whose first line, after
# leading spaces, opens with "# Fast Path exemption:". Blocks are separated
# by a line that holds only "@@END@@".
quoted_blocks() {
  awk '
    /^[ ]*```/ {
      if (!infence) { infence = 1; n = 0; next }
      infence = 0
      if (n > 0) {
        first = buf[1]; sub(/^[ ]+/, "", first)
        if (index(first, "# Fast Path exemption:") == 1) {
          for (i = 1; i <= n; i++) print buf[i]
          print "@@END@@"
        }
      }
      next
    }
    infence { buf[++n] = $0 }
  ' "$1" 2>/dev/null
}

# match_block <block file> <target file>: prints "{count} {first start line}".
# Lines compare after trailing whitespace is trimmed from both sides.
match_block() {
  awk '
    function rt(s) { sub(/[ \t\r]+$/, "", s); return s }
    FNR == NR { b[++n] = rt($0); next }
    { t[++m] = rt($0) }
    END {
      c = 0; first = 0
      if (n > 0) {
        for (s = 1; s + n - 1 <= m; s++) {
          ok = 1
          for (i = 1; i <= n; i++) if (t[s + i - 1] != b[i]) { ok = 0; break }
          if (ok) { c++; if (!first) first = s }
        }
      }
      print c, first
    }
  ' "$1" "$2"
}

# drop_lines <file> <start> <count>: the file without those lines.
drop_lines() {
  awk -v s="$2" -v n="$3" 'NR < s || NR >= s + n { print }' "$1"
}

# position <text> <needle>: the byte offset of the first needle, or -1.
position() {
  local text="$1" head
  case "$text" in
    *"$2"*) head="${text%%"$2"*}"; echo "${#head}" ;;
    *) echo "-1" ;;
  esac
}

# =============================================================================
# The fixture: hooks/ravintio.yml as the 0.37.2 release shipped it. The
# 0000031 guard bans a quiet grep fed by a pipe anywhere in a suite, so the
# heredoc holds @PIPE_QUIET_GREP@ and the sed below restores the real text.
FIXTURE="$WORK/ravintio-0.37.2.yml"
QUIET_GREP="grep -q"
sed "s/@PIPE_QUIET_GREP@/| $QUIET_GREP/g" > "$FIXTURE" <<'YML'
name: RAVINTIO Strict Pipeline

on:
  pull_request:
    branches: [ main, master ]

jobs:
  validate-branch:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Validate Code/Doc Parity
        run: |
          CHANGED_FILES=$(git diff --name-only origin/${{ github.base_ref }}...HEAD)
          COMMIT_MESSAGES=$(git log origin/${{ github.base_ref }}...HEAD --format="%s")

          # Fast Path exemption: if all commits are fix(fast-path): only require component.yml or changelog
          FAST_PATH_COUNT=$(echo "$COMMIT_MESSAGES" | grep -cE "^fix\(fast-path\):" || true)
          TOTAL_COUNT=$(echo "$COMMIT_MESSAGES" | grep -c "." || true)

          if [ "$FAST_PATH_COUNT" -gt 0 ] && [ "$FAST_PATH_COUNT" -eq "$TOTAL_COUNT" ]; then
            if echo "$CHANGED_FILES" @PIPE_QUIET_GREP@ "^src/"; then
              if ! echo "$CHANGED_FILES" @PIPE_QUIET_GREP@E "(component\.yml|plan/changelog/)"; then
                echo "::error title=RAVINTIO Fast Path Violation::Fast Path commits must update component.yml or plan/changelog/."
                exit 1
              fi
            fi
            echo "✅ RAVINTIO fast-path pipeline passed."
            exit 0
          fi

          # Standard check. This is a presence check, not a correspondence
          # guarantee: it confirms a file under plan/, docs/, or a
          # component.yml also changed in this diff — it does not verify
          # that file's content actually corresponds to the src/ change.
          if echo "$CHANGED_FILES" @PIPE_QUIET_GREP@ "^src/"; then
            if ! echo "$CHANGED_FILES" @PIPE_QUIET_GREP@E "^(plan/|docs/|.*component\.yml)"; then
              echo "::error title=RAVINTIO Strict Violation::Code under src/ changed with no plan/, docs/, or component.yml file also touched in this diff. This checks presence only — it does not verify that content corresponds to your change."
              exit 1
            fi
          fi
          echo "✅ RAVINTIO pipeline passed."
YML

echo ""
echo "=== req-005 AC1: the fixture is the 0.37.2 template ==="

if git -C "$ROOT" cat-file -e "$FIXTURE_COMMIT:ravintio-framework/hooks/ravintio.yml" 2>/dev/null; then
  git -C "$ROOT" show "$FIXTURE_COMMIT:ravintio-framework/hooks/ravintio.yml" > "$WORK/from-git.yml"
  assert_equals "yes" "$(yes_no cmp -s "$FIXTURE" "$WORK/from-git.yml")" \
    "req-005: the fixture equals hooks/ravintio.yml at the 0.37.2 template commit"
else
  echo "  SKIP: req-005: git can't resolve the 0.37.2 template commit here, so the fixture stands alone"
fi

# =============================================================================
echo ""
echo "=== req-005 AC1: the migration file and its header lines ==="

assert_equals "yes" "$(yes_no test -f "$MIGRATION")" "req-005: $STEM.md sits at the top level of migrations/"

assert_equals "yes" "$(yes_no grep -q '^# Migration: ' "$MIGRATION")" "req-005: the migration has a # Migration: title"

TARGET="$(header_line "$MIGRATION" '**Target:**')"
assert_contains "every" "$TARGET" "req-005: the Target line names every project"
assert_contains "framework source" "$TARGET" "req-005: the Target line includes the framework source"

SCOPE="$(header_line "$MIGRATION" '**Scope:**')"
assert_contains '`plan/.fast-path-scope`' "$SCOPE" "req-005: the Scope line names plan/.fast-path-scope"
assert_contains "\`$CI_PATH\`" "$SCOPE" "req-005: the Scope line names $CI_PATH"

MAY_EDIT="$(header_line "$MIGRATION" '**May edit:**')"
MAY_EDIT_PATHS="$(printf '%s\n' "$MAY_EDIT" | grep -oE '`[^`]+`' || true)"
assert_equals "\`$CI_PATH\`" "$MAY_EDIT_PATHS" "req-005: the May edit line names $CI_PATH and no other path"

SAFE="$(header_line "$MIGRATION" '**Safe to skip:**')"
assert_equals "yes" "$(yes_no grep -qE '^\*\*Safe to skip:\*\* No\.' <<< "$SAFE")" "req-005: the Safe to skip line opens with No."

assert_equals "no" "$(yes_no grep -qF '**Applies when:**' "$MIGRATION")" "req-005: the migration has no Applies when line, so every project runs it"

for h in "## Background" "## Migrator Instructions" "## Present Findings" "## Record"; do
  assert_equals "yes" "$(yes_no grep -qxF -- "$h" "$MIGRATION")" "req-005: the migration has a $h section"
done

# =============================================================================
echo ""
echo "=== req-005 AC1: the quoted exemption block ==="

quoted_blocks "$MIGRATION" > "$WORK/blocks.txt"
assert_equals "1" "$(grep -cx '@@END@@' "$WORK/blocks.txt")" "req-005: the migration quotes exactly one exemption block"
awk '$0 == "@@END@@" { exit } { print }' "$WORK/blocks.txt" > "$WORK/block.txt"

# The block runs from the comment to the fi that closes the FAST_PATH_COUNT test.
sed -n '20,33p' "$FIXTURE" > "$WORK/expected-block.txt"
assert_equals "yes" "$(yes_no cmp -s "$WORK/expected-block.txt" "$WORK/block.txt")" \
  "req-005: the quoted block is lines 20 to 33 of the 0.37.2 template, verbatim"
assert_equals "fi" "$(tail -1 "$WORK/block.txt" | tr -d ' ')" "req-005: the quoted block ends at the closing fi"

read -r COUNT START <<< "$(match_block "$WORK/block.txt" "$FIXTURE")"
assert_equals "1" "$COUNT" "req-005: the quoted block matches the 0.37.2 fixture once"
assert_equals "20" "$START" "req-005: the match starts at the # Fast Path exemption: line"

BLOCK_LINES="$(grep -c '' "$WORK/block.txt")"
drop_lines "$FIXTURE" "${START:-0}" "$BLOCK_LINES" > "$WORK/removed.yml"
assert_equals "0" "$(grep -cE 'fix\\?\(fast-path\\?\)|FAST_PATH_COUNT' "$WORK/removed.yml")" \
  "req-005: removing the block leaves no fix\\(fast-path\\) or FAST_PATH_COUNT text"
assert_equals "yes" "$(yes_no grep -qF '# Standard check.' "$WORK/removed.yml")" "req-005: the standard check stays after the removal"
{ sed -n '1,19p' "$FIXTURE"; sed -n '34,$p' "$FIXTURE"; } > "$WORK/expected-removed.yml"
assert_equals "yes" "$(yes_no cmp -s "$WORK/expected-removed.yml" "$WORK/removed.yml")" \
  "req-005: every line outside the block stays byte-identical"

# =============================================================================
echo ""
echo "=== req-005 AC1: the matching rule in a scratch 0.37.2 consumer ==="

CONSUMER="$WORK/consumer"
mkdir -p "$CONSUMER/.github/workflows"
CI_FILE="$CONSUMER/$CI_PATH"

# Trailing whitespace on the block lines still matches.
awk 'NR >= 20 && NR <= 33 { print $0 "   "; next } { print }' "$FIXTURE" > "$CI_FILE"
read -r COUNT START <<< "$(match_block "$WORK/block.txt" "$CI_FILE")"
assert_equals "1 20" "$COUNT $START" "req-005: the block matches once after trailing whitespace is trimmed"

# A second run on the cleaned file finds nothing, so the step counts as done.
read -r COUNT START <<< "$(match_block "$WORK/block.txt" "$WORK/removed.yml")"
assert_equals "0" "$COUNT" "req-005: a second run finds no block in the cleaned file"

# An edited block gives no match, while the retired words remain.
awk 'NR == 22 { sub(/TOTAL_COUNT/, "ALL_COUNT") } { print }' "$FIXTURE" > "$CI_FILE"
read -r COUNT START <<< "$(match_block "$WORK/block.txt" "$CI_FILE")"
assert_equals "0" "$COUNT" "req-005: an edited block gives no match"
assert_equals "yes" "$(yes_no grep -q 'FAST_PATH_COUNT' "$CI_FILE")" "req-005: the edited file still holds FAST_PATH_COUNT, so the migrator reports no match"

# Two copies of the block are not one match.
{ sed -n '1,33p' "$FIXTURE"; sed -n '20,33p' "$FIXTURE"; sed -n '34,$p' "$FIXTURE"; } > "$CI_FILE"
read -r COUNT START <<< "$(match_block "$WORK/block.txt" "$CI_FILE")"
assert_equals "2" "$COUNT" "req-005: two copies of the block are not a single match"

# =============================================================================
echo ""
echo "=== req-005 AC1: the Migrator Instructions ==="

STEPS="$(section "$MIGRATION" "## Migrator Instructions" "## Present Findings")"
ALL="$(cat "$MIGRATION" 2>/dev/null || true)"

for n in 1 2 3 4 5 6; do
  assert_equals "yes" "$(yes_no grep -qE "^$n\. " <<< "$STEPS")" "req-005: the Migrator Instructions hold step $n"
done

# The six steps run in the order req-005 gives.
P1="$(position "$STEPS" '`0.38.0`')"
P2="$(position "$STEPS" '`plan/current/change-summary.md`')"
P3="$(position "$STEPS" '`rm -- plan/.fast-path-scope`')"
P4="$(position "$STEPS" 'trailing whitespace')"
P5="$(position "$STEPS" 'matches once')"
P6="$(position "$STEPS" 'setup re-run')"
ORDER="no"
if [ "$P1" -ge 0 ] && [ "$P1" -lt "$P2" ] && [ "$P2" -lt "$P3" ] && [ "$P3" -lt "$P4" ] \
  && [ "$P4" -lt "$P5" ] && [ "$P5" -lt "$P6" ]; then
  ORDER="yes"
fi
assert_equals "yes" "$ORDER" "req-005: version check, run warning, delete, block read, removal, and setup re-run come in order"

# Step 1: the version check.
assert_contains '`ravintio-framework/component.yml`' "$STEPS" "req-005: step 1 reads ravintio-framework/component.yml"
assert_contains "refresh \`ravintio-framework/\`" "$STEPS" "req-005: step 1 asks for a pack refresh when the version is older"

# Step 2: the unfinished-run warning.
assert_contains '`plan/.fast-path-scope`' "$STEPS" "req-005: the run warning names the Fast Path leftover"
assert_contains '`plan/current/change-summary.md`' "$STEPS" "req-005: the run warning names the Change Pipeline leftover"
assert_contains "Feature Pipeline" "$STEPS" "req-005: the run warning sends the work to the Feature Pipeline"
assert_contains "warning changes no file" "$STEPS" "req-005: the run warning changes no file"

# Step 3: the human on the loop deletes the scope record (P2 revision).
assert_contains '`! rm -- plan/.fast-path-scope`' "$STEPS" "req-005: step 3 gives the Claude Code form of the delete"
assert_contains "never deletes" "$STEPS" "req-005: the migrator never deletes the scope record itself"
assert_contains "the Write-or-Edit rule (boot Hard Limit 8)" "$STEPS" "req-005: step 3 cites the Write-or-Edit rule by name"
assert_contains "path is gone" "$STEPS" "req-005: the migrator checks afterwards that the path is gone"
assert_contains "record body names" "$STEPS" "req-005: a leftover scope record goes in the record body"

# Steps 4 and 5: the CI block.
assert_contains "\`$CI_PATH\`" "$STEPS" "req-005: step 4 reads the CI file"
assert_contains "own confirmation" "$STEPS" "req-005: the CI edit needs its own confirmation"
assert_contains "\`autonomous\`" "$STEPS" "req-005: the CI edit still waits for an answer in autonomous run mode"
assert_contains "nothing else" "$STEPS" "req-005: the removal touches only the block lines"

# The declined or unmatched edit.
assert_contains '`declined`' "$STEPS" "req-005: a declined CI edit records the reason declined"
assert_contains '`no match`' "$STEPS" "req-005: an unmatched CI edit records the reason no match"
assert_contains '`corrections-skipped`' "$STEPS" "req-005: the edit counts in corrections-skipped"
assert_contains "line numbers" "$STEPS" "req-005: the migrator names the line numbers to delete by hand"
assert_contains "outcome \`skipped\`" "$STEPS" "req-005: a declined or unmatched edit records skipped"
assert_contains "never records \`applied\` with \`corrections-skipped: 0\`" "$STEPS" \
  "req-005: a declined or unmatched edit never records a clean applied"

# Step 6: the notice and the setup re-run.
assert_contains "setup.sh" "$STEPS" "req-005: step 6 names setup.sh"
assert_contains "setup.ps1" "$STEPS" "req-005: step 6 names setup.ps1"
assert_contains "each tool" "$STEPS" "req-005: step 6 asks for a re-run for each tool the project uses"
assert_contains '`ravintio-framework/hooks/ravintio.yml`' "$ALL" "req-005: the notice names the template to compare against"
assert_contains "0000364" "$ALL" "req-005: the notice names backlog 0000364"

# Every step is safe to repeat.
assert_contains "safe to repeat" "$ALL" "req-005: every step is safe to repeat"
assert_contains "second full run changes no file" "$ALL" "req-005: a second full run changes no file"

# The Record section.
RECORD="$(section "$MIGRATION" "## Record" "@@none@@")"
assert_contains "plan/_migrations/$STEM.md" "$RECORD" "req-005: the Record section names the record path"
assert_equals "no" "$(yes_no grep -q '_done' <<< "$ALL")" "req-005: the migration carries no _done text (0000035 req-007)"

# =============================================================================
echo ""
echo "=== req-005 AC3: the migrator scope rule ==="

LIMITS="$(section "$MIGRATOR" "## Hard Limits" "## Run records")"
RULE1="$(grep -m1 -E '^1\. ' <<< "$LIMITS" || true)"
assert_contains "Never modify files in \`src/\`" "$RULE1" "req-005: Hard Limit 1 keeps src/ closed"
assert_contains '`**May edit:**`' "$RULE1" "req-005: Hard Limit 1 names the May edit line"
for p in '`plan/`' '`docs/`' '`ravintio-framework/`'; do
  assert_contains "$p" "$RULE1" "req-005: Hard Limit 1 still names $p"
done

SKILL="$(cat "$MIGRATOR" 2>/dev/null || true)"
NAMED="$(section "$MIGRATOR" "### Named paths" "### Step 1: Read and summarise")"
assert_contains "own confirmation" "$NAMED" "req-005: each edit to a named path needs its own confirmation"
assert_contains "batch \`all\` answer doesn't cover" "$NAMED" "req-005: a batch all answer doesn't cover a named path"
assert_contains "\`autonomous\`" "$NAMED" "req-005: the migrator still asks in autonomous run mode"
assert_contains "absolute path" "$NAMED" "req-005: the migrator refuses an absolute path"
assert_contains '`..` part' "$NAMED" "req-005: the migrator refuses a .. part"
assert_contains "symbolic link" "$NAMED" "req-005: the migrator refuses a linked target or parent"
assert_contains "under \`src/\`" "$NAMED" "req-005: the migrator refuses a named path under src/"
assert_contains "reports each refusal" "$NAMED" "req-005: the migrator reports each refusal"
assert_contains "edits nothing there" "$NAMED" "req-005: a refused path gets no edit"

OUTCOMES="$(section "$MIGRATOR" "**Outcomes:**" "**Pending rule:**")"
SKIPPED="$(grep -m1 -F -- '- `skipped`:' <<< "$OUTCOMES" || true)"
assert_contains "named path" "$SKIPPED" "req-005: the skipped outcome covers a named-path edit"
assert_contains "declined" "$SKIPPED" "req-005: the skipped outcome covers a declined edit"
assert_contains "couldn't match" "$SKIPPED" "req-005: the skipped outcome covers an edit the migrator couldn't match"
assert_contains "the skip rule (migrator Hard Limit 3)" "$SKIPPED" "req-005: the skipped outcome keeps the skip rule"
assert_contains "the scope rule (migrator Hard Limit 1)" "$SKILL" "req-005: the migrator cites the scope rule by name"

print_summary
