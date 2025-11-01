import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @State private var showDeleteAlert = false
    @State private var showUploadTemplate = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.8)) // Customize color
                                .frame(width: 80, height: 80)
                            
                            Text(viewModel.profile?.display_name?.prefix(1).uppercased() ?? "?")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                        // User Info
                        VStack(spacing: 8) {
                            Text(viewModel.profile?.display_name ?? "user")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("@\(viewModel.profile?.username ?? "username")")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if let bio = viewModel.profile?.bio, !bio.isEmpty {
                                Text(String(bio.prefix(130)))
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    // Tabbed Content
                    VStack(spacing: 0) {
                        // Tab Headers
                        HStack(spacing: 40) {
                            // Favorites Tab
                            VStack(spacing: 8) {
                                Image(systemName: "heart")
                                    .foregroundColor(.gray)
                                    .bold()
                                
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: 80, height: 3)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.top)
                        
                        // Liked Posts Content
                        LikedPostsView()
                            .padding(.top, 20)
                    }
                }
                .alert("Are you sure you want to delete your account?",
                       isPresented: $showDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        Task {
                            await authViewModel.deleteAccount()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .frame(maxWidth: 1600)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showUploadTemplate = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showEditProfile = true
                        }) {
                            Label("Edit Profile", systemImage: "slider.vertical.3")
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            Label("Settings", systemImage: "gear")
                        }
                        
                        Button {
                            Task {
                                await authViewModel.signOut()
                            }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.forward")
                        }
                        
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete Account", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
#endif
                
#if os(macOS)
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showUploadTemplate = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            showEditProfile = true
                        }) {
                            Label("Edit Profile", systemImage: "slider.vertical.3")
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            Label("Settings", systemImage: "gear")
                        }
                        
                        Button {
                            Task {
                                await authViewModel.signOut()
                            }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.forward")
                        }
                        
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete Account", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
#endif
            }
            // Replace the sheet presentation with:
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: viewModel)
                    .environmentObject(authViewModel)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showUploadTemplate) {
                UploadTemplateView()
                    .environmentObject(authViewModel)
                    .presentationDetents([.large])
            }
            .refreshable {
                await viewModel.fetchProfile()
            }
            .task {
                if authViewModel.isAuthenticated {
                    await viewModel.fetchProfile()
                }
            }
        }
    }
}
