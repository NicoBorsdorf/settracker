import Foundation

actor AppDataStore {
    static let shared = AppDataStore()

    private let fm = FileManager.default
    private let containerFolderName = "settracker"
    private let stateFileName = "state.bin"

    // Default app exercises (not persisted; only user-added are persisted)
    let defaultExercises: [Exercise] = [
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
            let appURL = iCloudDocs.appendingPathComponent(containerFolderName, isDirectory: true)
            try createFolderIfNeeded(at: appURL)
            return appURL
        }
        // Fallback to local
        let local = localDocumentsURL()
            .appendingPathComponent(containerFolderName, isDirectory: true)
        try createFolderIfNeeded(at: local)
        return local
    }

    private func createFolderIfNeeded(at url: URL) throws {
        var isDir: ObjCBool = false
        if !fm.fileExists(atPath: url.path, isDirectory: &isDir) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private func stateFileURL() throws -> URL {
        let folder = try ensureAppFolder()
        return folder.appendingPathComponent(stateFileName, isDirectory: false)
    }

    // MARK: Load/Save

    func load() async throws -> AppStateFile {
        let url = try stateFileURL()
        guard fm.fileExists(atPath: url.path) else {
            // First run → build initial state using defaults
            return AppStateFile(
                schemaVersion: 1,
                settings: AppSettings(),
                userExercises: [], // no user exercises yet
                trainings: [],
                statistics: nil
            )
        }

        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let state = try decoder.decode(AppStateFile.self, from: data)
        return state
    }

    func save(_ state: AppStateFile) async throws {
        let url = try stateFileURL()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(state)

        // Write JSON bytes into a single binary file atomically
        try jsonData.write(to: url, options: [.atomic])
    }
}
