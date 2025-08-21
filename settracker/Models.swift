//
//  Models.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import SwiftUI

struct Training: Identifiable {
    let id: String = UUID().uuidString
    let date: Date
    let duration: Int
    let type: TrainingType
    var exercises: [TrainingExercise]
}

struct Exercise: Identifiable, Hashable {
    let id: String = UUID().uuidString
    let name: String
    let category: Category
}

enum Category: String, CaseIterable {
    case push
    case pull
    case legs
    case cardio
}

extension Category: Identifiable {
    var id: String { rawValue }
}

enum TrainingType: String, CaseIterable {
    case strength
    case mobility
    case cardio
}

struct TrainingSet: Identifiable, Hashable {
    let id: String = UUID().uuidString
    var reps: Int
    var weight: Double
}

struct TrainingExercise: Identifiable, Hashable {
    let id: String = UUID().uuidString
    var exercise: Exercise?
    var category: Category?
    var duration: Int = 0
    var trainingSets: [TrainingSet] = []
}

struct TrainingWeekGroup {
    let weekStart: Date
    let trainings: [Training]
}

var e: [Exercise] = [
    Exercise(
        name: "Push-ups",
        category: Category.push
    ),
    Exercise(
        name: "Bench Press",
        category: Category.push
    ),
    Exercise(
        name: "Pull-ups",
        category: Category.pull
    ),
    Exercise(
        name: "Overhead Press",
        category: Category.push
    ),
    Exercise(
        name: "Treadmill Running",
        category: Category.cardio
    ),
    Exercise(
        name: "Jump Rope",
        category: Category.cardio
    ),
]

class AppViewModel: ObservableObject {
    @Published var exercises = e

    @Published var trainings: [Training] = [
        Training(
            date: Date().addingTimeInterval(-86400),  // yesterday
            duration: 45,
            type: TrainingType.cardio,
            exercises: [
                TrainingExercise(
                    exercise: e[1],
                    category: Category.cardio,
                    duration: 30
                ),
                TrainingExercise(
                    exercise: e[2],
                    category: Category.cardio,
                    duration: 15
                ),
            ]
        ),
        Training(
            date: Date().addingTimeInterval(-172800),  // two days ago
            duration: 60,
            type: TrainingType.strength,
            exercises: [
                TrainingExercise(
                    exercise: e[0],
                    category: Category.push,
                    duration: 20
                ),
                TrainingExercise(
                    exercise: e[2],
                    category: Category.pull,
                    duration: 10,
                    ),
                TrainingExercise(
                    exercise: e[1],
                    category: Category.legs,
                    duration: 15
                ),
            ]
        ),
    ]
}
