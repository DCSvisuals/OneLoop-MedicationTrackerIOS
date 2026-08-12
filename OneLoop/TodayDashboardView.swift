//
//  TodayDashboardView.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import SwiftUI

struct TodayDashboardView: View {

    @Bindable var store: MedicationStore
    @Binding var showingAddMedication: Bool

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    headerSection
                    adherenceCard

                    if let dueDose = store.dueDose {
                        dueDoseCard(dueDose)
                    } else if let nextDose = store.nextIncompleteDose {
                        nextDoseCard(nextDose)
                    } else {
                        allDosesCompleteCard
                    }

                    scheduleSection

                    FloatingMenuScrollSpacer()
                }
                .padding()
            }
            .background(AppTheme.softBackground)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddMedication = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add medication")
                }
            }
        }
        .onAppear {
            store.resetDosesIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.resetDosesIfNeeded()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(
            alignment: .leading,
            spacing: 5
        ) {
            Text(greeting)
                .font(.title.bold())

            Text(
                Date.now.formatted(
                    date: .complete,
                    time: .omitted
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(
            .hour,
            from: .now
        )

        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Hello"
        }
    }

    // MARK: - Adherence

    private var adherenceCard: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(
                        Color.secondary.opacity(0.18),
                        lineWidth: 9
                    )

                Circle()
                    .trim(
                        from: 0,
                        to: store.progress
                    )
                    .stroke(
                        progressColor,
                        style: StrokeStyle(
                            lineWidth: 9,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .easeInOut,
                        value: store.progress
                    )

                Text(
                    store.progress.formatted(
                        .percent.precision(
                            .fractionLength(0)
                        )
                    )
                )
                .font(.headline)
            }
            .frame(width: 68, height: 68)
            .accessibilityLabel(
                "Today's adherence: " +
                "\(store.completedCount) of " +
                "\(store.totalCount) doses taken"
            )

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text("TODAY'S ADHERENCE")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Text(
                    "\(store.completedCount) of " +
                    "\(store.totalCount) doses taken"
                )
                .font(.headline)

                Text(adherenceMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(18)
        .background(
            AppTheme.cardBackground,
            in: RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    private var progressColor: Color {
        if store.totalCount == 0 {
            return .secondary
        }

        if store.progress >= 1 {
            return .green
        }

        if store.progress >= 0.5 {
            return .blue
        }

        return .orange
    }

    private var adherenceMessage: String {
        if store.totalCount == 0 {
            return "No medications scheduled today."
        }

        if store.progress >= 1 {
            return "All medications are logged for today."
        }

        if store.completedCount == 0 {
            return "Start today by logging your first dose."
        }

        return "\(store.remainingCount) dose" +
            (store.remainingCount == 1 ? "" : "s") +
            " remaining today."
    }

    // MARK: - Main dose cards

    private func dueDoseCard(
        _ scheduledDose: MedicationStore.ScheduledDose
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Label(
                "DOSE DUE NOW",
                systemImage: "bell.badge.fill"
            )
            .font(.caption.bold())
            .foregroundStyle(.orange)

            medicationHeader(scheduledDose)

            HStack(spacing: 12) {
                Button("Snooze 10 min") {
                    store.snooze(scheduledDose)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    store.markTaken(scheduledDose)
                } label: {
                    Label(
                        "Mark taken",
                        systemImage: "checkmark"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }

            NavigationLink {
                MedicationDetailView(
                    medication: scheduledDose.medication,
                    store: store
                )
            } label: {
                Label(
                    "View medication details",
                    systemImage: "info.circle"
                )
                .font(.footnote.weight(.semibold))
            }
        }
        .padding(18)
        .background(
            AppTheme.cardBackground,
            in: RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    private func nextDoseCard(
        _ scheduledDose: MedicationStore.ScheduledDose
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Label(
                "NEXT DOSE",
                systemImage: "clock.fill"
            )
            .font(.caption.bold())
            .foregroundStyle(.blue)

            medicationHeader(scheduledDose)

            Text(
                "Scheduled for " +
                scheduledDose.scheduledTime.formatted(
                    date: .omitted,
                    time: .shortened
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button {
                store.markTaken(scheduledDose)
            } label: {
                Label(
                    "Mark taken early",
                    systemImage: "checkmark"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            NavigationLink {
                MedicationDetailView(
                    medication: scheduledDose.medication,
                    store: store
                )
            } label: {
                Label(
                    "View medication details",
                    systemImage: "info.circle"
                )
                .font(.footnote.weight(.semibold))
            }
        }
        .padding(18)
        .background(
            AppTheme.cardBackground,
            in: RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    private var allDosesCompleteCard: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)

            Text("All done for today")
                .font(.title3.bold())

            Text(
                "You have logged all scheduled medications. " +
                "Your schedule will reset at midnight."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(18)
        .background(
            AppTheme.cardBackground,
            in: RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(AppTheme.success.opacity(0.35), lineWidth: 1)
        }
    }

    private func medicationHeader(
        _ scheduledDose: MedicationStore.ScheduledDose
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 14
        ) {
            Image(systemName: scheduledDose.medication.iconName)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    scheduledDose.medication.form.tint.gradient,
                    in: RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(scheduledDose.medication.name)
                    .font(.title3.bold())

                Text(scheduledDose.medication.dosage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(
                    "Dose \(scheduledDose.doseNumber) of " +
                    "\(scheduledDose.medication.dosesPerDay(on: .now))"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(
                scheduledDose.scheduledTime.formatted(
                    date: .omitted,
                    time: .shortened
                )
            )
            .font(.headline)
        }
    }

    // MARK: - Today's schedule

    private var scheduleSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("Today's schedule")
                .font(.title3.bold())

            if store.scheduledDoses.isEmpty {
                ContentUnavailableView(
                    "No medications scheduled",
                    systemImage: "pills",
                    description: Text(
                        "Add a medication to create " +
                        "your daily schedule."
                    )
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(store.scheduledDoses) { scheduledDose in
                        NavigationLink {
                            MedicationDetailView(
                                medication: scheduledDose.medication,
                                store: store
                            )
                        } label: {
                            scheduleRow(scheduledDose)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func scheduleRow(
        _ scheduledDose: MedicationStore.ScheduledDose
    ) -> some View {
        HStack(spacing: 14) {
            Image(
                systemName: statusIcon(
                    for: scheduledDose.status
                )
            )
            .font(.headline)
            .foregroundStyle(
                statusColor(
                    for: scheduledDose.status
                )
            )
            .frame(width: 28, height: 28)
            .background(
                statusColor(
                    for: scheduledDose.status
                )
                .opacity(0.12),
                in: Circle()
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(scheduledDose.medication.name)
                    .fontWeight(.semibold)

                Text(scheduledDose.medication.dosage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(
                alignment: .trailing,
                spacing: 3
            ) {
                Text(
                    scheduledDose.scheduledTime.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                )
                .font(.subheadline.weight(.semibold))

                Text(
                    statusText(
                        for: scheduledDose.status
                    )
                )
                .font(.caption)
                .foregroundStyle(
                    statusColor(
                        for: scheduledDose.status
                    )
                )
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(
            AppTheme.cardBackground,
            in: RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    // MARK: - Dose status display

    private func statusIcon(
        for status: Medication.Status
    ) -> String {
        switch status {
        case .taken:
            return "checkmark"

        case .dueNow:
            return "bell.fill"

        case .upcoming:
            return "clock.fill"

        case .missed:
            return "exclamationmark"
        }
    }

    private func statusColor(
        for status: Medication.Status
    ) -> Color {
        switch status {
        case .taken:
            return .green

        case .dueNow:
            return .orange

        case .upcoming:
            return .blue

        case .missed:
            return .red
        }
    }

    private func statusText(
        for status: Medication.Status
    ) -> String {
        switch status {
        case .taken:
            return "Taken"

        case .dueNow:
            return "Due now"

        case .upcoming:
            return "Upcoming"

        case .missed:
            return "Missed"
        }
    }
}
