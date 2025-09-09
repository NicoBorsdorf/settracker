import Foundation

actor AppDataStore {
    static let shared = AppDataStore()

    private let fm = FileManager.default
    private let containerFolderName = "settracker"
    private let stateFileName = "state.bin"

    // Default app exercises (not persisted; only user-added are persisted)
    
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

enum MuscleGroup: String, CaseIterable, Identifiable, Codable {
    // Neck / traps
    case upperTraps = "Upper Traps"
    case midLowerTraps = "Mid/Lower Traps"
    case neck = "Neck"

    // Shoulders
    case frontDelts = "Front Delts"
    case sideDelts = "Side Delts"
    case rearDelts = "Rear Delts"

    // Chest
    case upperChest = "Upper Chest"
    case midLowerChest = "Mid/Lower Chest"

    // Back (lats + upper back)
    case lats = "Lats"
    case upperBack = "Upper Back"  // rhomboids/teres/infraspinatus area

    // Arms
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"

    // Core
    case abs = "Abs"
    case obliques = "Obliques"
    case lowerBack = "Lower Back"

    // Hips / glutes
    case glutes = "Glutes"
    case hipFlexors = "Hip Flexors"
    case adductors = "Adductors"
    case abductors = "Abductors"

    // Legs
    case quads = "Quads"
    case hamstrings = "Hamstrings"
    case calves = "Calves"
    case tibialis = "Tibialis"

    var id: String { rawValue }
}
