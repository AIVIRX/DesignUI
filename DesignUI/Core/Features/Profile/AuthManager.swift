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
    case signInFailed(String) // You can expand this with other error cases as needed

    var localizedDescription: String {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials provided."
        case .signInFailed(let message):
            return message
        }
    }
}


class AuthManager: ObservableObject {
    @Published var session: Session? // To track user session
    private let client: SupabaseClient
    
    @Published var nonce: String = ""
    
    init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://dwxfipenxnqkhgtwggrv.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3eGZpcGVueG5xa2hndHdnZ3J2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjgwNjU4OTMsImV4cCI6MjA0MzY0MTg5M30.0mg37FPNXhj0drM0TFSlSzpl2Ofc7nyaHqOTnobvjac"
        )
        
        Task {
            await listenForAuthChanges()
            // Check for existing session asynchronously
        }
    }
    
    private func listenForAuthChanges() async {
        // Using Closure to subscribe to auth state changes
        let subscription = await client.auth.onAuthStateChange { [weak self] event, session in
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
            print("User signed in: \(String(describing: session))")
            self.session = session // Update session on sign in
        case .signedOut:
            print("User signed out.")
            self.session = nil // Clear session on sign out
        case .tokenRefreshed:
            print("Token refreshed: \(String(describing: session))")
            self.session = session // Update session on token refresh
        case .userUpdated:
            print("User updated: \(String(describing: session))")
            self.session = session // Update session if user info changed
        case .passwordRecovery:
            print("Password recovery event.")
        default:
            break
        }
    }
    
    
    // Function to generate the nonce
    func generateNonce() -> String {
        let nonce = randomNonceString()
        self.nonce = nonce  // Store the nonce to be used later
        return nonce
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
            print("User is logged in with session: \(session)")
        } else {
            print("User is not logged in.")
        }
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
