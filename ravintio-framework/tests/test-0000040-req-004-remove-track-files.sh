#!/usr/bin/env bash
# Verified by: integration
# Tests for feature 0000040-retire-fast-path.
#
# req-004: the pack holds no Fast Path or Change Pipeline workflow, no change
#          agent, and no change summary template. setup.sh and setup.ps1 carry
#          the retired list as two arrays and remove each listed copy from the
#          tool they set up, with or without a skill manifest (ADR-005).
#
# The suite follows test-0000030-req-004-install-clean-up-and-retired-flags.sh.
# It runs the setup.ps1 cases when PowerShell is on PATH.
#
# Environment (P4, after test-0000039-req-006-consumer-migration.sh):
#   RAVINTIO_TEST_PWSH         the PowerShell binary for the .ps1 pass. The
#                              default is pwsh. When set, a missing binary
#                              fails the suite instead of printing SKIP.
#   RAVINTIO_TEST_REQ004_ONLY  set to ps1 to skip the setup.sh runs. The
#                              static checks and the .ps1 pass still run.
# The test-suite CI job runs the whole suite on pwsh (PowerShell 7). The
# setup-powershell-51 job runs the .ps1 pass under powershell.exe (Windows
# PowerShell 5.1) with RAVINTIO_TEST_REQ004_ONLY=ps1.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
SETUP_SH="$FRAMEWORK/setup.sh"
SETUP_PS1="$FRAMEWORK/setup.ps1"
WORKFLOW="$FRAMEWORK/../.github/workflows/ravintio.yml"
PS_BIN="${RAVINTIO_TEST_PWSH:-pwsh}"
ONLY="${RAVINTIO_TEST_REQ004_ONLY:-}"

WORK="$(mktemp -d -t ravintio_0000040_req004_XXXXXX)"
OUTSIDE="$(mktemp -d -t ravintio_0000040_req004_outside_XXXXXX)"
# The failed-delete case makes a folder read-only, so restore write access
# before the delete. An interrupted run still removes both folders.
trap 'chmod -R u+w "$WORK" "$OUTSIDE" 2>/dev/null; rm -rf "$WORK" "$OUTSIDE"' EXIT

yes_no() { if "$@"; then echo "yes"; else echo "no"; fi; }

HAS_PWSH=no
command -v "$PS_BIN" >/dev/null 2>&1 && HAS_PWSH=yes

IS_WIN=no
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) IS_WIN=yes ;; esac

# One pack copy without its tests, shared by every workspace.
PACK="$WORK/pack"
cp -R "$FRAMEWORK" "$PACK"
rm -rf "$PACK/tests"

# make_workspace <name>: a git repository holding a copy of the pack.
make_workspace() {
  local ws="$WORK/$1"
  mkdir -p "$ws"
  cp -R "$PACK" "$ws/ravintio-framework"
  git init -q "$ws" >/dev/null 2>&1
  printf '%s' "$ws"
}

# run_setup <sh|ps1> <workspace> <tool>: runs setup and sets OUT and RC.
run_setup() {
  if [ "$1" = "ps1" ]; then
    # powershell.exe under Git Bash ends each line with CR, so strip it.
    OUT="$(cd "$2" && "$PS_BIN" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ravintio-framework/setup.ps1 "$3" 2>&1 | tr -d '\r')"
  else
    OUT="$(cd "$2" && bash ravintio-framework/setup.sh "$3" 2>&1)"
  fi
  RC=$?
}

# tool_dirs <tool>: sets SKILLS_REL and WORKFLOWS_REL from setup/{tool}.sh.
tool_dirs() {
  SKILLS_REL="$(sed -n 's/^TOOL_SKILLS_DIR="\(.*\)"$/\1/p' "$FRAMEWORK/setup/$1.sh")"
  WORKFLOWS_REL="$(sed -n 's/^TOOL_WORKFLOWS_DIR="\(.*\)"$/\1/p' "$FRAMEWORK/setup/$1.sh")"
}

