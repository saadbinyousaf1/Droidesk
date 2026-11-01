<!-- // © https://saadbinyousaf.dev/ © // -->
# FAQ and troubleshooting

## General

**Is Droidesk an emulator?**
No. It sets up and manages Google's official Android Emulator, the same one Android Studio uses, and roots it with rootAVD and Magisk.

**Does it need Android Studio?**
No. It downloads only the command-line tools, the emulator and the system images you choose.

**Is it safe?**
Droidesk is a few PowerShell scripts and one HTML file, so everything it does is readable in this repository. It downloads tools only from their official sources (Google, Adoptium, GitHub, GitLab and NuGet) and sends nothing anywhere else. The app talks to its own engine over `localhost`, protected by a random token. See [SECURITY.md](../SECURITY.md).

**Why does Windows warn about an unknown publisher?**
Windows tags files extracted from a downloaded zip. Unblock the zip before extracting (right-click → Properties → Unblock), or run this once in PowerShell:

```powershell
Get-ChildItem D:\Droidesk -Recurse | Unblock-File
```

Droidesk also unblocks its own files every time it starts.

**A `.ps1` file opened in Notepad.**
That's normal Windows behaviour for PowerShell scripts. Only open `Droidesk.bat` or the desktop shortcut.

## Setup

**Setup says it can't reach Google's servers.**
Check your connection, VPN or firewall. Setup needs `dl.google.com`, `api.adoptium.net`, `github.com` and `www.nuget.org`. Press **Retry** once you're back online.

**A download stopped with "made no progress".**
The connection stalled for several minutes. Press **Retry**. Finished downloads are kept, and interrupted ones resume.

**Windows didn't show the admin prompt.**
Turn on Windows Hypervisor Platform yourself: *Control Panel → Programs → Turn Windows features on or off → Windows Hypervisor Platform*, then restart.

## Devices

**A device closes right after starting.**
Usually virtualization is off in BIOS, or Windows still needs the restart after turning on Hypervisor Platform. Check Task Manager → Performance → CPU → *Virtualization*.

**A device is very slow.**
Give it 4 GB of memory and make sure no other virtualization software is competing for the CPU. Older VirtualBox versions are a common culprit. Laptops should be plugged in.

**The Play Store isn't on my device.**
Only *Google Play* system images include it. Create the device again with a Google Play image.

**Stop doesn't respond.**
Droidesk asks the device to shut down, then closes it forcibly after 8 seconds. If a device is stuck in *Shutting down*, close its emulator window.

## Root

**Rooting failed.**
Open the console log. The most common causes:
- Another device was running. Stop every device and press **Retry**.
- A preview or 16 KB page image. rootAVD may not support these yet. Use Android 15 or 16 with a Google Play image.
- A stale image. Droidesk repairs a missing `ramdisk.img` on its own, either from rootAVD's backup or by downloading the image again.

**Magisk says it needs additional setup.**
Accept it. The device reboots and Magisk is fully installed.

**I rooted one device and another one is rooted too.**
Root lives in the system image, which devices on the same Android version and image type share. To keep a device unrooted, give it a different image type or Android version.

**How do I unroot?**
Delete the image's folder under `data\sdk\system-images` while no device uses it, then create the device again. Droidesk downloads a clean image.

## Reporting a problem

[Open an issue](https://github.com/saadbinyousaf1/Droidesk/issues/new/choose) with your Windows version, the Droidesk version from the status bar, what you did, and the full console log.
