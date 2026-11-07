#!/usr/bin/env bash
# Verified by: integration
#
# Tests for feature 0000041-pack-source-under-src, req-002: the release script
# scripts/build-release.mjs rebuilds the root release copy from the pack source
# (ADR-003).
#
# Sections:
#   AC1  a build in a scratch source repo: bytes, exec bits, release.yml,
#        output lines, a second run, and the 30 second limit.
#   AC2  the refusals, the link cases, the failed build, the restore of a
#        leftover previous folder, and the .gitignore lines.
#   AC3  the boot template sentence and the ship skill steps.
#   AC4  manual (the P7 Decision line and the setup refresh). No test here.
#
# Expected state before build-release.mjs exists: every AC1 and AC2 case is RED
# because node cannot load the script, and the AC3 cases are RED because the
# templates and the ship skill do not yet name it.
#
# Scratch repos copy the tracked files of this pack, so the pack is read through
# pack-root.sh. The script under test is the one in this pack. It runs with the
# scratch repo as its working directory.
#
# Link and permission cases skip under Git Bash on Windows, as
# test-0000035-req-008-sanctioned-scripts.sh does.
#
# Every loop reads lines with `done <<< "$(...)"`, never `done < <(...)`.

set -uo pipefail

unset CLAUDE_PROJECT_DIR GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers/assert.sh"
source "$SCRIPT_DIR/helpers/pack-root.sh"

BUILD="$RAVINTIO_PACK_DIR/scripts/build-release.mjs"
STANDARD_BOOT="$RAVINTIO_PACK_DIR/templates/standard-boot.md"
CURSOR_BOOT="$RAVINTIO_PACK_DIR/templates/cursor-boot.md"
SHIP_SKILL="$RAVINTIO_PACK_DIR/skills/ravintio-ship-agent/SKILL.md"
NEW_SCRIPT="ravintio-framework/scripts/build-release.mjs" # portable-ok: the consumer-facing path in the root release copy, not a pack-source path
PACK_IN_SRC="src/ravintio-framework"
COPY_DIR="ravintio-framework"

# Git Bash gives /tmp/x, which node reads as C:\tmp\x. pwd -W gives the Windows form.
WORK="$(cd "$(mktemp -d -t ravintio_0000041_req002_XXXXXX)" && { pwd -W 2>/dev/null || pwd; })"
trap 'chmod -R u+rwx "$WORK" 2>/dev/null; rm -rf "$WORK"' EXIT

IS_WIN=no
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) IS_WIN=yes ;; esac

# sg <repo> <git args...>: git in a scratch repo with a fixed identity.
sg() {
  local d="$1"; shift
  git -C "$d" -c user.name=tester -c user.email=tester@example.invalid \
    -c commit.gpgsign=false -c core.autocrlf=false "$@"
}

# run_build <dir> [args...]: run the script in <dir>. Sets OUT, ERR, CODE.
run_build() {
  local d="$1"; shift
  OUT="$(cd "$d" && env -u CLAUDE_PROJECT_DIR node "$BUILD" "$@" 2>"$WORK/stderr.txt")"
  CODE=$?
  ERR="$(cat "$WORK/stderr.txt")"
}

# snap <dir>: one checksum of the tree outside .git: names, bytes, exec bits, link targets.
snap() {
  (
    cd "$1" || exit 1
    find . -path ./.git -prune -o -print | sort
    find . -path ./.git -prune -o -type f -exec cksum {} + 2>/dev/null | sort
    find . -path ./.git -prune -o -type f -perm -u+x -print 2>/dev/null | sort
    find . -path ./.git -prune -o -type l -exec readlink {} \; 2>/dev/null | sort
  ) | cksum
}

sha256_text() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -d' ' -f1; else shasum -a 256 | cut -d' ' -f1; fi
}

# ---------------------------------------------------------------------------
# Scratch source repo: a copy of this pack, product.yml, an older root copy.
# ---------------------------------------------------------------------------

BASE="$WORK/base"
mkdir -p "$BASE"
git -C "$RAVINTIO_REPO_ROOT" ls-files -z -- "$RAVINTIO_PACK_REL" \
  | tar -C "$RAVINTIO_REPO_ROOT" -cf - --null -T - 2>/dev/null \
  | tar -C "$BASE" -xf - 2>/dev/null

PACK_VERSION="$(sed -n 's/^version: *"\(.*\)"$/\1/p' "$BASE/$PACK_IN_SRC/component.yml" | head -1)"
printf 'id: "ravintio-framework"\nname: "RAVINTIO Framework"\nversion: "0.38.0"\nversionPolicy: "max-component-version"\n\ncomponents:\n  - id: "ravintio-framework"\n    path: "src/ravintio-framework/component.yml"\n' > "$BASE/product.yml"
printf '.DS_Store\n.ravintio-framework-build/\n.ravintio-framework-previous/\n' > "$BASE/.gitignore"

