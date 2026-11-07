#!/usr/bin/env bash
# Tests for feature 0000017 req-007: ship-agent cross-reference check and the
# 10th orchestrator Hard Limit (backlog 0000011).
#
# 0000040 req-004 retired the change agent, so its archive checks went with
# it. The file keeps its name, because regression-manifest.json and the
# 0000039 req-005 suite list it (backlog 0000365).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
SHIP_AGENT="$FRAMEWORK/skills/ravintio-ship-agent/SKILL.md"
ORCHESTRATOR="$FRAMEWORK/skills/ravintio-orchestrator/SKILL.md"

# ── AC-3: ship-agent P7 Step 6 has the cross-reference check ─────────────────

echo ""
echo "=== req-007: ship-agent cross-reference check ==="

SA_STEP6=$(sed -n '/### Step 6: Archive/,/### Step 6b/p' "$SHIP_AGENT")
assert_contains "Cross-reference check" "$SA_STEP6" \
  "req-007: ship-agent Step 6 has cross-reference check"
assert_contains "decisions-index.md" "$SA_STEP6" \
  "req-007: ship-agent check names decisions-index.md ADR links"

# ── AC-4: 10th orchestrator Hard Limit mandating archiving on every route ────

echo ""
echo "=== req-007: 10th Hard Limit ==="

HL=$(sed -n '/^## Hard Limits/,/^---/p' "$ORCHESTRATOR")
assert_contains "10." "$HL" \
  "req-007: Hard Limits list has a 10th entry"
assert_contains "Every pipeline route archives its working folder" "$HL" \
  "req-007: 10th Hard Limit mandates archiving for every route"

print_summary
