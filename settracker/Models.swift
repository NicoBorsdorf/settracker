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
    case none = ""
    var id: String { rawValue }
}

enum TrainingType: String, CaseIterable, Codable {
    case strength, cardio
    case none = ""
}

@Model
final class TrainingExercise {
    var exercise: String
    var category: Category
    var duration: Int = 0  // in seconds
    var training: Training?

    @Relationship(
        deleteRule: .cascade,
        inverse: \TrainingSet.trainingExercise
    )
    var trainingSets = [TrainingSet]()

    init(
        exercise: String = "",
        category: Category = .none,
        duration: Int = 0,
        trainingSets: [TrainingSet] = [],
    ) {
        self.exercise = exercise
        self.category = category
        self.duration = duration
        self.trainingSets = trainingSets
    }
}

@Model
final class TrainingSet: Identifiable {
    var setId: Int
    var reps: Int
    var weight: Double
    var trainingExercise: TrainingExercise?

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

    @Relationship(
        deleteRule: .cascade,
        inverse: \TrainingExercise.training
    )
    var exercises = [TrainingExercise]()

    init(
        date: Date = Date(),
        duration: Int = 0,
        type: TrainingType = .none,
        exercises: [TrainingExercise] = []
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
    var timeExercises: Bool
    var timeTrainings: Bool

    init(
        isCloudEnabled: Bool = false,
        theme: AppTheme = .system,
        timeExercises: Bool = true,
        timeTrainings: Bool = true
    ) {
        self.isCloudEnabled = isCloudEnabled
        self.theme = theme
        self.timeExercises = timeExercises
        self.timeTrainings = timeTrainings
    }
}

final class AppStateFile {
    // Schema version for future migrations
    var schemaVersion: Int = 1
    var settings: AppSettings
    var trainings: [Training]
    var statistics: StatisticsCache?

    init(
        settings: AppSettings,
        trainings: [Training],
        statistics: StatisticsCache? = nil
    ) {
        self.settings = settings
        self.trainings = trainings
        self.statistics = statistics
    }
}

@MainActor
final class AppViewModel: ObservableObject {
    // Injected SwiftData context
    private let context: ModelContext

    // Exposed data for views
    @Published private(set) var trainings: [Training] = []
    @Published var settings: AppSettings = AppSettings()

    init(context: ModelContext) {
        self.context = context
        Task {
            await loadInitialData()
        }
    }

    // MARK: Bootstrap / Queries

    func loadInitialData() async {
        await loadTrainings()
        await loadSettings()
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

    func loadSettings() async {
        do {
            if let s = try context.fetch(FetchDescriptor<AppSettings>()).first {
                self.settings = s
            }
        } catch {
            print("Failed to load AppSettings. Initializing with defaults.")
            self.settings = AppSettings()
        }
    }

    // MARK: Mutations (insert/update/delete)

    // MARK: Training Handlers
    func addTraining(_ training: Training) {
        context.insert(training)
        saveContextAndRefreshTrainings()
    }

    func deleteTraining(_ training: Training) {
        context.delete(training)
        saveContextAndRefreshTrainings()
    }

    // MARK: Save helpers

    func saveContext() {
        Task {
            do {
                try context.save()
            } catch {
                print("Save error:", error)
            }
        }
    }

    private func saveContextAndRefreshTrainings() {
        saveContext()
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
