# CacheCleaner for macOS

A powerful and user-friendly application for managing cache files on macOS. This tool helps you monitor and clean various types of caches to free up disk space.

![CacheCleaner Screenshot](screenshots/main.png)

## Features

- 📊 Display total cache size
- 📋 Show top 10 largest cache directories
- 🔍 Detailed Xcode cache information:
  - DerivedData
  - iOS Device Support
  - Archives
  - CoreSimulator
- 🗑️ One-click cache cleaning
- 🔄 Real-time size updates
- 👀 Clear and intuitive interface
- 🔒 Signed and notarized by Apple

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

1. Launch CacheCleaner from your Applications folder
2. The app will automatically scan and display cache sizes
3. Click on specific cache types to see detailed information
4. Use the "Clean" button to remove selected cache types
5. The app will show real-time progress during cleaning

## Cache Types

### General Caches
- Application caches (`~/Library/Caches`)
- System caches
- Third-party application caches

### Xcode Caches
- **DerivedData**: Build outputs and intermediate files
- **iOS Device Support**: Debug symbols and device support files
- **Archives**: Application archives
- **CoreSimulator**: iOS Simulator caches

## Security

CacheCleaner is designed with security in mind:
- Only accesses standard cache locations
- Requires explicit user confirmation before cleaning
- Never modifies system files
- All operations are logged and reversible

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

## Disclaimer

Please use this tool carefully. Clearing certain caches may:
- Require application restarts
- Cause temporary slowdowns during cache rebuilding
- Require rebuilding of Xcode projects (DerivedData)
- Need simulator reinitialization
- Require device resynchronization (iOS Device Support)

Always ensure you understand which caches you are clearing and their implications.