# Probes: a CRLF file for the hash rule, and an ignored file that must not ship.
printf 'a\r\nb\r\nc\rd\n' > "$BASE/$PACK_IN_SRC/crlf-probe.txt"
printf 'junk\n' > "$BASE/$PACK_IN_SRC/.DS_Store"

SRC_LIST="$WORK/src-list.z"
sg "$BASE" init -q . >/dev/null 2>&1
sg "$BASE" add -A >/dev/null 2>&1
sg "$BASE" commit -q -m "src" >/dev/null 2>&1
git -C "$BASE" ls-files -z -- "$PACK_IN_SRC" > "$SRC_LIST"

# Pick paths for the older root copy.
EXEC_P=""; CHG_P=""; SAME_P=""
while IFS= read -r -d '' p; do
  rel="${p#$PACK_IN_SRC/}"
  [ "$rel" = "component.yml" ] && continue
  case "$rel" in .*|*/.*) continue ;; esac
  if [ -z "$EXEC_P" ] && [ -x "$BASE/$p" ]; then EXEC_P="$rel"; fi
  if [ -z "$CHG_P" ] && [ ! -x "$BASE/$p" ] && [ "$rel" != "crlf-probe.txt" ]; then CHG_P="$rel"; continue; fi
  if [ -z "$SAME_P" ] && [ ! -x "$BASE/$p" ] && [ "$rel" != "crlf-probe.txt" ] && [ "$rel" != "$CHG_P" ]; then SAME_P="$rel"; fi
done < "$SRC_LIST"

OLD="$BASE/$COPY_DIR"
mkdir -p "$OLD/old-dir/deep"
printf 'only in the old copy\n' > "$OLD/old-only.txt"
printf 'deep\n' > "$OLD/old-dir/deep/x.txt"
printf 'id: "ravintio-framework"\nversion: "0.37.0"\n' > "$OLD/component.yml"
printf 'old release record\n' > "$OLD/release.yml"
mkdir -p "$OLD/$(dirname "$EXEC_P")" "$OLD/$(dirname "$CHG_P")" "$OLD/$(dirname "$SAME_P")"
cp -p "$BASE/$PACK_IN_SRC/$EXEC_P" "$OLD/$EXEC_P"
chmod -x "$OLD/$EXEC_P" 2>/dev/null
printf 'old bytes\n' > "$OLD/$CHG_P"
cp -p "$BASE/$PACK_IN_SRC/$SAME_P" "$OLD/$SAME_P"
sg "$BASE" add -A >/dev/null 2>&1
sg "$BASE" commit -q -m "old root copy" >/dev/null 2>&1

# fresh <name>: a copy of the base repo. Prints its path.
fresh() {
  cp -Rp "$BASE" "$WORK/$1"
  echo "$WORK/$1"
}

# ===========================================================================
echo "=== req-002 AC1: a build in a scratch source repo ==="
# ===========================================================================

R1="$(fresh run1)"
cp -Rp "$R1/$COPY_DIR" "$WORK/old-snapshot"
HEAD1="$(git -C "$R1" rev-parse HEAD)"
DATE_BEFORE="$(date -u +%Y-%m-%d)"
T0=$(date +%s)
run_build "$R1"
T1=$(date +%s)
DATE_AFTER="$(date -u +%Y-%m-%d)"

assert_equals "0" "$CODE" "req-002 AC1: the build exits 0"
assert_equals "yes" "$([ $((T1 - T0)) -lt 30 ] && echo yes || echo no)" "req-002 AC1: the full build finishes in under 30 seconds"

# Every tracked source file except component.yml, with the same bytes and exec bit.
MISSING=0; DIFFERS=0; XBIT=0; SRC_N=0; SRC_X=0; DST_X=0
while IFS= read -r -d '' p; do
  rel="${p#$PACK_IN_SRC/}"
  [ "$rel" = "component.yml" ] && continue
  SRC_N=$((SRC_N + 1))
  d="$R1/$COPY_DIR/$rel"
  if [ ! -f "$d" ]; then MISSING=$((MISSING + 1)); continue; fi
  cmp -s "$R1/$p" "$d" || DIFFERS=$((DIFFERS + 1))
  s=0; t=0
  [ -x "$R1/$p" ] && s=1
  [ -x "$d" ] && t=1
  SRC_X=$((SRC_X + s)); DST_X=$((DST_X + t))
  [ "$s" = "$t" ] || XBIT=$((XBIT + 1))
