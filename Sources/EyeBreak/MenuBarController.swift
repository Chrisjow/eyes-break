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

    // MARK: - Init

    init(timerManager: TimerManager, settings: SettingsManager, notifications: NotificationManager) {
        self.timerManager = timerManager
        self.settings = settings
        self.notifications = notifications
        super.init()
        setupStatusItem()
        observeState()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "EyeBreak")
            button.image?.isTemplate = true  // Adapts to dark/light menu bar
            button.action = #selector(handleClick)
            button.target = self
        }
    }

    private func observeState() {
        // Refresh tooltip whenever any relevant state changes
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

    // MARK: - Menu

    @objc private func handleClick() {
        // Build a fresh menu each click so times are current
        let menu = buildMenu()
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        // --- Status line ---
        let statusItem = NSMenuItem()
        if timerManager.isOnBreak {
            statusItem.title = "On break — \(formatTime(timerManager.breakTimeRemaining)) remaining"
        } else if timerManager.isPaused {
            statusItem.title = "Paused"
        } else {
            statusItem.title = "Next break in \(formatTime(timerManager.timeUntilBreak))"
        }
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        menu.addItem(.separator())

        // --- Pause / Resume ---
        let pauseItem = NSMenuItem(
            title: timerManager.isPaused ? "Resume" : "Pause",
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

        // --- Notification warning (shown only when permission was denied) ---
        if notifications.isDenied {
            let warnItem = NSMenuItem()
            warnItem.title = "⚠️ Notifications disabled"
            warnItem.isEnabled = false
            menu.addItem(warnItem)

            let fixItem = NSMenuItem(
                title: "Enable in System Settings…",
                action: #selector(openNotificationSettings),
                keyEquivalent: ""
            )
            fixItem.target = self
            menu.addItem(fixItem)
        }

        menu.addItem(.separator())

        // --- Quit ---
        let quitItem = NSMenuItem(
            title: "Quit EyeBreak",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        return menu
    }

    // MARK: - Actions

    @objc private func openNotificationSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
        NSWorkspace.shared.open(url)
    }

    @objc private func togglePause() {
        timerManager.togglePause()
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
        if m > 0 {
            return String(format: "%d:%02d", m, s)
        } else {
            return String(format: "0:%02d", s)
        }
    }
}
