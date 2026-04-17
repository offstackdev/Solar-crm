import Foundation

struct SupabaseSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let userID: UUID
    let expiresAt: Date

    var isExpired: Bool {
        expiresAt <= Date()
    }
}