done < "$SRC_LIST"
assert_equals "0" "$MISSING" "req-002 AC1: the root copy holds every tracked source file"
assert_equals "0" "$DIFFERS" "req-002 AC1: each copied file keeps its bytes"
assert_equals "0" "$XBIT" "req-002 AC1: each copied file keeps its executable bit"
assert_equals "yes" "$([ "$SRC_X" -gt 0 ] && [ "$SRC_X" = "$DST_X" ] && echo yes || echo no)" "req-002 AC1: the executable files are present in the root copy"
assert_equals "absent" "$([ -e "$R1/$COPY_DIR/component.yml" ] && echo present || echo absent)" "req-002 AC1: component.yml is absent from the root copy"
assert_equals "absent" "$([ -e "$R1/$COPY_DIR/.DS_Store" ] && echo present || echo absent)" "req-002 AC1: an ignored file never reaches the root copy"
assert_equals "absent" "$([ -e "$R1/$COPY_DIR/old-only.txt" ] || [ -e "$R1/$COPY_DIR/old-dir" ] && echo present || echo absent)" "req-002 AC1: a root file and folder that the source lacks are gone"
assert_equals "$((SRC_N + 1))" "$(find "$R1/$COPY_DIR" -type f | wc -l | tr -d ' ')" "req-002 AC1: the root copy holds the source files and release.yml, nothing else"
assert_equals "none" "$(ls -A "$R1" | grep -E '^\.ravintio-framework-(build|previous)$' | head -1 | grep . || echo none)" "req-002 AC1: no work folder remains"

# release.yml: exact format.
REL="$R1/$COPY_DIR/release.yml"
EXP_JS='
const fs = require("fs"), crypto = require("crypto");
const base = process.argv[1], prefix = process.argv[2];
const paths = fs.readFileSync(0, "utf8").split("\0").filter(Boolean)
  .map(p => p.slice(prefix.length)).filter(p => p !== "component.yml");
paths.sort();
let out = "";
for (const p of paths) {
  const text = fs.readFileSync(base + "/" + prefix + p).toString("latin1").replace(/\r\n/g, "\n");
  out += "  \"" + p + "\": \"" + crypto.createHash("sha256").update(Buffer.from(text, "latin1")).digest("hex") + "\"\n";
}
process.stdout.write(out);
'
EXP_FILES="$WORK/expected-files.txt"
node -e "$EXP_JS" "$R1" "$PACK_IN_SRC/" < "$SRC_LIST" > "$EXP_FILES"

HEADER_ACTUAL="$(sed -n '1,6p' "$REL" 2>/dev/null)"
HEADER_A="$(printf '# Written by scripts/build-release.mjs. Do not edit.\nformat: 1\nversion: "%s"\nsource-commit: "%s"\nbuilt: "%s"\nfiles:' "$PACK_VERSION" "$HEAD1" "$DATE_BEFORE")"
HEADER_B="$(printf '# Written by scripts/build-release.mjs. Do not edit.\nformat: 1\nversion: "%s"\nsource-commit: "%s"\nbuilt: "%s"\nfiles:' "$PACK_VERSION" "$HEAD1" "$DATE_AFTER")"
assert_equals "yes" "$([ "$HEADER_ACTUAL" = "$HEADER_A" ] || [ "$HEADER_ACTUAL" = "$HEADER_B" ] && echo yes || echo no)" \
  "req-002 AC1: release.yml opens with the comment, format, version, source-commit, built and files in order and quoted"
assert_equals "yes" "$(sed -n '7,$p' "$REL" 2>/dev/null | cmp -s - "$EXP_FILES" && echo yes || echo no)" \
  "req-002 AC1: the files block lists every root file once with its CRLF-as-LF SHA-256, in byte order"
assert_equals "0" "$(sed -n '7,$p' "$REL" 2>/dev/null | LC_ALL=C sort -c >/dev/null 2>&1; echo $?)" "req-002 AC1: the files lines sort in ascending byte order"
assert_equals "$((SRC_N))" "$(sed -n '7,$p' "$REL" 2>/dev/null | grep -cE '^  "[A-Za-z0-9._/-]+": "[0-9a-f]{64}"$')" "req-002 AC1: each files line has the two-space, quoted-path, 64-hex shape"
assert_equals "0" "$(grep -cE 'release\.yml|component\.yml' <<< "$(sed -n '7,$p' "$REL" 2>/dev/null)")" "req-002 AC1: no files line names release.yml or component.yml"
assert_equals "$(printf 'a\nb\nc\rd\n' | sha256_text)" "$(sed -n 's|^  "crlf-probe.txt": "\([0-9a-f]*\)"$|\1|p' "$REL" 2>/dev/null)" "req-002 AC1: a CRLF pair hashes as LF and a lone CR stays"
assert_equals "0a" "$(tail -c1 "$REL" 2>/dev/null | od -An -tx1 | tr -d ' \n')" "req-002 AC1: release.yml ends with one LF"
assert_equals "0" "$(grep -c "$(printf '\r')" "$REL" 2>/dev/null)" "req-002 AC1: release.yml holds no CR"

