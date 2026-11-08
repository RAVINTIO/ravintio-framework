#!/usr/bin/env bash
# Verified by: integration
# Verified by: execution
#
# Tests for feature 0000041-pack-source-under-src, req-006: the 0.39.0 consumer
# migration that offers to remove a leftover ravintio-framework/component.yml
# (ADR-008).
#
# Acceptance criteria covered:
#   AC1 (integration)  the migration file text: header lines, sections, steps,
#                      the rm command, the skipped reasons, and step 8.
#   AC2 (execution)    scratch consumer repos. The suite takes the rm command
#                      from the migration text and runs it in the scratch repo,
#                      then applies the step order the migration states to each
#                      case. A real migrator run belongs to P4 verify-by-execution.
#   AC3 (integration)  this repo's record for the migration.
#
# Section extraction uses awk -v with bracket classes, so no regex escapes
# reach the shell. Every loop reads lines with `done <<< "$(...)"`.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
source "$SCRIPT_DIR/helpers/pack-root.sh"

FW="$RAVINTIO_PACK_DIR"
REPO="$RAVINTIO_REPO_ROOT"
STEM="migrate-0.39.0-remove-pack-component-yml"
MIGRATION="$FW/migrations/$STEM.md"
RECORD="$REPO/plan/_migrations/$STEM.md"
LEFTOVER="ravintio-framework/component.yml" # portable-ok: the consumer-repo path the migration removes, not a pack-source path
RM_CMD="rm -- $LEFTOVER"

WORK="$(mktemp -d -t ravintio_0000041_req006_XXXXXX)" || { echo "  FAIL: req-006: mktemp -d failed"; exit 1; }
trap 'rm -rf "$WORK"' EXIT

# IS_WIN: yes under Git Bash, MSYS, or Cygwin. There, ln -s copies the target.
IS_WIN=no
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) IS_WIN=yes ;; esac

yes_no() {
  if "$@"; then echo yes; else echo no; fi
}

# section <file> <start heading> <next heading>: the lines between two headings.
section() {
  awk -v a="$2" -v b="$3" '$0 == a { on = 1; next } on && $0 == b { exit } on { print }' "$1" 2>/dev/null
}

# step_of <text> <n> <next>: the lines from step <n> up to step <next>.
step_of() {
  awk -v s="^$2[.] " -v e="^$3[.] " '$0 ~ s { on = 1 } on && $0 ~ e { exit } on { print }' <<< "$1"
}

# header_line <file> <key>: the first line that opens with the bold key.
header_line() {
  grep -m1 -F -- "$2" "$1" 2>/dev/null | grep -E '^[*][*]' || true
}

# position <text> <needle>: the byte offset of the first needle, or -1.
position() {
  local text="$1" head
  case "$text" in
    *"$2"*) head="${text%%"$2"*}"; echo "${#head}" ;;
    *) echo "-1" ;;
  esac
}

# frontmatter_value <file> <key>: the unquoted value of a frontmatter key.
frontmatter_value() {
  awk -v key="$2" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 {
      i = index($0, ":")
      if (i > 0 && substr($0, 1, i - 1) == key) {
        v = substr($0, i + 1)
        sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
        if (v ~ /^".*"$/) v = substr(v, 2, length(v) - 2)
        print v
        exit
      }
    }' "$1" 2>/dev/null
}

# =============================================================================
echo ""
echo "=== req-006 AC1: the migration file and its header lines ==="

assert_equals "yes" "$(yes_no test -f "$MIGRATION")" "req-006: $STEM.md sits at the top level of migrations/"
assert_equals "yes" "$(yes_no grep -q '^# Migration: ' "$MIGRATION")" "req-006: the migration has a # Migration: title"

TARGET="$(header_line "$MIGRATION" '**Target:**')"
assert_contains "downstream" "$TARGET" "req-006: the Target line names the downstream projects"
assert_contains "0.39.0" "$TARGET" "req-006: the Target line names the 0.39.0 pack"

APPLIES="$(header_line "$MIGRATION" '**Applies to:**')"
assert_equals "**Applies to:** downstream" "$APPLIES" "req-006: the Applies to line is downstream"

