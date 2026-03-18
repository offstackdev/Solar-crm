import SwiftUI

struct CloserDashboardView: View {
    @EnvironmentObject private var appState: AppState

    private var myLeads: [Lead] {
        appState.leadsForCurrentUser()
    }

    private var pendingLeads: [Lead] {
        myLeads.filter { $0.currentStatus.isVisibleInCloserLeads }
    }

    private var readyAppointments: [Lead] {
        myLeads.filter { $0.currentStatus == .onCloserSchedule || $0.currentStatus == .sentToCloser }
            .sorted { ($0.appointmentDate ?? .distantFuture) < ($1.appointmentDate ?? .distantFuture) }
    }

    private var runningAppointments: [Lead] {
        myLeads.filter { $0.currentStatus == .appointmentRun }
    }

    private var recentOutcomes: [Lead] {
        myLeads.filter { $0.currentStatus.isCompletedCloserOutcome }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 12) {
                            MetricCard(title: "Needs Confirmation", value: "\(pendingLeads.count)", systemImage: "tray.full")
                            MetricCard(title: "Ready Appointments", value: "\(readyAppointments.count)", systemImage: "calendar.badge.clock")
                        }

                        HStack(spacing: 12) {
                            MetricCard(title: "Running Now", value: "\(runningAppointments.count)", systemImage: "figure.walk.motion")
                            MetricCard(title: "Recent Outcomes", value: "\(recentOutcomes.prefix(7).count)", systemImage: "checkmark.seal")
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Needs Confirmation")
                                .font(.title3.bold())
                            if pendingLeads.isEmpty {
                                EmptyStateView(title: "No assigned leads", message: "Door knocker leads that still need confirmation or follow-through will appear here.", systemImage: "tray")
                            } else {
                                ForEach(pendingLeads) { lead in
                                    NavigationLink {
                                        CloserLeadDetailView(leadID: lead.id)
                                    } label: {
                                        CloserLeadCardView(
                                            lead: lead,
                                            doorKnockerName: appState.userName(for: lead.createdByDoorKnockerID)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ready To Run")
                                .font(.title3.bold())
                            if readyAppointments.isEmpty {
                                EmptyStateView(title: "Nothing ready", message: "Once the door knocker confirms the appointment, it moves here for closer execution.", systemImage: "calendar")
                            } else {
                                ForEach(readyAppointments) { lead in
                                    NavigationLink {
                                        CloserLeadDetailView(leadID: lead.id)
                                    } label: {
                                        CloserLeadCardView(
                                            lead: lead,
                                            doorKnockerName: appState.userName(for: lead.createdByDoorKnockerID)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recently Completed")
                                .font(.title3.bold())
                            if recentOutcomes.isEmpty {
                                EmptyStateView(title: "No completed outcomes", message: "Saved appointment outcomes will appear here after the closer updates them.", systemImage: "checkmark.circle")
                            } else {
                                ForEach(recentOutcomes.prefix(5)) { lead in
                                    NavigationLink {
                                        CloserLeadDetailView(leadID: lead.id)
                                    } label: {
                                        CloserLeadCardView(
                                            lead: lead,
                                            doorKnockerName: appState.userName(for: lead.createdByDoorKnockerID)
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
