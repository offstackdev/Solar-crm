import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            AppScreen(title: "Settings") {
                if let currentUser = appState.currentUser {
                    VStack(alignment: .leading, spacing: 12) {
                        AppSectionHeader("Profile")
                        AppOutlinedSurface {
                            VStack(alignment: .leading, spacing: 16) {
                                AppInfoRow(label: "Name", value: currentUser.fullName)
                                AppInfoRow(label: "Email", value: currentUser.email)
                                AppInfoRow(label: "Role", value: currentUser.role.title)
                                AppInfoRow(label: "Phone", value: currentUser.phoneNumber)
                            }
                        }
                    }
                }

                Button("Sign Out", role: .destructive) {
                    Task { await appState.logout() }
                }
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.red.opacity(0.12), in: Capsule())
                .foregroundStyle(.red)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
