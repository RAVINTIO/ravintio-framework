#!/usr/bin/env bash
# Verified by: unit
# Verified by: integration
# test-0000040-req-001-one-track-routing.sh
# Feature 0000040-retire-fast-path, req-001-one-track-routing (ADR-002).
# Every request that meets no standalone skill trigger routes to the Feature
# Pipeline, with or without a src/ target. No skill, template, or routing doc
# offers Fast Path or the Change Pipeline as a route.
# Criterion 2 also reads getting-started.md, pipeline-reference.md, and
# src/setup-hook-integration/docs/scope.md. req-007 writes those, so their
# checks pass only after req-007's P3 step.
# Run from any directory: bash ravintio-framework/tests/test-0000040-req-001-one-track-routing.sh
#
# REGRESSION-CANDIDATE: covers one-track routing in the orchestrator and the files that restate it, tagged by test-writer for human review at P7

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_DIR="$SCRIPT_DIR"
if [ "$(basename "$SCRIPT_DIR")" = "regression" ]; then
  TESTS_DIR="$(dirname "$SCRIPT_DIR")"
fi
source "$TESTS_DIR/helpers/assert.sh"

FW="$(cd "$TESTS_DIR/.." && pwd)"
ROOT="$(cd "$FW/.." && pwd)"
ORCH="$FW/skills/ravintio-orchestrator/SKILL.md"
PHASE0="$FW/skills/ravintio-orchestrator/references/phase-0-assess-and-coach.md"
ADOPT="$FW/skills/ravintio-orchestrator/references/adoption-modes.md"
SHIP="$FW/skills/ravintio-ship-agent/SKILL.md"
PIPEREF="$FW/pipeline-reference.md"

