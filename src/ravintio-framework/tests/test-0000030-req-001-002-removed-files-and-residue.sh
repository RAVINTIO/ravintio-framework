#!/usr/bin/env bash
# Tests for feature 0000030, req-001 and req-002: the Context Mode and
# Telemetry files are gone, nothing imports them, product.yml lists two
# components, CI has no telemetry job, and NFR-001 finds no residual
# reference outside the allowlist in plan/current/execution-plan.md.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
source "$SCRIPT_DIR/helpers/pack-root.sh"
ROOT="$RAVINTIO_REPO_ROOT"
PACK="$RAVINTIO_PACK_REL"
cd "$ROOT" || exit 1

# In the source repo, tree-wide scans skip the frozen release copy at ravintio-framework/.
if [ "$RAVINTIO_SOURCE_REPO" = "yes" ]; then
  SKIP_COPY=':!ravintio-framework'
else
  SKIP_COPY=':!.ravintio-no-such-path'
fi

echo "=== req-001 / req-002: removed paths do not exist ==="
for rel in "$PACK/hooks/context-mode" src/context-mode-hooks docs/context-mode.md \
  "$PACK/hooks/telemetry" \
  "$PACK/hooks/enforcement/check-telemetry-failures.mjs" \
  "$PACK/hooks/enforcement/check-telemetry-receipts.mjs" \
  "$PACK/hooks/enforcement/phase-enum.mjs" \
  "$PACK/scripts/verify-telemetry-hooks.mjs" \
  "$PACK/tests/helpers/controllable-backend.mjs"; do
  if [ -e "$rel" ]; then state=present; else state=absent; fi
  assert_equals "absent" "$state" "req-001/002: $rel is removed"
done

echo "=== req-002: no code imports a removed module ==="
importers=$(git grep -lE "from ['\"][^'\"]*(hooks/telemetry/|hooks/context-mode/|phase-enum\.mjs|check-telemetry-(failures|receipts)\.mjs|controllable-backend\.mjs)" \
  -- '*.mjs' '*.js' '*.ts' "$SKIP_COPY" | wc -l | tr -d ' ')
assert_equals "0" "$importers" "req-002: no .mjs, .js, or .ts file imports a removed module"

echo "=== req-001: product.yml lists two components ==="
count=$(grep -cE '^  - id: ' product.yml)
assert_equals "2" "$count" "req-001: product.yml components[] has two items"
assert_equals "0" "$(grep -c 'context-mode-hooks' product.yml)" "req-001: product.yml never names context-mode-hooks"
version=$(node "$PACK/scripts/product-version.mjs" 2>/dev/null)
# Compare with the framework component's own version rather than a fixed
# value, so a later version bump doesn't break this check (0000031 P4).
framework_version=$(sed -n 's/^version: "\(.*\)"$/\1/p' "$PACK/component.yml")
assert_equals "$framework_version" "$version" "req-001: product-version.mjs derives the framework component version"

echo "=== req-002: CI has no telemetry job ==="
assert_equals "0" "$(grep -ci 'telemetry' .github/workflows/ravintio.yml)" "req-002: .github/workflows/ravintio.yml has no telemetry job or step"

echo "=== NFR-001: no residual reference outside the allowlist ==="
PATTERN='context-mode|context_mode|context mode|structured-telemetry|telemetry|emit_event|backend-url'
residue=""
while IFS= read -r f; do
  case "$f" in
    docs/decisions-index.md|"$PACK"/standards/reference/backend-stack-evaluation.md) continue ;;
    "$PACK"/migrations/migrate-remove-context-mode-and-telemetry.md) continue ;;
    "$PACK"/tests/test-0000030-*) continue ;;
    # The 0.37.0 rename migration and its helpers name the retired telemetry variable to keep it unrenamed.
    "$PACK"/migrations/migrate-0.37.0-ravintio-rename.*) continue ;;
    # Feature 0000039 suites name the retired telemetry variable on purpose, to prove the rename keeps it.
    "$PACK"/tests/test-0000039-*) continue ;;
    "$PACK"/tests/regression/test-0000039-*) continue ;;
  esac
  hits=$(awk '/BEGIN retired-integrations/{f=1} /END retired-integrations/{f=0;next} !f' "$f" \
    | grep -inE "$PATTERN" \
    | grep -vE '[0-9]{7}-[a-z0-9-]*(context-mode|telemetry)' || true)
  case "$f" in
    "$PACK"/tests/*)
      # Comments and absence assertions in older tests are allowlisted.
      hits=$(printf '%s\n' "$hits" | grep -vE '^[0-9]+:[[:space:]]*#|assert_equals "0"|grep_count|context-mode free|occurrences in|^$' || true) ;;
  esac
  [ -n "$hits" ] && residue="$residue $f"
done < <(git grep -ilE "$PATTERN" -- . ':!plan' ":!$PACK/external-skills" "$SKIP_COPY")
assert_equals "" "$(echo $residue)" "NFR-001: no residual reference outside the allowlist"

print_summary
