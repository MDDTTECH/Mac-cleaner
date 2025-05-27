#!/bin/bash

# Configuration
APP_NAME="CacheCleaner"
DMG_NAME="${APP_NAME}.dmg"
VOLUME_NAME="${APP_NAME}"
BUILD_DIR=$(xcodebuild -project ${APP_NAME}.xcodeproj -showBuildSettings | grep "BUILT_PRODUCTS_DIR" | awk '{print $3}')
SOURCE_PATH="${BUILD_DIR}/${APP_NAME}.app"
DMG_PATH="./build/${DMG_NAME}"
TMP_DMG_PATH="./build/${APP_NAME}_tmp.dmg"
BACKGROUND_PATH="./build-resources/background.png"

# Clean up any existing files
rm -f "${DMG_PATH}" "${TMP_DMG_PATH}"

# Ensure build directory exists
mkdir -p ./build

# Build the app in release mode
echo "Building app in release mode..."
xcodebuild -scheme "${APP_NAME}" -configuration Release clean build

# Wait for the build to complete and verify the app exists
if [ ! -d "${SOURCE_PATH}" ]; then
    echo "Error: Built app not found at ${SOURCE_PATH}"
    exit 1
fi

# Create a temporary DMG
echo "Creating temporary DMG..."
hdiutil create -size 100m -fs HFS+ -volname "${VOLUME_NAME}" "${TMP_DMG_PATH}"

# Mount the temporary DMG
echo "Mounting temporary DMG..."
MOUNT_PATH=$(hdiutil attach -nobrowse -noverify "${TMP_DMG_PATH}" | grep '/Volumes/' | sed 's/.*\/Volumes\//\/Volumes\//')

# Copy the app to the DMG
echo "Copying app to DMG..."
echo "Source path: ${SOURCE_PATH}"
echo "Destination path: ${MOUNT_PATH}/"
cp -R "${SOURCE_PATH}" "${MOUNT_PATH}/"

# Create Applications symlink
echo "Creating Applications symlink..."
ln -s /Applications "${MOUNT_PATH}/Applications"

# Set custom icon and background (optional)
# cp ./build-resources/background.png "${MOUNT_PATH}/.background.png"
# osascript ./build-resources/customize-dmg.applescript

# Unmount the temporary DMG
echo "Unmounting temporary DMG..."
hdiutil detach "${MOUNT_PATH}"

# Convert the temporary DMG to the final compressed DMG
echo "Creating final compressed DMG..."
hdiutil convert "${TMP_DMG_PATH}" -format UDZO -o "${DMG_PATH}"

# Clean up
echo "Cleaning up..."
rm "${TMP_DMG_PATH}"

echo "DMG created at ${DMG_PATH}" 