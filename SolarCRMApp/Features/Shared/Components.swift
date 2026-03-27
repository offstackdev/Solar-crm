import SwiftUI

enum AppTheme {
    static let background = Color(uiColor: .systemGroupedBackground)
    static let onSurface = Color.primary
    static let onSurfaceVariant = Color.secondary
    static let primary = Color.accentColor
    static let primaryContainer = Color(uiColor: .systemBlue).opacity(0.12)
    static let secondary = Color(uiColor: .secondaryLabel)
    static let secondaryContainer = Color(uiColor: .tertiarySystemGroupedBackground)
    static let surfaceLow = Color(uiColor: .secondarySystemGroupedBackground)
    static let surfaceMid = Color(uiColor: .secondarySystemGroupedBackground)
    static let surfaceHigh = Color(uiColor: .tertiarySystemGroupedBackground)
    static let tertiaryContainer = Color(uiColor: .quaternarySystemFill)
    static let outline = Color(uiColor: .separator).opacity(0.3)
    static let shadow = Color.black.opacity(0.04)
}

struct AppScreen<Content: View>: View {
    let title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let title {
                        Text(title)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(AppTheme.onSurface)
                    }

                    content
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 110)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct AppSectionHeader: View {
    let title: String
    let trailingText: String?

    init(_ title: String, trailingText: String? = nil) {
        self.title = title
        self.trailingText = trailingText
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.onSurface)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primary)
            }
        }
    }
}

struct AppSurface<Content: View>: View {
    let fill: Color
    let content: Content

    init(fill: Color = AppTheme.surfaceLow, @ViewBuilder content: () -> Content) {
        self.fill = fill
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct AppOutlinedSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        AppSurface {
            content
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.outline, lineWidth: 1)
        )
        .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 4)
    }
}

struct AppPrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

struct AppSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

struct AppInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.onSurfaceVariant)
                .textCase(.uppercase)

            Spacer()

            Text(value.isEmpty ? "Not provided" : value)
                .font(.body)
                .foregroundStyle(AppTheme.onSurface)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct StatusBadge: View {
    let status: LeadStatus

    var body: some View {
        Label(status.rawValue, systemImage: symbolName)
            .font(.caption.weight(.medium))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundColor, in: Capsule())
            .foregroundStyle(foregroundColor)
    }

    private var symbolName: String {
        switch status.badgeTone {
        case .neutral: return "circle.fill"
        case .accent: return "clock.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .danger: return "xmark.circle.fill"
        }
    }

    private var backgroundColor: Color {
        switch status.badgeTone {
        case .neutral: return Color(uiColor: .tertiarySystemFill)
        case .accent: return AppTheme.primary.opacity(0.12)
        case .success: return Color.green.opacity(0.14)
        case .warning: return Color.orange.opacity(0.16)
        case .danger: return Color.red.opacity(0.14)
        }
    }

    private var foregroundColor: Color {
        switch status.badgeTone {
        case .neutral: return AppTheme.onSurfaceVariant
        case .accent: return AppTheme.primary
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
    var fill: Color = AppTheme.surfaceLow
    var accent: Color = AppTheme.primary
    var minHeight: CGFloat = 92

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(accent)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.onSurfaceVariant)

                Text(value)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.onSurface)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: minHeight, alignment: .leading)
        .padding(16)
        .background(fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct LeadCardView: View {
    let lead: Lead
    let doorKnockerName: String
    let closerName: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(lead.homeownerFullName)
                    .font(.headline)
                    .foregroundStyle(AppTheme.onSurface)

                Text("\(lead.propertyAddress), \(lead.city)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.onSurfaceVariant)

                HStack(spacing: 10) {
                    MetaLabel(systemImage: "person", text: doorKnockerName)

                    if lead.appointmentDate != nil {
                        MetaLabel(systemImage: "calendar", text: lead.appointmentDateText)
                    } else if !closerName.isEmpty {
                        MetaLabel(systemImage: "person.crop.circle.badge.checkmark", text: closerName)
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 10) {
                StatusBadge(status: lead.currentStatus)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(AppTheme.surfaceLow, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct CloserLeadCardView: View {
    let lead: Lead
    let doorKnockerName: String

    private var latestUpdateText: String {
        lead.statusHistory.first?.note ?? "No recent updates"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lead.homeownerFullName)
                        .font(.headline)
                        .foregroundStyle(AppTheme.onSurface)
                    Text("\(lead.propertyAddress), \(lead.city)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.onSurfaceVariant)
                }
                Spacer()
                StatusBadge(status: lead.currentStatus)
            }

            VStack(alignment: .leading, spacing: 6) {
                MetaLabel(systemImage: "person", text: doorKnockerName)
                if let appointmentDate = lead.appointmentDate {
                    MetaLabel(systemImage: "calendar", text: appointmentDate.formatted(date: .abbreviated, time: .shortened))
                }
            }

            Text(latestUpdateText)
                .font(.footnote)
                .foregroundStyle(AppTheme.onSurfaceVariant)
                .lineLimit(2)
        }
        .padding(16)
        .background(AppTheme.surfaceLow, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.secondary)
                .frame(width: 56, height: 56)
                .background(AppTheme.tertiaryContainer, in: Circle())

            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.onSurface)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(24)
        .background(AppTheme.surfaceLow, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct MetaLabel: View {
    let systemImage: String
    let text: String
    var emphasize = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(text)
                .lineLimit(1)
        }
        .font(emphasize ? .caption.weight(.bold) : .caption)
        .foregroundStyle(emphasize ? AppTheme.onSurface : AppTheme.onSurfaceVariant.opacity(0.78))
    }
}
