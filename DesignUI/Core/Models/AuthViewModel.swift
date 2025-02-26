//
//  AuthViewModel.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 2/6/25.
//

import SwiftUI
import Foundation
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
    
    let supabase = SupabaseManager.shared.client
    
    init() {
        currentUser = supabase.auth.currentUser
        isAuthenticated = currentUser != nil
        if isAuthenticated {
            Task {
                await checkUsername()
            }
        }
    }
    
    func checkUsername() async {
        guard let userId = currentUser?.id else { return }
        do {
            let response = try await supabase
                .from("profiles")
                .select() // ✅ Only fetch needed fields
                .eq("id", value: userId)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            if let profile = try? decoder.decode(Profile.self, from: response.data) {
                print("Username found: \(profile)")
                
                await MainActor.run {
                    hasUsername = true
                    self.userProfile = profile
                    self.objectWillChange.send() // ✅ Force UI update
                }
            }
        } catch {
            print("Error checking username:", error)
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
            try await supabase.auth.signOut()
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
            try await supabase.auth.signOut()
            
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
                self.hasUsername = false
            }
        } catch {
            print("Error deleting account:", error)
        }
    }
}


