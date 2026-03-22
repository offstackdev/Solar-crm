import Foundation

enum NotificationKind: String, Codable {
    case reminderRequest
    case leadStatusUpdate
    case appointmentConfirmed
    case appointmentRescheduled
    case assignmentChanged

    var symbolName: String {
        switch self {
        case .reminderRequest: return "bell.badge"
        case .leadStatusUpdate: return "arrow.triangle.2.circlepath"
        case .appointmentConfirmed: return "calendar.badge.checkmark"
        case .appointmentRescheduled: return "calendar.badge.exclamationmark"
        case .assignmentChanged: return "person.crop.circle.badge.checkmark"
        }
    }
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
