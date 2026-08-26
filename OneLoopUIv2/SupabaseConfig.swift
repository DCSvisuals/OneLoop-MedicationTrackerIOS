//
//  SupabaseConfig.swift
//  OneLoop
//
//  Fill in your Project URL and Publishable key from Supabase:
//  Project Settings → API
//

import Foundation

enum SupabaseConfig {
    /// Example: https://abcdefgh.supabase.co
    static let projectURLString = "https://eraojepflpmvcymumggy.supabase.co"

    /// Publishable key (sb_publishable_...) — never use the secret key here.
    static let publishableKey = "sb_publishable_43Gtyki76s6iUMRhPKBfrA_Mz2qZNMa"

    /// HTTPS bridge hosted on GitHub Pages.
    /// Supabase redirects here after Google; the page immediately forwards to
    /// `oneloopuiv2://auth-callback…` so ASWebAuthenticationSession can close.
    ///
    /// Deploy `docs/auth-callback/index.html` to:
    /// https://dcsvisuals.github.io/OneLoop-MedicationTracker-PrivacyPolicy/auth-callback/
    static let authRedirectURL = URL(
        string: "https://dcsvisuals.github.io/OneLoop-MedicationTracker-PrivacyPolicy/auth-callback/"
    )!

    /// Custom URL scheme registered in App-Info.plist.
    static let authCallbackScheme = "oneloopuiv2"

    /// Final deep link prefix used by the bridge page and onOpenURL.
    static let authCallbackURL = URL(string: "oneloopuiv2://auth-callback")!

    static var projectURL: URL? {
        guard projectURLString.hasPrefix("https://"),
              !projectURLString.contains("YOUR_"),
              let url = URL(string: projectURLString)
        else {
            return nil
        }
        return url
    }

    static var isConfigured: Bool {
        projectURL != nil &&
        !publishableKey.isEmpty &&
        !publishableKey.contains("YOUR_")
    }
}
