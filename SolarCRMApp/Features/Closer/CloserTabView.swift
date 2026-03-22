import SwiftUI

struct CloserTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            CloserDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }

            CloserScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }

            NotificationsView()
                .tabItem {
                    Label("Alerts", systemImage: "bell")
                }
                .badge(appState.unreadNotificationCount)

            ProfileView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
