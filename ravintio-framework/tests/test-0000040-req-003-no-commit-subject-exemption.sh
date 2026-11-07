#!/usr/bin/env bash
# Verified by: integration
# Tests for feature 0000040-retire-fast-path.
#
# req-003: pre-push and both CI files drop the commit subject exemption and
#          apply one source folder rule read from product.yml (ADR-003).
#   AC1: no fast-path text in the three files, and a fix(fast-path): branch
#        gets the same verdict as a branch with other subjects.
#   AC2: the source folder rule verdicts, run against pre-push and the CI step
#        extracted from hooks/ravintio.yml.
#   AC3: the validate-branch job matches in both CI files, and pre-push and
#        the CI step give the same exit code on every shared fixture.
#
# Every fixture is a scratch git repo under mktemp -d with a bare origin.
# The CI step runs as GitHub runs it, with bash -e -o pipefail.

set -uo pipefail

unset CLAUDE_PROJECT_DIR

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"

source "$SCRIPT_DIR/helpers/pack-root.sh"

FRAMEWORK="$RAVINTIO_PACK_DIR"
REPO_ROOT="$RAVINTIO_REPO_ROOT"
PRE_PUSH="$FRAMEWORK/hooks/pre-push"
CONSUMER_WORKFLOW="$FRAMEWORK/hooks/ravintio.yml"
REPO_WORKFLOW="$REPO_ROOT/.github/workflows/ravintio.yml"

# Git Bash gives /tmp/x. pwd -W gives the Windows form that a file:// URL needs.
WORK="$(cd "$(mktemp -d -t ravintio_0000040_req003_XXXXXX)" && { pwd -W 2>/dev/null || pwd; })"
trap 'rm -rf "$WORK"' EXIT

GIT=(git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c init.defaultBranch=main -c core.hooksPath=/dev/null)

match() { if grep -Eq -- "$1" <<< "$2"; then echo "yes"; else echo "no"; fi; }

