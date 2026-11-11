#!/usr/bin/env bash
# Exports the ios-architecture pack docs to a local agent skill directory, so a
# global skill can serve them without depending on the branch checked out here.
#
# Usage: scripts/sync-architecture-skill.sh [--check] [--worktree] [--ref <git-ref>] [--dest <skill-dir>]
#   --check      compare instead of writing; exits 1 when the copy differs
#   --worktree   export the working tree instead of a git ref (unpublished preview)
#   --ref        git ref to export (default: main)
#   --dest       skill directory (default: $SKILL_DIR or ~/.agents/skills/ios-architecture)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCS_PATH="templates/ai-packs/ios-architecture/docs"

ref="main"
dest="${SKILL_DIR:-$HOME/.agents/skills/ios-architecture}"
check=false
worktree=false

fail() {
  echo "sync-architecture-skill: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) check=true ;;
    --worktree) worktree=true ;;
    --ref) [[ $# -ge 2 ]] || fail "--ref needs a value"; ref="$2"; shift ;;
    --dest) [[ $# -ge 2 ]] || fail "--dest needs a value"; dest="$2"; shift ;;
    *) fail "unknown argument: $1" ;;
  esac
  shift
done

[[ -n "$dest" && "$dest" != "/" ]] || fail "refusing to use '$dest' as the skill directory"

staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
mkdir -p "$staging/docs"

if $worktree; then
  cp "$REPO_ROOT/$DOCS_PATH"/*.md "$staging/docs/"
  branch="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"
  commit="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
  source_line="working tree of $branch at $commit (unpublished)"
else
  git -C "$REPO_ROOT" rev-parse --verify --quiet "$ref^{commit}" >/dev/null || fail "unknown git ref: $ref"
  git -C "$REPO_ROOT" archive "$ref" "$DOCS_PATH" | tar -x -C "$staging"
  cp "$staging/$DOCS_PATH"/*.md "$staging/docs/"
  commit="$(git -C "$REPO_ROOT" rev-parse --short "$ref")"
  commit_date="$(git -C "$REPO_ROOT" log -1 --format=%cs "$ref")"
  source_line="$ref at $commit ($commit_date)"
fi

if $check; then
  [[ -d "$dest/docs" ]] || fail "$dest/docs does not exist; run 'make sync-skill'"
  if ! diff -rq "$staging/docs" "$dest/docs" >/dev/null; then
    diff -rq "$staging/docs" "$dest/docs" >&2 || true
    fail "$dest/docs differs from $source_line; run 'make sync-skill'"
  fi
  echo "sync-architecture-skill: $dest/docs matches $source_line"
  exit 0
fi

mkdir -p "$dest/docs"
find "$dest/docs" -maxdepth 1 -type f -name '*.md' -delete
cp "$staging/docs"/*.md "$dest/docs/"

{
  echo "Generated copy. Do not edit here: edit $DOCS_PATH in the anvil repository and run 'make sync-skill'."
  echo "source: $source_line"
  echo "synced: $(date +%Y-%m-%d)"
} > "$dest/VERSION"

count="$(find "$dest/docs" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
echo "sync-architecture-skill: wrote $count docs to $dest/docs from $source_line"
