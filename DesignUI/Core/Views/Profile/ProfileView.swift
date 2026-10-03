import SwiftUI
import SDWebImageSwiftUI

enum ProfileTab {
    case liked
    case myPosts
}

struct ProfileView: View {
    @EnvironmentObject private var designManager: DesignManager
    @EnvironmentObject private var toastManager: ToastManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.openWindow) private var openWindow
    @StateObject private var likedViewModel = LikedPostsViewModel()
    @StateObject private var userViewModel = UserPostsViewModel()
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var showDeleteAlert = false
    @State private var showDeletePostAlert = false
    @State private var showingPaywall = false
    @State private var selectedTab: ProfileTab = .liked
    @State private var postToDelete: DesignPost?
    @State private var hasLoadedLiked = false
    @State private var hasLoadedUserPosts = false
    @State private var showingLimitAlert = false

    private let freeDesignLimit = 3
    
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

    private var canCreateDesign: Bool {
        subscriptionManager.isSubscribed || designManager.designFiles.count < freeDesignLimit
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                profileContent
            }
            .navigationTitle("Profile")
            .frame(maxWidth: 1600)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    profileMenu
                }
            }
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
                    designManager.refreshDesignFiles()
                }
            }
        }
    }

    private var profileContent: some View {
        VStack(spacing: 24) {
            profileHeader
            tabbedPostsSection
        }
        .alert("Are you sure you want to delete your account?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await authViewModel.deleteAccount()
                }
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            avatarView
            userInfoView
        }
        .padding(.vertical)
    }

    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            if let avatarUrl = viewModel.profile?.avatarUrl, let url = URL(string: avatarUrl) {
                WebImage(url: url)
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade(duration: 0.2))
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.8))
                        .frame(width: 80, height: 80)

                    Text(viewModel.profile?.display_name?.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            if viewModel.profile?.verified == true {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .offset(x: 2, y: 2)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
    }

    private var userInfoView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Text(viewModel.profile?.display_name ?? "user")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Text(verbatim: "@\(viewModel.profile?.username ?? "username")")
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

    private var tabbedPostsSection: some View {
        VStack(spacing: 0) {
            tabHeader
            postsContent
        }
        .task(id: selectedTab) {
            await loadTabIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .likesChanged), perform: handleLikesChanged)
        .refreshable {
            await refreshCurrentTab()
        }
        .alert("Delete Post", isPresented: $showDeletePostAlert) {
            Button("Cancel", role: .cancel) {
                postToDelete = nil
            }
            Button("Delete", role: .destructive) {
                deleteSelectedPost()
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        .sheet(isPresented: $showingPaywall) {
            CustomPaywallView()
                .environmentObject(PaywallManager.shared)
                .environmentObject(subscriptionManager)
        }
        .alert("Free Limit Reached", isPresented: $showingLimitAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Subscribe") {
                showingPaywall = true
            }
        } message: {
            Text("Free users are limited to \(freeDesignLimit) designs. Subscribe to create unlimited designs.")
        }
    }

    private var tabHeader: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                HStack(spacing: 40) {
                    tabButton(.liked, icon: "heart", title: "Likes")
                }
                .padding(.top)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func tabButton(_ tab: ProfileTab, icon: String, title: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(selectedTab == tab ? .primary : .gray)
                        .bold()
                    Text(title)
                        .font(.caption)
                        .foregroundColor(selectedTab == tab ? .primary : .gray)
                }

                RoundedRectangle(cornerRadius: 20)
                    .frame(width: 80, height: 3)
                    .foregroundColor(selectedTab == tab ? .primary : .clear)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                    .padding(.top, 16)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var postsContent: some View {
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

    private var profileMenu: some View {
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

            Divider()

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

    private func loadTabIfNeeded() async {
        if selectedTab == .liked && !hasLoadedLiked && likedViewModel.likedPosts.isEmpty {
            hasLoadedLiked = true
            await likedViewModel.fetchLikedPosts()
        } else if selectedTab == .myPosts && !hasLoadedUserPosts && userViewModel.userPosts.isEmpty {
            hasLoadedUserPosts = true
            await userViewModel.fetchUserPosts()
        }
    }

    private func handleLikesChanged(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let postId = info["postId"] as? String,
            let isLiked = info["isLiked"] as? Bool
        else { return }

        if !isLiked {
            if let index = likedViewModel.likedPosts.firstIndex(where: { $0.id == postId }) {
                likedViewModel.likedPosts.remove(at: index)
            }
        } else {
            Task { @MainActor in
                await likedViewModel.addLikedPost(postId: postId)
            }
        }
    }

    private func refreshCurrentTab() async {
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

    private func deleteSelectedPost() {
        guard let post = postToDelete else {
            postToDelete = nil
            return
        }

        Task { @MainActor in
            do {
                try await userViewModel.deletePost(postId: post.id)
                postToDelete = nil
            } catch {
                print("Error deleting post: \(error.localizedDescription)")
                postToDelete = nil
            }
        }
    }
    
    @ViewBuilder
    private var postsGridView: some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            masonryGrid(columns: 2, spacing: 8, horizontalPadding: 8, verticalPadding: 8)
            
        } else {
            masonryGrid(columns: 5, spacing: 16, horizontalPadding: 16, verticalPadding: 16)
        }
#else
        masonryGrid(columns: 5, spacing: 16, horizontalPadding: 16, verticalPadding: 16)
#endif
    }

    private func masonryGrid(columns: Int, spacing: CGFloat, horizontalPadding: CGFloat, verticalPadding: CGFloat) -> some View {
        LazyMasonryView(
            items: posts,
            columns: columns,
            spacing: spacing,
            hasMorePosts: hasMorePosts,
            isLoading: isLoading,
            loadMoreHandler: { post in
                guard let post = post else { return }
                guard hasMorePosts && !isLoading else { return }
                Task {
                    await loadMoreIfNeeded(for: post)
                }
            }
        ) { post in
            postCell(for: post)
        }
        .id("masonry-\(selectedTab)")
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
    }

    private func loadMoreIfNeeded(for post: DesignPost) async {
        if isLikedFilter {
            await likedViewModel.loadMoreLikedPostsIfNeeded(currentItem: post)
        } else {
            await userViewModel.loadMoreUserPostsIfNeeded(currentItem: post)
        }
    }
    
    @ViewBuilder
    private func postCell(for post: DesignPost) -> some View {
        let status = post.status?.lowercased()
        let isPending = status == "pending"
        let isDenied = status == "denied" || status == "rejected"
        
        ZStack {
            CommunityCards(
                post: post,
                showDeleteButton: !isLikedFilter,
                onOpen: { postToOpen in
                    handleOpenPost(postToOpen)
                },
                onDelete: !isLikedFilter ? {
                    postToDelete = post
                    showDeletePostAlert = true
                } : nil
            )
            
            // Status Badge - positioned at top left (only for my posts)
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
    }

    private func openDesign(_ design: DesignFile) {
        #if os(macOS)
        openWindow(value: design.id)
        #else
        designManager.openDesign(design)
        #endif
    }

    private func handleOpenPost(_ postToOpen: DesignPost) {
        if postToOpen.isPremium && !subscriptionManager.isSubscribed {
            toastManager.showToast(ToastData(title: "Premium Required", icon: "lock.fill"))
            showingPaywall = true
            return
        }

        guard canCreateDesign else {
            showingLimitAlert = true
            return
        }

        toastManager.showToast(ToastData(title: "Loading Design...", icon: "clock.fill", duration: 5.0))

        Task {
            do {
                let fullPost = try await PostFetcher.fetchPostDetails(id: postToOpen.id)

                if let newDesign = await designManager.createDesignFromPost(post: fullPost, name: fullPost.title) {
                    await MainActor.run {
                        toastManager.dismissToast()
                        openDesign(newDesign)
                    }
                } else {
                    await MainActor.run {
                        toastManager.showToast(ToastData(title: "Load Failed", icon: "xmark.circle.fill"))
                    }
                }
            } catch {
                await MainActor.run {
                    toastManager.showToast(ToastData(title: "Load Failed", icon: "xmark.circle.fill"))
                }
            }
        }
    }
}
