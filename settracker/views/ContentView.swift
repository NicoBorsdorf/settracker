import SwiftUI

struct ContentView: View {
    @StateObject var router = AppRouter()
    @StateObject var viewModel = AppViewModel()

    private var baseTabs: [AppTab] { [.home, .exercises, .account]}

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
            }
            .tint(.accentColor)
            .tabBarMinimizeBehavior(.onScrollDown)
            .onChange(of: router.selectedTab) { _, newTab in
                router.selectedTab = newTab
            }
        } else {
            TabView(selection: $router.selectedTab) {
                HomeView(viewModel: viewModel)
                    .tabItem {
                        Label {
                            Text("home")
                        } icon: {
                            Image("house")
                        }
                    }.tag(0)

                ExerciseLibraryView(viewModel: viewModel)
                    .tabItem {
                        Label {
                            Text("exercises")
                        } icon: {
                            Image("dumbell.fill")
                        }
                    }.tag(1)

                AccountView()
                    .tabItem {
                        Label {
                            Text("account")
                        } icon: {
                            Image("person.circle")
                        }
                    }.tag(2)
            }
        }
    }
}

#Preview {
    ContentView()
}
