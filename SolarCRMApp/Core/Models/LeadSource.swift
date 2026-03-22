import Foundation

enum LeadSource: String, Codable, CaseIterable, Identifiable {
    case canvassing = "Canvassing"
    case referral = "Referral"
    case inbound = "Inbound"
    case event = "Event"
    case imageIntake = "Image Intake"

    var id: String { rawValue }

    init(backendValue: String) {
        self = LeadSource(rawValue: backendValue) ?? .canvassing
    }
}
