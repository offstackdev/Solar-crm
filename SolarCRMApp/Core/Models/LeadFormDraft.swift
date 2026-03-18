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
        !homeownerFullName.isEmpty && !phoneNumber.isEmpty && !propertyAddress.isEmpty && !city.isEmpty && !state.isEmpty && !zipCode.isEmpty
    }
}
