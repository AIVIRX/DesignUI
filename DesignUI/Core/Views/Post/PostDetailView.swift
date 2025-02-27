struct PostDetailView: View {
    let post: Post
    @StateObject private var likeManager = LikeManager.shared
    @State private var likeCount: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // ... existing header content ...
                
                // ... existing post content ...
                
                // Interaction buttons
                HStack(spacing: 24) {
                    // Like Button
                    Button(action: {
                        Task {
                            try? await likeManager.toggleLike(postId: post.id)
                            likeCount = await likeManager.getLikeCount(postId: post.id)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: likeManager.likedPosts.contains(post.id) ? "heart.fill" : "heart")
                                .foregroundColor(likeManager.likedPosts.contains(post.id) ? .red : .gray)
                            
                            Text("\(likeCount)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // ... existing comment button ...
                }
                .padding(.horizontal)
                
                // ... existing comments section ...
            }
        }
        .task {
            likeCount = await likeManager.getLikeCount(postId: post.id)
        }
    }
} 