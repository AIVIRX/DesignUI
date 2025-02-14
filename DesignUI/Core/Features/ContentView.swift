struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "square.grid.2x2")
                }
            
            ProfileContainerView()
                .environmentObject(authViewModel)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
} 