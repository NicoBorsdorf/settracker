import SwiftUI

struct ContentView: View {
    @Environment(AppRouter.self) var router
    let tabs: [AppTab] = AppTab.allCases
    @StateObject var viewModel = AppViewModel()

    var body: some View {
        @Bindable var router = router
        if #available(iOS 26.0, *){
            TabView(selection: $router.selectedTab) {
                ForEach(AppTab.allCases, id: \.self){ tab in
                    Tab(value: tab, role: .search){
                        AppTabRootView(tab: tab)
                    } label: {
                        Label(tab.title, systemImage: tab.icon)
                    }
                }
                    
            }
            .tint(.black)
            .tabBarMinimizeBehavior(.onScrollDown)
            .onChange(of: router.selectedTab){ oldTab, newTab in
                    withAnimation(.easeInOut) {
                        viewModel.selectedTab = newTab.rawValue
                    }
                
            }
        } else {
            EmptyView()
        }
    }
}

#Preview {
    ContentView()
}
