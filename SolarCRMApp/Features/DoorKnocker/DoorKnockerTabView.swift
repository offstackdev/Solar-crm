import SwiftUI

struct DoorKnockerTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            DoorKnockerDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
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
