//
//  SupabaseManager.swift
//  OneLoop
//

import AuthenticationServices
import Foundation
import Observation
import Supabase

@Observable
@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()

    private(set) var client: SupabaseClient?
    private(set) var session: Session?
    private(set) var isBusy = false
    var lastErrorMessage: String?
    var lastStatusMessage: String?

    var isSignedIn: Bool { session != nil }

    var userEmail: String? {
        session?.user.email
    }

    var userID: UUID? {
        session?.user.id
    }

    private init() {
        configureClientIfPossible()
    }

    // MARK: - Client

    func configureClientIfPossible() {
        guard SupabaseConfig.isConfigured,
              let url = SupabaseConfig.projectURL
        else {
            client = nil
            return
        }

        // Pin default auth redirects to the app scheme so OAuth returns to
        // OneLoop (and ASWebAuthenticationSession can auto-dismiss).
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.publishableKey,
            options: SupabaseClientOptions(
                auth: .init(
                    redirectToURL: SupabaseConfig.authRedirectURL,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )

        Task {
            await refreshSession()
            await listenForAuthChanges()
        }
    }

    /// Keep `session` in sync when auth completes (OAuth, deep link, etc.).
    private func listenForAuthChanges() async {
        guard let client else { return }

        for await (event, newSession) in client.auth.authStateChanges {
            switch event {
            case .initialSession:
                session = newSession
            case .signedIn, .tokenRefreshed, .userUpdated:
                session = newSession
                if newSession != nil {
                    completeAuthenticationSideEffects()
                }
            case .signedOut:
                session = nil
            default:
                if let newSession {
                    session = newSession
                }
            }
        }
    }

    func refreshSession() async {
        guard let client else { return }

        do {
            session = try await client.auth.session
            lastErrorMessage = nil
        } catch {
            session = nil
        }
    }

    // MARK: - Auth

    func signInWithEmailOTP(email: String) async {
        guard let client else {
            lastErrorMessage = "Add your Supabase URL and publishable key in SupabaseConfig.swift."
            return
        }

        isBusy = true
        lastErrorMessage = nil
        lastStatusMessage = nil
        defer { isBusy = false }

        do {
            try await client.auth.signInWithOTP(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                redirectTo: SupabaseConfig.authRedirectURL
            )
            lastStatusMessage =
                "Check your email for a sign-in link, then return to OneLoop."
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func signInWithEmailPassword(email: String, password: String) async {
        guard let client else {
            lastErrorMessage = "Add your Supabase URL and publishable key in SupabaseConfig.swift."
            return
        }

        isBusy = true
        lastErrorMessage = nil
        lastStatusMessage = nil
        defer { isBusy = false }

        do {
            session = try await client.auth.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            lastStatusMessage = "Signed in."
            completeAuthenticationSideEffects()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func signUpWithEmailPassword(
        email: String,
        password: String,
        fullName: String? = nil
    ) async {
        guard let client else {
            lastErrorMessage = "Add your Supabase URL and publishable key in SupabaseConfig.swift."
            return
        }

        isBusy = true
        lastErrorMessage = nil
        lastStatusMessage = nil
        defer { isBusy = false }

        do {
            let trimmedName = fullName?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let metadata: [String: AnyJSON]? = {
                guard let trimmedName, !trimmedName.isEmpty else { return nil }
                return ["full_name": .string(trimmedName)]
            }()

            let response = try await client.auth.signUp(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                data: metadata,
                redirectTo: SupabaseConfig.authRedirectURL
            )
            session = response.session
            if session == nil {
                lastStatusMessage =
                    "Account created. Check your email to confirm, then open the link on this device."
                // Still enter the app; email confirm will open OneLoop via deep link.
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding_v3")
                UserDefaults.standard.set(true, forKey: "hasAcceptedMedicalDisclaimer")
                NotificationCenter.default.post(
                    name: Self.didAuthenticateNotification,
                    object: nil
                )
            } else {
                lastStatusMessage = "Account created and signed in."
                completeAuthenticationSideEffects()
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func sendPasswordReset(email: String) async {
        guard let client else {
            lastErrorMessage = "Add your Supabase URL and publishable key in SupabaseConfig.swift."
            return
        }

        isBusy = true
        lastErrorMessage = nil
        lastStatusMessage = nil
        defer { isBusy = false }

        do {
            try await client.auth.resetPasswordForEmail(
                email.trimmingCharacters(in: .whitespacesAndNewlines),
                redirectTo: SupabaseConfig.authRedirectURL
            )
            lastStatusMessage = "Password reset email sent. Check your inbox."
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    /// Google OAuth via a dedicated browser presenter that always completes
    /// on the `oneloop://` deep link (auto-dismisses the sheet).
    func signInWithGoogle() async {
        guard let client else {
            lastErrorMessage = "Add your Supabase URL and publishable key in SupabaseConfig.swift."
            return
        }

        isBusy = true
        lastErrorMessage = nil
        lastStatusMessage = nil
        defer { isBusy = false }

        do {
            session = try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: SupabaseConfig.authRedirectURL,
                launchFlow: { url in
                    // Custom presenter: closes on oneloop:// and also accepts
                    // the same URL from the app's onOpenURL handler.
                    try await OAuthBrowserPresenter.shared.authenticate(
                        url: url,
                        callbackScheme: "oneloop"
                    )
                }
            )
            lastErrorMessage = nil
            lastStatusMessage = "Signed in with Google."
            completeAuthenticationSideEffects()
        } catch {
            await refreshSession()
            if session != nil {
                lastErrorMessage = nil
                lastStatusMessage = "Signed in with Google."
                completeAuthenticationSideEffects()
                return
            }

            let nsError = error as NSError
            let isCancel =
                (nsError.domain == ASWebAuthenticationSessionError.errorDomain
                    && nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue)
                || error is CancellationError
                || error.localizedDescription.localizedCaseInsensitiveContains("cancel")

            if isCancel {
                lastErrorMessage = nil
                lastStatusMessage = nil
            } else {
                lastErrorMessage = error.localizedDescription
            }
        }
    }

    func handleAuthCallback(url: URL) async {
        // HTTPS bridge page may open the app via oneloop://…
        // Mid-flight OAuth: hand the URL to the browser presenter first so
        // signInWithOAuth can exchange the code and dismiss the sheet.
        if url.scheme?.lowercased() == "oneloop" {
            if OAuthBrowserPresenter.shared.handleIncomingURL(url) {
                return
            }
        } else {
            return
        }

        guard let client else { return }

        do {
            session = try await client.auth.session(from: url)
            lastErrorMessage = nil
            lastStatusMessage = "Signed in."
            completeAuthenticationSideEffects()
        } catch {
            await refreshSession()
            if session != nil {
                lastErrorMessage = nil
                lastStatusMessage = "Signed in."
                completeAuthenticationSideEffects()
            } else {
                lastErrorMessage = error.localizedDescription
            }
        }
    }

    /// Posted when a session is established so UI can leave onboarding / refresh.
    static let didAuthenticateNotification = Notification.Name(
        "OneLoop.Supabase.didAuthenticate"
    )

    private func notifyAuthenticated() {
        guard session != nil else { return }
        NotificationCenter.default.post(
            name: Self.didAuthenticateNotification,
            object: nil
        )
    }

    /// Persist onboarding completion immediately so UI can't get stuck on the
    /// login carousel after a successful sign-in.
    private func completeAuthenticationSideEffects() {
        guard session != nil else { return }

        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding_v3")
        UserDefaults.standard.set(true, forKey: "hasAcceptedMedicalDisclaimer")

        notifyAuthenticated()
    }

    func signOut() async {
        guard let client else { return }

        isBusy = true
        defer { isBusy = false }

        do {
            try await client.auth.signOut()
            session = nil
            lastStatusMessage = "Signed out."
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    /// Deletes cloud medication rows for this user, then the Auth user via
    /// `DELETE /auth/v1/user` (requires “Allow users to delete their own accounts”
    /// in the Supabase Auth settings). Clears the local session on success.
    func deleteAccount() async {
        guard let client,
              let userID,
              let accessToken = session?.accessToken
        else {
            lastErrorMessage = "Sign in before deleting your account."
            return
        }

        isBusy = true
        lastErrorMessage = nil
        lastStatusMessage = nil
        defer { isBusy = false }

        do {
            // Remove app data first (RLS-scoped to this user).
            try await client
                .from("medications")
                .delete()
                .eq("user_id", value: userID)
                .execute()

            // Self-service account deletion (GoTrue).
            guard let projectURL = SupabaseConfig.projectURL else {
                lastErrorMessage = "Cloud is not configured."
                return
            }

            var request = URLRequest(
                url: projectURL.appendingPathComponent("auth/v1/user")
            )
            request.httpMethod = "DELETE"
            request.setValue(
                "Bearer \(accessToken)",
                forHTTPHeaderField: "Authorization"
            )
            request.setValue(
                SupabaseConfig.publishableKey,
                forHTTPHeaderField: "apikey"
            )

            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1

            guard (200...299).contains(status) else {
                lastErrorMessage =
                    "Could not delete account (HTTP \(status)). " +
                    "In Supabase → Authentication → Providers / Settings, " +
                    "enable “Allow users to delete their own accounts”, then try again."
                return
            }

            // Local cleanup — user is gone on the server.
            try? await client.auth.signOut()
            session = nil
            lastStatusMessage = "Your account was deleted."
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    // MARK: - Sync medications

    func pushMedications(from store: MedicationStore) async {
        guard let client, let userID else {
            lastErrorMessage = "Sign in before syncing."
            return
        }

        isBusy = true
        lastErrorMessage = nil
        lastStatusMessage = nil
        defer { isBusy = false }

        do {
            let rows = store.medications.map {
                MedicationRemoteRow(medication: $0, userID: userID)
            }

            try await client
                .from("medications")
                .upsert(rows, onConflict: "id")
                .execute()

            lastStatusMessage =
                "Uploaded \(rows.count) medication" +
                (rows.count == 1 ? "" : "s") +
                " to the cloud."
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func pullMedications(into store: MedicationStore) async {
        guard let client, userID != nil else {
            lastErrorMessage = "Sign in before syncing."
            return
        }

        isBusy = true
        lastErrorMessage = nil
        lastStatusMessage = nil
        defer { isBusy = false }

        do {
            let rows: [MedicationRemoteRow] = try await client
                .from("medications")
                .select()
                .execute()
                .value

            let remoteMeds = rows.map { $0.asMedication() }
            store.replaceAllMedications(with: remoteMeds)

            lastStatusMessage =
                "Downloaded \(remoteMeds.count) medication" +
                (remoteMeds.count == 1 ? "" : "s") +
                " from the cloud."
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }
}

// MARK: - Remote DTO

struct MedicationRemoteRow: Codable, Sendable {
    let id: UUID
    let user_id: UUID
    let name: String
    let start_date: String
    let doses_per_day: Int
    let dose_amount: Double
    let dose_unit: String
    let first_dose_time: String
    let interval_hours: Int
    let form: String
    let has_schedule_change: Bool
    let schedule_change_after_days: Int
    let doses_per_day_after_change: Int
    let interval_hours_after_change: Int

    init(medication: Medication, userID: UUID) {
        let dayFormatter = DateFormatter()
        dayFormatter.calendar = Calendar(identifier: .gregorian)
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dayFormatter.dateFormat = "yyyy-MM-dd"

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        id = medication.id
        user_id = userID
        name = medication.name
        start_date = dayFormatter.string(from: medication.startDate)
        doses_per_day = medication.dosesPerDay
        dose_amount = medication.doseAmount
        dose_unit = medication.doseUnit.rawValue
        first_dose_time = iso.string(from: medication.firstDoseTime)
        interval_hours = medication.intervalHours
        form = medication.form.rawValue
        has_schedule_change = medication.hasScheduleChange
        schedule_change_after_days = medication.scheduleChangeAfterDays
        doses_per_day_after_change = medication.dosesPerDayAfterChange
        interval_hours_after_change = medication.intervalHoursAfterChange
    }

    func asMedication() -> Medication {
        let dayFormatter = DateFormatter()
        dayFormatter.calendar = Calendar(identifier: .gregorian)
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dayFormatter.dateFormat = "yyyy-MM-dd"

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let isoBasic = ISO8601DateFormatter()
        isoBasic.formatOptions = [.withInternetDateTime]

        let start = dayFormatter.date(from: start_date) ?? .now
        let firstTime =
            iso.date(from: first_dose_time) ??
            isoBasic.date(from: first_dose_time) ??
            .now

        let unit = Medication.DoseUnit(rawValue: dose_unit) ?? .mg
        let formValue = Medication.Form(rawValue: form) ?? .pill

        return Medication(
            id: id,
            name: name,
            startDate: start,
            dosesPerDay: doses_per_day,
            doseAmount: dose_amount,
            doseUnit: unit,
            firstDoseTime: firstTime,
            intervalHours: interval_hours,
            form: formValue,
            hasScheduleChange: has_schedule_change,
            scheduleChangeAfterDays: schedule_change_after_days,
            dosesPerDayAfterChange: doses_per_day_after_change,
            intervalHoursAfterChange: interval_hours_after_change
        )
    }
}
