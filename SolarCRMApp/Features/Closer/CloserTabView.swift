import SwiftUI

struct CloserTabView: View {
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

            ProfileView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
