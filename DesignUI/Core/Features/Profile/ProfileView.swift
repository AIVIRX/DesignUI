//
//  ProfileView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/15/24.
//

import SwiftUI
import PostgREST

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var userProfile: Profile?
    @State private var isLoading = true
    @State private var isSigningOut: Bool = false
    @State private var showDeleteAlert = false
    @State private var showEditProfile = false
    @State private var showSignOutAlert = false
    let client = SupabaseManager.shared.client
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 16) {
                    //Profile Image
                    ZStack{
                        
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 90, height: 90)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        Text(String(userProfile?.display_name.prefix(1) ?? "").uppercased())
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    // User Info
                    VStack {
                        VStack{
                            HStack {
                                if userProfile?.verified == true {
                                    Text("     \(userProfile?.display_name ?? "")")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.blue)
                                } else {
                                    Text(userProfile?.display_name ?? "")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                        .padding(.bottom, 8)
                        
                        Text(userProfile?.bio ?? "")
                            .font(.body)
                            .foregroundColor(.white)
                            .frame(maxWidth: 250)
                    }
                }
                .padding(.top, 20)
                
                Divider()
                    .padding()
                
                HStack{
                    Text("Favorites")
                        .font(.title)
                        .padding()
                        .bold()
                    
                    Spacer()
                }
            }
        }
            .navigationTitle("Profile")
            .task {
                await fetchUserProfile()
            }
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Menu {
                        Button(action: {
                            showEditProfile.toggle()
                        }) {
                            Label("Edit Profile", systemImage: "person.fill")
                        }
                        
                        Button(role: .destructive, action: {
                            showDeleteAlert.toggle()
                        }) {
                            Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                        }
                    } label: {
                        Image(systemName: "gear")
                            .foregroundStyle(.white)
                    }
                    
                    Button(action: {
                        showSignOutAlert.toggle()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Add your delete account logic here
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone.")
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authManager.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    
    private func fetchUserProfile() async {
        guard let userId = authManager.currentUser?.id else {
            print("User ID not found.")
            return
        }
        
        do {
            // Fetch the user profile from the "profiles" table
            let response = try await client
                .from("profiles")
                .select("*")
                .eq("id", value: userId)
                .single()
                .execute() as PostgrestResponse<Profile>
            
            // Directly access the profile since response.value is not optional
            let profile = response.value
            print("Fetched profile: \(profile)")
            
            // Update the UI or store the profile as needed
            DispatchQueue.main.async {
                self.userProfile = profile
                self.isLoading = false
            }
        } catch {
            print("Error fetching profile: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}
