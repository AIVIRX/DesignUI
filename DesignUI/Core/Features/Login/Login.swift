//
//  Login.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/12/24.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import CryptoKit
import FirebaseFirestore

struct LoginView: View {
    @State private var errorMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var nonce: String?
    @Environment(\.colorScheme) private var scheme
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    var body: some View {
        NavigationStack {
            if isLoggedIn {
                // Show user profile information
                Text("Welcome, User!")
                // Add more profile details here
            } else {
                VStack{
                Text("Snippets UI Profile")
                    .font(.largeTitle).bold()
                Text("View Liked Designs And More!")
                    .padding(5).bold()
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.gray)
                    .shadow(radius: 5)
                    .padding()
                    .ignoresSafeArea(.all)
                        
                        SignInWithAppleButton(.signIn){ request in
                            let nonce = randomNonceString()
                            self.nonce =  nonce
                            request.requestedScopes = [.email,.fullName]
                            request.nonce =  sha256(nonce)
                        } onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                loginWithFirebase(authorization)
                            case .failure(let error):
                                showError(error.localizedDescription)
                            }
                        }
                        .frame(height: 50)
                        .clipShape(.capsule)
                        .padding(.top,  10)
                        
                        let user = Auth.auth().currentUser
                        if let user = user {
                            let uid = user.uid
                            Text(uid)
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                .onAppear {
                    checkLoggedIn()
                }
            }
        }
        .alert(errorMessage, isPresented: $showAlert){}
        .overlay {
            if isLoading {
                LoadingScreen()
            }
        }
    }
    
    func checkLoggedIn() {
        if Auth.auth().currentUser != nil {
            // User is already logged in
            isLoggedIn = true
        }
    }
    
    //loading screen
    @ViewBuilder
    func LoadingScreen() -> some View {
        ZStack{
            Rectangle()
                .fill(.ultraThinMaterial)
            ProgressView()
                .frame(width: 45, height: 45)
                .background(.background, in: .rect(cornerRadius:5))
        }
    }
    
    //Show Error
    func showError(_ message: String){
        errorMessage = message
        showAlert.toggle()
        isLoading = false
    }
    
    //Login With Firebase
    func loginWithFirebase(_ authorization: ASAuthorization){
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            //showing loading screen until login completes with firebase
            isLoading = true
            guard let nonce else {
                //fatalError("Invalid state: A login callback was received, but no login request was sent.")
                showError("Cannot Process Your Request")
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                //print("Unable to fetch identity token")
                showError("Cannot Process Your Request")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                //print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                showError("Cannot Process Your Request")
                return
            }
            // Initialize a Firebase credential, including the user's full name.
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    showError(error.localizedDescription)
                    return
                }
                // User is signed in to Firebase with Apple.
                isLoading = false
                isLoggedIn = true
                
                
                // Check if the user document already exists
                if let user = Auth.auth().currentUser {
                    let db = Firestore.firestore()
                    let userDocRef = db.collection("users").document(user.uid)
                    userDocRef.getDocument { (document, error) in
                        if let document = document, document.exists {
                            print("User document already exists")
                            isLoggedIn = true
                        } else {
                            // Create a Firestore document for the user
                            print("Creating New User document - New User")
                            let userData: [String: Any] = [
                                "uid": user.uid,
                                "displayName": user.displayName ?? "Anonymous",
                                "email": user.email ?? "",
                                "createdAt": Timestamp(),
                                "postsCount": 0,
                                "followersCount": 0,
                                "followingCount": 0,
                                "likesCount": 0,
                                "username": "",
                                "bio": "",
                                "imageURL": "",
                                "status": "active",
                                "isVerified": false
                            ]
                            
                            // Create a subcollection for liked posts
                            let likedPostsCollectionRef = userDocRef.collection("likedPosts")
                            
                            userDocRef.setData(userData) { error in
                                if let error = error {
                                    print("Error creating user document: \(error.localizedDescription)")
                                } else {
                                    print("User document created successfully!")
                                    // Create an empty document in the likedPosts subcollection
                                    likedPostsCollectionRef.addDocument(data: [:]) { error in
                                        if let error = error {
                                            print("Error creating likedPosts document: \(error.localizedDescription)")
                                        } else {
                                            print("LikedPosts document created successfully!")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
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


#Preview {
    LoginView()
}
