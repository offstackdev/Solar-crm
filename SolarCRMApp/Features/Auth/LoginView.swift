import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @FocusState private var focusedField: Field?

    @State private var email = ""
    @State private var password = ""
    @State private var selectedRole: UserRole = .doorKnocker
    @State private var isLoading = false
    @State private var errorMessage: String?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        header
                        formSection
                        supportSection
                        footerSection

#if DEBUG
                        debugSection
#endif
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                SolarMark()
                    .fill(AppTheme.primary)
                    .frame(width: 54, height: 54)

                Spacer()

                modeBadge
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Sign In")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppTheme.onSurface)

                Text("Access live leads, handoffs, and appointments from the field.")
                    .font(.body)
                    .foregroundStyle(AppTheme.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var formSection: some View {
        AppSurface {
            VStack(alignment: .leading, spacing: 16) {
                Text("Account")
                    .font(.headline)
                    .foregroundStyle(AppTheme.onSurface)

                AuthTextField(
                    title: "Email",
                    text: $email,
                    systemImage: "envelope",
                    keyboardType: .emailAddress,
                    textContentType: .username,
                    submitLabel: .next,
                    isFocused: focusedField == .email
                )
                .focused($focusedField, equals: .email)
                .onSubmit {
                    focusedField = .password
                }

                AuthSecureField(
                    title: "Password",
                    text: $password,
                    systemImage: "lock",
                    textContentType: .password,
                    submitLabel: .go,
                    isFocused: focusedField == .password
                )
                .focused($focusedField, equals: .password)
                .onSubmit {
                    Task { await signInWithEmail() }
                }

                Button {
                    focusedField = nil
                    Task { await signInWithEmail() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canSubmit || isLoading)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var supportSection: some View {
        AppOutlinedSurface {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sign-in Notes")
                    .font(.headline)
                    .foregroundStyle(AppTheme.onSurface)

                Text("Email and password are the only live sign-in credentials right now. Apple and Google sign-in are intentionally not wired to the backend yet.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.onSurfaceVariant)

                Button("Need help signing in?") {
                    focusedField = nil
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
    }

    private var footerSection: some View {
        Text("By signing in, you agree to Solar CRM's access and privacy policies for field operations.")
            .font(.footnote)
            .foregroundStyle(AppTheme.onSurfaceVariant)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
    }

#if DEBUG
    private var debugSection: some View {
        AppOutlinedSurface {
            VStack(alignment: .leading, spacing: 16) {
                Text("Developer Quick Access")
                    .font(.headline)
                    .foregroundStyle(AppTheme.onSurface)

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
                .controlSize(.large)
            }
        }
    }
#endif

    private var modeBadge: some View {
        Text(appState.isUsingBackend ? "Live Supabase" : "Mock Mode")
            .font(.caption.weight(.medium))
            .foregroundStyle(appState.isUsingBackend ? .green : .orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(appState.isUsingBackend ? Color.green.opacity(0.12) : Color.orange.opacity(0.12), in: Capsule())
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    private func signInWithEmail() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await appState.login(
                email: trimmedEmail,
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
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    let submitLabel: SubmitLabel
    let isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(AppTheme.onSurfaceVariant)
                .frame(width: 20)

            TextField(title, text: $text)
                .font(.body)
                .foregroundStyle(AppTheme.onSurface)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .submitLabel(submitLabel)
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isFocused ? Color.accentColor : AppTheme.outline, lineWidth: 1)
        }
        .animation(.easeOut(duration: 0.18), value: isFocused)
    }
}

private struct AuthSecureField: View {
    let title: String
    @Binding var text: String
    let systemImage: String
    let textContentType: UITextContentType?
    let submitLabel: SubmitLabel
    let isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(AppTheme.onSurfaceVariant)
                .frame(width: 20)

            SecureField(title, text: $text)
                .font(.body)
                .foregroundStyle(AppTheme.onSurface)
                .textContentType(textContentType)
                .submitLabel(submitLabel)
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isFocused ? Color.accentColor : AppTheme.outline, lineWidth: 1)
        }
        .animation(.easeOut(duration: 0.18), value: isFocused)
    }
}

private struct SolarMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.71, y: height * 0.16))
        path.addCurve(
            to: CGPoint(x: width * 0.24, y: height * 0.34),
            control1: CGPoint(x: width * 0.66, y: height * 0.02),
            control2: CGPoint(x: width * 0.30, y: height * 0.02)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.23, y: height * 0.83),
            control1: CGPoint(x: width * 0.08, y: height * 0.46),
            control2: CGPoint(x: width * 0.08, y: height * 0.78)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.55, y: height * 0.76),
            control1: CGPoint(x: width * 0.31, y: height * 0.92),
            control2: CGPoint(x: width * 0.50, y: height * 0.93)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.79, y: height * 0.38),
            control1: CGPoint(x: width * 0.60, y: height * 0.60),
            control2: CGPoint(x: width * 0.84, y: height * 0.58)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.71, y: height * 0.16),
            control1: CGPoint(x: width * 0.83, y: height * 0.26),
            control2: CGPoint(x: width * 0.79, y: height * 0.16)
        )
        path.closeSubpath()

        return path
    }
}
