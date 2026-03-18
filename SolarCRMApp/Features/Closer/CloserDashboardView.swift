import SwiftUI

struct CloserDashboardView: View {
    @EnvironmentObject private var appState: AppState

    private var myLeads: [Lead] {
        appState.leadsForCurrentUser()
    }

    private var pendingLeads: [Lead] {
        myLeads.filter { !$0.currentStatus.isConfirmedForCloserSchedule }
    }

    private var scheduledLeads: [Lead] {
        myLeads.filter { $0.currentStatus.isConfirmedForCloserSchedule }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        MetricCard(title: "Assigned Leads", value: "\(myLeads.count)", systemImage: "tray.full")
                        MetricCard(title: "On Schedule", value: "\(scheduledLeads.count)", systemImage: "calendar.badge.clock")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Leads")
                            .font(.title3.bold())
                        if pendingLeads.isEmpty {
                            EmptyStateView(title: "No pending leads", message: "Assigned leads that still need confirmation work will show here.", systemImage: "tray")
                        } else {
                            ForEach(pendingLeads) { lead in
                                NavigationLink {
                                    CloserLeadDetailView(leadID: lead.id)
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
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Appointments")
                            .font(.title3.bold())
                        if scheduledLeads.isEmpty {
                            EmptyStateView(title: "Nothing on schedule", message: "Confirmed appointments move here for closer execution.", systemImage: "calendar")
                        } else {
                            ForEach(scheduledLeads) { lead in
                                NavigationLink {
                                    CloserLeadDetailView(leadID: lead.id)
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
                    }
                }
                .padding(20)
            }
            .navigationTitle("Closer Dashboard")
        }
    }
}
