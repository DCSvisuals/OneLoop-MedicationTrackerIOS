//
//  EditMedicationView.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import SwiftUI

struct EditMedicationView: View {
    @Environment(\.dismiss) private var dismiss

    let medication: Medication
    let store: MedicationStore

    @State private var dosesPerDay: Int
    @State private var doseAmount: Double
    @State private var doseUnit: Medication.DoseUnit
    @State private var firstDoseTime: Date
    @State private var intervalHours: Int

    @State private var hasScheduleChange: Bool
    @State private var scheduleChangeAfterDays: Int
    @State private var dosesPerDayAfterChange: Int
    @State private var intervalHoursAfterChange: Int


    init(
        medication: Medication,
        store: MedicationStore
    ) {
        self.medication = medication
        self.store = store

        _dosesPerDay = State(
            initialValue: medication.dosesPerDay
        )

        _doseAmount = State(
            initialValue: medication.doseAmount
        )

        _doseUnit = State(
            initialValue: medication.doseUnit
        )

        _firstDoseTime = State(
            initialValue: medication.firstDoseTime
        )

        _intervalHours = State(
            initialValue: medication.intervalHours
        )

        _hasScheduleChange = State(
            initialValue: medication.hasScheduleChange
        )

        _scheduleChangeAfterDays = State(
            initialValue: medication.scheduleChangeAfterDays
        )

        _dosesPerDayAfterChange = State(
            initialValue: medication.dosesPerDayAfterChange
        )
        
        _intervalHoursAfterChange = State(
            initialValue: medication.intervalHoursAfterChange
        )

    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dose instructions") {
                    Text(medication.name)
                        .font(.headline)

                    Stepper(
                        "Doses per day: \(dosesPerDay)",
                        value: $dosesPerDay,
                        in: 1...6
                    )
                    .onChange(of: dosesPerDay) {
                        intervalHours = max(
                            1,
                            24 / dosesPerDay
                        )
                    }

                    TextField(
                        "Amount per dose",
                        value: $doseAmount,
                        format: .number
                    )
                    .keyboardType(.decimalPad)

                    Picker(
                        "Unit",
                        selection: $doseUnit
                    ) {
                        ForEach(
                            Medication.DoseUnit.allCases,
                            id: \.self
                        ) { unit in
                            Text(unit.rawValue)
                                .tag(unit)
                        }
                    }
                }

                Section("Change daily schedule") {
                    Toggle(
                        "Change schedule after starting dose",
                        isOn: $hasScheduleChange
                    )

                    if hasScheduleChange {
                        Stepper(
                            "Starting schedule: " +
                            "\(dosesPerDay) " +
                            "\(dosesPerDay == 1 ? "dose" : "doses") per day",
                            value: $dosesPerDay,
                            in: 1...6
                        )
                        .onChange(of: dosesPerDay) {
                            intervalHours = max(
                                1,
                                24 / dosesPerDay
                            )
                        }

                        Stepper(
                            "Starting schedule duration: " +
                            "\(scheduleChangeAfterDays) " +
                            "\(scheduleChangeAfterDays == 1 ? "day" : "days")",
                            value: $scheduleChangeAfterDays,
                            in: 1...90
                        )

                        Stepper(
                            "New schedule: " +
                            "\(dosesPerDayAfterChange) " +
                            "\(dosesPerDayAfterChange == 1 ? "dose" : "doses") per day",
                            value: $dosesPerDayAfterChange,
                            in: 1...6
                        )
                        .onChange(of: dosesPerDayAfterChange) {
                            intervalHoursAfterChange = max(
                                1,
                                24 / dosesPerDayAfterChange
                            )
                        }

                        if dosesPerDayAfterChange > 1 {
                            Stepper(
                                "New schedule interval: " +
                                "\(intervalHoursAfterChange) hours",
                                value: $intervalHoursAfterChange,
                                in: 1...23
                            )
                        } else {
                            Text("New schedule: one dose each day")
                                .foregroundStyle(.secondary)
                        }

                        Text(
                            "The new schedule begins at midnight after " +
                            "the starting period ends."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }


                Section("Reminder schedule") {
                    DatePicker(
                        "First dose reminder",
                        selection: $firstDoseTime,
                        displayedComponents: .hourAndMinute
                    )

                    if dosesPerDay > 1 {
                        Stepper(
                            "Interval between doses: " +
                            "\(intervalHours) hours",
                            value: $intervalHours,
                            in: 1...23
                        )
                    } else {
                        Text("One reminder each day")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Preview") {
                    ForEach(
                        0..<dosesPerDay,
                        id: \.self
                    ) { doseNumber in
                        let doseTime = Calendar.current.date(
                            byAdding: .hour,
                            value: intervalHours * doseNumber,
                            to: firstDoseTime
                        ) ?? firstDoseTime

                        LabeledContent(
                            "Dose \(doseNumber + 1)",
                            value: doseTime.formatted(
                                date: .omitted,
                                time: .shortened
                            )
                        )
                    }

                    if hasScheduleChange {
                        Text(
                            "After \(scheduleChangeAfterDays) " +
                            "\(scheduleChangeAfterDays == 1 ? "day" : "days"), " +
                            "the app changes to \(dosesPerDayAfterChange) " +
                            "\(dosesPerDayAfterChange == 1 ? "dose" : "doses") " +
                            "per day."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }

                Color.clear
                    .frame(height: 110)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.softBackground)
            .tint(AppTheme.blue)
            .navigationTitle("Edit Doses")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(doseAmount <= 0)
                }
            }
        }
    }

    private func saveChanges() {
        var updatedMedication = medication

        updatedMedication.dosesPerDay = dosesPerDay
        updatedMedication.doseAmount = doseAmount
        updatedMedication.doseUnit = doseUnit
        updatedMedication.firstDoseTime = firstDoseTime
        updatedMedication.intervalHours = intervalHours

        updatedMedication.hasScheduleChange = hasScheduleChange
        updatedMedication.scheduleChangeAfterDays =
            scheduleChangeAfterDays
        updatedMedication.dosesPerDayAfterChange =
            dosesPerDayAfterChange
        updatedMedication.intervalHoursAfterChange =
            intervalHoursAfterChange


        store.update(updatedMedication)

        dismiss()
    }
}
