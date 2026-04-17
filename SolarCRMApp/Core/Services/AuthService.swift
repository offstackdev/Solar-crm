import Foundation

protocol AuthServicing {
    func login(email: String, password: String?, role: UserRole?) async throws -> AppUser
    func logout() async
    func availableUsers() async -> [AppUser]
    func restoreSessionUser() async throws -> AppUser?
}

enum AuthError: Error {
    case userNotFound
}

actor MockAuthService: AuthServicing {
    private let users: [AppUser]

    init(users: [AppUser]) {
        self.users = users
    }

    func login(email: String, password: String?, role: UserRole?) async throws -> AppUser {
        _ = password
        if let role {
            guard let user = users.first(where: { $0.role == role }) else { throw AuthError.userNotFound }
            return user
        }

        guard let user = users.first(where: { $0.email.caseInsensitiveCompare(email) == .orderedSame }) else {
            throw AuthError.userNotFound
        }
        return user
    }

    func logout() async {}

    func availableUsers() async -> [AppUser] {
        users
    }

    func restoreSessionUser() async throws -> AppUser? {
        nil
    }
}
