import SwiftUI

struct ManagerTabView: View {
    var body: some View {
        TabView {
            ManagerDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }

            ManagerPipelineBoardView()
                .tabItem {
                    Label("Pipeline", systemImage: "square.split.3x1")
                }

            AssignmentManagerView()
                .tabItem {
                    Label("Assignments", systemImage: "person.2.badge.gearshape")
                }

            ProfileView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
