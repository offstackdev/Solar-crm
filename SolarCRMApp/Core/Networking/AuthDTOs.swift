import Foundation

struct SupabaseAuthTokenResponse: Decodable {
    struct AuthUser: Decodable {
        let id: UUID
        let email: String?
    }

    let access_token: String
    let refresh_token: String
    let expires_in: TimeInterval
    let user: AuthUser

    func toSession() -> SupabaseSession {
        SupabaseSession(
            accessToken: access_token,
            refreshToken: refresh_token,
            userID: user.id,
            expiresAt: Date().addingTimeInterval(expires_in)
        )
    }
}

struct AppUserDTO: Codable {
    let id: UUID
    let org_id: UUID
    let full_name: String
    let email: String
    let phone_number: String
    let role: String
    let assigned_closer_id: UUID?

    func toModel() throws -> AppUser {
        guard let role = UserRole(backendValue: role) else {
            throw BackendServiceError.notImplemented("Unsupported backend role value: \(self.role)")
        }

        return AppUser(
            id: id,
            fullName: full_name,
            email: email,
            role: role,
            orgID: org_id,
            assignedCloserID: assigned_closer_id,
            phoneNumber: phone_number
        )
    }
}
