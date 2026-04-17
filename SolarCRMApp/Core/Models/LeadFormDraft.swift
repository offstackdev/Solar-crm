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

    func cleaned() -> LeadFormDraft {
        var copy = self
        copy.homeownerFullName = homeownerFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.phoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.propertyAddress = propertyAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.state = state.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.zipCode = zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.utilityCompany = utilityCompany.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.averageElectricBill = averageElectricBill.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.roofType = roofType.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.shadingNotes = shadingNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        copy.languagePreference = languagePreference.trimmingCharacters(in: .whitespacesAndNewlines)
        return copy
    }
}
