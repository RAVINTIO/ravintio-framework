#!/usr/bin/env bash
# Verified by: unit
#
# Tests for feature 0000041-pack-source-under-src, req-001: move-pack-to-src.
#
# Covers AC2 and AC3. AC1 (the git pass) is verified by execution at P3 and
# has no durable suite, because a squash merge drops the pass commit.
#
# AC2: product.yml, product-version.mjs, .gitattributes, em-dash-guard.mjs.
# AC3: the setup-hook-integration manifest, the component registry link,
#      refresh-ravintio-framework-dir.ps1, the README structure block, and
#      self-description-check.mjs.
#
# The suite reads the repo through the req-008 resolver in helpers/pack-root.sh.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
source "$SCRIPT_DIR/helpers/pack-root.sh"

TOP="$RAVINTIO_REPO_ROOT"
PACK="$RAVINTIO_PACK_DIR"
REL="$RAVINTIO_PACK_REL"

WORK="$(mktemp -d -t ravintio_0000041_req001_XXXXXX)" || { echo "  FAIL: req-001: mktemp -d failed"; exit 1; }
trap 'rm -rf "$WORK"' EXIT

# file_has <file> <fixed string>: prints yes or no.
file_has() {
  if [ -f "$1" ] && grep -qF -- "$2" "$1"; then echo "yes"; else echo "no"; fi
}

# -----------------------------------------------------------------------
# AC2: product.yml and product-version.mjs
# -----------------------------------------------------------------------
echo "AC2: product.yml, version script, .gitattributes, em-dash guard"

PRODUCT_YML="$TOP/product.yml"
assert_equals "yes" "$(file_has "$PRODUCT_YML" 'path: "src/ravintio-framework/component.yml"')" \
  "req-001: product.yml lists ravintio-framework at src/ravintio-framework/component.yml"

assert_equals "yes" "$([ -f "$TOP/src/ravintio-framework/component.yml" ] && echo yes || echo no)" \
  "req-001: src/ravintio-framework/component.yml exists"

# The higher of the two component versions, read straight from the manifests.
EXPECTED_VERSION="$(node -e '
  const fs = require("fs");
  const read = (p) => (fs.readFileSync(p, "utf8").match(/^version:\s*"([^"]+)"/m) || [])[1];
  const a = read(process.argv[1]).split(".").map(Number);
  const b = read(process.argv[2]).split(".").map(Number);
  let hi = a;
  for (let i = 0; i < 3; i++) { if (b[i] !== a[i]) { hi = b[i] > a[i] ? b : a; break; } }
  process.stdout.write(hi.join("."));
' "$TOP/src/ravintio-framework/component.yml" "$TOP/src/setup-hook-integration/component.yml" 2>/dev/null)"

PV_OUT="$(cd "$TOP" && node src/ravintio-framework/scripts/product-version.mjs 2>/dev/null)"
PV_RC=$?
assert_exit_zero "$PV_RC" "req-001: product-version.mjs run from src exits 0 at the repo root"
assert_equals "$EXPECTED_VERSION" "$PV_OUT" \
  "req-001: product-version.mjs prints the higher of the two component versions"

# -----------------------------------------------------------------------
# AC2: .gitattributes
# -----------------------------------------------------------------------
GA="$TOP/.gitattributes"
ga_line() { # <path>: yes when the file holds "<path>  text eol=lf" with any spacing
  if [ -f "$GA" ] && grep -Eq "^$1[[:space:]]+text[[:space:]]+eol=lf[[:space:]]*$" "$GA"; then echo yes; else echo no; fi
}
assert_equals "yes" "$(ga_line 'src/ravintio-framework/hooks/pre-commit')" \
  "req-001: .gitattributes holds the src pre-commit text eol=lf line"
assert_equals "yes" "$(ga_line 'src/ravintio-framework/hooks/pre-push')" \
  "req-001: .gitattributes holds the src pre-push text eol=lf line"
assert_equals "yes" "$(ga_line 'ravintio-framework/hooks/pre-commit')" \
  "req-001: .gitattributes keeps the root pre-commit text eol=lf line"
assert_equals "yes" "$(ga_line 'ravintio-framework/hooks/pre-push')" \
  "req-001: .gitattributes keeps the root pre-push text eol=lf line"

# -----------------------------------------------------------------------
# AC2: em-dash-guard.mjs from the src pack
# -----------------------------------------------------------------------
GUARD="$PACK/hooks/enforcement/em-dash-guard.mjs"
EM="$(printf '\xe2\x80\x94')"

# guard_write <relative target>: run the guard for a Write with cwd set to a
# scratch project. Prints the exit code.
guard_write() {
  local target="$1" payload
  payload="$(node -e '
    const [fp, content] = process.argv.slice(1);
    process.stdout.write(JSON.stringify({tool_name:"Write",tool_input:{file_path:fp,content}}));
  ' "$target" "before ${EM} after")"
  (cd "$WORK" && printf '%s' "$payload" | node "$GUARD" >/dev/null 2>&1)
  echo $?
}

