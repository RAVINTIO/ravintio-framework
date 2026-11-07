#!/usr/bin/env bash
# Verified by: integration
#
# Tests for feature 0000041-pack-source-under-src, req-003: step 1a, the update
# policy and the migrator read ravintio-framework/release.yml first, and the
# read-only script scripts/release-check.mjs detects a release update and each
# changed pack file (ADR-004).
#
# Sections:
#   AC1  release-check.mjs in scratch consumer repos: exit codes, update:,
#        changed:, missing:, unlisted:, record:, warn: lines, --files-only,
#        link refusal, the first-upgrade rule, the recorded file, the
#        component.yml fallback and the malformed release.yml refusal.
#   AC2  the own-build rule in a scratch source repo.
#   AC3  the text checks: orchestrator step 1a and 1b, the update policy and
#        the migrator.
#
# Expected state before release-check.mjs exists: every AC1 and AC2 case is RED
# because the script is missing, and the AC3 orchestrator and policy cases are
# RED because the texts do not yet name the script.
#
# STEP 6 WAIT: the migrator cases in AC3 (the section marked "STEP 6" below)
# stay RED until build order step 6 edits ravintio-migrator/SKILL.md. Step 5
# does not touch that file, so a RED result there is expected until then.
#
# Each root copy comes from build-release.mjs in a scratch source repo that
# holds a copy of this pack's tracked files. The scratch consumer repos copy
# that built tree. The pack is read through pack-root.sh. The script under test
# is the one in this pack. It never runs against this repo.
#
# Link cases skip under Git Bash on Windows.
#
# Every loop reads lines with `done <<< "$(...)"`, never `done < <(...)`.

set -uo pipefail

unset CLAUDE_PROJECT_DIR GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
source "$SCRIPT_DIR/helpers/pack-root.sh"

BUILD="$RAVINTIO_PACK_DIR/scripts/build-release.mjs"
CHECK="$RAVINTIO_PACK_DIR/scripts/release-check.mjs"
ORCH="$RAVINTIO_PACK_DIR/skills/ravintio-orchestrator/SKILL.md"
POLICY="$RAVINTIO_PACK_DIR/standards/framework-update-policy.md"
MIGRATOR="$RAVINTIO_PACK_DIR/skills/ravintio-migrator/SKILL.md"
PACK_IN_SRC="src/ravintio-framework"
COPY_DIR="ravintio-framework"
POLICY_FILE_REL="standards/framework-update-policy.md"

# Git Bash gives /tmp/x, which node reads as C:\tmp\x. pwd -W gives the Windows form.
WORK="$(cd "$(mktemp -d -t ravintio_0000041_req003_XXXXXX)" && { pwd -W 2>/dev/null || pwd; })"
trap 'chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"' EXIT

IS_WIN=no
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) IS_WIN=yes ;; esac

# sg <repo> <git args...>: git in a scratch repo with a fixed identity.
sg() {
  local d="$1"; shift
  git -C "$d" -c user.name=tester -c user.email=tester@example.invalid \
    -c commit.gpgsign=false -c core.autocrlf=false "$@"
}

# run_check <dir> [args...]: run the script with --root <dir>. Sets OUT, ERR, CODE.
# A missing script gives code 127, so a RED run never reads as a real exit 1.
run_check() {
  local d="$1"; shift
  if [ ! -f "$CHECK" ]; then OUT=""; ERR="release-check.mjs missing"; CODE=127; return; fi
  OUT="$(cd "$d" && env -u CLAUDE_PROJECT_DIR node "$CHECK" --root "$d" "$@" 2>"$WORK/stderr.txt")"
  CODE=$?
  ERR="$(cat "$WORK/stderr.txt")"
}

# run_check_cwd <dir> [args...]: run the script with no --root, from <dir>.
run_check_cwd() {
  local d="$1"; shift
  if [ ! -f "$CHECK" ]; then OUT=""; ERR="release-check.mjs missing"; CODE=127; return; fi
  OUT="$(cd "$d" && env -u CLAUDE_PROJECT_DIR node "$CHECK" "$@" 2>"$WORK/stderr.txt")"
  CODE=$?
  ERR="$(cat "$WORK/stderr.txt")"
}

