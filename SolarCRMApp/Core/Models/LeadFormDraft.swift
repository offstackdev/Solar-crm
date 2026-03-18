import Foundation

struct LeadFormDraft: Equatable {
    var homeownerFullName: String = ""
    var phoneNumber: String = ""
    var email: String = ""
    var propertyAddress: String = ""
    var city: String = ""
    var state: String = ""
    var zipCode: String = ""
    var utilityCompany: String = ""
    var notes: String = ""
    var appointmentDate: Date = Date().addingTimeInterval(86_400)
    var hasAppointment: Bool = true
    var leadSource: LeadSource = .canvassing
    var homeownerType: String = "Homeowner"
    var averageElectricBill: String = ""
    var roofType: String = ""
    var shadingNotes: String = ""
    var decisionMakerPresent: Bool = true
    var spousePresentRequired: Bool = false
    var languagePreference: String = "English"

    var isValidForSubmission: Bool {
        missingRequiredFields.isEmpty
    }

    var missingRequiredFields: [String] {
        var fields: [String] = []
        if homeownerFullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { fields.append("Homeowner Name") }
        if phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { fields.append("Phone Number") }
        if propertyAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { fields.append("Address") }
        if city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { fields.append("City") }
        if state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { fields.append("State") }
        if zipCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { fields.append("Zip") }
        return fields
    }
}
