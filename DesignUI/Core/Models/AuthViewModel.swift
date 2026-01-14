//
//  AuthViewModel.swift
//  DockUI
//
//  Created by Maicol Cabreja on 2/6/25.
//

import SwiftUI
import AuthenticationServices
import Auth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var userProfile: Profile?
    @Published var hasUsername = false
    @Published var isAuthResolved = false
    @Published var isCheckingUsername = false
    
    let supabase = SupabaseManager.shared.client
    private var authChangeTask: Task<Void, Never>?
    
    init() {
        isLoading = true
        authChangeTask = Task {
            for await state in supabase.auth.authStateChanges {
                await MainActor.run {
                    if let user = state.session?.user {
                        self.currentUser = user
                        self.isAuthenticated = true
                        self.isCheckingUsername = true
                        Task {
                            await self.checkUsername()
                            await MainActor.run {
                                self.isCheckingUsername = false
                                // Mark auth as resolved after username check completes
                                if self.isAuthResolved == false {
                                    self.isAuthResolved = true
                                    self.isLoading = false
                                }
                            }
                        }
                    } else {
                        self.currentUser = nil
                        self.isAuthenticated = false
                        self.hasUsername = false
                        self.isCheckingUsername = false
                        // Mark auth as resolved immediately when not authenticated
                        if self.isAuthResolved == false {
                            self.isAuthResolved = true
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    deinit {
        authChangeTask?.cancel()
    }
    
    func checkUsername() async {
        guard let userId = currentUser?.id else { return }
        do {
            let response = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
            
            let decoder = JSONDecoder()
            let profiles = try decoder.decode([Profile].self, from: response.data)
            
            if let profile = profiles.first {
                let usernameValue = profile.username?.trimmingCharacters(in: .whitespacesAndNewlines)
                await MainActor.run {
                    self.userProfile = profile
                    self.hasUsername = (usernameValue?.isEmpty == false)
                    self.objectWillChange.send()
                }
            } else {
                // Profile doesn't exist yet - this is normal for new users
                await MainActor.run {
                    self.userProfile = nil
                    self.hasUsername = false
                    self.objectWillChange.send()
                }
            }
        } catch {
            // If profile doesn't exist, that's fine - user needs to set up username
            // Only log actual errors, not "not found" cases
            let errorString = String(describing: error)
            if !errorString.contains("No rows") && !errorString.contains("not found") && !errorString.contains("PGRST116") {
                print("Error checking username:", error)
            }
            await MainActor.run {
                self.userProfile = nil
                self.hasUsername = false
                self.objectWillChange.send()
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        
        do {
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            currentUser = response.user
            isAuthenticated = true
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String) async {
        isLoading = true
        
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            currentUser = response.user
            isAuthenticated = true
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let identityToken = appleIDCredential.identityToken,
               let token = String(data: identityToken, encoding: .utf8) {
                do {
                    let response = try await supabase.auth.signInWithIdToken(
                        credentials: .init(
                            provider: .apple,
                            idToken: token
                        )
                    )
                    currentUser = response.user
                    isAuthenticated = true
                } catch {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        case .failure(let error):
            showError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        
        do {
            try await supabase.auth.signOut(scope: .local)
            currentUser = nil
            isAuthenticated = false
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteAccount() async {        
        do {
            // Call the delete_user RPC function
            try await supabase.rpc("delete_user").execute()
            
            // Sign out the user locally
            try await supabase.auth.signOut(scope: .local)
            
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
                self.hasUsername = false
                self.objectWillChange.send()
            }
        } catch {
            print("Error deleting account:", error)
        }
    }
}
