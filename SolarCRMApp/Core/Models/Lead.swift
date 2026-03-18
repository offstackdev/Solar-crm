import Foundation

struct Lead: Identifiable, Codable, Equatable {
    let id: UUID
    var homeownerFullName: String
    var phoneNumber: String
    var email: String
    var propertyAddress: String
    var city: String
    var state: String
    var zipCode: String
    var utilityCompany: String
    var notes: String
    var appointmentDate: Date?
    var leadSource: LeadSource
    var createdByDoorKnockerID: UUID
    var assignedCloserID: UUID?
    var orgID: UUID
    var currentStatus: LeadStatus
    var statusHistory: [LeadHistoryItem]
    var createdAt: Date
    var updatedAt: Date
    var homeownerType: String
    var averageElectricBill: String
    var roofType: String
    var shadingNotes: String
    var decisionMakerPresent: Bool
    var spousePresentRequired: Bool
    var languagePreference: String

    var appointmentDateText: String {
        guard let appointmentDate else { return "Not scheduled" }
        return appointmentDate.formatted(date: .abbreviated, time: .shortened)
    }
}