# Output lines and the summary line.
EXP_LINES="$WORK/expected-lines.txt"
: > "$EXP_LINES"
N_ADDED=0; N_CHANGED=0; N_REMOVED=0; N_SAME=0
while IFS= read -r p; do
  [ -z "$p" ] && continue
  o="$WORK/old-snapshot/$p"; n="$R1/$COPY_DIR/$p"
  if [ ! -e "$o" ]; then
    echo "added: ravintio-framework/$p" >> "$EXP_LINES"; N_ADDED=$((N_ADDED + 1))
  else
    ox=0; nx=0; [ -x "$o" ] && ox=1; [ -x "$n" ] && nx=1
    if cmp -s "$o" "$n" && [ "$ox" = "$nx" ]; then N_SAME=$((N_SAME + 1)); else echo "changed: ravintio-framework/$p" >> "$EXP_LINES"; N_CHANGED=$((N_CHANGED + 1)); fi
  fi
done <<< "$(cd "$R1/$COPY_DIR" && find . -type f | sed 's|^\./||')"
while IFS= read -r p; do
  [ -z "$p" ] && continue
  if [ ! -e "$R1/$COPY_DIR/$p" ]; then echo "removed: ravintio-framework/$p" >> "$EXP_LINES"; N_REMOVED=$((N_REMOVED + 1)); fi
done <<< "$(cd "$WORK/old-snapshot" && find . -type f | sed 's|^\./||')"

ACT_LINES="$(grep -E '^(added|changed|removed): ' <<< "$OUT" | LC_ALL=C sort)"
assert_equals "$(LC_ALL=C sort "$EXP_LINES")" "$ACT_LINES" "req-002 AC1: the output holds one added, changed or removed line for each differing file"
assert_contains "removed: ravintio-framework/component.yml" "$OUT" "req-002 AC1: the first build prints the component.yml removal"
assert_contains "changed: ravintio-framework/release.yml" "$OUT" "req-002 AC1: the lines cover release.yml"
assert_equals "summary: version $PACK_VERSION, source-commit $HEAD1, added $N_ADDED, changed $N_CHANGED, removed $N_REMOVED, unchanged $N_SAME" \
  "$(printf '%s\n' "$OUT" | tail -n 1)" "req-002 AC1: the last line is the summary with matching counts"

# A second run on the same commit and day.
SIG_FILES="$(snap "$R1/$COPY_DIR")"
cp -Rp "$R1/$COPY_DIR" "$WORK/after-first"
run_build "$R1"
assert_equals "0" "$CODE" "req-002 AC1: a second run exits 0"
assert_equals "yes" "$(diff -r "$WORK/after-first" "$R1/$COPY_DIR" >/dev/null 2>&1 && echo yes || echo no)" "req-002 AC1: a second run leaves every root file and release.yml byte-identical"
assert_equals "$SIG_FILES" "$(snap "$R1/$COPY_DIR")" "req-002 AC1: a second run keeps the file set and the executable bits"
assert_contains "added 0, changed 0, removed 0, unchanged $((SRC_N + 1))" "$(printf '%s\n' "$OUT" | tail -n 1)" "req-002 AC1: the second summary shows added 0, changed 0, removed 0"

# ===========================================================================
echo "=== req-002 AC2: refusals ==="
# ===========================================================================

# refuses <label> <dir> [args...]: exit 2, a reason on stderr, nothing written.
refuses() {
  local label="$1" d="$2"; shift 2
  local before after
  before="$(snap "$d")"
  run_build "$d" "$@"
  after="$(snap "$d")"
  assert_equals "2" "$CODE" "req-002 AC2: $label exits 2"
  assert_equals "yes" "$([ -n "$ERR" ] && echo yes || echo no)" "req-002 AC2: $label names the reason on stderr"
  assert_equals "$before" "$after" "req-002 AC2: $label writes nothing"
}

# A downstream repo.
R="$(fresh downstream)"
printf 'id: "demo"\nname: "Demo"\nversion: "1.0.0"\nversionPolicy: "max-component-version"\n\ncomponents:\n  - id: "demo"\n    path: "src/demo/component.yml"\n' > "$R/product.yml"
refuses "a downstream repo" "$R"

# An argument, named without its value.
R="$(fresh argument)"
refuses "an argument" "$R" --root sentinel-value-xyz
assert_contains "--root" "$ERR" "req-002 AC2: the argument refusal names the argument"
assert_equals "absent" "$([[ "$ERR" == *"sentinel-value-xyz"* ]] && echo present || echo absent)" "req-002 AC2: the argument refusal never echoes the value"

