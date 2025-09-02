import Foundation
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @StateObject var router = AppRouter()

    private var baseTabs: [AppTab] {
        [.home, .exercises, .statistics, .account]
    }

    var body: some View {
        let tabView = TabView(selection: $router.selectedTab) {
            ForEach(baseTabs, id: \.self) { tab in
                Tab(value: tab) {
                    AppTabRootView(tab: tab)
                } label: {
                    Label {
                        Text(LocalizedStringKey(tab.title))
                    } icon: {
                        Image(systemName: tab.icon)
                    }
                }
            }
            Tab(value: AppTab.training, role: .search) {
                AppTabRootView(tab: .training)
            } label: {
                Label("Training", systemImage: "plus")
            }
        }
        .tint(.accentColor)
        .onChange(of: router.selectedTab) { _, newTab in
            router.selectedTab = newTab
        }

        if #available(iOS 26.0, *) {
            return
                tabView
                .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            return tabView
        }
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var context
    ContentView().environmentObject(
        AppViewModel(context: context)
    )
}
