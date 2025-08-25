//
//  Models.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import Foundation
import SwiftUI

enum Category: String, CaseIterable, Codable, Identifiable {
    case push, pull, legs, cardio
    var id: String { rawValue }
}

enum TrainingType: String, CaseIterable, Codable {
    case strength, mobility, cardio
}

struct Exercise: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var category: Category
    var isDefault: Bool = false
}

struct TrainingSet: Identifiable, Hashable, Codable {
    var id: Int
    var reps: Int
    var weight: Double
}

struct TrainingExercise: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    var exercise: String
    var category: Category
    var duration: Int = 0 // in seconds
    var trainingSets: [TrainingSet] = []
}

struct Training: Identifiable, Codable {
    var id: String = UUID().uuidString
    var date: Date
    var duration: Int = 0 // in seconds
    var type: TrainingType
    var exercises: [TrainingExercise]
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
    var typePercentages: [String: Double] // e.g., ["strength": 60, ...]
    var splitPercentages: [String: Double] // e.g., ["push": 40, ...]
}

enum AppTheme: String, Codable {
    case light, dark, system
}

// User preferences + persisted payload
struct AppSettings: Codable {
    var theme: AppTheme = .system
}

// Single persisted state file
struct AppStateFile: Codable {
    // Schema version for future migrations
    var schemaVersion: Int = 1
    var settings: AppSettings
    var userExercises: [Exercise]  // only user-created (isDefault == false)
    var trainings: [Training]
    var statistics: StatisticsCache?
}


@MainActor
final class AppViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var trainings: [Training] = []
    @Published var settings = AppSettings()
    @Published var statistics: StatisticsCache?
    @Published var isLoading = false

    private let store = AppDataStore.shared

    init() {
        Task { await loadInitialData() }
    }

    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let state = try await store.load()

            // Merge defaults with user exercises
            let user = state.userExercises
            let defaults = store.defaultExercises
            // If the user has edited default ones, you may need a strategy to reconcile.
            // For now we just append: defaults + user
            exercises = defaults + user
            trainings = state.trainings
            settings = state.settings
            statistics = state.statistics

            // If no trainings, you may want to prime statistics
            if statistics == nil {
                statistics = computeStatistics()
                try await persist()
            }
        } catch {
            print("Failed to load: \(error)")
            // fallback minimal state
            exercises = store.defaultExercises
            trainings = []
            settings = AppSettings()
            statistics = computeStatistics()
        }
    }

    func addExercise(name: String, category: Category) async {
        let ex = Exercise(name: name, category: category, isDefault: false)
        exercises.append(ex)
        await persistUserData()
    }

    func deleteExercise(id: String) async {
        // Prevent deletion of defaults by mistake
        exercises.removeAll { $0.id == id && $0.isDefault == false }
        await persistUserData()
    }

    func addTraining(_ t: Training) async {
        trainings.append(t)
        statistics = computeStatistics()
        await persistUserData()
    }

    func updateTraining(_ t: Training) async {
        if let idx = trainings.firstIndex(where: { $0.id == t.id }) {
            trainings[idx] = t
            statistics = computeStatistics()
            await persistUserData()
        }
    }

    func persist() async throws {
        // Persist whole state
        let state = AppStateFile(
            schemaVersion: 1,
            settings: settings,
            userExercises: exercises.filter { !$0.isDefault },
            trainings: trainings,
            statistics: statistics
        )
        try await store.save(state)
    }

    private func persistUserData() async {
        do {
            try await persist()
        } catch {
            print("Failed to save: \(error)")
        }
    }

    // MARK: Statistics
    func computeStatistics() -> StatisticsCache {
        // Average per week
        let trainingsSorted = trainings.sorted { $0.date < $1.date }
        let avg: Double = {
            guard let first = trainingsSorted.first?.date,
                  let last = trainingsSorted.last?.date,
                  !trainingsSorted.isEmpty else { return 0 }
            let comps = Calendar.current.dateComponents([.weekOfYear], from: first, to: last)
            let weeks = max(1, comps.weekOfYear ?? 1)
            return Double(trainingsSorted.count) / Double(weeks)
        }()

        // Type percentages
        let totalTrainings = Double(trainings.count)
        let typePct: [String: Double] = totalTrainings <= 0 ? [:] : {
            let grouped = Dictionary(grouping: trainings, by: { $0.type.rawValue })
            var dict: [String: Double] = [:]
            for (k, v) in grouped {
                dict[k] = Double(v.count) / totalTrainings * 100.0
            }
            return dict
        }()

        // Split percentages (from exercises)
        let allExercises = trainings.flatMap { $0.exercises }
        let totalEx = Double(allExercises.count)
        let splitPct: [String: Double] = totalEx <= 0 ? [:] : {
            let grouped = Dictionary(grouping: allExercises, by: { $0.category.rawValue })
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
