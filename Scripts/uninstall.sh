#!/usr/bin/env bash
# uninstall.sh — Remove the gherkin-gen CLI tool.
#
# Usage:
#   ./Scripts/uninstall.sh
#   PREFIX=~/.local/bin ./Scripts/uninstall.sh

set -euo pipefail

BINARY_NAME="gherkin-gen"
PREFIX="${PREFIX:-/usr/local/bin}"
TARGET="$PREFIX/$BINARY_NAME"

if [ -f "$TARGET" ]; then
    rm -f "$TARGET"
    echo "Removed $TARGET"
else
    echo "$TARGET not found — nothing to remove."
fi
