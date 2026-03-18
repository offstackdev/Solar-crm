import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var users: [AppUser] = []
    @Published var leads: [Lead] = []
    @Published var notifications: [AppNotification] = []
    @Published var isLoaded = false

    let services: ServiceContainer

    init(services: ServiceContainer) {
        self.services = services
    }

    static func bootstrap() -> AppState {
        let services = ServiceContainer(
            authService: MockAuthService(users: SeedData.users),
            leadService: MockLeadService(leads: SeedData.leads),
            notificationService: MockNotificationService(notifications: SeedData.notifications),
            aiExtractionService: MockAIExtractionService()
        )
        return AppState(services: services)
    }

    func loadSeedDataIfNeeded() async {
        guard !isLoaded else { return }
        users = await services.authService.availableUsers()
        leads = await services.leadService.fetchLeads()
        isLoaded = true
    }

    func login(email: String = "", role: UserRole? = nil) async throws {
        let user = try await services.authService.login(email: email, role: role)
        currentUser = user
        notifications = await services.notificationService.fetchNotifications(for: user.id)
    }

    func logout() async {
        await services.authService.logout()
        currentUser = nil
        notifications = []
    }

    func refreshLeadData() async {
        leads = await services.leadService.fetchLeads()
        if let user = currentUser {
            notifications = await services.notificationService.fetchNotifications(for: user.id)
        }
    }

    func saveNewLead(from draft: LeadFormDraft, source overrideSource: LeadSource? = nil) async {
        guard let currentUser else { return }
        let assignedCloserID = currentUser.assignedCloserID
        let timestamp = Date()
        let effectiveSource = overrideSource ?? draft.leadSource
        let initialStatus: LeadStatus = draft.hasAppointment ? .pendingConfirmation : .submitted
        let lead = Lead(
            id: UUID(),
            homeownerFullName: draft.homeownerFullName,
            phoneNumber: draft.phoneNumber,
            email: draft.email,
            propertyAddress: draft.propertyAddress,
            city: draft.city,
            state: draft.state,
            zipCode: draft.zipCode,
            utilityCompany: draft.utilityCompany,
            notes: draft.notes,
            appointmentDate: draft.hasAppointment ? draft.appointmentDate : nil,
            leadSource: effectiveSource,
            createdByDoorKnockerID: currentUser.id,
            assignedCloserID: assignedCloserID,
            orgID: currentUser.orgID,
            currentStatus: initialStatus,
            statusHistory: [
                LeadHistoryItem(id: UUID(), status: initialStatus, changedByUserID: currentUser.id, note: "Lead submitted by \(currentUser.fullName)", changedAt: timestamp)
            ],
            createdAt: timestamp,
            updatedAt: timestamp,
            homeownerType: draft.homeownerType,
            averageElectricBill: draft.averageElectricBill,
            roofType: draft.roofType,
            shadingNotes: draft.shadingNotes,
            decisionMakerPresent: draft.decisionMakerPresent,
            spousePresentRequired: draft.spousePresentRequired,
            languagePreference: draft.languagePreference
        )

        _ = await services.leadService.saveLead(lead)
        await refreshLeadData()
        if let closerID = assignedCloserID {
            await sendNotification(
                userID: closerID,
                leadID: lead.id,
                kind: .assignmentChanged,
                title: "New solar lead assigned",
                message: "\(lead.homeownerFullName) was submitted by \(currentUser.fullName)."
            )
        }
    }

    func updateLeadStatus(leadID: UUID, status: LeadStatus, note: String) async {
        guard let user = currentUser, var lead = leads.first(where: { $0.id == leadID }) else { return }
        lead.currentStatus = status
        lead.updatedAt = Date()
        lead.statusHistory.insert(.init(id: UUID(), status: status, changedByUserID: user.id, note: note, changedAt: Date()), at: 0)

        if status == .appointmentConfirmed {
            lead.currentStatus = .sentToCloser
            lead.statusHistory.insert(.init(id: UUID(), status: .sentToCloser, changedByUserID: user.id, note: "Lead routed to closer after confirmation", changedAt: Date()), at: 0)
            if lead.assignedCloserID != nil {
                lead.currentStatus = .onCloserSchedule
                lead.statusHistory.insert(.init(id: UUID(), status: .onCloserSchedule, changedByUserID: user.id, note: "Appointment placed on closer schedule", changedAt: Date()), at: 0)
            }
        }

        _ = await services.leadService.updateLead(lead)
        await refreshLeadData()

        if let closerID = lead.assignedCloserID, user.role == .doorKnocker, status == .appointmentConfirmed {
            await sendNotification(
                userID: closerID,
                leadID: lead.id,
                kind: .appointmentConfirmed,
                title: "Appointment confirmed",
                message: "\(lead.homeownerFullName) is confirmed and ready for your schedule."
            )
        }
    }

    func requestReminder(for leadID: UUID) async {
        guard
            let user = currentUser,
            var lead = leads.first(where: { $0.id == leadID }),
            let doorKnocker = users.first(where: { $0.id == lead.createdByDoorKnockerID })
        else { return }

        lead.updatedAt = Date()
        lead.statusHistory.insert(.init(id: UUID(), status: lead.currentStatus, changedByUserID: user.id, note: "Closer requested reminder to confirm appointment", changedAt: Date()), at: 0)
        _ = await services.leadService.updateLead(lead)

        await sendNotification(
            userID: doorKnocker.id,
            leadID: lead.id,
            kind: .reminderRequest,
            title: "Remind prospect to confirm",
            message: "\(user.fullName) asked you to re-confirm \(lead.homeownerFullName)'s appointment."
        )
        await refreshLeadData()
    }

    func updateCloserOutcome(leadID: UUID, outcome: LeadOutcome) async {
        guard let user = currentUser, var lead = leads.first(where: { $0.id == leadID }) else { return }

        let newStatus = outcome.resultingStatus
        lead.currentStatus = newStatus
        lead.updatedAt = Date()
        lead.statusHistory.insert(.init(id: UUID(), status: newStatus, changedByUserID: user.id, note: "Closer outcome updated to \(outcome.rawValue)", changedAt: Date()), at: 0)

        if outcome == .rescheduled {
            lead.statusHistory.insert(.init(id: UUID(), status: .appointmentRescheduled, changedByUserID: user.id, note: "Appointment needs a new time", changedAt: Date()), at: 0)
        }

        _ = await services.leadService.updateLead(lead)
        await refreshLeadData()

        await sendNotification(
            userID: lead.createdByDoorKnockerID,
            leadID: lead.id,
            kind: .leadStatusUpdate,
            title: "Closer updated lead status",
            message: "\(lead.homeownerFullName) is now marked \(newStatus.rawValue)."
        )
    }

    func reassign(leadID: UUID, closerID: UUID) async {
        guard let user = currentUser, user.role == .manager, var lead = leads.first(where: { $0.id == leadID }) else { return }
        lead.assignedCloserID = closerID
        lead.updatedAt = Date()
        lead.statusHistory.insert(.init(id: UUID(), status: lead.currentStatus, changedByUserID: user.id, note: "Manager reassigned closer", changedAt: Date()), at: 0)
        _ = await services.leadService.updateLead(lead)

        await sendNotification(
            userID: closerID,
            leadID: lead.id,
            kind: .assignmentChanged,
            title: "Lead reassigned to you",
            message: "\(lead.homeownerFullName) is now assigned to you."
        )
        await refreshLeadData()
    }

    func leadsForCurrentUser() -> [Lead] {
        guard let currentUser else { return [] }
        switch currentUser.role {
        case .doorKnocker:
            return leads.filter { $0.createdByDoorKnockerID == currentUser.id }
        case .closer:
            return leads.filter { $0.assignedCloserID == currentUser.id }
        case .manager:
            return leads
        }
    }

    func users(for role: UserRole) -> [AppUser] {
        users.filter { $0.role == role }
    }

    func userName(for id: UUID?) -> String {
        guard let id, let user = users.first(where: { $0.id == id }) else { return "Unassigned" }
        return user.fullName
    }

    func markNotificationRead(_ notification: AppNotification) async {
        await services.notificationService.markRead(notificationID: notification.id)
        notifications = await services.notificationService.fetchNotifications(for: notification.userID)
    }

    func extractLead(from imagePayloadName: String) async throws -> LeadExtraction {
        try await services.aiExtractionService.extractLead(from: imagePayloadName)
    }

    private func sendNotification(userID: UUID, leadID: UUID?, kind: NotificationKind, title: String, message: String) async {
        let notification = AppNotification(
            id: UUID(),
            userID: userID,
            leadID: leadID,
            kind: kind,
            title: title,
            message: message,
            createdAt: Date(),
            isRead: false
        )
        await services.notificationService.upsert(notification)
    }
}
