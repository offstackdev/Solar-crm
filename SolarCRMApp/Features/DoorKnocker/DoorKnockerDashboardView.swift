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
        myLeads
            .filter { !$0.currentStatus.isVisibleOnDoorKnockerActiveBoard }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private var greetingWord: String {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    private var periodEmoji: String {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: Date())
        return (5..<17).contains(hour) ? "☀️" : "🌙"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        topBar
                        greetingHeader
                        summaryBlock
                        metricRow
                        myLeadsSection
                        recentCloserUpdatesSection
                        addLeadButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 132)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var topBar: some View {
        HStack(spacing: 18) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(AppTheme.onSurface)
                .frame(width: 32, height: 32)

            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.onSurface)
                .frame(width: 32, height: 32)
        }
    }

    private var greetingHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(greetingWord)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(AppTheme.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(periodEmoji)
                .font(.system(size: 24))
        }
        .padding(.top, 8)
    }

    private var summaryBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("You have \(activeLeads.count) active \(leadWord(for: activeLeads.count)) and \(handoffLeads.count) recent \(handoffWord(for: handoffLeads.count)).")
                .font(.subheadline)
                .foregroundStyle(AppTheme.onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 10)
    }

    private var metricRow: some View {
        HStack(spacing: 16) {
            DashboardMetricCard(
                title: "Active Leads",
                value: activeLeads.count,
                systemImage: "person.2.fill"
            )

            DashboardMetricCard(
                title: "Handed Off",
                value: handoffLeads.count,
                systemImage: "arrowshape.turn.up.right.fill"
            )
        }
        .padding(.top, 0)
    }

    private var myLeadsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Leads")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.onSurface)

            if activeLeads.isEmpty {
                CompactEmptyCard(message: "New leads and pending confirmations will appear here.")
            } else {
                VStack(spacing: 12) {
                    ForEach(activeLeads) { lead in
                        leadLink(for: lead, style: .active)
                    }
                }
            }
        }
    }

    private var recentCloserUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Closer Updates")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.onSurface)

            if handoffLeads.isEmpty {
                CompactEmptyCard(message: "Once appointments move forward, their status updates will show up here.")
            } else {
                VStack(spacing: 12) {
                    ForEach(handoffLeads.prefix(5)) { lead in
                        leadLink(for: lead, style: .handoff)
                    }
                }
            }
        }
    }

    private var addLeadButton: some View {
        HStack {
            Spacer()

            NavigationLink {
                NewLeadFlowView()
            } label: {
                Label("Add New Lead", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(AppTheme.primary, in: Capsule())
            }

            Spacer()
        }
        .padding(.top, -4)
    }

    private func leadLink(for lead: Lead, style: DashboardLeadCard.Style) -> some View {
        NavigationLink {
            DoorKnockerLeadDetailView(leadID: lead.id)
        } label: {
            DashboardLeadCard(
                lead: lead,
                doorKnockerName: appState.userName(for: lead.createdByDoorKnockerID),
                style: style
            )
        }
        .buttonStyle(.plain)
    }

    private func leadWord(for count: Int) -> String {
        count == 1 ? "lead" : "leads"
    }

    private func handoffWord(for count: Int) -> String {
        count == 1 ? "handoff" : "handoffs"
    }
}

private struct DashboardMetricCard: View {
    let title: String
    let value: Int
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 24, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(AppTheme.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text("\(value)")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.onSurface)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: Color.black.opacity(0.14), radius: 8, x: 0, y: 5)
        .overlay(alignment: .topTrailing) {
            Text("\(value)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(AppTheme.primary, in: Circle())
                .offset(x: 7, y: -12)
        }
    }
}

private struct DashboardLeadCard: View {
    enum Style {
        case active
        case handoff
    }

    let lead: Lead
    let doorKnockerName: String
    let style: Style

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(lead.homeownerFullName)
                        .font(.headline)
                        .foregroundStyle(AppTheme.onSurface)
                        .lineLimit(1)

                    Text("\(lead.propertyAddress), \(lead.city)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 10)

                StatusBadge(status: lead.currentStatus)
                    .lineLimit(1)
                    .fixedSize()
            }

            HStack(spacing: 10) {
                MetaLabel(systemImage: "person", text: doorKnockerName)
                if lead.appointmentDate != nil {
                    MetaLabel(systemImage: "calendar", text: shortAppointmentText)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(AppTheme.onSurface)
            }

            if style == .handoff {
                Text("Show details")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
    }

    private var shortAppointmentText: String {
        guard let appointmentDate = lead.appointmentDate else { return "" }
        return appointmentDate.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}

private struct CompactEmptyCard: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(AppTheme.onSurfaceVariant)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
