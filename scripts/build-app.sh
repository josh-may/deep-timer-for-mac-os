#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="DeepTimer"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"
SPM_BUILD_DIR="$ROOT_DIR/.build/spm-release"

echo "🔨 Building Deep Timer..."
swift build -c release --scratch-path "$SPM_BUILD_DIR"
BIN_DIR="$(swift build -c release --show-bin-path --scratch-path "$SPM_BUILD_DIR")"

echo "📦 Creating .app bundle..."
mkdir -p "$DIST_DIR"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_DIR" "$RESOURCES_DIR"

echo "📋 Copying files..."
cp "$BIN_DIR/$APP_NAME" "$APP_DIR/"
cp "$ROOT_DIR/Packaging/Info.plist" "$APP_BUNDLE/Contents/"
cp "$ROOT_DIR/Packaging/AppIcon.icns" "$RESOURCES_DIR/"

# Copy resource bundle
RESOURCE_BUNDLE="$(find "$BIN_DIR" -maxdepth 1 -type d -name "${APP_NAME}_${APP_NAME}.bundle" -print -quit)"

if [ -n "$RESOURCE_BUNDLE" ]; then
    cp -R "$RESOURCE_BUNDLE" "$RESOURCES_DIR/"
    echo "✅ Resources copied"
else
    echo "⚠️  Resource bundle not found"
fi

# Ad-hoc sign the entire bundle so macOS treats it as a valid app
echo "🔏 Signing app bundle..."
codesign --force --deep -s - "$APP_BUNDLE"

echo "✅ Done! App created at: $APP_BUNDLE"
echo ""
echo "To run:"
echo "  open $APP_BUNDLE"
echo ""
echo "To install:"
echo "  cp -r $APP_BUNDLE /Applications/"
