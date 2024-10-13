//
//  AuthManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 10/10/24.
//
import Supabase
import AuthenticationServices
import CryptoKit
import Combine

enum AuthError: Error {
    case invalidCredentials
    case signInFailed(String)
    case usernameTaken
    case unknownError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials provided."
        case .signInFailed(let message):
            return message
        case .usernameTaken:
            return "This username is already taken."
        case .unknownError(let message):
            return "An unknown error occurred: \(message)"
        }
    }
}

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    let client = SupabaseManager.shared.client
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var session: Session?
    @Published var nonce: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            await listenForAuthChanges()
        }
    }
    
    
    
    private func listenForAuthChanges() async {
        // Using Closure to subscribe to auth state changes
        _ = await client.auth.onAuthStateChange { [weak self] event, session in
            // Ensure UI updates happen on the main thread
            self?.handleAuthEvent(event, session: session)
        }
        
        // Load session on initialization
        do {
            let session = try await client.auth.session // Await the session retrieval and handle errors
            DispatchQueue.main.async {
                self.session = session // Update session on the main thread
                print("Loaded session: \(String(describing: self.session))")
            }
        } catch {
            print("Failed to load session: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.session = nil // Optionally clear the session on failure
            }
        }
    }

    private func handleAuthEvent(_ event: AuthChangeEvent, session: Session?) {
        switch event {
        case .signedIn:
            DispatchQueue.main.async {
                print("User signed in: \(String(describing: session))")
                self.session = session // Update session on sign in
            }
        case .signedOut:
            print("User signed out.")
            DispatchQueue.main.async {
                self.session = nil // Clear session on sign out
            }
        case .tokenRefreshed:
            print("Token refreshed: \(String(describing: session))")
            DispatchQueue.main.async {
                self.session = session // Update session on token refresh
            }
        case .userUpdated:
            DispatchQueue.main.async {
                print("User updated: \(String(describing: session))")
                self.session = session // Update session if user info changed
            }
        case .passwordRecovery:
            print("Password recovery event.")
        default:
            break
        }
    }
    
    // Function to handle signing in with Apple
    func signInWithApple(authorization: ASAuthorization) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.invalidCredentials  // Handle error appropriately
        }
        
        // Pass both the ID token and the nonce (unhashed) to Supabase
        let session = try await supabase.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .apple,
                idToken: idTokenString,
                nonce: nonce  // Use the stored nonce (unhashed)
            )
        )
        
        DispatchQueue.main.async {
            self.session = session
        }
        
        print("Signed in with Supabase: \(session)")
    }
    
    func checkSession() {
        if let session = session {
            self.isAuthenticated = true
            print("User is logged in with session: \(session)")
        } else {
            self.isAuthenticated = false
            print("User is not logged in. (supabase)")
        }
    }
    
    func signOut() async {
        do {
            try await client.auth.signOut(scope: .local) // Sign out locally
            DispatchQueue.main.async {
                self.session = nil // Clear session
            }
        } catch {
            print("Sign out failed: \(error.localizedDescription)")
        }
    }

    func deleteAccount() async {
        do {
               // 1. Call the RPC function to delete the user
               try await client.rpc("delete_user").execute()
               print("User account deleted successfully.")

               // 2. Sign the user out globally to invalidate all sessions
               try await client.auth.signOut(scope: .global)
               print("User signed out successfully.")

               // 3. Clear the session in the app to update the UI
               DispatchQueue.main.async {
                   self.session = nil
               }

           } catch {
               print("Error during account deletion and sign-out: \(error.localizedDescription)")
           }
       }
    
    // Function to generate the nonce
    func generateNonce() -> String {
        let nonce = randomNonceString()
        self.nonce = nonce  // Store the nonce to be used later
        return nonce
    }
    
    // Existing nonce helpers
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
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.map { String(format: "%02x", $0) }.joined()
        return hashString
    }
}
