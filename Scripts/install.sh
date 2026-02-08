#!/usr/bin/env bash
# install.sh — Build and install the gherkin-gen CLI tool.
#
# Usage:
#   ./Scripts/install.sh              # installs to /usr/local/bin
#   PREFIX=~/.local/bin ./Scripts/install.sh  # custom prefix
#
# Requirements: Swift 6.2+

set -euo pipefail

BINARY_NAME="gherkin-gen"
PREFIX="${PREFIX:-/usr/local/bin}"
BUILD_DIR=".build/release"

# ---------- Helpers ----------

info()  { echo "==> $*"; }
error() { echo "ERROR: $*" >&2; exit 1; }

# ---------- Platform detection ----------

OS="$(uname -s)"
case "$OS" in
    Darwin) info "Platform: macOS" ;;
    Linux)  info "Platform: Linux" ;;
    *)      error "Unsupported platform: $OS" ;;
esac

# ---------- Swift check ----------

if ! command -v swift &>/dev/null; then
    error "Swift is not installed. Please install Swift 6.2+ first."
fi

SWIFT_VERSION="$(swift --version 2>&1 | head -1)"
info "Swift: $SWIFT_VERSION"

# ---------- Build ----------

info "Building $BINARY_NAME (release)..."
swift build -c release

if [ ! -f "$BUILD_DIR/$BINARY_NAME" ]; then
    error "Build succeeded but binary not found at $BUILD_DIR/$BINARY_NAME"
fi

# ---------- Install ----------

info "Installing to $PREFIX/$BINARY_NAME..."
mkdir -p "$PREFIX"
install -m 755 "$BUILD_DIR/$BINARY_NAME" "$PREFIX/$BINARY_NAME"

# ---------- Verify ----------

VERSION="$("$PREFIX/$BINARY_NAME" --help 2>&1 | head -1 || true)"
info "Installed $BINARY_NAME to $PREFIX/$BINARY_NAME"
info "$VERSION"
echo ""
echo "Run '$BINARY_NAME --help' to get started."
