import SwiftUI

struct ProfileContainerView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                ProfileView()
                    .environmentObject(authViewModel)
                
            } else {
                SignInView()
                    .environmentObject(authViewModel)
            }
        }
        .task {
            await authViewModel.checkUsername()
        }
    }
}
