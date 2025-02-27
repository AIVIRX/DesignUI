struct CommunityPostsView: View {
    @StateObject private var viewModel = LatestPostsViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.posts) { post in
                    PostCard(post: post)
                        .task {
                            await viewModel.loadMorePostsIfNeeded(currentItem: post)
                        }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.refreshPosts()
        }
        .task {
            await viewModel.loadMorePostsIfNeeded(currentItem: nil)
        }
    }
}

struct PostCard: View {
    let post: DesignPost
    
    var body: some View {
        // Implement your post card design here
        VStack {
            Text(post.title)
            // Add other post details
        }
    }
} 