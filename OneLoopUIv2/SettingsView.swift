//
//  SettingsView.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    let store: MedicationStore

    @Bindable private var cloud = SupabaseManager.shared

    @AppStorage("useDarkMode") private var useDarkMode = false
    @AppStorage("useSystemAppearance")
    private var useSystemAppearance = true
    @AppStorage("notificationsEnabled")
    private var notificationsEnabled = false
    @AppStorage("useLiquidGlassNavigation")
    private var useLiquidGlassNavigation = false

    @State private var notificationStatus:
        NotificationManager.AuthorizationStatus = .notDetermined
    @State private var showOpenSettingsHint = false

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                notificationsSection
                appearanceSection
                legalSection
                supportSection
                aboutSection

                Section {
                    FloatingMenuScrollSpacer()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.softBackground)
            .tint(AppTheme.blue)
            .navigationTitle("Settings")
            .task {
                await refreshNotificationStatus()
                await cloud.refreshSession()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification
                )
            ) { _ in
                Task {
                    await refreshNotificationStatus()
                    await cloud.refreshSession()
                }
            }
        }
    }

    // MARK: - Account (subpage)

    private var accountSection: some View {
        Section {
            NavigationLink {
                AccountAuthView(store: store)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: cloud.isSignedIn
                          ? "person.crop.circle.badge.checkmark"
                          : "person.crop.circle")
                        .font(.title2)
                        .foregroundStyle(AppTheme.blue)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(
                            cloud.isSignedIn
                                ? "Account"
                                : "Sign in / Register"
                        )
                        .font(.body.weight(.medium))

                        Text(accountSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Account")
        } footer: {
            Text(
                "Optional cloud backup. After you sign in, medications " +
                "sync automatically across your devices."
            )
        }
    }

    private var accountSubtitle: String {
        if !SupabaseConfig.isConfigured {
            return "Cloud not configured"
        }
        if cloud.isSignedIn {
            return cloud.userEmail ?? "Signed in"
        }
        return "Email, password, or Google"
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section {
            Toggle(
                "Medication reminders",
                isOn: $notificationsEnabled
            )
            .onChange(of: notificationsEnabled) { _, isEnabled in
                Task {
                    await handleNotificationsToggle(isEnabled)
                }
            }

            if notificationStatus == .denied {
                VStack(alignment: .leading, spacing: 10) {
                    Text(
                        "Notifications are turned off for OneLoop UIv2 in " +
                        "iOS Settings. Enable them to receive dose reminders."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Button {
                        NotificationManager.shared.openSystemSettings()
                    } label: {
                        Label(
                            "Open Settings",
                            systemImage: "gear"
                        )
                    }
                }
            } else {
                Text(
                    "Receive a reminder at every scheduled medication dose."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if showOpenSettingsHint {
                Text(
                    "Permission was not granted. Use Open Settings to allow " +
                    "notifications for OneLoop UIv2."
                )
                .font(.caption)
                .foregroundStyle(AppTheme.warning)
            }
        } header: {
            Text("Notifications")
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Toggle(
                "Use system appearance",
                isOn: $useSystemAppearance
            )

            Toggle("Dark mode", isOn: $useDarkMode)
                .disabled(useSystemAppearance)

            Text(
                useSystemAppearance
                    ? "OneLoop UIv2 follows your device appearance setting."
                    : (
                        useDarkMode
                            ? "Dark mode is enabled."
                            : "Light mode is enabled."
                    )
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            if #available(iOS 26.0, *) {
                Toggle(
                    "Liquid Glass navigation",
                    isOn: $useLiquidGlassNavigation
                )

                Text(
                    useLiquidGlassNavigation
                        ? "System Liquid Glass tab bar (iOS 26)."
                        : "Floating capsule (pill) menu with center add button."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                Text(
                    "Bottom menu uses the floating capsule (pill) style. " +
                    "Liquid Glass requires iOS 26 or newer."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .onAppear {
                    useLiquidGlassNavigation = false
                }
            }
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        Section {
            NavigationLink {
                MedicalDisclaimerDetailView()
            } label: {
                Label(
                    "Medical Disclaimer",
                    systemImage: "stethoscope"
                )
            }

            NavigationLink {
                PrivacyPolicyDetailView()
            } label: {
                Label(
                    "Privacy Policy",
                    systemImage: "hand.raised.fill"
                )
            }

            if let privacyURL = AppInfo.privacyPolicyURL {
                Link(destination: privacyURL) {
                    Label(
                        "Privacy Policy (Online)",
                        systemImage: "safari"
                    )
                }
            }

            Text(AppInfo.medicalDisclaimerShort)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Legal")
        }
    }

    // MARK: - Support

    private var supportSection: some View {
        Section("Support") {
            if let mailto = AppInfo.supportMailtoURL {
                Link(destination: mailto) {
                    Label(
                        "Email Support",
                        systemImage: "envelope.fill"
                    )
                }
            }

            Text(AppInfo.supportEmail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            if let supportURL = AppInfo.supportURL {
                Link(destination: supportURL) {
                    Label(
                        "Support Website",
                        systemImage: "safari"
                    )
                }
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("App", value: AppInfo.appName)
            LabeledContent(
                "Version",
                value: "\(AppInfo.marketingVersion) (\(AppInfo.buildNumber))"
            )
            LabeledContent(
                "Medications",
                value: "\(store.medications.count)"
            )
        }
    }

    // MARK: - Actions

    private func refreshNotificationStatus() async {
        notificationStatus = await NotificationManager.shared
            .authorizationStatus

        if notificationsEnabled,
           notificationStatus == .denied
        {
            notificationsEnabled = false
        }

        if notificationStatus == .authorized {
            showOpenSettingsHint = false
        }
    }

    private func handleNotificationsToggle(_ isEnabled: Bool) async {
        showOpenSettingsHint = false

        if isEnabled {
            let granted = await NotificationManager.shared
                .requestAuthorization()

            await refreshNotificationStatus()

            if granted {
                await NotificationManager.shared.rescheduleAll(
                    for: store.medications
                )
            } else {
                notificationsEnabled = false

                if notificationStatus == .denied {
                    showOpenSettingsHint = true
                }
            }
        } else {
            await NotificationManager.shared
                .removeAllMedicationNotifications()
        }
    }
}

#Preview {
    SettingsView(store: MedicationStore())
}