SCOPE="$(header_line "$MIGRATION" '**Scope:**')"
assert_contains "\`$LEFTOVER\`" "$SCOPE" "req-006: the Scope line names $LEFTOVER"
assert_contains "\`ravintio-framework/release.yml\`" "$SCOPE" "req-006: the Scope line names release.yml as read-only"
assert_contains "changes nothing there" "$SCOPE" "req-006: the Scope line says release.yml stays unchanged"

SAFE="$(header_line "$MIGRATION" '**Safe to skip:**')"
assert_contains "**Safe to skip:** Yes" "$SAFE" "req-006: the Safe to skip line is Yes"
assert_contains "step 1a" "$SAFE" "req-006: the Safe to skip line names the step 1a warning"
assert_contains "warns" "$SAFE" "req-006: the Safe to skip line says step 1a warns while the file stays"

assert_equals "no" "$(yes_no grep -qF '**May edit:**' "$MIGRATION")" "req-006: the migration has no May edit line"
assert_equals "no" "$(yes_no grep -qF '**Applies when:**' "$MIGRATION")" "req-006: the migration has no Applies when line"

for h in "## Background" "## Migrator Instructions" "## Present Findings" "## Record"; do
  assert_equals "yes" "$(yes_no grep -qxF -- "$h" "$MIGRATION")" "req-006: the migration has a $h section"
done

# =============================================================================
echo ""
echo "=== req-006 AC1: the Migrator Instructions ==="

STEPS="$(section "$MIGRATION" "## Migrator Instructions" "## Present Findings")"
ALL="$(cat "$MIGRATION" 2>/dev/null || true)"

for n in 1 2 3 3a 4 5 6 7 8; do
  assert_equals "yes" "$(yes_no grep -qE "^$n[.] " <<< "$STEPS")" "req-006: the Migrator Instructions hold step $n"
done

S1="$(step_of "$STEPS" 1 2)"
S2="$(step_of "$STEPS" 2 3)"
S3="$(step_of "$STEPS" 3 3a)"
S3A="$(step_of "$STEPS" 3a 4)"
S4="$(step_of "$STEPS" 4 5)"
S5="$(step_of "$STEPS" 5 6)"
S6="$(step_of "$STEPS" 6 7)"
S7="$(step_of "$STEPS" 7 8)"
S8="$(awk '/^8[.] /{ on = 1 } on { print }' <<< "$STEPS")"

# Step order: release.yml, leftover check, link, product.yml, confirm, rm, path check, decline, skipped body.
P1="$(position "$STEPS" '`ravintio-framework/release.yml`')"
P2="$(position "$STEPS" "doesn't exist as a file or a link")"
P3="$(position "$STEPS" '`ravintio-framework` itself is a link')"
P4="$(position "$STEPS" '`product.yml`')"
P5="$(position "$STEPS" 'confirm')"
P6="$(position "$STEPS" "$RM_CMD")"
P7="$(position "$STEPS" 'declines')"
ORDER="no"
if [ "$P1" -ge 0 ] && [ "$P1" -lt "$P2" ] && [ "$P2" -lt "$P3" ] && [ "$P3" -lt "$P4" ] \
  && [ "$P4" -lt "$P5" ] && [ "$P5" -lt "$P6" ] && [ "$P6" -lt "$P7" ]; then
  ORDER="yes"
fi
assert_equals "yes" "$ORDER" "req-006: release check, leftover check, link check, product.yml check, confirmation, delete, and decline come in order"

# Step 1: the release.yml check and the malformed stop.
assert_contains '`ravintio-framework/release.yml`' "$S1" "req-006: step 1 reads release.yml"
assert_contains "doesn't exist" "$S1" "req-006: step 1 stops when release.yml is missing"
assert_contains '`0.39.0`' "$S1" "req-006: step 1 compares the version with 0.39.0"
assert_contains "older" "$S1" "req-006: step 1 stops on an older version"
assert_contains "refresh \`ravintio-framework/\`" "$S1" "req-006: step 1 asks for a pack refresh"
assert_contains "Record nothing" "$S1" "req-006: step 1 records nothing, so the migration stays pending"
assert_contains "breaks the format" "$S1" "req-006: step 1 stops on a release.yml that breaks the format"
assert_contains "report the file" "$S1" "req-006: the malformed stop reports the file"
assert_contains "ADR-004" "$S1" "req-006: the malformed stop cites ADR-004"