# count_prefix <prefix>: lines of $OUT that start with the prefix.
count_prefix() {
  local n
  n="$(grep -c -- "^$1" <<< "$OUT" 2>/dev/null || true)"
  echo "${n:-0}"
}

# has_line <exact line>: yes when $OUT holds that exact line.
has_line() {
  if grep -qxF -- "$1" <<< "$OUT" 2>/dev/null; then echo yes; else echo no; fi
}

# has_text <needle> <text>: yes when the text holds the needle, ignoring case.
has_text() {
  if grep -qiF -- "$1" <<< "$2" 2>/dev/null; then echo yes; else echo no; fi
}

# section <file> <start regex> <stop regex>: lines from the first start match up
# to, not including, the next line that matches the stop regex.
section() {
  awk -v s="$2" -v e="$3" '
    started && $0 ~ e { exit }
    started { print; next }
    $0 ~ s { started = 1; print }
  ' "$1" 2>/dev/null
}

# write_record <dir> <version> <commit>: the recorded value, as step 1a writes it.
write_record() {
  mkdir -p "$1/plan"
  printf 'version: "%s"\nsource-commit: "%s"\n' "$2" "$3" > "$1/plan/framework-release.yml"
}

# ---------------------------------------------------------------------------
# Scratch source repo: a copy of this pack, product.yml, then a built root copy.
# ---------------------------------------------------------------------------

BASE="$WORK/base"
mkdir -p "$BASE"
git -C "$RAVINTIO_REPO_ROOT" ls-files -z -- "$RAVINTIO_PACK_REL" \
  | tar -C "$RAVINTIO_REPO_ROOT" -cf - --null -T - 2>/dev/null \
  | tar -C "$BASE" -xf - 2>/dev/null

printf 'id: "ravintio-framework"\nname: "RAVINTIO Framework"\nversion: "0.38.0"\nversionPolicy: "max-component-version"\n\ncomponents:\n  - id: "ravintio-framework"\n    path: "src/ravintio-framework/component.yml"\n' > "$BASE/product.yml"
printf '.DS_Store\n.ravintio-framework-build/\n.ravintio-framework-previous/\n' > "$BASE/.gitignore"
sg "$BASE" init -q . >/dev/null 2>&1
sg "$BASE" add -A >/dev/null 2>&1
sg "$BASE" commit -q -m "src" >/dev/null 2>&1

BUILD_OUT="$(cd "$BASE" && env -u CLAUDE_PROJECT_DIR node "$BUILD" 2>&1)"
BUILD_CODE=$?
assert_equals "0" "$BUILD_CODE" "req-003 setup: build-release.mjs builds the scratch root copy"

REL_FILE="$BASE/$COPY_DIR/release.yml"
REL_VERSION="$(sed -n 's/^version: "\(.*\)"$/\1/p' "$REL_FILE" 2>/dev/null | head -1)"
REL_SHA="$(sed -n 's/^source-commit: "\(.*\)"$/\1/p' "$REL_FILE" 2>/dev/null | head -1)"
REC_LINE="record: version \"$REL_VERSION\" source-commit \"$REL_SHA\""
OTHER_SHA="0123456789abcdef0123456789abcdef01234567"

# Pick a listed file with LF bytes only, for the CRLF and edit cases.
LF_FILE="$POLICY_FILE_REL"
# Pick a second listed file to delete.
DEL_FILE="templates/standard-boot.md"

# consumer <name>: a consumer repo holding a copy of the built root copy.
consumer() {
  local d="$WORK/$1"
  mkdir -p "$d"
  cp -Rp "$BASE/$COPY_DIR" "$d/$COPY_DIR"
  echo "$d"
}

# owndir <name>: a copy of the whole scratch source repo.
owndir() {
  cp -Rp "$BASE" "$WORK/$1"
  echo "$WORK/$1"
}

# ===========================================================================
echo "=== req-003 AC1: release-check.mjs in scratch consumer repos ==="
# ===========================================================================

assert_equals "yes" "$([ -f "$CHECK" ] && echo yes || echo no)" "req-003 AC1: scripts/release-check.mjs exists"

