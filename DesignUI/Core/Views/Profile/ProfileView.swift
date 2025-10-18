import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @State private var showDeleteAlert = false
    
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
                    Button("No", role: .cancel) { }
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showEditProfile = true
                    }) {
                        Image(systemName: "slider.vertical.3").bold()
                    }
                }
#endif
                
#if os(macOS)
                ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            showEditProfile = true
                        }) {
                            Image(systemName: "slider.vertical.3").bold()
                        }
                    }
#endif
                
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Sign Out"){
                            Task {
                                await authViewModel.signOut()
                            }
                        }
                        Button("Delete Account", role: .destructive) {
                            Task {
                                await authViewModel.deleteAccount()
                            }
                        }
                    } label: {
                        Image(systemName: "person.badge.key.fill")
                            .font(.title2)
                    }
                }
#endif
                
#if os(macOS)
                ToolbarItem {
                    Menu {
                        Button("Sign Out") {
                            Task {
                                await authViewModel.signOut()
                            }
                        }
                        
                        Button("Delete Account", role: .destructive) {
                            showDeleteAlert = true // Show confirmation alert
                        }
                    } label: {
                        Image(systemName: "person.badge.key.fill")
                            .font(.title2)
                    }
                }
#endif
            }
            // Replace the sheet presentation with:
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: viewModel)
                    .environmentObject(authViewModel)
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
