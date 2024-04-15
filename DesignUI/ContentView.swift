//
//  ContentView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 4/13/24.
//

import SwiftUI
import Firebase
import AuthenticationServices
import CryptoKit
import FirebaseAuth

struct ContentView: View {
    @AppStorage("log_Status") private var logStatus: Bool = false
    var body: some View {
            TabView{
                NavigationStack{
                ScrollView(.vertical, showsIndicators: true){
                    
                    VStack(alignment: .leading){
                        Text("Featured")
                            .font(.title2).bold()
                            .padding(.top, 10)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(1..<10) { index in
                                    DesignCards(
                                        image: Image("Swiftyui"),
                                        title: "Following List",
                                        author: "Aivirx",
                                        likes: "52",
                                        views: "1.5K"
                                    )
                                }
                            }
                            //.padding(.horizontal, 10)
                        }
                    }
                    
                    VStack(alignment: .leading){
                        Text("Trending")
                            .font(.title2).bold()
                            .padding(.top, 20)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(1..<10) { index in
                                    DesignCards(
                                        image: Image("Swiftyui"),
                                        title: "Following List",
                                        author: "Aivirx",
                                        likes: "52K",
                                        views: "1.9K"
                                    )
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading){
                        Text("Newest")
                            .font(.title2).bold()
                            .padding(.top, 20)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(1..<10) { index in
                                    DesignCards(
                                        image: Image("Swiftyui"),
                                        title: "Following List",
                                        author: "Aivirx",
                                        likes: "52",
                                        views: "104M"
                                    )
                                }
                            }
                        }
                    }
                    .navigationTitle("Designs")
                    
                    Button("Log Out"){
                        try? Auth.auth().signOut()
                        logStatus = false
                    }
                }
            }
                .tabItem {
                    Label("", systemImage: "house")
                }
                
                FeedPage()
                .tabItem {
                    Label("", systemImage: "list.bullet.rectangle.fill")
                }
                
                SearchPage()
                .tabItem { 
                    Label("", systemImage: "plus.square.dashed")
                }
                SearchPage()
                .tabItem {
                    Label("", systemImage: "bell")
                }
                
                profileHandler()
                .tabItem {
                    Label("", systemImage: "person.circle")
                   
                }
        }
    }
}

struct DesignCards: View {
        var image: Image
        var title: String
        var author: String
        var likes: String
        var views: String
    var body: some View {
            VStack(alignment: .leading) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 145, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                Text(title)
                    .font(.headline)
                
                HStack{
                    Text(author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "heart")
                        .resizable()
                        .frame(width: 10, height: 10)
                        .foregroundColor(.secondary)
                    Text(likes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "eye")
                        .resizable()
                        .frame(width: 13, height: 10)
                        .foregroundColor(.secondary)
                    Text(views)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .background(Color.clear)
        }
    }

struct CardPage: View {
    var body: some View {
        
        ScrollView{
            
        }
        
    }
}

struct FeedPage: View {
    var body: some View {
        ScrollView{
            
        }
        
    }
}

struct DesignerPage: View {
    var body: some View {
        ScrollView{
            
        }
    }
}

struct SearchPage: View {
    var body: some View {
        ScrollView{
            
        }
    }
}

struct NotificationsPage: View {
    var body: some View {
        ScrollView{
            
        }
    }
}

struct ProfilePage: View {
    @AppStorage("log_Status") private var logStatus: Bool = false
    var body: some View {
        let user = Auth.auth().currentUser
        if let user = user {
          let uid = user.uid
            Text(uid)
        }
    }
}

struct profileHandler: View {
    @AppStorage("log_Status") private var logStatus: Bool = false
    var body: some View {
        if logStatus{
            ProfilePage()
        } else {
            loginPage()
        }
    }
}

struct loginPage: View {
    @State private var errorMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var nonce: String?
    @Environment(\.colorScheme) private var scheme
    //User Login Status
    @AppStorage("log_Status") private var logStatus: Bool = false
    var body: some View {
        ZStack(alignment: .bottom){
            GeometryReader {
                let size = $0.size
                
                Image ("Swiftyui")
                    .resizable()
                    .aspectRatio (contentMode: .fill)
                    .offset (y: -60)
                    .frame(width: size.width, height: size.height)
            }
                //Gradient Masking
                    .mask{
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [
                                    .white,
                                    .white,
                                    .white,
                                    .white,
                                    .white.opacity(0.9),
                                    .white.opacity(0.6),
                                    .white.opacity(0.2),
                                    .clear,
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom))
                    }
                    .ignoresSafeArea()
            
            //Sign In Button
            VStack(alignment: .leading){
                Text("Design Beyond Limits. Explore DesignUI")
                    .font(.title).bold()
                
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
                .overlay{
//                    ZStack{
//                        Capsule()
//                        
//                        HStack{
//                            Image(systemName: "applelogo")
//                            
//                            Text("Sign In With Apple")
//                        }
//                        .foregroundStyle(scheme == .dark ? .black : .white)
//                    }
                }
                .frame(height: 50)
                .clipShape(.capsule)
                .padding(.top,  10)
                
                //other sign in options
                Button(action: {}, label: {
                    Text("Other Sign In Options")
                        .foregroundStyle (Color.primary)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .contentShape(.capsule)
                        .background{
                    Capsule()
                        .stroke(Color.primary, lineWidth: 0.5)
                        }
                })
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            
            
        }
        .alert(errorMessage, isPresented: $showAlert){
            
        }
        .overlay {
            if isLoading{
                LoadingScreen()
            }
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
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                           rawNonce: nonce,
                                                           fullName: appleIDCredential.fullName)
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
                ///Pushing User to Home View
                logStatus = true
                isLoading = false
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

#Preview {
    ContentView()
}