# --- A recorded value with a new source-commit at the same version ----------
C="$(consumer c-newcommit)"
write_record "$C" "$REL_VERSION" "$OTHER_SHA"
run_check "$C"
assert_equals "1" "$CODE" "req-003 AC1: a new source-commit at the same version exits 1"
assert_equals "yes" "$(has_line 'update: release')" "req-003 AC1: a new source-commit prints update: release"
assert_equals "yes" "$(has_line "$REC_LINE")" "req-003 AC1: a new source-commit prints the exact record: line"
assert_equals "yes" "$(has_line "release: version \"$REL_VERSION\" source-commit \"$REL_SHA\"")" "req-003 AC1: the release: line names the version and source commit"
assert_equals "yes" "$(has_line "recorded: version \"$REL_VERSION\" source-commit \"$OTHER_SHA\"")" "req-003 AC1: the recorded: line names the recorded version and source commit"
assert_equals "0" "$(( $(count_prefix 'changed: ') + $(count_prefix 'missing: ') + $(count_prefix 'unlisted: ') ))" "req-003 AC1: a new source-commit alone prints no file line"

# --- A recorded value that matches -----------------------------------------
C="$(consumer c-match)"
write_record "$C" "$REL_VERSION" "$REL_SHA"
run_check "$C"
assert_equals "0" "$CODE" "req-003 AC1: a matching recorded value and matching files exit 0"
assert_equals "yes" "$(has_line 'update: none')" "req-003 AC1: a matching recorded value prints update: none"
assert_equals "0" "$(count_prefix 'record:')" "req-003 AC1: a matching recorded value prints no record: line"

# --- The first-upgrade rule against docs/about.md ---------------------------
C="$(consumer c-first-differs)"
mkdir -p "$C/docs"
printf -- '---\nversion: "0.0.1"\nfeature: "x"\n---\n# About\n' > "$C/docs/about.md"
run_check "$C"
assert_equals "1" "$CODE" "req-003 AC1: a first upgrade with a different docs/about.md version exits 1"
assert_equals "yes" "$(has_line 'update: release')" "req-003 AC1: a first upgrade with a different version prints update: release"
assert_equals "yes" "$(has_line 'recorded: none, fallback docs/about.md version "0.0.1"')" "req-003 AC1: a first upgrade prints the docs/about.md fallback in the recorded: line"

C="$(consumer c-first-equal)"
mkdir -p "$C/docs"
printf -- '---\nversion: "%s"\nfeature: "x"\n---\n# About\n' "$REL_VERSION" > "$C/docs/about.md"
run_check "$C"
assert_equals "0" "$CODE" "req-003 AC1: a first upgrade with an equal version and matching files exits 0"
assert_equals "yes" "$(has_line "$REC_LINE")" "req-003 AC1: a first upgrade with an equal version prints a record: line"
assert_equals "yes" "$(has_line 'update: none')" "req-003 AC1: a first upgrade with an equal version prints update: none"

C="$(consumer c-first-noabout)"
run_check "$C"
assert_equals "1" "$CODE" "req-003 AC1: a first upgrade with no docs/about.md counts any release as an update"
assert_equals "yes" "$(has_line 'update: release')" "req-003 AC1: no recorded value and no docs/about.md prints update: release"
assert_equals "yes" "$(has_line 'recorded: none')" "req-003 AC1: no recorded value and no docs/about.md prints recorded: none"

# --- changed, missing and unlisted files at an unchanged version ------------
C="$(consumer c-files)"
write_record "$C" "$REL_VERSION" "$REL_SHA"
printf 'an edit\n' >> "$C/$COPY_DIR/$LF_FILE"
rm -f "$C/$COPY_DIR/$DEL_FILE"
printf 'extra\n' > "$C/$COPY_DIR/zz-unlisted-probe.txt"
run_check "$C"
assert_equals "1" "$CODE" "req-003 AC1: an edited, a deleted and an added file exit 1"
assert_equals "1" "$(count_prefix 'changed: ')" "req-003 AC1: one edited file prints one changed: line"
assert_equals "1" "$(count_prefix 'missing: ')" "req-003 AC1: one deleted file prints one missing: line"
assert_equals "1" "$(count_prefix 'unlisted: ')" "req-003 AC1: one added file prints one unlisted: line"
assert_equals "yes" "$(has_line "changed: $COPY_DIR/$LF_FILE")" "req-003 AC1: the changed: line names the edited file with its ravintio-framework/ path"
assert_equals "yes" "$(has_line "missing: $COPY_DIR/$DEL_FILE")" "req-003 AC1: the missing: line names the deleted file"
assert_equals "yes" "$(has_line "unlisted: $COPY_DIR/zz-unlisted-probe.txt")" "req-003 AC1: the unlisted: line names the added file"
assert_equals "yes" "$(has_line 'update: none')" "req-003 AC1: file lines at an unchanged version still print update: none"

