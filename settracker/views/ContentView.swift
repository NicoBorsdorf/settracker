import SwiftUI

struct ContentView: View {
    @StateObject var router = AppRouter()
    @StateObject var viewModel = AppViewModel()

    private var baseTabs: [AppTab] {
        [.home, .exercises, .statistics, .account]
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            TabView(selection: $router.selectedTab) {
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
            .tabBarMinimizeBehavior(.onScrollDown)
            .onChange(of: router.selectedTab) { _, newTab in
                router.selectedTab = newTab
            }
        } else {
            TabView(selection: $router.selectedTab) {
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
        }
    }
}

#Preview {
    ContentView()
}
