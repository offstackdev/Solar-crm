import Foundation

enum LeadStatus: String, Codable, CaseIterable, Identifiable {
    case newLead = "New Lead"
    case needsVerification = "Needs Verification"
    case submitted = "Submitted"
    case pendingConfirmation = "Pending Confirmation"
    case appointmentConfirmed = "Appointment Confirmed"
    case appointmentCanceled = "Appointment Canceled"
    case appointmentRescheduled = "Appointment Rescheduled"
    case sentToCloser = "Sent to Closer"
    case onCloserSchedule = "On Closer Schedule"
    case appointmentRun = "Appointment Run"
    case closed = "Closed"
    case oneLegger = "One-Legger"
    case needsFollowUp = "Needs Follow-Up"
    case noShow = "No Show"
    case notInterested = "Not Interested"

    var id: String { rawValue }

    var isVisibleOnDoorKnockerActiveBoard: Bool {
        switch self {
        case .newLead, .needsVerification, .submitted, .pendingConfirmation, .appointmentCanceled, .appointmentRescheduled:
            return true
        case .appointmentConfirmed, .sentToCloser, .onCloserSchedule, .appointmentRun, .closed, .oneLegger, .needsFollowUp, .noShow, .notInterested:
            return false
        }
    }

    var isConfirmedForCloserSchedule: Bool {
        self == .appointmentConfirmed || self == .sentToCloser || self == .onCloserSchedule || self == .appointmentRun
    }

    var isVisibleToCloser: Bool {
        switch self {
        case .submitted, .pendingConfirmation, .appointmentRescheduled, .sentToCloser, .onCloserSchedule, .appointmentRun, .closed, .oneLegger, .needsFollowUp, .noShow, .notInterested:
            return true
        case .newLead, .needsVerification, .appointmentConfirmed, .appointmentCanceled:
            return false
        }
    }

    var isVisibleInCloserLeads: Bool {
        switch self {
        case .submitted, .pendingConfirmation, .appointmentRescheduled, .sentToCloser:
            return true
        case .newLead, .needsVerification, .appointmentConfirmed, .appointmentCanceled, .onCloserSchedule, .appointmentRun, .closed, .oneLegger, .needsFollowUp, .noShow, .notInterested:
            return false
        }
    }

    var badgeTone: StatusTone {
        switch self {
        case .closed: return .success
        case .appointmentConfirmed, .sentToCloser, .onCloserSchedule: return .accent
        case .needsVerification, .needsFollowUp, .pendingConfirmation, .appointmentRescheduled: return .warning
        case .appointmentCanceled, .noShow, .notInterested: return .danger
        default: return .neutral
        }
    }
}

enum StatusTone {
    case neutral
    case accent
    case success
    case warning
    case danger
}