# --- CRLF copy, .DS_Store and component.yml print no file line --------------
C="$(consumer c-skip)"
write_record "$C" "$REL_VERSION" "$REL_SHA"
awk '{ printf "%s\r\n", $0 }' "$BASE/$COPY_DIR/$LF_FILE" > "$C/$COPY_DIR/$LF_FILE"
printf 'junk\n' > "$C/$COPY_DIR/.DS_Store"
printf 'id: "ravintio-framework"\nversion: "%s"\n' "$REL_VERSION" > "$C/$COPY_DIR/component.yml"
run_check "$C"
assert_equals "0" "$CODE" "req-003 AC1: a CRLF copy, a .DS_Store and a component.yml exit 0"
assert_equals "0" "$(( $(count_prefix 'changed: ') + $(count_prefix 'missing: ') + $(count_prefix 'unlisted: ') ))" "req-003 AC1: a CRLF copy, a .DS_Store and a component.yml print no file line"

# --- A leftover component.yml prints the warn: line at exit 0 ---------------
assert_equals "yes" "$(has_line 'warn: ravintio-framework/component.yml sits beside release.yml')" "req-003 AC1: a leftover component.yml prints the exact warn: line"

C="$(consumer c-nowarn)"
write_record "$C" "$REL_VERSION" "$REL_SHA"
run_check "$C"
assert_equals "0" "$(count_prefix 'warn:')" "req-003 AC1: no component.yml prints no warn: line"

# --- A pack with no release.yml reads the component.yml version -------------
C="$(consumer c-fallback)"
rm -f "$C/$COPY_DIR/release.yml"
printf 'id: "ravintio-framework"\nversion: "0.38.0"\n' > "$C/$COPY_DIR/component.yml"
write_record "$C" "0.38.0" "$OTHER_SHA"
run_check "$C"
assert_equals "0" "$CODE" "req-003 AC1: a pack with no release.yml and an equal recorded version exits 0"
assert_equals "yes" "$(has_line 'release: none, fallback component.yml version "0.38.0"')" "req-003 AC1: no release.yml prints the component.yml fallback release: line"
assert_equals "yes" "$(has_line 'files: not checked, no release.yml')" "req-003 AC1: no release.yml prints files: not checked, no release.yml"
assert_equals "0" "$(count_prefix 'record:')" "req-003 AC1: no release.yml prints no record: line"
assert_equals "0" "$(count_prefix 'warn:')" "req-003 AC1: a component.yml with no release.yml prints no warn: line"

write_record "$C" "0.0.1" "$OTHER_SHA"
run_check "$C"
assert_equals "1" "$CODE" "req-003 AC1: the component.yml fallback with a different recorded version exits 1"
assert_equals "yes" "$(has_line 'update: release')" "req-003 AC1: the component.yml fallback with a different recorded version prints update: release"

C="$(consumer c-neither)"
rm -f "$C/$COPY_DIR/release.yml"
run_check "$C"
assert_equals "2" "$CODE" "req-003 AC1: a pack with neither release.yml nor component.yml exits 2"
assert_equals "yes" "$([ -n "$ERR" ] && echo yes || echo no)" "req-003 AC1: exit 2 for a missing manifest names the reason on stderr"

C="$(consumer c-badcomp)"
rm -f "$C/$COPY_DIR/release.yml"
printf 'this is not a manifest\n' > "$C/$COPY_DIR/component.yml"
run_check "$C"
assert_equals "2" "$CODE" "req-003 AC1: an unreadable component.yml with no release.yml exits 2"

# --- A malformed release.yml, a format 2 and a linked release.yml -----------
C="$(consumer c-malformed)"
printf 'id: "ravintio-framework"\nversion: "%s"\n' "$REL_VERSION" > "$C/$COPY_DIR/component.yml"
printf 'this is not a release file\n' > "$C/$COPY_DIR/release.yml"
run_check "$C"
assert_equals "2" "$CODE" "req-003 AC1: a malformed release.yml exits 2"
assert_equals "yes" "$([ -n "$ERR" ] && echo yes || echo no)" "req-003 AC1: a malformed release.yml names the reason on stderr"
assert_equals "0" "$(count_prefix 'release: none, fallback')" "req-003 AC1: a malformed release.yml never falls back to component.yml"

