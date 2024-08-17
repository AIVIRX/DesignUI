//
//  DropDownView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/16/24.
//

import SwiftUI
import CryptoKit
import FirebaseAuth
import AuthenticationServices

struct DropdownMenuView: View {
    @State private var authorizationDelegate = AuthorizationControllerDelegate()
    @State private var alertItem: AlertItem?
    @EnvironmentObject var userStore: UserStore
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var nonce: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                alertItem = AlertItem(
                    title: Text("Sign Out"),
                    message: Text("Are you sure you want to sign out?"),
                    primaryButton: .destructive(Text("Sign Out")) {
                        signOutUser()
                    },
                    secondaryButton: .cancel()
                )
            }) {
                Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.title2)
                    .padding(5)
            }
            
            Button(role: .destructive, action: {
                alertItem = AlertItem(
                    title: Text("Delete Account"),
                    message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteCurrentUser()
                    },
                    secondaryButton: .cancel()
                )
            }) {
                Label("Delete Account", systemImage: "trash")
                    .font(.title2)
                    .padding(5)
                    .foregroundStyle(Color.red)
            }
            
            Spacer()
        }
        .buttonStyle(.plain)
        .frame(width: 200) // Adjust width as needed
        .padding(.top, 10)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 5)
        .alert(item: $alertItem) { alertItem in
            Alert(title: alertItem.title, message: alertItem.message, primaryButton: alertItem.primaryButton, secondaryButton: alertItem.secondaryButton ?? .default(Text("OK")))
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
            #if os(iOS)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return windowScene.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
            }
            
            return ASPresentationAnchor()
            #endif
            
            #if os(macOS)
            if let keyWindow = NSApplication.shared.keyWindow {
                return keyWindow
            } else {
                return NSApplication.shared.windows.first ?? NSWindow()
            }

            #endif
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
    
    func showError(_ message: String) {
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
