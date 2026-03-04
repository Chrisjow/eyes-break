import Foundation
import Combine
import AppKit

// MARK: - Notification delegate protocol

protocol NotificationResponder: AnyObject {
    func delayBreak(by minutes: Double)
}

// MARK: - TimerManager

final class TimerManager: ObservableObject {

    // MARK: Published state

    @Published private(set) var timeUntilBreak: TimeInterval
    @Published private(set) var breakTimeRemaining: TimeInterval = 0
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var isOnBreak: Bool = false

    // MARK: Dependencies

    let settings: SettingsManager
    private weak var notifications: NotificationManager?

    // MARK: Private

    private var mainTimer: Timer?
    private var breakTimer: Timer?
    private var preBreakNotificationSent: Bool = false
    private var overlayWindows: [BreakOverlayWindow] = []

    // MARK: Init

    init(settings: SettingsManager, notifications: NotificationManager) {
        self.settings = settings
        self.notifications = notifications
        self.timeUntilBreak = settings.breakInterval * 60
        startMainTimer()
    }

    // MARK: - Main countdown

    private func startMainTimer() {
        mainTimer?.invalidate()
        preBreakNotificationSent = false
        mainTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.mainTick()
        }
        // .common ensures the timer fires during tracking loops (e.g. menu open)
        RunLoop.main.add(mainTimer!, forMode: .common)
    }

    private func mainTick() {
        guard !isPaused && !isOnBreak else { return }

        timeUntilBreak -= 1

        // Send 1-minute warning whenever at least 60 s remain before the break
        if timeUntilBreak <= 60 && !preBreakNotificationSent {
            preBreakNotificationSent = true
            notifications?.sendPreBreakNotification()
        }

        if timeUntilBreak <= 0 {
            startBreak()
        }
    }

    // MARK: - Break lifecycle

    func startBreak() {
        mainTimer?.invalidate()
        isOnBreak = true
        breakTimeRemaining = settings.breakDuration
        showOverlays()

        breakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.breakTick()
        }
        RunLoop.main.add(breakTimer!, forMode: .common)
    }

    private func breakTick() {
        breakTimeRemaining -= 1
        if breakTimeRemaining <= 0 {
            endBreak()
        }
    }

    func endBreak() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.breakTimer?.invalidate()
            self.isOnBreak = false
            self.breakTimeRemaining = 0
            self.hideOverlays()
            self.timeUntilBreak = self.settings.breakInterval * 60
            self.startMainTimer()
        }
    }

    func skipBreak() {
        endBreak()
    }

    // MARK: - Controls

    func togglePause() {
        isPaused.toggle()
        if !isPaused && timeUntilBreak > 60 {
            preBreakNotificationSent = false
        }
    }

    func delayBreak(by minutes: Double) {
        guard !isOnBreak else { return }
        timeUntilBreak += minutes * 60
        // Allow the warning to fire again after the delay
        if timeUntilBreak > 60 {
            preBreakNotificationSent = false
        }
    }

    /// Reset countdown to the current break interval (called after settings change).
    func resetInterval() {
        mainTimer?.invalidate()
        isOnBreak = false
        breakTimeRemaining = 0
        hideOverlays()
        timeUntilBreak = settings.breakInterval * 60
        startMainTimer()
    }

    // MARK: - Overlay management

    private func showOverlays() {
        NSApp.activate(ignoringOtherApps: true)
        for screen in NSScreen.screens {
            let window = BreakOverlayWindow(screen: screen, timerManager: self)
            overlayWindows.append(window)
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func hideOverlays() {
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }
}

// MARK: - NotificationResponder

extension TimerManager: NotificationResponder {
    // Already implemented above as delayBreak(by:)
}
