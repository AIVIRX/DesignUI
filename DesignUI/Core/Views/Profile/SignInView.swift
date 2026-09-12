//
//  InfiniteBackground.swift
//
//  Created by Maicol Cabreja on 2/17/25.
//

import SwiftUI
import AuthenticationServices

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
            signInBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 32)
                signInCard
                Spacer(minLength: 32)
            }
            .padding(.horizontal, 24)
        }
        .navigationTitle("Account")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var signInCard: some View {
        VStack(spacing: 0) {
            appLogo
                .padding(.bottom, 24)
            signInTitle
            signInSubtitle
                .padding(.top, 10)
            benefits
                .padding(.top, 28)
            appleSignInButton
                .padding(.top, 28)
            privacyNote
                .padding(.top, 16)
        }
        .padding(32)
        .frame(maxWidth: 420)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.separator.opacity(0.45), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.18 : 0.08), radius: 20, y: 8)
    }

    private var signInBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemGroupedBackground)
        #endif
    }

    private var appLogo: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 76, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }

    private var signInTitle: some View {
        Text("Sign in to Dock UI")
            .font(.title2.weight(.semibold))
            .multilineTextAlignment(.center)
    }

    private var signInSubtitle: some View {
        Text("Keep your work, preferences, and saved designs available wherever you use Dock UI.")
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            benefit("arrow.triangle.2.circlepath", "Sync your workspace across devices")
            benefit("bookmark", "Save designs and favorite components")
            benefit("lock", "Your session is stored securely on this device")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func benefit(_ symbol: String, _ title: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
            .symbolRenderingMode(.hierarchical)
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
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .onChange(of: colorScheme) { _, _ in
            signInAppleButtonId = UUID().uuidString
        }
        .frame(height: 50)
        .frame(maxWidth: 500)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var privacyNote: some View {
        Text("Dock UI uses Sign in with Apple. Your email address is never shared without your permission.")
            .font(.footnote)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}
