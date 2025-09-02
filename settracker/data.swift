import Foundation

actor AppDataStore {
    static let shared = AppDataStore()

    private let fm = FileManager.default
    private let containerFolderName = "settracker"
    private let stateFileName = "state.bin"

    // Default app exercises (not persisted; only user-added are persisted)
    static let defaultExercises: [Exercise] = [
        Exercise(name: "Bench Press", category: .push, isDefault: true),
        Exercise(name: "Squat", category: .legs, isDefault: true),
        Exercise(name: "Deadlift", category: .pull, isDefault: true),
    ]

    // MARK: Paths
    private func iCloudDocumentsURL() -> URL? {
        fm.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents", isDirectory: true)
    }

    private func localDocumentsURL() -> URL {
        fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func ensureAppFolder() throws -> URL {
        // Prefer iCloud folder if available
        if let iCloudDocs = iCloudDocumentsURL() {
            let appURL = iCloudDocs.appendingPathComponent(
                containerFolderName,
                isDirectory: true
            )
            try createFolderIfNeeded(at: appURL)
            return appURL
        }
        // Fallback to local
        let local = localDocumentsURL()
            .appendingPathComponent(containerFolderName, isDirectory: true)

        do {
            try createFolderIfNeeded(at: local)
            return local
        } catch {
            throw AppError.dataCorruption
        }
    }

    private func createFolderIfNeeded(at url: URL) throws {
        var isDir: ObjCBool = false
        if !fm.fileExists(atPath: url.path, isDirectory: &isDir) {
            print("Creating folder: \(url.path)")
            try fm.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    private func stateFileURL() throws -> URL {
        let folder = try ensureAppFolder()
        return folder.appendingPathComponent(stateFileName, isDirectory: false)
    }

}
