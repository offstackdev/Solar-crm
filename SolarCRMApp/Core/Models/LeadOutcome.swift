import Foundation

enum LeadOutcome: String, CaseIterable, Identifiable {
    case closed = "Closed"
    case oneLegger = "One-Legger"
    case needsFollowUp = "Needs Follow-Up"
    case noShow = "No Show"
    case rescheduled = "Rescheduled"
    case notInterested = "Not Interested"

    var id: String { rawValue }

    var resultingStatus: LeadStatus {
        switch self {
        case .closed: return .closed
        case .oneLegger: return .oneLegger
        case .needsFollowUp: return .needsFollowUp
        case .noShow: return .noShow
        case .rescheduled: return .appointmentRescheduled
        case .notInterested: return .notInterested
        }
    }
}