# seed <workspace> <tool>: plants every retired copy for the tool, plus one
# consumer file in each folder. Sets SEEDED to the planted retired paths.
seed() {
  local ws="$1"
  tool_dirs "$2"
  SEEDED=""
  if [ -n "$WORKFLOWS_REL" ]; then
    mkdir -p "$ws/$WORKFLOWS_REL"
    echo "old" > "$ws/$WORKFLOWS_REL/fast-path.md"
    echo "old" > "$ws/$WORKFLOWS_REL/change-pipeline.md"
    echo "mine" > "$ws/$WORKFLOWS_REL/my-own-command.md"
    SEEDED="$WORKFLOWS_REL/fast-path.md
$WORKFLOWS_REL/change-pipeline.md"
  fi
  mkdir -p "$ws/$SKILLS_REL/ravintio-change-agent/references" "$ws/$SKILLS_REL/my-own-skill"
  echo "old" > "$ws/$SKILLS_REL/ravintio-change-agent/SKILL.md"
  : > "$ws/$SKILLS_REL/ravintio-change-agent/references/.gitkeep"
  echo "mine" > "$ws/$SKILLS_REL/my-own-skill/SKILL.md"
  SEEDED="${SEEDED:+$SEEDED
}$SKILLS_REL/ravintio-change-agent"
}

# retired_lines: the sorted (retired, removed) lines in OUT.
retired_lines() { printf '%s\n' "$OUT" | grep -F '(retired, removed)' | LC_ALL=C sort; }

# expected_lines: the sorted line each SEEDED path should print.
expected_lines() { printf '%s\n' "$SEEDED" | sed 's/^\(.*\)$/  - \1 (retired, removed)/' | LC_ALL=C sort; }

# expect_cleaned <shell> <workspace> <tool> <label>
expect_cleaned() {
  local ws="$2" p
  assert_equals "0" "$RC" "req-004: $1 $3 $4: setup exits 0"
  while IFS= read -r p; do
    assert_equals "no" "$(yes_no test -e "$ws/$p")" "req-004: $1 $3 $4: $p is gone"
  done <<< "$SEEDED"
  assert_equals "$(expected_lines)" "$(retired_lines)" "req-004: $1 $3 $4: one (retired, removed) line per retired path"
  assert_equals "yes" "$(yes_no test -f "$ws/$SKILLS_REL/my-own-skill/SKILL.md")" "req-004: $1 $3 $4: a consumer skill stays"
  if [ -n "$WORKFLOWS_REL" ]; then
    assert_equals "yes" "$(yes_no test -f "$ws/$WORKFLOWS_REL/my-own-command.md")" "req-004: $1 $3 $4: a consumer command stays"
  fi
}

# =============================================================================
echo ""
echo "=== req-004: the pack holds no retired track file ==="

for p in workflows/fast-path.md workflows/change-pipeline.md skills/ravintio-change-agent templates/change-summary.template.md; do
  assert_equals "no" "$(yes_no test -e "$FRAMEWORK/$p")" "req-004: the pack holds no $p"
done

# =============================================================================
echo ""
echo "=== req-004: setup.sh and setup.ps1 carry the retired list as two arrays ==="

# array_items <file> <open pattern> <close pattern>: the lines between them.
array_items() { awk -v o="$2" -v c="$3" '$0 ~ o {on=1; next} on && $0 ~ c {on=0} on' "$1"; }

# Bracket expressions keep the patterns free of awk escape handling.
SH_WF="$(array_items "$SETUP_SH" '^RETIRED_TRACK_WORKFLOWS=[(]$' '^[)]$')"
SH_SK="$(array_items "$SETUP_SH" '^RETIRED_TRACK_SKILLS=[(]$' '^[)]$')"
PS_WF="$(array_items "$SETUP_PS1" '^[$]RetiredTrackWorkflows = @[(]$' '^[)]$')"
PS_SK="$(array_items "$SETUP_PS1" '^[$]RetiredTrackSkills = @[(]$' '^[)]$')"
assert_equals "$(printf '%s\n%s' '  "fast-path.md"' '  "change-pipeline.md"')" "$SH_WF" "req-004: RETIRED_TRACK_WORKFLOWS lists both workflows, one quoted path per line"
assert_equals '  "ravintio-change-agent"' "$SH_SK" "req-004: RETIRED_TRACK_SKILLS lists the change agent, one quoted path per line"
assert_equals "$(printf '%s\n%s' "    'fast-path.md',"  "    'change-pipeline.md'")" "$PS_WF" "req-004: \$RetiredTrackWorkflows lists both workflows, one quoted path per line"
assert_equals "    'ravintio-change-agent'" "$PS_SK" "req-004: \$RetiredTrackSkills lists the change agent, one quoted path per line"
assert_contains "0000040 req-004" "$(grep -B4 '^RETIRED_TRACK_WORKFLOWS=($' "$SETUP_SH")" "req-004: a comment in setup.sh names 0000040 req-004"
assert_contains "0000040 req-004" "$(grep -B4 '^\$RetiredTrackWorkflows = @($' "$SETUP_PS1")" "req-004: a comment in setup.ps1 names 0000040 req-004"

