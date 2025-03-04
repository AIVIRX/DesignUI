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
    @State private var signInAppleButtonId = UUID().uuidString
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        Spacer()
                        // Header
                        VStack(spacing: 12) {
                            Text("Welcome to Dock UI")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Your Design Inspiration Hub")
                                .font(.title3)
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                // Features Section (Wrapped in Card)
                                FeatureCard(
                                    icon: "heart.fill",
                                    title: "Like Designs",
                                    description: "Like your favorite designs, and view them from your profile."
                                )
                                
                                FeatureCard(
                                    icon: "person.fill",
                                    title: "Personalized Profile",
                                    description: "Create your profile to showcase your liked designs."
                                )
                            }
                            .padding(.top, 60)
                            .padding(.horizontal)
                            .frame(maxWidth: 500, alignment: .leading)
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
                            .id(signInAppleButtonId)
                                .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                                .onChange(of: colorScheme, { oldValue, newValue in
                                    signInAppleButtonId = UUID().uuidString
                                })
                            .frame(height: 50)
                            .frame(maxWidth: 500)
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

// MARK: - FeatureCard Component
    struct FeatureCard: View {
        var icon: String
        var title: String
        var description: String
        
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.indigo.opacity(0.15)) // Faint Indigo
                    .shadow(radius: 2)
                
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .foregroundColor(.indigo)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
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
