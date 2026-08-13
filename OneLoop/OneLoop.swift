//
//  OneLoop.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import SwiftUI

@main
struct OneLoopApp: App {
    @State private var medicationStore = MedicationStore()
    @AppStorage("hasCompletedOnboarding_v3") private var hasCompletedOnboarding = false
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
                            || UserDefaults.standard.bool(forKey: "hasCompletedOnboarding_v3")
                        {
                            hasAcceptedDisclaimer = true
                            hasCompletedOnboarding = true
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
                }
                .task {
                    await SupabaseManager.shared.refreshSession()
                }
        }
    }
}