mkdir -p "$WORK/src/ravintio-framework/skills" "$WORK/ravintio-framework/skills"

assert_equals "2" "$(guard_write 'src/ravintio-framework/skills/x.md')" \
  "req-001: em-dash-guard blocks a U+2014 write to src/ravintio-framework/skills/"
assert_equals "2" "$(guard_write 'ravintio-framework/skills/x.md')" \
  "req-001: em-dash-guard still blocks a U+2014 write to ravintio-framework/skills/"

# -----------------------------------------------------------------------
# AC3: setup-hook-integration manifest
# -----------------------------------------------------------------------
echo "AC3: manifest, registry, refresh script, README, self-description check"

MANIFEST="$TOP/src/setup-hook-integration/component.yml"

assert_equals "yes" "$(file_has "$MANIFEST" 'src/ravintio-framework/setup.sh and setup.ps1 hook installation and settings.json merge')" \
  "req-001: manifest inScope names src/ravintio-framework/setup.sh and setup.ps1"
assert_equals "yes" "$(file_has "$MANIFEST" 'src/ravintio-framework/setup/claude-code.sh and setup/claude-code.ps1 hook path declarations')" \
  "req-001: manifest inScope names src/ravintio-framework/setup/claude-code.sh and .ps1"

SYSCTX="$(grep -E '^systemContext:' "$MANIFEST" 2>/dev/null || true)"
assert_contains "src/ravintio-framework/" "$SYSCTX" \
  "req-001: manifest systemContext names src/ravintio-framework/ as the code location"
assert_contains "release copy" "$SYSCTX" \
  "req-001: manifest systemContext names the ravintio-framework/ release copy that consumers run"
assert_contains "Installs hooks to .claude/hooks/" "$SYSCTX" \
  "req-001: manifest systemContext keeps the runtime hook path"
assert_equals "yes" "$(file_has "$MANIFEST" 'name: ".claude/hooks/enforcement/"')" \
  "req-001: manifest outputs keep the .claude/hooks/enforcement/ runtime path"

# -----------------------------------------------------------------------
# AC3: component registry link
# -----------------------------------------------------------------------
REGISTRY="$TOP/docs/component-registry.md"
assert_equals "yes" "$(file_has "$REGISTRY" '[component.yml](../src/ravintio-framework/component.yml)')" \
  "req-001: component-registry.md links the src/ravintio-framework/component.yml manifest"
assert_equals "no" "$(file_has "$REGISTRY" '[component.yml](../ravintio-framework/component.yml)')" \
  "req-001: component-registry.md no longer links the root manifest"

# -----------------------------------------------------------------------
# AC3: refresh-ravintio-framework-dir.ps1
# -----------------------------------------------------------------------
REFRESH="$TOP/refresh-ravintio-framework-dir.ps1"
assert_equals "yes" "$(file_has "$REFRESH" '$repoDir = $PSScriptRoot')" \
  "req-001: refresh-ravintio-framework-dir.ps1 sets repoDir from PSScriptRoot"
assert_equals "no" "$(file_has "$REFRESH" 'C:\d\planifest')" \
  "req-001: refresh-ravintio-framework-dir.ps1 drops the hard-coded C:\\d\\planifest path"
assert_equals "yes" "$(file_has "$REFRESH" '.\ravintio-framework\setup.ps1 claude-code --include-full-skill-library')" \
  "req-001: refresh-ravintio-framework-dir.ps1 still runs the root setup.ps1"
assert_equals "no" "$(file_has "$REFRESH" 'not required as this IS the framework')" \
  "req-001: refresh-ravintio-framework-dir.ps1 drops the stale 'this IS the framework' comment"

# -----------------------------------------------------------------------
# AC3: README structure block
# -----------------------------------------------------------------------
README="$TOP/README.md"
STRUCT="$(awk '/^## Repository structure/{f=1;next} f&&/^## /{exit} f' "$README" 2>/dev/null)"
assert_contains "src/ravintio-framework/" "$STRUCT" \
  "req-001: README structure block names src/ravintio-framework/"
assert_contains "Pack source (this repo only)" "$STRUCT" \
  "req-001: README structure block labels the src pack as the source"
assert_contains "release copy" "$STRUCT" \
  "req-001: README structure block calls the root ravintio-framework/ the release copy"

# -----------------------------------------------------------------------
# AC3: self-description-check.mjs
# -----------------------------------------------------------------------
SDC_OUT="$(cd "$TOP" && node "$REL/scripts/self-description-check.mjs" . 2>&1)"
SDC_RC=$?
assert_exit_zero "$SDC_RC" "req-001: self-description-check.mjs . exits 0 with the README naming src/ravintio-framework/"
if [ "$SDC_RC" -ne 0 ]; then echo "        output: $SDC_OUT"; fi

print_summary
