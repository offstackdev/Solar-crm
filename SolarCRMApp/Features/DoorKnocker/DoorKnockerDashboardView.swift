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
        myLeads.filter { !$0.currentStatus.isVisibleOnDoorKnockerActiveBoard }
    }

    private var greetingName: String {
        appState.currentUser?.fullName.split(separator: " ").first.map(String.init) ?? "Scout"
    }

    private let backgroundColor = Color.white
    private let onSurfaceColor = Color(red: 0.22, green: 0.18, blue: 0.0)
    private let onSurfaceVariantColor = Color(red: 0.427, green: 0.353, blue: 0.0)
    private let primaryColor = Color(red: 0.0, green: 0.322, blue: 0.816)
    private let primaryContainerColor = Color(red: 0.475, green: 0.616, blue: 1.0)
    private let secondaryColor = Color(red: 0.639, green: 0.22, blue: 0.0)
    private let secondaryContainerColor = Color(red: 1.0, green: 0.769, blue: 0.686)
    private let surfaceContainerLowColor = Color(red: 1.0, green: 0.941, blue: 0.769)
    private let surfaceContainerColor = Color(red: 1.0, green: 0.906, blue: 0.58)
    private let surfaceContainerHighestColor = Color(red: 1.0, green: 0.859, blue: 0.263)

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection

                        statsSection

                        NavigationLink {
                            NewLeadFlowView()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.headline)
                                Text("Create New Lead")
                                    .font(.headline.weight(.bold))
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 18)
                            .background(primaryColor, in: Capsule())
                            .foregroundStyle(.white)
                            .shadow(color: onSurfaceColor.opacity(0.06), radius: 20, x: 0, y: 10)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(title: "My Leads", trailingText: activeLeads.isEmpty ? nil : "View All")
                            if activeLeads.isEmpty {
                                styledEmptyState(
                                    title: "No active leads",
                                    message: "New leads and pending confirmations will appear here.",
                                    systemImage: "tray"
                                )
                            } else {
                                ForEach(activeLeads) { lead in
                                    NavigationLink {
                                        DoorKnockerLeadDetailView(leadID: lead.id)
                                    } label: {
                                        styledLeadCard(
                                            lead: lead,
                                            doorKnockerName: appState.userName(for: lead.createdByDoorKnockerID),
                                            closerName: appState.userName(for: lead.assignedCloserID)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(title: "Recent Closer Updates", trailingText: handoffLeads.isEmpty ? nil : "View All Updates")
                            if handoffLeads.isEmpty {
                                styledEmptyState(
                                    title: "No handoff history yet",
                                    message: "Once appointments are confirmed, closer updates will appear here.",
                                    systemImage: "clock.arrow.circlepath"
                                )
                            } else {
                                ForEach(handoffLeads.prefix(5)) { lead in
                                    NavigationLink {
                                        DoorKnockerLeadDetailView(leadID: lead.id)
                                    } label: {
                                        styledUpdateCard(
                                            lead: lead,
                                            doorKnockerName: appState.userName(for: lead.createdByDoorKnockerID),
                                            closerName: appState.userName(for: lead.assignedCloserID)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .padding(.top, 0)
                    .padding(.bottom, 110)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Good morning,")
                .font(.title3.weight(.bold))
                .foregroundStyle(onSurfaceColor)

            Text(greetingName)
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(primaryColor)
                .italic()

            Text("Your territory is bustling today. You have \(activeLeads.count) fresh opportunities waiting.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(onSurfaceVariantColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var statsSection: some View {
        HStack(spacing: 14) {
            statCard(
                title: "Active Leads",
                subtitle: "In your pipeline",
                value: "\(activeLeads.count)",
                systemImage: "person.3.sequence.fill",
                cardColor: surfaceContainerHighestColor,
                accentColor: primaryColor,
                iconColor: onSurfaceColor,
                textColor: onSurfaceColor,
                subtitleColor: onSurfaceVariantColor
            )

            statCard(
                title: "Handed Off",
                subtitle: "Sent to closers",
                value: "\(handoffLeads.count)",
                systemImage: "arrowshape.turn.up.right.fill",
                cardColor: secondaryContainerColor,
                accentColor: secondaryColor,
                iconColor: secondaryColor,
                textColor: Color(red: 0.506, green: 0.169, blue: 0.0),
                subtitleColor: Color(red: 0.506, green: 0.169, blue: 0.0).opacity(0.7)
            )
        }
    }

    private func sectionHeader(title: String, trailingText: String?) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(onSurfaceColor)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(primaryColor)
            }
        }
    }

    private func statCard(
        title: String,
        subtitle: String,
        value: String,
        systemImage: String,
        cardColor: Color,
        accentColor: Color,
        iconColor: Color,
        textColor: Color,
        subtitleColor: Color
    ) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(cardColor)

            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(iconColor)

                Spacer(minLength: 18)

                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(textColor)

                Text(subtitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(subtitleColor)

                Spacer()

                Text(value)
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(accentColor)
                    .italic()
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 192)
    }

    private func styledLeadCard(lead: Lead, doorKnockerName: String, closerName: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Circle()
                .fill(leadAccentColor(for: lead))
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(leadAccentForegroundColor(for: lead))
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(lead.homeownerFullName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(onSurfaceColor)

                Text("\(lead.propertyAddress), \(lead.city)")
                    .font(.subheadline)
                    .foregroundStyle(onSurfaceVariantColor)

                HStack(spacing: 12) {
                    metadataLabel(systemImage: "person", text: doorKnockerName)

                    if lead.appointmentDate != nil {
                        metadataLabel(systemImage: "calendar", text: lead.appointmentDateText)
                    } else if !closerName.isEmpty {
                        metadataLabel(systemImage: "person.crop.circle.badge.checkmark", text: closerName)
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 12) {
                statusChip(for: lead.currentStatus)

                ZStack {
                    Circle()
                        .fill(primaryColor)
                        .frame(width: 38, height: 38)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(20)
        .background(surfaceContainerLowColor, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func styledUpdateCard(lead: Lead, doorKnockerName: String, closerName: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lead.homeownerFullName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(onSurfaceColor)

                    Text("\(lead.propertyAddress), \(lead.city)")
                        .font(.subheadline)
                        .foregroundStyle(onSurfaceVariantColor)
                }

                Spacer()

                statusChip(for: lead.currentStatus)
            }

            VStack(alignment: .leading, spacing: 6) {
                metadataLabel(systemImage: "person", text: doorKnockerName)

                if lead.appointmentDate != nil {
                    metadataLabel(systemImage: "calendar", text: lead.appointmentDateText)
                }

                if !closerName.isEmpty {
                    metadataLabel(systemImage: "hand.raised.fill", text: closerName, emphasize: true)
                }
            }
        }
        .padding(20)
        .background(surfaceContainerLowColor, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(onSurfaceColor.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: onSurfaceColor.opacity(0.06), radius: 18, x: 0, y: 10)
    }

    private func metadataLabel(systemImage: String, text: String, emphasize: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(text)
                .lineLimit(1)
        }
        .font(emphasize ? .caption.weight(.bold) : .caption)
        .foregroundStyle(emphasize ? onSurfaceColor : onSurfaceVariantColor.opacity(0.78))
    }

    private func statusChip(for status: LeadStatus) -> some View {
        Text(status.rawValue.uppercased())
            .font(.caption2.weight(.black))
            .foregroundStyle(onSurfaceVariantColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.5), in: Capsule())
    }

    private func styledEmptyState(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 12) {
            Circle()
                .fill(primaryContainerColor)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: systemImage)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color(red: 0.0, green: 0.118, blue: 0.345))
                }

            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(onSurfaceColor)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(onSurfaceVariantColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(24)
        .background(surfaceContainerLowColor, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func leadAccentColor(for lead: Lead) -> Color {
        lead.appointmentDate != nil ? primaryContainerColor : Color(red: 1.0, green: 0.549, blue: 0.729)
    }

    private func leadAccentForegroundColor(for lead: Lead) -> Color {
        lead.appointmentDate != nil ? Color(red: 0.0, green: 0.118, blue: 0.345) : Color(red: 0.392, green: 0.0, blue: 0.22)
    }
}
