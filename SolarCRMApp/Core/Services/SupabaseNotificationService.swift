import Foundation

actor SupabaseNotificationService: NotificationServicing {
    private let configuration: BackendConfiguration
    private let sessionStore: SessionStoring

    init(configuration: BackendConfiguration, sessionStore: SessionStoring) {
        self.configuration = configuration
        self.sessionStore = sessionStore
    }

    func fetchNotifications(for userID: UUID) async -> [AppNotification] {
        do {
            guard let session = await sessionStore.loadSession(), !session.isExpired else { return [] }
            let dtos = try await get([AppNotificationDTO].self, path: "/rest/v1/app_notifications?user_id=eq.\(userID.uuidString)&select=*&order=created_at.desc", token: session.accessToken)
            return dtos.map { $0.toModel() }
        } catch {
            return []
        }
    }

    func upsert(_ notification: AppNotification) async -> NotificationDeliveryResult {
        do {
            guard let session = await sessionStore.loadSession(), !session.isExpired else {
                return .failure("The current session is missing or expired.")
            }
            let dto = AppNotificationDTO(model: notification)
            _ = try await post([dto], path: "/rest/v1/app_notifications", token: session.accessToken) as NoContentResponse
            return .success
        } catch {
            if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
                return .failure(description)
            }
            return .failure(String(describing: error))
        }
    }

    func markRead(notificationID: UUID) async {
        do {
            guard let session = await sessionStore.loadSession(), !session.isExpired else { return }
            struct ReadPayload: Encodable { let is_read: Bool }
            _ = try await patch(ReadPayload(is_read: true), path: "/rest/v1/app_notifications?id=eq.\(notificationID.uuidString)", token: session.accessToken) as NoContentResponse
        } catch {
            return
        }
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
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = extractBackendMessage(from: data) ?? "Supabase notification request failed with status \(httpResponse.statusCode)."
            throw BackendServiceError.requestFailed(message)
        }
        return try AppCoders.supabaseDecoder.decode(T.self, from: data)
    }

    private func post<T: Encodable, R: Decodable>(_ payload: T, path: String, token: String) async throws -> R {
        try await send(payload: payload, path: path, method: "POST", token: token, resolution: nil)
    }

    private func patch<T: Encodable, R: Decodable>(_ payload: T, path: String, token: String) async throws -> R {
        try await send(payload: payload, path: path, method: "PATCH", token: token, resolution: nil)
    }

    private func send<T: Encodable, R: Decodable>(payload: T, path: String, method: String, token: String, resolution: String?) async throws -> R {
        guard let url = URL(string: path, relativeTo: configuration.supabaseURL) else {
            throw BackendServiceError.notConfigured
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(configuration.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var preferValues = ["return=minimal"]
        if let resolution { preferValues.append("resolution=\(resolution)") }
        request.setValue(preferValues.joined(separator: ","), forHTTPHeaderField: "Prefer")
        request.httpBody = try AppCoders.supabaseEncoder.encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = extractBackendMessage(from: data) ?? "Supabase notification request failed with status \(httpResponse.statusCode)."
            throw BackendServiceError.requestFailed(message)
        }
        if R.self == NoContentResponse.self {
            return NoContentResponse() as! R
        }
        return try AppCoders.supabaseDecoder.decode(R.self, from: data)
    }

    private func extractBackendMessage(from data: Data) -> String? {
        if
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            if let description = object["error_description"] as? String, !description.isEmpty {
                return description
            }
            if let message = object["msg"] as? String, !message.isEmpty {
                return message
            }
            if let message = object["message"] as? String, !message.isEmpty {
                return message
            }
            if let error = object["error"] as? String, !error.isEmpty {
                return error
            }
        }

        if let raw = String(data: data, encoding: .utf8), !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return raw
        }

        return nil
    }
}
