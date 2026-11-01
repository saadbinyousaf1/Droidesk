<!-- // © https://saadbinyousaf.dev/ © // -->
# User guide

## The window

| Area | What it's for |
| --- | --- |
| **Toolbar** | The selected device, a green ▶ to start it, a red ■ to stop it, **Update emulator** and **Create device**. Click the folder path to open the Droidesk folder. |
| **Device Manager** | Every virtual device with its API level, system image, root status and state. Double-click a row to start it. |
| **Details** | Properties and actions for the selected device. |
| **Console** | Opens by itself while a task runs: the steps on the left and the live log on the right. Toggle it with the console icon on the left edge. |
| **Status bar** | What's happening right now, with a progress bar and **Cancel** while a task runs. |

Keyboard: arrow keys move through the device list, Enter selects, and Escape closes menus and dialogs.

## Devices

### Start and stop

- **Start** resumes from the quick-boot snapshot, so the device is usually back within seconds.
- **Cold Boot Now** does a full restart and ignores the saved state. Use it after rooting, or when a device misbehaves.
- **Stop** shuts the device down and saves its state for the next quick boot. If it doesn't respond within 8 seconds, Droidesk closes it forcibly.

Closing Droidesk doesn't stop running devices. Open Droidesk again any time to manage them.

### Create a device

**Create device** opens the same kind of dialog as Android Studio:

- **Device definition:** the phone or tablet profile, which sets screen size and density.
- **System image:** the Android version and the services that come with it.
  - *Google Play* includes the Play Store. Pick it for everyday apps.
  - *Google APIs* has Google services but no Play Store.
  - *16 KB pages* images are for testing apps on the newer memory page size.
- **Memory** and **Internal storage:** 4 GB of memory and 16 GB of storage suit most uses.

Images marked *Not downloaded* are fetched once and then shared by every device that uses them. **Check for new versions** asks Google for the current list, including previews such as Android 17.

### Root a device

Choose **Root with Magisk...** from the device menu or the Details panel, then pick a Magisk build:

- **Stable:** the recommended choice.
- **Beta:** newer, tested features.
- **Canary:** the latest development build.

Droidesk boots the device in the background, patches its system image with rootAVD and shuts it down again. When it's done, cold boot the device and finish setup in the Magisk app.

Rooting patches the **system image**, not just one device. Every device built on the same Android version and image type is rooted too. To have a rooted and an unrooted device side by side, use different image types or Android versions for them.

### Delete a device

**Delete** removes the device and everything on it. The system image stays, so other devices aren't affected.

## Updating

**Update emulator** updates the Android Emulator and adb. Stop every device first. System images, root and your devices are never touched by an update.

To update Droidesk itself, download the new release and copy its `Droidesk.bat` and `core` folder over your existing ones. Leave the `data` folder alone.

## Backing up and moving

Everything lives in the Droidesk folder:

```
Droidesk/
├─ Droidesk.bat
├─ core/     the app
└─ data/     emulator, system images, your devices, Java, Magisk
```

- **Back up:** stop all devices and copy the folder somewhere safe. To back up only your devices, copy `data\avd`.
- **Move:** stop all devices, move the folder, and open `Droidesk.bat` from the new place. Device paths, environment variables and the shortcut are fixed up automatically.
- **Reinstall Windows:** keep the folder, then open `Droidesk.bat` afterwards. Droidesk restores its environment variables and desktop shortcut, and if Windows Hypervisor Platform is off again, it shows the setup wizard. Press **Install**: nothing is downloaded again, it only asks once for admin rights and a restart.

## For developers

Droidesk runs Google's standard emulator, so your usual tools work with it:

- **adb** lives at `data\sdk\platform-tools\adb.exe`. Running devices show up in `adb devices` as `emulator-5554`, `emulator-5556` and so on.
- **Android Studio, VS Code, Flutter and React Native** find the SDK and running devices, because setup points `ANDROID_HOME` and `ANDROID_SDK_ROOT` at Droidesk's SDK.
- **From a terminal**, start a device with `data\sdk\emulator\emulator.exe -avd <name>` while `ANDROID_AVD_HOME` points at `data\avd`.
- **Root access:** on rooted devices, `adb shell su` works. Magisk asks for permission on the device.
