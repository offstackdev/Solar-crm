import Foundation

enum NotificationKind: String, Codable {
    case reminderRequest
    case leadStatusUpdate
    case appointmentConfirmed
    case appointmentRescheduled
    case assignmentChanged
}

struct AppNotification: Identifiable, Codable, Equatable {
    let id: UUID
    let userID: UUID
    let leadID: UUID?
    let kind: NotificationKind
    let title: String
    let message: String
    let createdAt: Date
    var isRead: Bool
}
