#!/bin/bash

# Configuration
APP_NAME="CacheCleaner"
DMG_NAME="${APP_NAME}.dmg"
BUILD_DIR="build"

echo "🚀 Building ${APP_NAME}..."

# Clean and build the app in release mode
xcodebuild -scheme "${APP_NAME}" -configuration Release clean build

# Get the path to the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "${APP_NAME}.app" -path "*/Release/*" -type d)

if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Built app not found"
    exit 1
fi

echo "✅ App built successfully at: ${APP_PATH}"

# Create build directory if it doesn't exist
mkdir -p "${BUILD_DIR}"

echo "📦 Creating DMG..."

# Create DMG
hdiutil create -volname "${APP_NAME}" \
               -srcfolder "${APP_PATH}" \
               -ov -format UDZO \
               "${BUILD_DIR}/${DMG_NAME}"

echo "✨ Done! DMG created at: ${BUILD_DIR}/${DMG_NAME}" 