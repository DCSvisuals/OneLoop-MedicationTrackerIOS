//
//  AppInfo.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import Foundation

/// Central place for App Store–facing metadata and legal copy.
enum AppInfo {
    static let appName = "OneLoop"
    static let marketingVersion =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        ?? "1.0"
    static let buildNumber =
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        ?? "1"

    /// Update this before shipping if you have a public site.
    static let supportEmail = "support@oneloop.app"
    static let supportMailtoURL = URL(
        string: "mailto:\(supportEmail)?subject=OneLoop%20Support"
    )

    /// Hosted privacy policy URL for App Store Connect.
    /// Until you publish one, the in-app Privacy Policy screen is available.
    /// Replace with your real HTTPS URL when ready.
    static let privacyPolicyURL = URL(
        string: "https://oneloop.app/privacy"
    )

    static let supportURL = URL(
        string: "https://oneloop.app/support"
    )

    // MARK: - Medical disclaimer

    static let medicalDisclaimerShort =
        "OneLoop is a personal medication reminder tool. " +
        "It is not a medical device and does not provide medical advice, " +
        "diagnosis, or treatment."

    static let medicalDisclaimerFull = """
    OneLoop is a personal organization and reminder app. It is intended only \
    to help you track medication schedules you enter yourself.

    OneLoop is not a medical device. It does not provide medical advice, \
    diagnosis, or treatment, and it does not replace guidance from a licensed \
    healthcare professional, pharmacist, or the instructions on your \
    medication label.

    Always follow the dosing instructions from your clinician and pharmacist. \
    Do not start, stop, or change any medication based solely on information \
    in this app.

    Reminder notifications depend on your device settings, power state, and \
    system permissions. OneLoop cannot guarantee that every reminder will be \
    delivered or seen. You remain responsible for taking your medications as \
    prescribed.

    If you have a medical emergency, contact emergency services immediately.
    """

    // MARK: - Privacy policy (in-app)

    static let privacyPolicyFull = """
    Last updated: August 2026

    OneLoop (“we”, “the app”) respects your privacy.

    1. Data we store
    OneLoop stores information you enter about medications and dosing \
    schedules, including medication names, amounts, forms, reminder times, \
    dose completion status, and related history.

    2. Where data is stored
    Medication data is stored on your device (application support storage). \
    Widget summary data may be shared with the OneLoop widget through an \
    App Group on the same device. Data is not uploaded to OneLoop servers \
    because OneLoop does not operate a backend account service in this version.

    3. Notifications
    If you enable medication reminders, OneLoop schedules local notifications \
    on your device. Notification permission is optional and can be changed in \
    iOS Settings.

    4. Analytics and advertising
    This version of OneLoop does not include third-party advertising SDKs or \
    analytics SDKs that track you across apps and websites.

    5. Sharing
    We do not sell your personal information. Because medication data stays on \
    your device in this version, it is not transmitted by OneLoop to external \
    servers. If you use device backup (for example iCloud Backup), Apple’s \
    backup practices may include app data according to your Apple account \
    settings.

    6. Your choices
    You can delete medications in the app, disable notifications, or delete \
    the app to remove local app data from the device (subject to any device \
    backups you maintain).

    7. Children
    OneLoop is not directed at children under 13. Do not enter another person’s \
    medication information unless you are authorized to manage it.

    8. Contact
    For privacy questions, contact: \(supportEmail)

    9. Changes
    We may update this policy when the app changes. The “Last updated” date \
    will be revised when material changes are made.
    """
}
