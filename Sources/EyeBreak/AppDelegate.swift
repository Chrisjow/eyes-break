import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var settings: SettingsManager!
    private var notifications: NotificationManager!
    private var timerManager: TimerManager!
    private var menuBar: MenuBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from the Dock — this is a menu bar-only app
        NSApp.setActivationPolicy(.accessory)

        // Build the object graph
        settings = SettingsManager()
        notifications = NotificationManager()
        timerManager = TimerManager(settings: settings, notifications: notifications)

        // Wire notification actions back to the timer
        notifications.responder = timerManager

        // Request permission and register the "+1 min / +5 min" category
        notifications.requestPermission()

        // Set up the menu bar icon and menu
        menuBar = MenuBarController(timerManager: timerManager, settings: settings, notifications: notifications)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Never quit when the settings window is closed
        return false
    }
}
