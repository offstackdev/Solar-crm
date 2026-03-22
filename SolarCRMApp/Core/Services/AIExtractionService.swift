import Foundation

protocol AILeadExtracting {
    func extractLead(from imagePayloadName: String) async throws -> LeadExtraction
}

struct UnavailableAIExtractionService: AILeadExtracting {
    func extractLead(from imagePayloadName: String) async throws -> LeadExtraction {
        _ = imagePayloadName
        throw BackendServiceError.notImplemented("AI note extraction is not connected to a live backend yet. Use manual entry for now.")
    }
}
