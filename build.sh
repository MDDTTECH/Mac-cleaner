#!/bin/bash

# Configuration
APP_NAME="CacheCleaner"
DMG_NAME="${APP_NAME}.dmg"
BUILD_DIR="build"

echo "🚀 Creating DMG for ${APP_NAME}..."

# Create build directory if it doesn't exist
mkdir -p "${BUILD_DIR}"

# Copy notarized app to build directory
cp -R "CacheCleaner.app" "${BUILD_DIR}/"

# Create DMG
echo "📦 Creating DMG..."
create-dmg \
  --volname "${APP_NAME}" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "${APP_NAME}.app" 200 190 \
  --hide-extension "${APP_NAME}.app" \
  --app-drop-link 600 185 \
  "${BUILD_DIR}/${DMG_NAME}" \
  "${BUILD_DIR}/"

echo "✨ Done! DMG created at: ${BUILD_DIR}/${DMG_NAME}" 