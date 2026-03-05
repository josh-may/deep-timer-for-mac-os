#!/bin/bash
set -euo pipefail

APP_NAME="DeepTimer"
DMG_NAME="DeepTimer-1.2.dmg"
DMG_URL="https://github.com/josh-may/deep-timer-for-mac-os/releases/download/v1.2/$DMG_NAME"
MOUNT_POINT="/Volumes/$APP_NAME"
INSTALL_DIR="/Applications"
TMP_DMG="/tmp/$DMG_NAME"

echo "Installing $APP_NAME..."

# Kill if running
pkill -x "$APP_NAME" 2>/dev/null || true

# Download
echo "Downloading $APP_NAME..."
curl -fsSL -o "$TMP_DMG" "$DMG_URL"

# Mount
echo "Mounting disk image..."
hdiutil attach "$TMP_DMG" -nobrowse -quiet

# Copy to Applications
echo "Installing to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$MOUNT_POINT/$APP_NAME.app" "$INSTALL_DIR/"

# Unmount and clean up
hdiutil detach "$MOUNT_POINT" -quiet
rm -f "$TMP_DMG"

# Strip quarantine/provenance flags so macOS doesn't block the app after restart
xattr -cr "$INSTALL_DIR/$APP_NAME.app"

echo "Launching $APP_NAME..."
open "$INSTALL_DIR/$APP_NAME.app"

echo "Done! $APP_NAME is running in your menu bar."
