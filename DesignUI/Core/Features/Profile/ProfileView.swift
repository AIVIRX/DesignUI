import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @StateObject private var viewModelLiked = LikedPostsViewModel()
    
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
                    
                    // Content Sections
                    VStack(spacing: 0) {
                        // Section Headers
                        VStack {
                            Image(systemName: "heart")
                                .foregroundStyle(.gray)
                                .bold()
                            
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width:  80 ,height: 3)
                                .foregroundStyle(.primary)
                                .padding(.top)
                        }
                        .padding(.top)
                        
                        // Placeholder for content
                        VStack {
                            if viewModelLiked.isLoading && viewModelLiked.likedPosts.isEmpty {
                                ProgressView()
                                    .padding()
                            } else if viewModelLiked.likedPosts.isEmpty {
                                VStack {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                        .padding()
                                    Text("No liked posts. Swipe down to refresh!")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 5)
                                .frame(maxWidth: .infinity, minHeight: 300)
                            } else {
                                LazyVGrid(columns: gridColumns, spacing: 16) {
                                    ForEach(viewModelLiked.likedPosts) { post in
                                        DesignCards(
                                            id: post.id,
                                            media: post.preview_image_url,
                                            title: post.title,
                                            authorName: post.profiles.username,
                                            isVerified: post.profiles.verified,
                                            description: post.description,
                                            codeSnippet: post.code_snippet,
                                            published: post.created_at,
                                            likesCount: post.likes_count,
                                            isLiked: false
                                        )
                                        .task {
                                            await viewModelLiked.loadMoreLikedPostsIfNeeded(currentItem: post)
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showEditProfile = true
                    }) {
                        Image(systemName: "slider.vertical.3").bold()
                    }
                }
                
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
            }
            // Replace the sheet presentation with:
            // Change the sheet presentation to:
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: viewModel)
                    .environmentObject(authViewModel)
            }
            .refreshable {
                await viewModel.fetchProfile()
                await viewModelLiked.refreshPosts()
            }
            .task {
                if authViewModel.isAuthenticated {
                    await viewModel.fetchProfile()
                }
            }
        }
        .onAppear {
            Task {
                await viewModelLiked.refreshPosts()
            }
        }
    }
}
