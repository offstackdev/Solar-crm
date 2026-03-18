import SwiftUI

struct ManagerDashboardView: View {
    @EnvironmentObject private var appState: AppState

    private var allLeads: [Lead] {
        appState.leads
    }

    private var appointments: [Lead] {
        allLeads.filter { $0.appointmentDate != nil }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        MetricCard(title: "Total Leads", value: "\(allLeads.count)", systemImage: "tray.full")
                        MetricCard(title: "Closed", value: "\(allLeads.filter { $0.currentStatus == .closed }.count)", systemImage: "checkmark.seal")
                    }

                    HStack(spacing: 12) {
                        MetricCard(title: "Needs Follow-Up", value: "\(allLeads.filter { $0.currentStatus == .needsFollowUp }.count)", systemImage: "arrow.triangle.2.circlepath")
                        MetricCard(title: "Appointments", value: "\(appointments.count)", systemImage: "calendar")
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
                        Text("All Leads")
                            .font(.title3.bold())
                        ForEach(allLeads) { lead in
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
            }
            .navigationTitle("Manager")
        }
    }
}
