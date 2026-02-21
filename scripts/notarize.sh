#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
APP_NAME="DeepTimer"
VERSION="1.0"

DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Deep Timer Distribution Builder${NC}"
echo "=================================="
echo ""

# Step 1: Build the app
echo -e "${GREEN}Step 1: Building app...${NC}"
"$SCRIPT_DIR/build-app.sh"

# Step 2: Sign the app (requires Developer ID)
echo ""
echo -e "${GREEN}Step 2: Code signing...${NC}"

# Check if Developer ID certificate exists
CERT_NAME=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)"/\1/' || echo "")

if [ -z "$CERT_NAME" ]; then
    echo -e "${RED}⚠️  No Developer ID certificate found${NC}"
    echo "To sign the app, you need to:"
    echo "1. Join the Apple Developer Program"
    echo "2. Create a Developer ID Application certificate"
    echo "3. Install the certificate in your login keychain"
    echo ""
    echo "For now, creating unsigned build..."
    SIGNED=false
else
    echo "Found certificate: $CERT_NAME"

    # Sign the app
    codesign --force --deep --sign "$CERT_NAME" \
        --options runtime \
        --entitlements "$ROOT_DIR/Packaging/entitlements.plist" \
        "$APP_BUNDLE"

    echo "✅ App signed successfully"
    SIGNED=true
fi

# Step 3: Create DMG
echo ""
echo -e "${GREEN}Step 3: Creating DMG installer...${NC}"

mkdir -p "$DIST_DIR"

DMG_NAME="$DIST_DIR/${APP_NAME}-${VERSION}.dmg"
rm -f "$DMG_NAME"

# Create temporary folder
TMP_DIR=$(mktemp -d)
cp -R "$APP_BUNDLE" "$TMP_DIR/"

# Create Applications symlink
ln -s /Applications "$TMP_DIR/Applications"

# Create DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$TMP_DIR" \
    -ov -format UDZO \
    "$DMG_NAME"

# Cleanup
rm -rf "$TMP_DIR"

echo "✅ DMG created: $DMG_NAME"

# Step 4: Notarize (if signed)
if [ "$SIGNED" = true ]; then
    echo ""
    echo -e "${GREEN}Step 4: Notarization...${NC}"
    echo "To notarize, you need an app-specific password from Apple."
    echo ""
    echo "Run this command manually:"
    echo "  xcrun notarytool submit $DMG_NAME \\"
    echo "    --apple-id YOUR_APPLE_ID \\"
    echo "    --password YOUR_APP_SPECIFIC_PASSWORD \\"
    echo "    --team-id YOUR_TEAM_ID \\"
    echo "    --wait"
    echo ""
    echo "After notarization completes, staple the ticket:"
    echo "  xcrun stapler staple $DMG_NAME"
else
    echo ""
    echo -e "${BLUE}ℹ️  Skipping notarization (unsigned build)${NC}"
fi

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo "Distribution file: $DMG_NAME"
echo ""
echo "Next steps:"
echo "1. Test the DMG on a clean Mac"
echo "2. If signed: notarize using the commands above"
echo "3. Upload to your website"