# Step 2: the leftover check.
assert_contains "\`$LEFTOVER\`" "$S2" "req-006: step 2 names the leftover file"
assert_contains "file or a link" "$S2" "req-006: step 2 treats a link as a leftover too"
assert_contains '`applied`' "$S2" "req-006: step 2 records applied when nothing is left"
assert_contains "both counts at \`0\`" "$S2" "req-006: step 2 records both counts at 0"

# Step 3: a linked ravintio-framework folder.
assert_contains '`ravintio-framework` itself is a link' "$S3" "req-006: step 3 checks whether ravintio-framework itself is a link"
assert_contains "don't show a delete command" "$S3" "req-006: step 3 holds back the delete command"
assert_contains "by hand" "$S3" "req-006: step 3 asks the human on the loop to check by hand"
assert_contains '`corrections-skipped`' "$S3" "req-006: step 3 counts in corrections-skipped"
assert_contains '`refused`' "$S3" "req-006: step 3 records the reason refused"

# Step 3a: a product.yml listing (risk R-013).
assert_contains '`product.yml`' "$S3A" "req-006: step 3a reads product.yml"
assert_contains "\`$LEFTOVER\`" "$S3A" "req-006: step 3a names the leftover file as a component path"
assert_contains "don't offer the removal" "$S3A" "req-006: step 3a offers no removal"
assert_contains '`product-version.mjs`' "$S3A" "req-006: step 3a names product-version.mjs"
assert_contains "component.yml not found" "$S3A" "req-006: step 3a quotes the exit 2 message"
assert_contains "R-013" "$S3A" "req-006: step 3a cites risk R-013"
assert_contains "never edits" "$S3A" "req-006: the migrator never edits product.yml"
assert_contains "migrator Hard Limit 1" "$S3A" "req-006: step 3a cites the scope rule"
assert_contains '`corrections-skipped`' "$S3A" "req-006: step 3a counts in corrections-skipped"
assert_contains '`listed in product.yml`' "$S3A" "req-006: step 3a records the reason listed in product.yml"

# Step 4: one confirmation, never batched.
assert_contains '`version`' "$S4" "req-006: step 4 shows the version the file reports"
assert_contains "release.yml" "$S4" "req-006: step 4 says the pack now ships release.yml"
assert_contains "own confirmation" "$S4" "req-006: the removal needs its own confirmation"
assert_contains "batch \`all\` answer doesn't cover it" "$S4" "req-006: a batch all answer doesn't cover the removal"
assert_contains '`autonomous`' "$S4" "req-006: the migrator still asks in autonomous run mode"

# Step 5: the human-run delete.
assert_contains "doesn't delete the file itself" "$S5" "req-006: the migrator never deletes the file itself"
assert_contains "the Write-or-Edit rule (boot Hard Limit 8)" "$S5" "req-006: step 5 cites the Write-or-Edit rule by name"
assert_contains "0000366" "$S5" "req-006: step 5 cites backlog 0000366"
assert_contains "\`$RM_CMD\`" "$S5" "req-006: step 5 shows the rm command"
assert_contains "\`! $RM_CMD\`" "$S5" "req-006: step 5 gives the Claude Code form of the delete"
assert_contains "project root" "$S5" "req-006: step 5 says to run the command from the project root"
assert_contains "removes the link and never its target" "$S5" "req-006: step 5 says rm removes a link and never its target"

# Step 6: the path check and its two outcomes.
assert_contains "is done" "$S6" "req-006: step 6 waits for the human on the loop to say it is done"
assert_contains "gone" "$S6" "req-006: step 6 checks that the path is gone"
assert_contains "file or as a link" "$S6" "req-006: step 6 checks for a file and for a link"
assert_contains '`corrections-applied`' "$S6" "req-006: step 6 counts a removal in corrections-applied"
assert_contains '`not removed`' "$S6" "req-006: step 6 records the reason not removed"
assert_contains '`corrections-skipped`' "$S6" "req-006: step 6 counts a leftover in corrections-skipped"

# Step 7: a decline.
assert_contains "change no file" "$S7" "req-006: a decline changes no file"
assert_contains '`declined`' "$S7" "req-006: a decline records the reason declined"
assert_contains '`corrections-skipped`' "$S7" "req-006: a decline counts in corrections-skipped"

