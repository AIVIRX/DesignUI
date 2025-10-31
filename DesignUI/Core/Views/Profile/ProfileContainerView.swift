import SwiftUI

struct ProfileContainerView: View {
    @StateObject private var authViewModel = AuthViewModel()    
    var body: some View {
        NavigationStack {
            if !authViewModel.isAuthResolved {
                ProgressView()
                    .progressViewStyle(.circular)
            } else if authViewModel.isAuthenticated {
                if authViewModel.hasUsername == false {
                    UsernameSetupView()
                        .environmentObject(authViewModel)
                } else {
                ProfileView()
                    .environmentObject(authViewModel)
                }
            } else {
                SignInView()
                    .environmentObject(authViewModel)
            }
        }
        // Reset the navigation stack when auth state flips so UI updates immediately
        .id(authViewModel.isAuthenticated ? "auth" : "guest")
    }
}
