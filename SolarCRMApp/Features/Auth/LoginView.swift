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
                Color.white
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                        formSection
                        footerSection

#if DEBUG
                        debugSection
#endif
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(spacing: 26) {
            HStack {
                Spacer()
                modeBadge
            }

            VStack(spacing: 24) {
                SolarMark()
                    .fill(Color.black)
                    .frame(width: 64, height: 64)

                VStack(spacing: 10) {
                    Text("Log in to Solar CRM")
                        .font(.system(size: 39, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)

                    Text("Access live leads, handoffs, and appointments from the field.")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.52))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 36)
            .padding(.bottom, 34)
        }
    }

    private var formSection: some View {
        VStack(spacing: 16) {
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
                ZStack {
                    Text("Continue")
                        .opacity(isLoading ? 0 : 1)

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(canSubmit ? Color.black.opacity(0.72) : Color.black.opacity(0.28))
                )
            }
            .disabled(!canSubmit || isLoading)
            .padding(.top, 6)

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.red.opacity(0.88))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }

            VStack(spacing: 10) {
                Button("Need help signing in?") {
                    focusedField = nil
                }
                .buttonStyle(.plain)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.06, green: 0.48, blue: 0.95))
                .padding(.top, 14)

                Text("Email and password are the only live sign-in credentials right now. Apple and Google sign-in are intentionally not wired to the backend yet.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.42))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 10)
            }
            .padding(.top, 8)
        }
    }

    private var footerSection: some View {
        VStack(spacing: 10) {
            Text("By logging in, you agree to Solar CRM's access and privacy policies for field operations.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.34))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 14)
        }
        .padding(.top, 34)
    }

#if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .padding(.bottom, 4)

            Text("Developer Quick Access")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.7))

            Picker("Demo Role", selection: $selectedRole) {
                ForEach(UserRole.allCases) { role in
                    Text(role.title).tag(role)
                }
            }
            .pickerStyle(.segmented)

            Button("Continue as \(selectedRole.title)") {
                Task {
                    await signInAsRole(selectedRole)
                }
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.03))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.14), lineWidth: 1)
            }
            .foregroundStyle(.black)
        }
        .padding(.top, 34)
    }
#endif

    private var modeBadge: some View {
        Text(appState.isUsingBackend ? "Live Supabase" : "Mock Mode")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(appState.isUsingBackend ? Color(red: 0.11, green: 0.43, blue: 0.24) : Color(red: 0.68, green: 0.38, blue: 0.06))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(appState.isUsingBackend ? Color(red: 0.90, green: 0.97, blue: 0.92) : Color(red: 1.0, green: 0.95, blue: 0.87))
            )
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
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.32))
                .frame(width: 20)

            TextField(title, text: $text)
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .foregroundStyle(.black)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .submitLabel(submitLabel)
        }
        .padding(.horizontal, 18)
        .frame(height: 62)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.06))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isFocused ? Color.black.opacity(0.28) : Color.clear, lineWidth: 1.5)
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
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.32))
                .frame(width: 20)

            SecureField(title, text: $text)
                .font(.system(size: 19, weight: .medium, design: .rounded))
                .foregroundStyle(.black)
                .textContentType(textContentType)
                .submitLabel(submitLabel)
        }
        .padding(.horizontal, 18)
        .frame(height: 62)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.06))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isFocused ? Color.black.opacity(0.28) : Color.clear, lineWidth: 1.5)
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