C="$(consumer c-format2)"
sed 's/^format: 1$/format: 2/' "$BASE/$COPY_DIR/release.yml" > "$WORK/format2.yml"
cp "$WORK/format2.yml" "$C/$COPY_DIR/release.yml"
printf 'id: "ravintio-framework"\nversion: "%s"\n' "$REL_VERSION" > "$C/$COPY_DIR/component.yml"
run_check "$C"
assert_equals "2" "$CODE" "req-003 AC1: a release.yml with format 2 exits 2"
assert_equals "0" "$(count_prefix 'release: none, fallback')" "req-003 AC1: a format 2 release.yml never falls back to component.yml"

if [ "$IS_WIN" = "no" ]; then
  C="$(consumer c-linkrel)"
  mv "$C/$COPY_DIR/release.yml" "$WORK/real-release.yml"
  ln -s "$WORK/real-release.yml" "$C/$COPY_DIR/release.yml"
  run_check "$C"
  assert_equals "2" "$CODE" "req-003 AC1: a linked release.yml exits 2"

  C="$(consumer c-linkrecord)"
  printf 'version: "%s"\nsource-commit: "%s"\n' "$REL_VERSION" "$REL_SHA" > "$WORK/real-record.yml"
  mkdir -p "$C/plan"
  ln -s "$WORK/real-record.yml" "$C/plan/framework-release.yml"
  run_check "$C"
  assert_equals "2" "$CODE" "req-003 AC1: a linked plan/framework-release.yml exits 2"

  C="$WORK/c-linkdir"
  mkdir -p "$C"
  ln -s "$BASE/$COPY_DIR" "$C/$COPY_DIR"
  run_check "$C"
  assert_equals "2" "$CODE" "req-003 AC1: a linked ravintio-framework/ folder exits 2"

  C="$(consumer c-linkfile)"
  write_record "$C" "$REL_VERSION" "$REL_SHA"
  cp "$C/$COPY_DIR/$LF_FILE" "$WORK/linked-target.md"
  rm -f "$C/$COPY_DIR/$LF_FILE"
  ln -s "$WORK/linked-target.md" "$C/$COPY_DIR/$LF_FILE"
  run_check "$C"
  assert_equals "1" "$CODE" "req-003 AC1: a link inside the pack exits 1"
  assert_equals "yes" "$(has_line "changed: $COPY_DIR/$LF_FILE")" "req-003 AC1: a link inside the pack counts as a changed file"
else
  echo "  SKIP: req-003 AC1: link cases (Git Bash on Windows)"
fi

# --- Arguments --------------------------------------------------------------
C="$(consumer c-args)"
write_record "$C" "$REL_VERSION" "$REL_SHA"
run_check "$C" --bogus
assert_equals "2" "$CODE" "req-003 AC1: an unknown argument exits 2"
run_check_cwd "$C"
assert_equals "0" "$CODE" "req-003 AC1: with no --root the working directory is the root"

# --- --files-only -----------------------------------------------------------
C="$(consumer c-fo-match)"
write_record "$C" "0.0.1" "$OTHER_SHA"
run_check "$C" --files-only
assert_equals "0" "$CODE" "req-003 AC1: --files-only exits 0 on a matching copy, whatever the recorded value says"
assert_equals "0" "$(count_prefix 'record:')" "req-003 AC1: --files-only prints no record: line"
assert_equals "0" "$(count_prefix 'update:')" "req-003 AC1: --files-only prints no update: line"

C="$(consumer c-fo-changed)"
printf 'an edit\n' >> "$C/$COPY_DIR/$LF_FILE"
run_check "$C" --files-only
assert_equals "1" "$CODE" "req-003 AC1: --files-only exits 1 on a changed file"
assert_equals "yes" "$(has_line "changed: $COPY_DIR/$LF_FILE")" "req-003 AC1: --files-only prints the changed: line"

