//
//  NotificationManager.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import Foundation
import UIKit
@preconcurrency import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    enum AuthorizationStatus: Equatable {
        case authorized
        case denied
        case notDetermined
        case unknown
    }

    /// iOS allows at most 64 pending local notifications.
    /// Keep a short horizon so multiple medications stay under the cap.
    private let scheduleDaysAhead = 7
    private let maxPendingNotifications = 60

    private init() {}

    var authorizationStatus: AuthorizationStatus {
        get async {
            let settings = await UNUserNotificationCenter
                .current()
                .notificationSettings()

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                return .authorized
            case .denied:
                return .denied
            case .notDetermined:
                return .notDetermined
            @unknown default:
                return .unknown
            }
        }
    }

    var isAuthorized: Bool {
        get async {
            await authorizationStatus == .authorized
        }
    }

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let settings = await center.notificationSettings()

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                return true

            case .notDetermined:
                return try await center.requestAuthorization(
                    options: [.alert, .badge, .sound]
                )

            case .denied:
                return false

            @unknown default:
                return false
            }
        } catch {
            print(
                "Notification permission error: " +
                error.localizedDescription
            )
            return false
        }
    }

    /// Opens the system Settings page for OneLoop so the user can enable notifications.
    func openSystemSettings() {
        guard let url = URL(
            string: UIApplication.openSettingsURLString
        ) else {
            return
        }

        UIApplication.shared.open(url)
    }

    func scheduleNotifications(for medication: Medication) async {
        guard UserDefaults.standard.bool(
            forKey: "notificationsEnabled"
        ) else {
            await removeNotifications(for: medication)
            return
        }

        let isAuthorized = await requestAuthorization()
        guard isAuthorized else {
            return
        }

        await removeNotifications(for: medication)

        let calendar = Calendar.current
        let center = UNUserNotificationCenter.current()
        let today = calendar.startOfDay(for: .now)

        let existingPending = await center.pendingNotificationRequests()
        var remainingSlots = max(
            0,
            maxPendingNotifications - existingPending.count
        )

        guard remainingSlots > 0 else {
            return
        }

        for offset in 0..<scheduleDaysAhead {
            guard remainingSlots > 0 else {
                break
            }

            guard let scheduledDay = calendar.date(
                byAdding: .day,
                value: offset,
                to: today
            ) else {
                continue
            }

            guard medication.isActive(on: scheduledDay) else {
                continue
            }

            let dosesForDay = medication.dosesPerDay(on: scheduledDay)
            guard dosesForDay > 0 else {
                continue
            }

            let intervalForDay = medication.intervalHours(
                on: scheduledDay
            )

            for doseIndex in 0..<dosesForDay {
                guard remainingSlots > 0 else {
                    break
                }

                let scheduledTime = medication.doseTime(
                    for: doseIndex,
                    on: scheduledDay,
                    intervalHours: intervalForDay
                )

                guard scheduledTime > .now else {
                    continue
                }

                let content = UNMutableNotificationContent()
                content.title = "Time for \(medication.name)"
                content.body =
                    "Dose \(doseIndex + 1) of " +
                    "\(dosesForDay): " +
                    medication.dosage
                content.sound = .default
                content.categoryIdentifier = "MEDICATION_REMINDER"
                content.userInfo = [
                    "medicationID": medication.id.uuidString,
                    "doseNumber": doseIndex + 1
                ]

                let components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: scheduledTime
                )

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: false
                )

                let identifier = notificationIdentifier(
                    medicationID: medication.id,
                    date: scheduledDay,
                    doseIndex: doseIndex
                )

                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )

                do {
                    try await center.add(request)
                    remainingSlots -= 1
                } catch {
                    print(
                        "Could not schedule notification: " +
                        error.localizedDescription
                    )
                }
            }
        }
    }

    func scheduleSnoozeNotification(
        for medication: Medication,
        doseNumber: Int,
        at date: Date
    ) async {
        guard UserDefaults.standard.bool(
            forKey: "notificationsEnabled"
        ) else {
            return
        }

        let isAuthorized = await requestAuthorization()
        guard isAuthorized else {
            return
        }

        guard date > .now else {
            return
        }

        let center = UNUserNotificationCenter.current()
        let identifier =
            "\(medication.id.uuidString)-snooze-\(doseNumber)"

        center.removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )

        let content = UNMutableNotificationContent()
        content.title = "Snoozed reminder: \(medication.name)"
        content.body =
            "Dose \(doseNumber): \(medication.dosage)"
        content.sound = .default
        content.categoryIdentifier = "MEDICATION_REMINDER"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print(
                "Could not schedule snooze notification: " +
                error.localizedDescription
            )
        }
    }

    func removeNotifications(for medication: Medication) async {
        let center = UNUserNotificationCenter.current()
        let prefix = "\(medication.id.uuidString)-"

        let pendingRequests = await center.pendingNotificationRequests()
        let pendingIdentifiers = pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }

        center.removePendingNotificationRequests(
            withIdentifiers: pendingIdentifiers
        )

        let deliveredNotifications = await center.deliveredNotifications()
        let deliveredIdentifiers = deliveredNotifications
            .map(\.request.identifier)
            .filter { $0.hasPrefix(prefix) }

        center.removeDeliveredNotifications(
            withIdentifiers: deliveredIdentifiers
        )
    }

    func removeAllMedicationNotifications() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    func rescheduleAll(for medications: [Medication]) async {
        await removeAllMedicationNotifications()

        guard UserDefaults.standard.bool(
            forKey: "notificationsEnabled"
        ) else {
            return
        }

        for medication in medications {
            await scheduleNotifications(for: medication)
        }
    }

    private func notificationIdentifier(
        medicationID: UUID,
        date: Date,
        doseIndex: Int
    ) -> String {
        let dateKey = Calendar.current
            .startOfDay(for: date)
            .formatted(
                .iso8601
                    .year()
                    .month()
                    .day()
            )

        return "\(medicationID.uuidString)-" +
            "\(dateKey)-dose-\(doseIndex)"
    }
}
