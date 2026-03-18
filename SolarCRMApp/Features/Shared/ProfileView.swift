import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                if let currentUser = appState.currentUser {
                    Section("Profile") {
                        LabeledContent("Name", value: currentUser.fullName)
                        LabeledContent("Email", value: currentUser.email)
                        LabeledContent("Role", value: currentUser.role.title)
                        LabeledContent("Phone", value: currentUser.phoneNumber)
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        Task { await appState.logout() }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
