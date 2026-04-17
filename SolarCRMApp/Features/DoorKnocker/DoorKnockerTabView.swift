import SwiftUI

struct DoorKnockerTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selection: Tab = .dashboard

    enum Tab {
        case dashboard, alerts, settings
    }

    private var unreadCount: Int {
        appState.notifications.filter { !$0.isRead }.count
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .dashboard: DoorKnockerDashboardView()
                case .alerts: NotificationsView()
                case .settings: ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selection: $selection, unreadCount: unreadCount)
                .padding(.horizontal, 40)
                .padding(.bottom, 8)
        }
    }
}

private struct FloatingTabBar: View {
    @Binding var selection: DoorKnockerTabView.Tab
    let unreadCount: Int

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.dashboard, title: "Dashboard", systemImage: "house.fill")
            tabButton(.alerts, title: "Alerts", systemImage: "bell.fill", badgeCount: unreadCount)
            tabButton(.settings, title: "Settings", systemImage: "gearshape.fill")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }

    private func tabButton(_ tab: DoorKnockerTabView.Tab, title: String, systemImage: String, badgeCount: Int = 0) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .semibold))
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .padding(.horizontal, 3)
                            .background(Color.red, in: Capsule())
                            .offset(x: 10, y: -6)
                    }
                }
                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(selection == tab ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
