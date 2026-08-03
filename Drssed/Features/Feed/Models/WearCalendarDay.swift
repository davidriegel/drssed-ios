//
//  WearCalendarDay.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

import Foundation

/// One cell of the month grid. `date` is nil for the padding cells before the
/// first and after the last day of the month.
struct WearCalendarDay {
    let date: Date?
    let isToday: Bool
    let wears: [OutfitWear]

    var accessibilityLabel: String? {
        guard let date else { return nil }

        let day = date.formatted(date: .long, time: .omitted)

        guard wears.first != nil else {
            return "\(day), \(String(localized: "calendar.day.empty"))"
        }

        let names = wears.compactMap(\.outfitName).joined(separator: ", ")
        return names.isEmpty ? day : "\(day), \(names)"
    }

    /// Builds the grid of the month that contains `anchor`, filled with the given entries.
    static func month(for anchor: Date, wears: [OutfitWear], calendar: Calendar = .current) -> [WearCalendarDay] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: anchor)),
              let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        var wearsByDay: [Date: [OutfitWear]] = [:]
        for wear in wears {
            wearsByDay[calendar.startOfDay(for: wear.wornOn), default: []].append(wear)
        }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingPadding = (firstWeekday - calendar.firstWeekday + 7) % 7
        let today = calendar.startOfDay(for: Date())

        var days: [WearCalendarDay] = (0..<leadingPadding).map { _ in
            WearCalendarDay(date: nil, isToday: false, wears: [])
        }

        for day in dayRange {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            let dayStart = calendar.startOfDay(for: date)

            days.append(
                WearCalendarDay(
                    date: dayStart,
                    isToday: dayStart == today,
                    wears: (wearsByDay[dayStart] ?? []).sorted { $0.wornOn < $1.wornOn }
                )
            )
        }

        // Pad the last row so the grid keeps its shape.
        let trailingPadding = (7 - days.count % 7) % 7
        days += (0..<trailingPadding).map { _ in
            WearCalendarDay(date: nil, isToday: false, wears: [])
        }

        return days
    }
}
