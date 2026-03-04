import Foundation
import UserNotifications

final class NotificationManager: NSObject {

    // Set by AppDelegate after TimerManager is created
    weak var responder: NotificationResponder?

    private enum Category {
        static let preBreak = "EYEBREAK_PREBREAK"
    }

    private enum Action {
        static let delay1 = "DELAY_1_MIN"
        static let delay5 = "DELAY_5_MIN"
    }

    // MARK: - Setup

    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            if granted {
                self?.registerCategory()
            }
        }
    }

    private func registerCategory() {
        let add1 = UNNotificationAction(
            identifier: Action.delay1,
            title: "+1 min",
            options: []
        )
        let add5 = UNNotificationAction(
            identifier: Action.delay5,
            title: "+5 min",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Category.preBreak,
            actions: [add1, add5],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Sending

    func sendPreBreakNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Eye Break in 1 Minute"
        content.body = "Look away from your screen and rest your eyes."
        content.sound = .default
        content.categoryIdentifier = Category.preBreak

        // Deliver immediately (no trigger)
        let request = UNNotificationRequest(
            identifier: "eyebreak.prebreak",
            content: content,
            trigger: nil
        )

        // Remove any previous pre-break notification before adding the new one
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["eyebreak.prebreak"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["eyebreak.prebreak"])
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    // Called when user taps an action button on the notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case Action.delay1:
            DispatchQueue.main.async { self.responder?.delayBreak(by: 1) }
        case Action.delay5:
            DispatchQueue.main.async { self.responder?.delayBreak(by: 5) }
        default:
            break
        }
        completionHandler()
    }

    // Allow the notification banner to show even while the app is active
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