C="$(consumer c-fo-norelease)"
rm -f "$C/$COPY_DIR/release.yml"
run_check "$C" --files-only
assert_equals "0" "$CODE" "req-003 AC1: --files-only exits 0 when release.yml is absent"
assert_equals "yes" "$(has_line 'skipped: no ravintio-framework/release.yml')" "req-003 AC1: --files-only prints the skipped: line when release.yml is absent"

# --- The script writes nothing ----------------------------------------------
C="$(consumer c-readonly)"
write_record "$C" "$REL_VERSION" "$OTHER_SHA"
BEFORE="$(cd "$C" && find . -type f -exec cksum {} + | sort | cksum)"
run_check "$C"
AFTER="$(cd "$C" && find . -type f -exec cksum {} + | sort | cksum)"
assert_equals "$BEFORE" "$AFTER" "req-003 AC1: the script writes no file, including plan/framework-release.yml"

# ===========================================================================
echo "=== req-003 AC2: the own-build rule in a scratch source repo ==="
# ===========================================================================

# An own build: the root copy was built from the current src/.
S="$(owndir own1)"
run_check "$S"
assert_equals "0" "$CODE" "req-003 AC2: an own build in a source repo exits 0"
assert_equals "yes" "$(has_line 'update: own-build')" "req-003 AC2: an own build prints update: own-build"
assert_equals "0" "$(count_prefix 'update: release')" "req-003 AC2: an own build prints no update: release"
assert_equals "yes" "$(has_line "$REC_LINE")" "req-003 AC2: an own build with no recorded value prints the record: line"

# The same after a squash-style rewrite drops source-commit from the history.
S="$(owndir own2)"
rm -rf "$S/.git"
sg "$S" init -q . >/dev/null 2>&1
sg "$S" add -A >/dev/null 2>&1
sg "$S" commit -q -m "squashed" >/dev/null 2>&1
GONE="$(git -C "$S" cat-file -e "$REL_SHA^{commit}" 2>/dev/null && echo present || echo absent)"
assert_equals "absent" "$GONE" "req-003 AC2: the squash-style rewrite removes source-commit from the history"
run_check "$S"
assert_equals "0" "$CODE" "req-003 AC2: an own build exits 0 after the history rewrite"
assert_equals "yes" "$(has_line 'update: own-build')" "req-003 AC2: an own build prints update: own-build after the history rewrite"

# One more commit changes a source file. With the recorded value, update: none.
S="$(owndir own3)"
write_record "$S" "$REL_VERSION" "$REL_SHA"
printf '\n<!-- later change -->\n' >> "$S/$PACK_IN_SRC/$LF_FILE"
sg "$S" add -A >/dev/null 2>&1
sg "$S" commit -q -m "later src change" >/dev/null 2>&1
run_check "$S"
assert_equals "0" "$CODE" "req-003 AC2: src moving ahead of the root copy exits 0 with the recorded value"
assert_equals "yes" "$(has_line 'update: none')" "req-003 AC2: src moving ahead of the root copy prints update: none"
assert_equals "0" "$(count_prefix 'update: own-build')" "req-003 AC2: src moving ahead of the root copy is not an own build"

# A root copy whose release.yml hashes do not match src/ is not an own build.
S="$(owndir own4)"
printf '\n<!-- later change -->\n' >> "$S/$PACK_IN_SRC/$LF_FILE"
sg "$S" add -A >/dev/null 2>&1
sg "$S" commit -q -m "later src change" >/dev/null 2>&1
run_check "$S"
assert_equals "1" "$CODE" "req-003 AC2: a root copy that does not match src/ exits 1"
assert_equals "yes" "$(has_line 'update: release')" "req-003 AC2: a root copy that does not match src/ prints update: release"
assert_equals "0" "$(count_prefix 'update: own-build')" "req-003 AC2: a root copy that does not match src/ prints no update: own-build"

# A tracked source file that release.yml lacks defeats the own-build proof.
S="$(owndir own5)"
printf 'new file\n' > "$S/$PACK_IN_SRC/zz-new-source-file.txt"
sg "$S" add -A >/dev/null 2>&1
sg "$S" commit -q -m "new src file" >/dev/null 2>&1
run_check "$S"
assert_equals "1" "$CODE" "req-003 AC2: a tracked source file that release.yml lacks exits 1"
assert_equals "0" "$(count_prefix 'update: own-build')" "req-003 AC2: a tracked source file that release.yml lacks is not an own build"