# file_url <path>: a file:// URL that git accepts on every platform.
file_url() {
  case "$1" in
    /*) printf 'file://%s' "$1" ;;
    *) printf 'file:///%s' "$1" ;;
  esac
}

# -----------------------------------------------------------------------
# The CI step, extracted from the YAML. The base ref becomes main.
# -----------------------------------------------------------------------

# ci_step_script <workflow>: prints the Validate Code/Doc Parity run block.
ci_step_script() {
  awk '
    /^      - name: Validate Code\/Doc Parity$/ { found = 1; next }
    found && !on && /^        run: \|$/ { on = 1; next }
    on && /^          / { print substr($0, 11); next }
    on && /^[[:space:]]*$/ { print ""; next }
    on { exit }
  ' "$1" | sed 's/\${{ github\.base_ref }}/main/g'
}

# job_block <workflow> <job id>: prints one top-level job.
job_block() {
  awk -v id="  $2:" '
    $0 == id { on = 1; print; next }
    on && /^  [^ ]/ { exit }
    on { print }
  ' "$1"
}

CI_STEP="$WORK/ci-step.sh"
ci_step_script "$CONSUMER_WORKFLOW" > "$CI_STEP"
CI_TEXT="$(cat "$CI_STEP")"

# -----------------------------------------------------------------------
# Fixture helpers
# -----------------------------------------------------------------------

# put <path> <text>: writes a file in the current fixture repo.
put() {
  mkdir -p "$(dirname "$REPO/$1")"
  printf '%s\n' "$2" > "$REPO/$1"
}

commit_all() {
  git -C "$REPO" add -A
  "${GIT[@]}" -C "$REPO" commit -q --no-verify -m "$1"
}

# new_repo <name> [<product.yml text>]: a bare origin and a clone on branch
# feature. The seed commit on main holds README.md and the optional product.yml.
new_repo() {
  local base="$WORK/$1"
  mkdir -p "$base"
  "${GIT[@]}" init -q --bare "$base/origin.git"
  "${GIT[@]}" init -q "$base/work"
  REPO="$base/work"
  put README.md "seed"
  if [ -n "${2:-}" ]; then put product.yml "$2"; fi
  commit_all "seed"
  git -C "$REPO" remote add origin "$base/origin.git"
  git -C "$REPO" push -q --no-verify origin main 2>/dev/null
  git -C "$REPO" checkout -q -b feature
}

# run_both: runs pre-push and the CI step in the current fixture repo.
run_both() {
  PP_OUT="$(cd "$REPO" && bash "$PRE_PUSH" 2>&1)"
  PP_CODE=$?
  CI_OUT="$(cd "$REPO" && bash -e -o pipefail "$CI_STEP" 2>&1)"
  CI_CODE=$?
}

# verdict <label> <expected exit> [<ERE that both outputs hold>]...
verdict() {
  local label="$1" want="$2" re
  shift 2
  run_both
  assert_equals "$want" "$PP_CODE" "req-003: pre-push exits $want, $label"
  assert_equals "$want" "$CI_CODE" "req-003: CI step exits $want, $label"
  assert_equals "$PP_CODE" "$CI_CODE" "req-003 AC3: pre-push and CI step give the same exit code, $label"
  for re in "$@"; do
    assert_equals "yes" "$(match "$re" "$PP_OUT")" "req-003: pre-push output holds '$re', $label"
    assert_equals "yes" "$(match "$re" "$CI_OUT")" "req-003: CI step output holds '$re', $label"
  done
  if [ "$want" != "$PP_CODE" ] || [ "$want" != "$CI_CODE" ]; then
    printf '    pre-push output:\n%s\n    CI step output:\n%s\n' "$PP_OUT" "$CI_OUT"
  fi
}

PRODUCT_PACK='id: "demo"
components:
  - id: "pack"
    path: "pack/component.yml"'

PRODUCT_ROOT='id: "demo"
components:
  - id: "demo"
    path: "component.yml"'

PRODUCT_BAD='id: "demo"
components:
  - id: "abs"
    path: "/abs/component.yml"
  - id: "up"
    path: "../up/component.yml"
  - id: "blank"
    path: ""'

# -----------------------------------------------------------------------
# AC3: the CI step exists and the validate-branch job matches
# -----------------------------------------------------------------------

echo ""
echo "=== req-003 AC3: validate-branch job matches in both CI files ==="

assert_equals "yes" "$(match 'git diff' "$CI_TEXT")" "req-003 AC3: the consumer template holds a Validate Code/Doc Parity run block"
CONSUMER_JOB="$(job_block "$CONSUMER_WORKFLOW" validate-branch)"
REPO_JOB="$(job_block "$REPO_WORKFLOW" validate-branch)"
assert_equals "yes" "$([ -n "$CONSUMER_JOB" ] && echo yes || echo no)" "req-003 AC3: the consumer template has a validate-branch job"
assert_equals "$CONSUMER_JOB" "$REPO_JOB" "req-003 AC3: validate-branch matches line for line in both CI files"
assert_equals "yes" "$(match 'merge-base[^|]*origin/\$\{\{ github\.base_ref \}\}' "$CONSUMER_JOB")" \
  "req-003: the CI step takes the merge base with origin/\${{ github.base_ref }}"
for job in self-description-check test-suite setup-powershell setup-powershell-51; do
  assert_equals "yes" "$([ -n "$(job_block "$REPO_WORKFLOW" "$job")" ] && echo yes || echo no)" \
    "req-003: the repo CI file keeps its $job job"
done

# -----------------------------------------------------------------------
# AC1: no commit subject exemption
# -----------------------------------------------------------------------

echo ""
echo "=== req-003 AC1: no fast-path text and no commit subject exemption ==="

for f in "$PRE_PUSH" "$CONSUMER_WORKFLOW" "$REPO_WORKFLOW"; do
  assert_equals "0" "$(grep -ciE 'fast[-_]path' "$f")" "req-003 AC1: $(basename "$(dirname "$f")")/$(basename "$f") holds no fast-path or FAST_PATH text"
done

for subject in "fix(fast-path): tweak the app" "feat: tweak the app"; do
  new_repo "ac1-manifest-$(match 'fast-path' "$subject")"
  put src/app.txt "code"
  put src/component.yml "version: 0.1.1"
  commit_all "$subject"
  verdict "src/ change with only a component.yml, subject '$subject'" 1 'src/'

  new_repo "ac1-code-$(match 'fast-path' "$subject")"
  put src/app.txt "code"
  put notes.txt "not a record"
  commit_all "$subject"
  verdict "src/ change with only a non-plan file, subject '$subject'" 1 'src/'

  new_repo "ac1-record-$(match 'fast-path' "$subject")"
  put src/app.txt "code"
  put plan/changelog/note.md "record"
  commit_all "$subject"
  verdict "src/ change with a plan/ record, subject '$subject'" 0
done

# -----------------------------------------------------------------------
# AC2: source folder rule verdicts
# -----------------------------------------------------------------------

echo ""
echo "=== req-003 AC2: a folder that product.yml lists is a source folder ==="

new_repo listed-no-record "$PRODUCT_PACK"
put pack/lib.txt "code"
commit_all "change the pack"
verdict "listed folder change with no record fails and names the folder" 1 'pack/' 'presence check'

new_repo listed-plan "$PRODUCT_PACK"
put pack/lib.txt "code"
put plan/current/note.md "record"
commit_all "change the pack with a plan record"
verdict "listed folder change with a plan/ record passes" 0

new_repo listed-docs "$PRODUCT_PACK"
put pack/lib.txt "code"
put docs/pack.md "record"
commit_all "change the pack with a docs record"
verdict "listed folder change with a docs/ record passes" 0

new_repo listed-manifest "$PRODUCT_PACK"
put pack/lib.txt "code"
put pack/component.yml "version: 0.2.0"
commit_all "change the pack and its manifest"
verdict "listed folder change with only its component.yml fails" 1 'pack/'

echo ""
echo "=== req-003 AC2: an unlisted component.yml makes no source folder ==="

new_repo unlisted "$PRODUCT_PACK"
put other/component.yml "version: 0.1.0"
commit_all "add an unlisted manifest"
git -C "$REPO" push -q --no-verify origin feature:main 2>/dev/null
put other/lib.txt "code"
commit_all "change the unlisted folder"
verdict "unlisted folder change with no record passes" 0

echo ""
echo "=== req-003 AC2: a branch that drops a component still has it checked ==="

new_repo dropped "$PRODUCT_PACK"
put product.yml 'id: "demo"
components: []'
put pack/lib.txt "code"
commit_all "drop the pack from product.yml and change it"
verdict "dropped component change with no record fails" 1 'pack/'

echo ""
echo "=== req-003 AC2: with no product.yml, only src/ counts ==="

new_repo no-product-lib
put lib/component.yml "version: 0.1.0"
put lib/lib.txt "code"
commit_all "change lib with no product.yml"
verdict "no product.yml, a change outside src/ passes" 0

new_repo no-product-src
put src/app.txt "code"
commit_all "change src with no product.yml"
verdict "no product.yml, a src/ change with no record fails" 1 'src/'

echo ""
echo "=== req-003 AC2: absolute, .. and empty path values are ignored with a warning ==="

new_repo bad-paths "$PRODUCT_BAD"
put abs/lib.txt "code"
commit_all "change a folder with an absolute path value"
verdict "ignored path values make no source folder" 0 '/abs/component\.yml' '\.\./up/component\.yml' 'empty'

new_repo bad-paths-src "$PRODUCT_BAD"
put src/app.txt "code"
commit_all "change src with bad path values"
verdict "ignored path values still leave src/ checked" 1 'src/'

echo ""
echo "=== req-003 AC2: a root-level component.yml makes the whole repo source ==="

new_repo root-code "$PRODUCT_ROOT"
put lib/lib.txt "code"
commit_all "change code at the root component"
verdict "root component, a code change with no record fails" 1 'whole repository'

new_repo root-code-record "$PRODUCT_ROOT"
put lib/lib.txt "code"
put plan/current/note.md "record"
commit_all "change code at the root component with a record"
verdict "root component, a code change with a record passes" 0

new_repo root-plan "$PRODUCT_ROOT"
put plan/current/note.md "record"
commit_all "change plan only"
verdict "root component, a plan/ change alone passes" 0

new_repo root-docs "$PRODUCT_ROOT"
put docs/guide.md "record"
commit_all "change docs only"
verdict "root component, a docs/ change alone passes" 0

echo ""
echo "=== req-003 AC2: pre-push with no origin/main ref warns and checks nothing ==="

REPO="$WORK/no-origin"
"${GIT[@]}" init -q "$REPO"
put src/app.txt "code"
commit_all "first commit, no remote"
NO_ORIGIN_OUT="$(cd "$REPO" && bash "$PRE_PUSH" 2>&1)"
NO_ORIGIN_CODE=$?
assert_equals "0" "$NO_ORIGIN_CODE" "req-003: pre-push exits 0 in a repo with no origin/main ref"
assert_equals "yes" "$(match 'origin/main' "$NO_ORIGIN_OUT")" "req-003: pre-push warning names the missing origin/main ref"
assert_equals "yes" "$(match 'WARNING' "$NO_ORIGIN_OUT")" "req-003: pre-push prints a warning when origin/main is missing"

echo ""
echo "=== req-003 AC2: a shallow clone with no merge base fails closed ==="

new_repo shallow-src
put src/app.txt "code"
put plan/current/note.md "record"
commit_all "feature change with a record"
git -C "$REPO" push -q --no-verify origin feature 2>/dev/null
git -C "$REPO" checkout -q main
put main.txt "main moves on"
commit_all "main moves on"
git -C "$REPO" push -q --no-verify origin main 2>/dev/null
SHALLOW="$WORK/shallow-clone"
git clone -q --depth 1 --no-single-branch --branch feature "$(file_url "$WORK/shallow-src/origin.git")" "$SHALLOW" 2>/dev/null
REPO="$SHALLOW"
assert_equals "true" "$(git -C "$REPO" rev-parse --is-shallow-repository)" "req-003: the fixture clone is shallow"
verdict "shallow clone where origin/main has no readable merge base" 1 'fetch-depth: 0'

print_summary