# has <needle> <haystack> <label>: passes when the haystack holds the needle.
has() {
  assert_equals "present" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# lacks <needle> <haystack> <label>: passes when the haystack omits the needle.
lacks() {
  assert_equals "absent" "$([[ "$2" == *"$1"* ]] && echo present || echo absent)" "$3"
}

# no_track_words <file> <label>: passes when the file names no retired track.
# The match ignores case, so "change pipeline run" counts too.
no_track_words() {
  local hits
  if [ ! -f "$1" ]; then
    assert_equals "file present" "file missing" "$2: $1 exists"
    return
  fi
  hits="$(grep -n -i -E 'fast path|fast-path|change pipeline|change-pipeline|change-agent' "$1" || true)"
  assert_equals "" "$hits" "$2 names no retired track"
}

ROUTING=$(sed -n '/^## Routing Directive/,/^## Phase Skip Protocol/p' "$ORCH")
TRIAGE=$(sed -n '/^## Routing Directive/,/^### /p' "$ORCH")
STANDALONE=$(sed -n '/^### Standalone Skills/,/^## Phase Skip Protocol/p' "$ORCH")
PREFIXES=$(sed -n '/^## Response Prefix Convention/,/^## Resume Detection/p' "$ORCH")
HL10=$(grep -E '^10\. ' "$ORCH")

echo "=== req-001: Routing Directive has two outcomes ==="

has "Every request must be triaged before any action is taken." "$TRIAGE" \
  "req-001: Routing Directive keeps the triage rule"
has "after P9" "$TRIAGE" "req-001: triage covers requests after P9"
has "whether or not a run is active" "$TRIAGE" "req-001: triage applies whether or not a run is active"
has "Triage has two outcomes." "$TRIAGE" "req-001: triage names two outcomes"
has "meets a standalone skill trigger invokes that skill" "$TRIAGE" \
  "req-001: a standalone skill trigger invokes that skill"
has "Every other request goes to the Feature Pipeline." "$TRIAGE" \
  "req-001: every other request goes to the Feature Pipeline"
has 'no `src/` target' "$TRIAGE" "req-001: the Feature Pipeline takes a change with no src/ target"
lacks "four tracks" "$ROUTING" "req-001: Routing Directive drops the four-track sentence"

echo ""
echo "=== req-001: Standalone Skills table ==="

for skill in ravintio-optimise-agent ravintio-refresh-setup; do
  row=$(grep "^| \`$skill\`" <<< "$STANDALONE")
  assert_equals "yes" "$([ -n "$row" ] && echo yes || echo no)" "req-001: Standalone Skills lists $skill"
done
row=$(grep -i '^| .*retrofit' <<< "$STANDALONE")
assert_equals "yes" "$([ -n "$row" ] && echo yes || echo no)" "req-001: Standalone Skills lists the retrofit workflow"
for skill in ravintio-test-writer ravintio-implementer ravintio-refactor; do
  row=$(grep "^| \`$skill\`" <<< "$STANDALONE")
  assert_equals "yes" "$([ -n "$row" ] && echo yes || echo no)" "req-001: Standalone Skills keeps the $skill sub-agent row"
done

echo ""
echo "=== req-001: orchestrator holds no track text ==="

lacks "Three-Track Decision Tree" "$(cat "$ORCH")" "req-001: orchestrator holds no Three-Track Decision Tree"
lacks "Fast Path Criteria" "$(cat "$ORCH")" "req-001: orchestrator holds no Fast Path Criteria section"
lacks '| `PC:`' "$PREFIXES" "req-001: phase prefix table holds no PC: row"
lacks "Invoking the Change Pipeline" "$(cat "$ORCH")" "req-001: orchestrator holds no Invoking the Change Pipeline section"
has "Feature Pipeline (ship-agent P7)" "$HL10" "req-001: Hard Limit 10 names the Feature Pipeline archive"
lacks "Change Pipeline" "$HL10" "req-001: Hard Limit 10 drops the Change Pipeline clause"
no_track_words "$ORCH" "req-001: orchestrator SKILL.md"

echo ""
echo "=== req-001: files that restate the route ==="

no_track_words "$PHASE0" "req-001: phase-0-assess-and-coach.md"
no_track_words "$ADOPT" "req-001: adoption-modes.md"
no_track_words "$FW/templates/standard-boot.md" "req-001: standard-boot.md"
no_track_words "$SHIP" "req-001: ship-agent SKILL.md"
no_track_words "$FW/skills/ravintio-adr-agent/SKILL.md" "req-001: adr-agent SKILL.md"
no_track_words "$FW/skills/ravintio-optimise-agent/SKILL.md" "req-001: optimise-agent SKILL.md"
no_track_words "$FW/templates/component-guide.md" "req-001: component-guide.md"
no_track_words "$FW/templates/domain-glossary-guide.md" "req-001: domain-glossary-guide.md"

echo ""
echo "=== req-001: version bump table ==="

BUMP=$(sed -n '/^   | Pipeline Track | Default Bump/,/^$/p' "$PHASE0" | grep '^   | ' | grep -v -E '^   \| (Pipeline Track|-)')
assert_equals "2" "$(printf '%s\n' "$BUMP" | grep -c '^   | ')" "req-001: version bump table holds two rows"
has "| Feature Pipeline | Minor (x.Y.0) |" "$BUMP" "req-001: version bump table keeps the Feature Pipeline row"
has "| Breaking change | Major (X.0.0) |" "$BUMP" "req-001: version bump table keeps the Breaking change row"
has "suggest a minor bump for a Feature Pipeline run" "$(cat "$ADOPT")" \
  "req-001: adoption-modes.md suggests a minor bump for a Feature Pipeline run"

echo ""
echo "=== req-001: ship Hard Limit 6 and Step 11 ==="

HL6=$(sed -n '/^## Hard Limits/,/^## Run mode/p' "$SHIP" | grep -E '^6\. ')
STEP11=$(sed -n '/^### Step 11: Confirm to human/,/^### Step 12/p' "$SHIP")
has "Feature Pipeline" "$HL6" "req-001: ship Hard Limit 6 names the Feature Pipeline"
has "A code change always needs a Feature Pipeline run." "$HL6" \
  "req-001: ship Hard Limit 6 says a code change needs a Feature Pipeline run"
has "never says a code change needs no P0" "$HL6" "req-001: ship Hard Limit 6 keeps the no-P0 ban"
has "pushes to \`main\`" "$HL6" "req-001: ship Hard Limit 6 keeps the main runbook ban"
has "names the Feature Pipeline, or the standalone skill it needs" "$STEP11" \
  "req-001: ship Step 11 names the Feature Pipeline or a standalone skill"

echo ""
echo "=== req-001: routing docs (req-007 writes these) ==="

no_track_words "$FW/getting-started.md" "req-001: getting-started.md"
no_track_words "$ROOT/src/setup-hook-integration/docs/scope.md" "req-001: setup-hook-integration scope.md"
PREFIX_ROWS=$(grep -E '^\| `PC:`' "$PIPEREF" || true)
assert_equals "" "$PREFIX_ROWS" "req-001: pipeline-reference.md holds no PC: row"
FP_HEADS=$(grep -E '^#+ .*Fast Path' "$PIPEREF" || true)
assert_equals "" "$FP_HEADS" "req-001: pipeline-reference.md holds no Fast Path section"
CP_HEADS=$(grep -E '^## Change Pipeline' "$PIPEREF" || true)
assert_equals "" "$CP_HEADS" "req-001: pipeline-reference.md holds no Change Pipeline section"

print_summary
