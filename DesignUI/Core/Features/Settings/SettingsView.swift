//
//  SettingsView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//
//  SettingsView.swift
//  DesignUI

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import CryptoKit
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var userStore: UserStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    @State private var showSignOutAlert: Bool = false
    @State private var showDeleteAccountAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var nonce: String?
    @State private var authorizationDelegate = AuthorizationControllerDelegate()

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Review")) {
                    Button {
                        requestReview()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.yellow)
                                .background(Color.indigo)
                                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 5, height: 5)))
                            Text("Rate Us")
                        }
                    }
                }

                Section(header: Text("Our Apps")) {
                    Link(destination: URL(string: "https://apps.apple.com/af/app/tasknow-simple-to-do-list/id1639588217")!) {
                        HStack {
                            Image("CryptoProfitLogo")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .cornerRadius(5)
                            Text("Crypto Profit Loss Calculator")
                        }
                    }

                    Link(destination: URL(string: "https://apps.apple.com/us/app/tasknow-simple-to-do-list/id1639588217")!) {
                        HStack {
                            Image("TaskNowLogo")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .cornerRadius(10)
                            Text("TaskNow - Simple To Do List")
                        }
                    }
                }

                Section("Privacy & Support") {
                    Link(destination: URL(string: "https://www.aivirx.com/crypto-profit-loss-calculator/privacy-policy")!) {
                        Text("Privacy Policy")
                    }
                    Link(destination: URL(string: "https://www.aivirx.com/contact")!) {
                        Text("Contact Us")
                    }
                }

                Section("Account") {
                    Button(action: {
                        showSignOutAlert = true
                    }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .alert(isPresented: $showSignOutAlert) {
                        Alert(
                            title: Text("Sign Out"),
                            message: Text("Are you sure you want to sign out from your account?"),
                            primaryButton: .destructive(
                                Text("Sign Out"),
                                action: signOutUser
                            ),
                            secondaryButton: .cancel()
                        )
                    }

                    Button(role: .destructive, action: {
                        showDeleteAccountAlert = true
                    }) {
                        Label("Delete Account", systemImage: "trash")
                            .foregroundStyle(Color.red)
                    }
                    .alert(isPresented: $showDeleteAccountAlert) {
                        Alert(
                            title: Text("Delete Account"),
                            message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                            primaryButton: .destructive(Text("Delete")) {
                                deleteCurrentUser()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
            .accentColor(colorScheme == .dark ? .white : .black)
            .navigationBarTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func signOutUser() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            userStore.signOut()
        } catch let signOutError as NSError {
            showError(signOutError.localizedDescription)
        }
    }

    private func deleteCurrentUser() {
        let nonce = randomNonceString()
        self.nonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = authorizationDelegate
        authorizationDelegate.onCompletion = { result in
            switch result {
            case .success(let authorization):
                self.handleAppleSignIn(authorization)
            case .failure(let error):
                self.showError(error.localizedDescription)
            }
        }
        authorizationDelegate.presentationAnchorProvider = {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return windowScene.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
            }
            return ASPresentationAnchor()
        }
        authorizationController.performRequests()
    }

    func handleAppleSignIn(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            showError("Unable to retrieve AppleIDCredential")
            return
        }

        guard let nonce = nonce else {
            fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }

        guard let appleIDToken = appleIDCredential.identityToken else {
            showError("Unable to fetch identity token")
            return
        }

        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            showError("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
            return
        }

        // Initialize a fresh Apple credential with Firebase.
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )

        // Reauthenticate current Apple user with fresh Apple credential.
        Auth.auth().currentUser?.reauthenticate(with: credential) { authResult, error in
            if let error = error {
                self.showError(error.localizedDescription)
                return
            }
            // Apple user successfully re-authenticated.
            self.performDeleteUser()
        }
    }

    private func performDeleteUser() {
        Task {
            do {
                try await Auth.auth().currentUser?.delete()
                userStore.signOut()
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in charset[Int(byte) % charset.count] }
        return String(nonce)
    }

    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
}

struct SupportView: View {
    var body: some View {
        Text("Support Information")
            .navigationBarTitle("Support")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy")
            .navigationBarTitle("Privacy Policy")
    }
}

#Preview {
    let store = Store()
    return SettingsView()
        .environmentObject(store)
        .environmentObject(UserStore())
}
