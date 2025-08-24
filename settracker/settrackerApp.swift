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
        }
    }
}