# A changed file in the root copy defeats the own-build proof.
S="$(owndir own6)"
printf 'an edit\n' >> "$S/$COPY_DIR/$LF_FILE"
run_check "$S"
assert_equals "1" "$CODE" "req-003 AC2: a changed root file in a source repo exits 1"
assert_equals "0" "$(count_prefix 'update: own-build')" "req-003 AC2: a changed root file in a source repo is not an own build"
assert_equals "yes" "$(has_line "changed: $COPY_DIR/$LF_FILE")" "req-003 AC2: a changed root file in a source repo prints the changed: line"

# A consumer repo never gets the own-build exception.
C="$(consumer c-notsource)"
run_check "$C"
assert_equals "0" "$(count_prefix 'update: own-build')" "req-003 AC2: a downstream repo never prints update: own-build"

# ===========================================================================
echo "=== req-003 AC3: the skill and policy texts ==="
# ===========================================================================

# --- Orchestrator step 1a ---------------------------------------------------
# Bracket classes, not backslashes: awk -v strips the escapes.
S1A="$(section "$ORCH" '^1a[.] [*][*]Detect a' '^1b[.] ')"
assert_equals "yes" "$([ -n "$S1A" ] && echo yes || echo no)" "req-003 AC3: the orchestrator keeps the 1a. **Detect a opening"
assert_equals "yes" "$(has_text 'framework-update-policy.md' "$S1A")" "req-003 AC3: step 1a keeps its link to framework-update-policy.md"
assert_equals "yes" "$(has_text 'node ravintio-framework/scripts/release-check.mjs' "$S1A")" "req-003 AC3: step 1a runs node ravintio-framework/scripts/release-check.mjs"
assert_equals "yes" "$(has_text 'exit 0' "$S1A")" "req-003 AC3: step 1a states the handling for exit 0"
assert_equals "yes" "$(has_text 'exit 1' "$S1A")" "req-003 AC3: step 1a states the handling for exit 1"
assert_equals "yes" "$(has_text 'exit 2' "$S1A")" "req-003 AC3: step 1a states the handling for exit 2"
assert_equals "yes" "$(has_text 'record:' "$S1A")" "req-003 AC3: step 1a names the record: line"
assert_equals "yes" "$(has_text 'plan/framework-release.yml' "$S1A")" "req-003 AC3: step 1a names the plan/framework-release.yml write"
assert_equals "yes" "$(has_text 'Write' "$S1A")" "req-003 AC3: step 1a writes the record with Write"
assert_equals "yes" "$(has_text 'own-build' "$S1A")" "req-003 AC3: step 1a names the own-build line"
assert_equals "yes" "$(has_text 'changed:' "$S1A")" "req-003 AC3: step 1a names each changed: file"
assert_equals "yes" "$(has_text 'missing:' "$S1A")" "req-003 AC3: step 1a names each missing: file"
assert_equals "yes" "$(has_text 'unlisted:' "$S1A")" "req-003 AC3: step 1a names each unlisted: file"
assert_equals "yes" "$(has_text 'warn:' "$S1A")" "req-003 AC3: step 1a names the warn: line"
assert_equals "yes" "$(has_text 'every session start' "$S1A")" "req-003 AC3: step 1a reports the warning at every session start"
assert_equals "yes" "$(has_text 'feat/' "$S1A")" "req-003 AC3: step 1a commits the record only on a feat/ branch"
assert_equals "yes" "$(has_text 'provenance' "$S1A")" "req-003 AC3: step 1a keeps the provenance confirmation"
assert_equals "yes" "$(has_text 'predates 0.39.0' "$S1A")" "req-003 AC3: step 1a covers a pack that predates 0.39.0 with no release-check.mjs"

# --- Orchestrator step 1b ---------------------------------------------------
S1B="$(section "$ORCH" '^1b[.] ' '^[0-9]+[a-z]?[.] ')"
assert_equals "yes" "$([ -n "$S1B" ] && echo yes || echo no)" "req-003 AC3: the orchestrator keeps step 1b"
assert_equals "yes" "$(has_text 'release-check.mjs' "$S1B")" "req-003 AC3: step 1b names release-check.mjs"
S1B_LINE="$(grep -iF 'release-check.mjs' <<< "$S1B" 2>/dev/null | head -1)"
assert_equals "yes" "$(has_text 'exit 2' "$S1B_LINE")" "req-003 AC3: step 1b names release-check.mjs exit 2 as a detection that could not run"

