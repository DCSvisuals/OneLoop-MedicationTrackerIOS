//
//  ScheduleView.swift
//  OneLoop
//
//  Created by David Carranco on 2026-08-01.
//

import SwiftUI

struct ScheduleView: View {
    enum CalendarView: String, CaseIterable, Identifiable {
        case day = "Daily"
        case week = "Weekly"
        case month = "Monthly"
        case year = "Yearly"

        var id: String { rawValue }

        var calendarSymbol: String {
            switch self {
            case .day:
                return "clock"
            case .week:
                return "rectangle.3.group"
            case .month:
                return "calendar"
            case .year:
                return "calendar.badge.clock"
            }
        }
    }

    struct ScheduleItem: Identifiable {
        let medication: Medication
        let doseNumber: Int
        let time: Date
        let status: Medication.Status

        var id: String {
            "\(medication.id.uuidString)-\(doseNumber)-\(time.timeIntervalSince1970)"
        }
    }

    @Bindable var store: MedicationStore

    @State private var selectedView: CalendarView = .day
    @State private var selectedDate = Date()

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.softBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        pageHeader
                        viewPicker
                        calendarNavigation

                        Group {
                            switch selectedView {
                            case .day:
                                dailyView

                            case .week:
                                weeklyView

                            case .month:
                                monthlyView

                            case .year:
                                yearlyView
                            }
                        }
                        .id(selectedView)
                        .transition(
                            OLMotion.siblingTransition(incomingFrom: .trailing)
                        )

