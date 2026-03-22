import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var selectedRole: UserRole = .doorKnocker
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.07, green: 0.10, blue: 0.18), Color(red: 0.10, green: 0.28, blue: 0.24)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(appState.isUsingBackend ? "Supabase Mode" : "Mock Mode")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(appState.isUsingBackend ? Color.green.opacity(0.2) : Color.orange.opacity(0.2), in: Capsule())
                                .foregroundStyle(.white)

                            Text("Solar CRM")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Field operations for solar teams, with role-based routing after sign-in.")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.78))
                        }

                        VStack(alignment: .leading, spacing: 18) {
                            Text("Sign In")
                                .font(.title2.bold())

                            VStack(spacing: 14) {
                                AuthTextField(
                                    title: "Email",
                                    text: $email,
                                    systemImage: "envelope"
                                )

                                AuthSecureField(
                                    title: "Password",
                                    text: $password,
                                    systemImage: "lock"
                                )
                            }

                            Button {
                                Task { await signInWithEmail() }
                            } label: {
                                HStack {
                                    if isLoading { ProgressView().tint(.white) }
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .foregroundStyle(.white)
                            }
                            .disabled(isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                            HStack {
                                Rectangle().fill(Color.secondary.opacity(0.2)).frame(height: 1)
                                Text("or continue with")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Rectangle().fill(Color.secondary.opacity(0.2)).frame(height: 1)
                            }

                            VStack(spacing: 12) {
                                AuthProviderButton(
                                    title: "Continue with Apple",
                                    systemImage: "apple.logo"
                                ) {
                                    Task { await signInWithProvider(.doorKnocker) }
                                }

                                AuthProviderButton(
                                    title: "Continue with Google",
                                    systemImage: "globe"
                                ) {
                                    Task { await signInWithProvider(.closer) }
                                }
                            }

                            Text("Your dashboard is assigned by your team role after authentication.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

#if DEBUG
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Developer Quick Access")
                                    .font(.headline)

                                Picker("Demo Role", selection: $selectedRole) {
                                    ForEach(UserRole.allCases) { role in
                                        Label(role.title, systemImage: role.symbolName).tag(role)
                                    }
                                }
                                .pickerStyle(.segmented)

                                Button("Continue as \(selectedRole.title)") {
                                    Task {
                                        await signInAsRole(selectedRole)
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
#endif
                        }
                        .padding(22)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))

                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func signInWithEmail() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await appState.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
        } catch {
            if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
                errorMessage = description
            } else {
                if appState.isUsingBackend {
                    errorMessage = "Supabase sign-in failed: \(String(describing: error))"
                } else {
                    errorMessage = "No mock user matches that email yet. Try `knocker1@suncrest.com`, `closer1@suncrest.com`, or `manager@suncrest.com`."
                }
            }
        }
    }

    private func signInWithProvider(_ fallbackRole: UserRole) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await appState.login(role: fallbackRole)
        } catch {
            errorMessage = "Mock social sign-in is unavailable right now."
        }
    }

    private func signInAsRole(_ role: UserRole) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await appState.login(role: role)
        } catch {
            errorMessage = "Unable to sign in to the selected role."
        }
    }
}

private struct AuthTextField: View {
    let title: String
    @Binding var text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
            TextField(title, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AuthSecureField: View {
    let title: String
    @Binding var text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
            SecureField(title, text: $text)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AuthProviderButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}
