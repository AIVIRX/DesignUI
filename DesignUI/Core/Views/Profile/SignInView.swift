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
            signInScreen
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authViewModel.errorMessage)
        }
    }

    private var signInScreen: some View {
        ZStack {
            signInBackground
            signInContent
        }
        .ignoresSafeArea(edges: .top)
    }

    private var signInBackground: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            signInGradientBackground
        }
    }

    private var signInContent: some View {
        VStack(spacing: 20) {
            appLogo
            signInTitle
            signInSubtitle
            appleSignInButton
        }
        .padding(42)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var appLogo: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 90)
    }

    private var signInTitle: some View {
        Text("Sign In")
            .font(.largeTitle)
            .bold()
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
    }

    private var signInSubtitle: some View {
        Text("Create your account to save favorites, sync across devices, and access exclusive features.")
            .foregroundStyle(.black.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    private var appleSignInButton: some View {
        SignInWithAppleButton { request in
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            Task {
                await authViewModel.handleSignInWithApple(result)
            }
        }
        .id(signInAppleButtonId)
        .signInWithAppleButtonStyle(.black)
        .onChange(of: colorScheme) { _, _ in
            signInAppleButtonId = UUID().uuidString
        }
        .frame(height: 50)
        .frame(maxWidth: 500)
        .cornerRadius(12)
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
