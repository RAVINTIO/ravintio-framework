#!/usr/bin/env bash
# pack-root.sh: the one resolver that suites use to find the pack and the repo root.
# Source it after helpers/assert.sh. See req-008 (tests-and-ci-from-src) and ADR-009.
#
# Sets four shell variables. It exports nothing and changes no environment variable.
#   RAVINTIO_PACK_DIR     absolute path of the pack that holds this helper
#   RAVINTIO_REPO_ROOT    the parent of src/ when the pack sits in a folder named src,
#                         otherwise the pack's parent
#   RAVINTIO_PACK_REL     src/ravintio-framework or ravintio-framework
#   RAVINTIO_SOURCE_REPO  yes when project-kind.mjs prints "framework source", else no
#
# In a source repo, sourcing this from the root release copy prints a FAIL line and exits 1.

_pr_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAVINTIO_PACK_DIR="$(cd "$_pr_here/../.." && pwd)"
_pr_parent="$(dirname "$RAVINTIO_PACK_DIR")"

if [ "$(basename "$_pr_parent")" = "src" ]; then
  RAVINTIO_REPO_ROOT="$(dirname "$_pr_parent")"
  RAVINTIO_PACK_REL="src/$(basename "$RAVINTIO_PACK_DIR")"
else
  RAVINTIO_REPO_ROOT="$_pr_parent"
  RAVINTIO_PACK_REL="$(basename "$RAVINTIO_PACK_DIR")"
fi

_pr_kind="$(node "$RAVINTIO_PACK_DIR/scripts/project-kind.mjs" --root "$RAVINTIO_REPO_ROOT" 2>/dev/null)"
if [ "$_pr_kind" = "framework source" ]; then
  RAVINTIO_SOURCE_REPO="yes"
else
  RAVINTIO_SOURCE_REPO="no"
fi

unset _pr_here _pr_parent _pr_kind

if [ "$RAVINTIO_SOURCE_REPO" = "yes" ] && [ "$RAVINTIO_PACK_REL" = "ravintio-framework" ]; then
  echo "FAIL: pack-root: this suite runs from the root release copy. Run it from src/ravintio-framework/tests/."
  exit 1
fi