# Step 8: the skipped body names the file.
assert_contains "\`$LEFTOVER\`" "$S8" "req-006: step 8 names the leftover file in every skipped body"
assert_contains "reason" "$S8" "req-006: step 8 names the reason in every skipped body"
assert_contains "step 1a" "$S8" "req-006: step 8 tells the human on the loop that step 1a warns"
assert_contains "session start" "$S8" "req-006: step 8 says the warning runs at each session start"

# The four skipped reasons, anywhere in the migration.
for r in declined 'not removed' refused 'listed in product.yml'; do
  assert_contains "\`$r\`" "$ALL" "req-006: the migration names the skipped reason $r"
done

# Every step is safe to repeat, and no other file changes.
assert_contains "safe to repeat" "$ALL" "req-006: every step is safe to repeat"
assert_contains "second full run changes no file" "$ALL" "req-006: a second full run changes no file"
assert_contains "no other file" "$ALL" "req-006: the migration changes no other file"

# The Record section.
RECORD_SECTION="$(section "$MIGRATION" "## Record" "@@none@@")"
assert_contains "plan/_migrations/$STEM.md" "$RECORD_SECTION" "req-006: the Record section names the record path"
assert_equals "no" "$(yes_no grep -q '_done' <<< "$ALL")" "req-006: the migration carries no _done text (0000035 req-007)"

# =============================================================================
echo ""
echo "=== req-006 AC2: scratch consumer runs ==="

# The command the suite runs is the one the migration shows, not a copy of it.
SHOWN_CMD="$(grep -oE 'rm -- [^` ]+' <<< "$S5" | head -1)"
assert_equals "$RM_CMD" "$SHOWN_CMD" "req-006: the rm command in the migration is the one the scratch runs use"

# mk_consumer <name> <release version or none> <leftover yes|no> <product.yml yes|no|none>
mk_consumer() {
  local d="$WORK/$1"
  mkdir -p "$d/ravintio-framework/migrations" "$d/plan/_migrations"
  if [ "$2" != "none" ]; then
    printf 'version: "%s"\nsource-commit: "abc"\nbuild-date: "2026-11-07"\n' "$2" > "$d/ravintio-framework/release.yml"
  fi
  if [ "$3" = "yes" ]; then
    printf 'id: "ravintio-framework"\nversion: "0.38.0"\n' > "$d/$LEFTOVER"
  fi
  case "$4" in
    yes) printf 'id: "app"\ncomponents:\n  - id: "pack"\n    path: "%s"\n' "$LEFTOVER" > "$d/product.yml" ;;
    no) printf 'id: "app"\ncomponents:\n  - id: "app"\n    path: "src/app/component.yml"\n' > "$d/product.yml" ;;
  esac
  printf 'keep\n' > "$d/ravintio-framework/other.md"
  echo "$d"
}

# snapshot <dir>: path and hash of every file except plan/_migrations/ records.
snapshot() {
  (cd "$1" && find . -type f -not -path './plan/_migrations/*' | LC_ALL=C sort | while IFS= read -r f; do
    printf '%s %s\n' "$f" "$(sha256_of "$f")"
  done)
}

# version_ok <release.yml>: yes when version reads 0.39.0 or later.
version_ok() {
  local v
  v="$(awk -F'"' '$1 ~ /^version:/ { print $2; exit }' "$1" 2>/dev/null)"
  [ -n "$v" ] || { echo no; return; }
  local a b c
  IFS=. read -r a b c <<< "$v"
  if [ "${a:-0}" -gt 0 ] || [ "${b:-0}" -ge 39 ]; then echo yes; else echo no; fi
}

