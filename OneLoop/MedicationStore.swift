//
//  MedicationStore.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import Foundation
import Observation

@Observable
final class MedicationStore {

    struct ScheduledDose: Identifiable, Hashable {
        let medication: Medication
        let doseNumber: Int
        let scheduledTime: Date
        let status: Medication.Status

        var id: String {
            "\(medication.id.uuidString)-\(doseNumber)"
        }
    }

    var medications: [Medication] = []
    /// Persisted schedule snapshots. Independent of the live medication list.
    var historyEntries: [MedicationHistoryEntry] = []

    private let fileManager = FileManager.default
    private let fileName = "medications.json"
    private let historyFileName = "medicationHistory.json"
    private let resetDateFileName = "lastDoseResetDate.txt"

    /// Grace period after a scheduled time before a dose is considered missed.
    private let missedGraceMinutes = 60

    init() {
        loadMedications()
        loadHistory()
        resetDosesIfNeeded()
    }

    // MARK: - History

    /// History grouped by day, newest first.
    var historyDayGroups: [MedicationHistoryDayGroup] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: historyEntries) { entry in
            calendar.startOfDay(for: entry.day)
        }

        return grouped
            .map { day, entries in
                MedicationHistoryDayGroup(
                    day: day,
                    entries: entries.sorted {
                        if $0.name.localizedCaseInsensitiveCompare($1.name)
                            != .orderedSame
                        {
                            return $0.name.localizedCaseInsensitiveCompare(
                                $1.name
                            ) == .orderedAscending
                        }

                        return $0.medicationID.uuidString <
                            $1.medicationID.uuidString
                    }
                )
            }
            .sorted { $0.day > $1.day }
    }

    // MARK: - Today

    var scheduledDoses: [ScheduledDose] {
        scheduledDoses(on: .now)
    }

    /// Builds the schedule for any calendar day.
    /// Status for non-today days is always upcoming (no historical tracking yet).
    func scheduledDoses(on date: Date, now: Date = .now) -> [ScheduledDose] {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let isToday = calendar.isDate(day, inSameDayAs: now)

        return medications
            .flatMap { medication -> [ScheduledDose] in
                guard medication.isActive(on: day) else {
                    return []
                }

                let activeDoseCount = medication.dosesPerDay(on: day)
                guard activeDoseCount > 0 else {
                    return []
                }

                let activeInterval = medication.intervalHours(on: day)

                return (0..<activeDoseCount).map { index in
                    let doseNumber = index + 1

                    let scheduledTime = medication.doseTime(
                        for: index,
                        on: day,
                        intervalHours: activeInterval
                    )

                    let status: Medication.Status

                    if isToday {
                        let savedDose = medication.doses.first {
                            $0.number == doseNumber
                        }

                        status = resolvedStatus(
                            savedStatus: savedDose?.status ?? .upcoming,
                            scheduledTime: scheduledTime,
                            snoozedUntil: savedDose?.snoozedUntil,
                            now: now
                        )
                    } else {
                        status = .upcoming
                    }

                    return ScheduledDose(
                        medication: medication,
                        doseNumber: doseNumber,
                        scheduledTime: scheduledTime,
                        status: status
                    )
                }
            }
            .sorted {
                $0.scheduledTime < $1.scheduledTime
            }
    }

    func doseCount(on date: Date) -> Int {
        scheduledDoses(on: date).count
    }

    func hasScheduledDoses(on date: Date) -> Bool {
        doseCount(on: date) > 0
    }

    var dueDose: ScheduledDose? {
        scheduledDoses.first {
            $0.status == .dueNow
        }
    }

    var missedDose: ScheduledDose? {
        scheduledDoses.first {
            $0.status == .missed
        }
    }

    var nextUpcomingDose: ScheduledDose? {
        scheduledDoses.first {
            $0.status == .upcoming
        }
    }

    /// Next dose the user still needs to act on.
    /// Priority: due now → missed (oldest first) → upcoming.
    var nextIncompleteDose: ScheduledDose? {
        if let dueDose {
            return dueDose
        }

        if let missedDose {
            return missedDose
        }

        return nextUpcomingDose
    }

    var dueMedication: Medication? {
        dueDose?.medication
    }

    /// True only when there is a schedule and every dose is taken.
    var allDosesTakenToday: Bool {
        totalCount > 0 && completedCount == totalCount
    }

    var missedCount: Int {
        scheduledDoses.filter {
            $0.status == .missed
        }.count
    }

    // MARK: - Completion totals

    var completedCount: Int {
        scheduledDoses.filter {
            $0.status == .taken
        }.count
    }

    var totalCount: Int {
        scheduledDoses.count
    }

    var remainingCount: Int {
        max(0, totalCount - completedCount)
    }

    var progress: Double {
        guard totalCount > 0 else {
            return 0
        }

        return Double(completedCount) / Double(totalCount)
    }

    // MARK: - Medication management

    /// Replaces the local medication list (used after a cloud download).
    func replaceAllMedications(with remote: [Medication]) {
        medications = remote.map { medication in
            var copy = medication
            copy.startDate = Calendar.current.startOfDay(for: copy.startDate)
            prepareDosesForToday(&copy)
            return copy
        }

        sortMedications()
        saveMedications()
        saveLastResetDate(Calendar.current.startOfDay(for: .now))

        for medication in medications {
            recordHistorySnapshot(for: medication, on: .now)
        }

        Task {
            for medication in medications {
                await NotificationManager.shared.scheduleNotifications(
                    for: medication
                )
            }
        }
    }

    func add(_ medication: Medication) {
        var medication = medication

        medication.startDate = Calendar.current.startOfDay(
            for: medication.startDate
        )

        prepareDosesForToday(&medication)

        medications.append(medication)

        sortMedications()
        saveMedications()

        // Capture today's schedule snapshot as soon as the medication is added.
        recordHistorySnapshot(for: medication, on: .now)

        Task {
            await NotificationManager.shared.scheduleNotifications(
                for: medication
            )
        }
    }

    func update(_ medication: Medication) {
        guard let index = medications.firstIndex(
            where: { $0.id == medication.id }
        ) else {
            return
        }

        let oldMedication = medications[index]

        var medication = medication

        medication.startDate = Calendar.current.startOfDay(
            for: medication.startDate
        )

        preserveTakenDoses(
            from: oldMedication,
            to: &medication
        )

        medications[index] = medication

        sortMedications()
        saveMedications()

        recordHistorySnapshot(for: medication, on: .now)

        Task {
            await NotificationManager.shared.removeNotifications(
                for: oldMedication
            )

            await NotificationManager.shared.scheduleNotifications(
                for: medication
            )
        }
    }

    func remove(_ medication: Medication) {
        // Snapshot today's schedule for this medication before deleting it.
        recordHistorySnapshot(
            for: medication,
            on: .now,
            markRemoved: true
        )

        medications.removeAll {
            $0.id == medication.id
        }

        saveMedications()

        Task {
            await NotificationManager.shared.removeNotifications(
                for: medication
            )
        }
    }

    // MARK: - Dose actions

    func markTaken(
        medicationID: UUID,
        doseNumber: Int
    ) {
        resetDosesIfNeeded()

        guard let index = medications.firstIndex(
            where: { $0.id == medicationID }
        ) else {
            return
        }

        medications[index].markDoseTaken(doseNumber)
        saveMedications()

        recordHistorySnapshot(
            for: medications[index],
            on: .now
        )
    }

    func markTaken(_ dose: ScheduledDose) {
        markTaken(
            medicationID: dose.medication.id,
            doseNumber: dose.doseNumber
        )
    }

    func markTaken(_ medication: Medication) {
        guard let dose = scheduledDoses.first(
            where: {
                $0.medication.id == medication.id &&
                (
                    $0.status == .dueNow ||
                    $0.status == .upcoming ||
                    $0.status == .missed
                )
            }
        ) else {
            return
        }

        markTaken(dose)
    }

    func markAllDosesAsNotTaken(_ medication: Medication) {
        resetDosesIfNeeded()

        guard let index = medications.firstIndex(
            where: { $0.id == medication.id }
        ) else {
            return
        }

        for doseIndex in medications[index].doses.indices {
            medications[index].doses[doseIndex].status = .upcoming
            medications[index].doses[doseIndex].snoozedUntil = nil
        }

        medications[index].status = .upcoming

        saveMedications()

        recordHistorySnapshot(
            for: medications[index],
            on: .now
        )
    }

    func updateDoseStatus(
        medicationID: UUID,
        doseNumber: Int,
        to status: Medication.Status
    ) {
        resetDosesIfNeeded()

        guard let index = medications.firstIndex(
            where: { $0.id == medicationID }
        ) else {
            return
        }

        medications[index].updateDoseStatus(
            doseNumber,
            to: status
        )

        saveMedications()

        recordHistorySnapshot(
            for: medications[index],
            on: .now
        )
    }

    func snooze(
        _ dose: ScheduledDose,
        minutes: Int = 10
    ) {
        resetDosesIfNeeded()

        guard let index = medications.firstIndex(
            where: { $0.id == dose.medication.id }
        ) else {
            return
        }

        let snoozeUntil = Date.now.addingTimeInterval(
            TimeInterval(minutes * 60)
        )

        medications[index].snoozeDose(
            dose.doseNumber,
            until: snoozeUntil
        )

        saveMedications()

        Task {
            await NotificationManager.shared.scheduleSnoozeNotification(
                for: medications[index],
                doseNumber: dose.doseNumber,
                at: snoozeUntil
            )
        }
    }

    func snooze(_ medication: Medication, minutes: Int = 10) {
        guard let dose = scheduledDoses.first(
            where: {
                $0.medication.id == medication.id &&
                (
                    $0.status == .dueNow ||
                    $0.status == .missed
                )
            }
        ) else {
            return
        }

        snooze(dose, minutes: minutes)
    }

    // MARK: - Midnight reset

    func resetDosesIfNeeded(now: Date = .now) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        guard let lastReset = loadLastResetDate() else {
            rebuildForNewDay(today)
            return
        }

        guard !calendar.isDate(
            lastReset,
            inSameDayAs: today
        ) else {
            // Keep today's history entry in sync with live schedule state.
            syncTodayHistoryIfNeeded(now: now)
            return
        }

        archiveHistoryThrough(
            endDayExclusive: today,
            lastTrackedDay: lastReset
        )
        rebuildForNewDay(today)
    }

    private func rebuildForNewDay(_ day: Date) {
        for index in medications.indices {
            prepareDosesForDay(
                &medications[index],
                day: day
            )
        }

        saveLastResetDate(day)
        saveMedications()

        Task {
            for medication in medications {
                await NotificationManager.shared.scheduleNotifications(
                    for: medication
                )
            }
        }
    }

    // MARK: - History recording

    /// Writes (or updates) a full schedule snapshot for one medication on a day.
    private func recordHistorySnapshot(
        for medication: Medication,
        on date: Date,
        markRemoved: Bool = false,
        finalizeMissed: Bool = false,
        now: Date = .now
    ) {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)

        guard medication.isActive(on: day) else {
            return
        }

        let doseCount = medication.dosesPerDay(on: day)
        guard doseCount > 0 else {
            return
        }

        let interval = medication.intervalHours(on: day)
        let isToday = calendar.isDate(day, inSameDayAs: now)

        let doses: [MedicationHistoryDose] = (0..<doseCount).map { index in
            let doseNumber = index + 1
            let scheduledTime = medication.doseTime(
                for: index,
                on: day,
                intervalHours: interval
            )

            let savedDose = medication.doses.first {
                $0.number == doseNumber
            }

            let status: Medication.Status

            if isToday && !finalizeMissed {
                status = resolvedStatus(
                    savedStatus: savedDose?.status ?? .upcoming,
                    scheduledTime: scheduledTime,
                    snoozedUntil: savedDose?.snoozedUntil,
                    now: now
                )
            } else if savedDose?.status == .taken {
                status = .taken
            } else if finalizeMissed || day < calendar.startOfDay(for: now) {
                status = scheduledTime <= now ? .missed : .upcoming
            } else {
                status = savedDose?.status ?? .upcoming
            }

            return MedicationHistoryDose(
                doseNumber: doseNumber,
                scheduledTime: scheduledTime,
                status: status,
                recordedAt: status == .taken ? now : nil
            )
        }

        let entry = MedicationHistoryEntry(
            medicationID: medication.id,
            day: day,
            name: medication.name,
            dosage: medication.dosage,
            form: medication.form,
            instructions: medication.instructions,
            doses: doses,
            wasRemovedFromSchedule: markRemoved
        )

        upsertHistoryEntry(entry)
    }

    /// Archives history for every day from `lastTrackedDay` up to (not including) `endDayExclusive`.
    private func archiveHistoryThrough(
        endDayExclusive: Date,
        lastTrackedDay: Date
    ) {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: lastTrackedDay)
        let end = calendar.startOfDay(for: endDayExclusive)

        while day < end {
            let isLastTrackedDay = calendar.isDate(
                day,
                inSameDayAs: lastTrackedDay
            )

            for medication in medications {
                // Live dose statuses only reflect the most recent tracked day.
                // Gap days are reconstructed from the schedule definition.
                if isLastTrackedDay {
                    recordHistorySnapshot(
                        for: medication,
                        on: day,
                        finalizeMissed: true
                    )
                } else {
                    recordHistorySnapshotFromScheduleOnly(
                        for: medication,
                        on: day
                    )
                }
            }

            guard let next = calendar.date(
                byAdding: .day,
                value: 1,
                to: day
            ) else {
                break
            }

            day = next
        }
    }

    /// Builds a history entry when we no longer have live dose statuses for that day.
    private func recordHistorySnapshotFromScheduleOnly(
        for medication: Medication,
        on date: Date
    ) {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)

        guard medication.isActive(on: day) else {
            return
        }

        let doseCount = medication.dosesPerDay(on: day)
        guard doseCount > 0 else {
            return
        }

        let interval = medication.intervalHours(on: day)
        let existing = historyEntries.first {
            $0.medicationID == medication.id &&
            calendar.isDate($0.day, inSameDayAs: day)
        }

        // Prefer any already-recorded taken statuses from that day.
        let doses: [MedicationHistoryDose] = (0..<doseCount).map { index in
            let doseNumber = index + 1
            let scheduledTime = medication.doseTime(
                for: index,
                on: day,
                intervalHours: interval
            )

            if let existingDose = existing?.doses.first(
                where: { $0.doseNumber == doseNumber }
            ), existingDose.status == .taken {
                return existingDose
            }

            return MedicationHistoryDose(
                doseNumber: doseNumber,
                scheduledTime: scheduledTime,
                status: .missed
            )
        }

        let entry = MedicationHistoryEntry(
            medicationID: medication.id,
            day: day,
            name: medication.name,
            dosage: medication.dosage,
            form: medication.form,
            instructions: medication.instructions,
            doses: doses
        )

        upsertHistoryEntry(entry)
    }

    private func syncTodayHistoryIfNeeded(now: Date = .now) {
        // Only create / refresh today's entries for medications that already
        // have history for today or have at least one taken dose.
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        for medication in medications {
            let hasTakenDose = medication.doses.contains {
                $0.status == .taken
            }

            let hasTodayEntry = historyEntries.contains {
                $0.medicationID == medication.id &&
                calendar.isDate($0.day, inSameDayAs: today)
            }

            if hasTakenDose || hasTodayEntry {
                recordHistorySnapshot(for: medication, on: today, now: now)
            }
        }
    }

    private func upsertHistoryEntry(_ entry: MedicationHistoryEntry) {
        if let index = historyEntries.firstIndex(
            where: { $0.storageKey == entry.storageKey }
        ) {
            var merged = entry
            // Keep the original entry id so SwiftUI identity stays stable.
            merged = MedicationHistoryEntry(
                id: historyEntries[index].id,
                medicationID: entry.medicationID,
                day: entry.day,
                name: entry.name,
                dosage: entry.dosage,
                form: entry.form,
                instructions: entry.instructions,
                doses: entry.doses,
                wasRemovedFromSchedule: entry.wasRemovedFromSchedule
                    || historyEntries[index].wasRemovedFromSchedule
            )
            historyEntries[index] = merged
        } else {
            historyEntries.append(entry)
        }

        historyEntries.sort {
            if $0.day != $1.day {
                return $0.day > $1.day
            }

            return $0.name.localizedCaseInsensitiveCompare($1.name)
                == .orderedAscending
        }

        saveHistory()
    }

    // MARK: - Dose building

    private func prepareDosesForToday(
        _ medication: inout Medication
    ) {
        prepareDosesForDay(
            &medication,
            day: Calendar.current.startOfDay(for: .now)
        )
    }

    private func prepareDosesForDay(
        _ medication: inout Medication,
        day: Date
    ) {
        let expectedCount = medication.dosesPerDay(on: day)

        medication.doses = (0..<expectedCount).map { index in
            Medication.Dose(
                number: index + 1,
                status: .upcoming
            )
        }

        medication.status = .upcoming
    }

    private func preserveTakenDoses(
        from oldMedication: Medication,
        to medication: inout Medication
    ) {
        let today = Calendar.current.startOfDay(for: .now)
        let expectedCount = medication.dosesPerDay(on: today)

        medication.doses = (0..<expectedCount).map { index in
            let doseNumber = index + 1

            let oldDose = oldMedication.doses.first {
                $0.number == doseNumber
            }

            return Medication.Dose(
                number: doseNumber,
                status: oldDose?.status ?? .upcoming,
                snoozedUntil: oldDose?.snoozedUntil
            )
        }

        medication.status = medication.doses.allSatisfy {
            $0.status == .taken
        } ? .taken : .upcoming
    }

    private func resolvedStatus(
        savedStatus: Medication.Status,
        scheduledTime: Date,
        snoozedUntil: Date?,
        now: Date = .now
    ) -> Medication.Status {
        if savedStatus == .taken {
            return .taken
        }

        // Active snooze keeps the dose upcoming until the snooze expires.
        if let snoozedUntil, snoozedUntil > now {
            return .upcoming
        }

        if scheduledTime > now {
            return .upcoming
        }

        let missedCutoff = scheduledTime.addingTimeInterval(
            TimeInterval(missedGraceMinutes * 60)
        )

        if now > missedCutoff {
            return .missed
        }

        return .dueNow
    }

    // MARK: - Persistence paths

    private var applicationFolderURL: URL? {
        do {
            let root = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

            let folder = root.appendingPathComponent(
                "OneLoop",
                isDirectory: true
            )

            try fileManager.createDirectory(
                at: folder,
                withIntermediateDirectories: true
            )

            return folder
        } catch {
            print(
                "Could not create storage folder: " +
                error.localizedDescription
            )

            return nil
        }
    }

    private var medicationsFileURL: URL? {
        applicationFolderURL?
            .appendingPathComponent(fileName)
    }

    private var historyFileURL: URL? {
        applicationFolderURL?
            .appendingPathComponent(historyFileName)
    }

    private var resetDateFileURL: URL? {
        applicationFolderURL?
            .appendingPathComponent(resetDateFileName)
    }

    // MARK: - Reset date

    private func loadLastResetDate() -> Date? {
        guard let url = resetDateFileURL,
              fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let text = try String(
                contentsOf: url,
                encoding: .utf8
            )

            return ISO8601DateFormatter().date(
                from: text.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            )
        } catch {
            return nil
        }
    }

    private func saveLastResetDate(_ date: Date) {
        guard let url = resetDateFileURL else {
            return
        }

        do {
            try ISO8601DateFormatter()
                .string(from: date)
                .write(
                    to: url,
                    atomically: true,
                    encoding: .utf8
                )
        } catch {
            print(
                "Could not save reset date: " +
                error.localizedDescription
            )
        }
    }

    // MARK: - Medication persistence

    private func loadMedications() {
        guard let url = medicationsFileURL else {
            return
        }

        guard fileManager.fileExists(
            atPath: url.path
        ) else {
            medications = []
            updateWidgetData()
            return
        }

        do {
            let data = try Data(contentsOf: url)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            medications = try decoder.decode(
                [Medication].self,
                from: data
            )

            sortMedications()
        } catch {
            print(
                "Could not load medications: " +
                error.localizedDescription
            )

            medications = []
        }

        updateWidgetData()
    }

    private func saveMedications() {
        guard let url = medicationsFileURL else {
            return
        }

        do {
            let encoder = JSONEncoder()

            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [
                .prettyPrinted,
                .sortedKeys
            ]

            let data = try encoder.encode(medications)

            try data.write(
                to: url,
                options: [.atomic]
            )
        } catch {
            print(
                "Could not save medications: " +
                error.localizedDescription
            )
        }

        updateWidgetData()
    }

    // MARK: - History persistence

    private func loadHistory() {
        guard let url = historyFileURL else {
            return
        }

        guard fileManager.fileExists(atPath: url.path) else {
            historyEntries = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            historyEntries = try decoder.decode(
                [MedicationHistoryEntry].self,
                from: data
            )
        } catch {
            print(
                "Could not load medication history: " +
                error.localizedDescription
            )
            historyEntries = []
        }
    }

    private func saveHistory() {
        guard let url = historyFileURL else {
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [
                .prettyPrinted,
                .sortedKeys
            ]

            let data = try encoder.encode(historyEntries)

            try data.write(
                to: url,
                options: [.atomic]
            )
        } catch {
            print(
                "Could not save medication history: " +
                error.localizedDescription
            )
        }
    }

    // MARK: - Widget

    private func updateWidgetData() {
        if let nextDose = nextIncompleteDose {
            WidgetDataStore.save(
                WidgetMedicationData(
                    medicationName: nextDose.medication.name,
                    dosage: nextDose.medication.dosage,
                    reminderTime: nextDose.scheduledTime,
                    completedCount: completedCount,
                    totalCount: totalCount,
                    allMedicationsTaken: false
                )
            )

            return
        }

        WidgetDataStore.save(
            WidgetMedicationData(
                medicationName: medications.isEmpty
                    ? "No medications"
                    : "All medications taken",
                dosage: medications.isEmpty
                    ? "Add a medication in OneLoop"
                    : "Great job for today",
                reminderTime: .now,
                completedCount: completedCount,
                totalCount: totalCount,
                allMedicationsTaken: !medications.isEmpty
            )
        )
    }

    private func sortMedications() {
        medications.sort {
            $0.firstDoseTime < $1.firstDoseTime
        }
    }
}
