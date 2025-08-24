//
//  Models.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import SwiftUI

struct Training: Identifiable {
    let id: String = UUID().uuidString
    var date: Date
    var duration: Int
    var type: TrainingType
    var exercises: [TrainingExercise]
}

struct Exercise: Identifiable, Hashable {
    let id: String = UUID().uuidString
    var name: String
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
    var exercise: Exercise
    var category: Category
    var duration: Int = 0
    var trainingSets: [TrainingSet] = []
}

struct TrainingWeekGroup {
    let weekStart: Date
    let trainings: [Training]
}


class AppViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var trainings: [Training] = []
    @Published var isLoading = false
    
    private let dataLoader = ExerciseDataLoader.shared
    
    init() {
        Task {
            await loadInitialData()
        }
    }
    
    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            exercises = []//try await dataLoader.loadExercisesFromiCloud()
        } catch {
            print("Failed to load exercises: \(error)")
            // Handle error appropriately
        }
    }
    
    func saveExercises() async {
        do {
            try await dataLoader.saveExercisesToiCloud(exercises)
        } catch {
            print("Failed to save exercises: \(error)")
        }
    }
}
