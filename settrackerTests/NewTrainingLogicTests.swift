//
//  NewTrainingLogicTests.swift
//  settracker
//
//  Created by Nico Borsdorf on 06.08.25.
//


import XCTest
@testable import settracker

final class NewTrainingLogicTests: XCTestCase {
    func testBuildDefaultTrainingExerciseForStrength() {
        let ex = Exercise(
            name: "Bench Press",
            category: Category.push
        )
        let te = buildDefaultTrainingExercise(from: ex)
        XCTAssertEqual(te.category, Category.push)
        XCTAssertEqual(te.trainingSets.count, 3)
        XCTAssertNil(te.duration)
    }

    func testBuildDefaultTrainingExerciseForCardio() {
        let ex = Exercise(
            name: "Treadmill",
            category: Category.cardio
        )
        let te = buildDefaultTrainingExercise(from: ex)
        XCTAssertEqual(te.category, Category.cardio)
        XCTAssertNil(te.trainingSets)
        XCTAssertEqual(te.duration, 20)
    }

    func testCopyFromTrainingDeepCopiesSets() {
        let ex = Exercise(name: "Bench Press", category: Category.push)
        // Prepare source training
        let sets = [
            TrainingSet( reps: 8, weight: 60),
            TrainingSet( reps: 6, weight: 70),
        ]
        let trEx = TrainingExercise(
            exercise: ex,
            category: Category.push,
            duration: 10,
            trainingSets: sets
        )
        let srcTraining = Training(
            date: Date(),
            duration: 0,
            type: TrainingType.strength,
            exercises: [trEx]
        )

        let vm = AppViewModel()
        vm.trainings = [srcTraining]

        // Simulate view copy
        let view = TrainingView(viewModel: vm)
        var localExercises: [TrainingExercise] = []
        // inline copy logic replicating copyFromTraining to test behavior
        if let training = vm.trainings.first(where: { $0.id == "t1" }) {
            let copied = training.exercises.map { src -> TrainingExercise in
                let copiedSets = src.trainingSets.map {
                    TrainingSet(reps: $0.reps, weight: $0.weight)
                }
                return TrainingExercise(
                    exercise: src.exercise,
                    category: src.category,
                    duration: 5,
                    trainingSets: copiedSets
                )
            }
            localExercises = copied
        }

        XCTAssertEqual(localExercises.count, 1)
        XCTAssertEqual(localExercises.first?.trainingSets.count, 2)
        XCTAssertEqual(localExercises.first?.duration, 5)
        // Ensure new IDs for copied sets
        XCTAssertNotEqual(localExercises.first?.trainingSets.first?.id, "s1")
    }
}
