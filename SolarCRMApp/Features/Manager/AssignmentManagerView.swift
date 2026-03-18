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
                    ForEach(appState.leads) { lead in
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lead.homeownerFullName)
                .font(.headline)
            Text(lead.propertyAddress)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Picker("Closer", selection: $selectedCloserID) {
                ForEach(appState.users(for: .closer)) { closer in
                    Text(closer.fullName).tag(Optional(closer.id))
                }
            }
            .onAppear {
                selectedCloserID = lead.assignedCloserID
            }

            Button("Reassign Lead") {
                guard let selectedCloserID else { return }
                Task { await appState.reassign(leadID: lead.id, closerID: selectedCloserID) }
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 6)
    }
}
