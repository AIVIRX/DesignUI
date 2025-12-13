import SwiftUI

enum ProfileTab {
    case liked
    case myPosts
}

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @State private var showDeleteAlert = false
    @State private var showUploadTemplate = false
    @State private var selectedTab: ProfileTab = .liked
    @StateObject private var likedViewModel = LikedPostsViewModel()
    @StateObject private var userViewModel = UserPostsViewModel()
    @State private var showDeletePostAlert = false
    @State private var postToDelete: DesignPost?
    
    private var isLikedFilter: Bool {
        selectedTab == .liked
    }
    
    private var posts: [DesignPost] {
        isLikedFilter ? likedViewModel.likedPosts : userViewModel.userPosts
    }
    
    private var isLoading: Bool {
        isLikedFilter ? likedViewModel.isLoading : userViewModel.isLoading
    }
    
    private var hasMorePosts: Bool {
        isLikedFilter ? likedViewModel.hasMorePosts : userViewModel.hasMorePosts
    }
    
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
                            HStack(spacing: 6) {
                            Text(viewModel.profile?.display_name ?? "user")
                                .font(.title2)
                                .fontWeight(.bold)
                                
                                if viewModel.profile?.verified == true {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                }
                            }
                            
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
                        ZStack(alignment: .top) {
                            // Tab Buttons
                        HStack(spacing: 40) {
                            // Liked Tab
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = .liked
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "heart")
                                        .foregroundColor(selectedTab == .liked ? .primary : .gray)
                                        .bold()
                                    
                                        // Spacer for indicator
                                    RoundedRectangle(cornerRadius: 20)
                                        .frame(width: 80, height: 3)
                                            .foregroundColor(.clear)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
                            
                            // My Posts Tab
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = .myPosts
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "square.grid.2x2")
                                        .foregroundColor(selectedTab == .myPosts ? .primary : .gray)
                                        .bold()
                                    
                                        // Spacer for indicator
                                    RoundedRectangle(cornerRadius: 20)
                                        .frame(width: 80, height: 3)
                                            .foregroundColor(.clear)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top)
                            .frame(maxWidth: .infinity)
                            
                            // Moving Indicator - single indicator that slides between positions
                            HStack(spacing: 40) {
                                RoundedRectangle(cornerRadius: 20)
                                    .frame(width: 80, height: 3)
                                    .foregroundColor(.primary)
                                    .id("indicator")
                                
                                Color.clear
                                    .frame(width: 80, height: 3)
                            }
                            .padding(.top, 32)
                            .frame(maxWidth: .infinity)
                            .offset(x: selectedTab == .liked ? 0 : 120)
                        .animation(.easeInOut(duration: 0.2), value: selectedTab)
                        }
                        
                        // Tab Content - posts grid
                        ScrollView {
                            if isLoading && posts.isEmpty {
                                ProgressView()
                                    .padding()
                            } else if posts.isEmpty {
                                VStack {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                        .padding()
                                    Text(isLikedFilter ? "No liked posts yet" : "No posts yet")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 5)
                                .frame(maxWidth: .infinity, minHeight: 300)
                            } else {
                                postsGridView
                            }
                        }
                        .padding(.top, 20)
                        .task(id: selectedTab) {
                            // Only load if the current tab's data is empty
                            if selectedTab == .liked && likedViewModel.likedPosts.isEmpty {
                                await likedViewModel.fetchLikedPosts()
                            } else if selectedTab == .myPosts && userViewModel.userPosts.isEmpty {
                                await userViewModel.fetchUserPosts()
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .likesChanged)) { notification in
                            guard isLikedFilter else { return }
                            guard
                                let info = notification.userInfo,
                                let postId = info["postId"] as? String,
                                let isLiked = info["isLiked"] as? Bool
                            else { return }

                            if !isLiked {
                                // Remove unliked post from the grid immediately
                                if let index = likedViewModel.likedPosts.firstIndex(where: { $0.id == postId }) {
                                    likedViewModel.likedPosts.remove(at: index)
                                }
                            } else {
                                // Post was liked - fetch and add it to the list
                                Task {
                                    await likedViewModel.addLikedPost(postId: postId)
                                }
                            }
                        }
                        .refreshable {
                            if isLikedFilter {
                                await likedViewModel.refreshPosts()
                            } else {
                                await userViewModel.refreshPosts()
                            }
                        }
                        .alert("Delete Post", isPresented: $showDeletePostAlert) {
                            Button("Cancel", role: .cancel) {
                                postToDelete = nil
                            }
                            Button("Delete", role: .destructive) {
                                if let post = postToDelete {
                                    Task {
                                        do {
                                            try await userViewModel.deletePost(postId: post.id)
                                        } catch {
                                            print("Error deleting post: \(error)")
                                        }
                                    }
                                }
                                postToDelete = nil
                            }
                        } message: {
                            Text("Are you sure you want to delete this post? This action cannot be undone.")
                        }
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
    
    @ViewBuilder
    private var postsGridView: some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            if #available(iOS 16.0, *) {
                LazyMasonryView(
                    items: posts,
                    columns: 2,
                    spacing: 8,
                    hasMorePosts: hasMorePosts,
                    isLoading: isLoading,
                    loadMoreHandler: { post in
                        guard let post = post else { return }
                        // Prevent multiple simultaneous loads
                        guard hasMorePosts && !isLoading else { return }
                        Task {
                            if isLikedFilter {
                                await likedViewModel.loadMoreLikedPostsIfNeeded(currentItem: post)
                            } else {
                                await userViewModel.loadMoreUserPostsIfNeeded(currentItem: post)
                            }
                        }
                    }
                ) { post in
                    postCell(for: post)
                }
                .id("masonry-\(selectedTab)")
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            } else {
                gridView(spacing: 8, horizontalPadding: 8)
            }
        } else {
            // iPad: Use LazyMasonryView with 5 columns like Mac
            if #available(iOS 16.0, *) {
                LazyMasonryView(
                    items: posts,
                    columns: 5,
                    spacing: 16,
                    hasMorePosts: hasMorePosts,
                    isLoading: isLoading,
                    loadMoreHandler: { post in
                        guard let post = post else { return }
                        // Prevent multiple simultaneous loads
                        guard hasMorePosts && !isLoading else { return }
                        Task {
                            if isLikedFilter {
                                await likedViewModel.loadMoreLikedPostsIfNeeded(currentItem: post)
                            } else {
                                await userViewModel.loadMoreUserPostsIfNeeded(currentItem: post)
                            }
                        }
                    }
                ) { post in
                    postCell(for: post)
                }
                .id("masonry-\(selectedTab)")
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            } else {
                gridView(spacing: 16, horizontalPadding: 16)
            }
        }
