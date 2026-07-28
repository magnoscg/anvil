#!/bin/bash
set -euo pipefail

INSTALL_DIR="/usr/local/bin"
BINARY_NAME="anvil"

echo ""
echo "  AnvilCLI Installer"
echo "  ==================="
echo ""

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    arm64|aarch64) ARCH_LABEL="Apple Silicon (arm64)" ;;
    x86_64)        ARCH_LABEL="Intel (amd64)" ;;
    *)
        echo "  Error: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac
echo "  Architecture: $ARCH_LABEL"

# Check binary exists next to this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY_PATH="$SCRIPT_DIR/$BINARY_NAME"

if [ ! -f "$BINARY_PATH" ]; then
    echo "  Error: '$BINARY_NAME' binary not found in $SCRIPT_DIR"
    echo "  Make sure install.sh is in the same directory as the anvil binary."
    exit 1
fi

echo "  Binary found: $BINARY_PATH"
echo ""

# Install
echo "  Installing to $INSTALL_DIR/$BINARY_NAME ..."
if [ -w "$INSTALL_DIR" ]; then
    cp "$BINARY_PATH" "$INSTALL_DIR/$BINARY_NAME"
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
else
    echo "  (requires sudo)"
    sudo cp "$BINARY_PATH" "$INSTALL_DIR/$BINARY_NAME"
    sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"
fi

echo ""
echo "  Done! AnvilCLI installed successfully."
echo ""
echo "  Get started:"
echo "    anvil init             Create a new iOS project"
echo "    anvil feature <name>   Scaffold a new feature"
echo "    anvil version          Show version"
echo "    anvil help             Show all commands"
echo ""
