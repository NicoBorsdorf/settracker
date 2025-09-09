//
//  AppRouter.swift
//  settracker
//
//  Created by Nico Borsdorf on 20.08.25.
//

import SwiftUI

class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab

    init(initialTab: AppTab = .home) {
        self.selectedTab = initialTab
    }
}

enum AppTab: Int, CaseIterable {
    case home = 0
    case statistics = 1
    case training = 2
    case account = 3

    var title: String {
        switch self {
        case .home: return "home"
        case .account: return "account"
        case .training: return ""
        case .statistics: return "statistics"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .statistics: return "chart.bar.fill"
        case .account: return "person.crop.circle"
        case .training: return ""
        }
    }
}

struct AppTabRootView: View {
    let tab: AppTab

    var body: some View {
        switch tab {
        case .home:
            HomeView().accessibilityLabel(Text(self.tab.title))
        case .statistics:
            StatisticsView().accessibilityLabel(Text(self.tab.title))
                .background(Color(.systemBackground))
        case .account:
            AccountView().accessibilityLabel(Text(self.tab.title))
        case .training:
            // only used in a new training case
            TrainingView(training: Training()).accessibilityLabel("training")
        }
    }
}
