//
//  Profile.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/12/24.
//
import SwiftUI
import AuthenticationServices
import FirebaseFirestore
import FirebaseAuth
import CryptoKit

class AuthorizationControllerDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var onCompletion: ((Result<ASAuthorization, Error>) -> Void)?
    var presentationAnchorProvider: (() -> ASPresentationAnchor)?
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onCompletion?(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onCompletion?(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentationAnchorProvider?() ?? ASPresentationAnchor()
    }
}

struct ProfileView: View {
    @EnvironmentObject var userStore: UserStore
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var showEditProfile = false
    @State private var showAccountSettings = false
    @State private var selectedTab = 1
    @State private var nonce: String?
    @State private var authorizationDelegate = AuthorizationControllerDelegate()
    @State private var isLoading = false
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                } else if let user = userStore.user {
                    VStack {
                        // Profile header
                        VStack {
                            // Circular profile image
                            Image("profile_image") // Replace with your image name
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 2))
                                .shadow(radius: 10)
                            
                            // Name
                            Text(user.displayName)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            // Bio
                            Text(user.bio)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding([.leading, .trailing], 20)
                            
                            // Edit User Account
                            Button(action: {
                                showEditProfile.toggle()
                            }) {
                                HStack {
                                    Text("Edit Profile")
                                }
                                .padding()
                                .background(.thinMaterial)
                                .cornerRadius(10)
                                .foregroundColor(.primary)
                            }
                            .sheet(isPresented: $showEditProfile) {
                                EditProfileView(displayName: user.displayName, bio: user.bio)
                                    .environmentObject(userStore)
                                    .presentationDetents([.medium, .large])
                            }
                            .sheet(isPresented: $showAccountSettings) {
                                AccountSettings()
                                    .presentationDetents([.medium, .large])
                            }
                        }
                        
                        // Tabs
                        HStack {
                            GeometryReader { geometry in
                                HStack(spacing: 0) {
                                    TabButton(imageName: "arrow.triangle.2.circlepath.icloud", isSelected: selectedTab == 0) {
                                        withAnimation {
                                            selectedTab = 0
                                        }
                                    }
                                    .frame(width: geometry.size.width / 2)
                                    
                                    TabButton(imageName: "heart", isSelected: selectedTab == 1) {
                                        withAnimation {
                                            selectedTab = 1
                                        }
                                    }
                                    .frame(width: geometry.size.width / 2)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundColor((colorScheme == .dark ? .white : .black))
                                        .frame(width: geometry.size.width / 2 - 20, height: 4)
                                        .offset(x: selectedTab == 0 ? -100 : 100, y: 28)
                                        .animation(.easeInOut(duration: 0.25), value: UUID())
                                )
                            }
                            .frame(height: 50)
                        }
                        
                        // Tab views
                        if selectedTab == 0 {
                            PostsView()
                        } else {
                            LikedView()
                        }
                    }
                    .onAppear {
                        print("User is logged in and user data is available: \(user.displayName), \(user.bio)")
                    }
                } else {
                    VStack {
                        Text("Snippets UI Profile")
                            .font(.largeTitle).bold()
                        Text("View Liked Designs And More!")
                            .padding(5).bold()
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.gray)
                            .shadow(radius: 5)
                            .padding()
                            .ignoresSafeArea(.all)
                            .frame(height: 450)
                        
                        SignInWithAppleButton(.signIn) { request in
                            let nonce = randomNonceString()
                            self.nonce = nonce
                            request.requestedScopes = [.email, .fullName]
                            request.nonce = sha256(nonce)
                        } onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                loginWithFirebase(authorization)
                            case .failure(let error):
                                showError(error.localizedDescription)
                            }
                        }
                        .signInWithAppleButtonStyle(buttonStyle)
                        .frame(height: 50)
                        .clipShape(Capsule())
                        .padding(.top, 10)
                        
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
                        print("User is not logged in or user data is not available")
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: HStack {
                // Settings
                Button(action: {
                    showAccountSettings.toggle()
                }) {
                    Image(systemName: "person.2.badge.gearshape.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                        .presentationDetents([.medium, .large])
                }
            })
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var buttonStyle: SignInWithAppleButton.Style {
        switch colorScheme {
        case .light: return .black
        case .dark: return .white
        @unknown default: return .black
        }
    }
    
    func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    func loginWithFirebase(_ authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // Showing loading screen until login completes with Firebase
            isLoading = true
            guard let nonce else {
                showError("Cannot Process Your Request")
                isLoading = false
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                showError("Cannot Process Your Request")
                isLoading = false
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                showError("Cannot Process Your Request")
                isLoading = false
                return
            }
            // Initialize a Firebase credential, including the user's full name.
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error {
                    showError(error.localizedDescription)
                    isLoading = false
                    return
                }
                // User is signed in to Firebase with Apple.
                if let user = Auth.auth().currentUser {
                    userStore.fetchUserData(uid: user.uid) { fetchedUser in
                        if fetchedUser == nil {
                            print("Creating New User document - New User")
                            let userData: [String: Any] = [
                                "uid": user.uid,
                                "displayName": "New User",
                                "email": user.email ?? "",
                                "followersCount": 0,
                                "followingCount": 0,
                                "likesCount": 0,
                                "username": "",
                                "bio": "",
                                "imageURL": ""
                            ]
                            let db = Firestore.firestore()
                            let userDocRef = db.collection("users").document(user.uid)
                            userDocRef.setData(userData) { error in
                                if let error = error {
                                    print("Error creating user document: \(error.localizedDescription)")
                                } else {
                                    print("User document created successfully!")
                                    // Create an empty document in the likedPosts subcollection
                                    let likedPostsCollectionRef = userDocRef.collection("likedPosts")
                                    likedPostsCollectionRef.addDocument(data: [:]) { error in
                                        if let error = error {
                                            print("Error creating likedPosts document: \(error.localizedDescription)")
                                        } else {
                                            print("LikedPosts document created successfully!")
                                        }
                                    }
                                    let newUser = UserModel(id: user.uid, displayName: "New User", bio: "")
                                    userStore.signIn(user: newUser)
                                }
                            }
                        }
                    }
                }
                isLoading = false
            }
        }
    }
    
    func checkLoggedIn() {
        if let user = Auth.auth().currentUser {
            print("User is logged in: \(user.uid)")
            userStore.fetchUserData(uid: user.uid) { fetchedUser in
                if fetchedUser == nil {
                    let userData = UserModel(id: user.uid, displayName: user.displayName ?? "New User", bio: "")
                    userStore.signIn(user: userData)
                }
            }
        } else {
            print("User is not logged in")
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

struct TabButton: View {
    var imageName: String
    var isSelected: Bool
    var action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack {
            Image(systemName: isSelected ? "\(imageName).fill" : "\(imageName)")
                .foregroundColor(isSelected ? (colorScheme == .dark ? .white : .black) : .gray)
                .font(.system(size: 20))
                .padding()
        }
        .onTapGesture {
            action()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserStore())
}
