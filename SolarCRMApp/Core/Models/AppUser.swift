import Foundation

struct AppUser: Identifiable, Codable, Equatable {
    let id: UUID
    var fullName: String
    var email: String
    var role: UserRole
    var orgID: UUID
    var assignedCloserID: UUID?
    var phoneNumber: String
}
