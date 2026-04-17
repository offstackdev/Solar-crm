import Foundation

struct AppNotificationDTO: Codable {
    let id: UUID
    let user_id: UUID
    let lead_id: UUID?
    let kind: String
    let title: String
    let message: String
    let created_at: Date
    let is_read: Bool

    func toModel() -> AppNotification {
        AppNotification(
            id: id,
            userID: user_id,
            leadID: lead_id,
            kind: NotificationKind(rawValue: kind) ?? .leadStatusUpdate,
            title: title,
            message: message,
            createdAt: created_at,
            isRead: is_read
        )
    }

    init(model: AppNotification) {
        self.id = model.id
        self.user_id = model.userID
        self.lead_id = model.leadID
        self.kind = model.kind.rawValue
        self.title = model.title
        self.message = model.message
        self.created_at = model.createdAt
        self.is_read = model.isRead
    }
}
