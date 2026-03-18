import SwiftUI

struct CloserScheduleView: View {
    @EnvironmentObject private var appState: AppState

    private var scheduleLeads: [Lead] {
        appState.leadsForCurrentUser()
            .filter { $0.currentStatus.isConfirmedForCloserSchedule }
            .sorted { ($0.appointmentDate ?? .distantFuture) < ($1.appointmentDate ?? .distantFuture) }
    }

    var body: some View {
        NavigationStack {
            List {
                if scheduleLeads.isEmpty {
                    EmptyStateView(title: "No scheduled appointments", message: "Confirmed leads move here automatically.", systemImage: "calendar.badge.exclamationmark")
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(scheduleLeads) { lead in
                        NavigationLink {
                            CloserLeadDetailView(leadID: lead.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(lead.homeownerFullName)
                                    .font(.headline)
                                Text(lead.appointmentDateText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(lead.propertyAddress)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Schedule")
        }
    }
}
