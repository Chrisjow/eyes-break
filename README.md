# EyeBreak

A lightweight macOS menu bar app that reminds you to take regular eye breaks, following the [20-20-20 rule](https://www.aao.org/eye-health/tips-prevention/computer-usage): every 20 minutes, look at something 20 feet away for 20 seconds.

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools (for `swift build`)

## Installation

### 1. Install Xcode Command Line Tools

If you don't already have them:

```bash
xcode-select --install
```

### 2. Clone or download the project

```bash
git clone <repo-url> ~/Documents/eyes-break
cd ~/Documents/eyes-break
```

Or simply place the project folder wherever you like and `cd` into it.

### 3. Build

```bash
chmod +x build.sh
./build.sh
```

This compiles the Swift package in release mode, packages it as `EyeBreak.app`, and ad-hoc signs it (required for notifications on macOS 13+).

### 4. Launch

```bash
open EyeBreak.app
```

Or double-click `EyeBreak.app` in Finder.

### 5. Allow notifications (first launch)

macOS will prompt you to allow notifications. Click **Allow** — notifications are used for the 1-minute pre-break warning.

### 6. Set notification style to Alerts (recommended)

By default macOS uses "Banners" which auto-dismiss after a few seconds. For persistent notifications that stay until you interact with them:

**System Settings → Notifications → EyeBreak → Alert Style → Alerts**

You can also reach this directly from the app menu: **Set Notifications to Alerts…**

### 7. Install to Applications (optional)

```bash
cp -R EyeBreak.app /Applications/
open /Applications/EyeBreak.app
```

### 8. Launch at login (optional)

Go to **System Settings → General → Login Items** → click **+** and select `EyeBreak.app`.

---

## Rebuilding after code changes

EyeBreak is a compiled Swift app, so **any change to a source file requires a rebuild** before it takes effect.

```bash
cd ~/Documents/eyes-break   # or wherever the project lives

# 1. Quit the running app first (menu bar icon → Quit EyeBreak)

# 2. Rebuild and relaunch
./build.sh && open EyeBreak.app
```

If you installed it to `/Applications`:

```bash
./build.sh
cp -R EyeBreak.app /Applications/
open /Applications/EyeBreak.app
```

> **Note:** Your settings (break interval, duration) are stored in `UserDefaults` and are not affected by rebuilds.

---

## How to use

### Menu bar icon

EyeBreak lives entirely in the **menu bar** (top-right area of your screen) as an eye icon **👁**. There is no Dock icon. The countdown updates live while the menu is open.

Click the icon to open the menu:

| Menu item | Description |
|---|---|
| **Next break in X:XX** | Live countdown to the next break |
| **Break Now** | Start a break immediately (⌘B) |
| **Delay +1 min** | Push the next break back by 1 minute |
| **Delay +5 min** | Push the next break back by 5 minutes |
| **Pause / Resume** | Temporarily stop the timer |
| **Settings…** | Open the settings panel |
| **Set Notifications to Alerts…** | Opens System Settings to make notifications persistent |
| **Quit EyeBreak** | Exit the app |

Hover over the icon at any time to see the countdown in a tooltip without opening the menu.

### Pre-break notification

**1 minute before** each break, a macOS notification appears:

> **Eye Break in 1 Minute**
> Look away from your screen and rest your eyes.

The notification has two action buttons:
- **+1 min** — delay the break by 1 minute
- **+5 min** — delay the break by 5 minutes

You can also delay the break from the menu bar without waiting for the notification (see **Delay +1 min** / **Delay +5 min** above).

If you ignore the notification, the break starts automatically when the timer reaches zero. No confirmation required.

> **Tip:** Set the notification style to **Alerts** (see Installation step 6) so the notification stays on screen until you interact with it.

### Break screen

When a break starts, a **full-screen blurred overlay** appears on all connected monitors showing:

- An eye icon and "Eye Break" title
- A reminder to look at something 20 feet away
- A **countdown timer** (counts down to zero)
- A **Skip Break** button to dismiss early

When the countdown reaches zero, the overlay dismisses itself and the interval timer restarts automatically.

### Screen lock

When you lock your screen (Ctrl+Cmd+Q or closing the lid), EyeBreak assumes you stepped away and took a natural break. The countdown resets to the full interval when your screen unlocks.

### Settings

Open **Settings…** from the menu bar menu (or press **⌘,**):

| Setting | Default | Range |
|---|---|---|
| **Break every** | 20 min | 1–120 min |
| **Break lasts** | 20 sec | 5–300 sec |

You can type a value directly into the field or use the **+/−** arrows. Click **Apply & Reset Timer** to restart the countdown with the new interval. Settings are saved to disk immediately and persist across app restarts.

---

## Project structure

```
eyes-break/
├── Package.swift                    # Swift Package Manager manifest
├── build.sh                         # Build, bundle, and ad-hoc sign script
├── Resources/
│   └── Info.plist                   # App metadata (bundle ID, LSUIElement, etc.)
└── Sources/EyeBreak/
    ├── main.swift                   # Entry point
    ├── AppDelegate.swift            # App lifecycle, wires all components
    ├── SettingsManager.swift        # Persistence via UserDefaults
    ├── TimerManager.swift           # Core countdown + break lifecycle
    ├── NotificationManager.swift    # Pre-break notifications + action handling
    ├── MenuBarController.swift      # NSStatusBar icon and live menu
    ├── BreakOverlayWindow.swift     # Full-screen NSWindow (screen-saver level)
    ├── BreakOverlayView.swift       # SwiftUI countdown and skip button
    └── SettingsView.swift           # SwiftUI settings panel
```

---

## Permissions

EyeBreak requests only one permission:

- **Notifications** — to show the 1-minute pre-break warning with delay actions.

No accessibility permissions, no screen recording, no network access.

---

## Security

EyeBreak is designed to be safe to share and run in a professional environment.

**No network access.** The app imports no networking framework and makes no outbound connections. The only URL it opens is a local `x-apple.systempreferences:…` scheme that launches System Settings on your own machine.

**No external dependencies.** `Package.swift` has zero third-party packages. The app is built entirely from Apple's own SDKs.

**Minimal data storage.** The only data written to disk is two `UserDefaults` values — break interval and break duration — stored in `~/Library/Preferences/com.eyebreak.app.plist`. Nothing else is read or written.

**No sensitive permissions.** The app does not request accessibility, screen recording, camera, microphone, contacts, location, or file system access.

**No remote attack surface.** The app accepts no network input, so there is nothing to exploit remotely. The only external signal it reacts to is `com.apple.screenIsUnlocked`, a system-level notification broadcast by macOS itself.

**Ad-hoc signed.** The binary is signed with an ad-hoc identity (`-`) rather than an Apple Developer certificate. macOS Gatekeeper will show a warning on first launch — go to **System Settings → Privacy & Security → Open Anyway** to approve it. This is a distribution method gate, not a flaw in the app.

---

## Troubleshooting

**The app doesn't appear in the menu bar after launching.**
macOS may have Gatekeeper blocked it. Go to **System Settings → Privacy & Security** and click **Open Anyway** next to the EyeBreak entry, then relaunch.

**The notification permission dialog never appeared.**
The permission may have been recorded as denied from a previous run. Reset it and relaunch:
```bash
tccutil reset UserNotifications com.eyebreak.app
open EyeBreak.app
```

**Notifications don't appear.**
Check **System Settings → Notifications → EyeBreak** and make sure notifications are enabled. Use the **Set Notifications to Alerts…** menu item to open the right settings pane directly.

**The notification disappears too quickly.**
Change the alert style to **Alerts** (not Banners) in **System Settings → Notifications → EyeBreak**. Alerts stay on screen until you dismiss them.

**The +1 min / +5 min buttons on notifications don't work.**
Make sure you click the action buttons (not just dismiss the notification). You can also use **Delay +1 min** / **Delay +5 min** directly from the menu bar menu.

**The overlay doesn't cover my second monitor.**
The overlay is created for every screen in `NSScreen.screens` at break time. If you connect a monitor after the app launches, it will be covered on the next break.
