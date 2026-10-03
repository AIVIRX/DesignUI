import SwiftUI

struct ProfileContainerView: View {
    @StateObject private var authViewModel = AuthViewModel()    
    var body: some View {
        NavigationStack {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if !authViewModel.isAuthResolved {
            loadingView
        } else if authViewModel.isAuthenticated {
            authenticatedContent
        } else {
            signInContent
        }
    }

    private var loadingView: some View {
        ProgressView()
            .progressViewStyle(.circular)
    }

    @ViewBuilder
    private var authenticatedContent: some View {
        if authViewModel.hasUsername == false {
            usernameSetupContent
        } else {
            profileContent
        }
    }

    private var usernameSetupContent: some View {
        UsernameSetupView()
            .environmentObject(authViewModel)
    }

    private var profileContent: some View {
        ProfileView()
            .environmentObject(authViewModel)
    }

    private var signInContent: some View {
        SignInView()
            .environmentObject(authViewModel)
    }
}
