//
//  Medication.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import Foundation
import SwiftUI

struct Medication: Identifiable, Hashable, Codable {
    
    enum Status: String, Hashable, Codable {
        case dueNow = "Due now"
        case upcoming = "Upcoming"
        case taken = "Taken"
        case missed = "Missed"
    }
    
    enum DoseUnit: String, CaseIterable, Hashable, Codable {
        case mg = "mg"
        case grams = "g"
        case ml = "mL"
        case units = "units"
    }
    
    enum Form: String, CaseIterable, Hashable, Codable {
        case pill = "Pill"
        case injection = "Injection"
        case cream = "Ointment / cream"
        
        var iconName: String {
            switch self {
            case .pill:
                return "pills.fill"
                
            case .injection:
                return "syringe.fill"
                
            case .cream:
                return "tube.2.fill"
            }
        }
        
        var tint: Color {
            switch self {
            case .pill:
                return AppTheme.blue
                
            case .injection:
                return AppTheme.warning
                
            case .cream:
                return .purple
            }
        }
    }
    
    struct Dose: Identifiable, Hashable, Codable {
        let id: UUID
        let number: Int
        var status: Status
        /// When set, the dose stays upcoming until this time (used for snooze).
        var snoozedUntil: Date?

        init(
            id: UUID = UUID(),
            number: Int,
            status: Status = .upcoming,
            snoozedUntil: Date? = nil
        ) {
            self.id = id
            self.number = number
            self.status = status
            self.snoozedUntil = snoozedUntil
        }

        enum CodingKeys: String, CodingKey {
            case id
            case number
            case status
            case snoozedUntil
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            number = try container.decode(Int.self, forKey: .number)
            status = try container.decode(Status.self, forKey: .status)
            snoozedUntil = try container.decodeIfPresent(
                Date.self,
                forKey: .snoozedUntil
            )
        }
    }
    
    let id: UUID
    
    var name: String
    var startDate: Date
    var dosesPerDay: Int
    var doseAmount: Double
    var doseUnit: DoseUnit
    var firstDoseTime: Date
    var intervalHours: Int
    var form: Form
    
    var status: Status
    var doses: [Dose]
    
    // MARK: - Staged daily schedule
    
    /// Enables a one-time change to the number of scheduled doses per day.
    var hasScheduleChange: Bool
    
    /// The initial schedule applies on medication days 1 through this value.
    var scheduleChangeAfterDays: Int
    
    /// The number of daily doses from the following day onward.
    var dosesPerDayAfterChange: Int
    var intervalHoursAfterChange: Int
    
    
    var iconName: String {
        form.iconName
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date = .now,
        dosesPerDay: Int,
        doseAmount: Double,
        doseUnit: DoseUnit,
        firstDoseTime: Date,
        intervalHours: Int,
        form: Form = .pill,
        status: Status = .upcoming,
        doses: [Dose]? = nil,
        hasScheduleChange: Bool = false,
        scheduleChangeAfterDays: Int = 3,
        dosesPerDayAfterChange: Int = 2,
        intervalHoursAfterChange: Int = 12
        
    ) {
        self.id = id
        self.name = name
        self.startDate = Calendar.current.startOfDay(
            for: startDate
        )
        
        self.dosesPerDay = max(1, dosesPerDay)
        self.doseAmount = doseAmount
        self.doseUnit = doseUnit
        self.firstDoseTime = firstDoseTime
        self.intervalHours = intervalHours
        self.form = form
        self.status = status
        
        self.hasScheduleChange = hasScheduleChange
        self.scheduleChangeAfterDays = max(
            1,
            scheduleChangeAfterDays
        )
        
        self.dosesPerDayAfterChange = max(
            1,
            dosesPerDayAfterChange
        )
        
        
        
        self.intervalHoursAfterChange = max(
            1,
            intervalHoursAfterChange
        )
        
        
        if let doses,
           doses.count == max(1, dosesPerDay) {
            self.doses = doses
        } else {
            self.doses = (0..<max(1, dosesPerDay)).map { index in
                Dose(
                    number: index + 1,
                    status: status
                )
            }
        }
    }
    
