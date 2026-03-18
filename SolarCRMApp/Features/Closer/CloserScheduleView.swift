import SwiftUI

struct CloserScheduleView: View {
    @EnvironmentObject private var appState: AppState

    private var readyLeads: [Lead] {
        appState.leadsForCurrentUser()
            .filter { $0.currentStatus == .onCloserSchedule || $0.currentStatus == .sentToCloser }
            .sorted { ($0.appointmentDate ?? .distantFuture) < ($1.appointmentDate ?? .distantFuture) }
    }

    private var runningLeads: [Lead] {
        appState.leadsForCurrentUser()
            .filter { $0.currentStatus == .appointmentRun }
            .sorted { ($0.appointmentDate ?? .distantFuture) < ($1.appointmentDate ?? .distantFuture) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Ready To Run") {
                    if readyLeads.isEmpty {
                        EmptyStateView(title: "No scheduled appointments", message: "Confirmed leads move here automatically.", systemImage: "calendar.badge.exclamationmark")
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(readyLeads) { lead in
                            NavigationLink {
                                CloserLeadDetailView(leadID: lead.id)
                            } label: {
                                CloserLeadCardView(
                                    lead: lead,
                                    doorKnockerName: appState.userName(for: lead.createdByDoorKnockerID)
                                )
                            }
                        }
                    }
                }

                Section("Appointment Run") {
                    if runningLeads.isEmpty {
                        Text("Appointments you have started will stay here until an outcome is saved.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(runningLeads) { lead in
                            NavigationLink {
                                CloserLeadDetailView(leadID: lead.id)
                            } label: {
                                CloserLeadCardView(
                                    lead: lead,
                                    doorKnockerName: appState.userName(for: lead.createdByDoorKnockerID)
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Schedule")
        }
    }
}