# run_migration <dir> <answer: confirm|decline> <fixture runs rm: yes|no>
# Applies the steps in the order the migration states. Prints the outcome line,
# or "none" when step 1 stops and nothing is recorded. Writes the record under
# plan/_migrations/ like the migrator.
run_migration() {
  local d="$1" answer="$2" does_rm="$3" rec="$1/plan/_migrations/$STEM.md"
  local outcome applied=0 skipped=0 body="" reason=""
  if [ -f "$rec" ]; then echo "unchanged"; return; fi
  if [ ! -f "$d/ravintio-framework/release.yml" ] || [ "$(version_ok "$d/ravintio-framework/release.yml")" != "yes" ]; then
    echo "none"; return
  fi
  if [ ! -e "$d/$LEFTOVER" ] && [ ! -L "$d/$LEFTOVER" ]; then
    outcome="applied"
  elif [ -L "$d/ravintio-framework" ]; then
    outcome="skipped"; skipped=1; reason="refused"
  elif [ -f "$d/product.yml" ] && grep -qF -- "path: \"$LEFTOVER\"" "$d/product.yml"; then
    outcome="skipped"; skipped=1; reason="listed in product.yml"
  elif [ "$answer" = "decline" ]; then
    outcome="skipped"; skipped=1; reason="declined"
  else
    if [ "$does_rm" = "yes" ]; then (cd "$d" && eval "$SHOWN_CMD"); fi
    if [ ! -e "$d/$LEFTOVER" ] && [ ! -L "$d/$LEFTOVER" ]; then
      outcome="applied"; applied=1
    else
      outcome="skipped"; skipped=1; reason="not removed"
    fi
  fi
  if [ "$outcome" = "skipped" ]; then body="The migration left \`$LEFTOVER\` in place. Reason: $reason."; fi
  printf -- '---\nmigration: "%s.md"\noutcome: "%s"\ndate: "2026-11-07"\nframework-version: "0.39.0"\ncorrections-applied: %s\ncorrections-skipped: %s\n---\n%s\n' \
    "$STEM" "$outcome" "$applied" "$skipped" "$body" > "$rec"
  echo "$outcome"
}

# Case 1: the removal is confirmed and the fixture runs the rm.
C="$(mk_consumer c1 0.39.0 yes no)"
BEFORE="$(snapshot "$C")"
assert_equals "applied" "$(run_migration "$C" confirm yes)" "req-006: a confirmed removal records applied"
assert_equals "no" "$(yes_no test -e "$C/$LEFTOVER")" "req-006: the confirmed removal leaves no $LEFTOVER"
assert_equals "1" "$(frontmatter_value "$C/plan/_migrations/$STEM.md" corrections-applied)" "req-006: the confirmed removal holds corrections-applied: 1"
assert_equals "$(grep -vF "./$LEFTOVER " <<< "$BEFORE")" "$(snapshot "$C")" "req-006: every other file stays byte-identical after the removal"
REC1="$(cat "$C/plan/_migrations/$STEM.md")"
assert_equals "unchanged" "$(run_migration "$C" confirm yes)" "req-006: a second run changes nothing"
assert_equals "$REC1" "$(cat "$C/plan/_migrations/$STEM.md")" "req-006: a second run leaves the record unchanged"

# Case 1b: the human says it's done but the file stays.
C="$(mk_consumer c1b 0.39.0 yes no)"
assert_equals "skipped" "$(run_migration "$C" confirm no)" "req-006: a leftover after the delete step records skipped"
assert_contains "not removed" "$(cat "$C/plan/_migrations/$STEM.md")" "req-006: a leftover after the delete step records not removed"

# Case 2: the removal is declined.
C="$(mk_consumer c2 0.39.0 yes no)"
BEFORE="$(snapshot "$C")"
assert_equals "skipped" "$(run_migration "$C" decline no)" "req-006: a declined removal records skipped"
assert_equals "$BEFORE" "$(snapshot "$C")" "req-006: a declined removal leaves every file byte-identical"
BODY="$(cat "$C/plan/_migrations/$STEM.md")"
assert_contains "$LEFTOVER" "$BODY" "req-006: the declined record body names the file"
assert_contains "declined" "$BODY" "req-006: the declined record body names the reason declined"
assert_equals "1" "$(frontmatter_value "$C/plan/_migrations/$STEM.md" corrections-skipped)" "req-006: the declined record holds corrections-skipped: 1"
REC2="$BODY"
run_migration "$C" confirm yes > /dev/null
assert_equals "$REC2" "$(cat "$C/plan/_migrations/$STEM.md")" "req-006: a second run after a decline leaves the record unchanged"

