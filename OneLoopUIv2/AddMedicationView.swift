//
//  AddMedicationView.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import SwiftUI

struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss

    let store: MedicationStore

    @State private var medicationName = ""
    @State private var medicationForm: Medication.Form = .pill

    @State private var startDate = Date()

    @State private var dosesPerDay = 1
    @State private var doseAmount = 0.0
    @State private var doseUnit: Medication.DoseUnit = .mg

    @State private var firstDoseTime = Date()
    @State private var intervalHours = 24

    @State private var hasScheduleChange = false
    @State private var scheduleChangeAfterDays = 3
    @State private var dosesPerDayAfterChange = 2
    @State private var intervalHoursAfterChange = 12

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication details") {
                    TextField(
                        "Medication name",
                        text: $medicationName
                    )

                    Picker(
                        "Medication type",
                        selection: $medicationForm
                    ) {
                        ForEach(
                            Medication.Form.allCases,
                            id: \.self
                        ) { form in
                            Label(
                                form.rawValue,
                                systemImage: form.iconName
                            )
                            .tag(form)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    DatePicker(
                        "Start date",
                        selection: $startDate,
                        displayedComponents: .date
                    )

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
                }

                Section("Change daily schedule") {
                    Toggle(
                        "Change schedule after starting dose",
                        isOn: $hasScheduleChange
                    )

                    if hasScheduleChange {
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
                            "The new schedule begins at midnight " +
                            "after the starting period ends."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }

                Section("Dose amount") {
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

                Section("Reminder schedule") {
                    DatePicker(
                        "First dose reminder",
                        selection: $firstDoseTime,
                        displayedComponents: .hourAndMinute
                    )

                    if dosesPerDay > 1 {
                        Stepper(
                            "Starting schedule interval: " +
                            "\(intervalHours) hours",
                            value: $intervalHours,
                            in: 1...23
                        )
                    } else {
                        Text("Starting schedule: one dose each day")
                            .foregroundStyle(.secondary)
                    }

                    schedulePreview
                }

                Color.clear
                    .frame(height: 100)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.softBackground)
            .tint(AppTheme.blue)
            .navigationTitle("Add Medication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMedication()
                    }
                    .disabled(
                        medicationName
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty || doseAmount <= 0
                    )
                }
            }
        }
    }

    private var schedulePreview: some View {
        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            Text("Starting schedule reminder times")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(
                0..<dosesPerDay,
                id: \.self
            ) { doseNumber in
                let time = Calendar.current.date(
                    byAdding: .hour,
                    value: intervalHours * doseNumber,
                    to: firstDoseTime
                ) ?? firstDoseTime

                Text(
                    "Dose \(doseNumber + 1): " +
                    time.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                )
                .font(.caption)
            }

            if hasScheduleChange {
                Divider()
                    .padding(.vertical, 3)

                Text(
                    "After \(scheduleChangeAfterDays) " +
                    "\(scheduleChangeAfterDays == 1 ? "day" : "days"): " +
                    "\(dosesPerDayAfterChange) " +
                    "\(dosesPerDayAfterChange == 1 ? "dose" : "doses") per day"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)

                if dosesPerDayAfterChange > 1 {
                    Text(
                        "Interval: " +
                        "\(intervalHoursAfterChange) hours"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                ForEach(
                    0..<dosesPerDayAfterChange,
                    id: \.self
                ) { doseNumber in
                    let time = Calendar.current.date(
                        byAdding: .hour,
                        value:
                            intervalHoursAfterChange *
                            doseNumber,
                        to: firstDoseTime
                    ) ?? firstDoseTime

                    Text(
                        "Dose \(doseNumber + 1): " +
                        time.formatted(
                            date: .omitted,
                            time: .shortened
                        )
                    )
                    .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func saveMedication() {
        let medication = Medication(
            name: medicationName.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            startDate: startDate,
            dosesPerDay: dosesPerDay,
            doseAmount: doseAmount,
            doseUnit: doseUnit,
            firstDoseTime: firstDoseTime,
            intervalHours: intervalHours,
            form: medicationForm,
            hasScheduleChange: hasScheduleChange,
            scheduleChangeAfterDays: scheduleChangeAfterDays,
            dosesPerDayAfterChange: dosesPerDayAfterChange,
            intervalHoursAfterChange: intervalHoursAfterChange
        )

        store.add(medication)

        dismiss()
    }
}

#Preview {
    AddMedicationView(
        store: MedicationStore()
    )
}
