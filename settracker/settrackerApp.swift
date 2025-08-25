//
//  settrackerApp.swift
//  settracker
//
//  Created by Nico Borsdorf on 02.07.25.
//

import SwiftUI
import SwiftData

@main
struct settrackerApp: App {
    let container: ModelContainer
    let appViewModel: AppViewModel
    var colorScheme: ColorScheme {
        let theme = appViewModel.settings.theme
        if theme == .system {
            return UIScreen.main.traitCollection.userInterfaceStyle == .dark ? .dark : .light
        }
        return theme == .dark ? .dark : .light
    }
    
    init() {
        do {
            container = try ModelContainer()
            appViewModel = AppViewModel()
        } catch {
            fatalError("Failed to initialize container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environmentObject(appViewModel)
                .preferredColorScheme(colorScheme(for: appViewModel.settings.theme))
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