# The call sits after the manifest prune and before the skill copy.
line_of() { grep -n -- "$2" "$1" | head -1 | cut -d: -f1; }
in_order() { [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ] && [ "$1" -lt "$2" ] && [ "$2" -lt "$3" ]; }
assert_equals "yes" "$(yes_no in_order "$(line_of "$SETUP_SH" 'rm -f "$manifest"')" "$(line_of "$SETUP_SH" '^  cleanup_retired_tracks ')" "$(line_of "$SETUP_SH" '^  copy_skills "$skills_dir"')")" \
  "req-004: setup_tool calls cleanup_retired_tracks after the manifest prune and before copy_skills"
assert_equals "yes" "$(yes_no in_order "$(line_of "$SETUP_PS1" 'Remove-Item -Path $manifest -Force')" "$(line_of "$SETUP_PS1" '^    Invoke-RetiredTrackCleanup ')" "$(line_of "$SETUP_PS1" '^    Copy-RavintioSkills -TargetDir $skillsDir')")" \
  "req-004: Invoke-RavintioSetup calls Invoke-RetiredTrackCleanup after the manifest prune and before Copy-RavintioSkills"

# The track clean-up needs no Node.js, so it sits outside the retired-integrations pass.
SH_FN="$(awk '/^cleanup_retired_tracks\(\) \{/{on=1} on{print} on && /^\}/{exit}' "$SETUP_SH")"
PS_FN="$(awk '/^function Invoke-RetiredTrackCleanup \{/{on=1} on{print} on && /^\}/{exit}' "$SETUP_PS1")"
assert_equals "no" "$(yes_no grep -q 'node' <<< "$SH_FN")" "req-004: cleanup_retired_tracks needs no node"
assert_equals "no" "$(yes_no grep -q 'node' <<< "$PS_FN")" "req-004: Invoke-RetiredTrackCleanup needs no node"
assert_contains "pwd -P" "$SH_FN" "req-004: cleanup_retired_tracks resolves the parent folder physically"
assert_contains "-LiteralPath" "$PS_FN" "req-004: Invoke-RetiredTrackCleanup deletes by -LiteralPath"
assert_contains "ReparsePoint" "$PS_FN" "req-004: Invoke-RetiredTrackCleanup removes a link as a link"

# =============================================================================
echo ""
echo "=== req-004 AC3: the 5.1 CI job runs the .ps1 pass under Windows PowerShell 5.1 ==="

# job_block ID prints one job from the workflow, up to the next job.
job_block() {
  awk -v id="  $1:" '
    $0 == id { on = 1; print; next }
    on && /^  [^ ]/ { exit }
    on { print }
  ' "$WORKFLOW"
}
# step_with TEXT prints the step in stdin that holds TEXT, up to the next step.
step_with() {
  awk -v t="$1" '
    /^      - / { if (hit) exit; buf = "" }
    { buf = buf $0 "\n" }
    index($0, t) { hit = 1 }
    END { if (hit) printf "%s", buf }
  '
}
in_text() { grep -E -- "$1" <<< "$2" >/dev/null && echo yes || echo no; }

SUITE_NAME="test-0000040-req-004-remove-track-files.sh"
S51="$(job_block setup-powershell-51 | step_with "$SUITE_NAME")"
assert_equals "yes" "$(in_text "bash ravintio-framework/tests/$SUITE_NAME\$" "$S51")" "req-004 AC3: the 5.1 job runs the req-004 suite"
assert_equals "yes" "$(in_text 'shell:[[:space:]]*bash$' "$S51")" "req-004 AC3: the req-004 step runs the suite through Git Bash"
assert_equals "yes" "$(in_text 'RAVINTIO_TEST_PWSH:[[:space:]]*powershell\.exe$' "$S51")" "req-004 AC3: the req-004 step sets RAVINTIO_TEST_PWSH to powershell.exe"
assert_equals "yes" "$(in_text 'RAVINTIO_TEST_REQ004_ONLY:[[:space:]]*ps1$' "$S51")" "req-004 AC3: the req-004 step runs the .ps1 pass only"
assert_equals "yes" "$(in_text 'PSVersion\.Major' "$S51")" "req-004 AC3: the req-004 step reads the PowerShell major version"
assert_equals "yes" "$(in_text '"\$major" != 5' "$S51")" "req-004 AC3: the req-004 step fails unless the major version is 5"
assert_equals "no" "$(in_text 'secrets\.' "$S51")" "req-004 AC3: the req-004 step references no secrets"

if [ "$HAS_PWSH" = "no" ] && [ -n "${RAVINTIO_TEST_PWSH:-}" ]; then
  echo "  FAIL: req-004 AC3: RAVINTIO_TEST_PWSH names $PS_BIN, which is not on PATH"; FAIL=$((FAIL + 1))
