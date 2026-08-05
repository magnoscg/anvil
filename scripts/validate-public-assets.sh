#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PREVIEW="$ROOT_DIR/docs/images/social-preview.png"
INIT_CAPTURE="$ROOT_DIR/docs/images/anvil-init.png"
DONE_CAPTURE="$ROOT_DIR/docs/images/anvil-done.png"
PROVENANCE="$ROOT_DIR/ASSET_PROVENANCE.md"
README="$ROOT_DIR/README.md"

EXPECTED_PREVIEW_HASH="4f6598e238b8f47ec6923ea39ac7cfd41e052fa79c2c79935a876199ce6f3c8d"
EXPECTED_INIT_HASH="4569144f02b81a80ae76b68e8e87f1cc2ad7d450a65cc8f43e2dd0f1cf943c58"
EXPECTED_DONE_HASH="34364d615d02590111f46d04b250eddc71a5c2aa188f66887f62589777e76151"

fail() {
  echo "public asset validation failed: $*" >&2
  exit 1
}

for file in "$PREVIEW" "$INIT_CAPTURE" "$DONE_CAPTURE" "$PROVENANCE" "$README"; do
  [[ -f "$file" && ! -L "$file" ]] || fail "$file must be a regular file"
done

width="$(sips -g pixelWidth "$PREVIEW" 2>/dev/null | awk '/pixelWidth/ { print $2 }')"
height="$(sips -g pixelHeight "$PREVIEW" 2>/dev/null | awk '/pixelHeight/ { print $2 }')"
[[ "$width" == "1280" && "$height" == "640" ]] \
  || fail "social preview must be 1280x640, found ${width}x${height}"

size="$(wc -c < "$PREVIEW" | tr -d ' ')"
[[ "$size" -le 1000000 ]] || fail "social preview must stay below 1 MB"

hash_for() {
  shasum -a 256 "$1" | awk '{ print $1 }'
}

[[ "$(hash_for "$PREVIEW")" == "$EXPECTED_PREVIEW_HASH" ]] \
  || fail "social preview SHA-256 does not match the reviewed asset"
[[ "$(hash_for "$INIT_CAPTURE")" == "$EXPECTED_INIT_HASH" ]] \
  || fail "anvil-init.png SHA-256 does not match the provenance record"
[[ "$(hash_for "$DONE_CAPTURE")" == "$EXPECTED_DONE_HASH" ]] \
  || fail "anvil-done.png SHA-256 does not match the provenance record"

grep -Fq '](docs/images/social-preview.png)' "$README" \
  || fail "README must display the social preview"
grep -Fq '[Asset provenance](ASSET_PROVENANCE.md)' "$README" \
  || fail "README must link asset provenance"
grep -Fq 'No AI-generated product pixels' "$PROVENANCE" \
  || fail "provenance must preserve the authentic-capture disclosure"
grep -Fq "$EXPECTED_PREVIEW_HASH" "$PROVENANCE" \
  || fail "provenance must record the reviewed social-preview hash"

if grep -Eq '(/Users/|/home/|file://|gh[pousr]_|sk-[A-Za-z0-9]{16}|AKIA[A-Z0-9]{16})' "$PROVENANCE"; then
  fail "provenance contains a local path or secret-like value"
fi

echo "Validated Anvil social preview: 1280x640, ${size} bytes, authentic sources, reviewed SHA-256."
