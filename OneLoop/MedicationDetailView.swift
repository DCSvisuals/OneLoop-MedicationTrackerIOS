//
//  MedicationDetailView.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import SwiftUI

struct MedicationDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let medication: Medication
    let store: MedicationStore

    @State private var showingEditDoses = false
    @State private var showingDeleteConfirmation = false

    private var currentMedication: Medication {
        store.medications.first {
            $0.id == medication.id
        } ?? medication
    }

    var body: some View {
        NavigationStack {
            List {
                medicationSection
                doseRemindersSection
                editSection
                removeSection

                FloatingMenuScrollSpacer()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .navigationTitle(currentMedication.name)
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditDoses) {
                EditMedicationView(
                    medication: currentMedication,
                    store: store
                )
            }
            .alert(
                "Remove \(currentMedication.name)?",
                isPresented: $showingDeleteConfirmation
            ) {
                Button(
                    "Remove Medication",
                    role: .destructive
                ) {
                    store.remove(currentMedication)
                    dismiss()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "This removes the medication and its reminder " +
                    "schedule from OneLoop."
                )
            }
        }
    }

    private var medicationSection: some View {
        Section("Medication") {
            LabeledContent(
                "Name",
                value: currentMedication.name
            )

            LabeledContent(
                "Dose",
                value: currentMedication.dosage
            )

            LabeledContent(
                "Daily schedule",
                value: currentMedication.instructions
            )

            LabeledContent(
                "Start date",
                value: currentMedication.startDate.formatted(
                    date: .abbreviated,
                    time: .omitted
                )
            )

            LabeledContent(
                "First reminder",
                value: currentMedication.firstDoseTime.formatted(
                    date: .omitted,
                    time: .shortened
                )
            )

            let todayInterval = currentMedication.intervalHours(
                on: .now
            )

            if currentMedication.dosesPerDay(on: .now) > 1 {
                LabeledContent(
                    "Dose interval",
                    value: "Every \(todayInterval) hours"
                )
            }
        }
    }

    private var doseRemindersSection: some View {
        Section("Dose reminders today") {
            let todayDoses = store.scheduledDoses.filter {
                $0.medication.id == currentMedication.id
            }

            if todayDoses.isEmpty {
                Text("No doses scheduled for today.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(todayDoses) { scheduledDose in
                    HStack(spacing: 12) {
                        Image(
                            systemName: scheduledDose.status == .taken
                                ? "checkmark.circle.fill"
                                : currentMedication.iconName
                        )
                        .foregroundStyle(
                            statusColor(for: scheduledDose.status)
                        )
                        .frame(width: 24)

                        VStack(
                            alignment: .leading,
                            spacing: 3
                        ) {
                            Text("Dose \(scheduledDose.doseNumber)")
                                .font(.body.weight(.medium))

                            Text(
                                scheduledDose.scheduledTime,
                                style: .time
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if scheduledDose.status == .taken {
                            Text("Taken")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.success)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(
                                    AppTheme.success.opacity(0.14),
                                    in: Capsule()
                                )
                        } else {
                            Button("Mark taken") {
                                store.markTaken(scheduledDose)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.lime)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    private var editSection: some View {
        Section {
            Button {
                showingEditDoses = true
            } label: {
                Label(
                    "Edit doses",
                    systemImage: "pencil"
                )
            }

            if currentMedication.doses.contains(
                where: { $0.status == .taken }
            ) {
                Button {
                    store.markAllDosesAsNotTaken(
                        currentMedication
                    )
                } label: {
                    Label(
                        "Undo taken doses",
                        systemImage: "arrow.uturn.backward"
                    )
                }
                .foregroundStyle(.orange)
            }
        } footer: {
            Text(
                AppInfo.medicalDisclaimerShort +
                " Update this medication only when following " +
                "instructions from your medical practitioner."
            )
        }
    }

    private var removeSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label(
                    "Remove Medication",
                    systemImage: "trash"
                )
            }
        }
    }

    private func statusColor(
        for status: Medication.Status
    ) -> Color {
        switch status {
        case .taken:
            return AppTheme.success

        case .dueNow, .missed:
            return AppTheme.warning

        case .upcoming:
            return AppTheme.blue
        }
    }
}
