import Foundation

enum SeedData {
    static let orgID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let managerID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let closerOneID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let closerTwoID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    static let knockerOneID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    static let knockerTwoID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!

    static let users: [AppUser] = [
        .init(id: managerID, fullName: "Elena Rivera", email: "manager@suncrest.com", role: .manager, orgID: orgID, assignedCloserID: nil, phoneNumber: "555-400-1000"),
        .init(id: closerOneID, fullName: "Marcus Cole", email: "closer1@suncrest.com", role: .closer, orgID: orgID, assignedCloserID: nil, phoneNumber: "555-400-2000"),
        .init(id: closerTwoID, fullName: "Priya Singh", email: "closer2@suncrest.com", role: .closer, orgID: orgID, assignedCloserID: nil, phoneNumber: "555-400-3000"),
        .init(id: knockerOneID, fullName: "Noah Bennett", email: "knocker1@suncrest.com", role: .doorKnocker, orgID: orgID, assignedCloserID: closerOneID, phoneNumber: "555-400-4000"),
        .init(id: knockerTwoID, fullName: "Isabella Gomez", email: "knocker2@suncrest.com", role: .doorKnocker, orgID: orgID, assignedCloserID: closerTwoID, phoneNumber: "555-400-5000")
    ]

    static let leads: [Lead] = [
        seededLead(
            id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
            name: "Daniel Kim",
            address: "912 Citrus Ave",
            city: "Corona",
            status: .pendingConfirmation,
            createdBy: knockerOneID,
            closerID: closerOneID,
            notes: "Homeowner interested in battery add-on.",
            appointmentOffset: 86_400
        ),
        seededLead(
            id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
            name: "Maria Torres",
            address: "4208 Ridge View Ln",
            city: "Ontario",
            status: .onCloserSchedule,
            createdBy: knockerOneID,
            closerID: closerOneID,
            notes: "Saturday morning confirmed. Spouse required.",
            appointmentOffset: 43_200
        ),
        seededLead(
            id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            name: "Liam Johnson",
            address: "1810 Dawn Creek Rd",
            city: "Riverside",
            status: .needsFollowUp,
            createdBy: knockerTwoID,
            closerID: closerTwoID,
            notes: "Wanted lower payment option.",
            appointmentOffset: -86_400
        ),
        seededLead(
            id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            name: "Grace Patel",
            address: "55 Canyon Crest Ct",
            city: "Moreno Valley",
            status: .closed,
            createdBy: knockerTwoID,
            closerID: closerTwoID,
            notes: "Closed with battery and main panel upgrade.",
            appointmentOffset: -172_800
        )
    ]

    static let notifications: [AppNotification] = [
        .init(id: UUID(), userID: knockerOneID, leadID: UUID(uuidString: "88888888-8888-8888-8888-888888888888"), kind: .leadStatusUpdate, title: "Appointment moved to closer schedule", message: "Maria Torres is now on Marcus Cole's schedule.", createdAt: Date().addingTimeInterval(-3_600), isRead: false),
        .init(id: UUID(), userID: knockerTwoID, leadID: UUID(uuidString: "99999999-9999-9999-9999-999999999999"), kind: .leadStatusUpdate, title: "Closer marked follow-up", message: "Liam Johnson needs follow-up after the appointment.", createdAt: Date().addingTimeInterval(-7_200), isRead: false),
        .init(id: UUID(), userID: closerOneID, leadID: UUID(uuidString: "77777777-7777-7777-7777-777777777777"), kind: .assignmentChanged, title: "New lead assigned", message: "Daniel Kim was routed to you after door confirmation.", createdAt: Date().addingTimeInterval(-10_800), isRead: true)
    ]

    private static func seededLead(id: UUID, name: String, address: String, city: String, status: LeadStatus, createdBy: UUID, closerID: UUID, notes: String, appointmentOffset: TimeInterval) -> Lead {
        let createdAt = Date().addingTimeInterval(-172_800)
        let history = [
            LeadHistoryItem(id: UUID(), status: .newLead, changedByUserID: createdBy, note: "Lead created in field", changedAt: createdAt),
            LeadHistoryItem(id: UUID(), status: status, changedByUserID: status == .closed || status == .needsFollowUp ? closerID : createdBy, note: "Workflow updated", changedAt: Date().addingTimeInterval(-3_600))
        ]

        return Lead(
            id: id,
            homeownerFullName: name,
            phoneNumber: "555-010-\(Int.random(in: 1000...9999))",
            email: "\(name.replacingOccurrences(of: " ", with: ".").lowercased())@email.com",
            propertyAddress: address,
            city: city,
            state: "CA",
            zipCode: "92880",
            utilityCompany: "Southern California Edison",
            notes: notes,
            appointmentDate: Date().addingTimeInterval(appointmentOffset),
            leadSource: .canvassing,
            createdByDoorKnockerID: createdBy,
            assignedCloserID: closerID,
            orgID: orgID,
            currentStatus: status,
            statusHistory: history,
            createdAt: createdAt,
            updatedAt: Date().addingTimeInterval(-1_800),
            homeownerType: "Homeowner",
            averageElectricBill: "$210",
            roofType: "Tile",
            shadingNotes: "Minimal shading",
            decisionMakerPresent: true,
            spousePresentRequired: status == .onCloserSchedule,
            languagePreference: "English"
        )
    }
}
