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
    #if os(iOS)
    #endif
    var body: some View {
        NavigationStack {
            ZStack {
                #if os(macOS)
                // macOS modern sign-in layout
                FluidGradient(blobs: [.purple, Color(red: 0.11, green: 0.01, blue: 0.2), .blue],
                              speed: 0.5,
                                      blur: 0.75)
                          .ignoresSafeArea()
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .padding()
                        Text("Accounts")
                            .font(.system(size: 30, weight: .bold))
                        Text("Sign in to sync favorites and access exclusive features.")
                            .foregroundStyle(.secondary)
                    }
                    
                    SignInWithAppleButton { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        Task {
                            await authViewModel.handleSignInWithApple(result)
                        }
                    }
                    .id(signInAppleButtonId)
                    .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                    .onChange(of: colorScheme, { _, _ in
                        signInAppleButtonId = UUID().uuidString
                    })
                    .frame(height: 44)
                    .frame(maxWidth: 360)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding(32)
                .frame(maxWidth: 520)
                .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
                #else
                // iOS layout (match onboarding welcome style, no images)
                ZStack {
                    Color.white.ignoresSafeArea()
                    signInGradientBackground
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50)
                        
                        Text("Sign In")
                            .font(.largeTitle).bold()
                            .foregroundStyle(.white)
                        
                        Text("Create your account to save favorites, sync across devices, and access exclusive features.")
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Spacer()
                        
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
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                    }
                    .padding(42)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
                .ignoresSafeArea(edges: .top)
                #endif
            }
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authViewModel.errorMessage)
        }
    }
    
    #if os(iOS)
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
    #endif
}

#if os(iOS)
extension View {
    func blurOpacityEffect(_ show: Bool) -> some View {
        self
            .blur(radius: show ? 0 : 2)
            .opacity(show ? 1 : 0)
            .scaleEffect(show ? 1 : 0.9)
    }
}
#endif
