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

                        if store.sortedHistoryEntries.isEmpty {
                            emptyHistoryCard
                        } else {
                            ForEach(store.sortedHistoryEntries) { entry in
                                historyEntryCard(entry)
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
                .olScrollTopFrost()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Header

    private var pageHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 7) {
                Text("ONELOOP")
                    .font(.caption.weight(.bold))
                    .tracking(1.6)
                    .foregroundStyle(AppTheme.teal)

                Text("History")
                    .font(AppTheme.pageTitle)
                    .foregroundStyle(AppTheme.navy)

                Text(
                    "Saved medication details — kept even after you remove them from your schedule."
                )
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
            }

            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppTheme.navy)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Entry cards

    private func historyEntryCard(
        _ entry: MedicationHistoryEntry
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
                        "\(entry.dosesPerDay) " +
                        "\(entry.dosesPerDay == 1 ? "dose" : "doses") / day"
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
                infoRow(
                    title: "Started",
                    value: entry.startDate.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
                infoRow(
                    title: "Interval",
                    value: "Every \(entry.intervalHours) hours"
                )
                infoRow(
                    title: "First dose",
                    value: entry.firstDoseTime.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                )

                if !entry.scheduledTimes.isEmpty {
                    infoRow(
                        title: "Times",
                        value: entry.scheduledTimes
                            .map {
                                $0.formatted(date: .omitted, time: .shortened)
                            }
                            .joined(separator: ", ")
                    )
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
        .opacity(entry.wasRemovedFromSchedule ? 0.85 : 1)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.mutedText)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(.caption)
                .foregroundStyle(AppTheme.navy)

            Spacer(minLength: 0)
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
                "When you add a medication, its details are saved here. " +
                "Removing it from your schedule keeps the History record."
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