fi

SHELLS=""
if [ "$ONLY" = "ps1" ]; then
  echo "  SKIP: req-004: the setup.sh runs, because RAVINTIO_TEST_REQ004_ONLY=ps1"
else
  SHELLS="sh"
fi
if [ "$HAS_PWSH" = "yes" ]; then
  echo "  PowerShell: $PS_BIN $("$PS_BIN" -NoProfile -NonInteractive -Command '$PSVersionTable.PSVersion.ToString()' 2>&1 | tr -d '\r')"
  SHELLS="${SHELLS:+$SHELLS }ps1"
elif [ -z "${RAVINTIO_TEST_PWSH:-}" ]; then
  echo "  SKIP: req-004: pwsh is not on PATH, so the setup.ps1 runs don't happen"
fi

# =============================================================================
echo ""
echo "=== req-004: a fresh setup.sh claude-code installs only the kept tracks ==="

if [ "$ONLY" = "ps1" ]; then
  echo "  SKIP: req-004: the fresh setup.sh run, because RAVINTIO_TEST_REQ004_ONLY=ps1"
else
  WS="$(make_workspace fresh)"
  run_setup sh "$WS" claude-code
  assert_equals "0" "$RC" "req-004: fresh claude-code: setup exits 0"
  for wf in feature-pipeline.md retrofit.md; do
    assert_equals "yes" "$(yes_no test -f "$WS/.claude/commands/$wf")" "req-004: fresh claude-code: .claude/commands/$wf is installed"
  done
  for p in .claude/commands/fast-path.md .claude/commands/change-pipeline.md .claude/skills/ravintio-change-agent; do
    assert_equals "no" "$(yes_no test -e "$WS/$p")" "req-004: fresh claude-code: no $p"
  done
  assert_equals "" "$(retired_lines)" "req-004: fresh claude-code: no (retired, removed) line"
fi

# =============================================================================
echo ""
echo "=== req-004: setup removes every retired copy for each tool ==="

for shell in $SHELLS; do
  for tool in claude-code antigravity copilot codex cursor windsurf cline; do
    WS="$(make_workspace "seed-$shell-$tool")"
    seed "$WS" "$tool"
    run_setup "$shell" "$WS" "$tool"
    expect_cleaned "$shell" "$WS" "$tool" "no manifest"
  done

  # A rerun finds nothing.
  WS="$WORK/seed-$shell-claude-code"
  run_setup "$shell" "$WS" claude-code
  assert_equals "0" "$RC" "req-004: $shell claude-code rerun: setup exits 0"
  assert_equals "" "$(retired_lines)" "req-004: $shell claude-code rerun: no (retired, removed) line"

  # A manifest that lists stale paths from an old checkout.
  WS="$(make_workspace "stale-manifest-$shell")"
  seed "$WS" claude-code
  printf '%s\n' "/no/such/checkout/.claude/skills/ravintio-change-agent" "/no/such/checkout/.claude/skills/ravintio-adr-agent" \
    > "$WS/.claude/skills/.ravintio-manifest"
  run_setup "$shell" "$WS" claude-code
  expect_cleaned "$shell" "$WS" claude-code "stale manifest"
done

# =============================================================================
echo ""
echo "=== req-004: a linked skills folder outside the project stays untouched ==="

if [ "$IS_WIN" = "yes" ]; then
  echo "  SKIP (windows): ln -s makes a copy under Git Bash, so the linked skills folder cannot be built"
else
  for shell in $SHELLS; do
    WS="$(make_workspace "linked-$shell")"
    TARGET="$OUTSIDE/skills-$shell"
    mkdir -p "$TARGET/ravintio-change-agent" "$WS/.claude"
    echo "keep me" > "$TARGET/ravintio-change-agent/SKILL.md"
    ln -s "$TARGET" "$WS/.claude/skills"
    run_setup "$shell" "$WS" claude-code
    assert_equals "0" "$RC" "req-004: $shell linked skills folder: setup exits 0"
    assert_equals "yes" "$(yes_no test -f "$TARGET/ravintio-change-agent/SKILL.md")" "req-004: $shell linked skills folder: the folder outside the project stays"
    assert_contains ".claude/skills/ravintio-change-agent resolves outside the project - not removed" "$OUT" "req-004: $shell linked skills folder: the refusal is reported"
    # The first run writes a manifest that lists the refused folder. The
    # second run's manifest prune must not delete it through the link (P4).
    run_setup "$shell" "$WS" claude-code
    assert_equals "0" "$RC" "req-004: $shell linked skills folder rerun: setup exits 0"
    assert_equals "yes" "$(yes_no test -f "$TARGET/ravintio-change-agent/SKILL.md")" "req-004: $shell linked skills folder rerun: the folder outside the project and its SKILL.md stay"
    assert_equals "no" "$(yes_no grep -q 'removed: ravintio-change-agent' <<< "$OUT")" "req-004: $shell linked skills folder rerun: no removed line for the refused folder"
    assert_contains ".claude/skills/ravintio-change-agent resolves outside the project - not removed" "$OUT" "req-004: $shell linked skills folder rerun: the refusal is reported again"
  done
