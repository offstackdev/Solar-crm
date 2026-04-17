import SwiftUI

struct ManagerPipelineBoardView: View {
    @EnvironmentObject private var appState: AppState

    private let boardColumns: [ManagerPipelineColumn] = [
        .init(title: "Needs Confirmation", statuses: [.submitted, .pendingConfirmation, .appointmentRescheduled]),
        .init(title: "Ready To Run", statuses: [.sentToCloser, .onCloserSchedule]),
        .init(title: "Appointment Run", statuses: [.appointmentRun]),
        .init(title: "Needs Follow-Up", statuses: [.needsFollowUp, .oneLegger]),
        .init(title: "Closed", statuses: [.closed]),
        .init(title: "No Sale", statuses: [.noShow, .notInterested, .appointmentCanceled])
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(boardColumns) { column in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(column.title)
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(AppTheme.onSurface)
                                    Spacer()
                                    Text("\(leads(in: column).count)")
                                        .font(.caption.weight(.black))
                                        .foregroundStyle(AppTheme.onSurfaceVariant)
                                }

                                ForEach(leads(in: column)) { lead in
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

                                Spacer()
                            }
                            .padding(20)
                            .frame(width: 320, alignment: .topLeading)
                            .background(AppTheme.surfaceLow, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Pipeline Board")
        }
    }

    private func leads(in column: ManagerPipelineColumn) -> [Lead] {
        appState.leads
            .filter { column.statuses.contains($0.currentStatus) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}

private struct ManagerPipelineColumn: Identifiable {
    let id = UUID()
    let title: String
    let statuses: [LeadStatus]
}
