import SwiftUI

struct CloserLeadDetailView: View {
    @EnvironmentObject private var appState: AppState
    let leadID: UUID
    @State private var selectedOutcome: LeadOutcome = .closed

    private var lead: Lead? {
        appState.leads.first(where: { $0.id == leadID })
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
                    Button("Remind to Confirm Appointment") {
                        Task { await appState.requestReminder(for: leadID) }
                    }

                    if lead.currentStatus.isConfirmedForCloserSchedule {
                        Button("Mark Appointment Run") {
                            Task {
                                await appState.updateLeadStatus(
                                    leadID: leadID,
                                    status: .appointmentRun,
                                    note: "Closer is running the appointment"
                                )
                            }
                        }
                    }
                }

                Section("Outcome") {
                    Picker("Result", selection: $selectedOutcome) {
                        ForEach(LeadOutcome.allCases) { outcome in
                            Text(outcome.rawValue).tag(outcome)
                        }
                    }

                    Button("Save Outcome") {
                        Task { await appState.updateCloserOutcome(leadID: leadID, outcome: selectedOutcome) }
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
    }
}