# An uncommitted change under src/.
R="$(fresh dirty)"
printf 'extra line\n' >> "$R/$PACK_IN_SRC/$CHG_P"
refuses "an uncommitted change under src/" "$R"
assert_contains "$CHG_P" "$ERR" "req-002 AC2: the dirty-tree refusal names the changed path"
R="$(fresh untracked)"
printf 'new\n' > "$R/$PACK_IN_SRC/not-committed-yet.txt"
refuses "an untracked file under src/" "$R"
assert_contains "not-committed-yet.txt" "$ERR" "req-002 AC2: the untracked-file refusal names the path"

# A path segment outside the allowed pattern.
R="$(fresh badname)"
printf 'x\n' > "$R/$PACK_IN_SRC/bad name.txt"
sg "$R" add -A >/dev/null 2>&1
sg "$R" commit -q -m "bad name" >/dev/null 2>&1
refuses "a tracked path with a space in a segment" "$R"
assert_contains "bad name.txt" "$ERR" "req-002 AC2: the path-segment refusal names the path"

if [ "$IS_WIN" = "yes" ]; then
  echo "  SKIP (windows): Git Bash ln -s copies the target, so the link cases cannot be built"
else
  # A tracked link under src/.
  R="$(fresh trackedlink)"
  ln -s component.yml "$R/$PACK_IN_SRC/linked.md"
  sg "$R" add -A >/dev/null 2>&1
  sg "$R" commit -q -m "tracked link" >/dev/null 2>&1
  refuses "a tracked link" "$R"
  assert_contains "linked.md" "$ERR" "req-002 AC2: the tracked-link refusal names the path"

  # Each of the three folders as a link. The target outside the root stays unchanged.
  for DIR in "$COPY_DIR" ".ravintio-framework-build" ".ravintio-framework-previous"; do
    R="$(fresh "link-$DIR")"
    OUTSIDE="$WORK/outside-$DIR"
    mkdir -p "$OUTSIDE/sub"
    printf 'outside bytes\n' > "$OUTSIDE/keep.txt"
    printf 'inner\n' > "$OUTSIDE/sub/inner.txt"
    rm -rf "${R:?}/$DIR"
    ln -s "$OUTSIDE" "$R/$DIR"
    OUT_BEFORE="$(snap "$OUTSIDE")"
    refuses "$DIR as a link" "$R"
    assert_equals "$OUT_BEFORE" "$(snap "$OUTSIDE")" "req-002 AC2: the file outside the root stays byte-identical when $DIR is a link"
  done

  # A link inside the old copy goes as a link. Its target stays unchanged.
  R="$(fresh innerlink)"
  OUTSIDE="$WORK/outside-inner"
  mkdir -p "$OUTSIDE/sub"
  printf 'outside bytes\n' > "$OUTSIDE/keep.txt"
  printf 'inner\n' > "$OUTSIDE/sub/inner.txt"
  ln -s "$OUTSIDE" "$R/$COPY_DIR/old-dir-link"
  ln -s "$OUTSIDE/keep.txt" "$R/$COPY_DIR/old-file-link"
  OUT_BEFORE="$(snap "$OUTSIDE")"
  run_build "$R"
  assert_equals "0" "$CODE" "req-002 AC2: a build with links in the old copy exits 0"
  assert_equals "absent" "$([ -L "$R/$COPY_DIR/old-dir-link" ] || [ -e "$R/$COPY_DIR/old-dir-link" ] && echo present || echo absent)" "req-002 AC2: a folder link inside the old copy is gone"
  assert_equals "absent" "$([ -L "$R/$COPY_DIR/old-file-link" ] || [ -e "$R/$COPY_DIR/old-file-link" ] && echo present || echo absent)" "req-002 AC2: a file link inside the old copy is gone"
  assert_equals "$OUT_BEFORE" "$(snap "$OUTSIDE")" "req-002 AC2: the link targets outside the root stay byte-identical"
fi

# An unreadable source file fails the build and keeps the old copy.
if [ "$IS_WIN" = "yes" ]; then
  echo "  SKIP (windows): chmod sets no NTFS mode, so the unreadable-file case cannot be built"
elif [ "$(id -u)" = "0" ]; then
  echo "  SKIP (root): root reads a mode 000 file, so the unreadable-file case cannot be built"
