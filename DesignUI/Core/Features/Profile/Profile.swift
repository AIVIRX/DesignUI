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
import UserNotifications
import FirebaseMessaging
import Supabase

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
    @EnvironmentObject private var store: Store
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
    @EnvironmentObject var viewModel: UserViewModel
    @ObservedObject var authManager = AuthManager.shared // Assuming you are using a singleton instance
    @State private var userName: String = "" // Moved from AuthManager to View
    @State private var displayName: String = "" // Moved from AuthManager to View
    @State private var isCheckingAvailability = false
    @State private var isUsernameTaken = false
    private var buttonStyle: SignInWithAppleButton.Style {
        switch colorScheme {
        case .light: return .black
        case .dark: return .white
        @unknown default: return .black
        }
    }
    var body: some View {
        NavigationStack{
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    
//                    if isLoading {
//                        VStack{
//                        }
//                        .overlay{
//                            Spacer()
//                            ProgressView("")
//                            Spacer()
//                        }
//                    } else
                    
                    
                    if authManager.session != nil {
                        
                        Button("Sign Out") {
                            Task {
                                await authManager.signOut()
                            }
                        }
                        
                        if let profile = viewModel.profile {
                            if profile.username.isEmpty {
                                // Show username selection view
                                VStack {
                                    Text("Choose your username")
                                        .font(.title)
                                        .padding()
                                    
                                    TextField("Username", text: $userName, onEditingChanged: { _ in
                                        // Perform async check when user finishes editing the field
                                        Task {
                                            isCheckingAvailability = true
                                            isUsernameTaken = await authManager.checkUsernameAvailability(userName)
                                            isCheckingAvailability = false
                                        }
                                    })
                                    .padding()
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    
                                    
                                    
                                    
                                    if isCheckingAvailability {
                                        ProgressView("Checking username availability...")
                                    } else if isUsernameTaken {
                                        Text("Username is already taken. Please choose another.")
                                            .foregroundColor(.red)
                                            .padding(.top, 5)
                                    }
                                    
                                    
                                    TextField("Display Name (Optional)", text: $displayName)
                                        .padding()
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    Button("Submit") {
                                        Task {
                                            let success = await authManager.saveUserProfile(username: userName, displayName: displayName)
                                            if success {
                                                // Reload the profile after successfully saving the username
                                                await viewModel.fetchProfileData()
                                            }
                                        }
                                    }
                                    .disabled(userName.isEmpty) // Disable if username is empty
                                }
                                .padding()
                            } else {
                                VStack {
                                    if let profile = viewModel.profile {
                                        VStack {
                                            if (profile.image_url != "") {
                                                WebImage(url: URL(string: profile.image_url)) { phase in
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
                                                            .overlay(Circle().strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                                                    case .failure:
                                                        Image(systemName: "")
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 100, height: 100)
                                                            .clipShape(Circle())
                                                            .overlay(Circle().strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                                                    }
                                                }
                                            } else {
                                                // Circular profile image
                                                Image(getFirstChar(profile.display_name))
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(Circle())
                                                    .overlay(Circle().stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 2))
                                                    .shadow(radius: 10)
                                                    .overlay {
                                                        Text(getFirstChar(profile.display_name))
                                                            .font(.title)
                                                            .fontWeight(.bold)
                                                    }
                                            }
                                            
                                            // Username
                                            Text("@\(profile.username)")
                                                .font(.body)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                            
                                            HStack{
                                                // Display Name
                                                Text(profile.display_name)
                                                    .font(.title)
                                                    .fontWeight(.bold)
                                                //Verified Mark
                                                if profile.is_verified{
                                                    Image(systemName: "checkmark.seal.fill")
                                                }
                                            }
                                            .padding(.bottom)
                                            
                                            // Bio
                                            Text(profile.bio)
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
#if os(iOS)
                                                    .background(.thickMaterial)
#endif
#if os(macOS)
                                                    .background(.gray.opacity(0.2))
#endif
                                                    .cornerRadius(10)
                                                    .foregroundColor(.primary)
                                                }
                                                //                                    .sheet(isPresented: $showEditProfile) {
                                                //                                        EditProfileView(displayName: user.displayName, bio: user.bio, username: user.username)
                                                //                                            .environmentObject(userStore)
                                                //                                            .presentationDetents([.large])
                                                //                                    }
#if os(iOS)
                                                Menu {
                                                    Button(action: {
                                                        alertItem = AlertItem(
                                                            title: Text("Sign Out"),
                                                            message: Text("Are you sure you want to sign out?"),
                                                            primaryButton: .destructive(Text("Sign Out")) {
                                                                //signOutUser()
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
                                                                Task {
                                                                    await authManager.deleteAccount()
                                                                }
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
                                                    Image(systemName: "gearshape.fill")
                                                        .font(.system(size: 16))
                                                        .bold()
                                                        .padding()
                                                        .background(.gray.opacity(0.2))
                                                        .cornerRadius(10)
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
#if os(iOS)
                                    requestNotificationPermissions()
#endif
                                }
                            }
                        }
                    } else {
                        VStack{
                            VStack(alignment: .center) {
                                
                                TitleView()
                                
                                InformationContainerView()
                                
                                SignInWithAppleButton(.signIn) { request in
                                    let nonce = authManager.generateNonce()  // Generate nonce here
                                    request.requestedScopes = [.email, .fullName]
                                    request.nonce = authManager.sha256(nonce)  // Pass the hashed nonce to the Apple request
                                } onCompletion: { result in
                                    switch result {
                                    case .success(let authorization):
                                        Task {
                                            do {
                                                try await authManager.signInWithApple(authorization: authorization)
                                            } catch {
                                                print("Sign in failed: \(error.localizedDescription)")
                                            }
                                        }
                                    case .failure(let error):
                                        print("Apple sign in failed: \(error.localizedDescription)")
                                    }
                                }
                                .id(signInAppleButtonId)
                                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                                .onChange(of: colorScheme, { oldValue, newValue in
                                    signInAppleButtonId = UUID().uuidString
                                })
                                .font(.system(size: 30))
                                .clipShape(Capsule())
                                .clipped()
#if os(iOS)
                                .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? 300 : 600, height: UIDevice.current.userInterfaceIdiom == .phone ? 50 : 50 )
#elseif os(macOS)
                                .frame(width: 600, height: 60)
#endif
                                
                                .padding(.top, 20)
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
                            print("User is not logged in or user data is not available")
                        }
                    }
                }
                .onAppear {
                    Task {
                        await viewModel.fetchProfileData()  // Call the fetch function
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
                .alert(item: $alertItem) { alertItem in
                    Alert(title: alertItem.title, message: alertItem.message, primaryButton: alertItem.primaryButton, secondaryButton: alertItem.secondaryButton ?? .default(Text("OK")))
                }
            }
            .offset(y: startAnimation ? 0 : 50)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3)) {
                    startAnimation = true
                    opacity = 1.0
                }
                
            }
#if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                if store.completedPurchases.isEmpty {
                    AdView(adUnitID: AdUnitID.finalAd)
                        .frame(width: 468, height: 60)
                        .padding(3)
                }
            }
#endif
        }
    }
    
    #if os(iOS)
    private func requestNotificationPermissions() {
            // Check current authorization status
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                if settings.authorizationStatus == .notDetermined {
                    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                    UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
                        if granted {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        } else if let error = error {
                            print("Notification authorization error: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    #endif
    
    func getFirstChar(_ deckName : String) -> String {
        return String(deckName.prefix(1))
    }
    
    func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
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
    static let mainColor = Color(UIColor.systemIndigo)
    #endif
    
    #if os(macOS)
    static let mainColor = Color(NSColor.systemIndigo)
    #endif
}