# Case 3: product.yml lists the leftover file.
C="$(mk_consumer c3 0.39.0 yes yes)"
BEFORE="$(snapshot "$C")"
assert_equals "skipped" "$(run_migration "$C" confirm yes)" "req-006: a product.yml listing records skipped"
assert_equals "$BEFORE" "$(snapshot "$C")" "req-006: a product.yml listing leaves $LEFTOVER and product.yml byte-identical"
BODY="$(cat "$C/plan/_migrations/$STEM.md")"
assert_contains "listed in product.yml" "$BODY" "req-006: the product.yml record body names the reason"
assert_contains "$LEFTOVER" "$BODY" "req-006: the product.yml record body names the file"
assert_equals "no" "$(yes_no grep -qF -- "$RM_CMD" <<< "$S3A")" "req-006: step 3a shows no rm command"

# Case 4: no leftover file.
C="$(mk_consumer c4 0.39.0 no no)"
BEFORE="$(snapshot "$C")"
assert_equals "applied" "$(run_migration "$C" confirm yes)" "req-006: no leftover file records applied"
assert_equals "0 0" "$(frontmatter_value "$C/plan/_migrations/$STEM.md" corrections-applied) $(frontmatter_value "$C/plan/_migrations/$STEM.md" corrections-skipped)" "req-006: no leftover file holds both counts at 0"
assert_equals "$BEFORE" "$(snapshot "$C")" "req-006: no leftover file leaves every file byte-identical"

# Case 5: no release.yml, and an older release.yml.
C="$(mk_consumer c5 none yes no)"
assert_equals "none" "$(run_migration "$C" confirm yes)" "req-006: no release.yml writes no record"
assert_equals "no" "$(yes_no test -e "$C/plan/_migrations/$STEM.md")" "req-006: no release.yml leaves no record file"
assert_equals "yes" "$(yes_no test -f "$C/$LEFTOVER")" "req-006: no release.yml leaves the leftover file in place"
C="$(mk_consumer c5b 0.38.0 yes no)"
assert_equals "none" "$(run_migration "$C" confirm yes)" "req-006: a release.yml older than 0.39.0 writes no record"

# Case 6: ravintio-framework itself is a link.
if [ "$IS_WIN" = yes ]; then
  echo "  SKIP (windows): a linked ravintio-framework: ln -s makes a copy under Git Bash, so a link cannot be built"
else
  C="$(mk_consumer c6 0.39.0 yes no)"
  mv "$C/ravintio-framework" "$C/real-pack"
  ln -s real-pack "$C/ravintio-framework"
  assert_equals "skipped" "$(run_migration "$C" confirm yes)" "req-006: a linked ravintio-framework records skipped"
  assert_contains "refused" "$(cat "$C/plan/_migrations/$STEM.md")" "req-006: a linked ravintio-framework records the reason refused"
  assert_equals "yes" "$(yes_no test -f "$C/real-pack/component.yml")" "req-006: a linked ravintio-framework keeps the file"
fi

# =============================================================================
echo ""
echo "=== req-006 AC3: this repo's record ==="

assert_equals "yes" "$(yes_no test -f "$RECORD")" "req-006: plan/_migrations/$STEM.md exists"
assert_equals "$STEM.md" "$(frontmatter_value "$RECORD" migration)" "req-006: the record names its migration"
assert_equals "not applicable" "$(frontmatter_value "$RECORD" outcome)" "req-006: the record outcome is not applicable"
assert_equals "0" "$(frontmatter_value "$RECORD" corrections-applied)" "req-006: the record holds corrections-applied: 0"
assert_equals "0" "$(frontmatter_value "$RECORD" corrections-skipped)" "req-006: the record holds corrections-skipped: 0"
DATE_VALUE="$(frontmatter_value "$RECORD" date)"
assert_equals "yes" "$([[ "$DATE_VALUE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && echo yes || echo no)" "req-006: the record holds a YYYY-MM-DD date"
assert_equals "yes" "$([[ "$(frontmatter_value "$RECORD" framework-version)" =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]] && echo yes || echo no)" "req-006: the record holds a framework-version"
RECORD_BODY="$( [ -f "$RECORD" ] && awk 'f >= 2 { print } /^---$/ { f++ }' "$RECORD")"
assert_contains "framework source" "$RECORD_BODY" "req-006: the record body says this project is the framework source"

print_summary
