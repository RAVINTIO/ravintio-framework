#!/usr/bin/env bash
# Verified by: integration
# Tests for feature 0000040-retire-fast-path.
#
# req-002: the write gates and the ratchet read no scope record. With no
#          design, gate-write and shell-write-guard block every write outside
#          plan/, docs/, and the permitted names, with the no-design reason
#          alone. A file at plan/.fast-path-scope changes no verdict and no
#          output. path-rules.mjs keeps its enforcement path list as
#          ENFORCEMENT_PATHS (ADR-002, ADR-004).
#
# This suite replaces test-0000035-req-001-fast-path-scope-record.sh and
# takes over the direct isEnforcementPath checks from
# test-0000035-req-009-fast-path-enforcement-paths.sh.
#
# Every fixture lives under mktemp -d. The suite uses git to build fixtures.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO="$(cd "$FRAMEWORK/.." && pwd)"
ENF="$FRAMEWORK/hooks/enforcement"
GATE_WRITE="$ENF/gate-write.mjs"
SHELL_GUARD="$ENF/shell-write-guard.mjs"
RATCHET="$ENF/ratchet-check.mjs"
PATH_RULES="$ENF/path-rules.mjs"

# Git Bash gives /tmp/x, which node reads as C:\tmp\x. pwd -W gives the Windows form.
WORK="$(cd "$(mktemp -d -t ravintio_0000040_req002_XXXXXX)" && { pwd -W 2>/dev/null || pwd; })"
trap 'rm -rf "$WORK"' EXIT

native() {
  if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

# native_url <path>: a file:// URL for a Node import. On Windows, import() rejects D:/x.
native_url() {
  if command -v cygpath >/dev/null 2>&1; then printf 'file:///%s' "$(cygpath -m "$1")"; else printf 'file://%s' "$1"; fi
}

GIT=(git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c init.defaultBranch=main)

# The shell guard drops the leading [RAVINTIO] tag, so the reason omits it.
NO_DESIGN="No confirmed design at plan/current/design.md. Complete Phase 0 first."
NOT_REGULAR="[RAVINTIO] plan/current/design.md is not a regular file, so the gate treats it as no design."
OVERSIZE="[RAVINTIO] plan/current/design.md is over the 1 MiB size cap, so the gate treats it as no design."

FX="$WORK/repo"
DESIGN="$FX/plan/current/design.md"
SCOPE="$FX/plan/.fast-path-scope"
mkdir -p "$FX/plan/current" "$FX/src"
"${GIT[@]}" init -q "$FX" >/dev/null 2>&1
"${GIT[@]}" -C "$FX" commit -q --allow-empty -m init --no-verify >/dev/null 2>&1
BRANCH="$(git -C "$FX" rev-parse --abbrev-ref HEAD)"
HEAD_ID="$(git -C "$FX" rev-parse HEAD)"

TARGETS="src/a.js
README.md
ravintio-framework/hooks/enforcement/gate-write.mjs
ravintio-framework/hooks/CLAUDE.md"

# record_text <branch> <head>: a well-formed record that lists every target.
record_text() {
  printf 'branch: %s\nhead: %s\npaths:\n' "$1" "$2"
  printf '%s\n' "$TARGETS" | while IFS= read -r t; do printf -- '- %s\n' "$t"; done
}

# The link kind points at a current record outside the fixture.
record_text "$BRANCH" "$HEAD_ID" > "$WORK/linked-record"
LINKS=no
ln -s "$WORK/linked-record" "$WORK/link-probe" 2>/dev/null && [ -L "$WORK/link-probe" ] && LINKS=yes

RECORD_KINDS="current stale invalid oversize folder"
if [ "$LINKS" = "yes" ]; then
  RECORD_KINDS="$RECORD_KINDS link"
else
  echo "  SKIP: req-002: this platform can't create symbolic links, so the linked record kind doesn't run"
fi

# set_record <kind>: puts a scope record of <kind> at plan/.fast-path-scope.
# The kind none removes it.
set_record() {
  rm -rf "$SCOPE"
  case "$1" in
    none) ;;
    current) record_text "$BRANCH" "$HEAD_ID" > "$SCOPE" ;;
    stale) record_text "some-other-branch" "$HEAD_ID" > "$SCOPE" ;;
    invalid) printf 'paths:\n- src/*\nbranch: ;\n' > "$SCOPE" ;;
    oversize)
      { record_text "$BRANCH" "$HEAD_ID"; for i in $(seq 1 400); do printf '# %s\n' "$(printf 'c%.0s' $(seq 1 50))"; done; } > "$SCOPE"
      ;;
    folder) mkdir -p "$SCOPE" && record_text "$BRANCH" "$HEAD_ID" > "$SCOPE/record" ;;
    link) ln -s "$WORK/linked-record" "$SCOPE" ;;
  esac
}

