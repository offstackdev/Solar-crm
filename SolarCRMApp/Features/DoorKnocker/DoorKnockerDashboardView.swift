import SwiftUI

struct DoorKnockerDashboardView: View {
    @EnvironmentObject private var appState: AppState

    private var myLeads: [Lead] {
        appState.leadsForCurrentUser()
    }

    private var activeLeads: [Lead] {
        myLeads.filter { $0.currentStatus.isVisibleOnDoorKnockerActiveBoard }
    }

    private var handoffLeads: [Lead] {
        myLeads.filter { !$0.currentStatus.isVisibleOnDoorKnockerActiveBoard }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 12) {
                            MetricCard(title: "Active Leads", value: "\(activeLeads.count)", systemImage: "person.3.sequence")
                            MetricCard(title: "Handed Off", value: "\(handoffLeads.count)", systemImage: "arrowshape.turn.up.right")
                        }

                        NavigationLink {
                            NewLeadFlowView()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create New Lead")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Leads")
                                .font(.title3.bold())
                            if activeLeads.isEmpty {
                                EmptyStateView(title: "No active leads", message: "New leads and pending confirmations will appear here.", systemImage: "tray")
                            } else {
                                ForEach(activeLeads) { lead in
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
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Closer Updates")
                                .font(.title3.bold())
                            if handoffLeads.isEmpty {
                                EmptyStateView(title: "No handoff history yet", message: "Once appointments are confirmed, closer updates will appear here.", systemImage: "clock.arrow.circlepath")
                            } else {
                                ForEach(handoffLeads.prefix(5)) { lead in
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
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 110)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Field Dashboard")
        }
    }
}
