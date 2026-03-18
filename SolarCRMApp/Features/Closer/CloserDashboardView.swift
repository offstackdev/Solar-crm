import SwiftUI

struct CloserDashboardView: View {
    @EnvironmentObject private var appState: AppState

    private var myLeads: [Lead] {
        appState.leadsForCurrentUser()
    }

    private var pendingLeads: [Lead] {
        myLeads.filter { $0.currentStatus.isVisibleInCloserLeads }
    }

    private var scheduledLeads: [Lead] {
        myLeads.filter { $0.currentStatus.isConfirmedForCloserSchedule }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 12) {
                            MetricCard(title: "Assigned Leads", value: "\(pendingLeads.count)", systemImage: "tray.full")
                            MetricCard(title: "On Schedule", value: "\(scheduledLeads.count)", systemImage: "calendar.badge.clock")
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Leads")
                                .font(.title3.bold())
                            if pendingLeads.isEmpty {
                                EmptyStateView(title: "No assigned leads", message: "Door knocker leads that still need confirmation or follow-through will appear here.", systemImage: "tray")
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
                                EmptyStateView(title: "Nothing on schedule", message: "Once the door knocker confirms the appointment, it moves here for closer execution.", systemImage: "calendar")
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
                    .padding(.bottom, 110)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Closer Dashboard")
        }
    }
}
