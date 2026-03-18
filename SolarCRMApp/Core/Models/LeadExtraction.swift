import Foundation

struct LeadExtraction: Equatable {
    struct FieldConfidence: Identifiable, Equatable {
        let id = UUID()
        let fieldName: String
        let confidence: Double
    }

    var draft: LeadFormDraft
    var fieldConfidences: [FieldConfidence]
    var rawText: String

    var lowConfidenceFields: [FieldConfidence] {
        fieldConfidences.filter { $0.confidence < 0.7 }
    }
}
