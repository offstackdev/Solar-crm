import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedRole: UserRole = .doorKnocker
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Solar CRM")
                        .font(.largeTitle.bold())
                    Text("Role-aware field operations for canvassers, closers, and managers.")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Login")
                        .font(.headline)

                    Picker("Role", selection: $selectedRole) {
                        ForEach(UserRole.allCases) { role in
                            Label(role.title, systemImage: role.symbolName).tag(role)
                        }
                    }
                    .pickerStyle(.inline)
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    Task {
                        isLoading = true
                        defer { isLoading = false }
                        do {
                            try await appState.login(role: selectedRole)
                        } catch {
                            errorMessage = "Unable to sign in to the selected role."
                        }
                    }
                } label: {
                    HStack {
                        if isLoading { ProgressView() }
                        Text("Continue as \(selectedRole.title)")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding(20)
            .navigationBarHidden(true)
        }
    }
}