# set_design <state>: missing, folder, or oversize at design.md. Each one
# takes the no-design route.
set_design() {
  rm -rf "$DESIGN"
  case "$1" in
    missing) ;;
    folder) mkdir -p "$DESIGN" ;;
    oversize)
      printf '# Design\n\n## Component Paths\n\n- src/\n- ravintio-framework/\n- README.md\n' > "$DESIGN"
      truncate -s 2M "$DESIGN"
      ;;
  esac
}

# run_gate <target>: a Write of <target> through gate-write. Sets CODE, OUT, and ERR.
run_gate() {
  node "$GATE_WRITE" >"$WORK/stdout.txt" 2>"$WORK/stderr.txt" <<< "{\"cwd\":\"$(native "$FX")\",\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$1\"}}"
  CODE=$?
  OUT=$(cat "$WORK/stdout.txt")
  ERR=$(cat "$WORK/stderr.txt")
}

# run_guard <command>: <command> through the shell-write guard. Sets CODE, OUT, and ERR.
run_guard() {
  node "$SHELL_GUARD" >"$WORK/stdout.txt" 2>"$WORK/stderr.txt" <<< "{\"cwd\":\"$(native "$FX")\",\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$1\"}}"
  CODE=$?
  OUT=$(cat "$WORK/stdout.txt")
  ERR=$(cat "$WORK/stderr.txt")
}

# extra_line <design state>: the line each block adds for that state, or empty.
extra_line() {
  case "$1" in
    folder) printf '%s' "$NOT_REGULAR" ;;
    oversize) printf '%s' "$OVERSIZE" ;;
  esac
}

# no_track_text <text>: yes when <text> names no retired track and no record.
no_track_text() {
  case "$1" in
    *"Fast Path"*|*"fast-path"*|*"Change Pipeline"*|*"scope record"*) echo no ;;
    *) echo yes ;;
  esac
}

# =============================================================================
echo ""
echo "=== req-002: no record kind changes a no-design verdict or its output ==="

for state in missing folder oversize; do
  set_design "$state"
  EXTRA="$(extra_line "$state")"
  while IFS= read -r target; do
    for hook in gate guard; do
      set_record none
      if [ "$hook" = "gate" ]; then run_gate "$target"; else run_guard "touch $target"; fi
      BASE_CODE="$CODE"
      BASE_OUTPUT="$OUT|$ERR"
      assert_equals "2" "$BASE_CODE" "req-002: $hook blocks $target with design.md $state and no record"
      assert_contains "$NO_DESIGN" "$ERR" "req-002: $hook gives the no-design reason for $target with design.md $state"
      if [ -n "$EXTRA" ]; then
        assert_contains "$EXTRA" "$ERR" "req-002: $hook keeps the extra line for design.md $state on $target"
      fi
      assert_equals "yes" "$(no_track_text "$OUT$ERR")" "req-002: $hook names no retired track for $target with design.md $state"
      for kind in $RECORD_KINDS; do
        set_record "$kind"
        if [ "$hook" = "gate" ]; then run_gate "$target"; else run_guard "touch $target"; fi
        assert_equals "$BASE_CODE" "$CODE" "req-002: $hook gives the same exit for $target with a $kind record and design.md $state"
        assert_equals "$BASE_OUTPUT" "$OUT|$ERR" "req-002: $hook gives the same output for $target with a $kind record and design.md $state"
      done
    done
  done <<< "$TARGETS"
