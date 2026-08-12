//
//  WidgetMedicationData.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import Foundation
import WidgetKit

struct WidgetMedicationData: Codable {
    let medicationName: String
    let dosage: String
    let reminderTime: Date
    let completedCount: Int
    let totalCount: Int
    let allMedicationsTaken: Bool

    static let empty = WidgetMedicationData(
        medicationName: "No medications",
        dosage: "Add a medication in OneLoop",
        reminderTime: .now,
        completedCount: 0,
        totalCount: 0,
        allMedicationsTaken: false
    )

    var progressText: String {
        "\(completedCount) of \(totalCount) taken"
    }
}

enum WidgetDataStore {
    static let appGroupIdentifier =
        "group.com.davidcarranco.oneloop.medtracker"

    static let medicationKey = "widgetMedicationData"

    static func save(_ data: WidgetMedicationData) {
        guard let sharedDefaults = UserDefaults(
            suiteName: appGroupIdentifier
        ) else {
            return
        }

        do {
            let encodedData = try JSONEncoder().encode(data)

            sharedDefaults.set(
                encodedData,
                forKey: medicationKey
            )

            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print(
                "Could not update widget data: " +
                error.localizedDescription
            )
        }
    }

    static func load() -> WidgetMedicationData {
        guard
            let sharedDefaults = UserDefaults(
                suiteName: appGroupIdentifier
            ),
            let encodedData = sharedDefaults.data(
                forKey: medicationKey
            ),
            let medicationData = try? JSONDecoder().decode(
                WidgetMedicationData.self,
                from: encodedData
            )
        else {
            return .empty
        }

        return medicationData
    }
}
