//
//  ContentView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 4/13/24.
//

//Make suree session ends.
import SwiftUI
import Firebase
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import Firebase
import FirebaseFirestore

struct ContentView: View {
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("", systemImage: "house")
                }
                .tag(0)
            
            UploadDesignPage()
                .tabItem {
                    Label("", systemImage: "plus.square.dashed")
                }
                .tag(1)
            
            ProfilePage()
                .tabItem {
                    Label("", systemImage: "person.circle")
                }
                .tag(2)
        }
    }
}

struct HomeView: View {
    var body: some View {
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
                        .padding(.horizontal, 10)
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
                        .padding(.horizontal, 10)
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
                        .padding(.horizontal, 10)
                    }
                }
                .navigationTitle("Designs")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: HStack{
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                            .resizable()
                            .frame(width: 25, height: 25)
                    };
                })
                let user = Auth.auth().currentUser
                if let user = user {
                    let uid = user.uid
                    Text(uid)
                        .font(.headline)
                }
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

struct SettingsView: View {
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}

struct UploadDesignPage: View {
        @State private var title: String = ""
        @State private var description: String = ""
        @State private var codeSnippet: String = ""
        @State private var selectedImage: UIImage?
        @State private var isShowingImagePicker = false
        var body: some View {
            NavigationView{
                ScrollView {
                    VStack {
                        VStack(alignment: .leading){
                            Text("Thumbnail")
                                .bold()
                            if let image = selectedImage {
                                Button(action: {
                                    selectedImage = nil
                                    isShowingImagePicker = true
                                }) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .clipped()
                                }
                            } else {
                                Button(action: {
                                    isShowingImagePicker = true
                                }) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .foregroundColor(.clear)
                                        .overlay(
                                            Image(systemName: "plus.circle.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 50, height: 50)
                                                .foregroundColor(.blue)
                                        )
                                        .frame(width: .infinity, height: 200)
                                }
                                .padding()
                                .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2.0, dash: [5])))
                                .sheet(isPresented: $isShowingImagePicker) {
                                    ImagePicker(selectedImage: $selectedImage)
                                }
                            }
                            
                            Text("Title")
                                .bold()
                            TextField("Login Screen UI", text: $title)
                                .padding()
                                .bold()
                                .frame(height: 50)
                                .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2.0)))
                            
                            Text("Description")
                                .bold()
                            TextField("A simple login menu.", text: $description)
                                .padding()
                                .bold()
                                .frame(height: 50)
                                .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2.0)))
                            
                            Text("Code")
                                .bold()
                            TextEditor(text: $codeSnippet)
                                .padding()
                                .frame(height: 100)
                                .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 2.0)))
                        }
                        
                        Button(action: {uploadDesign()}) {
                            Text("Upload Design")
                                .padding(8)
                                .frame(maxWidth: .infinity)
                                .font(.headline).bold()
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                    }
                    .navigationTitle("Upload Design")
                    .navigationBarTitleDisplayMode(.inline)
                    .padding()
                }
            }
            .navigationTitle("Upload Design")
        }

        func uploadDesign() {
            
        }
    }

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedImage: UIImage?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Update the view controller if needed
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ProfilePage: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @State private var selectedTab: Int = 0
    let tabs = ["Posts", "Saved", "Liked"]
    var body: some View {
        ScrollView{
            VStack(alignment: .center, spacing: 20) {
                // Circle Profile Image
                VStack(alignment: .center){
                    
                    Image("Maicol")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                    VStack{
                        Text("Aivirx")
                            .font(.title).bold()
                        // User Information
                        Text("@aivirx")
                            .font(.headline)
                    }
                }
                
                HStack {
                    // Followers Count
                    VStack {
                        Text("Followers")
                            .font(.headline)
                        
                        Text("108K")
                            .font(.headline)
                    }
                    .padding()
                    
                    // Following Count
                    VStack {
                        Text("Following")
                            .font(.headline)
                        Text("122")
                            .font(.headline)
                    }
                    .padding()
                    
                    // Account Likes Count
                    VStack {
                        Text("Likes")
                            .font(.headline)
                        Text("500M")
                            .font(.headline)
                    }
                    .padding()
                }
                
                Text("20 |📍manhattan | 🎧🎞️ new project soon (I think) ! 🌠 forever email: maicol@aivirx.com")
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                HStack{
                    // Follow Button
                    Button(action: {
                        // Handle follow button action
                    }) {
                        Text("Edit Profile")
                            .padding()
                            .background(Color.primary)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        // Handle follow button action
                    }) {
                        Text("Follow")
                            .padding()
                            .background(Color.primary)
                            .cornerRadius(10)
                    }
                }
                // Tab Bar
                HStack(spacing: 0) {
                    ForEach(0..<tabs.count) { index in
                        Button(action: {
                            selectedTab = index
                        }) {
                            Text(tabs[index])
                                .foregroundColor(selectedTab == index ? .blue : .gray)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 30)
                        }
                        .background(selectedTab == index ? Color.blue.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.bottom, 10)
                
                // Content based on selected tab
                if selectedTab == 0 {
                    PostsView()
                } else if selectedTab == 1 {
                    SavedView()
                } else if selectedTab == 2 {
                    LikedView()
                } else {
                    EmptyView()
                }
            
                Spacer()
            }
            .padding()
            
            Button("Log Out"){
                try? Auth.auth().signOut()
                isLoggedIn = false
            }
        }
    }
}

struct PostsView: View {
    var body: some View {
        Text("Posts Tab Content")
    }
}

struct SavedView: View {
    var body: some View {
        Text("Saved Tab Content")
    }
}

struct LikedView: View {
    var body: some View {
        Text("Liked Tab Content")
    }
}

struct loginPage: View {
    @State private var errorMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var nonce: String?
    @Environment(\.colorScheme) private var scheme
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    var body: some View {
        NavigationStack {
            if isLoggedIn {
                ContentView()
            } else {
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
                        Text("Discovery Beyond Limits. Explore DesignUI")
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
                }
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
                        } else {
                            // Create a Firestore document for the user
                            print("Creating New User document - New User")
                            let userData: [String: Any] = [
                                "uid": user.uid,
                                "displayName": user.displayName ?? "Anonymous",
                                "email": user.email ?? ""
                                // Add other user data as needed
                            ]
                            
                            userDocRef.setData(userData) { error in
                                if let error = error {
                                    print("Error creating user document: \(error.localizedDescription)")
                                } else {
                                    print("User document created successfully!")
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
