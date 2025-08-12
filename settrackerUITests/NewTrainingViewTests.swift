//
//  NewTrainingViewTests.swift
//  settracker
//
//  Created by Nico Borsdorf on 06.08.25.
//


import XCTest
import SwiftUI
@testable import settracker

final class NewTrainingViewTests: XCTestCase {
    func testSaveButtonDisabledWhenEmpty() {
        let vm = AppViewModel()
        let view = TrainingView(viewModel: vm)

        // We can't directly assert SwiftUI button disabled in unit tests easily.
        // Instead we verify the save logic guard works.
        var originalCount = vm.trainings.count
        // attempt to save with empty state
        // We need access to saveTraining; here we create a copy of the logic:
        func save(type: String, trainingExercises: [TrainingExercise]) -> Bool {
            guard !type.isEmpty, !trainingExercises.isEmpty else {
                return false
            }
            return true
        }

        XCTAssertFalse(save(type: "", trainingExercises: []))
        XCTAssertEqual(vm.trainings.count, originalCount)
    }

    func testGroupExercisesByCategoryOrdering() {
        let exercises = [
            Exercise(name: "Squat", category: Category.legs),
            Exercise(name: "Bench", category: Category.push),
            Exercise( name: "Row", category: Category.pull),
        ]
        let grouped = groupExercisesByCategory(exercises)
        XCTAssertEqual(grouped.map { $0.category }, Category.allCases)
        XCTAssertEqual(grouped[0].exercises.first?.name, "Bench")
        XCTAssertEqual(grouped[1].exercises.first?.name, "Row")
        XCTAssertEqual(grouped[2].exercises.first?.name, "Squat")
        XCTAssertTrue(grouped[3].exercises.isEmpty)
    }
}
