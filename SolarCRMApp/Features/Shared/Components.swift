import SwiftUI

struct StatusBadge: View {
    let status: LeadStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundColor, in: Capsule())
            .foregroundStyle(foregroundColor)
    }

    private var backgroundColor: Color {
        switch status.badgeTone {
        case .neutral: return Color.gray.opacity(0.15)
        case .accent: return Color.blue.opacity(0.15)
        case .success: return Color.green.opacity(0.16)
        case .warning: return Color.orange.opacity(0.18)
        case .danger: return Color.red.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch status.badgeTone {
        case .neutral: return .secondary
        case .accent: return .blue
        case .success: return .green
        case .warning: return .orange
        case .danger: return .red
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.blue)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct LeadCardView: View {
    let lead: Lead
    let doorKnockerName: String
    let closerName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lead.homeownerFullName)
                        .font(.headline)
                    Text("\(lead.propertyAddress), \(lead.city)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: lead.currentStatus)
            }

            HStack {
                Label(doorKnockerName, systemImage: "person")
                Spacer()
                Label(closerName, systemImage: "person.crop.circle.badge.checkmark")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if lead.appointmentDate != nil {
                Label(lead.appointmentDateText, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct CloserLeadCardView: View {
    let lead: Lead
    let doorKnockerName: String

    private var latestUpdateText: String {
        lead.statusHistory.first?.note ?? "No recent updates"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lead.homeownerFullName)
                        .font(.headline)
                    Text("\(lead.propertyAddress), \(lead.city)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: lead.currentStatus)
            }

            HStack {
                Label(doorKnockerName, systemImage: "person")
                Spacer()
                if let appointmentDate = lead.appointmentDate {
                    Label(appointmentDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(latestUpdateText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 34))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding()
    }
}
