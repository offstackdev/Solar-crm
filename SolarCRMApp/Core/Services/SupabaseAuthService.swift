import Foundation

actor SupabaseAuthService: AuthServicing {
    private let configuration: BackendConfiguration
    private let sessionStore: SessionStoring

    init(configuration: BackendConfiguration, sessionStore: SessionStoring) {
        self.configuration = configuration
        self.sessionStore = sessionStore
    }

    func login(email: String, password: String?, role: UserRole?) async throws -> AppUser {
        _ = role
        guard let password, !password.isEmpty else {
            throw BackendServiceError.notImplemented("Password is required for Supabase email sign-in.")
        }

        let tokenResponse = try await loginWithPassword(email: email, password: password)
        let session = tokenResponse.toSession()
        await sessionStore.saveSession(session)
        return try await fetchProfile(for: session)
    }

    func logout() async {
        await sessionStore.clearSession()
    }

    func availableUsers() async -> [AppUser] {
        do {
            guard let session = await sessionStore.loadSession(), !session.isExpired else { return [] }
            guard let currentUser = try? await fetchProfile(for: session) else { return [] }

            let path = "/rest/v1/app_users?org_id=eq.\(currentUser.orgID.uuidString)&select=id,org_id,full_name,email,phone_number,role,assigned_closer_id"
            let profiles = try await get([AppUserDTO].self, path: path, token: session.accessToken)
            return profiles.compactMap { try? $0.toModel() }
        } catch {
            return []
        }
    }

    func restoreSessionUser() async throws -> AppUser? {
        guard let session = await sessionStore.loadSession(), !session.isExpired else {
            await sessionStore.clearSession()
            return nil
        }
        return try await fetchProfile(for: session)
    }

    private func loginWithPassword(email: String, password: String) async throws -> SupabaseAuthTokenResponse {
        guard let url = URL(string: "/auth/v1/token?grant_type=password", relativeTo: configuration.supabaseURL) else {
            throw BackendServiceError.notConfigured
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(configuration.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "email": email,
            "password": password
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = extractBackendMessage(from: data) ?? "Supabase sign-in failed with status \(httpResponse.statusCode)."
            throw BackendServiceError.requestFailed(message)
        }

        return try JSONDecoder().decode(SupabaseAuthTokenResponse.self, from: data)
    }

    private func fetchProfile(for session: SupabaseSession) async throws -> AppUser {
        let profiles = try await get([AppUserDTO].self, path: "/rest/v1/app_users?id=eq.\(session.userID.uuidString)&select=id,org_id,full_name,email,phone_number,role,assigned_closer_id", token: session.accessToken)
        guard let profile = profiles.first else {
            throw BackendServiceError.requestFailed("No app_users profile matched the authenticated user. Make sure app_users.id matches the Supabase Auth user ID.")
        }
        return try profile.toModel()
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
            let message = extractBackendMessage(from: data) ?? "Supabase request failed with status \(httpResponse.statusCode)."
            throw BackendServiceError.requestFailed(message)
        }

        return try AppCoders.supabaseDecoder.decode(T.self, from: data)
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
