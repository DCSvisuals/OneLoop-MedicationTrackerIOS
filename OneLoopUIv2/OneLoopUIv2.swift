//
//  OneLoopUIv2.swift
//  OneLoopUIv2
//
//  Created by David Carranco on 2026-08-01.
//

import SwiftUI

@main
struct OneLoopUIv2App: App {
    @State private var medicationStore = MedicationStore()
    @AppStorage("hasCompletedOnboarding_v4") private var hasCompletedOnboarding = false
    @AppStorage("hasAcceptedMedicalDisclaimer") private var hasAcceptedDisclaimer = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(medicationStore)
                .onOpenURL { url in
                    Task {
                        // Prefer completing an in-flight OAuth browser session.
                        // Falls through to session exchange for magic links / email confirm.
                        await SupabaseManager.shared.handleAuthCallback(url: url)
                        if SupabaseManager.shared.isSignedIn
                            || UserDefaults.standard.bool(forKey: "hasCompletedOnboarding_v4")
                        {
                            hasAcceptedDisclaimer = true
                            hasCompletedOnboarding = true
                        }
                        if SupabaseManager.shared.isSignedIn {
                            await SupabaseManager.shared.syncMedications(
                                with: medicationStore
                            )
                        }
                    }
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: SupabaseManager.didAuthenticateNotification
                    )
                ) { _ in
                    hasAcceptedDisclaimer = true
                    hasCompletedOnboarding = true
                    Task {
                        if SupabaseManager.shared.isSignedIn {
                            await SupabaseManager.shared.syncMedications(
                                with: medicationStore
                            )
                        }
                    }
                }
                .task {
                    await SupabaseManager.shared.refreshSession()
                    if SupabaseManager.shared.isSignedIn {
                        await SupabaseManager.shared.syncMedications(
                            with: medicationStore
                        )
                    }
                }
        }
    }
}
