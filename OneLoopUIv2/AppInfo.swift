//
//  AppInfo.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import Foundation

/// Central place for App Store–facing metadata and legal copy.
enum AppInfo {
    static let appName = "OneLoop UIv2"
    static let marketingVersion =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        ?? "1.0"
    static let buildNumber =
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        ?? "1"

    /// Update this before shipping if you have a public site.
    static let supportEmail = "support@oneloop.app"
    static let supportMailtoURL = URL(
        string: "mailto:\(supportEmail)?subject=OneLoop%20UIv2%20Support"
    )

    /// Public site (GitHub Pages).
    static let homeURL = URL(
        string: "https://dcsvisuals.github.io/OneLoop-MedicationTracker-PrivacyPolicy/"
    )

    /// Hosted privacy policy URL for App Store Connect and in-app links.
    static let privacyPolicyURL = URL(
        string: "https://dcsvisuals.github.io/OneLoop-MedicationTracker-PrivacyPolicy/privacy/"
    )

    static let supportURL = URL(
        string: "https://dcsvisuals.github.io/OneLoop-MedicationTracker-PrivacyPolicy/support/"
    )

    // MARK: - Medical disclaimer

    static let medicalDisclaimerShort =
        "OneLoop UIv2 is a personal medication reminder tool. " +
        "It is not a medical device and does not provide medical advice, " +
        "diagnosis, or treatment. Optional account data may be stored with Supabase."

    static let medicalDisclaimerFull = """
    OneLoop UIv2 is a personal organization and reminder app. It is intended only \
    to help you track medication schedules you enter yourself.

    OneLoop UIv2 is not a medical device. It does not provide medical advice, \
    diagnosis, or treatment, and it does not replace guidance from a licensed \
    healthcare professional, pharmacist, or the instructions on your \
    medication label.

    Always follow the dosing instructions from your clinician and pharmacist. \
    Do not start, stop, or change any medication based solely on information \
    in this app.

    Reminder notifications depend on your device settings, power state, and \
    system permissions. OneLoop UIv2 cannot guarantee that every reminder will be \
    delivered or seen. You remain responsible for taking your medications as \
    prescribed.

    Account and cloud backup: If you create an account or sign in (for example \
    with email or Google), OneLoop UIv2 may store your account information and any \
    medication data you choose to upload on Supabase (a cloud database and \
    authentication service). Cloud backup is optional. Data kept only on this \
    device is not sent to Supabase until you sign in and upload.

    If you have a medical emergency, contact emergency services immediately.
    """

    // MARK: - Privacy policy (in-app)

    static let privacyPolicyFull = """
    Last updated: August 2026

    OneLoop UIv2 (“we”, “the app”) respects your privacy.

    1. Data we store
    OneLoop UIv2 stores information you enter about medications and dosing \
    schedules, including medication names, amounts, forms, reminder times, \
    dose completion status, and related history. If you create an account, \
    we also store account identifiers such as your email address and \
    authentication provider details (for example Google sign-in).

    2. Where data is stored
    Medication data is stored on your device (application support storage) \
    by default. Widget summary data may be shared with the OneLoop UIv2 widget \
    through an App Group on the same device.

    Optional cloud storage (Supabase): When you register or sign in and use \
    cloud backup/sync, account and medication information you upload is \
    stored in Supabase (hosted cloud infrastructure used for authentication \
    and database storage). Access to cloud rows is restricted with Row Level \
    Security so only your signed-in account can access your data. Sign-in \
    providers you choose (such as Google) process authentication according \
    to their own policies.

    3. Notifications
    If you enable medication reminders, OneLoop UIv2 schedules local notifications \
    on your device. Notification permission is optional and can be changed in \
    iOS Settings.

    4. Analytics and advertising
    This version of OneLoop UIv2 does not include third-party advertising SDKs or \
    analytics SDKs that track you across apps and websites.

    5. Sharing
    We do not sell your personal information. Cloud data is processed by \
    Supabase (and your chosen sign-in provider, if any) only to provide the \
    app’s account and sync features. If you use device backup (for example \
    iCloud Backup), Apple’s backup practices may include local app data \
    according to your Apple account settings.

    6. Your choices
    You can use OneLoop UIv2 without an account (data stays on device). You can \
    sign out, avoid uploading, delete medications in the app, disable \
    notifications, or delete the app to remove local app data (subject to \
    any device backups you maintain). You may also request account-related \
    help via the support contact below.

    7. Children
    OneLoop UIv2 is not directed at children under 13. Do not enter another person’s \
    medication information unless you are authorized to manage it.

    8. Contact
    For privacy questions, contact: \(supportEmail)

    9. Changes
    We may update this policy when the app changes. The “Last updated” date \
    will be revised when material changes are made.
    """
}
