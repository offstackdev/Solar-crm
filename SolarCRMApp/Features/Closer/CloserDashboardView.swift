import SwiftUI

struct CloserDashboardView: View {
    @EnvironmentObject private var appState: AppState

    private let summaryColumns = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

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
            AppScreen(title: "Closer Dashboard") {
                LazyVGrid(columns: summaryColumns, alignment: .leading, spacing: 12) {
                    MetricCard(title: "Needs Confirmation", value: "\(pendingLeads.count)", systemImage: "tray.full", fill: AppTheme.surfaceHigh)
                    MetricCard(title: "Ready Appointments", value: "\(readyAppointments.count)", systemImage: "calendar.badge.clock", fill: AppTheme.primaryContainer)
                    MetricCard(title: "Running Now", value: "\(runningAppointments.count)", systemImage: "figure.walk.motion", fill: AppTheme.secondaryContainer, accent: AppTheme.secondary)
                    MetricCard(title: "Recent Outcomes", value: "\(recentOutcomes.prefix(7).count)", systemImage: "checkmark.seal", fill: AppTheme.surfaceLow, accent: AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    AppSectionHeader("Needs Confirmation")
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
                    AppSectionHeader("Ready To Run")
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
                    AppSectionHeader("Recently Completed")
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
            .navigationTitle("Closer Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
