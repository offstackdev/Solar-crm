import SwiftUI

struct DoorKnockerTabView: View {
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

            ProfileView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
