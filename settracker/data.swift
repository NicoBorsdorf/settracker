import Foundation
import SwiftData

class ExerciseDataLoader {
    static let shared = ExerciseDataLoader()
    private let fileManager = FileManager.default

    // Default exercises as fallback
    private let defaultExercises = [
        Exercise(name: "Bench Press", category: Category.push),
        Exercise(name: "Squat", category: Category.legs),
        Exercise(name: "Deadlift", category: Category.pull),
    ]

    func loadDataFromiCloud() async throws -> [Exercise] {
        // Try to load from iCloud first
        if let iCloudURL = getiCloudExercisesURL() {
            do {
                let data = try Data(contentsOf: iCloudURL)
                let exercises = [] as [Exercise]
                return exercises
            } catch {
                print(
                    "Failed to load from iCloud: \(error.localizedDescription)"
                )
            }
        }

        // Fallback to default exercises
        return defaultExercises
    }

    private func getiCloudExercisesURL() -> URL? {
        guard
            let iCloudURL = fileManager.url(forUbiquityContainerIdentifier: nil)
        else {
            print("iCloud not available")
            return nil
        }

        let documentsURL = iCloudURL.appendingPathComponent("Documents")
        let exercisesURL = documentsURL.appendingPathComponent("exercises.json")

        return exercisesURL
    }

    func saveExercisesToiCloud(_ exercises: [Exercise]) async throws {
        guard let iCloudURL = getiCloudExercisesURL() else {
            throw NSError(
                domain: "ExerciseData",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "iCloud not available"]
            )
        }

        //let data = try JSONEncoder().encode(exercises)
        //try data.write(to: iCloudURL)
    }
}
