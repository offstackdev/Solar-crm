import SwiftUI

struct DoorKnockerDashboardView: View {
    @EnvironmentObject private var appState: AppState

    private let summaryColumns = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

    private var myLeads: [Lead] {
        appState.leadsForCurrentUser()
    }

    private var activeLeads: [Lead] {
        myLeads.filter { $0.currentStatus.isVisibleOnDoorKnockerActiveBoard }
    }

    private var handoffLeads: [Lead] {
        myLeads
            .filter { !$0.currentStatus.isVisibleOnDoorKnockerActiveBoard }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private var greetingName: String {
        appState.currentUser?.fullName.split(separator: " ").first.map(String.init) ?? "there"
    }

    var body: some View {
        NavigationStack {
            AppScreen(title: "Field Work") {
                AppSurface(fill: AppTheme.surfaceHigh) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Good morning, \(greetingName).")
                            .font(.title3.weight(.semibold))

                        Text("You have \(activeLeads.count) active leads and \(handoffLeads.count) recent handoffs.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.onSurfaceVariant)
                    }
                }

                LazyVGrid(columns: summaryColumns, alignment: .leading, spacing: 12) {
                    MetricCard(title: "Active Leads", value: "\(activeLeads.count)", systemImage: "person.2.fill")
                    MetricCard(
                        title: "Handed Off",
                        value: "\(handoffLeads.count)",
                        systemImage: "arrowshape.turn.up.right.fill",
                        fill: AppTheme.primaryContainer,
                        accent: AppTheme.primary
                    )
                }

                NavigationLink {
                    NewLeadFlowView()
                } label: {
                    Label("Add New Lead", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                VStack(alignment: .leading, spacing: 12) {
                    AppSectionHeader("My Leads")

                    if activeLeads.isEmpty {
                        EmptyStateView(
                            title: "No active leads",
                            message: "New leads and pending confirmations will appear here.",
                            systemImage: "tray"
                        )
                    } else {
                        ForEach(activeLeads) { lead in
                            leadRow(for: lead)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    AppSectionHeader("Recent Closer Updates")

                    if handoffLeads.isEmpty {
                        EmptyStateView(
                            title: "No closer updates yet",
                            message: "Once appointments move forward, their status updates will show up here.",
                            systemImage: "calendar.badge.clock"
                        )
                    } else {
                        ForEach(handoffLeads.prefix(5)) { lead in
                            leadRow(for: lead)
                        }
                    }
                }
            }
            .navigationTitle("Field Work")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func leadRow(for lead: Lead) -> some View {
        NavigationLink {
            DoorKnockerLeadDetailView(leadID: lead.id)
        } label: {
            LeadCardView(
                lead: lead,
                doorKnockerName: appState.userName(for: lead.createdByDoorKnockerID),
                closerName: appState.userName(for: lead.assignedCloserID)
            )
        }
        .buttonStyle(.plain)
    }
}
