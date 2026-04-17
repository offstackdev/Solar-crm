import SwiftUI

struct CloserLeadDetailView: View {
    @EnvironmentObject private var appState: AppState

    let leadID: UUID

    @State private var selectedOutcome: LeadOutcome = .closed
    @State private var isRequestingReminder = false
    @State private var isSavingOutcome = false
    @State private var reminderMessage: String?
    @State private var outcomeMessage: String?

    private var lead: Lead? {
        appState.leads.first(where: { $0.id == leadID })
    }

    private var canRequestReminder: Bool {
        guard let lead else { return false }
        return lead.currentStatus == .submitted || lead.currentStatus == .pendingConfirmation || lead.currentStatus == .appointmentRescheduled
    }

    private var canMarkAppointmentRun: Bool {
        guard let lead else { return false }
        return lead.currentStatus == .onCloserSchedule || lead.currentStatus == .sentToCloser
    }

    private var canSaveOutcome: Bool {
        lead?.currentStatus == .appointmentRun
    }

    private var hasRecordedFinalOutcome: Bool {
        guard let lead else { return false }
        switch lead.currentStatus {
        case .closed, .oneLegger, .needsFollowUp, .noShow, .notInterested, .appointmentRescheduled:
            return true
        default:
            return false
        }
    }

    var body: some View {
        List {
            if let lead {
                Section("Lead") {
                    LabeledContent("Homeowner", value: lead.homeownerFullName)
                    LabeledContent("Phone", value: lead.phoneNumber)
                    LabeledContent("Address", value: "\(lead.propertyAddress), \(lead.city)")
                    LabeledContent("Door Knocker", value: appState.userName(for: lead.createdByDoorKnockerID))
                    LabeledContent("Appointment", value: lead.appointmentDateText)
                    HStack {
                        Text("Status")
                        Spacer()
                        StatusBadge(status: lead.currentStatus)
                    }
                }

                Section("Closer Actions") {
                    if canRequestReminder {
                        Button(action: requestReminder) {
                            HStack {
                                if isRequestingReminder {
                                    ProgressView()
                                }
                                Text("Remind to Confirm Appointment")
                            }
                        }
                        .disabled(isRequestingReminder)
                    }

                    if let reminderMessage {
                        Text(reminderMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if canMarkAppointmentRun {
                        Button("Mark Appointment Run", action: markAppointmentRun)
                    }

                    if lead.currentStatus == .appointmentRun {
                        Text("Appointment is marked as run. Record the outcome below.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Outcome") {
                    if hasRecordedFinalOutcome && !canSaveOutcome {
                        Text("Current outcome: \(lead.currentStatus.rawValue)")
                            .font(.subheadline)
                    } else {
                        Picker("Result", selection: $selectedOutcome) {
                            ForEach(LeadOutcome.allCases) { outcome in
                                Text(outcome.rawValue).tag(outcome)
                            }
                        }

                        Button(action: saveOutcome) {
                            HStack {
                                if isSavingOutcome {
                                    ProgressView()
                                }
                                Text("Save Outcome")
                            }
                        }
                        .disabled(!canSaveOutcome || isSavingOutcome)

                        if !canSaveOutcome && !hasRecordedFinalOutcome {
                            Text("Mark the appointment as run before recording an outcome.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let outcomeMessage {
                        Text(outcomeMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notes") {
                    Text(lead.notes.isEmpty ? "No notes" : lead.notes)
                }

                Section("History") {
                    ForEach(lead.statusHistory) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                StatusBadge(status: item.status)
                                Spacer()
                                Text(item.changedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(item.note)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle("Lead Detail")
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .tint(AppTheme.primary)
        .task(id: lead?.currentStatus) {
            selectedOutcome = outcomeSelection(for: lead?.currentStatus)
        }
    }

    private func requestReminder() {
        Task {
            isRequestingReminder = true
            defer { isRequestingReminder = false }

            let result = await appState.requestReminder(for: leadID)
            switch result {
            case .sent:
                reminderMessage = "Reminder sent to \(appState.userName(for: lead?.createdByDoorKnockerID))."
            case .alreadyPending:
                reminderMessage = "A reminder is already pending for this lead."
            case .failed(let message):
                reminderMessage = message
            }
        }
    }

    private func markAppointmentRun() {
        Task {
            await appState.updateLeadStatus(
                leadID: leadID,
                status: .appointmentRun,
                note: "Closer is running the appointment"
            )
        }
    }

    private func saveOutcome() {
        Task {
            isSavingOutcome = true
            defer { isSavingOutcome = false }

            await appState.updateCloserOutcome(leadID: leadID, outcome: selectedOutcome)
            outcomeMessage = selectedOutcome == .rescheduled
                ? "Outcome saved. The lead was returned for appointment re-confirmation."
                : "Outcome saved and shared back with the door knocker."
        }
    }

    private func outcomeSelection(for status: LeadStatus?) -> LeadOutcome {
        switch status {
        case .closed:
            return .closed
        case .oneLegger:
            return .oneLegger
        case .needsFollowUp:
            return .needsFollowUp
        case .noShow:
            return .noShow
        case .appointmentRescheduled:
            return .rescheduled
        case .notInterested:
            return .notInterested
        default:
            return selectedOutcome
        }
    }
}
