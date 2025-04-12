import SwiftUI

struct ProfileContainerView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("hasRequestedPushPermission") private var hasRequestedPushPermission = false
    
    var body: some View {
        Group{
            if authViewModel.isAuthenticated {
                ProfileView()
                    .environmentObject(authViewModel)
                
            } else {
                //SignInView()
                SignInView()
                    .environmentObject(authViewModel)
            }
        }
        .task {
            await authViewModel.checkUsername()
        }
        
    }
}
