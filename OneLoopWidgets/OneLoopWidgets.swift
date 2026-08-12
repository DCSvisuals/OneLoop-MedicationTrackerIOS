//
//  OneLoopWidgets.swift
//  OneLoopWidgets
//
//  Created by David Carranco on 2026-08-02.
//

import WidgetKit
import SwiftUI

struct MedicationWidgetEntry: TimelineEntry {
    let date: Date
    let medication: WidgetMedicationData
}

struct MedicationWidgetProvider: TimelineProvider {
    func placeholder(
        in context: Context
    ) -> MedicationWidgetEntry {
        MedicationWidgetEntry(
            date: .now,
            medication: .empty
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (MedicationWidgetEntry) -> Void
    ) {
        let entry = MedicationWidgetEntry(
            date: .now,
            medication: WidgetDataStore.load()
        )

        completion(entry)
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (
            Timeline<MedicationWidgetEntry>
        ) -> Void
    ) {
        let entry = MedicationWidgetEntry(
            date: .now,
            medication: WidgetDataStore.load()
        )

        let refreshDate = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: .now
        ) ?? .now.addingTimeInterval(900)

        completion(
            Timeline(
                entries: [entry],
                policy: .after(refreshDate)
            )
        )
    }
}

struct OneLoopMedicationWidget: Widget {
    let kind = "OneLoopMedicationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: MedicationWidgetProvider()
        ) { entry in
            OneLoopWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Medication Progress")
        .description(
            "View your next medication and today's progress."
        )
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

#Preview(
    "Home Screen Small",
    as: .systemSmall
) {
    OneLoopMedicationWidget()
} timeline: {
    MedicationWidgetEntry(
        date: .now,
        medication: .empty
    )
}

#Preview(
    "Home Screen Medium",
    as: .systemMedium
) {
    OneLoopMedicationWidget()
} timeline: {
    MedicationWidgetEntry(
        date: .now,
        medication: .empty
    )
}

#Preview(
    "Lock Screen Circular",
    as: .accessoryCircular
) {
    OneLoopMedicationWidget()
} timeline: {
    MedicationWidgetEntry(
        date: .now,
        medication: .empty
    )
}

#Preview(
    "Lock Screen Rectangular",
    as: .accessoryRectangular
) {
    OneLoopMedicationWidget()
} timeline: {
    MedicationWidgetEntry(
        date: .now,
        medication: .empty
    )
}
