import SwiftUI

struct ProfileContainerView: View {
    @StateObject private var authViewModel = AuthViewModel()    
    var body: some View {
        NavigationStack {
            if authViewModel.isAuthenticated {
                ProfileView()
                    .environmentObject(authViewModel)
            } else {
                SignInView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
