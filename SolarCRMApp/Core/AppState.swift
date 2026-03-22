import Foundation
import SwiftUI

enum ReminderRequestResult {
    case sent
    case alreadyPending
    case failed(String)
}

@MainActor
final class AppState: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var users: [AppUser] = []
    @Published var leads: [Lead] = []
    @Published var notifications: [AppNotification] = []
    @Published var isLoaded = false

    let services: ServiceContainer

    var isUsingBackend: Bool {
        services.isUsingBackend
    }

    var supportsAIExtraction: Bool {
        services.supportsAIExtraction
    }

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    init(services: ServiceContainer) {
        self.services = services
    }

    static func bootstrap() -> AppState {
        AppState(services: ServiceContainer.bootstrap())
    }

    func loadSeedDataIfNeeded() async {
        guard !isLoaded else { return }
        if currentUser == nil, let restoredUser = try? await services.authService.restoreSessionUser() {
            currentUser = restoredUser
            users = await services.authService.availableUsers()
            await refreshLeadData()
        } else {
            users = await services.authService.availableUsers()
        }
        if currentUser == nil {
            leads = await services.leadService.fetchLeads()
        }
        isLoaded = true
    }

    func login(email: String = "", password: String? = nil, role: UserRole? = nil) async throws {
        let user = try await services.authService.login(email: email, password: password, role: role)
        currentUser = user
        users = await services.authService.availableUsers()
        await refreshLeadData()
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

    func saveNewLead(from draft: LeadFormDraft, source overrideSource: LeadSource? = nil) async -> Bool {
        guard let currentUser else { return false }
        let assignedCloserID = currentUser.assignedCloserID
        let timestamp = Date()
        let cleanedDraft = draft.cleaned()
        let effectiveSource = overrideSource ?? cleanedDraft.leadSource
        let initialStatus: LeadStatus = cleanedDraft.hasAppointment ? .pendingConfirmation : .submitted
        let lead = Lead(
            id: UUID(),
            homeownerFullName: cleanedDraft.homeownerFullName,
            phoneNumber: cleanedDraft.phoneNumber,
            email: cleanedDraft.email,
            propertyAddress: cleanedDraft.propertyAddress,
            city: cleanedDraft.city,
            state: cleanedDraft.state,
            zipCode: cleanedDraft.zipCode,
            utilityCompany: cleanedDraft.utilityCompany,
            notes: cleanedDraft.notes,
            appointmentDate: cleanedDraft.hasAppointment ? cleanedDraft.appointmentDate : nil,
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
            homeownerType: cleanedDraft.homeownerType,
            averageElectricBill: cleanedDraft.averageElectricBill,
            roofType: cleanedDraft.roofType,
            shadingNotes: cleanedDraft.shadingNotes,
            decisionMakerPresent: cleanedDraft.decisionMakerPresent,
            spousePresentRequired: cleanedDraft.spousePresentRequired,
            languagePreference: cleanedDraft.languagePreference
        )

        _ = await services.leadService.saveLead(lead)
        guard let persistedLead = await verifyPersistedLead(
            leadID: lead.id,
            expectedStatus: initialStatus,
            expectedAssignedCloserID: assignedCloserID,
            expectedHistoryNotes: ["Lead submitted by \(currentUser.fullName)"]
        ) else {
            await refreshLeadData()
            return false
        }

        if let manager = users.first(where: { $0.role == .manager && $0.orgID == currentUser.orgID }) {
            await sendNotification(
                userID: manager.id,
                leadID: persistedLead.id,
                kind: .leadStatusUpdate,
                title: "New lead created",
                message: "\(persistedLead.homeownerFullName) was submitted by \(currentUser.fullName) with status \(initialStatus.rawValue)."
            )
        }

        await refreshLeadData()
        return true
    }

    func updateLeadStatus(leadID: UUID, status: LeadStatus, note: String) async {
        guard let user = currentUser, var lead = leads.first(where: { $0.id == leadID }) else { return }
        let timestamp = Date()
        var expectedStatus = status
        var expectedHistoryNotes = [note]
        lead.currentStatus = status
        lead.updatedAt = timestamp
        lead.statusHistory.insert(.init(id: UUID(), status: status, changedByUserID: user.id, note: note, changedAt: timestamp), at: 0)

        if status == .appointmentConfirmed {
            expectedStatus = .sentToCloser
            lead.currentStatus = .sentToCloser
            let handoffNote = "Lead routed to closer after confirmation"
            expectedHistoryNotes.append(handoffNote)
            lead.statusHistory.insert(.init(id: UUID(), status: .sentToCloser, changedByUserID: user.id, note: handoffNote, changedAt: timestamp), at: 0)
            if lead.assignedCloserID != nil {
                expectedStatus = .onCloserSchedule
                lead.currentStatus = .onCloserSchedule
                let scheduleNote = "Appointment placed on closer schedule"
                expectedHistoryNotes.append(scheduleNote)
                lead.statusHistory.insert(.init(id: UUID(), status: .onCloserSchedule, changedByUserID: user.id, note: scheduleNote, changedAt: timestamp), at: 0)
            }
        }

        _ = await services.leadService.updateLead(lead)
        guard let persistedLead = await verifyPersistedLead(
            leadID: lead.id,
            expectedStatus: expectedStatus,
            expectedAssignedCloserID: lead.assignedCloserID,
            expectedHistoryNotes: expectedHistoryNotes
        ) else {
            await refreshLeadData()
            return
        }

        await markNotificationsRead(for: persistedLead.id, kind: .reminderRequest, userID: persistedLead.createdByDoorKnockerID)
        await refreshLeadData()

        if let closerID = persistedLead.assignedCloserID, user.role == .doorKnocker, status == .appointmentConfirmed {
            await sendNotification(
                userID: closerID,
                leadID: persistedLead.id,
                kind: .appointmentConfirmed,
                title: "Appointment confirmed",
                message: "\(persistedLead.homeownerFullName) is confirmed and ready for your schedule."
            )
        }

        if user.role == .doorKnocker, status == .appointmentConfirmed {
            await sendNotification(
                userID: persistedLead.createdByDoorKnockerID,
                leadID: persistedLead.id,
                kind: .leadStatusUpdate,
                title: "Lead handed off to closer",
                message: "\(persistedLead.homeownerFullName) moved out of your active queue and onto the closer schedule."
            )
        }

        if status == .appointmentCanceled {
            if let closerID = persistedLead.assignedCloserID {
                await sendNotification(
                    userID: closerID,
                    leadID: persistedLead.id,
                    kind: .leadStatusUpdate,
                    title: "Appointment canceled",
                    message: "\(persistedLead.homeownerFullName) was canceled by the door knocker."
                )
            }
            await markNotificationsRead(for: persistedLead.id, kind: .reminderRequest, userID: persistedLead.createdByDoorKnockerID)
        }

        if status == .appointmentRescheduled {
            if let closerID = persistedLead.assignedCloserID {
                await sendNotification(
                    userID: closerID,
                    leadID: persistedLead.id,
                    kind: .appointmentRescheduled,
                    title: "Appointment rescheduled",
                    message: "\(persistedLead.homeownerFullName) needs a new confirmed time from the door knocker."
                )
            }
            await markNotificationsRead(for: persistedLead.id, kind: .reminderRequest, userID: persistedLead.createdByDoorKnockerID)
        }
    }

    func requestReminder(for leadID: UUID) async -> ReminderRequestResult {
        guard
            let user = currentUser,
            var lead = leads.first(where: { $0.id == leadID }),
            let doorKnocker = users.first(where: { $0.id == lead.createdByDoorKnockerID })
        else { return .failed("The assigned door knocker could not be found in the org user roster.") }

        let existingNotifications = await services.notificationService.fetchNotifications(for: doorKnocker.id)
        let alreadyPending = existingNotifications.contains {
            $0.leadID == lead.id && $0.kind == .reminderRequest && !$0.isRead
        }

        if alreadyPending {
            return .alreadyPending
        }

        lead.updatedAt = Date()
        lead.statusHistory.insert(.init(id: UUID(), status: lead.currentStatus, changedByUserID: user.id, note: "Closer requested reminder to confirm appointment", changedAt: Date()), at: 0)
        _ = await services.leadService.updateLead(lead)

        let sendResult = await sendNotification(
            userID: doorKnocker.id,
            leadID: lead.id,
            kind: .reminderRequest,
            title: "Remind prospect to confirm",
            message: "\(user.fullName) asked you to re-confirm \(lead.homeownerFullName)'s appointment."
        )
        await refreshLeadData()
        switch sendResult {
        case .success:
            return .sent
        case .failure(let message):
            return .failed(message)
        }
    }

    func updateCloserOutcome(leadID: UUID, outcome: LeadOutcome) async {
        guard let user = currentUser, var lead = leads.first(where: { $0.id == leadID }) else { return }

        let newStatus = outcome.resultingStatus
        let timestamp = Date()
        let outcomeNote: String
        lead.currentStatus = newStatus
        lead.updatedAt = timestamp

        if outcome == .rescheduled {
            outcomeNote = "Closer requested a new appointment time and returned the lead for re-confirmation"
            lead.statusHistory.insert(.init(id: UUID(), status: .appointmentRescheduled, changedByUserID: user.id, note: outcomeNote, changedAt: timestamp), at: 0)
        } else {
            outcomeNote = "Closer outcome updated to \(outcome.rawValue)"
            lead.statusHistory.insert(.init(id: UUID(), status: newStatus, changedByUserID: user.id, note: outcomeNote, changedAt: timestamp), at: 0)
        }

        _ = await services.leadService.updateLead(lead)
        guard let persistedLead = await verifyPersistedLead(
            leadID: lead.id,
            expectedStatus: newStatus,
            expectedAssignedCloserID: lead.assignedCloserID,
            expectedHistoryNotes: [outcomeNote]
        ) else {
            await refreshLeadData()
            return
        }
        await refreshLeadData()

        if outcome == .rescheduled {
            await sendNotification(
                userID: persistedLead.createdByDoorKnockerID,
                leadID: persistedLead.id,
                kind: .appointmentRescheduled,
                title: "Appointment needs to be re-confirmed",
                message: "\(persistedLead.homeownerFullName) was marked Rescheduled by the closer and needs a new confirmed appointment time."
            )
        } else {
            await sendNotification(
                userID: persistedLead.createdByDoorKnockerID,
                leadID: persistedLead.id,
                kind: .leadStatusUpdate,
                title: "Closer outcome recorded",
                message: "\(persistedLead.homeownerFullName) is now marked \(newStatus.rawValue)."
            )
        }

        if let manager = users.first(where: { $0.role == .manager && $0.orgID == persistedLead.orgID }) {
            await sendNotification(
                userID: manager.id,
                leadID: persistedLead.id,
                kind: .leadStatusUpdate,
                title: "Closer outcome recorded",
                message: "\(persistedLead.homeownerFullName) was updated to \(newStatus.rawValue) by \(user.fullName)."
            )
        }
    }

    func reassign(leadID: UUID, closerID: UUID) async {
        guard let user = currentUser, user.role == .manager, var lead = leads.first(where: { $0.id == leadID }) else { return }
        let previousCloserID = lead.assignedCloserID
        lead.assignedCloserID = closerID
        lead.updatedAt = Date()
        let reassignmentNote = previousCloserID == nil
            ? "Manager assigned closer to \(userName(for: closerID))"
            : "Manager reassigned closer from \(userName(for: previousCloserID)) to \(userName(for: closerID))"
        lead.statusHistory.insert(.init(id: UUID(), status: lead.currentStatus, changedByUserID: user.id, note: reassignmentNote, changedAt: Date()), at: 0)
        _ = await services.leadService.updateLead(lead)
        guard let persistedLead = await verifyPersistedLead(
            leadID: lead.id,
            expectedStatus: lead.currentStatus,
            expectedAssignedCloserID: closerID,
            expectedHistoryNotes: [reassignmentNote]
        ) else {
            await refreshLeadData()
            return
        }

        await sendNotification(
            userID: closerID,
            leadID: persistedLead.id,
            kind: .assignmentChanged,
            title: previousCloserID == nil ? "New lead assigned" : "Lead reassigned to you",
            message: "\(persistedLead.homeownerFullName) is now assigned to you."
        )

        await sendNotification(
            userID: persistedLead.createdByDoorKnockerID,
            leadID: persistedLead.id,
            kind: .assignmentChanged,
            title: "Closer assignment changed",
            message: "\(persistedLead.homeownerFullName) is now assigned to \(userName(for: closerID))."
        )

        if let previousCloserID, previousCloserID != closerID {
            await sendNotification(
                userID: previousCloserID,
                leadID: persistedLead.id,
                kind: .assignmentChanged,
                title: "Lead moved off your queue",
                message: "\(persistedLead.homeownerFullName) was reassigned to \(userName(for: closerID))."
            )
        }
        await refreshLeadData()
    }

    func leadsForCurrentUser() -> [Lead] {
        guard let currentUser else { return [] }
        switch currentUser.role {
        case .doorKnocker:
            return leads.filter { $0.createdByDoorKnockerID == currentUser.id }
        case .closer:
            return leads.filter { $0.assignedCloserID == currentUser.id && $0.currentStatus.isVisibleToCloser }
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

    private func sendNotification(userID: UUID, leadID: UUID?, kind: NotificationKind, title: String, message: String) async -> NotificationDeliveryResult {
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
        return await services.notificationService.upsert(notification)
    }

    private func markNotificationsRead(for leadID: UUID, kind: NotificationKind, userID: UUID) async {
        let existingNotifications = await services.notificationService.fetchNotifications(for: userID)
        for notification in existingNotifications where notification.leadID == leadID && notification.kind == kind && !notification.isRead {
            await services.notificationService.markRead(notificationID: notification.id)
        }
    }

    private func verifyPersistedLead(
        leadID: UUID,
        expectedStatus: LeadStatus,
        expectedAssignedCloserID: UUID?,
        expectedHistoryNotes: [String]
    ) async -> Lead? {
        guard let persistedLead = await services.leadService.fetchLead(id: leadID) else {
            return nil
        }

        guard persistedLead.currentStatus == expectedStatus else {
            return nil
        }

        guard persistedLead.assignedCloserID == expectedAssignedCloserID else {
            return nil
        }

        let persistedNotes = Set(persistedLead.statusHistory.map(\.note))
        guard expectedHistoryNotes.allSatisfy(persistedNotes.contains) else {
            return nil
        }

        return persistedLead
    }
}

enum NotificationDeliveryResult {
    case success
    case failure(String)
}
