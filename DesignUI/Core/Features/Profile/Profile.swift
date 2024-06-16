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

// AuthorizationControllerDelegate class to handle authorization
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
    @EnvironmentObject var store: Store
    @State private var isLoggedIn = false
    @State private var errorMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var nonce: String?
    @Environment(\.colorScheme) private var scheme
    @State private var authorizationDelegate = AuthorizationControllerDelegate()
    @State private var showDeletionConfirmation = false
    @State private var showSignOutConfirmation = false
    @State private var showEditProfile = false
    @State private var selectedTab = 1
    @State private var user: UserModel?
    var body: some View {
        NavigationView {
            VStack {
                if isLoggedIn {
                    if let user = user {
                        VStack {
                            // Profile header
                            VStack {
                                // Circular profile image
                                Image("profile_image") // Replace with your image name
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(radius: 10)
                                
                                // Name
                                Text(user.displayName) // Replace with your name
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                // Bio
                                Text(user.bio)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding([.leading, .trailing], 20)
                                
                                //Edit User Account
                                Button(action: {
                                    showEditProfile.toggle()
                                }) {
                                    HStack{
                                        Text("Edit Profile")
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                    .foregroundColor(.blue)
                                }
                                .sheet(isPresented: $showEditProfile) {
                                    EditProfileView(displayName: user.displayName, bio: user.bio)
                                }
                                Divider()
                            }
                            
                            // Tabs
                            HStack {
                                
                                //                                        TabButton(title: "Posts", isSelected: selectedTab == 0) {
                                //                                            selectedTab = 0
                                // }
                                TabButton(title: "Liked", isSelected: selectedTab == 1) {
                                    selectedTab = 1
                                }
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            // Tab views
                            if selectedTab == 0 {
                                PostsView()
                            } else {
                                LikedView()
                            }
                            
                            //Sign Out
                            Button(action: {
                                showSignOutConfirmation.toggle()
                            }) {
                                HStack{
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                    
                                }
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.red)
                            }
                            .alert(isPresented: $showSignOutConfirmation) {
                                Alert(
                                    title: Text("Sign Out"),
                                    message: Text("Are you sure you want to sign out from your account?"),
                                    primaryButton: .destructive(Text("Sign out")) {
                                        signOutUser()
                                    },
                                    secondaryButton: .cancel()
                                )}
                            
                            
                            
                            //delete User Account
                            Button(action: {
                                showDeletionConfirmation.toggle()
                            }) {
                                HStack{
                                    Image(systemName: "trash")
                                    Text("Delete Account")
                                }
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.red)
                            }
                            .alert(isPresented: $showDeletionConfirmation) {
                                Alert(
                                    title: Text("Delete Account"),
                                    message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                                    primaryButton: .destructive(Text("Delete")) {
                                        deleteCurrentUser()
                                    },
                                    secondaryButton: .cancel()
                                )}}} else {
                                    // Loading state or empty state
                                    Text("Loading...")
                                        .onAppear {
                                            fetchUserData()
                                        }
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
                        
                        
                        
                        SignInWithAppleButton(.signIn){ request in
                            let nonce = randomNonceString()
                            self.nonce =  nonce
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
                    }
                }
            }
            .padding(5)
            .navigationBarTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: HStack {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                }
            })
            .alert(errorMessage, isPresented: $showAlert){}
            .overlay {
                if isLoading {
                    LoadingScreen()
                }
            }
        }
    }
                                        
                                        
    
    private var buttonStyle: SignInWithAppleButton.Style {
           switch scheme {
           case .light: return .black
           case .dark: return .white
           @unknown default: return .black
           }
       }
    
    // Fetch User Data from Firestore
        func fetchUserData() {
            guard let user = Auth.auth().currentUser else { return }
            let db = Firestore.firestore()
            let userDocRef = db.collection("users").document(user.uid)
            userDocRef.addSnapshotListener { documentSnapshot, error in
                if let error = error {
                    showError(error.localizedDescription)
                    return
                }
                guard let document = documentSnapshot, document.exists, let data = document.data() else {
                    showError("Document does not exist")
                    return
                }
                let displayName = data["displayName"] as? String ?? "New User"
                let bio = data["bio"] as? String ?? ""
                self.user = UserModel(id: user.uid, displayName: displayName, bio: bio)
            }
        }
    
    // User is already logged in
    func checkLoggedIn() {
        if Auth.auth().currentUser != nil {
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
                                "displayName": "New User",
                                "email": user.email ?? "",
                                "followersCount": 0,
                                "followingCount": 0,
                                "likesCount": 0,
                                "username": "",
                                "bio": "",
                                "imageURL": ""
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
    
    private func signOutUser() {
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
            updateUI()
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
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
                updateUI()
            } catch {
                showError(error.localizedDescription)
            }
        }
    }
    
    private func updateUI() {
        isLoggedIn = false
    }
    
    struct TabButton: View {
        var title: String
        var isSelected: Bool
        var action: () -> Void
        
        var body: some View {
            Text(title)
                .font(.headline)
                .padding()
                //.background((isSelected ? Color.gray : Color.clear).opacity(0.3))
                .cornerRadius(10)
                .onTapGesture {
                    action()
                }
        }
    }
}

#Preview {
    ProfileView()
}
