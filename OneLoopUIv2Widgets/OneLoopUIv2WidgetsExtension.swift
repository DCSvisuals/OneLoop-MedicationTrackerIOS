//
//  OneLoopUIv2WidgetsExtension.swift
//  OneLoopUIv2
//
//  Created by David Carranco on 2026-08-02.
//

import SwiftUI
import WidgetKit

struct OneLoopUIv2WidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: MedicationWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallWidget

            case .systemMedium:
                mediumWidget

            case .accessoryCircular:
                circularWidget

            case .accessoryRectangular:
                rectangularWidget

            case .accessoryInline:
                inlineWidget

            default:
                smallWidget
            }
        }
        .containerBackground(for: .widget) {
            if family == .systemSmall || family == .systemMedium {
                Color.clear
                    .background(.fill.tertiary)
            } else {
                Color.clear
            }
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "cross.case.fill")
                    .foregroundStyle(Color(red: 0.12, green: 0.32, blue: 0.72))

                Spacer()

                Text(progressLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if entry.medication.allMedicationsTaken {
                Text("All done")
                    .font(.headline)
                    .lineLimit(2)

                Text(entry.medication.dosage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Text(entry.medication.medicationName)
                    .font(.headline)
                    .lineLimit(2)

                Text(entry.medication.dosage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Label {
                    Text(
                        entry.medication.reminderTime,
                        style: .time
                    )
                } icon: {
                    Image(systemName: "clock")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(Color(red: 0.12, green: 0.32, blue: 0.72))
            }
        }
    }

    private var mediumWidget: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    entry.medication.allMedicationsTaken
                        ? "Today's progress"
                        : "Next medication",
                    systemImage: "cross.case.fill"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0.12, green: 0.32, blue: 0.72))

                Text(entry.medication.medicationName)
                    .font(.title3.weight(.bold))
                    .lineLimit(1)

                Text(entry.medication.dosage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Spacer(minLength: 0)

                if !entry.medication.allMedicationsTaken {
                    Label {
                        Text(
                            entry.medication.reminderTime,
                            style: .time
                        )
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(
                            Color(red: 0.12, green: 0.32, blue: 0.72).opacity(0.22),
                            lineWidth: 10
                        )

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color(red: 0.12, green: 0.32, blue: 0.72),
                            style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(entry.medication.completedCount)")
                        .font(.title2.weight(.bold))
                }
                .frame(width: 76, height: 76)

                Text(progressLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var circularWidget: some View {
        Gauge(value: progress) {
            Image(systemName: "cross.case.fill")
        } currentValueLabel: {
            Text("\(entry.medication.completedCount)")
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var rectangularWidget: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(entry.medication.medicationName)
                .font(.headline)
                .lineLimit(1)

            Text(entry.medication.dosage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack {
                if !entry.medication.allMedicationsTaken {
                    Image(systemName: "clock")

                    Text(
                        entry.medication.reminderTime,
                        style: .time
                    )
                }

                Spacer()

                Text(progressLabel)
            }
            .font(.caption2)
        }
    }

    private var inlineWidget: some View {
        Text(inlineWidgetText)
    }

    private var inlineWidgetText: String {
        if entry.medication.allMedicationsTaken {
            return "OneLoop UIv2: all doses taken"
        }

        let reminderTime = entry.medication.reminderTime.formatted(
            date: .omitted,
            time: .shortened
        )

        return "\(entry.medication.medicationName): \(reminderTime)"
    }

    private var progress: Double {
        guard entry.medication.totalCount > 0 else {
            return 0
        }

        return Double(entry.medication.completedCount) /
            Double(entry.medication.totalCount)
    }

    private var progressLabel: String {
        "\(entry.medication.completedCount) of " +
        "\(entry.medication.totalCount)"
    }
}