    // MARK: - Backward-compatible persistence
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case startDate
        case dosesPerDay
        case doseAmount
        case doseUnit
        case firstDoseTime
        case intervalHours
        case form
        case status
        case doses
        
        case hasScheduleChange
        case scheduleChangeAfterDays
        case dosesPerDayAfterChange
        case intervalHoursAfterChange
        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )
        
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        startDate = Calendar.current.startOfDay(
            for: try container.decodeIfPresent(
                Date.self,
                forKey: .startDate
            ) ?? .now
        )
        
        dosesPerDay = max(
            1,
            try container.decode(Int.self, forKey: .dosesPerDay)
        )
        
        doseAmount = try container.decode(
            Double.self,
            forKey: .doseAmount
        )
        
        doseUnit = try container.decode(
            DoseUnit.self,
            forKey: .doseUnit
        )
        
        firstDoseTime = try container.decode(
            Date.self,
            forKey: .firstDoseTime
        )
        
        intervalHours = try container.decode(
            Int.self,
            forKey: .intervalHours
        )
        
        form = try container.decode(
            Form.self,
            forKey: .form
        )
        
        status = try container.decode(
            Status.self,
            forKey: .status
        )
        
        doses = try container.decode(
            [Dose].self,
            forKey: .doses
        )
        
        hasScheduleChange = try container.decodeIfPresent(
            Bool.self,
            forKey: .hasScheduleChange
        ) ?? false
        
        scheduleChangeAfterDays = max(
            1,
            try container.decodeIfPresent(
                Int.self,
                forKey: .scheduleChangeAfterDays
            ) ?? 3
        )
        
        dosesPerDayAfterChange = max(
            1,
            try container.decodeIfPresent(
                Int.self,
                forKey: .dosesPerDayAfterChange
            ) ?? dosesPerDay
        )
        
        intervalHoursAfterChange = max(
            1,
            try container.decodeIfPresent(
                Int.self,
                forKey: .intervalHoursAfterChange
            ) ?? max(
                1,
                24 / dosesPerDayAfterChange
            )
        )

    }


    // MARK: - Display

    var dosage: String {
        let formattedAmount = doseAmount.formatted(
            .number.precision(
                .fractionLength(
                    doseAmount.rounded() == doseAmount ? 0 : 1
                )
            )
        )

        return "\(formattedAmount) \(doseUnit.rawValue)"
    }

    var instructions: String {
        if hasScheduleChange {
            return "\(dosesPerDay) " +
                "\(dosesPerDay == 1 ? "dose" : "doses") daily " +
                "for \(scheduleChangeAfterDays) " +
                "\(scheduleChangeAfterDays == 1 ? "day" : "days"), " +
                "then \(dosesPerDayAfterChange) " +
                "\(dosesPerDayAfterChange == 1 ? "dose" : "doses") daily"
        }

        return "\(dosesPerDay) " +
            "\(dosesPerDay == 1 ? "dose" : "doses") per day • " +
            "Every \(intervalHours) hours"
    }

    var scheduledTime: Date {
        firstDoseTime
    }

    var completedDoseCount: Int {
        doses.filter {
            $0.status == .taken
        }.count
    }

    var isCompleteToday: Bool {
        completedDoseCount == doses.count
    }

    // MARK: - Staged schedule calculation

    /// Day 1 is the saved medication start date.
    func dayNumber(on date: Date) -> Int {
        let calendar = Calendar.current

        let firstDay = calendar.startOfDay(
            for: startDate
        )

        let currentDay = calendar.startOfDay(
            for: date
        )

        let elapsedDays = calendar.dateComponents(
            [.day],
            from: firstDay,
            to: currentDay
        ).day ?? 0

        return max(1, elapsedDays + 1)
    }

    /// Returns the number of scheduled doses for this medication on a day.
    func dosesPerDay(on date: Date) -> Int {
        guard hasScheduleChange else {
            return dosesPerDay
        }

        if dayNumber(on: date) > scheduleChangeAfterDays {
            return dosesPerDayAfterChange
        }

        return dosesPerDay
    }

    /// Whether this medication has started by the given day.
    func isActive(on date: Date) -> Bool {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        return day >= startDate
    }

    /// Original dose-time helper, based on the medication's first saved time.
    /// `doseNumber` is zero-based (0 = first dose).
    func doseTime(for doseNumber: Int) -> Date {
        doseTime(
            for: doseNumber,
            on: .now,
            intervalHours: intervalHours(on: .now)
        )
    }

    /// Dose time recreated for an exact calendar day.
    /// `doseNumber` is zero-based (0 = first dose).
    func doseTime(
        for doseNumber: Int,
        on day: Date,
        intervalHours: Int
    ) -> Date {
        let calendar = Calendar.current

        let dayParts = calendar.dateComponents(
            [.year, .month, .day],
            from: day
        )

        let timeParts = calendar.dateComponents(
            [.hour, .minute],
            from: firstDoseTime
        )

        let firstDoseOnDay = calendar.date(
            from: DateComponents(
                year: dayParts.year,
                month: dayParts.month,
                day: dayParts.day,
                hour: timeParts.hour,
                minute: timeParts.minute
            )
        ) ?? day

        return calendar.date(
            byAdding: .hour,
            value: intervalHours * doseNumber,
            to: firstDoseOnDay
        ) ?? firstDoseOnDay
    }

    func intervalHours(on date: Date) -> Int {
        guard hasScheduleChange else {
            return intervalHours
        }

        if dayNumber(on: date) > scheduleChangeAfterDays {
            return intervalHoursAfterChange
        }

        return intervalHours
    }

    /// Scheduled dose times for a specific calendar day.
    func scheduledTimes(on date: Date) -> [Date] {
        guard isActive(on: date) else {
            return []
        }

        let count = dosesPerDay(on: date)
        let interval = intervalHours(on: date)

        return (0..<count).map { index in
            doseTime(for: index, on: date, intervalHours: interval)
        }
    }


    // MARK: - Dose status

    func status(forDoseNumber doseNumber: Int) -> Status {
        doses.first {
            $0.number == doseNumber
        }?.status ?? .upcoming
    }

    mutating func markDoseTaken(_ doseNumber: Int) {
        guard let index = doses.firstIndex(
            where: { $0.number == doseNumber }
        ) else {
            return
        }

        doses[index].status = .taken
        doses[index].snoozedUntil = nil
        syncOverallStatus()
    }

    mutating func updateDoseStatus(
        _ doseNumber: Int,
        to newStatus: Status
    ) {
        guard let index = doses.firstIndex(
            where: { $0.number == doseNumber }
        ) else {
            return
        }

        doses[index].status = newStatus
        if newStatus == .taken {
            doses[index].snoozedUntil = nil
        }
        syncOverallStatus()
    }

    mutating func snoozeDose(
        _ doseNumber: Int,
        until date: Date
    ) {
        guard let index = doses.firstIndex(
            where: { $0.number == doseNumber }
        ) else {
            return
        }

        doses[index].status = .upcoming
        doses[index].snoozedUntil = date
        syncOverallStatus()
    }

    mutating func resetDosesForNewDay() {
        for index in doses.indices {
            doses[index].status = .upcoming
            doses[index].snoozedUntil = nil
        }

        status = .upcoming
    }

    private mutating func syncOverallStatus() {
        if doses.allSatisfy({ $0.status == .taken }) {
            status = .taken
            return
        }

        if doses.contains(where: { $0.status == .dueNow }) {
            status = .dueNow
            return
        }

        if doses.contains(where: { $0.status == .missed }) {
            status = .missed
            return
        }

        status = .upcoming
    }
}
