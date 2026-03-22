import SwiftUI

struct ManagerDashboardView: View {
    @EnvironmentObject private var appState: AppState

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

    private var recentLeads: [Lead] {
        allLeads.sorted { $0.updatedAt > $1.updatedAt }.prefix(8).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 12) {
                            MetricCard(title: "Total Leads", value: "\(allLeads.count)", systemImage: "tray.full")
                            MetricCard(title: "Needs Confirmation", value: "\(needsConfirmation.count)", systemImage: "phone.badge.waveform")
                        }

                        HStack(spacing: 12) {
                            MetricCard(title: "Ready Appointments", value: "\(readyAppointments.count)", systemImage: "calendar")
                            MetricCard(title: "Running", value: "\(runningAppointments.count)", systemImage: "figure.walk.motion")
                        }

                        HStack(spacing: 12) {
                            MetricCard(title: "Completed", value: "\(completed.count)", systemImage: "checkmark.seal")
                            MetricCard(title: "Needs Follow-Up", value: "\(allLeads.filter { $0.currentStatus == .needsFollowUp }.count)", systemImage: "arrow.triangle.2.circlepath")
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Team Overview")
                                .font(.title3.bold())
                            ForEach(UserRole.allCases) { role in
                                HStack {
                                    Label(role.title, systemImage: role.symbolName)
                                    Spacer()
                                    Text("\(appState.users(for: role).count)")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Closer Load")
                                .font(.title3.bold())
                            ForEach(appState.users(for: .closer)) { closer in
                                let closerLeads = allLeads.filter { $0.assignedCloserID == closer.id }
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(closer.fullName)
                                            .font(.headline)
                                        Text("\(closerLeads.filter { $0.currentStatus == .onCloserSchedule || $0.currentStatus == .sentToCloser }.count) ready, \(closerLeads.filter { $0.currentStatus.isCompletedCloserOutcome }.count) completed")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(closerLeads.count)")
                                        .font(.title3.bold())
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Lead Activity")
                                .font(.title3.bold())
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
                    .padding(20)
                    .padding(.bottom, 110)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Manager")
        }
    }
}
