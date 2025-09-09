//
//  settrackerApp.swift
//  settracker
//
//  Created by Nico Borsdorf on 02.07.25.
//

import SwiftData
import SwiftUI

@main
struct settrackerApp: App {
    let container: ModelContainer
    let appViewModel: AppViewModel

    init() {
        do {
            container = try ModelContainer(
                for:
                Training.self,
                TrainingSet.self,
                TrainingExercise.self,
                AppSettings.self,
            )
            container.mainContext.autosaveEnabled = true
            appViewModel = AppViewModel(context: container.mainContext)
        } catch {
            fatalError("Failed to initialize container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environmentObject(appViewModel)
                .preferredColorScheme(
                    colorScheme(for: appViewModel.settings.theme)
                )
        }
    }

    private func colorScheme(for theme: AppTheme) -> ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
