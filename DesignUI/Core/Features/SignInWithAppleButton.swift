//
//  SignInWithAppleButton.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/15/24.
//

import SwiftUI
import AuthenticationServices

struct SignInWithAppleView: View {
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        SignInWithAppleButton { request in
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            Task {
                do {
                    switch result {
                    case .success(let auth):
                        guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                            throw AuthError.invalidCredential
                        }
                        
                        guard let idToken = credential.identityToken,
                              let token = String(data: idToken, encoding: .utf8) else {
                            throw AuthError.invalidToken
                        }
                        
                        // Sign in with Supabase using the Apple ID token
                        let authResponse = try await authManager.client.auth.signInWithIdToken(
                            credentials: .init(
                                provider: .apple,
                                idToken: token
                            )
                        )
                        
                        // Update user profile if this is a first-time sign in
                        if let fullName = credential.fullName,
                           let email = credential.email {
                            try await updateUserProfile(
                                userId: authResponse.user.id.uuidString, // Convert UUID to String
                                email: email,
                                firstName: fullName.givenName,
                                lastName: fullName.familyName
                            )
                        }
                        
                        await MainActor.run {
                            authManager.currentUser = authResponse.user
                            authManager.isAuthenticated = true
                        }
                        
                    case .failure(let error):
                        throw error
                    }
                } catch {
                    await MainActor.run {
                        showError = true
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 50)
        .cornerRadius(8)
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func updateUserProfile(userId: String, email: String, firstName: String?, lastName: String?) async throws {
        let fullName = [firstName, lastName].compactMap { $0 }.joined(separator: " ")
        let username = email.components(separatedBy: "@")[0].lowercased()
        
        try await authManager.client
            .from("profiles")
            .update([
                "email": email,
                "username": username,
                "full_name": fullName
            ])
            .eq("id", value: userId)
            .execute()
    }
}

// Custom errors for better error handling
enum AuthError: LocalizedError {
    case invalidCredential
    case invalidToken
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple ID credential"
        case .invalidToken:
            return "Invalid authentication token"
        }
    }
}

#Preview {
    SignInWithAppleView()
        .padding()
}
