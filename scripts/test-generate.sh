#!/bin/bash
# test-generate.sh — End-to-end test: generate a project and build it
# Usage: ./scripts/test-generate.sh [project-name] [ios-version]
set -euo pipefail

PROJECT_NAME="${1:-TestProject}"
IOS_VERSION="${2:-18.0}"
SWIFT_VERSION="6.0"
BUNDLE_ID="com.test.${PROJECT_NAME}"
SCHEMES="Dev,Stg,Production"
OUTPUT_DIR=$(mktemp -d)
SIM_ID="B14005E0-AD25-4A48-BA38-6559F4684B8F"

echo "=== AnvilCLI E2E Test ==="
echo "  Project:  $PROJECT_NAME"
echo "  iOS:      $IOS_VERSION"
echo "  Swift:    $SWIFT_VERSION"
echo "  Output:   $OUTPUT_DIR"
echo ""

# Step 1: Build anvil
echo "--- Step 1: Building anvil ---"
make build 2>&1 | tail -1

# Step 2: Generate project programmatically using Go
echo ""
echo "--- Step 2: Generating project ---"
go run ./scripts/generate_test_project.go \
  -name "$PROJECT_NAME" \
  -bundle-id "$BUNDLE_ID" \
  -ios-version "$IOS_VERSION" \
  -swift-version "$SWIFT_VERSION" \
  -schemes "$SCHEMES" \
  -output "$OUTPUT_DIR" \
  -include-example \
  -include-swiftdata

PROJECT_DIR="$OUTPUT_DIR/$PROJECT_NAME"

echo "  Generated at: $PROJECT_DIR"
echo ""

# Step 3: Check directory structure
echo "--- Step 3: Directory structure ---"
echo "  Root:"
ls "$PROJECT_DIR" | sed 's/^/    /'
echo "  Source ($PROJECT_NAME/):"
ls "$PROJECT_DIR/$PROJECT_NAME" 2>/dev/null | sed 's/^/    /' || echo "    (not found!)"
echo ""

# Step 4: Run tuist generate
echo "--- Step 4: tuist generate ---"
cd "$PROJECT_DIR"
tuist generate 2>&1 || {
  echo "  FAILED! Tuist logs:"
  LATEST_LOG=$(ls -t ~/.local/state/tuist/sessions/*/logs.txt 2>/dev/null | head -1)
  if [ -n "$LATEST_LOG" ]; then
    grep -i "error\|incorrect\|fatal" "$LATEST_LOG" | tail -10
  fi
  echo ""
  echo "  Generated Project.swift:"
  cat "$PROJECT_DIR/Project.swift"
  echo ""
  echo "  Cleaning up: $OUTPUT_DIR"
  rm -rf "$OUTPUT_DIR"
  exit 1
}
echo ""

# Step 5: List schemes
echo "--- Step 5: Available schemes ---"
XCODEPROJ=$(find "$PROJECT_DIR" -maxdepth 1 -name "*.xcodeproj" | head -1)
xcodebuild -list -project "$XCODEPROJ" 2>&1 | grep -A20 "Schemes:" || true
echo ""

# Step 6: Build
SCHEME="${PROJECT_NAME}-Dev"
echo "--- Step 6: Building scheme $SCHEME ---"
xcodebuild build \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$SIM_ID" \
  2>&1 | grep "error:" | sort -u || true

BUILD_EXIT=${PIPESTATUS[0]}
echo ""
if [ "$BUILD_EXIT" -eq 0 ]; then
  echo "=== BUILD SUCCEEDED ==="
else
  echo "=== BUILD FAILED (exit $BUILD_EXIT) ==="
fi

# Cleanup
echo ""
echo "  Cleaning up: $OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"

exit $BUILD_EXIT
