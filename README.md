# WebViewScreenSaver
[![Build](https://img.shields.io/github/actions/workflow/status/NextviewConsulting/webviewscreensaver/ci.yml?branch=master)](https://github.com/NextviewConsulting/webviewscreensaver/actions)

> [!NOTE]
> This is Nextview Consulting's security-hardened fork of [liquidx/webviewscreensaver](https://github.com/liquidx/webviewscreensaver). See [Security notes](#security-notes) for what differs from upstream.

A macOS screen saver that displays a web page or a series of web pages.

> [!WARNING]
> If the Options button doesn't do anything on macOS 26 Tahoe close and reopen System Settings. This seems to be an OS-level bug with no known code workaround.

## Installation

Build from source (requires [Xcode](https://developer.apple.com/xcode/)):
``` bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/NextviewConsulting/webviewscreensaver/master/install-from-source.sh)"
```

A locally built screensaver is not quarantined, so Gatekeeper does not need to be bypassed.

**Note**: Release builds of this fork are currently only **ad-hoc signed**. Signing with an Apple Developer ID and notarization will be added once an Apple Developer account is available (`archive.sh` already accepts a `SIGN_IDENTITY`). Until then, prefer building from source over installing a downloaded build, and do not disable Gatekeeper (`--no-quarantine`, `xattr -d com.apple.quarantine`) on managed Macs.

## Configuration

Open up System Preferences > **Desktop and Screen Saver** > Screen Saver and **WebViewScreenSaver** should be at the end of the list.

In the addresses section fill in as many websites as you want the screensaver to cycle through and the amount of time to pause on each.

**Tip**: To edit a **selected** row, click **once** or tap **Enter** or **Tab**.

Passing in a negative time value e.g. `-1` will notify the screensaver to remain on that website indefinitely.

Need some website ideas? Check out suggestions in the [examples](examples.json). (feel free to suggest others)

The example file can also be used with the **fetch URLs** feature: `https://raw.githubusercontent.com/NextviewConsulting/webviewscreensaver/master/examples.json`

The address list URL must use `https://`, and only `https://` entries from a fetched list are used; plain `http://`, `file://` and local paths in a remote list are skipped.

Local **absolute** paths can also be used as an address with or without the `file://` schema.

E.g. `file:///Users/myUser/mySreensaver/index.html`

**Note**: If you are running **Catalina** or newer the provided path cannot reside in your personal folders which require extra permissions (this includes things like *Downloads*, *Documents* or *Desktop*) but can be anywhere else in your user's folder.

### Configuration for IT
If you are interested in scripting configuration changes, WebViewScreenSaver, like most other screensavers, makes use of the macOS `defaults` system.

This can be queried and updated via:
``` bash
/usr/libexec/PlistBuddy -c 'Print' ~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/ByHost/WebViewScreenSaver.*.plist
```

Depending on how it was installed, which macOS version and which architecture you are running you might find the plist under the following paths:
```bash
ls ~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/ByHost/WebViewScreenSaver.*
ls ~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/net.liquidx.WebViewScreenSaver
ls ~/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver-x86_64/Data/Library/Preferences/net.liquidx.WebViewScreenSaver
ls ~/Library/Preferences/ByHost/WebViewScreenSaver.* # Pre macOS 10.15
```

Any .plist editor can be used including built-in `PlistBuddy` and `plutil`.

To keep cookies and logins between runs (off by default in this fork), set the `kScreenSaverPersistWebsiteData` key to `true` in that plist, e.g.:
``` bash
/usr/libexec/PlistBuddy -c 'Add :kScreenSaverPersistWebsiteData bool true' <path to plist>
```

## Security notes

Changes in this fork compared to upstream:

* **Remote address lists are HTTPS only.** The list URL must be `https://`, redirects off HTTPS and non-200 responses are rejected, and only `https://` entries are used. A remote list can no longer load local files.
* **No persistent website data by default.** Pages run in a private (non-persistent) data store, so logins do not stay active indefinitely. Opt in with `kScreenSaverPersistWebsiteData` (see above).
* **Navigation is limited** to `https`, `http`, `file`, `about`, `data` and `blob` URLs, so pages cannot open other apps through custom URL schemes. Fixed a crash when a page tried to open a new window.
* **Safer internals:** secure decoding for table drag-and-drop, no URLs or error text written to the log file, defaults and examples switched to HTTPS.
* **CI hardening:** GitHub Actions pinned to commit SHAs with least-privilege `permissions`.

Things the code cannot fix for you:

* The screensaver also runs while the Mac is **locked**, so anyone near the screen can read the page. Do not show confidential or client data.
* Pages run with full JavaScript. Only add sites you trust.

## License
Code is licensed under the [Apache License, Version 2.0 License](LICENSE.md).
