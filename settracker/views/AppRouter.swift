//
//  AppRouter.swift
//  settracker
//
//  Created by Nico Borsdorf on 20.08.25.
//

import SwiftUI


@Observable
class AppRouter {
    var selectedTab: AppTab
    var presentedSheet: PresentedSheet?
    
    init(inititalTab: AppTab = .home) {
        self.selectedTab = inititalTab
    }
}

enum PresentedSheet: Equatable {
    case none
    case addExercise
}

enum AppTab: Int, CaseIterable {
    case home = 0
    case exercises = 1
    case account = 2
    
    var title: String {
        switch self {
        case .home: return "home"
        case .exercises: return "exercises"
        case .account: return "account"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .exercises: return "list.bullet"
        case .account: return "person.crop.circle"
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
        }
    }
}
