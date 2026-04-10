#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Building Wally..."
swift build -c release

BUILD_DIR=".build/release"
APP_DIR="$BUILD_DIR/Wally.app/Contents"

rm -rf "$BUILD_DIR/Wally.app"
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"
cp "$BUILD_DIR/Wally" "$APP_DIR/MacOS/Wally"
cp "Resources/Info.plist" "$APP_DIR/Info.plist"

codesign --force --sign - "$APP_DIR/MacOS/Wally"
codesign --force --sign - "$BUILD_DIR/Wally.app"
codesign --force --sign - "$BUILD_DIR/wallpaper"

echo ""
echo "Build complete:"
echo "  App: $BUILD_DIR/Wally.app"
echo "  CLI: $BUILD_DIR/wallpaper"
echo ""
echo "Install with:"
echo "  cp -r $BUILD_DIR/Wally.app /Applications/"
echo "  cp $BUILD_DIR/wallpaper ~/.local/bin/"
