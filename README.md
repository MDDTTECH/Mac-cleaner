# CacheCleaner for macOS

A powerful and user-friendly application for managing cache files on macOS. This tool helps you monitor and clean various types of caches to free up disk space with **granular control** over Xcode caches.

![CacheCleaner Screenshot](screenshots/main.png)

## ✨ Key Features

- 📊 **Dual Size Display**: Total cache size + dedicated Xcode cache size
- 📋 **Top 10 Largest Caches**: Quick overview of biggest space consumers
- 🔍 **Detailed Xcode Cache Management**:
  - **DerivedData**: Individual project cache control with build info
  - **iOS Device Support**: Per-device debug symbols with iOS versions
  - **Archives**: Application archives with version and build numbers
  - **CoreSimulator**: Safe simulator cache cleaning (preserves app data)
- 🎯 **Granular Control**: Delete specific items instead of bulk operations
- 🗑️ **Smart Cleaning**: One-click cleaning with detailed confirmations
- 🔄 **Real-time Updates**: Live progress indicators and size updates
- 👀 **Intuitive Interface**: Collapsible lists with detailed information
- 🔒 **Secure**: Signed and notarized by Apple

## System Requirements

- macOS 14.0 or later
- At least 50MB of free disk space

## Installation

1. Download the latest version from the [Releases](https://github.com/yourusername/CacheCleaner/releases) page
2. Double-click the downloaded DMG file
3. Drag CacheCleaner to your Applications folder
4. Launch CacheCleaner from Applications

### Updating
When updating to a new version:
1. Quit CacheCleaner if it's running
2. Download the new version
3. Replace the old version in your Applications folder

## Usage

1. **Launch CacheCleaner** from your Applications folder
2. **Automatic Scan**: The app scans and displays cache sizes automatically
3. **Explore Details**: Click on collapsible sections to see detailed breakdowns:
   - **DerivedData**: View individual projects with build info and last access dates
   - **iOS Device Support**: See specific devices (iPhone 13 Pro, iPhone 15 Pro) with iOS versions
   - **Archives**: Browse application archives with version numbers and build dates
   - **CoreSimulator**: Review simulator cache sizes (app data preserved)
4. **Selective Cleaning**: Choose specific items to delete instead of bulk operations
5. **Confirm & Clean**: Review detailed information before confirming deletion
6. **Progress Tracking**: Watch real-time progress indicators during cleaning
7. **Automatic Refresh**: Cache sizes update automatically after cleaning

## Cache Types

### General Caches
- **Application caches** (`~/Library/Caches`)
- **System caches**
- **Third-party application caches**

### Xcode Caches (Detailed Control)

#### 📁 DerivedData - Build Cache
- **What it contains**: Build outputs, intermediate files, indexes
- **Granular control**: Delete individual project caches
- **Information shown**: Project name, workspace path, last access date, size
- **Safe to delete**: Yes, but project will rebuild on next Xcode launch

#### 📱 iOS Device Support - Debug Symbols
- **What it contains**: Debug symbols for physical devices
- **Granular control**: Delete symbols for specific devices and iOS versions
- **Information shown**: Device model (iPhone 13 Pro, iPhone 15 Pro), iOS version, build number, size
- **Safe to delete**: Yes, symbols will re-download when device is connected

#### 📦 Archives - Application Archives
- **What it contains**: Built application archives for distribution
- **Granular control**: Delete individual application archives
- **Information shown**: App name, bundle ID, version, build number, creation date, size
- **Safe to delete**: Yes, but you'll lose those specific build archives

#### 🎮 CoreSimulator - Simulator Caches
- **What it contains**: System caches and temporary files (NOT app data)
- **Granular control**: Clean only system caches, preserve simulator data
- **Information shown**: Total cache size
- **Safe to delete**: Yes, only removes system caches, preserves installed apps and user data

## Security & Safety

CacheCleaner is designed with security and safety in mind:
- **Standard Locations Only**: Only accesses standard cache locations
- **Explicit Confirmation**: Requires detailed confirmation before any cleaning operation
- **System File Protection**: Never modifies system files or critical data
- **Detailed Warnings**: Shows exactly what will be deleted and potential consequences
- **Granular Control**: Delete only what you specifically choose
- **Data Preservation**: CoreSimulator cleaning preserves simulator app data
- **Reversible Operations**: All operations are logged and can be understood

## Troubleshooting

If you encounter issues:

1. **App won't open**
   - Make sure you're running macOS 14.0 or later
   - Try moving the app to a different folder and back to Applications

2. **Permission Issues**
   - Check System Settings → Privacy & Security
   - Look for CacheCleaner in Full Disk Access
   - Enable if requested

3. **Other Issues**
   - Check the Console app for any error messages
   - Contact support with the error details

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with SwiftUI
- Uses System Commands for accurate cache size calculation
- Implements Apple's security guidelines

## Support

For support, please open an issue in the GitHub repository or contact the maintainers.

## ⚠️ Important Notes

Please use this tool carefully. Different cache types have different implications:

### DerivedData Cleaning
- ✅ **Safe**: Project will rebuild on next Xcode launch
- ⏱️ **Impact**: First build after cleaning will be slower
- 🔄 **Recovery**: Automatic rebuild, no data loss

### iOS Device Support Cleaning
- ✅ **Safe**: Debug symbols will re-download when device connects
- 📱 **Impact**: Debugging on physical devices may be less detailed initially
- 🔄 **Recovery**: Automatic re-download, no data loss

### Archives Cleaning
- ⚠️ **Consider**: You'll lose specific build archives
- 📦 **Impact**: Cannot distribute those specific builds
- ❌ **Recovery**: Archives cannot be recovered, rebuild required

### CoreSimulator Cleaning
- ✅ **Safe**: Only removes system caches
- 🎮 **Preserved**: Installed apps, user data, simulator settings
- 🔄 **Recovery**: System caches rebuild automatically

### General Cache Cleaning
- ✅ **Safe**: Only removes cache files
- 🔄 **Impact**: Applications may rebuild caches on next launch
- ⏱️ **Recovery**: Automatic cache rebuilding

**Always review the detailed information before confirming any deletion.**

## 💡 Use Cases

### For iOS Developers
- **Clean old device symbols**: Remove debug symbols for devices you no longer use
- **Free up DerivedData**: Delete build caches for completed projects
- **Archive management**: Remove old app archives to save space
- **Simulator optimization**: Clean simulator caches while preserving app data

### For Mac Developers
- **Project cleanup**: Remove DerivedData for archived projects
- **Build optimization**: Clean build caches for faster rebuilds
- **Storage management**: Identify and remove largest cache consumers

### For System Administrators
- **Bulk cleanup**: Use top 10 caches list to identify space hogs
- **Selective cleaning**: Choose specific cache types based on user needs
- **Monitoring**: Track cache growth over time

## 🚀 What's New

### Latest Version Features
- **Granular Control**: Delete individual items instead of bulk operations
- **Detailed Information**: See device models, app versions, build numbers
- **Smart Cleaning**: CoreSimulator preserves app data, only removes system caches
- **Dual Size Display**: Separate indicators for total caches and Xcode-specific caches
- **Enhanced Safety**: Detailed confirmations with specific warnings
- **Better UX**: Collapsible lists with progress indicators


