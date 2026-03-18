#!/bin/bash
set -euo pipefail

APP_NAME="DeepTimer"
INSTALL_DIR="/Applications"
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd || true)"
BUILD_ROOT=""
TEMP_ROOT=""

find_repo_root() {
  local dir="${1:-$PWD}"

  while [ "$dir" != "/" ]; do
    if [ -f "$dir/Package.swift" ] && [ -x "$dir/scripts/build-app.sh" ]; then
      printf '%s\n' "$dir"
      return 0
    fi

    dir="$(dirname "$dir")"
  done

  return 1
}

cleanup() {
  if [ -n "$TEMP_ROOT" ] && [ -d "$TEMP_ROOT" ]; then
    rm -rf "$TEMP_ROOT"
  fi
}

trap cleanup EXIT

if [ -n "$SCRIPT_ROOT" ] && [ -f "$SCRIPT_ROOT/Package.swift" ] && [ -x "$SCRIPT_ROOT/scripts/build-app.sh" ]; then
  BUILD_ROOT="$SCRIPT_ROOT"
elif BUILD_ROOT="$(find_repo_root "$PWD")"; then
  :
else
  TEMP_ROOT="$(mktemp -d)"
  ARCHIVE_PATH="$TEMP_ROOT/deep-timer-main.tar.gz"

  echo "Downloading latest source..."
  curl -fsSL -o "$ARCHIVE_PATH" "https://github.com/josh-may/deep-timer-for-mac-os/archive/refs/heads/main.tar.gz"

  echo "Extracting source..."
  tar -xzf "$ARCHIVE_PATH" -C "$TEMP_ROOT"
  BUILD_ROOT="$(find "$TEMP_ROOT" -mindepth 1 -maxdepth 1 -type d -name 'deep-timer-for-mac-os-*' -print -quit)"

  if [ -z "$BUILD_ROOT" ]; then
    echo "Failed to locate extracted source directory." >&2
    exit 1
  fi
fi

echo "Building $APP_NAME..."
bash "$BUILD_ROOT/scripts/build-app.sh"

echo "Installing to $INSTALL_DIR..."
pkill -x "$APP_NAME" 2>/dev/null || true
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$BUILD_ROOT/dist/$APP_NAME.app" "$INSTALL_DIR/"

echo "Finalizing app bundle..."
xattr -cr "$INSTALL_DIR/$APP_NAME.app"
codesign --force --deep -s - "$INSTALL_DIR/$APP_NAME.app"

echo "Launching $APP_NAME..."
open "$INSTALL_DIR/$APP_NAME.app"

echo "Done! $APP_NAME is running in your menu bar."