#else
        if #available(macOS 13.0, *) {
            LazyMasonryView(
                items: posts,
                columns: 5,
                spacing: 16,
                hasMorePosts: hasMorePosts,
                isLoading: isLoading,
                loadMoreHandler: { post in
                    guard let post = post else { return }
                    Task {
                        if isLikedFilter {
                            await likedViewModel.loadMoreLikedPostsIfNeeded(currentItem: post)
                        } else {
                            await userViewModel.loadMoreUserPostsIfNeeded(currentItem: post)
                        }
                    }
                }
            ) { post in
                postCell(for: post)
            }
            .id("masonry-\(selectedTab)-\(posts.count)")
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        } else {
            gridView(spacing: 16, horizontalPadding: 16)
        }
#endif
    }
    
    private func gridView(spacing: CGFloat, horizontalPadding: CGFloat) -> some View {
        let columns = [
            GridItem(.adaptive(minimum: 150), spacing: spacing)
        ]
        
        return LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(posts) { post in
                postCell(for: post)
                    .task {
                        if isLikedFilter {
                            await likedViewModel.loadMoreLikedPostsIfNeeded(currentItem: post)
                        } else {
                            await userViewModel.loadMoreUserPostsIfNeeded(currentItem: post)
                        }
                    }
            }
        }
        .padding(.horizontal, horizontalPadding)
    }
    
    @ViewBuilder
    private func postCell(for post: DesignPost) -> some View {
        let postType = post.post_type?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isComponent = postType == "component"
        let isPending = post.status?.lowercased() == "pending"
        
        ZStack {
            DesignCards(
                id: post.id,
                media: post.preview_image_url,
                title: post.title,
                authorName: post.profiles.username,
                isVerified: post.profiles.verified,
                description: post.description,
                codeSnippet: post.code_snippet,
                published: post.created_at,
                isLiked: false,
                isPremium: post.isPremium == true,
                isComponent: isComponent,
                showLikeButton: !isLikedFilter,
                showDeleteButton: !isLikedFilter,
                onDelete: !isLikedFilter ? {
                    postToDelete = post
                    showDeletePostAlert = true
                } : nil
            )
            
            // Pending Badge - positioned at bottom left (only for my posts)
            if !isLikedFilter && isPending {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                    Text("Pending")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(8)
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
    }
}
