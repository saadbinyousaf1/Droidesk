<!-- // © https://saadbinyousaf.dev/ © // -->
# Security policy

## How Droidesk handles your machine

- **Local only.** The engine listens on `localhost` on a random port. Every API request must carry a random token that's generated at each start and only passed to the app window.
- **Official sources only.** Downloads come from `dl.google.com` (Android SDK), `api.adoptium.net` (Java), `github.com` and `raw.githubusercontent.com` (Magisk), `gitlab.com` (rootAVD) and `www.nuget.org` (WebView2 libraries).
- **No telemetry.** Droidesk doesn't collect or send any data about you or your devices.
- **Admin rights only when needed.** Admin rights are requested once, to turn on Windows Hypervisor Platform, through the standard Windows prompt.
- **No changes outside its folder,** apart from four user environment variables (`ANDROID_HOME`, `ANDROID_SDK_ROOT`, `ANDROID_AVD_HOME`, `ANDROID_USER_HOME`), the desktop shortcut and the Hypervisor Platform feature.

Rooted devices run with Magisk. Treat a rooted emulator like any rooted device, and only grant root to apps you trust.

## Supported versions

Security fixes go into the latest release.

## Reporting a vulnerability

Please don't open a public issue for security problems. Report them privately through [GitHub security advisories](https://github.com/saadbinyousaf1/Droidesk/security/advisories/new) with steps to reproduce. You'll get a reply within a week.
