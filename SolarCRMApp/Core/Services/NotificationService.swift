import Foundation

protocol NotificationServicing {
    func fetchNotifications(for userID: UUID) async -> [AppNotification]
    func upsert(_ notification: AppNotification) async -> NotificationDeliveryResult
    func markRead(notificationID: UUID) async
}

actor MockNotificationService: NotificationServicing {
    private var notifications: [AppNotification]

    init(notifications: [AppNotification]) {
        self.notifications = notifications
    }

    func fetchNotifications(for userID: UUID) async -> [AppNotification] {
        notifications
            .filter { $0.userID == userID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func upsert(_ notification: AppNotification) async -> NotificationDeliveryResult {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = notification
        } else {
            notifications.insert(notification, at: 0)
        }
        return .success
    }

    func markRead(notificationID: UUID) async {
        guard let index = notifications.firstIndex(where: { $0.id == notificationID }) else { return }
        notifications[index].isRead = true
    }
}
