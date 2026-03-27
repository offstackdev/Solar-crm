import SwiftUI

struct ManagerDashboardView: View {
    @EnvironmentObject private var appState: AppState

    private let summaryColumns = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

    private var allLeads: [Lead] {
        appState.leads
    }

    private var needsConfirmation: [Lead] {
        allLeads.filter { $0.currentStatus == .submitted || $0.currentStatus == .pendingConfirmation || $0.currentStatus == .appointmentRescheduled }
    }

    private var readyAppointments: [Lead] {
        allLeads.filter { $0.currentStatus == .sentToCloser || $0.currentStatus == .onCloserSchedule }
    }

    private var runningAppointments: [Lead] {
        allLeads.filter { $0.currentStatus == .appointmentRun }
    }

    private var completed: [Lead] {
        allLeads.filter { $0.currentStatus.isCompletedCloserOutcome }
    }

    private var needsFollowUp: [Lead] {
        allLeads.filter { $0.currentStatus == .needsFollowUp }
    }

    private var recentLeads: [Lead] {
        allLeads.sorted { $0.updatedAt > $1.updatedAt }.prefix(8).map { $0 }
    }

    var body: some View {
        NavigationStack {
            AppScreen(title: "Manager") {
                LazyVGrid(columns: summaryColumns, alignment: .leading, spacing: 12) {
                    MetricCard(title: "Total Leads", value: "\(allLeads.count)", systemImage: "tray.full")
                    MetricCard(title: "Needs Confirmation", value: "\(needsConfirmation.count)", systemImage: "phone.badge.waveform")
                    MetricCard(title: "Ready Appointments", value: "\(readyAppointments.count)", systemImage: "calendar")
                    MetricCard(title: "Running", value: "\(runningAppointments.count)", systemImage: "figure.walk.motion")
                    MetricCard(title: "Completed", value: "\(completed.count)", systemImage: "checkmark.seal")
                    MetricCard(title: "Needs Follow-Up", value: "\(needsFollowUp.count)", systemImage: "arrow.triangle.2.circlepath")
                }

                VStack(alignment: .leading, spacing: 12) {
                    AppSectionHeader("Team Overview")
                    ForEach(UserRole.allCases) { role in
                        AppOutlinedSurface {
                            HStack {
                                Label(role.title, systemImage: role.symbolName)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(AppTheme.onSurface)
                                Spacer()
                                Text("\(appState.users(for: role).count)")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.primary)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    AppSectionHeader("Closer Load")
                    ForEach(appState.users(for: .closer)) { closer in
                        let closerLeads = allLeads.filter { $0.assignedCloserID == closer.id }
                        AppOutlinedSurface {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(closer.fullName)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.onSurface)
                                    Text("\(closerLeads.filter { $0.currentStatus == .onCloserSchedule || $0.currentStatus == .sentToCloser }.count) ready, \(closerLeads.filter { $0.currentStatus.isCompletedCloserOutcome }.count) completed")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.onSurfaceVariant)
                                }
                                Spacer()
                                Text("\(closerLeads.count)")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.primary)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    AppSectionHeader("Recent Lead Activity")
                    ForEach(recentLeads) { lead in
                        NavigationLink {
                            ManagerLeadDetailView(leadID: lead.id)
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
            .navigationTitle("Manager")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
