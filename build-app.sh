#!/bin/bash
set -e

echo "🔨 Building Deep Timer..."
swift build -c release

echo "📦 Creating .app bundle..."
APP_DIR="DeepTimer.app/Contents/MacOS"
RESOURCES_DIR="DeepTimer.app/Contents/Resources"
mkdir -p "$APP_DIR"
mkdir -p "$RESOURCES_DIR"

echo "📋 Copying files..."
cp .build/release/DeepTimer "$APP_DIR/"
cp Info.plist DeepTimer.app/Contents/
cp AppIcon.icns "$RESOURCES_DIR/"

# Copy resource bundle
if [ -d ".build/arm64-apple-macosx/release/DeepTimer_DeepTimer.bundle" ]; then
    cp -r .build/arm64-apple-macosx/release/DeepTimer_DeepTimer.bundle "$RESOURCES_DIR/"
    echo "✅ Resources copied"
fi

echo "✅ Done! App created at: DeepTimer.app"
echo ""
echo "To run:"
echo "  open DeepTimer.app"
echo ""
echo "To install:"
echo "  cp -r DeepTimer.app /Applications/"
