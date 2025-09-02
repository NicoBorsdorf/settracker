//
//  Models.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import Foundation
import SwiftData
import SwiftUI

enum Category: String, CaseIterable, Codable, Identifiable {
    case push, pull, legs, cardio
    var id: String { rawValue }
}

enum TrainingType: String, CaseIterable, Codable {
    case strength, mobility, cardio
    case none = ""
}

@Model
final class Exercise {
    @Attribute(.unique) var name: String
    var category: Category
    var isDefault: Bool = false

    init(name: String, category: Category, isDefault: Bool = false) {
        self.name = name
        self.category = category
        self.isDefault = isDefault
    }
}

@Model
final class TrainingExercise {
    var exercise: String
    var category: Category
    var duration: Int = 0  // in seconds
    var trainingSets: [TrainingSet] = []

    init(
        exercise: String,
        category: Category,
        duration: Int,
        trainingSets: [TrainingSet]
    ) {
        self.exercise = exercise
        self.category = category
        self.duration = duration
        self.trainingSets = trainingSets
    }
}

@Model
final class TrainingSet {
    var setId: Int
    var reps: Int
    var weight: Double

    init(setId: Int, reps: Int, weight: Double) {
        self.setId = setId
        self.reps = reps
        self.weight = weight
    }
}

@Model
final class Training {
    var date: Date
    var duration: Int = 0  // in seconds
    var type: TrainingType
    var exercises: [TrainingExercise]

    init(
        date: Date,
        duration: Int,
        type: TrainingType,
        exercises: [TrainingExercise]
    ) {
        self.date = date
        self.duration = duration
        self.type = type
        self.exercises = exercises
    }
}

struct TrainingWeekGroup {
    let week: Date
    let weekString: String
    let trainings: [Training]
}

// Derived data you want to cache (can be recomputed if missing)
struct StatisticsCache: Codable {
    var lastComputed: Date
    var avgTrainingsPerWeek: Double
    var typePercentages: [String: Double]  // e.g., ["strength": 60, ...]
    var splitPercentages: [String: Double]  // e.g., ["push": 40, ...]
}

enum AppTheme: String, Codable {
    case light, dark, system
}

// User preferences + persisted payload
@Model
final class AppSettings {
    var isCloudEnabled: Bool
    var theme: AppTheme

    init(isCloudEnabled: Bool = false, theme: AppTheme = .system) {
        self.isCloudEnabled = isCloudEnabled
        self.theme = theme
    }
}

final class AppStateFile {
    // Schema version for future migrations
    var schemaVersion: Int = 1
    var settings: AppSettings
    var userExercises: [Exercise]  // only user-created (isDefault == false)
    var trainings: [Training]
    var statistics: StatisticsCache?

    init(
        settings: AppSettings,
        userExercises: [Exercise],
        trainings: [Training],
        statistics: StatisticsCache? = nil
    ) {
        self.settings = settings
        self.userExercises = userExercises
        self.trainings = trainings
        self.statistics = statistics
    }
}

@MainActor
final class AppViewModel: ObservableObject {
    // Injected SwiftData context
    private let context: ModelContext

    // Exposed data for views
    @Published private(set) var exercises: [Exercise] = []
    @Published private(set) var trainings: [Training] = []
    @Published var settings: AppSettings

    init(context: ModelContext) {
        self.context = context
        do {
            if let s = try context.fetch(FetchDescriptor<AppSettings>()).first {
                self.settings = s
            } else {
                throw AppError.newError("Failed to load settings")
            }
        } catch {
            print("Failed to load AppSettings. Initializing with defaults.")
            self.settings = AppSettings()
        }

    }

    // MARK: Bootstrap / Queries

    func loadInitialData() async {
        await loadExercises()
        await loadTrainings()
    }

    func loadExercises(category: Category? = nil) async {
        var descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        if let cat = category {
            descriptor.predicate = #Predicate<Exercise> { $0.category == cat }
        }
        do {
            exercises = try context.fetch(descriptor)
        } catch {
            print("Fetch exercises failed: \(error)")
            exercises = []
        }
    }

