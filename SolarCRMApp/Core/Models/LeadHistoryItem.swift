import Foundation

struct LeadHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let status: LeadStatus
    let changedByUserID: UUID
    let note: String
    let changedAt: Date
}
