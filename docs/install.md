<!-- // © https://saadbinyousaf.dev/ © // -->
# Installation

Droidesk installs nothing outside its own folder. Setup takes about 10 minutes on a normal connection, most of it downloading.

## Before you start

**Turn on virtualization.** The emulator needs Intel VT-x or AMD-V (also called SVM). Open Task Manager → Performance → CPU and look for **Virtualization: Enabled**. If it says Disabled, turn it on in your BIOS/UEFI settings. The option is usually under *Advanced* or *CPU Configuration*.

**Pick a folder without spaces.** For example `D:\Droidesk`. Use a drive you don't format when reinstalling Windows if you want your devices to survive a reinstall.

## Download and extract

1. Download `Droidesk-vX.Y.Z.zip` from the [latest release](https://github.com/saadbinyousaf1/Droidesk/releases/latest).
2. Right-click the zip, choose **Properties**, tick **Unblock** at the bottom and press **OK**.
   This stops Windows from showing an *Unknown Publisher* warning for every file.
3. Extract it. You get this:

```
Droidesk/
├─ Droidesk.bat    the only file you open
└─ core/           the app
```

## First run

1. Open `Droidesk.bat`. The **Droidesk Setup Wizard** appears.
2. Press **Install**. Droidesk downloads, into `Droidesk\data`:

   | Component | Size |
   | --- | --- |
   | Java 21 (portable) | 190 MB |
   | Android SDK Command-line Tools | 150 MB |
   | Android Emulator | 350 MB |
   | Android SDK Platform-Tools | 10 MB |

3. If **Windows Hypervisor Platform** is off, Windows shows one admin prompt to turn it on. Accept it. Droidesk then asks you to restart Windows once.
4. After the restart, open Droidesk again from the desktop shortcut it created.

If the connection drops during setup, Droidesk retries on its own. If it gives up, press **Retry**. Anything already downloaded is kept.

## Create your first device

1. Press **Create device**.
2. Pick a **device definition** on the left, for example *Pixel 8*.
3. Pick a **system image** on the right. *Android 15, Google Play* is a good default and the most reliable to root.
4. Set the name, memory and storage.
5. Keep **Root with Magisk** ticked and leave the recommended Magisk version selected.
6. Press **Finish**.

The console at the bottom shows the image downloading (1 to 1.5 GB), the device being built, a first boot in the background and Magisk being patched in.

## Finish Magisk setup

Once rooting is done:

1. Open the menu on the device (⋮ or right-click) and choose **Cold Boot Now**.
2. Open the **Magisk** app on the device. If it asks for additional setup, accept it and let the device reboot.
3. Magisk now shows as installed, and apps that ask for root get a Magisk prompt.

## Uninstall

Close Droidesk and stop every device, then delete the Droidesk folder and the **Droidesk** shortcut on your desktop. Setup also set four user environment variables (`ANDROID_HOME`, `ANDROID_SDK_ROOT`, `ANDROID_AVD_HOME`, `ANDROID_USER_HOME`). Remove them from *Settings → System → About → Advanced system settings → Environment Variables* if no other tool uses them.
