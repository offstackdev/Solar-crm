import SwiftUI

struct AssignmentManagerView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            AppScreen(title: "Assignments") {
                VStack(alignment: .leading, spacing: 12) {
                    AppSectionHeader("Door Knocker to Closer Coverage")
                    ForEach(appState.users(for: .doorKnocker)) { knocker in
                        AppSurface {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(knocker.fullName)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(AppTheme.onSurface)
                                Text("Assigned closer: \(appState.userName(for: knocker.assignedCloserID))")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.onSurfaceVariant)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    AppSectionHeader("Lead Reassignment")
                    ForEach(appState.leads.sorted { $0.updatedAt > $1.updatedAt }) { lead in
                        ManagerLeadAssignmentRow(lead: lead)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
        AppOutlinedSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lead.homeownerFullName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.onSurface)
                        Text(lead.propertyAddress)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.onSurfaceVariant)
                    }
                    Spacer()
                    StatusBadge(status: lead.currentStatus)
                }

                Text("Door knocker: \(appState.userName(for: lead.createdByDoorKnockerID))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.onSurfaceVariant)

                Picker("Closer", selection: $selectedCloserID) {
                    ForEach(appState.users(for: .closer)) { closer in
                        Text(closer.fullName).tag(Optional(closer.id))
                    }
                }
                .task(id: lead.assignedCloserID) {
                    selectedCloserID = lead.assignedCloserID
                }

                Button(action: reassignLead) {
                    HStack {
                        if isSaving {
                            ProgressView()
                        }
                        Text("Reassign Lead")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.primaryContainer.opacity(0.22), in: Capsule())
                    .foregroundStyle(AppTheme.primary)
                }
                .buttonStyle(.plain)
                .disabled(isSaving || selectedCloserID == nil || selectedCloserID == lead.assignedCloserID)

                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
            }
        }
    }

    private func reassignLead() {
        guard let selectedCloserID else { return }

        Task {
            isSaving = true
            defer { isSaving = false }

            await appState.reassign(leadID: lead.id, closerID: selectedCloserID)
            message = "Assigned to \(appState.userName(for: selectedCloserID))."
        }
    }
}
