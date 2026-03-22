import SwiftUI

struct AssignmentManagerView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                Section("Door Knocker to Closer Coverage") {
                    ForEach(appState.users(for: .doorKnocker)) { knocker in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(knocker.fullName)
                                .font(.headline)
                            Text("Assigned closer: \(appState.userName(for: knocker.assignedCloserID))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Lead Reassignment") {
                    ForEach(appState.leads.sorted { $0.updatedAt > $1.updatedAt }) { lead in
                        ManagerLeadAssignmentRow(lead: lead)
                    }
                }
            }
            .navigationTitle("Assignments")
        }
    }
}

struct ManagerLeadAssignmentRow: View {
    @EnvironmentObject private var appState: AppState
    let lead: Lead
    @State private var selectedCloserID: UUID?
    @State private var message: String?
    @State private var isSaving = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lead.homeownerFullName)
                        .font(.headline)
                    Text(lead.propertyAddress)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: lead.currentStatus)
            }

            Text("Door knocker: \(appState.userName(for: lead.createdByDoorKnockerID))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Closer", selection: $selectedCloserID) {
                ForEach(appState.users(for: .closer)) { closer in
                    Text(closer.fullName).tag(Optional(closer.id))
                }
            }
            .onAppear {
                selectedCloserID = lead.assignedCloserID
            }

            Button {
                guard let selectedCloserID else { return }
                Task {
                    isSaving = true
                    await appState.reassign(leadID: lead.id, closerID: selectedCloserID)
                    message = "Assigned to \(appState.userName(for: selectedCloserID))."
                    isSaving = false
                }
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                    }
                    Text("Reassign Lead")
                }
            }
            .buttonStyle(.bordered)
            .disabled(isSaving || selectedCloserID == nil || selectedCloserID == lead.assignedCloserID)

            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
