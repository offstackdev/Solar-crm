import Foundation

actor SupabaseLeadService: LeadServicing {
    private let configuration: BackendConfiguration
    private let sessionStore: SessionStoring

    init(configuration: BackendConfiguration, sessionStore: SessionStoring) {
        self.configuration = configuration
        self.sessionStore = sessionStore
    }

    func fetchLeads() async -> [Lead] {
        do {
            guard let session = await sessionStore.loadSession(), !session.isExpired else { return [] }
            let leadsDTO = try await get([LeadDTO].self, path: "/rest/v1/leads?select=*&order=updated_at.desc", token: session.accessToken)
            let historyDTO = (try? await get([LeadHistoryItemDTO].self, path: "/rest/v1/lead_status_history?select=*&order=changed_at.desc", token: session.accessToken)) ?? []

            return leadsDTO.map { dto in
                let history = historyDTO
                    .filter { $0.lead_id == dto.id }
                    .map { $0.toModel() }
                return dto.toModel(history: history)
            }
        } catch {
            return []
        }
    }

    func saveLead(_ lead: Lead) async -> Lead {
        do {
            guard let session = await sessionStore.loadSession(), !session.isExpired else { return lead }
            let dto = LeadDTO(model: lead)
            _ = try await post([dto], path: "/rest/v1/leads", token: session.accessToken, preferRepresentation: false) as NoContentResponse
            try await upsertHistory(lead.statusHistory, for: lead.id, token: session.accessToken)
            return lead
        } catch {
            return lead
        }
    }

    func updateLead(_ lead: Lead) async -> Lead {
        do {
            guard let session = await sessionStore.loadSession(), !session.isExpired else { return lead }
            let dto = LeadDTO(model: lead)
            _ = try await patch([dto], path: "/rest/v1/leads?id=eq.\(lead.id.uuidString)", token: session.accessToken, preferRepresentation: false) as NoContentResponse
            try await upsertHistory(lead.statusHistory, for: lead.id, token: session.accessToken)
            return lead
        } catch {
            return lead
        }
    }

    private func upsertHistory(_ history: [LeadHistoryItem], for leadID: UUID, token: String) async throws {
        let payload = history.map { LeadHistoryItemDTO(model: $0, leadID: leadID) }
        guard !payload.isEmpty else { return }
        _ = try await post(payload, path: "/rest/v1/lead_status_history?on_conflict=id", token: token, preferRepresentation: false, resolution: "merge-duplicates") as NoContentResponse
    }

    private func get<T: Decodable>(_ type: T.Type, path: String, token: String) async throws -> T {
        guard let url = URL(string: path, relativeTo: configuration.supabaseURL) else {
            throw BackendServiceError.notConfigured
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(configuration.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.invalidResponse
        }
        return try AppCoders.supabaseDecoder.decode(T.self, from: data)
    }

    private func post<T: Encodable, R: Decodable>(_ payload: T, path: String, token: String, preferRepresentation: Bool, resolution: String? = nil) async throws -> R {
        try await send(payload: payload, path: path, method: "POST", token: token, preferRepresentation: preferRepresentation, resolution: resolution)
    }

    private func patch<T: Encodable, R: Decodable>(_ payload: T, path: String, token: String, preferRepresentation: Bool) async throws -> R {
        try await send(payload: payload, path: path, method: "PATCH", token: token, preferRepresentation: preferRepresentation, resolution: nil)
    }

    private func send<T: Encodable, R: Decodable>(payload: T, path: String, method: String, token: String, preferRepresentation: Bool, resolution: String?) async throws -> R {
        guard let url = URL(string: path, relativeTo: configuration.supabaseURL) else {
            throw BackendServiceError.notConfigured
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(configuration.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var preferValues = [preferRepresentation ? "return=representation" : "return=minimal"]
        if let resolution { preferValues.append("resolution=\(resolution)") }
        request.setValue(preferValues.joined(separator: ","), forHTTPHeaderField: "Prefer")
        request.httpBody = try AppCoders.supabaseEncoder.encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIClientError.invalidResponse
        }
        if R.self == NoContentResponse.self {
            return NoContentResponse() as! R
        }
        return try AppCoders.supabaseDecoder.decode(R.self, from: data)
    }
}
