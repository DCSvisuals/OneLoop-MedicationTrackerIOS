//
//  MedicationHistory.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import Foundation

/// A single scheduled dose captured for history.
struct MedicationHistoryDose: Identifiable, Hashable, Codable {
    let id: UUID
    let doseNumber: Int
    let scheduledTime: Date
    var status: Medication.Status
    var recordedAt: Date?

    init(
        id: UUID = UUID(),
        doseNumber: Int,
        scheduledTime: Date,
        status: Medication.Status,
        recordedAt: Date? = nil
    ) {
        self.id = id
        self.doseNumber = doseNumber
        self.scheduledTime = scheduledTime
        self.status = status
        self.recordedAt = recordedAt
    }
}

/// One medication's schedule snapshot for a single calendar day.
/// Survives even after the live medication is removed from the schedule.
struct MedicationHistoryEntry: Identifiable, Hashable, Codable {
    let id: UUID
    let medicationID: UUID
    /// Start of the calendar day this entry belongs to.
    let day: Date

    var name: String
    var dosage: String
    var form: Medication.Form
    var instructions: String
    var doses: [MedicationHistoryDose]
    /// True when the live medication was deleted from the schedule.
    var wasRemovedFromSchedule: Bool

    init(
        id: UUID = UUID(),
        medicationID: UUID,
        day: Date,
        name: String,
        dosage: String,
        form: Medication.Form,
        instructions: String,
        doses: [MedicationHistoryDose],
        wasRemovedFromSchedule: Bool = false
    ) {
        self.id = id
        self.medicationID = medicationID
        self.day = Calendar.current.startOfDay(for: day)
        self.name = name
        self.dosage = dosage
        self.form = form
        self.instructions = instructions
        self.doses = doses.sorted { $0.doseNumber < $1.doseNumber }
        self.wasRemovedFromSchedule = wasRemovedFromSchedule
    }

    var completedCount: Int {
        doses.filter { $0.status == .taken }.count
    }

    var totalCount: Int {
        doses.count
    }

    var missedCount: Int {
        doses.filter { $0.status == .missed }.count
    }

    var isComplete: Bool {
        !doses.isEmpty && doses.allSatisfy { $0.status == .taken }
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var iconName: String {
        form.iconName
    }

    /// Stable key used to upsert one entry per medication per day.
    static func storageKey(
        medicationID: UUID,
        day: Date
    ) -> String {
        let dayKey = Calendar.current
            .startOfDay(for: day)
            .timeIntervalSince1970

        return "\(medicationID.uuidString)-\(dayKey)"
    }

    var storageKey: String {
        Self.storageKey(medicationID: medicationID, day: day)
    }
}

/// A day section used by the History UI.
struct MedicationHistoryDayGroup: Identifiable {
    let day: Date
    let entries: [MedicationHistoryEntry]

    var id: Date { day }
}
