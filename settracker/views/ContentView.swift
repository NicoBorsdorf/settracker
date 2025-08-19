import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = AppViewModel()

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
                HomeView(viewModel: viewModel)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }.tag(0)
                
                ExerciseLibraryView(viewModel: viewModel)
                    .tabItem {
                        Label("Exercises", systemImage: "dumbbell.fill")
                    }.tag(1)
                
                AccountView()
                    .tabItem {
                        Label("Account", systemImage: "person.circle")
                    }.tag(2)
        }.background(.white)
    }
}

#Preview {
    ContentView()
}
