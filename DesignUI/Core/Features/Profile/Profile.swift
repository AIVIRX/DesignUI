//
//  Profile.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/12/24.
//

import SwiftUI
import AuthenticationServices
import FirebaseFirestore
import CryptoKit
import SDWebImage
import SDWebImageSwiftUI
import UserNotifications
import FirebaseMessaging
import Supabase

struct ProfileView: View {
    @EnvironmentObject private var store: Store
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var showEditProfile = false
    @State private var showAccountSettings = false
    @State private var selectedTab = 1
    @State private var nonce: String?
    @State private var showDeleteAccountAlert = false
    @State private var showSignOutAlert = false
    @State private var alertItem: AlertItem?
    @Environment(\.colorScheme) var colorScheme
    @State private var startAnimation: Bool = false
    @State private var opacity: Double = 0.0
    @State private var showMenu = false
    @State private var signInAppleButtonId = UUID().uuidString
    @ObservedObject var userViewModel = UserViewModel.shared
    @ObservedObject var authManager = AuthManager.shared
    @State private var userName: String = ""
    @State private var displayName: String = ""
    @State private var isCheckingAvailability = false
    @State private var isUsernameTaken = false
    let client = SupabaseManager.shared.client
    
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
                    VStack {
                        if let profile = userViewModel.profile {
                            VStack {
                                if (profile.image_url != "") {
                                    WebImage(url: URL(string: profile.image_url + "?t=\(Date().timeIntervalSince1970)")) { phase in
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
                                    .sheet(isPresented: $showEditProfile) {
                                        EditProfileView()
                                            .presentationDetents([.large])
                                    }
#if os(iOS)
                                    Menu {
                                        Button(action: {
                                            alertItem = AlertItem(
                                                title: Text("Sign Out"),
                                                message: Text("Are you sure you want to sign out?"),
                                                primaryButton: .destructive(Text("Sign Out")) {
                                                    Task{
                                                        await authManager.signOut()
                                                        authManager.checkSession()
                                                    }
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
                                                    Task{
                                                        await authManager.deleteAccount()
                                                        authManager.checkSession()
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
                        }
                        
                        // Tab views
                        if selectedTab == 0 {
                            Text("Post View")
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


