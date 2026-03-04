import AppKit
import SwiftUI
import Combine

final class MenuBarController: NSObject {

    private var statusItem: NSStatusItem!
    private let timerManager: TimerManager
    private let settings: SettingsManager
    private let notifications: NotificationManager
    private var cancellables = Set<AnyCancellable>()
    private var settingsWindow: NSWindow?

    // Persistent menu — built once, items updated in place
    private var menu: NSMenu!
    private var countdownItem: NSMenuItem!   // updated every second while menu is open
    private var pauseItem: NSMenuItem!       // title flips between Pause / Resume
    private var notifWarnItem: NSMenuItem!
    private var notifFixItem: NSMenuItem!

    private var menuUpdateTimer: Timer?

    // MARK: - Init

    init(timerManager: TimerManager, settings: SettingsManager, notifications: NotificationManager) {
        self.timerManager = timerManager
        self.settings = settings
        self.notifications = notifications
        super.init()
        setupStatusItem()
        buildMenu()
        observeTooltip()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "EyeBreak")
            button.image?.isTemplate = true
        }
    }

    /// Build the menu once. Items are mutated in place afterward — no rebuild needed.
    private func buildMenu() {
        menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false

        // --- Countdown (live) ---
        countdownItem = NSMenuItem()
        countdownItem.isEnabled = false
        menu.addItem(countdownItem)

        menu.addItem(.separator())

        // --- Pause / Resume ---
        pauseItem = NSMenuItem(
            title: "Pause",
            action: #selector(togglePause),
            keyEquivalent: "p"
        )
        pauseItem.target = self
        menu.addItem(pauseItem)

        // --- Settings ---
        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        // --- Notification warning (hidden by default, shown when denied) ---
        notifWarnItem = NSMenuItem()
        notifWarnItem.title = "⚠️ Notifications disabled"
        notifWarnItem.isEnabled = false
        notifWarnItem.isHidden = true
        menu.addItem(notifWarnItem)

        notifFixItem = NSMenuItem(
            title: "Enable in System Settings…",
            action: #selector(openNotificationSettings),
            keyEquivalent: ""
        )
        notifFixItem.target = self
        notifFixItem.isHidden = true
        menu.addItem(notifFixItem)

        menu.addItem(.separator())

        // --- Quit ---
        let quitItem = NSMenuItem(
            title: "Quit EyeBreak",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Tooltip (updates while menu is closed)

    private func observeTooltip() {
        Publishers.CombineLatest3(
            timerManager.$timeUntilBreak,
            timerManager.$isPaused,
            timerManager.$isOnBreak
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in self?.updateTooltip() }
        .store(in: &cancellables)
    }

    private func updateTooltip() {
        guard let button = statusItem.button else { return }
        if timerManager.isOnBreak {
            button.toolTip = "EyeBreak — on break"
        } else if timerManager.isPaused {
            button.toolTip = "EyeBreak — paused"
        } else {
            button.toolTip = "EyeBreak — next break in \(formatTime(timerManager.timeUntilBreak))"
        }
    }

    // MARK: - Menu item updates

    private func updateAllItems() {
        // Countdown line
        if timerManager.isOnBreak {
            countdownItem.title = "On break — \(formatTime(timerManager.breakTimeRemaining)) remaining"
        } else if timerManager.isPaused {
            countdownItem.title = "Paused"
        } else {
            countdownItem.title = "Next break in \(formatTime(timerManager.timeUntilBreak))"
        }

        // Pause / Resume label
        pauseItem.title = timerManager.isPaused ? "Resume" : "Pause"

        // Notification warning visibility
        let denied = notifications.isDenied
        notifWarnItem.isHidden = !denied
        notifFixItem.isHidden = !denied
    }

    // MARK: - Actions

    @objc private func togglePause() {
        timerManager.togglePause()
    }

    @objc private func openNotificationSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
        NSWorkspace.shared.open(url)
    }

    @objc private func openSettings() {
        if settingsWindow == nil || !settingsWindow!.isVisible {
            let view = SettingsView(settings: settings, timerManager: timerManager)
            let hosting = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: hosting)
            window.title = "EyeBreak Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 320, height: 220))
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Helpers

    private func formatTime(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let m = total / 60
        let s = total % 60
        return m > 0 ? String(format: "%d:%02d", m, s) : String(format: "0:%02d", s)
    }
}

// MARK: - NSMenuDelegate

extension MenuBarController: NSMenuDelegate {

    func menuWillOpen(_ menu: NSMenu) {
        // Refresh immediately so the first frame is accurate
        updateAllItems()

        // Then tick every second while the menu stays open
        menuUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateAllItems()
        }
        RunLoop.main.add(menuUpdateTimer!, forMode: .common)
    }

    func menuDidClose(_ menu: NSMenu) {
        menuUpdateTimer?.invalidate()
        menuUpdateTimer = nil
    }
}
