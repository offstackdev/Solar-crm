import Foundation

protocol AILeadExtracting {
    func extractLead(from imagePayloadName: String) async throws -> LeadExtraction
}

enum AIExtractionError: Error {
    case noDataDetected
}

struct MockAIExtractionService: AILeadExtracting {
    func extractLead(from imagePayloadName: String) async throws -> LeadExtraction {
        guard !imagePayloadName.isEmpty else { throw AIExtractionError.noDataDetected }

        let draft = LeadFormDraft(
            homeownerFullName: "Sara Alvarez",
            phoneNumber: "(714) 555-0142",
            email: "sara.alvarez@email.com",
            propertyAddress: "1442 Golden Mesa Dr",
            city: "Riverside",
            state: "CA",
            zipCode: "92507",
            utilityCompany: "Southern California Edison",
            notes: "Interested in offsetting summer bill. Shade on west side only. Wants Saturday afternoon.",
            appointmentDate: Date().addingTimeInterval(172_800),
            hasAppointment: true,
            leadSource: .imageIntake,
            homeownerType: "Homeowner",
            averageElectricBill: "$245",
            roofType: "Comp Shingle",
            shadingNotes: "Light west-side shade",
            decisionMakerPresent: true,
            spousePresentRequired: true,
            languagePreference: "English"
        )

        return LeadExtraction(
            draft: draft,
            fieldConfidences: [
                .init(fieldName: "Homeowner Name", confidence: 0.96),
                .init(fieldName: "Phone Number", confidence: 0.94),
                .init(fieldName: "Address", confidence: 0.88),
                .init(fieldName: "Utility Company", confidence: 0.72),
                .init(fieldName: "Average Electric Bill", confidence: 0.64),
                .init(fieldName: "Appointment Time", confidence: 0.58)
            ],
            rawText: "Sara Alvarez 7145550142 1442 Golden Mesa Dr Riverside CA 92507 SCE bill 245 spouse needed sat afternoon"
        )
    }
}
