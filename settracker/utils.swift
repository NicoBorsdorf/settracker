//
//  utils.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import SwiftUI


func groupTrainingsByWeek(_ trainings: [Training]) -> [TrainingWeekGroup] {
    let grouped = Dictionary(grouping: trainings) { t in
        startOfWeek(for: t.date)
    }

    let groups = grouped.map { (weekStart, items) in
        TrainingWeekGroup(
            week: weekStart,
            weekString: formatWeekRange(weekStart),
            trainings: items.sorted { $0.date > $1.date }
        )
    }

    return groups.sorted { $0.week > $1.week }
}

func startOfWeek(for date: Date, calendar: Calendar = .current) -> Date {
    let cal = calendar
    let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    return cal.date(from: comps) ?? date
}

func formatWeekRange(_ start: Date) -> String {
    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents(
        [.yearForWeekOfYear, .weekOfYear],
        from: start
    )
    return "\(String(localized: "week")) \(components.weekOfYear ?? 0) / \(components.yearForWeekOfYear ?? 0)"
}

func groupExercisesByCategory(_ exercises: [Exercise]) -> [(
    category: Category, exercises: [Exercise]
)] {
    let categories = Category.allCases

    return categories.map { category in
        let filtered = exercises.filter { $0.category == category }
        return (category: category, exercises: filtered)
    }
}
