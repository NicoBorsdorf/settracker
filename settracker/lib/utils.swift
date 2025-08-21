//
//  utils.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import SwiftUI

func groupTrainingsByWeek(_ trainings: [Training]) -> [TrainingWeekGroup] {
    var grouped: [String: [Training]] = [:]

    for training in trainings {
        let weekStart = getWeekStart(training.date)
        let key = weekStart.description
        grouped[key, default: []].append(training)
    }

    return grouped.map { key, value in
        TrainingWeekGroup(
            weekStart: ISO8601DateFormatter().date(from: key) ?? Date(),
            trainings: value
        )
    }.sorted { $0.weekStart > $1.weekStart }
}

func getWeekStart(_ date: Date) -> Date {
    let calendar = Calendar.current
    let components = calendar.dateComponents(
        [.yearForWeekOfYear, .weekOfYear],
        from: date
    )
    return calendar.date(from: components) ?? date
}

func formatWeekRange(_ start: Date) -> String {
    let calendar = Calendar(identifier: .gregorian)
    let components = calendar.dateComponents(
        [.yearForWeekOfYear, .weekOfYear],
        from: start
    )
    return "\(String(localized: "week")) \(components.weekOfYear ?? 0) / \(components.yearForWeekOfYear ?? 0)"
}

func buildDefaultTrainingExercise(from exercise: Exercise) -> TrainingExercise {
    if exercise.category == Category.cardio {
        return TrainingExercise(
            exercise: exercise,
            category: exercise.category,
            duration: 20,
            trainingSets: []
        )
    } else {
        let defaultSets = [
            TrainingSet(reps: 10, weight: 0),
            TrainingSet(reps: 10, weight: 0),
            TrainingSet(reps: 10, weight: 0),
        ]
        return TrainingExercise(
            exercise: exercise,
            category: Category.push,
            duration: 0,
            trainingSets: defaultSets
        )
    }
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
