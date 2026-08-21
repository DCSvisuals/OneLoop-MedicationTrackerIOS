//
//  MedicationHistory.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import Foundation

/// A saved medication record for History.
/// Stores schedule *info* only — never taken / missed / daily logging.
/// Survives after the live medication is removed from the schedule.
struct MedicationHistoryEntry: Identifiable, Hashable, Codable {
    let id: UUID
    let medicationID: UUID

    var name: String
    var dosage: String
    var form: Medication.Form
    var instructions: String
    var startDate: Date
    var dosesPerDay: Int
    var intervalHours: Int
    /// Reference time used for the first daily dose (date portion ignored in UI).
    var firstDoseTime: Date
    /// Scheduled dose times for a representative day (informational only).
    var scheduledTimes: [Date]
    /// True when the live medication was deleted from the schedule.
    var wasRemovedFromSchedule: Bool
    /// When this history record was last written.
    var recordedAt: Date

    init(
        id: UUID = UUID(),
        medicationID: UUID,
        name: String,
        dosage: String,
        form: Medication.Form,
        instructions: String,
        startDate: Date,
        dosesPerDay: Int,
        intervalHours: Int,
        firstDoseTime: Date,
        scheduledTimes: [Date],
        wasRemovedFromSchedule: Bool = false,
        recordedAt: Date = .now
    ) {
        self.id = id
        self.medicationID = medicationID
        self.name = name
        self.dosage = dosage
        self.form = form
        self.instructions = instructions
        self.startDate = Calendar.current.startOfDay(for: startDate)
        self.dosesPerDay = dosesPerDay
        self.intervalHours = intervalHours
        self.firstDoseTime = firstDoseTime
        self.scheduledTimes = scheduledTimes.sorted()
        self.wasRemovedFromSchedule = wasRemovedFromSchedule
        self.recordedAt = recordedAt
    }

    var iconName: String {
        form.iconName
    }

    /// One history card per medication.
    var storageKey: String {
        medicationID.uuidString
    }
}
