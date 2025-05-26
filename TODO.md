# TODO: Planned Features

## Time Machine Management
- [ ] Add Time Machine snapshots viewing
  - Implementation: `tmutil listlocalsnapshots /`
  - UI: List of snapshots with size and date
- [ ] Add snapshot deletion
  - Implementation: `sudo tmutil deletelocalsnapshots`
  - UI: Delete button with confirmation

## System Cleanup
- [ ] System logs cleanup
  - Path: `/private/var/log/*`
  - Add size calculation
  - Add safe cleanup option
- [ ] System cache cleanup
  - Path: `/private/var/folders/*`
  - Add size calculation
  - Add safe cleanup option

## iOS Management
- [ ] iOS backup management
  - Path: `~/Library/Application Support/MobileSync/Backup`
  - Features:
    - List all backups with device names
    - Show backup sizes
    - Show backup dates
    - Option to delete old backups

## User Management
- [ ] User space analysis
  - Path: `/Users/`
  - Features:
    - List all users
    - Show space used by each user
    - Identify inactive users
- [ ] Integration with System Settings
  - Open User & Groups preferences
  - (Note: Direct user deletion requires system privileges)

## General Improvements
- [ ] Add progress indicators for long operations
- [ ] Add detailed error messages
- [ ] Add cleanup scheduling
- [ ] Add cleanup presets
- [ ] Add backup before cleanup option

## Security
- [ ] Add privilege escalation for system operations
- [ ] Add secure deletion option
- [ ] Add operation logging
- [ ] Add undo functionality for deletions

## UI/UX
- [ ] Add dark mode support
- [ ] Add cleanup history
- [ ] Add space saved statistics
- [ ] Add cleanup recommendations
- [ ] Add quick actions menu

## Documentation
- [ ] Add detailed documentation for each cleanup type
- [ ] Add safety warnings
- [ ] Add troubleshooting guide
- [ ] Add FAQ section 