done
set_design missing
set_record none

# =============================================================================
echo ""
echo "=== req-002: permitted paths, the sentinel, and a design keep their behaviour ==="

set_record current
run_gate "docs/notes.md"
assert_equals "0" "$CODE" "req-002: docs/notes.md passes with a current record and no design"
assert_equals "" "$ERR" "req-002: an always-permitted write prints nothing"
run_gate "src/a/CLAUDE.md"
assert_equals "0" "$CODE" "req-002: a permitted name outside every enforcement path passes"
run_guard "touch docs/notes.md"
assert_equals "0" "$CODE" "req-002: the shell guard passes docs/notes.md"
assert_equals "" "$ERR" "req-002: the shell guard prints nothing for docs/notes.md"

run_gate "plan/current/x.md"
assert_equals "2" "$CODE" "req-002: plan/current/x.md blocks without the sentinel"
assert_contains "plan/.orchestrator-active" "$ERR" "req-002: the sentinel reason still applies"

printf '## Component Paths\n- lib/\n' > "$DESIGN"
run_gate "src/a.js"
assert_equals "2" "$CODE" "req-002: with a design, src/a.js outside it blocks"
assert_contains "not covered by the confirmed design" "$ERR" "req-002: the component-path reason applies"
run_gate "lib/x.js"
assert_equals "0" "$CODE" "req-002: with a design, a covered path passes"
run_guard "touch lib/x.js"
assert_equals "0" "$CODE" "req-002: with a design, the shell guard passes a covered path"
set_design missing
set_record none

# =============================================================================
echo ""
echo "=== req-002: ENFORCEMENT_PATHS and isEnforcementPath ==="