                        FloatingMenuScrollSpacer()
                    }
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

                Text("Schedule")
                    .font(AppTheme.pageTitle)
                    .foregroundStyle(AppTheme.navy)

                Text("Plan your doses with confidence.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedText)
            }

            Spacer()

            Image(systemName: "calendar")
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

    // MARK: - View picker

    private var viewPicker: some View {
        HStack(spacing: 5) {
            ForEach(CalendarView.allCases) { view in
                Button {
                    withAnimation(OLMotion.sibling) {
                        selectedView = view
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: view.calendarSymbol)
                            .font(.caption.weight(.bold))

                        Text(view.rawValue)
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(
                        selectedView == view
                            ? AppTheme.scheduleSelectionText
                            : AppTheme.mutedText
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        selectedView == view
                            ? AppTheme.lime
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            AppTheme.elevatedCard,
            in: RoundedRectangle(cornerRadius: 17)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 17)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    // MARK: - Date navigation

    private var calendarNavigation: some View {
        HStack {
            Button {
                moveDate(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.navy)
                    .frame(width: 42, height: 42)
                    .background(
                        AppTheme.cardBackground,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 3) {
                Text(headerTitle.uppercased())
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.navy)

                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedText)
            }

            Spacer()

            Button {
                moveDate(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.navy)
                    .frame(width: 42, height: 42)
                    .background(
                        AppTheme.cardBackground,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var headerTitle: String {
        switch selectedView {
        case .day:
            return selectedDate.formatted(
                .dateTime.month(.wide).year()
            )

        case .week:
            return "Week of " + selectedDate.formatted(
                .dateTime.month(.abbreviated).day()
            )

        case .month:
            return selectedDate.formatted(
                .dateTime.month(.wide).year()
            )

        case .year:
            return selectedDate.formatted(.dateTime.year())
        }
    }

    private var headerSubtitle: String {
        switch selectedView {
        case .day:
            return selectedDate.formatted(
                .dateTime.weekday(.wide).day()
            )

        case .week:
            return "\(weeklyDoseTotal) doses this week"

        case .month:
            return "\(scheduleItems.count) doses on selected day"

        case .year:
            return "Medication overview"
        }
    }

    // MARK: - Daily

    private var dailyView: some View {
        VStack(alignment: .leading, spacing: 18) {
            weekStrip

            HStack {
                Text("DOSE TIMELINE")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(AppTheme.mutedText)

                Spacer()

                Text("\(scheduleItems.count) DOSES")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.blue)
            }

            if scheduleItems.isEmpty {
                noMedicationsCard
            } else {
                VStack(spacing: 0) {
                    ForEach(
                        Array(scheduleItems.enumerated()),
                        id: \.element.id
                    ) { index, item in
                        timelineRow(
                            item,
                            isLast: index == scheduleItems.count - 1
                        )
                    }
                }
                .padding(.vertical, 4)
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
    }

    private var weekStrip: some View {
        HStack(spacing: 5) {
            ForEach(-3...3, id: \.self) { offset in
                let date = calendar.date(
                    byAdding: .day,
                    value: offset,
                    to: startOfDay
                ) ?? selectedDate

                Button {
                    selectedDate = date
                } label: {
                    VStack(spacing: 8) {
                        Text(
                            date.formatted(
                                .dateTime.weekday(.narrow)
                            )
                        )
                        .font(.caption.weight(.bold))

                        Text(date.formatted(.dateTime.day()))
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(
                        calendar.isDate(
                            date,
                            inSameDayAs: selectedDate
                        )
                            ? AppTheme.scheduleSelectionText
                            : AppTheme.mutedText
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        calendar.isDate(
                            date,
                            inSameDayAs: selectedDate
                        )
                            ? AppTheme.lime
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            AppTheme.elevatedCard,
            in: RoundedRectangle(cornerRadius: 19)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 19)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    private func timelineRow(
        _ item: ScheduleItem,
        isLast: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Text(
                item.time.formatted(
                    date: .omitted,
                    time: .shortened
                )
            )
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AppTheme.navy)
            .frame(width: 64, alignment: .leading)
            .padding(.top, 4)

            VStack(spacing: 0) {
                Circle()
                    .fill(statusColor(for: item.status))
                    .frame(width: 12, height: 12)
                    .overlay {
                        Circle()
                            .stroke(
                                statusColor(for: item.status)
                                    .opacity(0.22),
                                lineWidth: 6
                            )
                    }

                if !isLast {
                    Rectangle()
                        .fill(AppTheme.cardBorder)
                        .frame(width: 1)
                        .frame(maxHeight: .infinity)
                        .padding(.top, 7)
                }
            }
            .frame(minHeight: 72)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.medication.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.navy)

                Text(
                    "Dose \(item.doseNumber) • " +
                    item.medication.dosage
                )
                .font(.caption)
                .foregroundStyle(AppTheme.mutedText)

                Text(item.medication.instructions)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.mutedText.opacity(0.85))
            }

            Spacer(minLength: 0)

            Image(systemName: item.medication.iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(item.medication.form.tint)
                .frame(width: 38, height: 38)
                .background(
                    item.medication.form.tint.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 12)
                )
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 13)
    }

    // MARK: - Weekly timetable

    private var weeklyView: some View {
        let hours = Array(6...21)
        let hourHeight: CGFloat = 46
        let dayWidth: CGFloat = 78
        let headerHeight: CGFloat = 40
        let gridHeight = CGFloat(hours.count) * hourHeight

        return VStack(alignment: .leading, spacing: 12) {
            Text("WEEKLY TIMETABLE")
                .font(.caption.weight(.bold))
                .tracking(1)
                .foregroundStyle(AppTheme.mutedText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(width: 46, height: headerHeight)

                        ForEach(hours, id: \.self) { hour in
                            Text(String(format: "%02d:00", hour))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(AppTheme.mutedText)
                                .frame(
                                    width: 46,
                                    height: hourHeight,
                                    alignment: .topTrailing
                                )
                                .padding(.trailing, 6)
                        }
                    }

                    ForEach(0..<7, id: \.self) { offset in
                        let date = calendar.date(
                            byAdding: .day,
                            value: offset,
                            to: startOfWeek
                        ) ?? selectedDate

                        timetableDayColumn(
                            date: date,
                            hours: hours,
                            hourHeight: hourHeight,
                            dayWidth: dayWidth,
                            headerHeight: headerHeight,
                            gridHeight: gridHeight
                        )
                    }
                }
                .padding(.bottom, 8)
            }
            .padding(12)
            .background(
                AppTheme.cardBackground,
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            }
        }
    }

    private func timetableDayColumn(
        date: Date,
        hours: [Int],
        hourHeight: CGFloat,
        dayWidth: CGFloat,
        headerHeight: CGFloat,
        gridHeight: CGFloat
    ) -> some View {
        let isToday = calendar.isDateInToday(date)
        let firstHour = hours.first ?? 6
        let lastHour = hours.last ?? 21
        let items = store.scheduledDoses(on: date).filter { dose in
            let hour = calendar.component(.hour, from: dose.scheduledTime)
            return hour >= firstHour && hour <= lastHour
        }

        return VStack(spacing: 0) {
            VStack(spacing: 1) {
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(.caption2.weight(.bold))
                Text(date.formatted(.dateTime.day()))
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(isToday ? AppTheme.actionText : AppTheme.navy)
            .frame(width: dayWidth, height: headerHeight)
            .background(
                isToday ? AppTheme.blue : Color.clear,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(hours, id: \.self) { _ in
                        Rectangle()
                            .fill(AppTheme.cardBorder.opacity(0.7))
                            .frame(height: 1)
                            .frame(maxWidth: .infinity, maxHeight: hourHeight, alignment: .top)
                    }
                }

                ForEach(items) { dose in
                    let hour = calendar.component(.hour, from: dose.scheduledTime)
                    let minute = calendar.component(.minute, from: dose.scheduledTime)
                    let y = (
                        CGFloat(hour - firstHour)
                        + CGFloat(minute) / 60
                    ) * hourHeight

                    Button {
                        selectedDate = date
                        selectedView = .day
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dose.medication.name)
                                .font(.caption2.weight(.bold))
                                .lineLimit(1)
                            Text(
                                dose.scheduledTime.formatted(
                                    date: .omitted,
                                    time: .shortened
                                )
                            )
                            .font(.caption2)
                            .lineLimit(1)
                        }
                        .foregroundStyle(AppTheme.actionText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                        .frame(width: dayWidth - 8, alignment: .leading)
                        .background(
                            statusColor(for: dose.status),
                            in: RoundedRectangle(
                                cornerRadius: 8,
                                style: .continuous
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .offset(x: 4, y: max(0, y))
                    .accessibilityLabel(
                        "\(dose.medication.name) on " +
                        date.formatted(.dateTime.weekday(.wide)) +
                        " at " +
                        dose.scheduledTime.formatted(date: .omitted, time: .shortened)
                    )
                }
            }
            .frame(width: dayWidth, height: gridHeight, alignment: .top)
        }
    }

    // MARK: - Monthly

    private var monthlyView: some View {
        VStack(spacing: 14) {
            weekdayHeader
            monthGrid

            HStack(spacing: 8) {
                Circle()
                    .fill(AppTheme.lime)
                    .frame(width: 8, height: 8)

                Text("Selected day")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedText)

                Spacer()

                Circle()
                    .fill(AppTheme.blue)
                    .frame(width: 8, height: 8)

                Text("Scheduled doses")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedText)
            }
            .padding(.horizontal, 5)
        }
        .padding(17)
        .background(
            AppTheme.cardBackground,
            in: RoundedRectangle(cornerRadius: 24)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) {
                weekday in
                Text(String(weekday.prefix(1)))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.mutedText)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        let days = daysInMonthGrid

        return LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: 5),
                count: 7
            ),
            spacing: 8
        ) {
            ForEach(days.indices, id: \.self) { index in
                if let date = days[index] {
                    monthDayButton(date)
                } else {
                    Color.clear
                        .frame(height: 39)
                }
            }
        }
    }

    private func monthDayButton(_ date: Date) -> some View {
        let isSelected = calendar.isDate(
            date,
            inSameDayAs: selectedDate
        )

        let isToday = calendar.isDateInToday(date)

        return Button {
            selectedDate = date
            selectedView = .day
        } label: {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.day()))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(
                        isSelected
                            ? AppTheme.scheduleSelectionText
                            : AppTheme.navy
                    )

                Circle()
                    .fill(
                        hasScheduledDoses(on: date)
                            ? AppTheme.blue
                            : Color.clear
                    )
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                isSelected
                    ? AppTheme.lime
                    : (
                        isToday
                            ? AppTheme.blue.opacity(0.12)
                            : Color.clear
                    ),
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Yearly

    private var yearlyView: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(1...12, id: \.self) { month in
                let monthDate = dateForMonth(month)
                let monthDoseDays = doseDaysInMonth(monthDate)

                Button {
                    selectedDate = monthDate
                    selectedView = .month
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(monthName(for: month))
                            .font(.headline)
                            .foregroundStyle(AppTheme.navy)

                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { index in
                                Circle()
                                    .fill(
                                        index < min(monthDoseDays, 5)
                                            ? AppTheme.blue.opacity(0.75)
                                            : AppTheme.blue.opacity(0.18)
                                    )
                                    .frame(width: 5, height: 5)
                            }
                        }

                        Text(
                            monthDoseDays == 0
                                ? "No scheduled doses"
                                : "\(monthDoseDays) days with doses"
                        )
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(15)
                    .background(
                        AppTheme.cardBackground,
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                AppTheme.cardBorder,
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private var scheduleItems: [ScheduleItem] {
        store.scheduledDoses(on: selectedDate).map { dose in
            ScheduleItem(
                medication: dose.medication,
                doseNumber: dose.doseNumber,
                time: dose.scheduledTime,
                status: dose.status
            )
        }
    }

    private var weeklyDoseTotal: Int {
        (0..<7).reduce(0) { total, offset in
            let date = calendar.date(
                byAdding: .day,
                value: offset,
                to: startOfWeek
            ) ?? selectedDate

            return total + store.doseCount(on: date)
        }
    }

    private var startOfDay: Date {
        calendar.startOfDay(for: selectedDate)
    }

    private var startOfWeek: Date {
        calendar.date(
            from: calendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear],
                from: selectedDate
            )
        ) ?? selectedDate
    }

    private var daysInMonthGrid: [Date?] {
        guard
            let interval = calendar.dateInterval(
                of: .month,
                for: selectedDate
            ),
            let firstWeekday = calendar.dateComponents(
                [.weekday],
                from: interval.start
            ).weekday,
            let range = calendar.range(
                of: .day,
                in: .month,
                for: selectedDate
            )
        else {
            return []
        }

        let leadingEmptyDays = (
            firstWeekday - calendar.firstWeekday + 7
        ) % 7

        var days: [Date?] = Array(
            repeating: nil,
            count: leadingEmptyDays
        )

        for day in range {
            days.append(
                calendar.date(
                    byAdding: .day,
                    value: day - 1,
                    to: interval.start
                )
            )
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func hasScheduledDoses(on date: Date) -> Bool {
        store.hasScheduledDoses(on: date)
    }

    private func dateForMonth(_ month: Int) -> Date {
        var components = calendar.dateComponents(
            [.year],
            from: selectedDate
        )
        components.month = month
        components.day = 1
        return calendar.date(from: components) ?? selectedDate
    }

    private func doseDaysInMonth(_ monthDate: Date) -> Int {
        guard
            let interval = calendar.dateInterval(
                of: .month,
                for: monthDate
            ),
            let dayCount = calendar.range(
                of: .day,
                in: .month,
                for: monthDate
            )?.count
        else {
            return 0
        }

        var count = 0
        for offset in 0..<dayCount {
            guard let day = calendar.date(
                byAdding: .day,
                value: offset,
                to: interval.start
            ) else {
                continue
            }

            if store.hasScheduledDoses(on: day) {
                count += 1
            }
        }

        return count
    }

    private func moveDate(by direction: Int) {
        let component: Calendar.Component

        switch selectedView {
        case .day:
            component = .day
        case .week:
            component = .weekOfYear
        case .month:
            component = .month
        case .year:
            component = .year
        }

        selectedDate = calendar.date(
            byAdding: component,
            value: direction,
            to: selectedDate
        ) ?? selectedDate
    }

    private func monthName(for month: Int) -> String {
        calendar.monthSymbols[month - 1]
    }

    private func statusColor(for status: Medication.Status) -> Color {
        switch status {
        case .taken:
            return AppTheme.success
        case .dueNow, .missed:
            return AppTheme.warning
        case .upcoming:
            return AppTheme.blue
        }
    }

    private var noMedicationsCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 34))
                .foregroundStyle(AppTheme.blue)

            Text("No doses scheduled")
                .font(.headline)
                .foregroundStyle(AppTheme.navy)

            Text("Add medication to build your daily timeline.")
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
