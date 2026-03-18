import SwiftUI

struct ManagerPipelineBoardView: View {
    @EnvironmentObject private var appState: AppState

    private let boardColumns: [LeadStatus] = [
        .submitted,
        .pendingConfirmation,
        .onCloserSchedule,
        .appointmentRun,
        .closed,
        .needsFollowUp
    ]

    var body: some View {
        NavigationStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(boardColumns) { status in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(status.rawValue)
                                    .font(.headline)
                                Spacer()
                                Text("\(appState.leads.filter { $0.currentStatus == status }.count)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(appState.leads.filter { $0.currentStatus == status }) { lead in
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
                        .padding()
                        .frame(width: 300, alignment: .topLeading)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(20)
            }
            .navigationTitle("Pipeline Board")
        }
    }
}
