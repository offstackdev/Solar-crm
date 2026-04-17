import SwiftUI

struct DoorKnockerTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: DoorKnockerTab = .dashboard

    var body: some View {
        ZStack(alignment: .bottom) {
            activeTabView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingDoorKnockerTabBar(
                selectedTab: $selectedTab,
                unreadCount: appState.unreadNotificationCount
            )
            .padding(.horizontal, 18)
            .padding(.bottom, 10)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    @ViewBuilder
    private var activeTabView: some View {
        switch selectedTab {
        case .dashboard:
            DoorKnockerDashboardView()
        case .alerts:
            NotificationsView()
        case .settings:
            ProfileView()
        }
    }
}

private enum DoorKnockerTab: CaseIterable, Identifiable {
    case dashboard
    case alerts
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .dashboard:
            return "Dashboard"
        case .alerts:
            return "Alerts"
        case .settings:
            return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            return "house.fill"
        case .alerts:
            return "bell.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

private struct FloatingDoorKnockerTabBar: View {
    @Binding var selectedTab: DoorKnockerTab
    let unreadCount: Int
    @Namespace private var glassNamespace

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 14) {
                tabBarContent
                    .glassEffect(.regular.tint(Color.white.opacity(0.12)).interactive(), in: .rect(cornerRadius: 32))
            }
        } else {
            tabBarContent
                .background(.regularMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.72), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 5)
        }
    }

    private var tabBarContent: some View {
        HStack(spacing: 0) {
            ForEach(DoorKnockerTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(6)
        .frame(height: 58)
    }

    private func tabButton(_ tab: DoorKnockerTab) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.28, extraBounce: 0.12)) {
                selectedTab = tab
            }
        } label: {
            ZStack {
                activeTabBackground(for: tab)

                VStack(spacing: 3) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 19, weight: .bold))
                            .frame(height: 21)

                        if tab == .alerts, unreadCount > 0 {
                            Text("\(min(unreadCount, 99))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 15, height: 15)
                                .background(Color.red, in: Circle())
                                .offset(x: 9, y: -6)
                        }
                    }

                    Text(tab.title)
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
            .foregroundStyle(selectedTab == tab ? AppTheme.onSurface : AppTheme.onSurfaceVariant)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func activeTabBackground(for tab: DoorKnockerTab) -> some View {
        if selectedTab == tab {
            if #available(iOS 26, *) {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .glassEffect(.regular.tint(Color.white.opacity(0.30)).interactive(), in: .rect(cornerRadius: 26))
                    .glassEffectID("active-door-knocker-tab", in: glassNamespace)
            } else {
                Capsule()
                    .fill(Color.white.opacity(0.54))
                    .matchedGeometryEffect(id: "active-door-knocker-tab", in: glassNamespace)
            }
        }
    }
}
