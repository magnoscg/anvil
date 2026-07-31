#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PACK_ROOT="$REPO_ROOT/templates/ai-packs"
PATTERN_ROOT="$PACK_ROOT/swift-design-patterns/skills"
PROVENANCE="$PACK_ROOT/PROVENANCE.yml"

fail() {
  echo "skill validation failed: $*" >&2
  exit 1
}

directory_digest() {
  local directory="$1"
  (
    cd "$directory"
    find . -type f -print | LC_ALL=C sort | while IFS= read -r file; do
      local digest
      digest="$(shasum -a 256 "$file" | awk '{print $1}')"
      printf '%s  %s\n' "${file#./}" "$digest"
    done
  ) | shasum -a 256 | awk '{print $1}'
}

if [[ "${1:-}" == "--print-external-digests" ]]; then
  for slug in swiftui-expert-skill swift-concurrency mobile-ios-design; do
    printf '%s %s\n' "$slug" "$(directory_digest "$PACK_ROOT/ios-skills/skills/$slug")"
  done
  exit 0
fi

[[ -d "$PACK_ROOT" ]] || fail "missing pack root"
[[ -f "$PROVENANCE" ]] || fail "missing templates/ai-packs/PROVENANCE.yml"
[[ -f "$REPO_ROOT/THIRD_PARTY_NOTICES.md" ]] || fail "missing root THIRD_PARTY_NOTICES.md"
[[ -f "$PACK_ROOT/ios-skills/THIRD_PARTY_NOTICES.md" ]] || fail "missing installable iOS notices"

skill_count="$(find "$PACK_ROOT" -name SKILL.md -type f | wc -l | tr -d ' ')"
[[ "$skill_count" == "34" ]] || fail "expected 34 skills, found $skill_count"

pattern_count="$(find "$PATTERN_ROOT" -name SKILL.md -type f | wc -l | tr -d ' ')"
[[ "$pattern_count" == "25" ]] || fail "expected 25 pattern skills, found $pattern_count"

if grep -Riq 'refactoring[.]guru' "$PACK_ROOT"; then
  fail "distributed content contains a prohibited source reference"
fi

while IFS= read -r skill; do
  slug="$(basename "$(dirname "$skill")")"
  grep -Fq -- "- slug: $slug" "$PROVENANCE" || fail "$slug is missing from PROVENANCE.yml"

  case "$slug" in
    swiftui-expert-skill|swift-concurrency|mobile-ios-design)
      ;;
    *)
      grep -Fxq 'license: MIT' "$skill" || fail "$slug is missing license: MIT"
      grep -Fxq '  author: Oscar Canton' "$skill" || fail "$slug has the wrong first-party author"
      grep -Fxq '  origin: first-party' "$skill" || fail "$slug has the wrong first-party origin"
      ;;
  esac
done < <(find "$PACK_ROOT" -name SKILL.md -type f | LC_ALL=C sort)

provenance_count="$(grep -c '^  - slug: ' "$PROVENANCE" | tr -d ' ')"
[[ "$provenance_count" == "34" ]] || fail "expected 34 provenance entries, found $provenance_count"

verify_external_digest() {
  local slug="$1"
  local expected="$2"
  local actual
  actual="$(directory_digest "$PACK_ROOT/ios-skills/skills/$slug")"
  [[ "$actual" == "$expected" ]] || fail "$slug differs from its pinned upstream content"
  grep -Fq "$expected" "$PROVENANCE" || fail "$slug digest is missing from PROVENANCE.yml"
}

verify_external_digest swiftui-expert-skill 305778f66db8b44b9a0fef755aa5d96a1d58cd68ca63913941ca437629ee5604
verify_external_digest swift-concurrency 203418f17642362dd2996ec77e49749197fec491a2800f6ef147c3f8506f212c
verify_external_digest mobile-ios-design d99af4cb3a8922a0800b3b2cfc752bbb2c9453e93b914b5a2577679aeebf12a1

temporary_dir="$(mktemp -d "${TMPDIR:-/tmp}/anvil-skill-validation.XXXXXX")"
trap 'rm -rf "$temporary_dir"' EXIT
mkdir -p "$temporary_dir/module-cache"

example_count=0
for skill in "$PATTERN_ROOT"/*/SKILL.md; do
  slug="$(basename "$(dirname "$skill")")"
  fence_count="$(grep -c '^```swift$' "$skill" | tr -d ' ')"
  [[ "$fence_count" == "1" ]] || fail "$slug must contain exactly one Swift example"

  example="$temporary_dir/$slug.swift"
  awk '
    /^```swift$/ { inside = 1; next }
    inside && /^```$/ { exit }
    inside { print }
  ' "$skill" > "$example"

  [[ -s "$example" ]] || fail "$slug has an empty Swift example"
  CLANG_MODULE_CACHE_PATH="$temporary_dir/module-cache" \
    xcrun --sdk macosx swiftc \
    -module-cache-path "$temporary_dir/module-cache" \
    -swift-version 6 \
    -typecheck "$example" || fail "$slug does not compile with Swift 6"
  example_count=$((example_count + 1))
done

[[ "$example_count" == "25" ]] || fail "expected 25 compiled examples, found $example_count"

echo "Validated 34 skills, 34 provenance entries, and 25 Swift 6 examples."
