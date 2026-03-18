import Foundation

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case doorKnocker
    case closer
    case manager

    var id: String { rawValue }

    var title: String {
        switch self {
        case .doorKnocker: return "Door Knocker"
        case .closer: return "Closer"
        case .manager: return "Manager"
        }
    }

    var symbolName: String {
        switch self {
        case .doorKnocker: return "figure.walk"
        case .closer: return "calendar.badge.clock"
        case .manager: return "rectangle.3.group.bubble.left"
        }
    }
}
