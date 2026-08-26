//
//  AccountAuthView.swift
//  OneLoop
//
//  Login / register / cloud sync — Settings subpage (same UI as onboarding).
//

import SwiftUI

struct AccountAuthView: View {
    let store: MedicationStore

    @Bindable private var cloud = SupabaseManager.shared

    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                if !SupabaseConfig.isConfigured {
                    configurationMissingCard
                } else if cloud.isSignedIn {
                    signedInCard
                    cloudSyncCard
                    accountActionsSection
                } else {
                    AuthCardView()
                        .padding(.horizontal, 20)
                }

                FloatingMenuScrollSpacer()
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.softBackground)
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await cloud.refreshSession()
            if cloud.isSignedIn {
                await cloud.syncMedications(with: store)
            }
        }
        .confirmationDialog(
            "Sign out?",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign out", role: .destructive) {
                Task { await cloud.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "You’ll stay signed out on this device until you sign in again. " +
                "Medications already on this iPhone are not removed."
            )
        }
        .confirmationDialog(
            "Delete account?",
            isPresented: $showDeleteAccountConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive) {
                Task { await cloud.deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This permanently deletes your OneLoop UIv2 cloud account and " +
                "backed-up medications. Medications already saved on this " +
                "device are not removed. This cannot be undone."
            )
        }
    }

    // MARK: - Not configured

    private var configurationMissingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                "Cloud account is not configured",
                systemImage: "exclamationmark.triangle.fill"
            )
            .foregroundStyle(AppTheme.warning)

            Text(
                "Add your Supabase Project URL and Publishable key in " +
                "SupabaseConfig.swift, then rebuild the app."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
    }

    // MARK: - Signed in

    private var signedInCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Signed in", systemImage: "person.crop.circle.badge.checkmark")
                .font(.headline)
                .foregroundStyle(AppTheme.blue)

            LabeledContent("Email") {
                Text(cloud.userEmail ?? "—")
                    .foregroundStyle(.secondary)
            }

            Text(
                "Medications on this device sync to your account automatically. " +
                "Only your account can access them."
            )
            .font(.caption)
            .foregroundStyle(AppTheme.mutedText)

            if let status = cloud.lastStatusMessage {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(AppTheme.teal)
            }

            if let error = cloud.lastErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppTheme.warning)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
        .padding(.horizontal, 20)
    }

    private var cloudSyncCard: some View {
        VStack(spacing: 12) {
            Button {
                Task { await cloud.pushMedications(from: store) }
            } label: {
                Label("Upload medications", systemImage: "icloud.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.blue)
            .disabled(cloud.isBusy)

            Button {
                Task { await cloud.pullMedications(into: store) }
            } label: {
                Label("Download medications", systemImage: "icloud.and.arrow.down")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .disabled(cloud.isBusy)

            Text(
                "Medications sync automatically when you sign in. " +
                "Upload and download are still available if you need to force a copy. " +
                "Download replaces local medications with the cloud copy."
            )
            .font(.caption)
            .foregroundStyle(AppTheme.mutedText)
        }
        .padding(20)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Sign out / delete account

    private var accountActionsSection: some View {
        VStack(spacing: 12) {
            Button {
                showSignOutConfirmation = true
            } label: {
                Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(cloud.isBusy)
            .opacity(cloud.isBusy ? 0.55 : 1)
            .accessibilityHint("Shows a confirmation before signing out")

            Button {
                showDeleteAccountConfirmation = true
            } label: {
                Label("Delete account", systemImage: "trash.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Color.red)
                    .background(
                        Color.red.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.red.opacity(0.45), lineWidth: 1.5)
                    }
            }
            .buttonStyle(.plain)
            .disabled(cloud.isBusy)
            .opacity(cloud.isBusy ? 0.55 : 1)
            .accessibilityHint("Shows a confirmation before permanently deleting your account")

            Text(
                "Delete account removes your cloud login and backed-up medications. " +
                "Local medications on this device are kept."
            )
            .font(.caption)
            .foregroundStyle(AppTheme.mutedText)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    NavigationStack {
        AccountAuthView(store: MedicationStore())
    }
}
