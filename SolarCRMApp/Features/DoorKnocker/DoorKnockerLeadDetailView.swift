import SwiftUI

struct DoorKnockerLeadDetailView: View {
    @EnvironmentObject private var appState: AppState
    let leadID: UUID

    private var lead: Lead? {
        appState.leads.first(where: { $0.id == leadID })
    }

    var body: some View {
        List {
            if let lead {
                Section("Lead") {
                    LabeledContent("Homeowner", value: lead.homeownerFullName)
                    LabeledContent("Phone", value: lead.phoneNumber)
                    LabeledContent("Address", value: "\(lead.propertyAddress), \(lead.city), \(lead.state) \(lead.zipCode)")
                    LabeledContent("Utility", value: lead.utilityCompany)
                    LabeledContent("Appointment", value: lead.appointmentDateText)
                    HStack {
                        Text("Status")
                        Spacer()
                        StatusBadge(status: lead.currentStatus)
                    }
                }

                Section("Actions") {
                    if lead.currentStatus.isVisibleOnDoorKnockerActiveBoard {
                        Button("Appointment Confirmed") {
                            Task {
                                await appState.updateLeadStatus(
                                    leadID: leadID,
                                    status: .appointmentConfirmed,
                                    note: "Door knocker confirmed the appointment with prospect"
                                )
                            }
                        }

                        Button("Appointment Canceled") {
                            Task {
                                await appState.updateLeadStatus(
                                    leadID: leadID,
                                    status: .appointmentCanceled,
                                    note: "Door knocker canceled appointment after homeowner update"
                                )
                            }
                        }

                        Button("Appointment Rescheduled") {
                            Task {
                                await appState.updateLeadStatus(
                                    leadID: leadID,
                                    status: .appointmentRescheduled,
                                    note: "Door knocker rescheduled appointment"
                                )
                            }
                        }
                    } else {
                        Text("This lead has been handed off. You can monitor updates here, but closer workflow controls are locked.")
                            .font(.subheadline)
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
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Lead Detail")
    }
}
