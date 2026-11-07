<!-- // © https://saadbinyousaf.dev/ © // -->
# Changelog

## v1.0.1

### Root
- Rooting now always downloads the release build of Magisk (about 11 MB). Before, it could pick the 35 MB debug build that ships alongside each Magisk release.
- Canary builds are read from Magisk's current update feed again, and debug-only builds are skipped.
- The Magisk picker shows each build's download size.

### Look
- The interface now uses Google Sans Flex, the typeface of Pixel phones and Android, with Google Sans Code in the console.

## v1.0.0

The first public release.

### Devices
- Create virtual devices from any phone or tablet profile Google ships, on Android 11 to 16 and Android 17 previews, with Google Play, Google APIs or 16 KB page images.
- Start, cold boot, stop and delete devices from a Device Manager styled after Android Studio, with row actions, a right-click menu and a Details panel.
- Devices start without console windows and keep running when Droidesk closes.

### Root
- Root while creating a device, or later from the device menu.
- Choose any Stable, Beta or Canary Magisk build from its GitHub releases.
- Rooting runs headless in the background and needs no key presses.
- A missing `ramdisk.img` is repaired automatically before patching.

### Setup and updates
- A setup wizard installs Java, the Android tools and the emulator into the Droidesk folder, with a live log.
- Windows Hypervisor Platform is turned on with a single admin prompt when needed.
- Downloads resume after drops, retry up to five times and stop with a clear message instead of hanging.
- **Update emulator** updates the emulator and adb without touching system images or root.
- **Check for new versions** pulls the current list of system images from Google, including previews.

### Portability
- Everything lives in one folder: `Droidesk.bat`, `core` and `data`.
- Moving the folder or reinstalling Windows keeps every device. Paths, environment variables and the desktop shortcut are repaired on the next start.
