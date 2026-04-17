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
    let homeowner_type: String
    let average_electric_bill: String
    let roof_type: String
    let shading_notes: String
    let decision_maker_present: Bool
    let spouse_present_required: Bool
    let language_preference: String
    let created_by_door_knocker_id: UUID
    let assigned_closer_id: UUID?
    let org_id: UUID
    let current_status: String
    let created_at: Date
    let updated_at: Date

    func toModel(history: [LeadHistoryItem]) -> Lead {
        Lead(
            id: id,
            homeownerFullName: homeowner_full_name,
            phoneNumber: phone_number,
            email: email,
            propertyAddress: property_address,
            city: city,
            state: state,
            zipCode: zip_code,
            utilityCompany: utility_company,
            notes: notes,
            appointmentDate: appointment_at,
            leadSource: LeadSource(backendValue: lead_source),
            createdByDoorKnockerID: created_by_door_knocker_id,
            assignedCloserID: assigned_closer_id,
            orgID: org_id,
            currentStatus: LeadStatus(backendValue: current_status),
            statusHistory: history.sorted { $0.changedAt > $1.changedAt },
            createdAt: created_at,
            updatedAt: updated_at,
            homeownerType: homeowner_type,
            averageElectricBill: average_electric_bill,
            roofType: roof_type,
            shadingNotes: shading_notes,
            decisionMakerPresent: decision_maker_present,
            spousePresentRequired: spouse_present_required,
            languagePreference: language_preference
        )
    }

    init(model: Lead) {
        self.id = model.id
        self.homeowner_full_name = model.homeownerFullName
        self.phone_number = model.phoneNumber
        self.email = model.email
        self.property_address = model.propertyAddress
        self.city = model.city
        self.state = model.state
        self.zip_code = model.zipCode
        self.utility_company = model.utilityCompany
        self.notes = model.notes
        self.appointment_at = model.appointmentDate
        self.lead_source = model.leadSource.rawValue
        self.homeowner_type = model.homeownerType
        self.average_electric_bill = model.averageElectricBill
        self.roof_type = model.roofType
        self.shading_notes = model.shadingNotes
        self.decision_maker_present = model.decisionMakerPresent
        self.spouse_present_required = model.spousePresentRequired
        self.language_preference = model.languagePreference
        self.created_by_door_knocker_id = model.createdByDoorKnockerID
        self.assigned_closer_id = model.assignedCloserID
        self.org_id = model.orgID
        self.current_status = model.currentStatus.rawValue
        self.created_at = model.createdAt
        self.updated_at = model.updatedAt
    }
}

struct LeadHistoryItemDTO: Codable {
    let id: UUID
    let lead_id: UUID
    let status: String
    let note: String
    let changed_by_user_id: UUID
    let changed_at: Date

    func toModel() -> LeadHistoryItem {
        LeadHistoryItem(
            id: id,
            status: LeadStatus(backendValue: status),
            changedByUserID: changed_by_user_id,
            note: note,
            changedAt: changed_at
        )
    }

    init(model: LeadHistoryItem, leadID: UUID) {
        self.id = model.id
        self.lead_id = leadID
        self.status = model.status.rawValue
        self.note = model.note
        self.changed_by_user_id = model.changedByUserID
        self.changed_at = model.changedAt
    }
}
