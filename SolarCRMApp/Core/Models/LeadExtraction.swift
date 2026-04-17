import Foundation

struct LeadExtraction: Equatable {
    struct FieldConfidence: Identifiable, Equatable {
        let id = UUID()
        let fieldName: String
        let confidence: Double

        var displayName: String {
            switch fieldName {
            case "homeownerFullName":
                return "Homeowner Name"
            case "phoneNumber":
                return "Phone Number"
            case "email":
                return "Email"
            case "propertyAddress":
                return "Property Address"
            case "city":
                return "City"
            case "state":
                return "State"
            case "zipCode":
                return "ZIP Code"
            case "utilityCompany":
                return "Utility Company"
            case "notes":
                return "Notes"
            case "homeownerType":
                return "Homeowner Type"
            case "averageElectricBill":
                return "Average Electric Bill"
            case "roofType":
                return "Roof Type"
            case "shadingNotes":
                return "Shading Notes"
            case "decisionMakerPresent":
                return "Decision Maker Present"
            case "spousePresentRequired":
                return "Spouse Present Required"
            case "languagePreference":
                return "Language Preference"
            default:
                return fieldName
            }
        }
    }

    var draft: LeadFormDraft
    var fieldConfidences: [FieldConfidence]
    var rawText: String

    var lowConfidenceFields: [FieldConfidence] {
        fieldConfidences.filter { $0.confidence < 0.7 }
    }

    var formattedRawText: String {
        Self.formatSourceText(rawText)
    }

    private static func formatSourceText(_ text: String) -> String {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.components(separatedBy: .newlines)

        var output: [String] = []
        var previousWasBlank = false

        for line in lines {
            let cleaned = line.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if cleaned.isEmpty {
                if !previousWasBlank, !output.isEmpty {
                    output.append("")
                }
                previousWasBlank = true
                continue
            }

            output.append(cleaned)
            previousWasBlank = false
        }

        return output.joined(separator: "\n")
    }
}