fi

# =============================================================================
echo ""
echo "=== req-004: a retired path that is itself a link goes as a link ==="

# The retired skill folder links to a folder outside the project, and the
# retired workflow links to a file outside it. Setup removes each link and
# leaves its target and the target's contents in place.
if [ "$IS_WIN" = "yes" ]; then
  echo "  SKIP (windows): ln -s makes a copy under Git Bash, so a retired path cannot be a link"
else
  for shell in $SHELLS; do
    WS="$(make_workspace "retired-link-$shell")"
    DIR_TARGET="$OUTSIDE/change-agent-$shell"
    FILE_TARGET="$OUTSIDE/fast-path-$shell.md"
    mkdir -p "$DIR_TARGET/references" "$WS/.claude/skills" "$WS/.claude/commands"
    echo "keep me" > "$DIR_TARGET/SKILL.md"
    echo "keep me too" > "$DIR_TARGET/references/notes.md"
    echo "keep this file" > "$FILE_TARGET"
    ln -s "$DIR_TARGET" "$WS/.claude/skills/ravintio-change-agent"
    ln -s "$FILE_TARGET" "$WS/.claude/commands/fast-path.md"
    run_setup "$shell" "$WS" claude-code
    L="req-004: $shell retired link"
    assert_equals "0" "$RC" "$L: setup exits 0"
    for p in .claude/skills/ravintio-change-agent .claude/commands/fast-path.md; do
      assert_equals "no" "$(yes_no test -L "$WS/$p")" "$L: the link $p is gone"
      assert_equals "no" "$(yes_no test -e "$WS/$p")" "$L: nothing stands at $p"
    done
    assert_equals "yes" "$(yes_no test -f "$DIR_TARGET/SKILL.md")" "$L: the linked folder's SKILL.md survives"
    assert_equals "yes" "$(yes_no test -f "$DIR_TARGET/references/notes.md")" "$L: the linked folder's nested file survives"
    assert_equals "keep this file" "$(cat "$FILE_TARGET" 2>/dev/null)" "$L: the linked file survives with its content"
    assert_equals "$(printf '%s\n%s' '  - .claude/commands/fast-path.md (retired, removed)' '  - .claude/skills/ravintio-change-agent (retired, removed)')" \
      "$(retired_lines)" "$L: one (retired, removed) line per link"
  done
fi

# =============================================================================
echo ""
echo "=== req-004: a failed delete warns, leaves the path, and setup exits 0 ==="

# A read-only folder inside the retired skill folder blocks its delete. The
# skills folder itself stays writable, so the rest of the install runs.
if [ "$IS_WIN" = "yes" ]; then
  echo "  SKIP (windows): chmod 555 does not block deletes on NTFS, so the undeletable retired folder cannot be built"
elif [ "$(id -u)" = "0" ]; then
  echo "  SKIP: req-004: running as root, a read-only folder cannot block a delete"
else
  for shell in $SHELLS; do
    WS="$(make_workspace "locked-$shell")"
    LOCKED="$WS/.claude/skills/ravintio-change-agent/references"
    mkdir -p "$LOCKED"
    echo "old" > "$WS/.claude/skills/ravintio-change-agent/SKILL.md"
    echo "old" > "$LOCKED/notes.md"
    chmod 555 "$LOCKED"
    run_setup "$shell" "$WS" claude-code
    chmod 755 "$LOCKED"
    L="req-004: $shell failed delete"
    assert_equals "0" "$RC" "$L: setup exits 0"
    assert_contains "  ! could not remove .claude/skills/ravintio-change-agent - left in place, delete it by hand" "$OUT" "$L: the warning names the path"
    assert_equals "yes" "$(yes_no test -d "$WS/.claude/skills/ravintio-change-agent")" "$L: the path is left in place"
    assert_equals "" "$(retired_lines)" "$L: no (retired, removed) line"
    assert_contains "Setup complete." "$OUT" "$L: the rest of the install finishes"
  done
fi

print_summary