LIST_STATE=$(node --input-type=module -e "
import * as rules from '$(native_url "$PATH_RULES")';
const list = rules.ENFORCEMENT_PATHS;
process.stdout.write([
  Array.isArray(list) && list.length > 0,
  Object.isFrozen(list),
  'FAST_PATH_ENFORCEMENT_PATHS' in rules,
  typeof rules.isEnforcementPath,
].join(' '));
")
assert_equals "true true false function" "$LIST_STATE" "req-002: path-rules.mjs exports a frozen ENFORCEMENT_PATHS, no old name, and isEnforcementPath"

# matches <path>...: the isEnforcementPath result for each path, space separated.
matches() {
  node --input-type=module -e "
import { isEnforcementPath } from '$(native_url "$PATH_RULES")';
process.stdout.write(process.argv.slice(1).map((p) => String(isEnforcementPath(p))).join(' '));
" "$@"
}

for target in \
  "ravintio-framework/hooks/enforcement/gate-write.mjs" \
  "RAVINTIO-Framework/Hooks/x.mjs" \
  "ravintio-framework/scripts/run-mode.mjs" \
  "ravintio-framework/setup/claude-code.sh" \
  "ravintio-framework/standards/autonomous-run-standards.md" \
  "setup.sh" \
  "tools/setup.ps1" \
  ".claude/hooks/enforcement/gate-write.mjs" \
  ".cursor/hooks/adapters/cursor.mjs" \
  ".git/hooks/pre-commit" \
  ".git/config" \
  ".claude/settings.json" \
  ".claude/settings.local.json" \
  ".CLAUDE/Settings.Local.JSON" \
  ".cursor/settings.json" \
  ".clinerules/hooks.json" \
  ".windsurf/hooks.json" \
  ".github/hooks/ravintio.json" \
  ".github/workflows/ravintio.yml" \
  ".GitHub/Workflows/RAVINTIO.yml" \
  ".codex/config.toml" \
  "opencode.json" \
  "opencode.jsonc" \
  ".opencode/plugins/@ravintio/opencode-hooks/index.js"; do
  assert_equals "true" "$(matches "$target")" "req-002: isEnforcementPath covers $target"
done

for target in "tools/setup.sh.md" "docs-site/hooks/x.md" ".github/workflows/other.yml" "ravintio-framework/workflows/x.md" "src/a.js"; do
  assert_equals "false" "$(matches "$target")" "req-002: isEnforcementPath leaves out $target"
done

# The match folds compatibility forms and case widely (G-S02).
LONG_S=$'\xc5\xbf'
assert_equals "true true true" \
  "$(matches "ravintio-framework/hook${LONG_S}/enforcement/gate-write.mjs" ".claude/${LONG_S}ettings.json" ".claude/settings.j${LONG_S}on")" \
  "req-002: isEnforcementPath folds the long s to s"

# =============================================================================
echo ""
echo "=== req-002: a target can't forge a line of hook output (G-S11) ==="

# forged_lines <prefix>: how many stderr lines start with prefix.
forged_lines() { printf '%s\n' "$ERR" | grep -c "^$1" || true; }
LS=$'\xe2\x80\xa8'

run_gate 'src/b.js\n[RAVINTIO] forged line'
assert_equals "2" "$CODE" "req-002: a target with a newline still blocks with no design"
assert_equals "0" "$(forged_lines '\[RAVINTIO\] forged')" "req-002: the no-design reason prints no forged line"

run_guard "touch 'src/b.js\n[RAVINTIO] forged line'"
assert_equals "2" "$CODE" "req-002: the shell guard blocks a target with a newline"
assert_equals "0" "$(forged_lines '\[RAVINTIO\] forged')" "req-002: the shell guard block line prints no forged line"
assert_contains "writes 'src/b.js\n[RAVINTIO]" "$ERR" "req-002: the shell guard block line shows the newline as \\n"
run_guard "touch \$Q'\n[RAVINTIO] forged line'"
assert_equals "0" "$CODE" "req-002: a word with no literal prefix still passes"
assert_contains "no literal prefix" "$ERR" "req-002: the no-literal-prefix warning applies"
assert_equals "0" "$(forged_lines '\[RAVINTIO\] forged')" "req-002: the no-literal-prefix warning prints no forged line"
run_guard "cd a; cd b; cd c; cd d; cd e; cd f; cd g; touch 'src/e.js\n[RAVINTIO] forged line'"
assert_equals "2" "$CODE" "req-002: a relative target after too many folders blocks"
assert_contains "too many to judge" "$ERR" "req-002: the too-many-folders reason applies"
assert_equals "0" "$(forged_lines '\[RAVINTIO\] forged')" "req-002: the too-many-folders reason prints no forged line"
run_guard "cd \$D; touch 'docs/f.md\n[RAVINTIO] forged line'"
assert_equals "0" "$CODE" "req-002: a permitted target after a cd the guard can't follow passes"
assert_contains "after a cd it can't follow" "$ERR" "req-002: the cd-it-can't-follow warning applies"
assert_equals "0" "$(forged_lines '\[RAVINTIO\] forged')" "req-002: the cd-it-can't-follow warning prints no forged line"
run_guard "touch 'src/g.js${LS}[RAVINTIO] forged line'"
assert_equals "2" "$CODE" "req-002: the shell guard blocks a target with U+2028"
assert_equals "no" "$([[ "$ERR" == *"$LS"* ]] && echo yes || echo no)" "req-002: the shell guard prints no raw U+2028"

printf '## Component Paths\n- lib/\n' > "$DESIGN"
run_gate 'src/d.js\r\n[RAVINTIO] forged\tline'
assert_equals "2" "$CODE" "req-002: an uncovered target with a newline still blocks"
assert_contains "not covered by the confirmed design" "$ERR" "req-002: the not-covered reason applies"
assert_equals "0" "$(forged_lines '\[RAVINTIO\] forged')" "req-002: the not-covered reason prints no forged line"
assert_contains 'src/d.js\r\n[RAVINTIO] forged\tline' "$ERR" "req-002: the not-covered reason escapes \\r, \\n, and \\t"
run_gate "src/$(printf 'x%.0s' $(seq 1 200)).js"
assert_equals "no" "$([[ "$ERR" == *"src/$(printf 'x%.0s' $(seq 1 77))"* ]] && echo yes || echo no)" \
  "req-002: the not-covered reason shows no more than 80 characters of the path"

# Bidirectional controls and other format characters print as an escape
# (G-N3). The bytes are the UTF-8 forms of U+202E, U+2066, and U+200B.
RLO=$'\xe2\x80\xae'
LRI=$'\xe2\x81\xa6'
ZWSP=$'\xe2\x80\x8b'
BS='\'
run_gate "src/h${RLO}sj.js${LRI}x${ZWSP}y${LS}z"
assert_equals "2" "$CODE" "req-002: an uncovered target with format characters still blocks"
assert_contains "src/h${BS}u{202E}sj.js${BS}u{2066}x${BS}u{200B}y${BS}u{2028}z" "$ERR" "req-002: format characters print as \\u{XXXX}"
assert_equals "no" "$([[ "$ERR" == *"$RLO"* || "$ERR" == *"$LRI"* || "$ERR" == *"$ZWSP"* ]] && echo yes || echo no)" \
  "req-002: the reason prints no raw bidirectional control or format character"
run_guard "touch 'src/h${RLO}sj.js'"
assert_equals "no" "$([[ "$ERR" == *"$RLO"* ]] && echo yes || echo no)" "req-002: the shell guard prints no raw U+202E"
set_design missing

# =============================================================================
echo ""
echo "=== req-002: ratchet-check gives the same verdict with and without a record ==="

RFX="$WORK/ratchet"
mkdir -p "$RFX/plan/current"
git init -q "$RFX" >/dev/null 2>&1
printf -- '---\nstatus: "active"\n---\n# Loop State: x\n' > "$RFX/plan/current/loop-state-x.md"
printf '# Requirement\n## Acceptance Criteria\n- [ ] criterion alpha holds\n- [ ] criterion beta holds\n' > "$RFX/plan/current/req.md"

# run_ratchet: a weakening Edit of plan/current/req.md. Sets CODE, OUT, and ERR.
run_ratchet() {
  local payload
  payload=$(node -e '
    const [cwd] = process.argv.slice(1);
    process.stdout.write(JSON.stringify({cwd, tool_name: "Edit", tool_input: {file_path: "plan/current/req.md", old_string: "- [ ] criterion beta holds\n", new_string: ""}}));
  ' "$(native "$RFX")")
  node "$RATCHET" >"$WORK/stdout.txt" 2>"$WORK/stderr.txt" <<< "$payload"
  CODE=$?
  OUT=$(cat "$WORK/stdout.txt")
  ERR=$(cat "$WORK/stderr.txt")
}

run_ratchet
assert_equals "2" "$CODE" "req-002: ratchet-check blocks a weakening Edit with no record"
BASE_OUTPUT="$OUT|$ERR"
printf 'branch: main\nhead: %s\npaths:\n- plan/current/req.md\n' "$HEAD_ID" > "$RFX/plan/.fast-path-scope"
run_ratchet
assert_equals "2" "$CODE" "req-002: ratchet-check blocks the same Edit with a record"
assert_equals "$BASE_OUTPUT" "$OUT|$ERR" "req-002: ratchet-check gives the same output with a record"

# =============================================================================
echo ""
echo "=== req-002: source search of the hooks and the root .gitignore ==="

for file in path-rules.mjs gate-write.mjs shell-write-guard.mjs ratchet-check.mjs; do
  for token in fast-path-scope FAST_PATH_SCOPE_FILE parseScopeRecord readGitState scopeVerdict loadScope readScope \
    "Fast Path: admitted" FAST_PATH_ENFORCEMENT_PATHS; do
    assert_equals "0" "$(grep -cF -- "$token" "$ENF/$file" || true)" "req-002: $file holds no $token"
  done
  assert_equals "0" "$(grep -ciE 'fast[ _-]?path' "$ENF/$file" || true)" "req-002: $file names no Fast Path in any form"
done
assert_equals "0" "$(grep -cF 'fast-path' "$REPO/.gitignore" || true)" "req-002: the root .gitignore names no scope record and no fast-path.md"

print_summary
