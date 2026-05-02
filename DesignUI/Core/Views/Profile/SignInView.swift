//
//  InfiniteBackground.swift
//
//  Created by Maicol Cabreja on 2/17/25.
//

import SwiftUI
import AuthenticationServices
import FluidGradient

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var signInAppleButtonId = UUID().uuidString
    
    var body: some View {
        NavigationStack {
            ZStack {
                ZStack {
                    Color.white.ignoresSafeArea()
                    signInGradientBackground
                    
                    VStack(spacing: 20) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90)
                        
                        Text("Sign In")
                            .font(.largeTitle).bold()
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.center)
                        
                        Text("Create your account to save favorites, sync across devices, and access exclusive features.")
                            .foregroundStyle(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                        
                        SignInWithAppleButton { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            Task {
                                await authViewModel.handleSignInWithApple(result)
                            }
                        }
                        .id(signInAppleButtonId)
                        .signInWithAppleButtonStyle(.black)
                        .onChange(of: colorScheme, { _, _ in
                            signInAppleButtonId = UUID().uuidString
                        })
                        .frame(height: 50)
                        .frame(maxWidth: 500)
                        .cornerRadius(12)
                    }
                    .padding(42)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authViewModel.errorMessage)
        }
    }
    
    private var signInGradientBackground: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.004, green: 0.373, blue: 1, opacity: 1), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 500
            )
            
            RadialGradient(
                colors: [Color(red: 0, green: 0.875, blue: 1, opacity: 1), .clear],
                center: .top,
                startRadius: 50,
                endRadius: 450
            )
            
            RadialGradient(
                colors: [Color(red: 0.004, green: 0.678, blue: 1, opacity: 1), .clear],
                center: .init(x: 0.5, y: -0.2),
                startRadius: 0,
                endRadius: 350
            )
        }
    }
}
