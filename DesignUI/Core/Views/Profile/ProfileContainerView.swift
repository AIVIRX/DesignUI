import SwiftUI

struct ProfileContainerView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("hasRequestedPushPermission") private var hasRequestedPushPermission = false
    
    var body: some View {
        NavigationStack {
            if authViewModel.isAuthenticated {
                if authViewModel.hasUsername {
                    ProfileView()
                        .environmentObject(authViewModel)
                } else {
                    UsernameSelectionView()
                        .environmentObject(authViewModel)
                }
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
