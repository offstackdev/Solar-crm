import SwiftUI

struct DoorKnockerDashboardView: View {
    @EnvironmentObject private var appState: AppState

    private var firstName: String {
        appState.currentUser?.fullName.split(separator: " ").first.map(String.init) ?? ""
    }

    private var myLeads: [Lead] {
        appState.leadsForCurrentUser()
    }

    private var activeLeads: [Lead] {
        myLeads.filter { $0.currentStatus.isVisibleOnDoorKnockerActiveBoard }
    }

    private var handoffLeads: [Lead] {
        myLeads.filter { !$0.currentStatus.isVisibleOnDoorKnockerActiveBoard }
    }

    private var greetingWord: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "☀️"
        case 12..<17: return "🌤️"
        default: return "🌙"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    topBar
                    greetingHeader
                    summaryText
                    metricsRow
                    myLeadsCard
                    recentClosersSection
                    addLeadButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    private var topBar: some View {
        HStack {
            Image(systemName: "person.circle")
                .font(.system(size: 26))
                .foregroundStyle(.primary)
            Spacer()
            Text("$200")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.black, in: Capsule())
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.leading, 10)
        }
        .padding(.top, 8)
    }

    private var greetingHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(greetingWord)
                .font(.system(size: 40, weight: .bold))
            Text(greetingEmoji)
                .font(.system(size: 32))
        }
    }

    private var summaryText: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Good morning, \(firstName).")
                .font(.title3.bold())
            Text("You have \(activeLeads.count) active \(activeLeads.count == 1 ? "lead" : "leads") and \(handoffLeads.count) recent \(handoffLeads.count == 1 ? "handoff" : "handoffs").")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var metricsRow: some View {
        HStack(spacing: 14) {
            DashMetricCard(title: "Active Leads", value: activeLeads.count, systemImage: "person.2.fill")
            DashMetricCard(title: "Handed Off", value: handoffLeads.count, systemImage: "arrowshape.turn.up.right.fill")
        }
        .padding(.top, 4)
    }

    private var myLeadsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Leads")
                .font(.title3.bold())

            if activeLeads.isEmpty {
                Text("New leads and pending confirmations will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 14) {
                    ForEach(activeLeads) { lead in
                        NavigationLink {
                            DoorKnockerLeadDetailView(leadID: lead.id)
                        } label: {
                            CompactLeadRow(
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var recentClosersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Closer Updates")
                .font(.title3.bold())

            if handoffLeads.isEmpty {
                Text("Once appointments are confirmed, closer updates will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                ForEach(handoffLeads.prefix(5)) { lead in
                    NavigationLink {
                        DoorKnockerLeadDetailView(leadID: lead.id)
                    } label: {
                        CloserUpdateCard(
                            lead: lead,
                            doorKnockerName: appState.userName(for: lead.createdByDoorKnockerID)
                        )
                    }
                    .buttonStyle(.plain)
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
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                    Text("Add New Lead")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 44)
                .padding(.vertical, 18)
                .background(Color.blue, in: Capsule())
            }
            Spacer()
        }
        .padding(.top, 12)
    }
}

private struct DashMetricCard: View {
    let title: String
    let value: Int
    let systemImage: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text("\(value)")
                    .font(.title2.bold())
            }
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        .overlay(alignment: .topTrailing) {
            Text("\(value)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Color.blue, in: Circle())
                .offset(x: 8, y: -8)
        }
    }
}

private struct CompactLeadRow: View {
    let lead: Lead
    let doorKnockerName: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(lead.homeownerFullName)
                    .font(.headline)
                Text("\(lead.propertyAddress), \(lead.city)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Label(doorKnockerName, systemImage: "person")
                        .lineLimit(1)
                    if lead.appointmentDate != nil {
                        Label(lead.appointmentDateText, systemImage: "calendar")
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 18) {
                LeadStatusPill(status: lead.currentStatus)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

private struct CloserUpdateCard: View {
    let lead: Lead
    let doorKnockerName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(lead.homeownerFullName)
                        .font(.headline)
                    Text("\(lead.propertyAddress), \(lead.city)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        Label(doorKnockerName, systemImage: "person")
                            .lineLimit(1)
                        if lead.appointmentDate != nil {
                            Label(lead.appointmentDateText, systemImage: "calendar")
                                .lineLimit(1)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 18) {
                    LeadStatusPill(status: lead.currentStatus, includesClock: true)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            Text("Show details")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct LeadStatusPill: View {
    let status: LeadStatus
    var includesClock: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2.weight(.bold))
            Text(status.rawValue)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(background, in: Capsule())
        .foregroundStyle(foreground)
    }

    private var iconName: String {
        if includesClock { return "clock.fill" }
        switch status.badgeTone {
        case .warning, .danger: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .accent: return "clock.fill"
        case .neutral: return "circle.fill"
        }
    }

    private var background: Color {
        switch status.badgeTone {
        case .neutral: return Color.gray.opacity(0.15)
        case .accent: return Color.blue.opacity(0.15)
        case .success: return Color.green.opacity(0.16)
        case .warning: return Color.orange.opacity(0.18)
        case .danger: return Color.red.opacity(0.15)
        }
    }

    private var foreground: Color {
        switch status.badgeTone {
        case .neutral: return .secondary
        case .accent: return .blue
        case .success: return .green
        case .warning: return .orange
        case .danger: return .red
        }
    }
}
