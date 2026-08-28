//
//  AuthCardView.swift
//  OneLoop
//
//  Shared SmartNest-style login / register card used by onboarding + Settings.
//

import SwiftUI

enum AuthCardMode: String, CaseIterable {
    case login
    case register
}

struct AuthCardView: View {
    /// Called after a successful password login, register, or Google sign-in.
    var onAuthenticated: (() -> Void)?
    /// When true, shows a skip / later action under the card (onboarding only).
    var showsSignInLater: Bool = false
    var signInLaterTitle: String = "Sign in later"
    var onSignInLater: (() -> Void)?

    @Bindable private var cloud = SupabaseManager.shared

    @State private var mode: AuthCardMode = .login
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var rememberMe = true
    @State private var acceptedTerms = false
    @State private var acceptedHealthData = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("oneloop")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .tracking(3)
            }
            .foregroundStyle(AppTheme.navy)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 18) {
                Text(
                    mode == .login
                        ? "Stay in your loop"
                        : "Create an account"
                )
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.navy)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

                if mode == .register {
                    smartField(title: "Name") {
                        TextField("Your name", text: $fullName)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                    }
                }

                smartField(title: "Email") {
                    TextField("you@email.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                smartField(title: "Password") {
                    HStack(spacing: 8) {
                        Group {
                            if showPassword {
                                TextField("••••••••", text: $password)
                            } else {
                                SecureField("••••••••", text: $password)
                            }
                        }
                        .textContentType(mode == .login ? .password : .newPassword)

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(AppTheme.mutedText)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if mode == .login {
                    HStack {
                        Toggle(isOn: $rememberMe) {
                            Text("Remember me")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.navy)
                        }
                        .toggleStyle(AuthCheckboxToggleStyle())
                        .tint(AppTheme.blue)

                        Spacer(minLength: 8)

                        Button("Forget password?") {
                            Task {
                                guard !trimmedEmail.isEmpty else {
                                    cloud.lastErrorMessage =
                                        "Enter your email first, then tap Forget password."
                                    return
                                }
                                await cloud.sendPasswordReset(email: trimmedEmail)
                            }
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.blue)
                        .buttonStyle(.plain)
                    }
                } else {
                    Toggle(isOn: $acceptedTerms) {
                        (
                            Text("I agree to the ")
                                .foregroundStyle(AppTheme.navy)
                            + Text("Terms of Service")
                                .foregroundStyle(AppTheme.blue)
                                .underline()
                        )
                        .font(.subheadline)
                    }
                    .toggleStyle(AuthCheckboxToggleStyle())
                    .tint(AppTheme.blue)

                    Toggle(isOn: $acceptedHealthData) {
                        Text(
                            "I consent to OneLoop processing my medication names and schedules as health-related data for optional encrypted cloud backup (GDPR). I can use the app without an account."
                        )
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.navy)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .toggleStyle(AuthCheckboxToggleStyle())
                    .tint(AppTheme.blue)
                    .accessibilityLabel("Consent to processing health-related data")
                }

                Button {
                    Task { await submit() }
                } label: {
                    Group {
                        if cloud.isBusy {
                            ProgressView().tint(.white)
                        } else {
                            Text(mode == .login ? "Login" : "Create account")
                                .font(.body.weight(.semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .foregroundStyle(AppTheme.actionText)
                    .background(
                        AppTheme.blue,
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit || cloud.isBusy)
                .opacity(canSubmit && !cloud.isBusy ? 1 : 0.5)

                if let status = cloud.lastStatusMessage {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(AppTheme.teal)
                        .frame(maxWidth: .infinity)
                }

                if let error = cloud.lastErrorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(AppTheme.warning)
                        .frame(maxWidth: .infinity)
                }

                Button {
                    withAnimation(.snappy) {
                        mode = mode == .login ? .register : .login
                        cloud.lastErrorMessage = nil
                        cloud.lastStatusMessage = nil
                    }
                } label: {
                    Text(
                        mode == .login
                            ? "New here? Create an account"
                            : "Already have an account? Login"
                    )
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.blue)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                VStack(spacing: 14) {
                    Text("Or Sign in with")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedText)

                    HStack(spacing: 18) {
                        socialCircle(
                            systemImage: "g.circle.fill",
                            label: "Google",
                            enabled: mode == .login || (acceptedTerms && acceptedHealthData)
                        ) {
                            Task { await signInWithGoogle() }
                        }

                        socialCircle(
                            systemImage: "apple.logo",
                            label: "Apple",
                            enabled: false
                        ) {}
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
            }
            .padding(22)
            .background(
                AppTheme.cardBackground,
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.05), radius: 24, y: 10)

            if showsSignInLater {
                VStack(spacing: 8) {
                    Button {
                        onSignInLater?()
                    } label: {
                        Text(signInLaterTitle)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.navy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(signInLaterTitle)

                    Text("You can create an account anytime in Settings.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onChange(of: cloud.isSignedIn) { _, signedIn in
            if signedIn {
                onAuthenticated?()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: SupabaseManager.didAuthenticateNotification
            )
        ) { _ in
            onAuthenticated?()
        }
    }

    // MARK: - Actions

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        guard !trimmedEmail.isEmpty, password.count >= 6 else { return false }
        if mode == .register { return acceptedTerms && acceptedHealthData }
        return true
    }

    private func submit() async {
        switch mode {
        case .login:
            await cloud.signInWithEmailPassword(
                email: trimmedEmail,
                password: password
            )
            if cloud.isSignedIn {
                onAuthenticated?()
            }

        case .register:
            guard acceptedTerms else {
                cloud.lastErrorMessage = "Please agree to the Terms of Service."
                return
            }
            guard acceptedHealthData else {
                cloud.lastErrorMessage =
                    "Please consent to processing health-related data to create an account."
                return
            }
            HealthDataConsent.isGranted = true
            await cloud.signUpWithEmailPassword(
                email: trimmedEmail,
                password: password,
                fullName: fullName
            )
            // Open Today after register (even if email confirmation is pending).
            if cloud.lastErrorMessage == nil {
                onAuthenticated?()
            }
        }
    }

    private func signInWithGoogle() async {
        if mode == .register {
            guard acceptedTerms, acceptedHealthData else {
                cloud.lastErrorMessage =
                    "To create an account with Google, agree to the Terms of Service and consent to health-data processing."
                return
            }
            HealthDataConsent.isGranted = true
        }
        await cloud.signInWithGoogle()
        if cloud.isSignedIn {
            onAuthenticated?()
        }
    }

    // MARK: - Field chrome

    private func smartField<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.navy)

            content()
                .foregroundStyle(AppTheme.navy)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    AppTheme.fieldFill,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
        }
    }

    private func socialCircle(
        systemImage: String,
        label: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(
                    enabled ? AppTheme.navy : AppTheme.mutedText.opacity(0.35)
                )
                .frame(width: 52, height: 52)
                .background(AppTheme.softBackground, in: Circle())
                .overlay {
                    Circle().stroke(AppTheme.cardBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(!enabled || cloud.isBusy)
        .accessibilityLabel(label)
    }
}

struct AuthCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .center, spacing: 10) {
                Image(
                    systemName: configuration.isOn
                        ? "checkmark.square.fill"
                        : "square"
                )
                .font(.body)
                .foregroundStyle(
                    configuration.isOn ? AppTheme.blue : AppTheme.mutedText
                )

                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScrollView {
        AuthCardView(showsSignInLater: true, onSignInLater: {})
            .padding()
    }
    .background(AppTheme.softBackground)
}
