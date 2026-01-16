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
    @State private var hasLoadedLiked = false
    @State private var hasLoadedUserPosts = false
    
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
                        ZStack(alignment: .bottomTrailing) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.8)) // Customize color
                                    .frame(width: 80, height: 80)
                                
                                Text(viewModel.profile?.display_name?.prefix(1).uppercased() ?? "?")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            if viewModel.profile?.verified == true {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                    .offset(x: 2, y: 2)
                            }
                        }
                        // User Info
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                            Text(viewModel.profile?.display_name ?? "user")
                                .font(.title2)
                                .fontWeight(.bold)
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
                            // Tab Buttons with Moving Indicator
                            VStack(spacing: 0) {
                                HStack(spacing: 40) {
                                    // Liked Tab
                                    VStack{
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedTab = .liked
                                            }
                                        } label: {
                                            HStack{
                                                Image(systemName: "heart")
                                                    .foregroundColor(selectedTab == .liked ? .primary : .gray)
                                                    .bold()
                                             Text("Likes")
                                                    .font(.caption)
                                                    .foregroundColor(selectedTab == .liked ? .primary : .gray)

                                            }
                                        }
                                        .buttonStyle(.plain)
                                        
                                        // Indicator
                                        RoundedRectangle(cornerRadius: 20)
                                            .frame(width: 80, height: 3)
                                            .foregroundColor(selectedTab == .liked ? .primary : .clear)
                                            .animation(.easeInOut(duration: 0.2), value: selectedTab)
                                            .padding(.top, 16)
                                    }
                                    
                                    VStack{
                                        // My Posts Tab
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedTab = .myPosts
                                            }
                                        } label: {
                                            HStack{
                                                Image(systemName: "square.grid.2x2")
                                                    .foregroundColor(selectedTab == .myPosts ? .primary : .gray)
                                                    .bold()
                                                
                                                Text("Posts")
                                                    .font(.caption)
                                                    .foregroundColor(selectedTab == .myPosts ? .primary : .gray)

                                            }
                                        }
                                        .buttonStyle(.plain)
                                        
                                        // Indicator
                                        RoundedRectangle(cornerRadius: 20)
                                            .frame(width: 80, height: 3)
                                            .foregroundColor(selectedTab == .myPosts ? .primary : .clear)
                                            .animation(.easeInOut(duration: 0.2), value: selectedTab)
                                            .padding(.top, 16)
                                    }
                                }
                                .padding(.top)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        
                        // Tab Content - posts grid
                            if isLoading && posts.isEmpty {
                                ProgressView()
                                    .padding()
                                    .frame(maxWidth: .infinity, minHeight: 300)
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
                    
                    .task(id: selectedTab) {
                        // Only load once per tab, and only if empty
                        if selectedTab == .liked && !hasLoadedLiked && likedViewModel.likedPosts.isEmpty {
                            hasLoadedLiked = true
                            await likedViewModel.fetchLikedPosts()
                        } else if selectedTab == .myPosts && !hasLoadedUserPosts && userViewModel.userPosts.isEmpty {
                            hasLoadedUserPosts = true
                            await userViewModel.fetchUserPosts()
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .likesChanged)) { notification in
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
                            // Always update, even if not on liked tab, so it appears when user switches
                            Task { @MainActor in
                                await likedViewModel.addLikedPost(postId: postId)
                            }
                        }
                    }
                    .refreshable {
                        if isLikedFilter {
                            hasLoadedLiked = false
                            await likedViewModel.refreshPosts()
                            hasLoadedLiked = true
                        } else {
                            hasLoadedUserPosts = false
                            await userViewModel.refreshPosts()
                            hasLoadedUserPosts = true
                        }
                    }
                    .alert("Delete Post", isPresented: $showDeletePostAlert) {
                        Button("Cancel", role: .cancel) {
                            postToDelete = nil
                        }
                        Button("Delete", role: .destructive) {
                            if let post = postToDelete {
                                Task { @MainActor in
                                    do {
                                        try await userViewModel.deletePost(postId: post.id)
                                        postToDelete = nil
                                    } catch {
                                        print("Error deleting post: \(error.localizedDescription)")
                                        postToDelete = nil
                                    }
                                }
                            } else {
                                postToDelete = nil
                            }
                        }
                    } message: {
                        Text("Are you sure you want to delete this post? This action cannot be undone.")
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
            .id("masonry-\(selectedTab)")
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
        let status = post.status?.lowercased()
        let isPending = status == "pending"
        let isDenied = status == "denied" || status == "rejected"
        
        ZStack {
            DesignCards(
                post: post,
                showLikeButton: true,
                showDeleteButton: !isLikedFilter,
                onDelete: !isLikedFilter ? {
                    postToDelete = post
                    showDeletePostAlert = true
                } : nil
            )
            
            // Status Badge - positioned at bottom left (only for my posts)
            if !isLikedFilter {
                if isPending {
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
                } else if isDenied {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Denied")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(8)
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
        }
    }
}
