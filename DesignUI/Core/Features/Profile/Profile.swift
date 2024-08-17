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
import SDWebImage
import SDWebImageSwiftUI

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
    @State private var isLoading = true
    @State private var showDeleteAccountAlert = false
    @State private var showSignOutAlert = false
    @State private var alertItem: AlertItem?
    @Environment(\.colorScheme) var colorScheme
    
    @State private var startAnimation: Bool = false
    @State private var opacity: Double = 0.0
    @State private var showMenu = false

    @State private var signInAppleButtonId = UUID().uuidString
    private var buttonStyle: SignInWithAppleButton.Style {
        switch colorScheme {
        case .light: return .black
        case .dark: return .white
        @unknown default: return .black
        }
    }
    
    var body: some View {
        
            ScrollView{
                VStack {
                    if isLoading {
                        VStack{
                            
                        }
                        .overlay{
                            Spacer()
                            ProgressView("")
                            Spacer()
                        }
                    } else if let user = userStore.user {
                        VStack {
                            // Profile header
                            VStack {
                                if user.profileImage != ""{
                                    WebImage(url: URL(string: user.profileImage)) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 160, height: 130)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                                .overlay(Circle().strokeBorder(colorScheme == .light ? Color.black : Color.primary, style: StrokeStyle(lineWidth: 2.0)))
                                                .shadow(radius: 10)
                                        case .failure:
                                            Image(systemName: "")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipShape(Circle())
                                                .overlay(Circle().strokeBorder(colorScheme == .light ? Color.black : Color.primary, style: StrokeStyle(lineWidth: 2.0)))
                                                .shadow(radius: 10)
                                        }
                                    }
                                } else {
                                    // Circular profile image
                                    Image(getFirstChar(user.displayName)) // Replace with your image name
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 2))
                                        .shadow(radius: 10)
                                        .overlay {
                                            Text(getFirstChar(user.displayName))
                                                .font(.title)
                                                .fontWeight(.bold)
                                        }
                                }
                                HStack{
                                    // Name
                                    Text(user.displayName)
                                        .font(.title)
                                        .fontWeight(.bold)
                                    
                                    if user.isVerified{
                                        Image(systemName: "checkmark.seal.fill")
                                    }
                                }
                                
                                // Username
                                Text("@\(user.username)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding([.leading, .trailing], 20)
                                    .padding(.bottom, 10)
                                
                                // Bio
                                Text(user.bio)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                    .padding([.leading, .trailing], 20)
                                    .padding(.bottom, 10)
                                
                                // Edit User Account
                                HStack {
                                    Button(action: {
                                        showEditProfile.toggle()
                                    }) {
                                        HStack {
                                            Text("Edit Profile")
                                        }
                                        .font(.system(size: 16))
                                        .bold()
                                        .padding()
                                        .background(.thickMaterial)
                                        .cornerRadius(10)
                                        .foregroundColor(.primary)
                                    }
                                    .sheet(isPresented: $showEditProfile) {
                                        EditProfileView(displayName: user.displayName, bio: user.bio, username: user.username)
                                            .environmentObject(userStore)
                                            .presentationDetents([.large])
                                    }
#if os(iOS)
                                    Menu {
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
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "gearshape.fill")
                                                .font(.system(size: 16))
                                                .bold()
                                                .padding()
                                                .background(.thickMaterial)
                                                .cornerRadius(10)
                                                .foregroundColor(.primary)
                                            
                                        }
                                    }
#endif
                                    
#if os(macOS)
                                    Button(action: {
                                        showMenu.toggle()
                                    }) {
                                        Image(systemName: "ellipsis.circle")
                                            .font(.title)
                                            .foregroundColor(.primary)
                                    }
                                    .popover(isPresented: $showMenu, arrowEdge: .top) {
                                        DropdownMenuView()
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
#endif
                                }
#if os(macOS)
                                .buttonStyle(.plain)
#endif
                                .frame(width: 400)
                            }
                            
                            // Tabs
                            HStack {
                                GeometryReader { geometry in
                                    HStack(spacing: 0) {
                                        
                                        TabButton(imageName: "heart", isSelected: selectedTab == 1) {
                                            withAnimation {
                                                selectedTab = 1
                                            }
                                        }
                                        .frame(width: geometry.size.width )
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .foregroundColor((colorScheme == .dark ? .white : .black))
                                            .frame(width: geometry.size.width / 2 - 20, height: 4)
                                            .offset(y: 28)
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
                        .padding(.top)
                        .onAppear {
                            print("User is logged in and user data is available: \(user.displayName), \(user.bio)")
                        }
                    } else {
                        VStack{
                            VStack(alignment: .center) {
                                
                                TitleView()
                                
                                InformationContainerView()
                                
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
                                .id(signInAppleButtonId)
                                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                                .onChange(of: colorScheme, { oldValue, newValue in
                                    signInAppleButtonId = UUID().uuidString
                                })
                                .font(.title)
                                .clipShape(Capsule())
                                .clipped()
                                .frame(height: 30)
                                .padding(.top, 10)
                                .background(.clear)
                                
                                let user = Auth.auth().currentUser
                                if let user = user {
                                    let uid = user.uid
                                    Text(uid)
                                        .font(.headline)
                                }
                            }
                            
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .onAppear {
                            checkLoggedIn()
                            print("User is not logged in or user data is not available")
                        }
                        
                    }
                }
                .navigationTitle("Profile")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .alert(isPresented: $showErrorAlert) {
                    Alert(
                        title: Text("Error"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .offset(y: startAnimation ? 0 : 50)
            .opacity(opacity)
        
        .background(Color(red: 30/255, green: 30/255, blue: 30/255))
        .onAppear {
            checkLoggedIn()
            withAnimation(.easeInOut(duration: 0.3)) {
                startAnimation = true
                opacity = 1.0
            }
            
        }
    }
    
    
    func getFirstChar(_ deckName : String) -> String {
        return String(deckName.prefix(1))
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
                                "followersCount": 0,
                                "followingCount": 0,
                                "likesCount": 0,
                                "username": "",
                                "bio": "",
                                "imageURL": "",
                                "visibility": "public",
                                "createdAt": Timestamp(),
                                "websiteURL": "",
                                "isVerified": false,
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
                                    let newUser = UserModel(id: user.uid, profileImage: "", displayName: "New User", username: "", bio: "", isVerified: false)
                                    userStore.signIn(user: newUser)
                                }
                            }
                        }
                        isLoading = false
                    }
                }
            }
        }
    }
    
    func checkLoggedIn() {
        isLoading = true
        if let user = Auth.auth().currentUser {
            print("User is logged in: \(user.uid)")
            userStore.fetchUserData(uid: user.uid) { fetchedUser in
                if fetchedUser == nil {
                    let userData = UserModel(id: user.uid, profileImage: "", displayName: user.displayName ?? "New User", username: "", bio: "", isVerified: false)
                    userStore.signIn(user: userData)
                }
                isLoading = false
            }
        } else {
            print("User is not logged in")
            isLoading = false
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

struct LikedPost: Identifiable {
    var id: String
    var img: String
    var title: String
    var description: String
}

struct InformationDetailView: View {
    var title: String = "title"
    var subTitle: String = "subTitle"
    var imageName: String = "car"

    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: imageName)
                .font(.largeTitle)
                .foregroundColor(.mainColor)
                .frame(width: 40, height: 40)
                .padding()
                .accessibility(hidden: true)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibility(addTraits: .isHeader)

                Text(subTitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top)
    }
}