# --- Update policy ----------------------------------------------------------
DETECT="$(section "$POLICY" '^## Detection signal' '^## ')"
GATE="$(section "$POLICY" '^## Human confirmation gate' '^## ')"
assert_equals "yes" "$([ -n "$DETECT" ] && echo yes || echo no)" "req-003 AC3: the policy keeps ## Detection signal"
assert_equals "yes" "$(has_text 'release.yml' "$DETECT")" "req-003 AC3: the policy detection section names release.yml"
assert_equals "yes" "$(has_text 'changed file' "$DETECT")" "req-003 AC3: the policy states the changed-file signal"
assert_equals "yes" "$(has_text 'release update' "$DETECT")" "req-003 AC3: the policy states the release-update signal"
assert_equals "yes" "$(has_text 'first upgrade' "$DETECT")" "req-003 AC3: the policy states the first-upgrade rule"
assert_equals "yes" "$(has_text 'plan/framework-release.yml' "$DETECT")" "req-003 AC3: the policy names the recorded file"
assert_equals "yes" "$(has_text 'component.yml' "$DETECT")" "req-003 AC3: the policy states the component.yml fallback"
assert_equals "yes" "$(has_text '0.39.0' "$DETECT")" "req-003 AC3: the policy ties the fallback to a pack before 0.39.0"
assert_equals "yes" "$(has_text 'SHA-256' "$DETECT")" "req-003 AC3: the policy states the SHA-256 hash rule"
assert_equals "yes" "$(has_text 'CRLF' "$DETECT")" "req-003 AC3: the policy states that CRLF reads as LF in the hash rule"
assert_equals "yes" "$(has_text 'release-check.mjs' "$DETECT")" "req-003 AC3: the policy names the script that runs the check"
assert_equals "yes" "$(has_text 'beside' "$DETECT")" "req-003 AC3: the policy states the leftover manifest warning"
assert_equals "yes" "$(has_text 'own build' "$GATE")" "req-003 AC3: the policy gate states the own-build exception"
assert_equals "yes" "$(has_text 'provenance' "$(cat "$POLICY")")" "req-003 AC3: the policy keeps the word provenance"

# --- Migrator ---------------------------------------------------------------
# STEP 6: these cases stay RED until build order step 6 edits
# ravintio-migrator/SKILL.md. Step 5 leaves that file alone.
FV_ROW="$(grep -F '| `framework-version`' "$MIGRATOR" 2>/dev/null | head -1)"
FV_TPL="$(grep -E '^framework-version:' "$MIGRATOR" 2>/dev/null | head -1)"
ORDER="$(section "$MIGRATOR" '^### Order and old paths' '^##+ ')"
REL_LINES="$(grep -iF 'release.yml' "$MIGRATOR" 2>/dev/null)"
assert_equals "yes" "$(has_text 'release.yml' "$FV_ROW")" "req-003 AC3 (step 6): the migrator framework-version row reads release.yml"
assert_equals "yesyes" "$(has_text 'release.yml' "$FV_ROW")$(has_text 'component.yml' "$FV_ROW")" "req-003 AC3 (step 6): the migrator framework-version row falls back to component.yml"
assert_equals "yes" "$(has_text 'release.yml' "$FV_TPL")" "req-003 AC3 (step 6): the migrator Step 5 record template reads release.yml"
assert_equals "yes" "$(has_text 'release.yml' "$ORDER")" "req-003 AC3 (step 6): Order and old paths reads a migration's framework version through release.yml"
assert_equals "yes" "$(has_text 'component.yml' "$ORDER")" "req-003 AC3 (step 6): Order and old paths keeps the component.yml fallback"
assert_equals "yes" "$(has_text 'stop' "$REL_LINES")" "req-003 AC3 (step 6): the migrator stops on a release.yml that breaks the format"
assert_equals "yes" "$(has_text 'records nothing' "$REL_LINES")" "req-003 AC3 (step 6): the migrator records nothing on a release.yml that breaks the format"

print_summary
