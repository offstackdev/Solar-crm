import SwiftUI

struct ManagerLeadDetailView: View {
    @EnvironmentObject private var appState: AppState
    let leadID: UUID

    private var lead: Lead? {
        appState.leads.first(where: { $0.id == leadID })
    }

    var body: some View {
        List {
            if let lead {
                Section("Lead Snapshot") {
                    LabeledContent("Homeowner", value: lead.homeownerFullName)
                    LabeledContent("Door Knocker", value: appState.userName(for: lead.createdByDoorKnockerID))
                    LabeledContent("Closer", value: appState.userName(for: lead.assignedCloserID))
                    LabeledContent("Status", value: lead.currentStatus.rawValue)
                    LabeledContent("Appointment", value: lead.appointmentDateText)
                }

                Section("Solar Qualifiers") {
                    LabeledContent("Homeowner Type", value: lead.homeownerType)
                    LabeledContent("Average Bill", value: lead.averageElectricBill)
                    LabeledContent("Roof Type", value: lead.roofType)
                    LabeledContent("Shading", value: lead.shadingNotes)
                    LabeledContent("Decision Maker Present", value: lead.decisionMakerPresent ? "Yes" : "No")
                    LabeledContent("Spouse Required", value: lead.spousePresentRequired ? "Yes" : "No")
                }

                Section("History") {
                    ForEach(lead.statusHistory) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.status.rawValue)
                                .font(.headline)
                            Text(item.note)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(item.changedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Lead Admin")
    }
}