    func loadTrainings(from start: Date? = nil, to end: Date? = nil) async {
        let sorts = [SortDescriptor(\Training.date, order: .reverse)]
        var descriptor = FetchDescriptor<Training>(sortBy: sorts)

        if let start, let end {
            descriptor.predicate = #Predicate<Training> { t in
                t.date >= start && t.date < end
            }
        }

        do {
            trainings = try context.fetch(descriptor)
        } catch {
            print("Fetch trainings failed: \(error)")
            trainings = []
        }
    }

    // MARK: Mutations (insert/update/delete)

    func addExercise(_ ex: Exercise) {
        context.insert(ex)
        saveContextAndRefreshExercises()
    }

    func renameExercise(_ exercise: Exercise, to newName: String) {
        exercise.name = newName
        saveContextAndRefreshExercises()
    }

    func deleteExercise(_ exercise: Exercise) {
        context.delete(exercise)
        saveContextAndRefreshExercises()
    }

    func addTraining(_ training: Training) {
        context.insert(training)
        saveContextAndRefreshTrainings()
    }

    func updateTraining(
        _ training: Training,
        type: TrainingType? = nil,
        date: Date? = nil
    ) {
        if let type = type { training.type = type }
        if let date = date { training.date = date }
        saveContextAndRefreshTrainings()
    }

    func deleteTraining(_ training: Training) {
        context.delete(training)
        saveContextAndRefreshTrainings()
    }

    // MARK: Save helpers

    private func saveContextAndRefreshExercises() {
        do {
            try context.save()
        } catch {
            print("Save error (exercises):", error)
        }
        Task { await loadExercises() }
    }

    private func saveContextAndRefreshTrainings() {
        do {
            try context.save()
        } catch {
            print("Save error (trainings):", error)
        }
        Task { await loadTrainings() }
    }

    // MARK: Statistics
    func computeStatistics() async -> StatisticsCache {
        return await Task.detached {
            return await self._computeStatistics()
        }.value
    }

    private func _computeStatistics() -> StatisticsCache {
        // Average per week
        let trainingsSorted = trainings.sorted { $0.date < $1.date }
        let avg: Double = {
            guard let first = trainingsSorted.first?.date,
                let last = trainingsSorted.last?.date,
                !trainingsSorted.isEmpty
            else { return 0 }
            let comps = Calendar.current.dateComponents(
                [.weekOfYear],
                from: first,
                to: last
            )
            let weeks = max(1, comps.weekOfYear ?? 1)
            return Double(trainingsSorted.count) / Double(weeks)
        }()

        // Type percentages
        let totalTrainings = Double(trainings.count)
        let typePct: [String: Double] =
            totalTrainings <= 0
            ? [:]
            : {
                let grouped = Dictionary(
                    grouping: trainings,
                    by: { $0.type.rawValue }
                )
                var dict: [String: Double] = [:]
                for (k, v) in grouped {
                    dict[k] = Double(v.count) / totalTrainings * 100.0
                }
                return dict
            }()

        // Split percentages (from exercises)
        let allExercises = trainings.flatMap { $0.exercises }
        let totalEx = Double(allExercises.count)
        let splitPct: [String: Double] =
            totalEx <= 0
            ? [:]
            : {
                let grouped = Dictionary(
                    grouping: allExercises,
                    by: { $0.category.rawValue }
                )
                var dict: [String: Double] = [:]
                for (k, v) in grouped {
                    dict[k] = Double(v.count) / totalEx * 100.0
                }
                return dict
            }()

        return StatisticsCache(
            lastComputed: Date(),
            avgTrainingsPerWeek: avg,
            typePercentages: typePct,
            splitPercentages: splitPct
        )
    }
}

enum AppError: LocalizedError {
    case dataCorruption
    case networkError
    case newError(String)

    var errorDescription: String? {
        switch self {
        case .dataCorruption:
            return "Data file appears to be corrupted"
        case .networkError:
            return "Unable to sync data"
        case .newError(let message):
            return message
        }
    }
}