struct TitleView: View {
    var body: some View {
        VStack {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .accessibility(hidden: true)
            
            Text("Dock UI")
                .customTitleText()
            
            Text("Accounts")
                .customTitleText()
                .foregroundColor(.mainColor)
        }
        .padding(.top,8)
    }
}

struct InformationContainerView: View {
    var body: some View {
        VStack(alignment: .leading) {
            InformationDetailView(title: "Likes", subTitle: "Sign in to like posts and see the likes. View all your liked posts in your profile.", imageName: "heart")

            InformationDetailView(title: "Customization", subTitle: "Customize your profile with a display name, bio & profile image. Make your profile truly yours!", imageName: "person.fill")
        }
    }
}

struct ButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .font(.headline)
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            .background(RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.mainColor))
            .padding(.bottom)
    }
}

extension View {
    func customButton() -> ModifiedContent<Self, ButtonModifier> {
        return modifier(ButtonModifier())
    }
}

extension Text {
    func customTitleText() -> Text {
        self
            .fontWeight(.black)
            .font(.system(size: 36))
    }
}

extension Color {
    #if os(iOS)
    static var mainColor = Color(UIColor.systemIndigo)
    #endif
    
    #if os(macOS)
    static var mainColor = Color(NSColor.systemIndigo)
    #endif
}
