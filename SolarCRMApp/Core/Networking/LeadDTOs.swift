import Foundation

struct LeadDTO: Codable {
    let id: UUID
    let homeowner_full_name: String
    let phone_number: String
    let email: String
    let property_address: String
    let city: String
    let state: String
    let zip_code: String
    let utility_company: String
    let notes: String
    let appointment_at: Date?
    let lead_source: String
    let created_by_door_knocker_id: UUID
    let assigned_closer_id: UUID?
    let org_id: UUID
    let current_status: String
    let created_at: Date
    let updated_at: Date
}