else
  R="$(fresh unreadable)"
  chmod 000 "$R/$PACK_IN_SRC/$SAME_P"
  OLD_SIG="$(snap "$R/$COPY_DIR")"
  run_build "$R"
  assert_equals "yes" "$([ "$CODE" -ne 0 ] && echo yes || echo no)" "req-002 AC2: an unreadable source file fails the build with a non-zero exit"
  assert_equals "$OLD_SIG" "$(snap "$R/$COPY_DIR")" "req-002 AC2: the old root copy stays byte-identical after a failed build"
  assert_equals "none" "$(ls -A "$R" | grep -E '^\.ravintio-framework-(build|previous)$' | head -1 | grep . || echo none)" "req-002 AC2: no work folder remains after a failed build"
  chmod 644 "$R/$PACK_IN_SRC/$SAME_P"
fi

# A leftover previous folder with no root copy: restore, then build.
R="$(fresh restore)"
mv "$R/$COPY_DIR" "$R/.ravintio-framework-previous"
mkdir -p "$R/.ravintio-framework-build"
printf 'partial\n' > "$R/.ravintio-framework-build/partial.txt"
run_build "$R"
assert_equals "0" "$CODE" "req-002 AC2: a run with a leftover previous folder exits 0"
assert_contains "restored: ravintio-framework/ from an interrupted build" "$OUT" "req-002 AC2: the run prints the restored line"
assert_contains "removed: ravintio-framework/old-only.txt" "$OUT" "req-002 AC2: the restored copy is the base of the comparison"
assert_equals "present" "$([ -f "$R/$COPY_DIR/release.yml" ] && [ -f "$R/$COPY_DIR/$CHG_P" ] && echo present || echo absent)" "req-002 AC2: the build completes after the restore"
assert_equals "none" "$(ls -A "$R" | grep -E '^\.ravintio-framework-(build|previous)$' | head -1 | grep . || echo none)" "req-002 AC2: neither work folder remains after the restore"

# Both a previous folder and a root copy: the earlier swap finished.
R="$(fresh bothpresent)"
cp -Rp "$R/$COPY_DIR" "$R/.ravintio-framework-previous"
run_build "$R"
assert_equals "0" "$CODE" "req-002 AC2: a run with both root and previous folders exits 0"
assert_equals "absent" "$([ -e "$R/.ravintio-framework-previous" ] && echo present || echo absent)" "req-002 AC2: the finished swap leaves no previous folder"
assert_equals "absent" "$([[ "$OUT" == *"restored:"* ]] && echo present || echo absent)" "req-002 AC2: no restored line prints when the root copy exists"

# ===========================================================================
echo "=== req-002 P5: security fixes (F-01, F-06, F-07, F-08, work folder mode) ==="
# ===========================================================================

# F-01: the working folder, the resolved root and the git top level must be one path.
if [ "$IS_WIN" = "yes" ]; then
  echo "  SKIP (windows): the P5 F-01 reproduction relies on POSIX paths"
else
  R="$(fresh p5root)"
  mkdir -p "$R/src/src/ravintio-framework"
  cp "$R/product.yml" "$R/src/product.yml"
  printf 'id: "x"\nversion: "9.9.9"\n' > "$R/src/src/ravintio-framework/component.yml"
  printf 'pwned\n' > "$R/src/src/ravintio-framework/evil.md"
  sg "$R" add -A >/dev/null 2>&1
  sg "$R" commit -q -m "plant" >/dev/null 2>&1
  printf 'local untracked\n' > "$R/$PACK_IN_SRC/MYNOTES.txt"
  P5_BEFORE="$(snap "$R/$PACK_IN_SRC")"
  P5_SRC_BEFORE="$(snap "$R/src")"
  run_build "$R/src"
  assert_equals "2" "$CODE" "req-002 P5 F-01: a run from src/ beside a tracked src/product.yml exits 2"
  assert_equals "$P5_BEFORE" "$(snap "$R/$PACK_IN_SRC")" "req-002 P5 F-01: src/ravintio-framework/ stays byte-identical after the src/ run"
  assert_equals "$P5_SRC_BEFORE" "$(snap "$R/src")" "req-002 P5 F-01: the src/ run writes nothing under src/"
  assert_equals "present" "$([ -f "$R/$PACK_IN_SRC/MYNOTES.txt" ] && echo present || echo absent)" "req-002 P5 F-01: an untracked file in the pack source survives the src/ run"

  R="$(fresh p5subfolder)"
  P5_ALL_BEFORE="$(snap "$R")"
  run_build "$R/$COPY_DIR"
  assert_equals "2" "$CODE" "req-002 P5 F-01: a plain run from a subfolder exits 2"
  assert_equals "yes" "$([ -n "$ERR" ] && echo yes || echo no)" "req-002 P5 F-01: the subfolder refusal names the reason on stderr"
  assert_equals "$P5_ALL_BEFORE" "$(snap "$R")" "req-002 P5 F-01: the subfolder run writes nothing"
fi

