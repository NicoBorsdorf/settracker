//
//  AppRouter.swift
//  settracker
//
//  Created by Nico Borsdorf on 20.08.25.
//

import SwiftUI

class AppRouter: ObservableObject {
    var selectedTab: AppTab
    
    init(initialTab: AppTab = .home) {
        self.selectedTab = initialTab
    }
}

enum AppTab: Int, CaseIterable {
    case home = 0
    case exercises = 1
    case account = 2
    case training = 3
    
    var title: String {
        switch self {
        case .home: return "home"
        case .exercises: return "exercises"
        case .account: return "account"
        case .training: return ""
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .exercises: return "dumbbell.fill"
        case .account: return "person.crop.circle"
            case .training: return ""
        }
    }
}


struct AppTabRootView: View {
    @StateObject var viewModel = AppViewModel()
    let tab: AppTab
    
    var body: some View {
        switch tab {
        case .home:
            HomeView(viewModel: viewModel)
        case .exercises:
            ExerciseLibraryView(viewModel: viewModel)
        case .account:
            AccountView()
        case .training:
            TrainingView(viewModel: viewModel)
        }
    }
}
