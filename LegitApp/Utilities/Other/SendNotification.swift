//
//  sendNotification.swift
//  LegitApp
//
//  Created by Milán Várady on 2023. 04. 15..
//

import Foundation
import UserNotifications
import OSLog

enum NotificationReason {
    case success
    case failure
}

/// Sends a push notifcation
///
/// Only sends the notification if the user has enabled notifications for the specified reason in settings
///
/// - Parameters:
///   - title: Notification title
///   - body: Notification body
///   - reason: Reason why the notification was sent, task success or failure
///
/// - Returns: `Void`
func sendNotification(title: String, body: String = "", reason: NotificationReason) async {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "sendNotification")

    // Return before touching UNUserNotificationCenter when the user disabled this notification type.
    if (!UserDefaults.standard.bool(forKey: Preferences.notificationSuccess.rawValue) && reason == .success)
        || (!UserDefaults.standard.bool(forKey: Preferences.notificationFailure.rawValue) && reason == .failure) {
        return
    }

    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()

    guard (settings.authorizationStatus == .authorized) ||
            (settings.authorizationStatus == .provisional) else {

            // Ask for authorization
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            logger.error("Failed to request notification authorization. Error: \(error.localizedDescription)")
        }

        return
    }

    let content = UNMutableNotificationContent()

    content.title = title
    content.body = body
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

    do {
        try await UNUserNotificationCenter.current().add(request)
    } catch {
        logger.error("Failed to send notication. Error: \(error.localizedDescription)")
    }
}