# F-06: git config from the environment never runs a command.
R="$(fresh p5fsmonitor)"
P5_MARK="$WORK/p5-fsmonitor-marker"
rm -f "$P5_MARK"
(
  export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.fsmonitor "GIT_CONFIG_VALUE_0=touch '$P5_MARK'; false"
  run_build "$R"
)
assert_equals "absent" "$([ -e "$P5_MARK" ] && echo present || echo absent)" "req-002 P5 F-06: a core.fsmonitor command from GIT_CONFIG_* never runs"

# F-07: two bad source entries exit 2, not 1.
R="$(fresh p5releaseyml)"
printf 'tracked\n' > "$R/$PACK_IN_SRC/release.yml"
sg "$R" add -A >/dev/null 2>&1
sg "$R" commit -q -m "tracked release.yml" >/dev/null 2>&1
refuses "req-002 P5 F-07: a tracked src/ravintio-framework/release.yml" "$R"

P5_CASE="$WORK/p5-case-probe"
mkdir -p "$P5_CASE"
: > "$P5_CASE/a"; : > "$P5_CASE/A"
if [ "$(ls "$P5_CASE" | wc -l | tr -d ' ')" != "2" ]; then
  echo "  SKIP (case-insensitive file system): the P5 F-07 case-only collision cannot be built"
else
  R="$(fresh p5collision)"
  mkdir -p "$R/$PACK_IN_SRC/zcase"
  printf 'one\n' > "$R/$PACK_IN_SRC/zcase/Readme.md"
  printf 'two\n' > "$R/$PACK_IN_SRC/zcase/readme.md"
  sg "$R" add -A >/dev/null 2>&1
  sg "$R" commit -q -m "case collision" >/dev/null 2>&1
  refuses "req-002 P5 F-07: two tracked paths that differ only in case" "$R"
fi

# F-08: the restored line prints even when the build then fails.
if [ "$IS_WIN" = "yes" ]; then
  echo "  SKIP (windows): chmod sets no NTFS mode, so the P5 F-08 unreadable-file case cannot be built"
elif [ "$(id -u)" = "0" ]; then
  echo "  SKIP (root): root reads a mode 000 file, so the P5 F-08 unreadable-file case cannot be built"
else
  R="$(fresh p5restorefail)"
  mv "$R/$COPY_DIR" "$R/.ravintio-framework-previous"
  # git must not see the mode 000 file as dirty, or the dirty check fails first and the build step never runs.
  sg "$R" config core.trustctime false
  sg "$R" update-index --refresh >/dev/null 2>&1
  chmod 000 "$R/$PACK_IN_SRC/$SAME_P"
  run_build "$R"
  assert_equals "yes" "$([ "$CODE" -ne 0 ] && echo yes || echo no)" "req-002 P5 F-08: a restore followed by an unreadable source file fails the build"
  assert_contains "restored: ravintio-framework/ from an interrupted build" "$OUT$ERR" "req-002 P5 F-08: the restored line prints although the build then fails"
  assert_equals "present" "$([ -f "$R/$COPY_DIR/old-only.txt" ] && echo present || echo absent)" "req-002 P5 F-08: the restored copy is back in place after the failed build"
  chmod 644 "$R/$PACK_IN_SRC/$SAME_P"
fi

# Work folder mode: poll while a build runs and read the build folder mode.
if [ "$IS_WIN" = "yes" ]; then
  echo "  SKIP (windows): NTFS has no POSIX mode, so the P5 work folder mode cannot be read"
else
  R="$(fresh p5mode)"
  P5_MODE=""
  (cd "$R" && node "$BUILD" >/dev/null 2>&1) &
  P5_PID=$!
  while kill -0 "$P5_PID" 2>/dev/null; do
    if [ -d "$R/.ravintio-framework-build" ]; then
      P5_MODE="$(stat -c %a "$R/.ravintio-framework-build" 2>/dev/null || stat -f %Lp "$R/.ravintio-framework-build" 2>/dev/null)"
      break
    fi
  done
  wait "$P5_PID" 2>/dev/null
  if [ -z "$P5_MODE" ]; then
    echo "  SKIP (too fast): the build folder was never seen while the build ran"
  else
    assert_equals "700" "$P5_MODE" "req-002 P5 F-02: the build folder is created with mode 0700"
  fi
fi

# .gitignore lists both work folders.
GI="$RAVINTIO_REPO_ROOT/.gitignore"
assert_equals "yes" "$(grep -qxF '.ravintio-framework-build/' "$GI" && echo yes || echo no)" "req-002 AC2: .gitignore holds the .ravintio-framework-build/ line"
assert_equals "yes" "$(grep -qxF '.ravintio-framework-previous/' "$GI" && echo yes || echo no)" "req-002 AC2: .gitignore holds the .ravintio-framework-previous/ line"

# ===========================================================================
echo "=== req-002 AC3: boot templates and ship skill ==="
# ===========================================================================

