//
//  InfiniteBackground.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 2/17/25.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        // Header
                        VStack(spacing: 12) {
                            Text("Welcome to Dock UI")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Your Design Inspiration Hub")
                                .font(.title3)
                                .foregroundColor(.gray)
                            
                            VStack {
                                // Features Section
                                FeatureRow(
                                    icon: "heart.fill",
                                    title: "Like Designs",
                                    description: "Like your favorite designs, and view them from your profile."
                                )
                                
                                FeatureRow(
                                    icon: "person.fill",
                                    title: "Personalized Profile",
                                    description: "Create your profile to showcase your liked designs"
                                )
                            }
                            .padding(.top, 60)
                        }
                        Spacer()
                        
                        // Sign in with Apple button
                        VStack(spacing: 16) {
                            Text("Sign in to unlock all features")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            
                            SignInWithAppleButton { request in
                                request.requestedScopes = [.email, .fullName]
                            } onCompletion: { result in
                                Task {
                                    await authViewModel.handleSignInWithApple(result)
                                }
                            }
                            .signInWithAppleButtonStyle(
                                colorScheme == .dark ? .white : .black
                            )
                            .frame(height: 50)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authViewModel.errorMessage)
        }
    }
    
    // MARK: - Sign Up Function
    private func signUp() async {
        await authViewModel.signIn(email: email, password: password)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding()
        .cornerRadius(16)
    }
}
