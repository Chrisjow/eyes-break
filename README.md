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

This compiles the Swift package in release mode and produces `EyeBreak.app` in the current directory.

### 4. Launch

```bash
open EyeBreak.app
```

Or double-click `EyeBreak.app` in Finder.

### 5. Allow notifications (first launch)

macOS will prompt you to allow notifications. Click **Allow** — notifications are used for the 1-minute pre-break warning.

### 6. Install to Applications (optional)

```bash
cp -R EyeBreak.app /Applications/
open /Applications/EyeBreak.app
```

### 7. Launch at login (optional)

Go to **System Settings → General → Login Items** → click **+** and select `EyeBreak.app`.

---

## Rebuilding after code changes

EyeBreak is a compiled Swift app, so **any change to a source file requires a rebuild** before it takes effect.

### Steps

```bash
cd ~/Documents/eyes-break   # or wherever the project lives

# 1. Quit the running app first (menu bar icon → Quit EyeBreak)

# 2. Rebuild
./build.sh

# 3. Relaunch
open EyeBreak.app
```

If you installed it to `/Applications`, copy the new bundle over the old one:

```bash
./build.sh
cp -R EyeBreak.app /Applications/
open /Applications/EyeBreak.app
```

> **Note:** Your settings (break interval, duration) are stored in `UserDefaults` and are not affected by rebuilds.

---

## How to use

### Menu bar icon

EyeBreak lives entirely in the **menu bar** (top-right area of your screen) as an eye icon **👁**. There is no Dock icon.

Click the icon to open the menu:

| Menu item | Description |
|---|---|
| **Next break in X:XX** | Live countdown to the next break |
| **Pause / Resume** | Temporarily stop the timer |
| **Settings…** | Open the settings panel |
| **Quit EyeBreak** | Exit the app |

Hover over the icon at any time to see the countdown in a tooltip without opening the menu.

### Pre-break notification

**1 minute before** each break, a macOS notification appears:

> **Eye Break in 1 Minute**
> Look away from your screen and rest your eyes.

The notification has two action buttons:
- **+1 min** — delay the break by 1 minute
- **+5 min** — delay the break by 5 minutes

If you ignore the notification, the break starts automatically when the timer reaches zero. No confirmation required.

### Break screen

When a break starts, a **full-screen blurred overlay** appears on all connected monitors showing:

- An eye icon and "Eye Break" title
- A reminder to look at something 20 feet away
- A **countdown timer** (counts down to zero)
- A **Skip Break** button to dismiss early

When the countdown reaches zero, the overlay dismisses itself and the interval timer restarts automatically.

### Settings

Open **Settings…** from the menu bar menu (or press **⌘,**):

| Setting | Default | Range |
|---|---|---|
| **Break every** | 20 min | 1–120 min |
| **Break lasts** | 20 sec | 5–300 sec |

After adjusting the values, click **Apply & Reset Timer** to restart the countdown with the new interval. Settings are saved to disk immediately and persist across app restarts.

---

## Project structure

```
eyes-break/
├── Package.swift                    # Swift Package Manager manifest
├── build.sh                         # Build + bundle script
├── Resources/
│   └── Info.plist                   # App metadata (bundle ID, LSUIElement, etc.)
└── Sources/EyeBreak/
    ├── main.swift                   # Entry point
    ├── AppDelegate.swift            # App lifecycle, wires all components
    ├── SettingsManager.swift        # Persistence via UserDefaults
    ├── TimerManager.swift           # Core countdown + break lifecycle
    ├── NotificationManager.swift    # Pre-break notifications + action handling
    ├── MenuBarController.swift      # NSStatusBar icon and menu
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

## Troubleshooting

**The app doesn't appear in the menu bar after launching.**
macOS may have gatekeeper blocked it. Go to **System Settings → Privacy & Security** and click **Open Anyway** next to the EyeBreak entry, then relaunch.

**Notifications don't appear.**
Check **System Settings → Notifications → EyeBreak** and make sure notifications are enabled and the alert style is set to **Alerts** or **Banners**.

**The +1 min / +5 min buttons on notifications don't work.**
Make sure you click the action buttons (not just dismiss the notification). If the app was force-quit and relaunched, notification actions will work again on the next pre-break warning.

**The overlay doesn't cover my second monitor.**
The overlay is created for every screen in `NSScreen.screens` at break time. If you connect a monitor after the app launches, it will be covered on the next break.