sentence() {
  grep '^8\. \*\*Code changes go through Write or Edit' "$1" | sed -n 's/.*\(Sanctioned scripts:.*\)/\1/p'
}
SENT_STD="$(sentence "$STANDARD_BOOT")"
SENT_CUR="$(sentence "$CURSOR_BOOT")"
for T in "$STANDARD_BOOT" "$CURSOR_BOOT"; do
  NAME="$(basename "$T")"
  assert_equals "1" "$(grep -c 'Sanctioned scripts:' "$T")" "req-002 AC3: $NAME holds one Sanctioned scripts: sentence"
  assert_equals "8" "$(sentence "$T" | grep -o '`ravintio-framework/[^`]*`' | sort -u | wc -l | tr -d ' ')" "req-002 AC3: $NAME names eight scripts"
  assert_contains "\`$NEW_SCRIPT\`" "$(sentence "$T")" "req-002 AC3: $NAME names $NEW_SCRIPT"
done
assert_equals "yes" "$([ -n "$SENT_STD" ] && [ "$SENT_STD" = "$SENT_CUR" ] && echo yes || echo no)" "req-002 AC3: both boot templates carry one identical Sanctioned scripts: sentence"

section() {
  awk -v h="$2" 'index($0, h) == 1 { p = 1; print; next } p && /^### / { exit } p { print }' "$1"
}
L5B="$(grep -n '^### Step 5b' "$SHIP_SKILL" | head -1 | cut -d: -f1)"
L5C="$(grep -n '^### Step 5c: Build the release copy' "$SHIP_SKILL" | head -1 | cut -d: -f1)"
L6="$(grep -n '^### Step 6: ' "$SHIP_SKILL" | head -1 | cut -d: -f1)"
assert_equals "yes" "$([ -n "$L5B" ] && [ -n "$L5C" ] && [ -n "$L6" ] && [ "$L5B" -lt "$L5C" ] && [ "$L5C" -lt "$L6" ] && echo yes || echo no)" "req-002 AC3: the ship skill holds Step 5c between Step 5b and Step 6"

S5C="$(section "$SHIP_SKILL" '### Step 5c: Build the release copy')"
assert_contains "node ravintio-framework/scripts/project-kind.mjs" "$S5C" "req-002 AC3: Step 5c runs the project-kind.mjs check"
assert_contains "framework source" "$S5C" "req-002 AC3: Step 5c names the framework source kind"
assert_contains "P7: Step 5c skipped: project kind {output}" "$S5C" "req-002 AC3: Step 5c holds the skip line with the printed kind"
assert_contains "P7: Step 5c warning: src/ravintio-framework/ exists, so check product.yml" "$S5C" "req-002 AC3: Step 5c holds the src/ warning line"
assert_contains "node ravintio-framework/scripts/build-release.mjs" "$S5C" "req-002 AC3: Step 5c runs the build-release.mjs call"
assert_contains "summary:" "$S5C" "req-002 AC3: Step 5c logs the summary line on exit 0"
assert_contains "exit 0" "$(tr 'A-Z' 'a-z' <<< "$S5C")" "req-002 AC3: Step 5c handles exit 0"
assert_contains "exit 2" "$(tr 'A-Z' 'a-z' <<< "$S5C")" "req-002 AC3: Step 5c handles exit 2"
assert_contains "any other exit" "$(tr 'A-Z' 'a-z' <<< "$S5C")" "req-002 AC3: Step 5c handles any other exit"

S7="$(section "$SHIP_SKILL" '### Step 7: Commit archive')"
GATE_LINE='if [ "$(node ravintio-framework/scripts/project-kind.mjs)" = "framework source" ]; then git add -A -- ravintio-framework/; fi'
ADD_LINE='git add plan/current/ plan/_archive/ plan/changelog/ docs/about.md'
assert_equals "1" "$(grep -cxF -- "$GATE_LINE" <<< "$S7")" "req-002 AC3: Step 7 holds the project-kind-gated git add -A line"
assert_equals "1" "$(grep -cxF -- "$ADD_LINE" <<< "$S7")" "req-002 AC3: Step 7 keeps its existing git add line"
assert_equals "yes" "$(a="$(grep -nxF -- "$ADD_LINE" <<< "$S7" | cut -d: -f1)"; b="$(grep -nxF -- "$GATE_LINE" <<< "$S7" | cut -d: -f1)"; [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ] && echo yes || echo no)" "req-002 AC3: the gated line follows the existing git add line"
assert_equals "yes" "$(grep -E '^- `P7:`' "$SHIP_SKILL" | head -1 | grep -qF 'Step 5c' && echo yes || echo no)" "req-002 AC3: the Prefix line names Step 5c"

print_summary
