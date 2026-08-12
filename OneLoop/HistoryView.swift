//
//  HistoryView.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import SwiftUI

struct MedicationHistoryView: View {
    @Bindable var store: MedicationStore

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.softBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        pageHeader

                        if store.historyDayGroups.isEmpty {
                            emptyHistoryCard
                        } else {
                            ForEach(store.historyDayGroups) { group in
                                daySection(group)
                            }
                        }

                        FloatingMenuScrollSpacer()
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                store.resetDosesIfNeeded()
            }
        }
    }

    // MARK: - Header

    private var pageHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 7) {
                Text("ONELOOP")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.blue)

                Text("History")
                    .font(
                        .system(
                            size: 38,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(AppTheme.navy)

                Text(
                    "Saved schedule records, even after a medication is removed."
                )
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
            }

            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.blue)
                .frame(width: 48, height: 48)
                .background(
                    AppTheme.cardBackground,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Day sections

    private func daySection(
        _ group: MedicationHistoryDayGroup
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dayTitle(for: group.day))
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(AppTheme.mutedText)

            ForEach(group.entries) { entry in
                historyEntryCard(entry)
            }
        }
    }

    private func dayTitle(for day: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(day) {
            return "TODAY"
        }

        if calendar.isDateInYesterday(day) {
            return "YESTERDAY"
        }

        return day.formatted(
            .dateTime
                .weekday(.wide)
                .month(.abbreviated)
                .day()
                .year()
        )
        .uppercased()
    }

    // MARK: - Entry cards

    private func historyEntryCard(
        _ entry: MedicationHistoryEntry
    ) -> some View {
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: entry.iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(entry.form.tint)
                    .frame(width: 42, height: 42)
                    .background(
                        entry.form.tint.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 13)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.navy)

                    Text(
                        "\(entry.dosage) • " +
                        "\(entry.totalCount) " +
                        "\(entry.totalCount == 1 ? "dose" : "doses") scheduled"
                    )
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedText)

                    if entry.wasRemovedFromSchedule {
                        Text("Removed from schedule")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AppTheme.warning)
                    }
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.doses) { dose in
                    HStack(spacing: 10) {
                        Image(systemName: doseStatusIcon(dose.status))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(doseStatusColor(dose.status))
                            .frame(width: 16)

                        Text("Dose \(dose.doseNumber)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.navy)

                        Spacer()

                        Text(
                            dose.scheduledTime.formatted(
                                date: .omitted,
                                time: .shortened
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)

                        Text(dose.status.rawValue)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(doseStatusColor(dose.status))
                            .frame(width: 64, alignment: .trailing)
                    }
                }
            }

            Text(entry.instructions)
                .font(.caption)
                .foregroundStyle(AppTheme.mutedText)
        }
        .padding(17)
        .background(
            AppTheme.cardBackground,
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    private func doseStatusIcon(
        _ status: Medication.Status
    ) -> String {
        switch status {
        case .taken:
            return "checkmark.circle.fill"
        case .missed:
            return "exclamationmark.circle.fill"
        case .dueNow:
            return "bell.fill"
        case .upcoming:
            return "clock.fill"
        }
    }

    private func doseStatusColor(
        _ status: Medication.Status
    ) -> Color {
        switch status {
        case .taken:
            return AppTheme.success
        case .missed, .dueNow:
            return AppTheme.warning
        case .upcoming:
            return AppTheme.blue
        }
    }

    // MARK: - Empty state

    private var emptyHistoryCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 34))
                .foregroundStyle(AppTheme.blue)

            Text("No medication history yet")
                .font(.headline)
                .foregroundStyle(AppTheme.navy)

            Text(
                "When you add medications or log doses, " +
                "their schedule details are saved here — " +
                "even if you later remove them."
            )
            .font(.subheadline)
            .foregroundStyle(AppTheme.mutedText)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(
            AppTheme.cardBackground,
            in: RoundedRectangle(cornerRadius: 24)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }
}
