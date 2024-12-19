struct PostCard: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ... existing post content ...
            
            HStack(spacing: 20) {
                LikeButton(postId: post.id)
                
                // ... other buttons ...
            }
            .padding(.horizontal)
        }
    }
} 